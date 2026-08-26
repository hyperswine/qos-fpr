#!/usr/bin/env python3
"""fprd.py -- the fpr compiler hosted as a UNIX-DOMAIN-SOCKET server.

QOS Portable apps reach it through Sys.compile (std/compile.fpr):
the app-side shim rides the qosp syscall channel (tag 7), qosp's
host side (qos/portable/compile.c) connects HERE, and this daemon
runs the actual ./fprc pipeline -- so the compiler stays a host
process while the editing/storing policy stays inside QOS.

    cd fp-risc && python3 tools/fprd.py [sock-path]

  socket   argv[1], else $FPRD_SOCK, else /tmp/fprd.sock
  frame    4-byte LE length + payload, both directions
  request  "<profile>\n<source bytes>" -- profile is a WHITELISTED
           token (never argv passthrough): qos-portable | bare-metal
  reply    "ok\n<assembly .s text>"  or  "err\n<compiler stderr>"

One connection per compile, requests served sequentially (fprc is a
process spawn; the client holds one syscall anyway).  The reply is
the PROGRAM's own .s; module units (e.g. the prelude) are shared
cached artifacts on the host side and do not ride the channel.
"""
import os
import socket
import struct
import subprocess
import sys
import tempfile

PROFILES = {"qos-portable", "bare-metal"}
MAX_REQ = 4 << 20  # a 4 MiB source bound: honest refusal, not an OOM


def recv_exact(c, n):
    buf = b""
    while len(buf) < n:
        part = c.recv(n - len(buf))
        if not part:
            raise ConnectionError("peer closed mid-frame")
        buf += part
    return buf


def compile_one(profile, source):
    if profile not in PROFILES:
        return b"err\nunknown profile %r (want: %s)" % (
            profile, " | ".join(sorted(PROFILES)))
    with tempfile.TemporaryDirectory(prefix="fprd-") as td:
        src = os.path.join(td, "in.fpr")
        out = os.path.join(td, "out.s")
        with open(src, "wb") as f:
            f.write(source)
        env = dict(os.environ, LC_ALL="C.UTF-8")
        r = subprocess.run(
            ["./fprc", "--profile=" + profile, "--prelude=core/prelude.fpr",
             src, out],
            capture_output=True, env=env, timeout=120)
        if r.returncode != 0 or not os.path.exists(out):
            msg = (r.stderr + r.stdout).strip() or b"compile failed"
            return b"err\n" + msg
        with open(out, "rb") as f:
            return b"ok\n" + f.read()


def serve(path):
    if not os.path.exists("./fprc"):
        sys.exit("fprd: run from fp-risc/ (needs ./fprc + core/prelude.fpr)")
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(path)
    srv.listen(4)
    print(f"fprd: serving ./fprc on {path}", flush=True)
    while True:
        c, _ = srv.accept()
        try:
            (n,) = struct.unpack("<I", recv_exact(c, 4))
            if n > MAX_REQ:
                reply = b"err\nrequest too large"
            else:
                req = recv_exact(c, n)
                nl = req.find(b"\n")
                profile = req[:nl].decode("ascii", "replace") if nl >= 0 else ""
                source = req[nl + 1:] if nl >= 0 else b""
                try:
                    reply = compile_one(profile, source)
                except subprocess.TimeoutExpired:
                    reply = b"err\ncompile timed out"
            c.sendall(struct.pack("<I", len(reply)) + reply)
        except (ConnectionError, OSError) as e:
            print(f"fprd: connection dropped: {e}", flush=True)
        finally:
            c.close()


if __name__ == "__main__":
    serve(sys.argv[1] if len(sys.argv) > 1
          else os.environ.get("FPRD_SOCK", "/tmp/fprd.sock"))
