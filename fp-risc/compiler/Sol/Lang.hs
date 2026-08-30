{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TupleSections #-}
{-# OPTIONS_GHC -Wno-missing-export-lists #-}

-- Sol language front-end: parse (megaparsec) + desugar to a minimal functional
-- core. Directly reused from the FPRISC compiler front-end, plus:
--
--   * `> expr.` top-level eval statements (script ergonomics)
--   * `@/path/literal` path literals (logical URLs onto host files)
--
-- Core has ONLY:
--   variables, int/string literals, application, let, if-else,
--   tagged product construction (typeid + variant id + fields),
--   tag tests, positional projections, primitive references.

module Sol.Lang (module Sol.Lang, module FPRISC) where

import Control.Monad (foldM, unless, void, when)
import FPRISC (SExpr (..), Seg (..), SStmt (..), SPat (..), SGuard (..), STop (..), Ty (..), Name, program, guardBools, mapGuardE, expandPathLits, shapeTyTable, primNames)
-- (Name comes from FPRISC; sol's own alias deleted)
import Control.Monad.State.Strict
import Data.Char (isAlphaNum, isLetter, isLower, isUpper)
import Data.List (foldl', intercalate, nub, sort, sortOn)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Data.Maybe (fromMaybe)
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L


--------------------------------------------------------------------------------
-- Surface AST + parser: SHARED (FPRISC.hs) — the fold is complete.
-- Sol.Lang re-exports the one grammar's types and `program`; what
-- remains below is the HostedBytecode PIPELINE proper: Core, desugar,
-- values, linearity.  Sol-only helpers over the shared types:
--------------------------------------------------------------------------------

guardExprs :: [SGuard] -> [SExpr]
guardExprs gs = [e | g <- gs, e <- case g of GBool e' -> [e']; GPat _ e' -> [e']]

guardPats :: [SGuard] -> [SPat]
guardPats gs = [p | GPat p _ <- gs]

mapGuardP :: (SPat -> SPat) -> SGuard -> SGuard
mapGuardP _ (GBool e) = GBool e
mapGuardP f (GPat p e) = GPat (f p) e

-- the shared lexer stores string literals as UTF-8 BYTES (the AOT
-- codegen contract); the VM works in real Chars — decode at the
-- surface->Core boundary.
decodeU8 :: String -> String
decodeU8 [] = []
decodeU8 (c : cs)
  | b < 0x80 = c : decodeU8 cs
  | b >= 0xC0 && b < 0xE0, (c1 : r) <- cs, cont c1 = toEnum ((b - 0xC0) * 64 + v c1) : decodeU8 r
  | b >= 0xE0 && b < 0xF0, (c1 : c2 : r) <- cs, cont c1, cont c2 = toEnum ((b - 0xE0) * 4096 + v c1 * 64 + v c2) : decodeU8 r
  | b >= 0xF0 && b < 0xF8, (c1 : c2 : c3 : r) <- cs, cont c1, cont c2, cont c3 = toEnum ((b - 0xF0) * 262144 + v c1 * 4096 + v c2 * 64 + v c3) : decodeU8 r
  | otherwise = c : decodeU8 cs
  where
    b = fromEnum c
    cont ch = fromEnum ch >= 0x80 && fromEnum ch < 0xC0
    v ch = fromEnum ch - 0x80

--------------------------------------------------------------------------------
-- Core AST
--------------------------------------------------------------------------------

data Core
  = CVar Name
  | CInt Integer
  | CStr String
  | CApp Core Core
  | CLam [Name] Core
  | CLet Name Core Core
  | CIf Core Core Core
  | CMk Int Int [Core]
  | CTagEq Int Int Core
  | CProj Int Core
  | CErr String
  deriving (Show)

type Prog = M.Map Name ([Name], Core)

--------------------------------------------------------------------------------
-- Desugaring
--------------------------------------------------------------------------------

data DEnv = DEnv
  { dFresh :: Int,
    dCons :: M.Map Name (Int, Int, Int),
    dShapes :: M.Map [Name] Int,
    dLifted :: [(Name, [Name], Core)]
  }

type D = Control.Monad.State.Strict.State DEnv

fresh :: String -> D Name
fresh pre = do
  s <- get
  put s {dFresh = dFresh s + 1}
  pure (pre ++ "_" ++ show (dFresh s))

builtinCons :: M.Map Name (Int, Int, Int)
builtinCons =
  M.fromList
    [ ("Unit", (0, 0, 0)),
      ("False", (1, 0, 0)),
      ("True", (1, 1, 0)),
      ("Nil", (2, 0, 0)),
      ("Cons", (2, 1, 2)),
      ("Ok", (3, 0, 1)),
      ("Err", (3, 1, 1)),
      ("Tup2", (4, 0, 2)),
      ("Tup3", (5, 0, 3)),
      -- wide tuples, tids 10..14 -- SAME numbering as the AOT side
      -- (FPRISC builtinCons / fpr.h T_TUP4..T_TUP8)
      ("Tup4", (10, 0, 4)),
      ("Tup5", (11, 0, 5)),
      ("Tup6", (12, 0, 6)),
      ("Tup7", (13, 0, 7)),
      ("Tup8", (14, 0, 8))
    ]

-- the shared tuple rule (mirrors FPRISC.tupCon): 2..8 are real
-- constructors; the old `else "Tup2"` fallback silently packed wider
-- tuples under a Tup2 header -- the corruption class tupCon exists
-- to make unrepresentable.
solTupCon :: Int -> String
solTupCon n
  | n >= 2 && n <= 8 = "Tup" ++ show n
  | otherwise =
      error
        ( "tuple of " ++ show n
            ++ " elements: this ABI has Tup2..Tup8 -- past 8, "
            ++ "declare a constructor or use a record instead"
        )

boolT, listT, atomT :: Int
boolT = 1
listT = 2
atomT = 6

collectCons :: [STop] -> M.Map Name (Int, Int, Int)
collectCons tops = withAliases (M.union builtinCons (M.fromList user))
  where
    tdecls = [cs | TType _ _ _ cs <- tops]
    user = concat (zipWith one [10 ..] tdecls)
    one tid cs = [(c, (tid, v, length tys)) | ((c, tys), v) <- zip cs [0 ..]]
    withAliases m = foldl' (\acc (t, tgt) -> maybe acc (\e -> M.insert t e acc) (M.lookup tgt m)) m
                            [(t, tgt) | TAlias t tgt <- tops]

collectShapes :: [STop] -> M.Map [Name] Int
collectShapes tops = M.fromList (zip allShapes [100 ..])
  where
    allShapes = nub (concatMap topShapes tops)
    topShapes (TShape _ fs) = [sort (map fst fs)]
    topShapes (TBind _ ps g b) =
      concatMap patShapes ps
        ++ concatMap exprShapes (guardExprs g)
        ++ concatMap patShapes (guardPats g)
        ++ exprShapes b
    topShapes _ = []
    patShapes = \case
      PCon _ ps -> concatMap patShapes ps
      PTup ps -> concatMap patShapes ps
      _ -> []
    exprShapes = \case
      SRec fs -> [sort (map fst fs)] ++ concatMap (exprShapes . snd) fs
      SApp a b -> exprShapes a ++ exprShapes b
      SLam _ e -> exprShapes e
      SBlock ss e -> concatMap stmtShapes ss ++ exprShapes e
      SCase s as -> exprShapes s ++ concatMap (\(p, e) -> patShapes p ++ exprShapes e) as
      SBin _ a b -> exprShapes a ++ exprShapes b
      SProj e _ -> exprShapes e
      SUpd m as -> exprShapes m ++ concatMap (exprShapes . snd) as
      STup es -> concatMap exprShapes es
      SList es -> concatMap exprShapes es
      SStrI segs -> concat [exprShapes e | SegExpr e <- segs]
      _ -> []
    stmtShapes (SBind _ _ x) = exprShapes x
    stmtShapes (SBindPat p x) = patShapes p ++ exprShapes x

dExpr :: SExpr -> D Core
dExpr = \case
  SVar n -> do
    cons <- gets dCons
    pure $ case M.lookup n cons of
      Just (_, _, _) -> CVar n
      Nothing -> CVar n
  SInt i -> pure (CInt i)
  SAtom a -> pure (CMk atomT 0 [CStr a])
  SApp a b -> CApp <$> dExpr a <*> dExpr b
  SLam ps e -> CLam ps <$> dExpr e
  SBlock stmts e -> go stmts
    where
      go [] = dExpr e
      go (SBind n ps rhs : rest) = do
        rhs' <- dExpr rhs
        let rhs'' = if null ps then rhs' else CLam ps rhs'
        CLet n rhs'' <$> go rest
      go (SBindPat p rhs : rest) = do
        rhs' <- dExpr rhs
        s <- fresh "bind"
        k <- go rest
        body <- matchPat (CVar s) p k (CErr "let pattern: no match")
        pure (CLet s rhs' body)
  SCase scrut arms -> do
    s <- fresh "scrut"
    sc' <- dExpr scrut
    body <-
      compileArms
        (CVar s)
        [(p, Nothing, e) | (p, e) <- arms]
        (CErr ("case: no matching pattern; arms were " ++ show (map fst arms)))
    pure (CLet s sc' body)
  SBin "|>" a f -> CApp <$> dExpr f <*> dExpr a
  SBin ">>" a b -> do
    a' <- dExpr a
    b' <- dExpr b
    u <- fresh "seq"
    pure (CLet u a' b')
  SBin "|>?" a f -> do
    v <- fresh "ok"
    e <- fresh "err"
    dExpr (SCase a [(PCon "Ok" [PVar v], SApp f (SVar v)), (PCon "Err" [PVar e], SApp (SVar "Err") (SVar e))])
  SBin "::" a b -> dExpr (SApp (SApp (SVar "Cons") a) b)
  SBin op a b -> do
    a' <- dExpr a
    b' <- dExpr b
    pure (CApp (CApp (CVar op) a') b')
  SProj e path -> do
    e' <- dExpr e
    foldM projField e' path
  SRec fs -> do
    let sorted = sortOn fst fs
    tid <- shapeId (map fst sorted)
    -- records carry their FIELD COUNT in var (unused for shapes: one
    -- shape per tid).  The runtime's Vec fix_layout reads it to give
    -- record elements SoA columns by default -- the "no field counts
    -- in headers" limitation, closed where it bit hardest.
    CMk tid (length sorted) <$> mapM (dExpr . snd) sorted
  SUpd m assigns -> do
    m' <- dExpr m
    v <- fresh "rec"
    body <- updateRecord (CVar v) assigns
    pure (CLet v m' body)
  STup es -> do
    let con = solTupCon (length es)
    (tid, var, _) <- conInfo con
    CMk tid var <$> mapM dExpr es
  SList es -> dExpr (foldr (\x acc -> SApp (SApp (SVar "Cons") x) acc) (SVar "Nil") es)
  SStrI segs -> do
    parts <- mapM segCore segs
    pure $ case parts of
      [] -> CStr ""
      (p : ps) -> foldl' (\acc x -> CApp (CApp (CVar "strcat") acc) x) p ps
    where
      segCore (SegStr s) = pure (CStr (decodeU8 s))
      segCore (SegExpr e) = CApp (CVar "str") <$> dExpr e

conInfo :: Name -> D (Int, Int, Int)
conInfo c = do
  cons <- gets dCons
  case M.lookup c cons of
    Just i -> pure i
    Nothing -> error ("unknown constructor: " ++ c)

shapeId :: [Name] -> D Int
shapeId fs = do
  shapes <- gets dShapes
  case M.lookup (sort fs) shapes of
    Just i -> pure i
    Nothing -> error ("unknown record shape: " ++ show fs)

projField :: Core -> Name -> D Core
projField scrut f = do
  shapes <- gets dShapes
  let cands = [(tid, idx, length fs) | (fs, tid) <- M.toList shapes, f `elem` fs, let idx = length (takeWhile (/= f) (sort fs))]
  case cands of
    [] -> error ("no record shape has field ." ++ f)
    [(_, idx, _)] -> pure (CProj idx scrut)
    many' -> do
      v <- fresh "r"
      let chain = foldr (\(tid, idx, ar) rest -> CIf (CTagEq tid ar (CVar v)) (CProj idx (CVar v)) rest) (CErr ("no shape with field ." ++ f ++ " matched")) many'
      pure (CLet v scrut chain)

updateRecord :: Core -> [([Name], SExpr)] -> D Core
updateRecord scrut assigns = do
  shapes <- gets dShapes
  let roots = nub (map (head . fst) assigns)
      cands = [(fs, tid) | (fs, tid) <- M.toList shapes, all (`elem` fs) roots]
  when (null cands) $ error ("no record shape has fields " ++ show roots)
  arms <- mapM rebuild cands
  pure $ case arms of
    [(_, _, body)] -> body
    _ ->
      foldr
        (\(tid, ar, body) rest -> CIf (CTagEq tid ar scrut) body rest)
        (CErr "record update: no shape matched")
        arms
  where
    rebuild (fs, tid) = do
      let sorted = sort fs
      fields <- mapM (fieldValue tid) (zip [0 ..] sorted)
      pure (tid, length fs, CMk tid (length fs) fields)
      where
        fieldValue _ (idx, f) =
          case [(path, e) | (path, e) <- assigns, head path == f] of
            [] -> pure (CProj idx scrut)
            [([_], e)] -> dExpr e
            deeper -> do
              let subAssigns = [(tail p, e) | (p, e) <- deeper]
              updateRecord (CProj idx scrut) subAssigns

compileArms :: Core -> [(SPat, Maybe SExpr, SExpr)] -> Core -> D Core
compileArms scrut arms fallback = go arms
  where
    go [] = pure fallback
    go ((p, g, body) : rest) = do
      nxt <- go rest
      body' <- dExpr body
      inner <- case g of
        Nothing -> pure body'
        Just ge -> do
          ge' <- dExpr ge
          pure (CIf ge' body' nxt)
      matchPat scrut p inner nxt

matchPat :: Core -> SPat -> Core -> Core -> D Core
matchPat scrut p ok fail' = case p of
  PSig x _ -> pure (CLet x scrut ok) -- erased by erasePSig; treat as PVar if one survives
  PWild -> pure ok
  PVar x -> pure (CLet x scrut ok)
  PInt n -> pure (CIf (CApp (CApp (CVar "==") scrut) (CInt n)) ok fail')
  PStr s -> pure (CIf (CApp (CApp (CVar "==") scrut) (CStr s)) ok fail')
  PCon c ps -> do
    (tid, var, ar) <- conInfo c
    unless (length ps == ar) $ error ("constructor " ++ c ++ " arity mismatch in pattern")
    inner <- matchFields scrut ps ok fail'
    pure (CIf (CTagEq tid var scrut) inner fail')
  PTup ps -> do
    let con = solTupCon (length ps)
    (tid, var, _) <- conInfo con
    inner <- matchFields scrut ps ok fail'
    pure (CIf (CTagEq tid var scrut) inner fail')
  PRec fs -> do
    let bind [] = pure ok
        bind (f : rest) = do
          proj <- projField scrut f
          CLet f proj <$> bind rest
    bind fs

matchFields :: Core -> [SPat] -> Core -> Core -> D Core
matchFields scrut ps ok fail' = go (zip [0 ..] ps)
  where
    go [] = pure ok
    go ((i, p) : rest) = do
      inner <- go rest
      matchPat (CProj i scrut) p inner fail'

compileTop :: [STop] -> D Prog
compileTop tops = do
  cons <- gets dCons
  let conGlobals = [(c, (params, CMk tid var (map CVar params))) | (c, (tid, var, ar)) <- M.toList cons, let params = ["x" ++ show i | i <- [1 .. ar]]]
  binds <- mapM compileGroup (groupClauses [b | b@TBind {} <- tops])
  pure (M.fromList (conGlobals ++ binds))
  where
    groupClauses [] = []
    groupClauses (TBind n ps g b : rest) =
      let (same, others) = span (\(TBind n' _ _ _) -> n' == n) rest
       in (n, (ps, g, b) : [(ps', g', b') | TBind _ ps' g' b' <- same]) : groupClauses others
    groupClauses (_ : rest) = groupClauses rest

compileGroup :: (Name, [([SPat], [SGuard], SExpr)]) -> D (Name, ([Name], Core))
compileGroup (n, clauses@((ps0, _, _) : _)) = do
  let arity = length ps0
  args <- mapM (\i -> fresh ("a" ++ show i)) [1 .. arity]
  body <- goClauses args clauses
  pure (n, (args, body))
  where
    goClauses _ [] = pure (CErr ("no matching clause for " ++ n))
    goClauses args ((ps, g, b) : rest) = do
      nxtBig <- goClauses args rest
      -- JOIN POINT: the fallthrough continuation is spliced into every
      -- failure site of this clause's pattern/guard match (tuple tag
      -- checks, literal subpatterns, each guard component). Inlining it
      -- verbatim doubles the tree per clause — exponential in clause
      -- count (22 idiomatic clauses OOM'd the compiler). Bind it once as
      -- a zero-use-arg lambda instead; lambda lifting turns it into an
      -- ordinary supercombinator capturing the args, and each failure
      -- site becomes a call. Last clause keeps the tiny CErr inline.
      (nxt, wrap) <- case rest of
        [] -> pure (nxtBig, pure)
        _ -> do
          j <- fresh "join"
          pure (CApp (CVar j) (CInt 0), \body -> pure (CLet j (CLam ["_j"] nxtBig) body))
      r <- goClause args ps g b nxt
      wrap r
    goClause args ps g b nxt = do
      let goGuards [] = dExpr b
          goGuards (GBool ge : gs) = do
            ge' <- dExpr ge
            k <- goGuards gs
            pure (CIf ge' k nxt)
          goGuards (GPat p e : gs) = do
            e' <- dExpr e
            k <- goGuards gs
            gv <- fresh "g"
            m <- matchPat (CVar gv) p k nxt
            pure (CLet gv e' m)
      inner <- goGuards g
      matchMany (zip (map CVar args) ps) inner nxt
    matchMany [] ok _ = pure ok
    matchMany ((s, p) : rest) ok fail' = do
      inner <- matchMany rest ok fail'
      matchPat s p inner fail'
compileGroup (n, []) = error ("empty clause group: " ++ n)

--------------------------------------------------------------------------------
-- Lambda lifting
--------------------------------------------------------------------------------

liftProg :: Prog -> D Prog
liftProg prog = do
  let globalNames = M.keysSet prog
  lifted <- M.traverseWithKey (\_ (ps, b) -> (ps,) <$> liftC globalNames ps b) prog
  extra <- gets dLifted
  extra' <-
    mapM
      ( \(n, ps, b) -> do
          b' <- liftC globalNames ps b
          pure (n, (ps, b'))
      )
      extra
  pure (M.union lifted (M.fromList extra'))
  where
    liftC globals bound = go (foldr (:) [] bound)
      where
        go env = \case
          CLam ps body -> do
            body' <- go (ps ++ env) body
            let fvs =
                  nub
                    [ v | v <- freeVars body', v `notElem` ps, not (v `M.member` prog), v `notElem` primNames
                    ]
                capture = filter (`elem` (env :: [Name])) fvs
            nm <- fresh "lifted"
            modify (\s -> s {dLifted = (nm, capture ++ ps, body') : dLifted s})
            pure (foldl' CApp (CVar nm) (map CVar capture))
          CApp a b -> CApp <$> go env a <*> go env b
          CLet x a b -> CLet x <$> go env a <*> go (x : env) b
          CIf c t e -> CIf <$> go env c <*> go env t <*> go env e
          CMk t v fs -> CMk t v <$> mapM (go env) fs
          CTagEq t v e -> CTagEq t v <$> go env e
          CProj i e -> CProj i <$> go env e
          other -> pure other

freeVars :: Core -> [Name]
freeVars = \case
  CVar n -> [n]
  CApp a b -> freeVars a ++ freeVars b
  CLam ps b -> filter (`notElem` ps) (freeVars b)
  CLet x a b -> freeVars a ++ filter (/= x) (freeVars b)
  CIf c t e -> freeVars c ++ freeVars t ++ freeVars e
  CMk _ _ fs -> concatMap freeVars fs
  CTagEq _ _ e -> freeVars e
  CProj _ e -> freeVars e
  _ -> []

liftFix :: Prog -> D Prog
liftFix p = do
  modify (\s -> s {dLifted = []})
  p' <- liftProg p
  if any (hasLam . snd . snd) (M.toList p') then liftFix p' else pure p'
  where
    hasLam = \case
      CLam _ _ -> True
      CApp a b -> hasLam a || hasLam b
      CLet _ a b -> hasLam a || hasLam b
      CIf c t e -> hasLam c || hasLam t || hasLam e
      CMk _ _ fs -> any hasLam fs
      CTagEq _ _ e -> hasLam e
      CProj _ e -> hasLam e
      _ -> False

--------------------------------------------------------------------------------
-- Pretty printer for Core
--------------------------------------------------------------------------------

pretty :: Core -> String
pretty = go 0
  where
    ind n = replicate (n * 2) ' '
    go _ (CVar n) = n
    go _ (CInt i) = show i
    go _ (CStr s) = show s
    go _ (CErr m) = "error " ++ show m
    go d e@CApp {} = let (f, as) = spine e in "(" ++ unwords (map (go d) (f : as)) ++ ")"
    go d (CLam ps b) = "(\\" ++ unwords ps ++ " -> " ++ go d b ++ ")"
    go d (CLet x a b) = "let " ++ x ++ " = " ++ go (d + 1) a ++ " in\n" ++ ind (d + 1) ++ go (d + 1) b
    go d (CIf c t e) = "if " ++ go d c ++ "\n" ++ ind (d + 1) ++ "then " ++ go (d + 1) t ++ "\n" ++ ind (d + 1) ++ "else " ++ go (d + 1) e
    go d (CMk t v fs) = "mk[" ++ show t ++ "." ++ show v ++ "](" ++ intercalate ", " (map (go d) fs) ++ ")"
    go d (CTagEq t v e) = "tag?(" ++ go d e ++ " == " ++ show t ++ "." ++ show v ++ ")"
    go d (CProj i e) = "proj." ++ show i ++ "(" ++ go d e ++ ")"
    spine (CApp a b) = let (f, as) = spine a in (f, as ++ [b])
    spine f = (f, [])

prettyProg :: Prog -> [Name] -> String
prettyProg prog names = unlines [n ++ " " ++ unwords ps ++ " =\n  " ++ pretty b ++ "\n" | n <- names, Just (ps, b) <- [M.lookup n prog]]

--------------------------------------------------------------------------------
-- Linearity checker (static, pre-desugar).
--------------------------------------------------------------------------------

data LShape = LU | LL | LTupS [LShape] deriving (Show)

isLin :: LShape -> Bool
isLin LL = True
isLin (LTupS ss) = any isLin ss
isLin LU = False

data LinInfo = LinInfo
  { liLinTys :: [Name],
    liSigs :: M.Map Name ([LShape], LShape),
    liConSh :: M.Map Name (LShape, [LShape]),
    liConAr :: M.Map Name Int
  }

shapeOfTy :: [Name] -> Ty -> LShape
shapeOfTy lin = \case
  TTup ts -> LTupS (map (shapeOfTy lin) ts)
  TCon n as -> if n `elem` lin || any (isLin . shapeOfTy lin) as then LL else LU
  TVarT _ -> LU
  TArrT _ _ -> LU
  TVApp _ _ -> LU
  TOther -> LU

buildLinInfo :: [STop] -> LinInfo
buildLinInfo tops = LinInfo lin sigs conSh conAr
  where
    aliases = [(t, tgt) | TAlias t tgt <- tops]
    lin0 = [n | TType n True _ _ <- tops]
    lin = lin0 ++ [t | (t, tgt) <- aliases, tgt `elem` lin0]
    sigs = M.fromList [(n, (map sh ps, sh r)) | TSig n (ps, r) _ <- tops]
    conSh0 = M.fromList [(c, (if linear then LL else LU, map sh tys)) | TType _ linear _ cs <- tops, (c, tys) <- cs]
    conSh = foldl' (\m (t, tgt) -> maybe m (\e -> M.insert t e m) (M.lookup tgt m)) conSh0 aliases
    conAr0 = M.fromList [(c, length tys) | TType _ _ _ cs2 <- tops, (c, tys) <- cs2]
    conAr = foldl' (\m (t, tgt) -> maybe m (\e -> M.insert t e m) (M.lookup tgt m)) conAr0 aliases
    sh = shapeOfTy lin

type Cnt = M.Map Name Int

type LRes = ([String], Maybe Cnt, LShape)

lcheck :: LinInfo -> [STop] -> [String]
lcheck li tops = concatMap checkGroup groups
  where
    groups = groupTB [b | b@TBind {} <- tops]
    groupTB [] = []
    groupTB (TBind n ps g b : rest) = let (same, others) = span (\(TBind n' _ _ _) -> n' == n) rest in (n, (ps, g, b) : [(p', g', b') | TBind _ p' g' b' <- same]) : groupTB others
    groupTB (_ : rest) = groupTB rest

    checkGroup (n, clauses) = concatMap (checkClause n) clauses

    checkClause n (pats, g, body) =
      let paramShapes = case M.lookup n (liSigs li) of
            Just (ps, _) | length ps == length pats -> ps
            _ -> replicate (length pats) LU
          binds = concat (zipWith (bindPat li) pats paramShapes)
          env = M.fromList binds
          linear = [v | (v, s) <- binds, isLin s]
          (genv, ge, gc) =
            foldl'
              ( \(en, errs, cnt) gd -> case gd of
                  GBool gx ->
                    let (e', c', _) = lin' en gx
                     in (en, errs ++ e', M.unionWith (+) cnt (fromMaybe M.empty c'))
                  GPat p gx ->
                    let (e', c', _) = lin' en gx
                        en' = M.union (M.fromList (bindPat li p LU)) en
                     in (en', errs ++ e', M.unionWith (+) cnt (fromMaybe M.empty c'))
              )
              (env, [], M.empty)
              g
          (be, bc, _) = lin' genv body
          guardErr = ["in " ++ n ++ ": guard uses linear variable(s) " ++ show (M.keys (M.filter (> 0) gc)) ++ " (guards may re-evaluate on fallthrough)" | not (M.null (M.filter (> 0) gc))]
          useErrs = case bc of
            Nothing -> []
            Just c -> ["in " ++ n ++ ": linear variable '" ++ v ++ "' used " ++ show (M.findWithDefault 0 v c) ++ " time(s), expected exactly 1" | v <- linear, M.findWithDefault 0 v c /= 1]
       in ge ++ be ++ guardErr ++ useErrs
      where
        lin' = linExpr li

bindPat :: LinInfo -> SPat -> LShape -> [(Name, LShape)]
bindPat li p s = case p of
  PSig x _ -> [(x, s)] -- erased by erasePSig; PVar behavior if one survives
  PVar x -> [(x, s)]
  PWild -> []
  PInt _ -> []
  PStr _ -> []
  PRec fs -> [(f, LU) | f <- fs]
  PTup ps -> case s of
    LTupS ss | length ss == length ps -> concat (zipWith (bindPat li) ps ss)
    _ -> concatMap (\q -> bindPat li q LU) ps
  PCon c ps -> case M.lookup c (liConSh li) of
    Just (_, argShapes) | length argShapes == length ps -> concat (zipWith (bindPat li) ps argShapes)
    _ -> concatMap (\q -> bindPat li q LU) ps

linExpr :: LinInfo -> M.Map Name LShape -> SExpr -> LRes
linExpr li env0 = go env0
  where
    zero = M.empty
    addC = M.unionWith (+)
    plus (Just a) (Just b) = Just (addC a b)
    plus _ _ = Nothing

    go :: M.Map Name LShape -> SExpr -> LRes
    go env = \case
      SVar v -> case M.lookup v env of
        Just s | isLin s -> ([], Just (M.singleton v 1), s)
        Just s -> ([], Just zero, s)
        Nothing -> ([], Just zero, globalShape v)
      SInt _ -> ([], Just zero, LU)
      SAtom _ -> ([], Just zero, LU)
      SStrI segs ->
        let rs = [go env e | SegExpr e <- segs]
         in (concat [e | (e, _, _) <- rs], foldl' plus (Just zero) [c | (_, c, _) <- rs], LU)
      e@SApp {} -> appSpine env e
      SBin "|>" a f -> go env (SApp f a)
      SBin "::" a b -> go env (SApp (SApp (SVar "Cons") a) b)
      SBin ">>" a b ->
        let (e1, c1, _) = go env a; (e2, c2, s2) = go env b
         in (e1 ++ e2, plus c1 c2, s2)
      SBin _ a b ->
        let (e1, c1, _) = go env a; (e2, c2, _) = go env b
         in (e1 ++ e2, plus c1 c2, LU)
      SProj e _ -> let (er, c, _) = go env e in (er, c, LU)
      SRec fs ->
        let rs = map (go env . snd) fs
         in (concat [e | (e, _, _) <- rs], foldl' plus (Just zero) [c | (_, c, _) <- rs], LU)
      SUpd m as ->
        let rs = go env m : map (go env . snd) as
         in (concat [e | (e, _, _) <- rs], foldl' plus (Just zero) [c | (_, c, _) <- rs], LU)
      SList es ->
        let rs = map (go env) es
            sh = if any (\(_, _, s) -> isLin s) rs then LL else LU
         in (concat [e | (e, _, _) <- rs], foldl' plus (Just zero) [c | (_, c, _) <- rs], sh)
      STup es ->
        let rs = map (go env) es
         in (concat [e | (e, _, _) <- rs], foldl' plus (Just zero) [c | (_, c, _) <- rs], LTupS [s | (_, _, s) <- rs])
      SLam _ body ->
        let caps = [v | v <- sFree body, maybe False isLin (M.lookup v env)]
         in (["lambda captures linear variable(s) " ++ show caps ++ " (PoC: partial applications holding linear values unsupported)" | not (null caps)], Just zero, LU)
      SCase scrut arms ->
        let (se, sc, sshape) = go env scrut
            armRes = map (checkArm env sshape) arms
            errs = se ++ concat [e | (e, _, _) <- armRes]
            live = [(c, s) | (_, Just c, s) <- armRes]
            agree = case live of
              [] -> []
              ((c0, _) : rest) -> ["case branches disagree on use of linear variable(s) " ++ show (disagreeing c0 c) | (c, _) <- rest, not (M.null (disagreeingM c0 c))]
            total = case live of
              [] -> Nothing
              ((c0, _) : _) -> plus sc (Just c0)
            shape = case live of ((_, s) : _) -> s; [] -> LU
         in (errs ++ agree, total, shape)
      SBlock stmts final -> goBlock env stmts final

    disagreeingM a b = M.filter id (M.intersectionWith (/=) a' b')
      where
        a' = M.unionWith (+) a (M.map (const 0) b)
        b' = M.unionWith (+) b (M.map (const 0) a)
    disagreeing a b = M.keys (disagreeingM a b)

    checkArm env sshape (p, body) =
      let binds = bindPat li p sshape
          env' = M.union (M.fromList binds) env
          (es, c, s) = go env' body
          linear = [v | (v, sh) <- binds, isLin sh]
          errs = case c of
            Nothing -> []
            Just cc -> ["linear variable '" ++ v ++ "' bound in pattern used " ++ show (M.findWithDefault 0 v cc) ++ " time(s), expected 1" | v <- linear, M.findWithDefault 0 v cc /= 1]
          c' = fmap (\cc -> foldr M.delete cc (map fst binds)) c
       in (es ++ errs, c', s)

    goBlock env [] final = go env final
    goBlock env (SBind n [] rhs : rest) final =
      let (e1, c1, sh) = go env rhs
          env' = M.insert n sh env
          (e2, c2, shf) = goBlock env' rest final
          errs = case c2 of
            Nothing -> []
            Just cc | isLin sh, M.findWithDefault 0 n cc /= 1 -> ["linear variable '" ++ n ++ "' used " ++ show (M.findWithDefault 0 n cc) ++ " time(s), expected exactly 1"]
            _ -> []
          c2' = fmap (M.delete n) c2
       in (e1 ++ e2 ++ errs, plus c1 c2', shf)
    goBlock env (SBind n _ps rhs : rest) final =
      let caps = [v | v <- sFree rhs, maybe False isLin (M.lookup v env)]
          errs = ["local function '" ++ n ++ "' captures linear variable(s) " ++ show caps | not (null caps)]
          (e2, c2, shf) = goBlock (M.insert n LU env) rest final
       in (errs ++ e2, c2, shf)
    goBlock env (SBindPat p rhs : rest) final =
      let (e1, c1, sh) = go env rhs
          binds = bindPat li p sh
          env' = M.union (M.fromList binds) env
          (e2, c2, shf) = goBlock env' rest final
          linear = [v | (v, s) <- binds, isLin s]
          errs = case c2 of
            Nothing -> []
            Just cc -> ["linear variable '" ++ v ++ "' used " ++ show (M.findWithDefault 0 v cc) ++ " time(s), expected exactly 1" | v <- linear, M.findWithDefault 0 v cc /= 1]
          c2' = fmap (\cc -> foldr M.delete cc (map fst binds)) c2
       in (e1 ++ e2 ++ errs, plus c1 c2', shf)

    appSpine env e =
      let (h, args) = flatten e []
          argRes = map (go env) args
          argErrs = concat [er | (er, _, _) <- argRes]
          argCnt = foldl' plus (Just zero) [c | (_, c, _) <- argRes]
          anyLinArg = any (\(_, _, s) -> isLin s) argRes
       in case h of
            SVar "error" -> (argErrs, Nothing, LU)
            SVar g ->
              let (sh, full) = headShape g (length args)
                  perr = ["partial application of '" ++ g ++ "' over linear argument(s) (PoC unsupported)" | anyLinArg && not full]
                  (he, hc, _) = go env (SVar g)
               in (argErrs ++ perr ++ he, plus hc argCnt, sh)
            _ ->
              let (he, hc, _) = go env h
               in (argErrs ++ he, plus hc argCnt, LU)
      where
        flatten (SApp f a) acc = flatten f (a : acc)
        flatten f acc = (f, acc)

    headShape g nargs
      | Just (retSh, _) <- M.lookup g (liConSh li),
        Just ar <- M.lookup g (liConAr li) =
          (if nargs == ar then retSh else LU, nargs >= ar)
      | Just (ps, r) <- M.lookup g (liSigs li) = (if nargs == length ps then r else LU, nargs >= length ps)
      | otherwise = (LU, True)
    globalShape v
      | Just (ps, r) <- M.lookup v (liSigs li), null ps = r
      | Just (r, as) <- M.lookup v (liConSh li), null as = r
      | otherwise = LU

sFree :: SExpr -> [Name]
sFree = nub . go
  where
    go = \case
      SVar v -> [v]
      SApp a b -> go a ++ go b
      SLam ps e -> filter (`notElem` ps) (go e)
      SBin _ a b -> go a ++ go b
      SProj e _ -> go e
      SRec fs -> concatMap (go . snd) fs
      SUpd m as -> go m ++ concatMap (go . snd) as
      STup es -> concatMap go es
      SList es -> concatMap go es
      SStrI segs -> concat [go e | SegExpr e <- segs]
      SCase s arms -> go s ++ concatMap armF arms
      SBlock ss e -> blockF ss e
      _ -> []
    armF (p, e) = filter (`notElem` patB p) (go e)
    patB = \case
      PVar x -> [x]
      PCon _ ps -> concatMap patB ps
      PTup ps -> concatMap patB ps
      PRec fs -> fs
      _ -> []
    blockF [] e = go e
    blockF (SBind n ps rhs : rest) e = filter (`notElem` ps) (go rhs) ++ filter (/= n) (blockF rest e)
    blockF (SBindPat p rhs : rest) e = go rhs ++ filter (`notElem` patB p) (blockF rest e)


--------------------------------------------------------------------------------
-- Module import support: binder-aware renaming and alias qualification.
--
-- `renameTops rn` renames every reference to a module's own top-level names
-- (values, types, constructors, sigs) — used to prefix an imported module's
-- definitions with its alias ("node" -> "web.node"). Local binders shadow.
--
-- `qualifyUses aliases` rewrites `m.f` (parsed as a projection off the
-- variable m) into a reference to the merged global "m.f" whenever m is a
-- module alias and not locally bound.
--------------------------------------------------------------------------------

-- rename guard components left-to-right: each pattern's variables shadow
-- (become binders) for later guard expressions and the clause body
renGuards ::
  (S.Set Name -> SExpr -> SExpr) ->
  (SPat -> SPat) ->
  S.Set Name ->
  [SGuard] ->
  (S.Set Name, [SGuard])
renGuards re rp = go
  where
    go bs [] = (bs, [])
    go bs (GBool e : gs) = let (bs', gs') = go bs gs in (bs', GBool (re bs e) : gs')
    go bs (GPat p e : gs) =
      let bs2 = S.union bs (S.fromList (patVars p))
          (bs', gs') = go bs2 gs
       in (bs', GPat (rp p) (re bs e) : gs')

patVars :: SPat -> [Name]
patVars = \case
  PVar n -> [n]
  PSig n _ -> [n]
  PCon _ ps -> concatMap patVars ps
  PTup ps -> concatMap patVars ps
  PRec ns -> ns
  _ -> []

-- generic bottom-up expr transform threading the set of locally-bound names;
-- pf transforms binding patterns (case alts, block pattern-binds) so that
-- imported constructor names in patterns are renamed too
transformE :: (S.Set Name -> SExpr -> SExpr) -> S.Set Name -> SExpr -> SExpr
transformE f = transformEP f id

transformEP :: (S.Set Name -> SExpr -> SExpr) -> (SPat -> SPat) -> S.Set Name -> SExpr -> SExpr
transformEP f pf = go
  where
    go bs e0 = f bs $ case e0 of
      SApp a b -> SApp (go bs a) (go bs b)
      SLam ps b -> SLam ps (go (bs `S.union` S.fromList ps) b)
      SBlock stmts fin ->
        let (stmts', bs') = goStmts bs stmts
         in SBlock stmts' (go bs' fin)
      SCase s alts -> SCase (go bs s) [(pf p, go (bs `S.union` S.fromList (patVars p)) e) | (p, e) <- alts]
      SBin op a b -> SBin op (go bs a) (go bs b)
      SProj e path -> SProj (go bs e) path
      SRec fs -> SRec [(n, go bs e) | (n, e) <- fs]
      SUpd m as -> SUpd (go bs m) [(p, go bs e) | (p, e) <- as]
      STup es -> STup (map (go bs) es)
      SList es -> SList (map (go bs) es)
      SStrI segs -> SStrI [case s of SegExpr e -> SegExpr (go bs e); o -> o | s <- segs]
      other -> other
    goStmts bs [] = ([], bs)
    goStmts bs (SBind n ps x : rest) =
      let x' = go (bs `S.union` S.fromList (n : ps)) x
          (rest', bs') = goStmts (S.insert n bs) rest
       in (SBind n ps x' : rest', bs')
    goStmts bs (SBindPat p x : rest) =
      let x' = go bs x
          (rest', bs') = goStmts (bs `S.union` S.fromList (patVars p)) rest
       in (SBindPat (pf p) x' : rest', bs')

renameTops :: M.Map Name Name -> [STop] -> [STop]
renameTops rn tops0 = map top tops0
  where
    look n = M.findWithDefault n n rn
    -- dotted-head renaming exists ONLY for struct field self-references
    -- (`ListS.add` before the struct expands to flat globals). It must
    -- NOT fire for other dotted names: diamond file-module imports leave
    -- canonical cross-module refs like `logic.base.findCh` whose head
    -- coincides with a use-binding name — renaming those dangles them.
    structNames = S.fromList [n | TStruct n _ _ <- tops0]
    lookDotted v = case M.lookup v rn of
      Just r -> r
      Nothing -> case break (== '.') v of
        (h, '.' : rest) | S.member h structNames, M.member h rn -> look h ++ "." ++ rest
        _ -> v
    top = \case
      TBind n ps g b ->
        let bs = S.fromList (concatMap patVars ps)
            (bs', g') = renGuards re rp bs g
         in TBind (look n) (map rp ps) g' (re bs' b)
      TSig n (ps, r) pcs -> TSig (look n) (map rt ps, rt r) pcs
      TType n l ps cs -> TType (look n) l ps [(look c, map rt tys) | (c, tys) <- cs]
      TEval e -> TEval (re S.empty e)
      TAlias t tgt -> TAlias (look t) (look tgt)
      TSigDef n fs -> TSigDef (look n) fs
      TStruct n sigs fs -> TStruct (look n) (map look sigs) [(f, re S.empty e) | (f, e) <- fs]
      other -> other
    rt = \case
      TCon n as -> TCon (look n) (map rt as)
      TTup ts -> TTup (map rt ts)
      o -> o
    rp = \case
      PCon c ps -> PCon (look c) (map rp ps)
      PTup ps -> PTup (map rp ps)
      PSig n sg -> PSig n (look sg)
      o -> o
    re = transformEP step rp
    step bs e = case e of
      SVar v | not (S.member v bs) -> SVar (lookDotted v)
      _ -> e


-- every name a module defines at top level (what an importer may reference)
topNames :: [STop] -> [Name]
topNames tops =
  concat
    [ [n | TBind n _ _ _ <- tops],
      [n | TSig n _ _ <- tops],
      [n | TType n _ _ _ <- tops],
      [c | TType _ _ _ cs <- tops, (c, _) <- cs],
      [t | TAlias t _ <- tops],
      [n | TSigDef n _ <- tops],
      [n | TStruct n _ _ <- tops]
    ]

qualifyUses :: M.Map Name Name -> [STop] -> [STop]
qualifyUses aliases = map top
  where
    top = \case
      TBind n ps g b ->
        let bs = S.fromList (concatMap patVars ps)
            (bs', g') = renGuards re id bs g
         in TBind n ps g' (re bs' b)
      TEval e -> TEval (re S.empty e)
      -- the shared parser produces TUse for `m = use "spec".`; splicing
      -- already happened in expandUses — re-emit the RUNTIME binding so
      -- first-class Module values (`run m`) keep working
      TUse mn spec -> TBind mn [] [] (re S.empty (SApp (SVar "use") (SStrI [SegStr spec])))
      TAlias t tgt -> TAlias t (retgt tgt)
      other -> other
    retgt tgt = case break (== '.') tgt of
      (m, '.' : rest) | Just canon <- M.lookup m aliases -> canon ++ "." ++ rest
      _ -> tgt
    re = transformE step
    step bs e = case e of
      SProj (SVar m) (f : rest)
        | Just canon <- M.lookup m aliases,
          not (S.member m bs) ->
            let base = SVar (canon ++ "." ++ f)
             in if null rest then base else SProj base rest
      _ -> e
