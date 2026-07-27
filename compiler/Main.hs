module Main where

import Codegen (Target, codegenRev, emitProgram, externals, rv32, rv64, tgtName)
import A64 (lowerA64, a64Rev)
import X64 (lowerX64, deTlsQosApp, x64Rev)
import Control.Monad (forM, forM_, unless, when)
import Control.Monad.State.Strict (runState)
import Data.List (isPrefixOf)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import FPRISC
import Infer (inferTops)
import Struct (erasePSig, expandStructs, sigTable, specialize, structTable)
import Modules (LoadResult (..), ModExport (..), hashAST, loadProgram)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.FilePath (takeDirectory, (</>))
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import Text.Megaparsec (errorBundlePretty, parse)

data Opts = Opts
  { oTarget :: Target,
    oA64 :: Bool, -- lower the rv64 emission (the shared RISC IR) to AArch64
    oX64 :: Bool, -- lower it to x86-64 (SysV) instead
    oQosApp :: Bool, -- qx64: QOS-x86_64 app image (plain-global cells, no TLS)
    oRvv :: Bool,
    oPrelude :: Maybe FilePath,
    oFiles :: [FilePath]
  }

parseArgs :: [String] -> Opts
parseArgs = foldl step (Opts rv64 False False False False Nothing [])
  where
    step o "--target=rv32" = o {oTarget = rv32}
    step o "--target=rv64" = o {oTarget = rv64}
    step o "--target=a64" = o {oTarget = rv64, oA64 = True} -- rv64 emission is the IR
    step o "--target=x64" = o {oTarget = rv64, oX64 = True} -- likewise
    step o "--target=qx64" = o {oTarget = rv64, oX64 = True, oQosApp = True} -- QOS-x86_64
    step o "--rvv" = o {oRvv = True}
    step o a
      | "--prelude=" `isPrefixOf` a = o {oPrelude = Just (drop (length "--prelude=") a)}
      | otherwise = o {oFiles = oFiles o ++ [a]}

parseFile :: FilePath -> IO [STop]
parseFile p = do
  src <- readFile p
  case parse program p src of
    Left e -> putStrLn (errorBundlePretty e) >> exitFailure >> pure []
    Right tops -> pure tops

-- top-level bind name -> arity, for the extern-known-globals map:
-- cross-unit references stay KNOWN (direct calls, 0-ary `call`,
-- fpr_obj_ value refs) because the importer parsed the dep anyway.
arities :: [STop] -> M.Map String Int
arities tops = M.fromList [(n, length ps) | TBind n ps _ _ <- tops]

bindNames :: [STop] -> S.Set String
bindNames = M.keysSet . arities

