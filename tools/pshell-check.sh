#!/bin/bash
# tools/pshell-check.sh -- build + drive programs/pshell.fpr on BOTH
# hosted paths (co-compiled posix GFX, and as a .qa under multi-hart
# GFX qosp), assert the interaction, the gen_view split, the snapshot
# structure, and kv persistence across launches.
#
# Frames carry live text (clock, render stats), so runs are not
# byte-comparable; the assertions are structural instead: the model
# trajectory via the result string, the store via the kv file, and the
# pixels via color/position checks against scene2d's palette.
set -u
cd "$(dirname "$0")/.."

SPEC="right down left up up left left right  p z z z z z z z  left z z z z z z z  z z z z z z z p  enter a b c space 1 2 3  enter t w o space o k z  enter esc p z z z z z  q z z z z z z z"
EVD=/tmp/pshell-check.evd
python3 tools/kbdsim.py "$EVD" "$SPEC" >/dev/null || exit 1
python3 tools/kbdsim.py /tmp/pshell-quit.evd "p z z z z z z z  q" >/dev/null || exit 1

fail() { echo "pshell-check: FAIL: $*"; exit 1; }

snapcheck() {  # snapcheck <ppm> <where>  (right|left|bottom = focus-blue bbox)
python3 - "$1" "$2" <<'EOF' || exit 1
import sys
from PIL import Image
f, where = sys.argv[1], sys.argv[2]
im = Image.open(f).convert('RGB')
def near(p, t, tol=40): return all(abs(a-b) <= tol for a, b in zip(p, t))
fx = [(x, y) for y in range(0, 480, 2) for x in range(0, 640, 2)
      if near(im.getpixel((x, y)), (84, 183, 255))]
amber = sum(1 for y in range(0, 480, 2) for x in range(0, 640, 2)
            if near(im.getpixel((x, y)), (255, 204, 76)))
assert fx, f"{f}: no focus-blue pixels"
x0 = min(x for x, y in fx); x1 = max(x for x, y in fx)
y1 = max(y for x, y in fx)
cx = (x0 + x1) / 2
if where == 'right': assert cx > 320, f"{f}: focus ring not on the right tile ({cx})"
if where == 'left': assert cx < 320, f"{f}: focus ring not on the left tile ({cx})"
if where == 'bottom': assert y1 > 380, f"{f}: focus box not the input row ({y1})"
need = 2 if where == 'bottom' else 40   # notes screen: amber is just the '>' prompt
assert amber > need, f"{f}: no slot text"
print(f"  {f}: focus at {where}, slot text present: PASS")
EOF
}

runcheck() {  # runcheck <label> <cmd-prefix...>
  local label=$1; shift
  rm -f pshell*.ppm
  out=$("$@" 2>&1 | tr -d '\r')
  echo "$out" | grep -q "0 notes replayed" || fail "$label: fresh boot not empty"
  echo "$out" | grep -q "7 frames" || fail "$label: wrong frame count"
  echo "$out" | grep -q "2 notes" || fail "$label: notes not committed"
  echo "  $label session: 7 frames, 2 notes: PASS"
  snapcheck pshell1.ppm right
  snapcheck pshell3.ppm left
  snapcheck pshell6.ppm bottom
}

echo "== co-compiled posix (GFX=1) =="
make -s posix.bin GFX=1 PROG=programs/pshell.fpr >/dev/null || fail posix build
rm -f /tmp/pshell-check.kv
runcheck posix env FPR_STORE=/tmp/pshell-check.kv FPR_EVDEV=$EVD timeout 120 ./posix.bin
grep -q "abc 123" /tmp/pshell-check.kv || fail "posix kv missing note 1"
grep -q "two okz" /tmp/pshell-check.kv || fail "posix kv missing note 2"
out=$(FPR_STORE=/tmp/pshell-check.kv FPR_EVDEV=/tmp/pshell-quit.evd timeout 60 ./posix.bin </dev/null 2>&1)
echo "$out" | grep -q "2 notes replayed" || fail "posix relaunch replay"
echo "  posix kv + relaunch replay: PASS"

echo "== .qa under GFX qosp, FPR_HARTS=4 =="
rm -f qosp && make -s qosp GFX=1 >/dev/null || fail qosp build
make -s portable-qa PROG=programs/pshell.fpr >/dev/null || fail qa build
rm -rf qos-store
runcheck qosp env FPR_HARTS=4 FPR_EVDEV=$EVD timeout 180 ./qosp --yes app.qa
grep -q "abc 123" qos-store/pshell.kv || fail "qosp kv missing note 1"
out=$(FPR_HARTS=4 FPR_EVDEV=/tmp/pshell-quit.evd timeout 90 ./qosp --yes app.qa </dev/null 2>&1)
echo "$out" | tr -d '\r' | grep -q "2 notes replayed" || fail "qosp relaunch replay"
echo "  qosp kv trampoline + relaunch replay (4 harts): PASS"

echo "== plugin: pnotes.qa under qosp =="
make -s plugin-qa >/dev/null || fail "plugin build"
rm -rf qos-store
out=$(FPR_HARTS=4 FPR_EVDEV=$EVD timeout 180 ./qosp --yes app.qa </dev/null 2>&1 | tr -d '\r')
echo "$out" | grep -q "notes plugin attached" || fail "plugin did not attach"
echo "$out" | grep -q "7 frames" || fail "plugin session frames"
echo "$out" | grep -q "2 notes" || fail "plugin session notes"
grep -q "abc 123" qos-store/pshell.kv || fail "plugin kv"
echo "  qosp: attach + full session through the plugin screen: PASS"
out=$(FPR_STORE=/tmp/pshell-check.kv FPR_EVDEV=/tmp/pshell-quit.evd timeout 60 ./posix.bin </dev/null 2>&1 | tr -d '\r')
echo "$out" | grep -q "builtin notes" || fail "posix should fall back to builtin"
echo "  posix: honest qosp-only refusal + builtin fallback: PASS"

echo "== reclamation soak (25s idle, 4 harts) =="
# a leak of even one slab per frame dies here; steady state is a few
# dozen grows total (the acb ledger), not hundreds
rm -rf qos-store
rm -f /tmp/pshell-soak.fifo && mkfifo /tmp/pshell-soak.fifo
(FPR_HARTS=4 FPR_EVDEV=/tmp/pshell-soak.fifo timeout 40 ./qosp --yes --trace app.qa </dev/null >/tmp/pshell-soak.txt 2>&1 &)
sleep 1; exec 8>/tmp/pshell-soak.fifo; sleep 25
cat /tmp/pshell-quit.evd >&8; exec 8>&-; sleep 2
grep -q "PANIC" /tmp/pshell-soak.txt && fail "soak panicked: $(grep PANIC /tmp/pshell-soak.txt | head -1)"
grows=$(grep -c 'grow(' /tmp/pshell-soak.txt)
[ "$grows" -lt 120 ] || fail "soak leaking: $grows grows in 25s (expect a few dozen)"
echo "  soak: $grows grows, no panic: PASS"

echo "pshell-check: ALL PASS"
