#!/usr/bin/env python3
"""terra2-keys.py -- a key script as an evdev replay file for FPR_EVDEV.

    terra2-keys.py out.evd P enter enter P space P q

Each name becomes a press + release record (struct input_event, 24 bytes:
two 8-byte timeval words, type u16, code u16, value u32).  The evdev tier
consumes one record per poll and std.MVU buffers presses; terra2 takes one
buffered key per idle tick, so a replayed game is the same game every run.
"""
import struct, sys

CODES = {"esc": 1, "1": 2, "2": 3, "3": 4, "4": 5, "5": 6, "bksp": 14, "q": 16, "e": 18,
         "r": 19, "o": 24, "s": 31, "p": 25, "enter": 28, "a": 30, "f": 33, "c": 46, "v": 47,
         "space": 57, "up": 103, "left": 105, "right": 106, "down": 108}

def main():
    out, names = sys.argv[1], sys.argv[2:]
    recs = b""
    t = 1
    for n in names:
        code = CODES[n.lower()]
        for value in (1, 0):
            recs += struct.pack("<qqHHI", t, 0, 1, code, value)
            t += 1
    open(out, "wb").write(recs)
    print(f"{out}: {len(names)} keys, {len(recs)} bytes")

if __name__ == "__main__":
    main()
