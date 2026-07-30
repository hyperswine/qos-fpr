# SDK.md — FP-RISC as a standalone hosted toolchain

The question: what does it take to `fpr build myapp.fpr` on a stock
x86-64 Linux or arm64 macOS box, without this repo's Makefile ritual —
while KEEPING the property that the output is one static executable
(the isolation/reliability/reproducibility property is the point; the
packaging is what needed work, not the linking model).

## What "standalone" actually requires

An installed toolchain directory is four things:

    fpr-sdk/
      bin/fprc              the compiler (one GHC-built binary; no
                            Haskell toolchain on the target machine)
      bin/sol               the driver host (ditto)
      runtime/              the C sources (core/ + posix/), ~15 files
      programs/prelude.fpr  the prelude
      tools/build.sol       the driver

Host prerequisites: a C compiler and `ar`. Nothing else — no make, no
cabal, no ghc. The Haskell part is "bundled" the same way any compiler
is: as a prebuilt binary per host platform. fprc has no runtime
Haskell dependencies beyond what GHC links in, so the per-platform
build is `ghc -O1 -icompiler -o fprc compiler/Main.hs` on a machine of
that platform, once, at SDK release time.

## The driver: tools/build.sol (the make replacement, in Sol)

`sol tools/build.sol` reads `fpr.build` (key=value: prog / target /
out / harts) and runs the whole pipeline:

    fprc -> .s (+ module units) -> cc -> link against libfpr-<t>.a

Verified in-tree: built programs/httpd.fpr to a static `httpd` that
served /status live; warm rebuild 1.0s vs 3.1s cold; changing two
config lines cross-built tests/sched.fpr for a64 and it ran green
under qemu-aarch64.

What it does that make didn't:

- **Content tracking, not mtimes.** libfpr-<target>.a rebuilds only
  when the md5 of the runtime source SET changes (stamp recorded in
  build/libfpr-<t>.stamp). Touching files does nothing; changing one
  byte rebuilds. This is the precompiled-runtime answer to "compile
  any .fpr on the fly": the runtime compiles once per (target, harts),
  after which a program build is fprc + one cc invocation.
- **The sweep.sol contrast, applied to builds:** progress streams live
  through the realtime tier (build/build.log, tailable mid-build),
  while build/build-report.txt is written transactionally — it exists
  complete or not at all, even if the build is killed.
- **Self-contained:** the driver vendors its own string helpers and
  depends on nothing but the sol binary — an SDK file, not a repo file.

Migration path from make, honestly staged: build.sol now owns the
hosted-target program builds (the thing an SDK user does daily). The
Makefile still owns the bare-metal QEMU matrix, procapps/disk imaging,
and the test harness — those migrate function by function as build.sol
grows verbs (`test`, `image`, `qa`), each one a Sol clause replacing a
make recipe, until make is a thin `make x: ; sol tools/build.sol x`
shim and then nothing.

## The two platforms named

**x86-64 Linux — done.** Everything above is verified on it. `-static`
against glibc; musl is the known upgrade for truly-portable binaries.

**arm64 macOS — the pieces exist, one leg unverified.** fprc's qa64/
a64mac lowering is assembled-verified; clang assembles the emitted .s
and is the linker; the ctx switch and adrp-based deTLS were built for
exactly this. Differences the driver will absorb when a real Mac is in
the loop: no `-static` (Apple forbids static libSystem — the binary is
still self-contained in the sense that matters: one file, only
libSystem underneath), `ar` -> `libtool -static` or plain ar both
work, and Mach-O symbol naming (leading underscore) is already handled
by the a64mac emitter. That first-real-Mac session is the same
smoke-script plan already on the books for qosp.

## What this deliberately does NOT change

No dynamic loading, no shared libfpr.so, no compile-server daemon. The
one-static-executable model IS the reproducibility story ("if it
compiles it works", Nix-flake-like, isolation at build time). The SDK
makes producing that artifact one command on a fresh machine; it does
not soften the artifact.
