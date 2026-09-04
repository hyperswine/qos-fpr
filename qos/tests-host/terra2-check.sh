#!/bin/bash
# terra2-check.sh -- Terra II, played by a key script under Xvfb.
#
# Builds the game .qa and qosp-gl, replays a fixed key file (FPR_EVDEV),
# and asserts the transcript the rules log (calls, the attack lunge on the
# HQ, a unit destroyed, the AI's turn) plus the frames the S key read back
# mid-animation: 960x600 PPMs that are not blank.  Needs xvfb-run and
# libglfw; check-all.sh skips the leg without them.
set -e
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$HERE/fp-risc" && make -s qos-app PROG=programs/terra2.fpr >/dev/null 2>&1
cd "$HERE/qos" && make -s portable-gl >/dev/null 2>&1
python3 tests-host/terra2-keys.py /tmp/terra2.evd \
  s right right enter enter space \
  up up right right enter a up up enter p space \
  up up right right enter a enter p space q >/dev/null
rm -f /tmp/terra2-*.ppm
FPR_EVDEV=/tmp/terra2.evd timeout 240 xvfb-run -a ./qosp-gl --yes ../fp-risc/app.qa > /tmp/terra2-check.log 2>&1 || true
fail() { echo "terra2-check: FAIL: $1"; tail -20 /tmp/terra2-check.log; exit 1; }
grep -aq "you: LightInf called to forward 3" /tmp/terra2-check.log || fail "the call"
grep -aq "you: LightInf attacks the HQ" /tmp/terra2-check.log || fail "the lane attack"
grep -aq "HQ hit for 2: 13 left" /tmp/terra2-check.log || fail "HQ damage"
grep -aq "turn 1 side 1" /tmp/terra2-check.log || fail "the enemy turn"
grep -aq "enemy: .* called to" /tmp/terra2-check.log || fail "the AI's call"
grep -aq "destroyed" /tmp/terra2-check.log || fail "a death"
grep -aq "game over" /tmp/terra2-check.log || fail "clean exit"
grep -aq "PANIC" /tmp/terra2-check.log && fail "panic"
N=$(ls /tmp/terra2-*.ppm 2>/dev/null | wc -l)
[ "$N" -ge 3 ] || fail "expected >= 3 snapshots, got $N"
for f in /tmp/terra2-*.ppm; do
  head -2 "$f" | grep -q "960 600" || fail "$f: not 960x600"
  # not blank: more than 2% of the bytes differ from the clear colour
  python3 - "$f" <<'PY' || fail "$f: blank frame"
import sys; b=open(sys.argv[1],'rb').read(); d=b.split(b'\n',3)[3]
lit=sum(1 for i in range(0,len(d),3*97) if d[i]>40 or d[i+1]>40 or d[i+2]>40)
sys.exit(0 if lit*97*3 > len(d)*0.02 else 1)
PY
done
FR=$(grep -a "game over" /tmp/terra2-check.log | sed 's/.*\[mvu: \([0-9]*\) frames.*/\1/')
echo "terra2-check: ALL LEGS PASS ($N snapshots, $FR frames: call, lane attack on the HQ, AI turn, a death, clean quit)"
