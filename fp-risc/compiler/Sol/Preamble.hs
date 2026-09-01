-- Preamble.hs — the auto-provided std surface (prelude source) and the
-- HAL symbol/arity table. Extracted from Main so tooling (property tests,
-- future REPL) can drive the exact same pipeline in-process.

module Sol.Preamble (prelude, halArities) where

import qualified Data.Map.Strict as M
import Sol.Lang (Name)

-- ---- the auto-provided std surface -----------------------------------------
-- Injected before every script: Path + linear Handle types, and the file API
-- signatures the linearity checker enforces. readPath/writePath are ordinary
-- Sol code written against the linear API — the prelude eats its own cooking.
prelude :: String
prelude =
  unlines
    [ "Path = Type (Path String).",
      "Handle 1 = Type (Handle Int).",
      -- Io: the structured intents `write`/`read` decode. Effects (Dir, Rm,
      -- RmDir) are written TO a path; queries (Ls, Stat, Exists, IsDir, Sh)
      -- carry their path/command and are read FROM. Everything below the
      -- handle quartet is ordinary Sol code over read/write — the HAL's
      -- whole outside-world surface is those two symbols plus the handles.
      -- Now* are the REALTIME intents: they leave the transaction. They are
      -- spelled separately from their transactional twins on purpose, so a
      -- reader can see at the call site that atomicity was given up, and so
      -- the compiler can count them and say so.
      "Io = Type (Dir | Rm | RmDir | Ls x | Stat x | Exists x | IsDir x | Sh x",
      "         | Now x | NowSet x | NowAdd x | NowSh x | NowLine).",
      "open : String -> Handle.",
      "readAll : Handle -> (String, Handle).",
      "writeAll : Handle -> String -> Handle.",
      "close : Handle -> Unit.",
      -- ---- the Ok/Err default pattern -------------------------------------
      -- Fallible work returns `Ok x | Err msg` and chains with |>?. The
      -- HAL's fallible primitives are the Try.* family; the PANICKING
      -- spellings below are one `unwrap` away — sugar over the honest
      -- tier, not a separate mechanism. `readPath` of a missing file is
      -- therefore a PANIC now (absence is not ""): reach for exists,
      -- readPathOr, or Try.readPath when absence is an expected case.
      -- The combinators a railway actually needs, so that every script
      -- does not reinvent them slightly differently. All of them are
      -- ordinary Sol over the same two constructors -- the prelude eats
      -- its own cooking here as it does for readPath.
      --   consume:  unwrap (insist)  okOr (default)
      --   stay on:  mapOk (value)    andThen / |>? (fallible step)
      --   recover:  orElse (fallback)
      --   report:   mapErr, context (add a label to the failure)
      --   gather:   collect (List of Results -> Result of List)
      "unwrap r = case r of Ok x -> x | Err e -> error e.",
      "okOr d r = case r of Ok x -> x | Err e -> d.",
      "mapOk f r = case r of Ok x -> Ok (f x) | Err e -> Err e.",
      "andThen f r = case r of Ok x -> f x | Err e -> Err e.",
      "mapErr f r = case r of Ok x -> Ok x | Err e -> Err (f e).",
      "orElse alt r = case r of Ok x -> Ok x | Err e -> alt.",
      "context label r = mapErr (fn e -> \"{label}: {e}\") r.",
      "isOk r = case r of Ok x -> True | Err e -> False.",
      -- the first Err wins and stops the walk; all Ok gives the values in
      -- order (the traverse a script reaches for when parsing many lines)
      "collect rs = foldl collectStep (Ok []) rs.",
      "collectStep acc r = case acc of Err e -> Err e | Ok xs -> (case r of Ok x -> Ok (List.append xs [x]) | Err e -> Err e).",
      "parseInt s = unwrap (Try.parseInt s).",
      "readPath p = unwrap (Try.readPath p).",
      "readPathOr d p = okOr d (Try.readPath p).",
      "writePath p s = write p s.",
      "mkdirp p = write p Dir.",
      "rm p = write p Rm.",
      "rmdir p = write p RmDir.",
      "mv a b = s = read a; u = write b s; write a Rm.",
      "ls p = read (Ls p).",
      "stat p = read (Stat p).",
      "exists p = read (Exists p).",
      "isDir p = read (IsDir p).",
      "sh c = read (Sh c).",
      "shq c = write \"/dev/sh\" c.",
      "print v = write \"/dev/out\" v.",
      "input u = read \"/dev/in\".",
      "sleepMs n = write \"/dev/clock\" n.",
      "fuelPreempts u = read \"/dev/fuel\".",
      -- ---- realtime escapes: NOT the default, see Txn.hs ----
      -- readNow   : re-reads the disk, so a poll loop can observe change
      -- writeNow  : lands on disk immediately, survives a rollback
      -- appendNow : same, appending — progress logs you can tail
      -- shNow     : streams a command's output live, returns the exit code
      -- readLineNow : one line of stdin, now, for prompts
      -- Transactional twins to prefer: readPath, writePath, sh/shq, input.
      -- ---- BStr: the fast byte-buffer string variant ----
      -- Declared LINEAR (BStr 1) for the same reason Vector is: in-place
      -- mutation is only sound when there's exactly one owner. Every op
      -- threads the buffer and returns it; BStr.toStr consumes it.
      -- Use for: append-heavy builders, index-heavy scanning, any string
      -- work that scales with input size rather than staying tiny.
      -- Use VStr (the default) for: filenames, status text, numbers, anything
      -- short that you build once and read a few times.
      "BStr 1 = Type (BStr Int).",
      "BStr.new : Unit -> BStr.",
      "BStr.fromStr : String -> BStr.",
      "BStr.toStr : BStr -> String.",
      "BStr.append : String -> BStr -> BStr.",
      "BStr.cat : a -> a -> a.",
      -- Interrogation THREADS the buffer, exactly like Vec.len / Vec.get:
      -- a linear value must be handed back or it cannot be used again.
      "BStr.len : BStr -> (Int, BStr).",
      "BStr.at : BStr -> Int -> (Int, BStr).",
      "BStr.sub : BStr -> Int -> Int -> (BStr, BStr).",
      "BStr.free : BStr -> Unit.",
      -- Structured processes use raw argv, never shell parsing. Empty cwd
      -- inherits the script's cwd; env entries override inherited values;
      -- timeoutMs <= 0 means no timeout.
      "ProcessSpec = Type (ProcessSpec (List String) String (List (String, String)) String Int).",
      "ProcessResult = Type (ProcessResult Int String String).",
      "Proc.query : ProcessSpec -> Result ProcessResult String.",
      "Proc.afterCommit : ProcessSpec -> Unit.",
      "Proc.runNow : ProcessSpec -> Result ProcessResult String.",
      "readNow p = read (Now p).",
      "writeNow p s = write p (NowSet s).",
      "appendNow p s = write p (NowAdd s).",
      "shNow c = read (NowSh c).",
      "readLineNow u = read NowLine.",
      "Vector 1 = Type (Vector Int).",
      "Vec.new : Unit -> Vector.",
      "Vec.range : Int -> Int -> Vector.",
      "Vec.mmul : Int -> Int -> Int -> Vector -> Vector -> (Vector, Vector, Vector).",
      "Vec.push : a -> Vector -> Vector.",
      "Vec.len : Vector -> (Int, Vector).",
      "Vec.get : Int -> Vector -> (a, Vector).",
      "Vec.set : Int -> a -> Vector -> Vector.",
      "Vec.map : (a -> b) -> Vector -> Vector.",
      "Vec.filter : (a -> Bool) -> Vector -> Vector.",
      "Vec.fold : (b -> a -> b) -> b -> Vector -> (b, Vector).",
      "Vec.toList : Vector -> List a.",
      "Vec.fromList : List a -> Vector.",
      "Vec.free : Vector -> Unit.",
      "Module = Type (Module Int).",
      "use : String -> Module.",
      "run : Module -> a -> String.",
      "View.serve : Int -> (a -> b) -> (c -> b -> e) -> (b -> d) -> f -> Unit.",
      "Persistent = Type (Persistent x).",
      "Cmd = Type (None | Print x | ReadFile x y | Rng x y z | Batch x | Put x y | Get x y | Msg x y).",
      -- ---- stdlib: sigs are rows, structures implement them ----
      -- Add is the monoid-ish slice (Numeric, Str, List); Arith is the
      -- full numeric row. Structural rows mean Numeric : Arith ALSO
      -- satisfies Add at call sites without declaring it.
      "Add = Sig { (+) : t -> t -> t, zero : t }.",
      "Arith = Sig { (+) : t -> t -> t, (-) : t -> t -> t, (*) : t -> t -> t, (/) : t -> t -> t, zero : t }.",
      "Functor = Sig { map : (a -> b) -> t a -> t b }.",
      "StreamOps = Sig { filter : (a -> Bool) -> t a -> t a, fold : (b -> a -> b) -> b -> t a -> b, find : (a -> Bool) -> t a -> t a, any : (a -> Bool) -> t a -> Bool, all : (a -> Bool) -> t a -> Bool }.",
      "Numeric = Struct Arith {",
      "  (+) = fn a b -> a + b,",
      "  (-) = fn a b -> a - b,",
      "  (*) = fn a b -> a * b,",
      "  (/) = fn a b -> a / b,",
      "  zero = 0,",
      "  abs = fn a -> case a < 0 of True -> 0 - a | False -> a,",
      "  max = fn a b -> case a > b of True -> a | False -> b,",
      "  min = fn a b -> case a < b of True -> a | False -> b,",
      "  clamp = fn lo hi a -> Numeric.min hi (Numeric.max lo a),",
      "  mod = fn a b -> a - (a / b) * b,",
      -- the inexact tier: div is TRUE division (1 `div` 2 = 0.5); sqrt,
      -- floor, round complete the surface. Plain +,-,*,< work on the
      -- results directly — inexactness propagates by promotion, and a
      -- computation landing back on an integer renders as one.
      "  div = fn a b -> Num.div a b,",
      "  sqrt = fn a -> Num.sqrt a,",
      "  floor = fn a -> Num.floor a,",
      "  round = fn a -> Num.round a,",
      "  inexact = fn a -> Num.div a 1,",
      "  neg = fn a -> 0 - a",
      "}.",
      "Str = Struct Add {",
      "  (+) = fn a b -> strcat a b,",
      "  zero = \"\",",
      "  len = fn s -> strlen s,",
      "  cat = fn a b -> strcat a b,",
      "  at = fn s i -> charAt s i,",
      "  fromCode = fn c -> chr c,",
      "  parse = fn s -> parseInt s",
      "}.",
      "List = Struct Add Functor StreamOps {",
      "  (+) = fn a b -> List.append a b,",
      "  zero = [],",
      "  append = fn a b -> case a of Nil -> b | x :: rest -> x :: (List.append rest b),",
      "  map = fn f xs -> map f xs,",
      "  filter = fn p xs -> filter p xs,",
      "  fold = fn f z xs -> foldl f z xs,",
      "  find = fn p xs -> case filter p xs of Nil -> [] | x :: rest -> [x],",
      "  any = fn p xs -> case filter p xs of Nil -> False | _ -> True,",
      "  all = fn p xs -> case filter (fn x -> case p x of True -> False | False -> True) xs of Nil -> True | _ -> False,",
      "  len = fn xs -> foldl (fn n x -> n + 1) 0 xs,",
      "  rev = fn xs -> foldl (fn acc x -> x :: acc) [] xs,",
      "  gen = fn n f -> List.genGo 0 n f,",
      "  genGo = fn i n f -> case i >= n of True -> [] | False -> f i :: List.genGo (i + 1) n f,",
      "  genS = fn s n f -> case n == 0 of True -> (s, []) | False -> (case f s of (s2, x) -> (case List.genS s2 (n - 1) f of (s3, xs) -> (s3, x :: xs))),",
      "  groupby = fn f xs -> foldl (fn acc x -> List.gbIns (f x) x acc) [] xs,",
      "  gbIns = fn k x g -> case g of Nil -> [(k, [x])] | p :: rest -> (case p of (kk, vs) -> (case kk == k of True -> (kk, List.append vs [x]) :: rest | False -> p :: (List.gbIns k x rest)))",
      "}."
    ]

