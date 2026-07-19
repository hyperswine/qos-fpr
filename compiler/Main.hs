module Main where

import Codegen (Target, codegenRev, emitProgram, externals, rv32, rv64, tgtName)
import Control.Monad (forM, forM_, unless, when)
import Control.Monad.State.Strict (runState)
import Data.List (isPrefixOf)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import FPRISC
import Modules (LoadResult (..), ModExport (..), hashAST, loadProgram)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.FilePath (takeDirectory, (</>))
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import Text.Megaparsec (errorBundlePretty, parse)

data Opts = Opts
  { oTarget :: Target,
    oRvv :: Bool,
    oPrelude :: Maybe FilePath,
    oFiles :: [FilePath]
  }

parseArgs :: [String] -> Opts
parseArgs = foldl step (Opts rv64 False Nothing [])
  where
    step o "--target=rv32" = o {oTarget = rv32}
    step o "--target=rv64" = o {oTarget = rv64}
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
    _ -> putStrLn "usage: fprc [--target=rv32|rv64] [--rvv] [--prelude=FILE] <in.fpr> <out.s>" >> exitFailure >> pure ("", "")
  preludeTops <- maybe (pure []) parseFile (oPrelude opts)
  rootTops <- parseFile inp
  lr <- loadProgram preludeTops inp rootTops
  case lr of
    Left e -> putStrLn e >> exitFailure
    Right (LoadResult tops exports notes units root' rootHash) -> do
      mapM_ putStrLn notes
      -- ---- whole-program ANALYSES (cheap; codegen below is per-unit) ----
      let preludeHash = hashAST preludeTops
          -- content-addressed cons: every unit's types under ITS hash;
          -- both sides of a `use` compute the same ids from the same AST.
          consAll =
            M.unions
              ( collectCons preludeHash preludeTops
                  : collectCons rootHash root'
                  : [collectCons h uts | (h, uts) <- units]
              )
          shapes = collectShapes tops -- structural fnv ids: globally consistent
          -- tid collision check (fnv32 is probabilistic; fail LOUDLY)
          tidDecls =
            [ (t, ownerT ++ "." ++ n)
              | (ownerT, ownerH, uts) <-
                  ("prelude", preludeHash, preludeTops)
                    : ("root", rootHash, root')
                    : [(take 12 h, h, uts) | (h, uts) <- units],
              TType n _ _ <- uts,
              let t = tidFor ownerH n
            ]
          li = buildLinInfo tops
          lerrs = lcheck li tops
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
      let compileUnit uts = fst (runState (compileTop uts >>= liftFix) (DEnv 0 consAll shapes []))
          preludeExt = arities preludeTops
          unitExt = M.unions [arities uts | (_, uts) <- units]
          extFor = M.union preludeExt unitExt -- own names win via prog-first lookup
          tgt = oTarget opts
          rvv = oRvv opts
          tag = "g" ++ show codegenRev ++ "-" ++ tgtName tgt ++ (if rvv then "-rvv" else "")
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
                let asm = emitProgram tgt rvv [] ext exps prog
                length asm `seq` writeFile path asm
                pure (path, show (M.size prog) ++ " supercombinators")
      createDirectoryIfMissing True unitDir
      -- prelude unit (unqualified names; the always-linked stdlib unit)
      preludeOut <-
        if null preludeTops
          then pure []
          else do
            r <- emitUnit (unitDir </> ("prelude-" ++ take 12 preludeHash ++ "-" ++ tag ++ ".s"))
                          (bindNames preludeTops) M.empty preludeTops
            pure [r]
      -- dep module units (hash-qualified; filename carries the prelude
      -- hash too -- unit code depends on prelude arities)
      unitOuts <- forM units $ \(h, uts) ->
        emitUnit (unitDir </> ("u-" ++ take 12 h ++ "-p" ++ take 8 preludeHash ++ "-" ++ tag ++ ".s"))
                 (bindNames uts) extFor uts
      -- the root: exports its own binds; modtab (all dep exports) lives here
      let rootProg = compileUnit root'
      writeFile out (emitProgram tgt rvv exports extFor (bindNames root') rootProg)
      -- the link list: everything the root's image needs beyond out itself
      writeFile (out ++ ".units") (unlines (map fst (preludeOut ++ unitOuts)))
      forM_ (preludeOut ++ unitOuts) $ \(p, note) -> putStrLn ("unit " ++ p ++ " (" ++ note ++ ")")
      putStrLn ("wrote " ++ out ++ " (" ++ show (M.size rootProg) ++ " supercombinators, linearity OK)")
      when (not (null exports)) $
        putStrLn ("module table: " ++ show (length [e | e <- exports, meArity e >= 1]) ++ " remote-callable exports")
      putStrLn "assumed external symbols (the fpr_g_ HAL/runtime contract):"
      putStrLn ("  " ++ unwords (externals extFor rootProg))
