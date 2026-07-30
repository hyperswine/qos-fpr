# build.sol -- the FP-RISC hosted-target build driver, in Sol.
#
#   sol tools/build.sol
#
# Reads fpr.build (key=value lines) from the repo root:
#
#   prog=programs/httpd.fpr     # the .fpr to build
#   target=x64                  # x64 | a64 | a64-mac
#   out=httpd                   # output executable name
#   harts=2                     # POSIX kthread harts
#
# What it does that make doesn't:
#   - CONTENT tracking, not mtimes: the runtime archive libfpr-<t>.a
#     rebuilds only when the checksum of the runtime source set
#     changes, recorded in build/libfpr-<t>.stamp.
#   - a TRANSACTIONAL build record (build/build-report.txt exists
#     complete or not at all, even if the build is killed), while
#     progress streams live via the realtime tier (build/build.log,
#     tailable mid-build) -- the sweep.sol contrast, applied to make.
#   - one readable pipeline: fprc -> cc -> archive -> link, each step a
#     clause, each failure a report line with the failing command.
#
# PORTABILITY: everything the driver shells out to is POSIX-portable
# on purpose (cksum not md5sum, date +%s not %N) -- the Darwin
# differences live in the four target tables below, mirroring the
# Makefile's Darwin block, which is the one source of truth for them:
#   a64-mac => ctx_a64.S, cc (Apple clang), fprc --target=a64mac
#              (Mach-O syntax: _sym, @PAGE/@PAGEOFF, Darwin TLV),
#              and NO -static (Mach-O has no static libSystem; the
#              philosophy concedes libSystem the way GFX concedes Mesa).

conf = "fpr.build".
progress = "build/build.log".
report = "build/build-report.txt".

# ---- vendored string helpers (self-contained: the SDK driver depends on
# nothing outside this file + the sol binary) --------------------------------

nl = Str.fromCode 10.
pI s = case s == "" of True -> 0 | False -> Str.parse s.
not2 a = case a of True -> False | False -> True.
substr s i j = case i > j of True -> "" | False -> "{Str.fromCode (Str.at s i)}{substr s (i + 1) j}".
findCh c s i = case i > Str.len s of True -> 0 | False -> (case Str.at s i == c of True -> i | False -> findCh c s (i + 1)).
splitCh c s | s == "" = [].
splitCh c s =
  k = findCh c s 1;
  case k of
    0 -> [s]
  | _ -> substr s 1 (k - 1) :: splitCh c (substr s (k + 1) (Str.len s)).
append2 xs ys = case xs of [] -> ys | x :: r -> x :: append2 r ys.

# ---- config ---------------------------------------------------------------

cfgLines u = filter (fn l -> not2 (l == "")) (splitCh 10 (readPath conf)).
cfgGet key dflt =
  hits = filter (fn l -> keyOf l == key) (cfgLines Unit);
  case hits of [] -> dflt | l :: _ -> valOf l.
keyOf l = case splitCh 61 l of k :: _ -> k | [] -> "".
valOf l = case splitCh 61 l of _ :: v :: _ -> v | _ -> "".

# ---- the target tables (mirror the Makefile's arch/Darwin blocks) ---------
# "a64-mac" is a64 hardware: same context switch, same runtime C. The
# THREE things that differ are the assembler syntax (fprc target
# a64mac), the compiler driver (Apple cc), and static linking (none).

isA64 tgt = case tgt == "a64" of True -> True | False -> tgt == "a64-mac".

coreSrcs u =
  ["runtime/core/runtime.c", "runtime/core/actors.c", "runtime/core/bits.c",
   "runtime/core/vec.c", "runtime/core/mod.c", "runtime/core/sstr.c",
   "runtime/core/buddy.c"].
posixSrcs tgt =
  ctx = case isA64 tgt of True -> "runtime/posix/ctx_a64.S" | False -> "runtime/posix/ctx_x64.S";
  ["runtime/posix/hal.c", "runtime/posix/main.c", "runtime/posix/stubs.c",
   "runtime/posix/net.c", "runtime/posix/net_raw.c", "runtime/posix/heap.S", ctx].

ccFor tgt = case tgt of
  "a64" -> "aarch64-linux-gnu-gcc"
| "a64-mac" -> "cc"
| _ -> "gcc".

fprTgt tgt = case tgt of
  "a64-mac" -> "a64mac"
| _ -> tgt.

staticFor tgt = case tgt of
  "a64-mac" -> ""
| _ -> "-static".

joinSp xs = case xs of [] -> "" | x :: r -> (case r of [] -> x | _ -> "{x} {joinSp r}").

# ---- steps ----------------------------------------------------------------

say s = u = appendNow progress "{s}{nl}"; print s.

step name cmd = (rc, out) = sh cmd; stepRes name cmd rc out.
stepRes name cmd rc out | rc == 0 = u = say "  ok  {name}"; out.
stepRes name cmd rc out =
  u1 = say "  FAIL {name}: {cmd}";
  u2 = say out;
  error "build failed at {name}".

