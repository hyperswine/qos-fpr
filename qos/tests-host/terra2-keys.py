#!/usr/bin/env python3
"""terra2-keys.py -- a key script as an evdev replay file for FPR_EVDEV.

    terra2-keys.py out.evd P enter enter P space P q

Each name becomes a press + release record (struct input_event, 24 bytes:
two 8-byte timeval words, type u16, code u16, value u32).  The evdev tier
consumes one record per poll and std.MVU buffers presses; terra2 takes one
buffered key per idle tick, so a replayed game is the same game every run.
"""
import struct, sys

CODES = {"esc": 1, "bksp": 14, "enter": 28, "space": 57, "up": 103, "left": 105, "right": 106, "down": 108,
         "minus": 12, "equal": 13, "dot": 52, "comma": 51, "slash": 53,
         "1": 2, "2": 3, "3": 4, "4": 5, "5": 6, "6": 7, "7": 8, "8": 9, "9": 10, "0": 11}
for row, base in (("qwertyuiop", 16), ("asdfghjkl", 30), ("zxcvbnm", 44)):
    for i, ch in enumerate(row):
        CODES[ch] = base + i
PUNCT = {" ": "space", ".": "dot", "-": "minus", "=": "equal", ",": "comma", "/": "slash"}


def expand(names):
    """a `type:...` argument types its text (letters, digits, punctuation)"""
    out = []
    for n in names:
        if n.startswith("type:"):
            out += [PUNCT.get(ch, ch) for ch in n[5:]]
        else:
            out.append(n)
    return out

def main():
    out, names = sys.argv[1], expand(sys.argv[2:])
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