-- HAL symbols + arities the bytecode compiler may emit saturated HCALLs for
halArities :: M.Map Name Int
halArities =
  M.fromList
    [ ("str", 1), ("strcat", 2), ("String.len", 1), ("strlen", 1),
      ("error", 1), ("Try.parseInt", 1), ("Try.readPath", 1),
      ("charAt", 2), ("chr", 1), ("substr", 3), ("!", 2),
      ("open", 1), ("readAll", 1), ("writeAll", 2), ("close", 1),
      ("BStr.new", 1), ("BStr.fromStr", 1), ("BStr.toStr", 1),
      ("BStr.append", 2), ("BStr.cat", 2), ("BStr.len", 1),
      ("BStr.at", 2), ("BStr.sub", 3), ("BStr.free", 1),
      ("Proc.query", 1), ("Proc.afterCommit", 1), ("Proc.runNow", 1),
      ("read", 1), ("write", 2),
      ("myself", 1), ("spawn", 1), ("send", 2), ("sendLinear", 2), ("sendArc", 2), ("receive", 1), ("receiveFrom", 2),
      ("kill", 1), ("yield", 1), ("drop", 1), ("keep", 1), ("device", 1), ("reg32", 2),
      ("Sys.poolReset", 1), ("Sys.sleepUs", 1), ("Sys.logAt", 2), ("Sys.memStats", 1),
      ("Num.div", 2), ("Num.sqrt", 1), ("Num.floor", 1), ("Num.round", 1),
      ("map", 2), ("filter", 2), ("foldl", 3),
      ("Vec.new", 1), ("Vec.range", 2), ("Vec.mmul", 5), ("Vec.push", 2), ("Vec.len", 1), ("Vec.get", 2),
      ("Vec.set", 3), ("Vec.map", 2), ("Vec.filter", 2), ("Vec.fold", 3),
      ("Vec.toList", 1), ("Vec.fromList", 1), ("Vec.free", 1),
      ("use", 1), ("run", 2), ("View.serve", 5)
    ]
