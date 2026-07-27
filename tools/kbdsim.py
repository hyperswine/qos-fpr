#!/usr/bin/env python3
"""kbdsim.py -- a simulated keyboard-style device speaking evdev.

Emits Linux `struct input_event` records (the evdev wire format --
exactly what a real /dev/input/eventN delivers and what libevdev
parses), so the runtime's ONE raw reader (runtime/posix/evdev_raw.c)
serves real hardware and simulation identically.  Three modes:

  file mode (default) -- write all events at once to a regular file:
      tools/kbdsim.py script.evd "d*6 w*4 q"
      FPR_EVDEV=script.evd ./qosp --yes app.qa
    Deterministic: the app drains one event per poll, so an MVU loop
    replays the exact same model trajectory every run.

  fifo mode -- feed a FIFO live, one press per --rate seconds:
      mkfifo /tmp/kbd && tools/kbdsim.py --fifo /tmp/kbd "d*20" &
      FPR_EVDEV=/tmp/kbd ./qosp --yes app.qa
    The reader's nonblocking accumulate handles partial records.

  uinput mode -- create a REAL kernel virtual keyboard (/dev/uinput
    must exist; needs permissions).  The events then arrive through an
    actual /dev/input/eventN like any physical keyboard:
      tools/kbdsim.py --uinput "w*5 a*3" &
      FPR_EVDEV=/dev/input/eventN ./qosp --yes app.qa

The spec is space-separated tokens `<key>` or `<key>*<n>`: each unit is
one press (value 1) + one release (value 0), each followed by an
EV_SYN frame marker, matching real device traffic.  Keys: a-z, 0-9,
space, up/down/left/right, esc.
"""
import argparse, os, struct, sys, time

EV_SYN, EV_KEY = 0x00, 0x01
# linux/input-event-codes.h, the subset a control-input program wants
KEY = {**{chr(ord('a')+i): c for i, c in enumerate(
        [30,48,46,32,18,33,34,35,23,36,37,38,50,49,24,25,16,19,31,20,22,47,17,45,21,44])},
       **{str(d): c for d, c in zip(range(10), [11,2,3,4,5,6,7,8,9,10])},
       'space': 57, 'esc': 1, 'up': 103, 'down': 108, 'left': 105, 'right': 106}

def ev(etype, code, value):
    # 64-bit struct input_event: timeval (2x u64) + type,code (u16) + value (s32)
    t = time.time()
    return struct.pack("qqHHi", int(t), int((t % 1) * 1e6), etype, code, value)

def key_unit(code):
    return (ev(EV_KEY, code, 1) + ev(EV_SYN, 0, 0) +
            ev(EV_KEY, code, 0) + ev(EV_SYN, 0, 0))

def parse_spec(spec):
    units = []
    for tok in spec.split():
        name, _, n = tok.partition('*')
        if name not in KEY:
            sys.exit(f"kbdsim: unknown key {name!r} (have: {' '.join(sorted(KEY))})")
        units += [KEY[name]] * (int(n) if n else 1)
    return units

def run_uinput(units, rate):
    import fcntl
    UI_SET_EVBIT, UI_SET_KEYBIT = 0x40045564, 0x40045565
    UI_DEV_CREATE, UI_DEV_DESTROY = 0x5501, 0x5502
    fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
    fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
    for c in set(units): fcntl.ioctl(fd, UI_SET_KEYBIT, c)
    # struct uinput_user_dev: name[80] + input_id (4x u16) + ff + 4x abs arrays
    dev = struct.pack("80sHHHHi", b"kbdsim virtual keyboard", 0x03, 0x1, 0x1, 1, 0)
    dev += b"\0" * (4 * 64 * 4)
    os.write(fd, dev)
    fcntl.ioctl(fd, UI_DEV_CREATE, 0)
    print("kbdsim: virtual keyboard created (find it under /dev/input/)", file=sys.stderr)
    time.sleep(1.0)  # give udev/openers a beat
    for c in units:
        os.write(fd, key_unit(c))
        time.sleep(rate)
    time.sleep(0.5)
    fcntl.ioctl(fd, UI_DEV_DESTROY, 0)
    os.close(fd)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fifo", action="store_true", help="pace writes for a live FIFO")
    ap.add_argument("--uinput", action="store_true", help="create a real virtual device")
    ap.add_argument("--rate", type=float, default=0.05, help="seconds between presses (fifo/uinput)")
    ap.add_argument("path_or_spec")
    ap.add_argument("spec", nargs="?")
    a = ap.parse_args()
    if a.uinput:
        run_uinput(parse_spec(a.path_or_spec if a.spec is None else a.spec), a.rate)
        return
    path, spec = a.path_or_spec, a.spec
    if spec is None:
        sys.exit("kbdsim: need <path> <spec> (or --uinput <spec>)")
    units = parse_spec(spec)
    if a.fifo:
        with open(path, "wb", buffering=0) as f:
            for c in units:
                f.write(key_unit(c))
                time.sleep(a.rate)
    else:
        with open(path, "wb") as f:
            for c in units:
                f.write(key_unit(c))
        print(f"kbdsim: wrote {len(units)} key units ({len(units)*4} events) to {path}")

if __name__ == "__main__":
    main()
