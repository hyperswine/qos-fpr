#!/bin/bash
# terra2-check.sh -- Terra II, played by a key script under Xvfb.
#
# Builds the game .qa and qosp-gl, replays a fixed key file (FPR_EVDEV),
# and asserts the transcript the rules print (the calls, the attack lunge
# on the HQ, a unit destroyed, the AI's turn), the frames the S key read
# back mid-animation (960x600 PPMs that are not blank), and the sound the
# synthesizer dumped (FPR_SND_DUMP: a WAV as long as the run, with
# distinct bursts over silence).  Needs xvfb-run and libglfw;
# check-all.sh skips the leg without them.
set -e
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$HERE/fp-risc" && make -s qos-app PROG=programs/terra2.fpr >/dev/null 2>&1
cd "$HERE/qos" && make -s portable-gl >/dev/null 2>&1
python3 tests-host/terra2-keys.py /tmp/terra2.evd \
  enter s right right enter enter space \
  up up right right enter a up up enter p space \
  up up right right enter a enter left enter right enter p space q >/dev/null
rm -f /tmp/terra2-*.ppm /tmp/terra2.wav
FPR_SND_DUMP=/tmp/terra2.wav FPR_EVDEV=/tmp/terra2.evd timeout 240 xvfb-run -a ./qosp-gl --yes ../fp-risc/app.qa > /tmp/terra2-check.log 2>&1 || true
fail() { echo "terra2-check: FAIL: $1"; tail -20 /tmp/terra2-check.log; exit 1; }
grep -aq "you: LightInf called to forward 3" /tmp/terra2-check.log || fail "the call"
grep -aq "you: LightInf attacks the HQ" /tmp/terra2-check.log || fail "the lane attack"
grep -aq "HQ hit for 2: 13 left" /tmp/terra2-check.log || fail "HQ damage"
grep -aq "turn 1 side 1" /tmp/terra2-check.log || fail "the enemy turn"
grep -aq "enemy: .* called to" /tmp/terra2-check.log || fail "the AI's call"
grep -aq "destroyed" /tmp/terra2-check.log || fail "a death"
grep -aq "you: MechInf called to forward 4" /tmp/terra2-check.log || fail "the tank's call"
grep -aq "\[gfx\] mesh tank_hull: 172 triangles" /tmp/terra2-check.log || fail "the hull mesh"
grep -aq "\[gfx\] mesh tank_turret: 124 triangles" /tmp/terra2-check.log || fail "the turret mesh"
for m in infantry infantry_kit truck truck_kit truck_canvas hq hq_fence hq_dish; do
  grep -aq "\[gfx\] mesh $m: [0-9]* triangles" /tmp/terra2-check.log || fail "the $m mesh"
done
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
# the sound: the mix is as long as the run and carries distinct bursts
# (cursor ticks, the opening riff, calls, blows, turn chimes, the close)
[ -s /tmp/terra2.wav ] || fail "no sound dump"
python3 - /tmp/terra2.wav <<'PY' || fail "sound dump"
import sys, struct
b = open(sys.argv[1], 'rb').read()
assert b[:4] == b'RIFF' and b[8:12] == b'WAVE', "not a WAV"
rate = struct.unpack_from('<I', b, 24)[0]; data = b[44:]
n = len(data) // 2
secs = n / rate
frames = struct.unpack('<%dh' % n, data[:n * 2])
win = rate // 50  # 20 ms windows
loud = [max(abs(x) for x in frames[i:i + win]) > 1500 for i in range(0, n - win, win)]
bursts = sum(1 for i in range(1, len(loud)) if loud[i] and not loud[i - 1])
quiet = 1 - sum(loud) / max(1, len(loud))
print(f"terra2 sound: {secs:.1f} s, {bursts} bursts, {quiet * 100:.0f}% silence")
assert secs > 12, "too short"
assert bursts >= 20, "too few bursts"
assert quiet > 0.3, "never quiet"
PY
SND=$(grep -a -m1 "dump closed" /tmp/terra2-check.log | sed 's/.*(\(.*\) s), \(.*\) tones.*/\1 s, \2 tones/')
FR=$(grep -a "game over" /tmp/terra2-check.log | sed 's/.*\[mvu: \([0-9]*\) frames.*/\1/')
echo "terra2-check: ALL LEGS PASS ($N snapshots, $FR frames, sound $SND: title, call, lane attack on the HQ, AI turn, a death, the tank, clean quit)"
