#!/bin/bash
# tools/livenotes-check.sh -- end-to-end conformance for FPRLive-in-FP-RISC.
#
#   1. build the FP-RISC server (programs/livenotes.fpr) for posix
#   2. build the C client (tools/fprlive_client.c)
#   3. start the server; fetch golden.txt (the server's own naive
#      re-evaluation of its own emitted ISA words)
#   4. replay the image's scripted timeline in lockstep; the client's
#      incremental trace.txt must be byte-identical, and the timing
#      contract (round trip included) must hold
#
#   PORT=9xxx ./tools/livenotes-check.sh
set -u
SRV=0
cd "$(dirname "$0")/.."
PORT="${PORT:-8796}"
WORK=$(mktemp -d)
trap 'kill $SRV 2>/dev/null; rm -rf "$WORK"' EXIT

echo "== build server (FP-RISC -> posix)"
# change POSIXARCH=a64 to x86 for testing on x86
make -s posix.bin PROG=programs/livenotes.fpr POSIXARCH=a64 >/dev/null || exit 1
echo "== build client (C)"
cc -O2 -o "$WORK/client" tools/fprlive_client.c || exit 1

echo "== start server on :$PORT"
FPR_PORT=$PORT ./posix.bin </dev/null >"$WORK/srv.log" 2>&1 &
SRV=$!
sleep 2
grep -q "FPRLive server up" "$WORK/srv.log" || { echo "server failed:"; cat "$WORK/srv.log"; exit 1; }

cd "$WORK"
echo "== fetch golden (server-side naive re-eval)"
./client 127.0.0.1 "$PORT" --golden > golden.txt || exit 1
echo "== lockstep script replay (client-side incremental)"
./client 127.0.0.1 "$PORT" --script > script.log
RC=$?
tail -9 script.log

if diff -q golden.txt trace.txt >/dev/null; then
  echo "semantic conformance: PASS ($(wc -l < golden.txt) lines byte-identical)"
else
  echo "semantic conformance: FAIL"
  diff golden.txt trace.txt | head -10
  exit 1
fi
exit $RC
