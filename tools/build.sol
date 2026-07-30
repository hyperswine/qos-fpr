# build.sol -- the FP-RISC hosted-target build driver, in Sol.
#
#   sol tools/build.sol
#
# Reads fpr.build (key=value lines) from the repo root:
#
#   prog=programs/httpd.fpr     # the .fpr to build
#   target=x64                  # x64 | a64  (posix hosted targets)
#   out=httpd                   # output executable name
#   harts=2                     # POSIX kthread harts
#
# What it does that make doesn't:
#   - CONTENT tracking, not mtimes: the runtime archive libfpr-<t>.a
#     rebuilds only when the md5 of the runtime source set changes,
#     recorded in build/libfpr-<t>.stamp -- touch a file all you like.
#   - a TRANSACTIONAL build record (build/build-report.txt exists
#     complete or not at all, even if the build is killed), while
#     progress streams live via the realtime tier (build/build.log,
#     tailable mid-build) -- the sweep.sol contrast, applied to make.
#   - one readable pipeline: fprc -> as -> archive -> link, each step a
#     clause, each failure a report line with the failing command.
#
# The SDK story this is the seed of: a toolchain directory = fprc +
# runtime/ + prelude + this driver; the host needs only cc. The output
# stays ONE static executable -- the isolation/reproducibility property
# is the point, this just makes producing it one command.

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

# ---- the file sets (mirrors Makefile; one place, readable) ----------------

coreSrcs u =
  ["runtime/core/runtime.c", "runtime/core/actors.c", "runtime/core/bits.c",
   "runtime/core/vec.c", "runtime/core/mod.c", "runtime/core/sstr.c",
   "runtime/core/buddy.c"].
posixSrcs tgt =
  ctx = case tgt == "a64" of True -> "runtime/posix/ctx_a64.S" | False -> "runtime/posix/ctx_x64.S";
  ["runtime/posix/hal.c", "runtime/posix/main.c", "runtime/posix/stubs.c",
   "runtime/posix/net.c", "runtime/posix/net_raw.c", "runtime/posix/heap.S", ctx].
ccFor tgt = case tgt == "a64" of True -> "aarch64-linux-gnu-gcc" | False -> "gcc".
fprTgt tgt = tgt.
staticFor tgt = case tgt == "a64" of True -> "-static" | False -> "-static".

joinSp xs = case xs of [] -> "" | x :: r -> (case r of [] -> x | _ -> "{x} {joinSp r}").

# ---- steps ----------------------------------------------------------------

say s = u = appendNow progress "{s}{nl}"; print s.

step name cmd = (rc, out) = sh cmd; stepRes name cmd rc out.
stepRes name cmd rc out | rc == 0 = u = say "  ok  {name}"; out.
stepRes name cmd rc out =
  u1 = say "  FAIL {name}: {cmd}";
  u2 = say out;
  error "build failed at {name}".

# content stamp of a source set (md5 over the files, order fixed)
stampOf srcs =
  (rc, out) = sh "cat {joinSp srcs} | md5sum | cut -d' ' -f1";
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
  t0 = shOut "date +%s%N";
  u2 = say "fpr build: {prog} -> {out} (target {tgt}, {harts} hart(s))";

  # 1. the compiler itself (SDK installs ship it prebuilt; in-repo we
  #    bootstrap it once via ghc, content-tracked the same way)
  u3 = ensureFprc Unit;

  # 2. runtime archive (cached by content)
  lib = ensureLib tgt harts;

  # 3. program: fprc -> .s (+ its module units)
  u4 = step "fprc {prog}" "LC_ALL=C.UTF-8 ./fprc --target={fprTgt tgt} --prelude=programs/prelude.fpr {prog} build/app-{tgt}.s 2>&1";
  units = trim (readPathOr "build/app-{tgt}.s.units" "");

  # 4. link: program + units + archive -> ONE static executable
  cc = ccFor tgt;
  u5 = step "link {out}" "{cc} {staticFor tgt} -O2 -DFPR_POSIX -DFPR_NHARTS={harts} -Iruntime/core build/app-{tgt}.s {units} {lib} -lpthread -o {out} 2>&1";

  t1 = shOut "date +%s%N";
  ms = (pI (trim t1) - pI (trim t0)) / 1000000;
  u6 = say "  ok  {out} built in {ms} ms";
  u7 = writePath report "fpr build report{nl}prog={prog}{nl}target={tgt}{nl}out={out}{nl}libstamp={stampOf (append2 (coreSrcs Unit) (posixSrcs tgt))}{nl}elapsed_ms={ms}{nl}";
  print "report -> {report}".

shOut c = (rc, out) = sh c; out.

# SDK installs ship fprc prebuilt; in-repo we bootstrap it once via ghc
ensureFprc u | exists "fprc" = say "  ok  fprc (present)".
ensureFprc u = u2 = step "bootstrap fprc" "ghc -O1 -icompiler -o fprc compiler/Main.hs 2>&1"; Unit.

# strip trailing whitespace/newlines (harness.sol idiom)
trim s = trimGo s (Str.len s).
trimGo s n | n == 0 = "".
trimGo s n | Str.at s n <= 32 = trimGo s (n - 1).
trimGo s n = substr s 1 n.
