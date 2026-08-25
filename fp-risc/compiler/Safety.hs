{-# LANGUAGE LambdaCase #-}
-- Safety.hs — the safe/unsafe line, drawn and ENFORCED.
--
-- The division (see docs/SAFETY.md):
--
--   UNSAFE code is code whose WCET the compiler cannot see through:
--     * implicit recursion — a custom recursive function (self or
--       mutual), as opposed to the builtin/std recursion SCHEMES
--       (Vec.map/fold, Std.fold, ...) whose bounds are the scheme's
--     * and, transitively, code that leans on such functions OUTSIDE
--       the vetted library
--
--   The RULES:
--     1. every function in a recursive SCC MUST carry an explicit
--        signature of the form   f : unsafe T1 -> T2 .
--        No inference hides recursion.  Missing marker = compile error.
--     2. calling a MARKED-unsafe function from an unmarked function is
--        itself unsafe and requires a marker — UNLESS the callee is
--        LIBRARY code (the prelude, or a use-spliced module: dotted
--        names).  The library is the vetted set: its recursive
--        internals are marked (rule 1 applies to it too — honesty),
--        but USING it is the sanctioned way to recurse, so the taint
--        stops at the library boundary.  "Core functions rather than
--        std functions" is exactly the taint this rule tracks.
--     3. safe functions need no signature and are preferred bare.
--        A function marked unsafe that the analysis finds safe gets a
--        note, not an error.
--
-- FPR_UNSAFE_SUGGEST=1 prints paste-ready signatures (with the
-- INFERRED types) for every violation, so adopting the discipline is
-- mechanical rather than archaeological.
module Safety (safetyCheck) where

import Data.Graph (SCC (..), stronglyConnComp)
import Data.List (nub)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import FPRISC

safetyCheck :: S.Set Name -> [STop] -> [(Name, String)] -> ([String], [String])
safetyCheck preludeNames tops notes = (errs, suggests)
  where
    bindNames = nub [n | TBind n _ _ _ <- tops]
    topSet = S.fromList bindNames
    markedSigs =
      S.fromList
        [ n
          | TSig n _ pres <- tops,
            any (\p -> (fst <$> p) == Just "$unsafe") pres
        ]
    -- `unsafe program.` / `unsafe module.`: the blanket marker (parsed
    -- as a $module sig).  Every bind counts as marked, and the
    -- redundant-marker nag below is silenced -- blanket IS the loose
    -- mode.  Per-function sigs remain the strict mode for library code.
    blanket = S.member "$module" markedSigs
    marked = if blanket then S.union markedSigs topSet else markedSigs
    blessed n = S.member n preludeNames || '.' `elem` n || '@' `elem` n -- module-spliced = library
    clausesOf n = [(ps, g, b) | TBind n' ps g b <- tops, n' == n]
    refs (ps, g, b) =
      let bound = S.fromList (concatMap patVars ps)
          gbound = S.union bound (S.fromList (concatMap gPatVars g))
          gPatVars (GPat p _) = patVars p
          gPatVars (GBool _) = []
          gExprs = [e | gd <- g, e <- case gd of GBool e' -> [e']; GPat _ e' -> [e']]
       in topRefs2 gbound b ++ concatMap (topRefs2 bound) gExprs
    callsOf n = nub (concatMap refs (clausesOf n))
    -- free applied top-level names (same recipe as Infer's SCC pass)
    topRefs2 bound e = [n | n <- coll bound e, S.member n topSet]
      where
        coll bs = \case
          SVar v | not (S.member v bs) -> [v]
          SApp a b -> coll bs a ++ coll bs b
          SLam ps x -> coll (bs <> S.fromList ps) x
          SBlock stmts fin -> gos bs stmts fin
          SCase s as -> coll bs s ++ concat [coll (bs <> S.fromList (patVars p)) x | (p, x) <- as]
          SBin _ a b -> coll bs a ++ coll bs b
          SProj x _ -> coll bs x
          SRec fs -> concatMap (coll bs . snd) fs
          SUpd m as -> coll bs m ++ concatMap (coll bs . snd) as
          STup es -> concatMap (coll bs) es
          SList es -> concatMap (coll bs) es
          SStrI segs -> concat [coll bs x | SegExpr x <- segs]
          _ -> []
        gos bs [] fin = coll bs fin
        gos bs (SBind n ps x : rest) fin = coll (bs <> S.fromList (n : ps)) x ++ gos (S.insert n bs) rest fin
        gos bs (SBindPat p x : rest) fin = coll bs x ++ gos (bs <> S.fromList (patVars p)) rest fin
    sccs = stronglyConnComp [(n, n, callsOf n) | n <- bindNames]
    recursive =
      S.fromList
        (concat [ns | CyclicSCC ns <- sccs]
           ++ [n | AcyclicSCC n <- sccs, n `elem` callsOf n])
    -- rule 2: taint from marked, non-library callees
    taints n = any (\g -> S.member g marked && not (blessed g)) (callsOf n)
    -- the entry point is where taint terminates: main's WCET is the
    -- program's, already the object of study (and `>` evals synthesize
    -- a main the user never wrote).  Rule 1 still applies to it.
    -- rule 1 binds where a signature can be WRITTEN: plain names.
    -- Blessed names (prelude, module-spliced, struct fields) are the
    -- library boundary -- trusted in both directions; their honesty is
    -- carried by the plain helpers that back the schemes.
    required =
      S.union
        (S.filter (not . blessed) recursive)
        (S.fromList [n | n <- bindNames, n /= "main", not (blessed n), taints n])
    violated = [n | n <- bindNames, S.member n required, not (S.member n marked)]
    why n
      | S.member n recursive = "recursive"
      | otherwise = "calls an unsafe-marked function"
    errs =
      [ n ++ " is unsafe (" ++ why n ++ ") but has no explicit `" ++ n ++ " : unsafe ...` signature"
        | n <- violated
      ]
        ++ [ n ++ " is declared unsafe but the analysis finds it safe -- drop the marker (or keep it only if the WCET is opaque for another reason)"
             | not blanket,
               n <- S.toList marked,
               not (S.member n required),
               S.member n topSet,
               not (blessed n)
           ]
    tyOf n = holed (maybe "_" id (M.lookup n (M.fromList notes)))
    -- rows aren't writable in the sig grammar: print '_' (the mono
    -- hole) for any {...} segment, balanced-brace aware
    holed [] = []
    holed ('{' : rest) = '_' : holed (dropBraces (1 :: Int) rest)
    holed (c : rest) = c : holed rest
    dropBraces 0 s' = s'
    dropBraces k ('{' : s') = dropBraces (k + 1) s'
    dropBraces k ('}' : s') = dropBraces (k - 1) s'
    dropBraces k (_ : s') = dropBraces k s'
    dropBraces _ [] = []
    suggests = [n ++ " : unsafe " ++ tyOf n ++ " ." | n <- violated]
