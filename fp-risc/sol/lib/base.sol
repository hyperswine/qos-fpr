# base.sol — the base library.  Most of what lived here is now PRELUDE
# (Str.*, List.*, and/or/not): each name below is a thin alias kept so
# older scripts keep running, and its body names the builtin to reach
# for instead.  New code should use the builtin directly.

pI s = case s == "" of True -> 0 | False -> Str.parse s.   # or Try.parseInt on the rails
and2 a b = and a b.
or2 a b = or a b.
not2 a = not a.
max0 n = Numeric.max 0 n.
boolInt b = case b of True -> 1 | False -> 0.
nl = Str.fromCode 10.

takeN n xs = List.take n xs.
listLen xs = List.len xs.

removeAt k xs | xs == [] = [].
removeAt k xs = case xs of
  x :: r -> (case k == 1 of True -> r | False -> x :: removeAt (k - 1) r).

# string helpers: inclusive slice, char search, split -- all Str.* now
substr s i j = Str.slice s i j.
findCh c s i = Str.findFrom c s i.
findSp s i = Str.findFrom 32 s i.
splitFirst s = k = findSp s 1; case k of 0 -> (s, "") | _ -> (Str.slice s 1 (k - 1), Str.slice s (k + 1) (Str.len s)).
splitCh c s = Str.split c s.

imod2 a b = Numeric.mod a b.

# last path segment
baseName p =
  k = lastSlash p 1 0;
  case k == 0 of True -> p | False -> Str.slice p (k + 1) (Str.len p).
lastSlash p i best | i > Str.len p = best.
lastSlash p i best = case Str.at p i == 47 of True -> lastSlash p (i + 1) i | False -> lastSlash p (i + 1) best.