# content stamp of a source set. cksum, not md5sum: md5sum does not
# exist on macOS (it is `md5 -q` there); cksum is POSIX and on both.
stampOf srcs =
  (rc, out) = sh "cat {joinSp srcs} | cksum | cut -d' ' -f1";
  trim out.

# the runtime archive: rebuilt only when the source-set content changes
ensureLib tgt harts =
  srcs = append2 (coreSrcs Unit) (posixSrcs tgt);
  want = stampOf srcs;
  lib = "build/libfpr-{tgt}.a";
  stampF = "build/libfpr-{tgt}.stamp";
  have = readPathOr stampF "";
  libCheck tgt harts srcs want lib stampF have.

libCheck tgt harts srcs want lib stampF have | have == want =
  u = say "  ok  libfpr-{tgt}.a (content unchanged, {want})";
  lib.
libCheck tgt harts srcs want lib stampF have = buildLib tgt harts srcs want lib stampF.

buildLib tgt harts srcs want lib stampF =
  cc = ccFor tgt;
  u1 = say "  ..  libfpr-{tgt}.a: runtime content changed -> rebuilding";
  u2 = step "compile runtime" "{cc} -O2 -Wall -DFPR_POSIX -DFPR_NHARTS={harts} -Iruntime/core -c {joinSp srcs} 2>&1";
  u3 = step "archive" "ar rcs {lib} *.o && rm -f *.o";
  u4 = writePath stampF want;
  lib.

readPathOr p dflt = case exists p of True -> readPath p | False -> dflt.

# ---- main -----------------------------------------------------------------

> (rc0, o0) = sh "mkdir -p build";
  u1 = writeNow progress "";
  prog = cfgGet "prog" "tests/hello.fpr";
  tgt = cfgGet "target" "x64";
  out = cfgGet "out" "app";
  harts = cfgGet "harts" "2";
  t0 = shOut "date +%s";
  u2 = say "fpr build: {prog} -> {out} (target {tgt}, {harts} hart(s))";

  # 1. the compiler itself (SDK installs ship it prebuilt; in-repo we
  #    bootstrap it once -- via cabal.project on a Mac, ghc elsewhere)
  u3 = ensureFprc Unit tgt;

  # 2. runtime archive (cached by content)
  lib = ensureLib tgt harts;

  # 3. program: fprc -> .s (+ its module units)
  u4 = step "fprc {prog}" "LC_ALL=C.UTF-8 ./fprc --target={fprTgt tgt} --prelude=programs/prelude.fpr {prog} build/app-{tgt}.s 2>&1";
  units = trim (readPathOr "build/app-{tgt}.s.units" "");

  # 4. link: program + units + archive -> one executable (static where
  #    the platform allows; on a Mac, one file over libSystem)
  cc = ccFor tgt;
  u5 = step "link {out}" "{cc} {staticFor tgt} -O2 -DFPR_POSIX -DFPR_NHARTS={harts} -Iruntime/core build/app-{tgt}.s {units} {lib} -lpthread -o {out} 2>&1";

  t1 = shOut "date +%s";
  secs = pI (trim t1) - pI (trim t0);
  u6 = say "  ok  {out} built in {secs} s";
  u7 = writePath report "fpr build report{nl}prog={prog}{nl}target={tgt}{nl}out={out}{nl}libstamp={stampOf (append2 (coreSrcs Unit) (posixSrcs tgt))}{nl}elapsed_s={secs}{nl}";
  print "report -> {report}".

shOut c = (rc, out) = sh c; out.

# SDK installs ship fprc prebuilt; in-repo bootstrap:
#   - Mac: cabal.project builds fprc (and sol). --installdir=. drops
#     the binary as ./fprc directly -- do NOT install to ~/.local/bin
#     and prelude-`mv` it here: the prelude mv is TRANSACTIONAL
#     (buffered until commit), so ./fprc would not exist on disk when
#     step 3 runs it mid-transaction. If a copy IS needed, it must be
#     `sh "mv ..."` (immediate), never the buffered mv.
#   - elsewhere: plain ghc, no cabal needed.
ensureFprc u tgt | exists "fprc" = say "  ok  fprc (present)".
ensureFprc u tgt | tgt == "a64-mac" =
  u1 = step "bootstrap fprc (cabal)" "cabal install exe:fprc --installdir=. --overwrite-policy=always --install-method=copy 2>&1";
  Unit.
ensureFprc u tgt =
  u1 = step "bootstrap fprc" "ghc -O1 -icompiler -o fprc compiler/Main.hs 2>&1";
  Unit.

# strip trailing whitespace/newlines (harness.sol idiom)
trim s = trimGo s (Str.len s).
trimGo s n | n == 0 = "".
trimGo s n | Str.at s n <= 32 = trimGo s (n - 1).
trimGo s n = substr s 1 n.
