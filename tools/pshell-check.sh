#!/bin/bash
# tools/pshell-check.sh -- build + drive programs/pshell.fpr on BOTH
# hosted paths, now as the multi-app LAUNCHER: posix boots with 0 apps
# (plugin loading is qosp-only) and must degrade cleanly; qosp attaches
# the four app .qa's and runs a full session: clock -> suspend -> logs
# (reading the /services/log ring the hello app's CHILD ACTOR wrote
# through the capability) -> notes (commit + kv) -> clock RE-ENTRY
# (the suspended state resumed).  Then a reclamation soak: leaks that
# a short session can never show die here instead of on the Pi.
set -u
cd "$(dirname "$0")/.."

# home nav -> clock (3 keys) -> snap -> esc -> logs -> snap -> esc ->
# notes -> "hi" -> commit -> esc -> clock again -> snap -> esc -> quit
SPEC="right z z z z z z z  enter a b c z z z z  z z z z z z z p  esc z z z z z z z  down right z z z z z  enter z z z z z z z  z z z z z z z p  esc up left z z z z  z enter h i z z z z  enter z z z z z z z  esc right z z z z z  enter z z z z z z p  esc q z z z z z z"
EVD=/tmp/pshell-check.evd
python3 tools/kbdsim.py "$EVD" "$SPEC" >/dev/null || exit 1
python3 tools/kbdsim.py /tmp/pshell-quit.evd "p z z z z z z z  q" >/dev/null || exit 1

fail() { echo "pshell-check: FAIL: $*"; exit 1; }

echo "== build =="
make -s posix.bin GFX=1 PROG=programs/pshell.fpr >/dev/null || fail "posix build"
make -s qosp GFX=1 >/dev/null || fail "qosp build"
make -s portable-qa PROG=programs/pshell.fpr >/dev/null || fail "app build"
make -s apps-qa >/dev/null || fail "apps build"

echo "== posix: launcher with 0 apps (honest degrade) =="
rm -f /tmp/pshell-check.kv pshell*.ppm
out=$(FPR_STORE=/tmp/pshell-check.kv FPR_EVDEV=$EVD timeout 120 ./posix.bin </dev/null 2>&1 | tr -d '\r')
echo "$out" | grep -q "0 apps loaded" || fail "posix: expected 0 apps"
echo "$out" | grep -q "pshell:.*0 apps" || fail "posix: result string"
echo "$out" | grep -q "PANIC" && fail "posix: panicked"
echo "  posix: 0 apps, clean session: PASS"

echo "== qosp: 4 apps, full multi-app session (4 harts) =="
rm -rf qos-store pshell*.ppm
out=$(FPR_HARTS=4 FPR_EVDEV=$EVD timeout 180 ./qosp --yes app.qa </dev/null 2>&1 | tr -d '\r')
echo "$out" | grep -q "4 apps loaded" || fail "qosp: 4 apps did not attach"
echo "$out" | grep -q "app 0: NOTES" || fail "qosp: NOTES not discovered"
echo "$out" | grep -q "app 3: LOGS" || fail "qosp: LOGS not discovered"
echo "$out" | grep -q "\[log\] HELLO 5 FROM CHILD ACTOR" || fail "qosp: child actor's logs missing"
echo "$out" | grep -q "pshell:.*4 apps" || fail "qosp: result string"
echo "$out" | grep -q "PANIC" && fail "qosp: panicked"
grep -q "hi" qos-store/pshell.kv || fail "qosp: note not persisted"
ls pshell*.ppm >/dev/null 2>&1 || fail "qosp: no snapshots"
python3 - <<'EOF' || exit 1
from PIL import Image
import glob
def near(p,t,tol=40): return all(abs(a-b)<=tol for a,b in zip(p,t))
snaps = sorted(glob.glob('pshell*.ppm'), key=lambda f:int(f[6:-4]))
assert len(snaps) == 3, f"expected 3 snapshots, got {snaps}"
# middle snapshot = the LOGS screen: green title block + text rows in
# the top-left region (the ring lines)
im = Image.open(snaps[1]).convert('RGB')
text = sum(1 for y in range(40,140,2) for x in range(16,400,2)
           if near(im.getpixel((x,y)),(237,240,245)))
assert text > 60, f"{snaps[1]}: no log lines rendered ({text})"
print(f"  {snaps[1]}: log lines rendered: PASS")
EOF
echo "  qosp: session + child-actor log routing + kv: PASS"

echo "== qosp: relaunch replays the note =="
out=$(FPR_HARTS=4 FPR_EVDEV=/tmp/pshell-quit.evd timeout 120 ./qosp --yes app.qa </dev/null 2>&1 | tr -d '\r')
echo "$out" | grep -q "4 apps loaded" || fail "relaunch: apps"
echo "$out" | grep -q "PANIC" && fail "relaunch: panicked"
grep -q "hi" qos-store/pshell.kv || fail "relaunch: kv lost"
echo "  qosp relaunch: PASS"

echo "== reclamation soak (25s idle, 4 harts) =="
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
