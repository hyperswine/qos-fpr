#!/bin/sh
# mac-smoke.sh -- first-boot verification of the QOS posix HAL on macOS
# (Apple Silicon).  Run from the repo root on an arm64 Mac:
#
#     sh tools/mac-smoke.sh
#
# Needs: GHC 9.4+ (ghcup or `brew install ghc cabal-install`), Xcode CLT
# (clang/cc).  No qemu, no cross toolchain: the a64mac target is native.
set -e

echo "== host"
uname -sm
case "$(uname -sm)" in
  "Darwin arm64") ;;
  *) echo "note: expected 'Darwin arm64'; continuing anyway" ;;
esac

echo "== fprc"
# [ -x ./fprc ] || (cd compiler && ghc -O1 -o ../fprc Main.hs)

	echo "== heap layout (Mach-O .zerofill ordering: end must be start + 256 MiB)"
cc -c runtime/posix/heap.S -o /tmp/qos-heap.o
nm -n /tmp/qos-heap.o | grep -E "_heap|_proc_arena"
START=$(nm /tmp/qos-heap.o | awk '/__heap_start/{print "0x"$1}')
END=$(nm /tmp/qos-heap.o | awk '/__heap_end/{print "0x"$1}')
[ $((END - START)) -eq 268435456 ] || { echo "FAIL: heap span $(($END - $START))"; exit 1; }
echo "ok: heap span 256 MiB, symbols ordered"

echo "== single-actor program"
make posix-run POSIXARCH=a64 PROG=tests/orig1.fpr

echo "== the actor scheduler on pthread harts"
make posix-run POSIXARCH=a64 PROG=tests/actors.fpr

echo "== the typed layer (sigs/structs/SString/VList)"
make posix-run POSIXARCH=a64 PROG=tests/typed.fpr

echo "== the svc URL funnel (read/write over every service)"
make posix-run POSIXARCH=a64 PROG=tests/svcurl.fpr

echo "== the slab churn (memory model under load)"
make posix-run POSIXARCH=a64 PROG=tests/slab.fpr

echo
echo "mac smoke: ALL GREEN"
echo "next: FPR_PORT=8000 make posix-run POSIXARCH=a64 PROG=programs/httpd.fpr"
