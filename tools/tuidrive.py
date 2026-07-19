"""tuidrive.py -- boot the stui image under QEMU, type stax at it, and
reconstruct the 80x24 screen from the emitted escape stream.

Usage: tuidrive.py [--keep] [--paste] "1 2 + ." "help" ...
Each argument is typed followed by Enter, with a settle delay; a screen
snapshot is printed after each. Ends by typing "exit" (unless --keep).
"""
import os, pty, re, select, subprocess, sys, time

W, H = 80, 24

class Screen:
    def __init__(self):
        self.grid = [[' '] * W for _ in range(H)]
        self.fg = [[0] * W for _ in range(H)]
        self.bg = [[0] * W for _ in range(H)]
        self.r = self.c = 0
        self.cfg = self.cbg = 0
        self.pend = b''
    def feed(self, chunk: bytes):
        data = self.pend + chunk
        self.pend = b''
        # hold back a trailing incomplete escape sequence
        m = re.search(rb'\x1b(\[[0-9;?]*)?$', data)
        if m:
            self.pend = data[m.start():]
            data = data[:m.start()]
        i, n = 0, len(data)
        while i < n:
            b = data[i]
            if b == 0x1b and i + 1 < n and data[i+1] == ord('['):
                m = re.match(rb'\x1b\[([0-9;?]*)([A-Za-z])', data[i:])
                if not m:
                    i += 1; continue
                params, fin = m.group(1).decode(), m.group(2).decode()
                if fin == 'H':
                    parts = params.split(';') if params else []
                    self.r = (int(parts[0]) - 1) if parts and parts[0] else 0
                    self.c = (int(parts[1]) - 1) if len(parts) > 1 and parts[1] else 0
                elif fin == 'm':
                    for p in (params.split(';') if params else ['0']):
                        v = int(p) if p else 0
                        if v == 0: self.cfg = self.cbg = 0
                        elif 30 <= v <= 37: self.cfg = v - 29
                        elif v == 39: self.cfg = 0
                        elif 40 <= v <= 47: self.cbg = v - 39
                        elif v == 49: self.cbg = 0
                elif fin == 'J':
                    self.grid = [[' '] * W for _ in range(H)]
                i += m.end()
            elif b in (0x0d,): self.c = 0; i += 1
            elif b in (0x0a,): self.r = min(H - 1, self.r + 1); i += 1
            else:
                if 32 <= b < 127 and self.r < H and self.c < W:
                    self.grid[self.r][self.c] = chr(b)
                    self.fg[self.r][self.c] = self.cfg
                    self.bg[self.r][self.c] = self.cbg
                    self.c += 1
                i += 1
    def dump(self):
        top = '.' + '=' * W + '.'
        return '\n'.join([top] + ['|' + ''.join(row) + '|' for row in self.grid] + [top.replace('.', "'")])

def drain(fd, scr, dur):
    end, total = time.time() + dur, 0
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.1)
        if r:
            try: data = os.read(fd, 65536)
            except OSError: break
            if not data: break
            scr.feed(data); total += len(data)
    return total

def main():
    args = sys.argv[1:]
    keep = '--keep' in args
    paste = '--paste' in args
    cmds = [a for a in args if not a.startswith('--')]
    mfd, sfd = pty.openpty()
    qemu = subprocess.Popen(
        ['qemu-system-riscv64', '-machine', 'virt', '-smp', '2', '-m', '256M',
         '-nographic', '-bios', 'none', '-kernel', 'image.elf'],
        stdin=sfd, stdout=sfd, stderr=subprocess.DEVNULL)
    os.close(sfd)
    scr = Screen()
    try:
        n = drain(mfd, scr, 3.0)
        print(f'--- boot: first frame, {n} bytes on the wire ---')
        print(scr.dump())
        for cmd in cmds:
            if paste:
                os.write(mfd, cmd.encode() + b'\r')
            else:
                for ch in cmd:
                    os.write(mfd, ch.encode()); time.sleep(0.02)
                time.sleep(0.3)
                os.write(mfd, b'\r')
            n = drain(mfd, scr, 3.0)
            print(f'--- after "{cmd}": {n} bytes on the wire ---')
            print(scr.dump())
        if not keep:
            for ch in 'exit':
                os.write(mfd, ch.encode()); time.sleep(0.02)
            os.write(mfd, b'\r')
            drain(mfd, scr, 1.5)
            print('--- sent exit; machine halted ---')
    finally:
        qemu.terminate()
        try: qemu.wait(timeout=3)
        except subprocess.TimeoutExpired: qemu.kill()

if __name__ == '__main__':
    main()