main :: IO ()
main = do
  setLocaleEncoding utf8
  opts <- parseArgs <$> getArgs
  (inp, out) <- case oFiles opts of
    [i, o] -> pure (i, o)
    _ -> putStrLn "usage: fprc [--target=rv32|rv64|a64|x64|qx64] [--rvv] [--prelude=FILE] <in.fpr> <out.s>" >> exitFailure >> pure ("", "")
  preludeTops <- maybe (pure []) parseFile (oPrelude opts)
  rootTops <- parseFile inp
  lr <- loadProgram preludeTops inp rootTops
  case lr of
    Left e -> putStrLn e >> exitFailure
    Right (LoadResult tops0 exports notes units0 root0 rootHash) -> do
      mapM_ putStrLn notes
      -- ---- ML-style modules: expand sigs/structures, typecheck (HM +
      -- rows), resolve operators by operand type, monomorphize -----------
      -- The global sig table spans units (prelude sigs are visible
      -- everywhere). Structs expand per-unit to flat `Numeric.+` globals
      -- plus a first-class record; codegen stays per-unit, cached.
      let sigs = sigTable tops0
          structs = structTable tops0
          expandU uts = snd (expandStructs sigs uts)
          preludeExpErrs = fst (expandStructs sigs preludeTops)
          preludeE = expandU preludeTops
          root' = expandU root0
          units = [(h, expandU uts) | (h, uts) <- units0]
          tops = expandU tops0
      unless (null preludeExpErrs) $ do
        putStrLn "=== SIG/STRUCT: ERRORS ==="
        mapM_ (putStrLn . ("  * " ++)) preludeExpErrs
        exitFailure
      -- typecheck the merged expanded program; rewritten tops carry
      -- operator sites resolved to prims / Str.+ / s.(+)
      let (terrs, _notes, topsRW) = inferTops sigs structs tops
      unless (null terrs) $ do
        putStrLn "=== TYPE ERRORS ==="
        mapM_ (putStrLn . ("  * " ++)) terrs
        exitFailure
      -- specialize generic calls; clones land in the merged program used
      -- for whole-program analyses. Per-unit codegen re-expands + rewrites
      -- its own tops (deterministic), so operator resolution is local.
      let (specErrs, topsSpec) = specialize sigs structs topsRW
      unless (null specErrs) $ do
        putStrLn "=== SIG/STRUCT: ERRORS ==="
        mapM_ (putStrLn . ("  * " ++)) specErrs
        exitFailure
      let finalTops = erasePSig topsSpec
      -- ---- whole-program ANALYSES (cheap; codegen below is per-unit) ----
      let preludeHash = hashAST preludeTops
          -- content-addressed cons: every unit's types under ITS hash;
          -- both sides of a `use` compute the same ids from the same AST.
          consAll =
            M.unions
              ( collectCons preludeHash preludeE
                  : collectCons rootHash root'
                  : [collectCons h uts | (h, uts) <- units]
              )
          shapes = collectShapes finalTops -- structural fnv ids: globally consistent
          -- tid collision check (fnv32 is probabilistic; fail LOUDLY)
          tidDecls =
            [ (t, ownerT ++ "." ++ n)
              | (ownerT, ownerH, uts) <-
                  ("prelude", preludeHash, preludeE)
                    : ("root", rootHash, root')
                    : [(take 12 h, h, uts) | (h, uts) <- units],
              TType n _ _ _ <- uts,
              let t = tidFor ownerH n
            ]
          li = buildLinInfo finalTops
          lerrs = lcheck li finalTops
      -- real tid clash check: same tid, different qualified type name
      let byTid = M.fromListWith (++) [(t, [q]) | (t, q) <- tidDecls]
          bad = [(t, qs) | (t, qs) <- M.toList byTid, length (S.toList (S.fromList qs)) > 1]
      unless (null bad) $ do
        putStrLn "=== TYPEID COLLISION (content-addressed tid clash; rename a type) ==="
        forM_ bad $ \(t, qs) -> putStrLn ("  tid " ++ show t ++ ": " ++ unwords qs)
        exitFailure
      unless (null (liLinTys li)) $
        putStrLn ("linear types: " ++ unwords (liLinTys li))
      unless (null lerrs) $ do
        putStrLn "=== LINEARITY: ERRORS ==="
        mapM_ (putStrLn . ("  * " ++)) lerrs
        exitFailure
      -- ---- per-unit CODEGEN (separate compilation) ----
      -- Each unit is expanded already (preludeE/units/root'). For codegen
      -- we also need operator sites resolved locally (Int prim / Str.+),
      -- which inferTops does; a unit typechecks standalone WITH the prelude
      -- in scope. Cross-unit monomorphization clones live in the ROOT
      -- (specialize ran on the whole program above); finalTops' root
      -- portion carries them.
      let resolveUnit uts =
            let (_, _, rw) = inferTops sigs structs (preludeE ++ uts)
                bn = S.fromList ([fst3 b | b@(TBind {}) <- uts])
             in [t | t@(TBind n _ _ _) <- rw, S.member n bn]
                  ++ [t | t <- rw, not (isTBind t)]
          compileUnit uts = fst (runState (compileTop uts >>= liftFix) (DEnv 0 consAll shapes []))
          preludeExt = arities preludeE
          unitExt = M.unions [arities uts | (_, uts) <- units]
          extFor = M.union preludeExt unitExt -- own names win via prog-first lookup
          tgt = oTarget opts
          a64 = oA64 opts
          x64 = oX64 opts
          qapp = oQosApp opts
          lower | a64 = lowerA64
                | x64 && qapp = deTlsQosApp . lowerX64
                | x64 = lowerX64
                | otherwise = id
          rvv = oRvv opts && not a64 && not x64 -- no RVV lowering in the PoCs
          spec = not x64 -- SysV callee-saved registers can't host the s6+ spec loops
          tname | a64 = "a64r" ++ show a64Rev
                | x64 && qapp = "qx64r" ++ show x64Rev -- distinct cache tag: de-TLS'd units
                | x64 = "x64r" ++ show x64Rev
                | otherwise = tgtName tgt
          tag = "g" ++ show codegenRev ++ "-" ++ tname ++ (if rvv then "-rvv" else "")
          unitDir = takeDirectory out </> "units"
          emitUnit path exps ext uts = do
            cached <- doesFileExist path
            if cached
              then pure (path, "cached")
              else do
                let prog = compileUnit uts
                -- FORCE before the write: an `error` raised while the
                -- assembly is lazily produced must propagate, never
                -- leave an empty file the cache then serves as a valid
                -- compiled unit (the bbspi arity>8 incident)
                let asm = lower (emitProgram tgt rvv spec [] ext exps prog)
                length asm `seq` writeFile path asm
                pure (path, show (M.size prog) ++ " supercombinators")
      createDirectoryIfMissing True unitDir
      -- prelude unit (unqualified names; the always-linked stdlib unit).
      -- The prelude is self-contained, so resolve its own operators.
      let preludeResolved = let (_, _, rw) = inferTops sigs structs preludeE in rw
      preludeOut <-
        if null preludeTops
          then pure []
          else do
            r <- emitUnit (unitDir </> ("prelude-" ++ take 12 preludeHash ++ "-" ++ tag ++ ".s"))
                          (bindNames preludeE) M.empty preludeResolved
            pure [r]
      -- dep module units (hash-qualified; filename carries the prelude
      -- hash too -- unit code depends on prelude arities)
      unitOuts <- forM units $ \(h, uts) ->
        emitUnit (unitDir </> ("u-" ++ take 12 h ++ "-p" ++ take 8 preludeHash ++ "-" ++ tag ++ ".s"))
                 (bindNames uts) extFor (resolveUnit uts)
      -- the root: exports its own binds; modtab (all dep exports) lives
      -- here. Root codegen uses the FULLY specialized+resolved tops
      -- (finalTops), filtered to root's own names + any monomorphized
      -- clones (clones have no home unit; they ride with the root).
      let rootNames = S.fromList ([fst3 b | b@(TBind {}) <- root'])
          unitNames = S.fromList (concat [[fst3 b | b@(TBind {}) <- uts] | (_, uts) <- units])
          preludeNames = S.fromList (map fst3 [b | b@(TBind {}) <- preludeE, True])
          rootProgTops =
            [ t | t@(TBind n _ _ _) <- finalTops,
                  S.member n rootNames
                    || (not (S.member n unitNames) && not (S.member n preludeNames))
            ]
          rootProg = compileUnit rootProgTops
      writeFile out (lower (emitProgram tgt rvv spec exports extFor (bindNames root') rootProg))
      -- the link list: everything the root's image needs beyond out itself
      writeFile (out ++ ".units") (unlines (map fst (preludeOut ++ unitOuts)))
      forM_ (preludeOut ++ unitOuts) $ \(p, note) -> putStrLn ("unit " ++ p ++ " (" ++ note ++ ")")
      putStrLn ("wrote " ++ out ++ " (" ++ show (M.size rootProg) ++ " supercombinators, linearity OK)")
      when (not (null exports)) $
        putStrLn ("module table: " ++ show (length [e | e <- exports, meArity e >= 1]) ++ " remote-callable exports")
      putStrLn "assumed external symbols (the fpr_g_ HAL/runtime contract):"
      putStrLn ("  " ++ unwords (externals extFor rootProg))

fst3 :: STop -> String
fst3 (TBind n _ _ _) = n
fst3 _ = ""

isTBind :: STop -> Bool
isTBind TBind {} = True
isTBind _ = False
