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

# eight apps in a 4-column grid: NOTES 0 CLOCK 1 HELLO 2 LOGS 3
# MONITOR 4 FILES 5 DISK 6 CLI 7 (+RENDER 8, HARTS 9).  Route: notes
# commit (through the file actor) -> clock -> files (list + RESOLVE)
# -> monitor -> logs(n) -> disk -> CLI (ls, write a file, cat it back)
# -> clock again (suspend/resume).  F12 is the snapshot key: inside an
# app every letter belongs to the app, which a CLI needs.  Filler is
# `tab` (maps to no character) for the same reason.
SPEC="enter h i enter tab tab tab  esc right tab tab tab tab tab  enter a b c tab tab tab  tab tab tab tab tab tab tab f12  esc right right tab tab tab tab  enter n tab tab tab tab tab  tab tab tab tab tab tab tab f12  esc down tab tab tab tab tab  enter tab tab tab tab tab tab  l s enter tab tab tab tab  tab tab tab tab tab tab tab f12  type:write space type:/tmp/Scratch-1.txt space tab  type:\"ok!\" tab tab tab tab tab tab  enter tab tab tab tab tab tab  type:cat space type:/tmp/Scratch-1.txt tab  enter tab tab tab tab tab tab  tab tab tab tab tab tab f12  esc left tab tab tab tab tab  enter tab tab tab tab tab tab  tab tab tab tab tab tab tab f12  esc left tab tab tab tab tab  enter tab tab tab tab tab tab  tab tab tab tab tab tab tab f12  down down down down tab tab tab  enter tab tab tab tab tab tab  tab tab tab tab tab tab tab f12  backspace esc left tab tab tab tab  enter tab tab tab tab tab tab  tab tab tab tab tab tab tab f12  esc up right tab tab tab tab  enter tab tab tab tab tab tab  tab tab tab tab tab tab tab f12  esc q tab tab tab tab tab"
EVD=/tmp/pshell-check.evd
python3 tools/kbdsim.py "$EVD" "$SPEC" >/dev/null || exit 1
python3 tools/kbdsim.py /tmp/pshell-quit.evd "f12 tab tab tab tab tab tab tab  q" >/dev/null || exit 1

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
echo "$out" | grep -q "8 apps loaded" || fail "qosp: 8 apps did not attach"
echo "$out" | grep -q "app 0: NOTES" || fail "qosp: NOTES not discovered"
echo "$out" | grep -q "app 4: MONITOR" || fail "qosp: MONITOR not discovered"
echo "$out" | grep -q "app 5: FILES" || fail "qosp: FILES not discovered"
echo "$out" | grep -q "app 6: DISK" || fail "qosp: DISK not discovered"
echo "$out" | grep -q "app 7: CLI" || fail "qosp: CLI not discovered"
echo "$out" | grep -q "system: opening /home/notes.txt" || fail "qosp: notes file actor never spawned"
echo "$out" | grep -q "system: creating /tmp/Scratch-1.txt" || fail "qosp: CLI write did not create a file"
echo "$out" | grep -q "\[log\] HELLO 5 FROM CHILD ACTOR" || fail "qosp: child actor's logs missing"
echo "$out" | grep -q "\[warn\] HELLO 3 WAS A WARNING" || fail "qosp: warn severity missing"
echo "$out" | grep -q "\[ERR\] HELLO 5 WAS AN ERROR" || fail "qosp: error severity missing"
echo "$out" | grep -q "pshell:.*8 apps" || fail "qosp: result string"
echo "$out" | grep -q "PANIC" && fail "qosp: panicked"
grep -q "/home/notes.txt" qos-store/pshell.kv || fail "qosp: notes record not written"
grep -q "/tmp/Scratch-1.txt" qos-store/pshell.kv || fail "qosp: CLI write not on the log"
# the exact bytes: uppercase, digits, punctuation and a SHIFTED quote
# all survived keyboard -> keymap -> file actor -> append log
grep -q '"ok!"' qos-store/pshell.kv || fail "qosp: shifted characters lost on the way to disk"
ls pshell*.ppm >/dev/null 2>&1 || fail "qosp: no snapshots"
python3 - <<'EOF' || exit 1
from PIL import Image
import glob
def near(p,t,tol=40): return all(abs(a-b)<=tol for a,b in zip(p,t))
snaps = sorted(glob.glob('pshell*.ppm'), key=lambda f:int(f[6:-4]))
assert len(snaps) == 9, f"expected 9 snapshots, got {snaps}"
def textin(f, y0, y1):
    im = Image.open(f).convert('RGB')
    return sum(1 for y in range(y0,y1,2) for x in range(16,420,2)
               if near(im.getpixel((x,y)),(237,240,245)))
# snaps: clock, logs, cli-ls, cli-cat, disk, files-list,
# files-resolved, monitor, clock-resumed
assert textin(snaps[1],40,140) > 60, f"{snaps[1]}: no log lines"
assert textin(snaps[2],40,240) > 80, f"{snaps[2]}: no cli ls output"
assert textin(snaps[3],40,240) > 80, f"{snaps[3]}: no cli cat output"
assert textin(snaps[4],55,110) > 10, f"{snaps[4]}: no disk records"
assert textin(snaps[5],40,240) > 90, f"{snaps[5]}: no namespace rows"
assert textin(snaps[6],40,140) > 60, f"{snaps[6]}: path did not resolve"
assert textin(snaps[7],40,240) > 80, f"{snaps[7]}: no actor tree rows"
print("  logs / cli ls+cat / disk / namespace / resolved / monitor: PASS")
EOF
echo "  qosp: session + child-actor log routing + kv: PASS"

echo "== qosp: relaunch replays the note =="
out=$(FPR_HARTS=4 FPR_EVDEV=/tmp/pshell-quit.evd timeout 120 ./qosp --yes app.qa </dev/null 2>&1 | tr -d '\r')
echo "$out" | grep -q "8 apps loaded" || fail "relaunch: apps"
echo "$out" | grep -q "PANIC" && fail "relaunch: panicked"
grep -q "/home/notes.txt" qos-store/pshell.kv || fail "relaunch: kv lost"
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
