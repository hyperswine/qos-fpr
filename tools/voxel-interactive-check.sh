#!/bin/bash
# tools/voxel-interactive-check.sh -- build + exercise the live voxel TUI.
#
#   1. FPR_EVDEV replay, twice: byte-identical AFTER normalizing the
#      latency readout (the one wall-clock field in the frame text --
#      everything else is deterministic), and pinned at 64x48 (the
#      evdev tier never emits a kind-5 size event, so replays see the
#      same event stream they always did).
#   2. mechanics asserted from the replay log: move, jump, destroy,
#      place WATER (v), hold CLOUD (c), clean q quit.
#   3. a pty session: initial size -> 96x64, SIGWINCH grow -> 144x96,
#      SIGWINCH shrink -> 64x48, a clear on every change, clean quit.
set -u
cd "$(dirname "$0")/.."
make -s posix.bin PROG=programs/voxel-interactive.fpr >/dev/null 2>&1 || { echo "build FAILED"; exit 1; }

# ---- 1+2: evdev replay ------------------------------------------------
# 16 polls/frame and press+release pairs = 8 presses per frame; the
# status line's act field shows the LAST action of a frame, so each
# 8-unit batch below ends on the mechanic it asserts
python3 tools/kbdsim.py /tmp/vi.evd \
  "up*8  space d*6 x  s s 5 5 5 5 v f  a a a a a a a c  q" >/dev/null
FPR_EVDEV=/tmp/vi.evd ./posix.bin > /tmp/vi-1.txt 2>&1 || { echo "replay run FAILED"; exit 1; }
FPR_EVDEV=/tmp/vi.evd ./posix.bin > /tmp/vi-2.txt 2>&1 || { echo "replay run 2 FAILED"; exit 1; }

norm() { sed 's/lat [0-9.]*ms/lat -/g' "$1"; }
if [ "$(norm /tmp/vi-1.txt | md5sum)" = "$(norm /tmp/vi-2.txt | md5sum)" ]; then
  echo "replay determinism (lat-normalized): PASS"
else
  echo "replay determinism: FAIL"; exit 1
fi
grep -ao 'f[0-9]* [0-9]*x[0-9]*' /tmp/vi-1.txt | grep -vq ' 64x48$' && { echo "replay resized -- FAIL"; exit 1; }
echo "replay resolution pinned at 64x48: PASS"

for want in "air" "destroy [0-9]" "place 11 at" "hold cloud" "bye ("; do
  grep -aq "$want" /tmp/vi-1.txt && echo "  mechanic: '$want' PASS" \
                                 || { echo "  mechanic: '$want' FAIL"; exit 1; }
done

# ---- 3: pty resize ----------------------------------------------------
python3 - <<'EOF' || exit 1
import os, pty, time, signal, fcntl, termios, struct, re, sys
pid, fd = pty.fork()
if pid == 0:
    os.execv("./posix.bin", ["./posix.bin"])
def setsize(r, c):
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", r, c, 0, 0))
buf = bytearray()
def drain(secs):
    end = time.time() + secs
    os.set_blocking(fd, False)
    while time.time() < end:
        try: buf.extend(os.read(fd, 1 << 20))
        except (BlockingIOError, OSError): time.sleep(0.01)
setsize(40, 100); drain(4)                        # -> 96x64
setsize(60, 150); os.kill(pid, signal.SIGWINCH); drain(4)   # -> 144x96
setsize(20, 70);  os.kill(pid, signal.SIGWINCH); drain(3)   # -> 64x48 floor
os.write(fd, b"q"); drain(3)
os.kill(pid, signal.SIGKILL)
seen = [m.decode() for m in re.findall(rb'f\d+ (\d+x\d+)', bytes(buf))]
order = [r for i, r in enumerate(seen) if i == 0 or r != seen[i-1]]
ok = order == ['96x64', '144x96', '64x48']
print("pty resize 96x64 -> 144x96 -> 64x48:", "PASS" if ok else "FAIL " + str(order))
clears = bytes(buf).count(b'\x1b[2J')
print("clear on every change (1 boot + 3):", "PASS" if clears == 4 else f"FAIL ({clears})")
print("clean quit:", "PASS" if b"bye (" in buf else "FAIL")
sys.exit(0 if ok and clears == 4 and b"bye (" in buf else 1)
EOF
echo "voxel-interactive-check: ALL PASS"
