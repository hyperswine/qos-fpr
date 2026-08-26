#!/usr/bin/env python3

"""qos.py -- the pipeline layer over the whole tree.

The Makefiles stay what they are: MECHANISM (cross-compilation,
linking, packaging -- fp-risc/Makefile and qos/Makefile know how each
artifact is made).  This file is the POLICY layer the project always
gets used as anyway: one command from the repo root that knows how the
pieces compose -- compiler -> .qa -> host -> disk -> QEMU -> browser --
and where every intermediate lives, so you never cd between component
directories or thread app.qa paths by hand again.

    ./qos.py build                  bring fpr + qosp up to date
    ./qos.py run tests/dtree.fpr    compile + host on qosp (the default)
    ./qos.py run tests/fmath.fpr --on virt      ... on bare-metal QEMU
    ./qos.py run sol/examples/todo.sol          ... .sol runs the sol profile
    ./qos.py serve tests/mvuweb.fpr --port 8080 LiveView app, URL printed
    ./qos.py native                 kernel + disk + interactive QEMU boot
    ./qos.py native --apps a.qa b.qa --smoke    seeded, scripted boot check
    ./qos.py disk my.img 8 a.qa     seed a QLOG image (mkdisk)
    ./qos.py commit mods/qlog.fpr   fpr commit (the .fpr store)
    ./qos.py test                   the fast smoke set;  --all = check-all.sh
    ./qos.py clean

Everything delegates to make for staleness (an up-to-date tree is a
no-op), so this adds no second dependency graph -- just one honest
entry point over the existing one.
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FPR = ROOT / "fp-risc"
QOS = ROOT / "qos"


def say(msg):
    print(f"\033[36m[qos]\033[0m {msg}", flush=True)


def die(msg, code=1):
    print(f"\033[31m[qos]\033[0m {msg}", file=sys.stderr)
    sys.exit(code)


def sh(cmd, cwd=ROOT, env=None, quiet=False, check=True):
    e = dict(os.environ)
    if env:
        e.update({k: str(v) for k, v in env.items()})
    r = subprocess.run(
        cmd, cwd=cwd, env=e,
        stdout=subprocess.DEVNULL if quiet else None,
        stderr=subprocess.STDOUT if quiet else None)
    if check and r.returncode != 0:
        die(f"failed ({r.returncode}): {' '.join(map(str, cmd))}", r.returncode)
    return r.returncode


def run_scan(cmd, cwd, env=None, expect=None):
    """Stream a child's output live; if expect is set, also scan for it
    and report the verdict in the exit code."""
    e = dict(os.environ)
    if env:
        e.update({k: str(v) for k, v in env.items()})
    p = subprocess.Popen(cmd, cwd=cwd, env=e, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    hit = expect is None
    try:
        for raw in p.stdout: # type: ignore
            line = raw.decode("utf-8", "replace")
            sys.stdout.write(line)
            sys.stdout.flush()
            if expect and expect in line:
                hit = True
        p.wait()
    except KeyboardInterrupt:
        p.terminate()
        p.wait()
    if expect:
        if hit:
            say(f"expect: found {expect!r}")
        else:
            die(f"expect: {expect!r} never appeared")
    return p.returncode


# ---- resolution -------------------------------------------------------------

def resolve_prog(prog):
    """A program path as typed from anywhere -> the fp-risc-relative
    path the Makefile wants."""
    p = Path(prog)
    for cand in (Path.cwd() / p, FPR / p, ROOT / p):
        if cand.is_file():
            return os.path.relpath(cand.resolve(), FPR)
    die(f"no such program: {prog} (looked in ., fp-risc/, repo root)")


# ---- the stages -------------------------------------------------------------

def build_fpr():
    say("fpr (compiler; no-op when fresh)")
    sh(["make", "-s", "fpr"], cwd=FPR, quiet=True)


def build_qosp():
    say("qosp (portable host; no-op when fresh)")
    sh(["make", "-s", "portable"], cwd=QOS, quiet=True)


def build_native():
    say("qos-native.elf + disk.img")
    sh(["make", "-s", "native", "disk.img"], cwd=QOS, quiet=True)


def build_app(prog, harts=None):
    say(f"qos-app {prog}")
    target = "qos-app-macos" if sys.platform == "darwin" and os.uname().machine == "arm64" else "qos-app"
    cmd = ["make", "-s", target, f"PROG={prog}"]
    if harts:
        cmd.append(f"HARTS={harts}")
    sh(cmd, cwd=FPR, quiet=True)


# ---- commands ---------------------------------------------------------------

def cmd_build(a):
    t0 = time.time()
    build_fpr()
    if a.what in ("all", "host"):
        build_qosp()
    if a.what in ("all", "native"):
        build_native()
    say(f"build done in {time.time() - t0:.1f}s")


def cmd_run(a):
    t0 = time.time()
    prog = resolve_prog(a.prog)
    build_fpr()

    if prog.endswith(".sol") or a.on == "sol": # type: ignore
        say(f"sol profile: {prog}")
        env = {"LD_LIBRARY_PATH": "/usr/lib/llvm-18/lib"}
        return run_scan([str(FPR / "fpr"), "sol", prog], cwd=FPR, env=env, expect=a.expect)
    if a.on == "virt":
        say(f"bare-metal QEMU virt: {prog}")
        cmd = ["make", "-s", "bare-metal-run", f"PROG={prog}"]
        if a.harts:
            cmd.append(f"HARTS={a.harts}")
        return run_scan(cmd, cwd=FPR, expect=a.expect)

    # the default: host the .qa on qosp
    build_app(prog, a.harts)
    build_qosp()
    env = {}
    if a.port:
        env["FPR_PORT"] = a.port
    if a.harts:
        env["FPR_HARTS"] = a.harts
    if a.fresh_disk:
        (QOS / "qosp.disk").unlink(missing_ok=True)
        say("qosp.disk: fresh")
    say(f"qosp: {prog}" + (f"  (port {a.port})" if a.port else ""))
    rc = run_scan(["./qosp", "--yes", "../fp-risc/app.qa"], cwd=QOS, env=env, expect=a.expect)
    say(f"total {time.time() - t0:.1f}s")

    return rc


def cmd_serve(a):
    prog = resolve_prog(a.prog)
    build_fpr()
    build_app(prog)
    build_qosp()
    say(f"serving {prog} at http://127.0.0.1:{a.port}/  (Ctrl-C stops)")

    return run_scan(["./qosp", "--yes", "../fp-risc/app.qa"], cwd=QOS, env={"FPR_PORT": a.port})


def cmd_native(a):
    build_fpr()
    build_native()
    disk = QOS / "disk.img"
    if a.apps:
        disk = QOS / "disk-seeded.img"
        say(f"seeding {disk.name} with {len(a.apps)} app(s)")
        sh([sys.executable, str(FPR / "tools" / "mkdisk.py"), str(disk),
            "8"] + [str(Path(p).resolve()) for p in a.apps], cwd=QOS)
    qemu = ["qemu-system-riscv64", "-accel", "tcg,thread=multi",
            "-machine", "virt", "-smp", str(a.smp), "-m", a.mem,
            "-nographic", "-bios", "none", "-kernel", "qos-native.elf",
            "-drive", f"file={disk},if=none,format=raw,id=hd0",
            "-device", "virtio-blk-device,drive=hd0"]
    if a.smoke:
        say("smoke boot (scripted, ~10s)")

        p = subprocess.Popen(qemu, cwd=QOS, stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.DEVNULL)

        p.stdin.write(b"yyyy") # type: ignore
        p.stdin.flush() # type: ignore
        t0, buf = time.time(), b""
        ok = False
        while time.time() - t0 < 20:
            b = p.stdout.read1(4096) # type: ignore
            if not b:
                break
            buf += b
            if b"app launcher" in buf:
                ok = True
                break
        p.kill()
        if not ok:
            die("smoke boot: launcher never appeared")
        say(f"launcher up at +{time.time() - t0:.2f}s")
        return 0

    say(f"booting QOS Native ({a.smp} harts, {a.mem}, {disk.name}) -- " "q quits the launcher; C-a x kills QEMU")
    return subprocess.call(qemu, cwd=QOS)

def cmd_disk(a):
    build_fpr()  # apps may have just been rebuilt; mkdisk itself is pure
    say(f"mkdisk {a.img} ({a.size_mb}MB, {len(a.apps)} app(s))")
    sh([sys.executable, str(FPR / "tools" / "mkdisk.py"), a.img, str(a.size_mb)] + a.apps, cwd=Path.cwd())

def cmd_commit(a):
    build_fpr()
    mod = resolve_prog(a.mod)
    return sh([str(FPR / "fpr"), "commit"] + (["--major"] if a.major else []) + [mod], cwd=FPR, check=False)

SMOKE = [
    # (label, list-of-(prog, backend, expect))
    ("hello / qosp",      "tests/hello.fpr",    "qosp", "hello from a .qa"),
    ("mvu engine",        "tests/mvutick.fpr",  "qosp", "4 statics builds"),
    ("disk v2",           "tests/qdisk2.fpr",   "qosp", "torn=True"),
    ("dtree == GHC",      "tests/dtree.fpr",    "qosp", "root split: col 1"),
    ("bigfree",           "tests/bigfree.fpr",  "qosp", "BIGFREE HOLDS"),
    ("fmath / virt",      "tests/fmath.fpr",    "virt", "FMATH HOLDS"),
    ("autodrop / virt",   "tests/autodrop.fpr", "virt", "AUTODROP HOLDS"),
    ("bigframe / virt",   "tests/bigframe.fpr", "virt", "sum3=57569"),
]

def cmd_test(a):
    if a.all:
        say("the full sweep (check-all.sh; ~12-15 min)")
        return subprocess.call(["sh", "check-all.sh"], cwd=ROOT)
    build_fpr()
    build_qosp()
    t0 = time.time()
    fails = []
    ran = 0
    for label, prog, backend, expect in SMOKE:
        if a.legs and not any(k in label or k in prog for k in a.legs):
            continue
        if backend == "qosp":
            build_app(prog)
            r = subprocess.run(["./qosp", "--yes", "../fp-risc/app.qa"], cwd=QOS, capture_output=True, timeout=180)
            out = r.stdout.decode("utf-8", "replace")
        else:
            r = subprocess.run(["make", "-s", "bare-metal-run", f"PROG={prog}"], cwd=FPR, capture_output=True, timeout=300)
            out = r.stdout.decode("utf-8", "replace")
        ok = expect in out
        ran += 1
        say(f"{'ok  ' if ok else 'FAIL'} {label}")
        if not ok:
            fails.append(label)
    # the multi-client LiveView wire rides its own script
    if not a.legs or any("web" in k or "live" in k for k in a.legs):
        r = subprocess.run(["sh", "tests-host/mvuweb-check.sh"], cwd=QOS, capture_output=True, timeout=300)
        ok = b"ALL LEGS PASS" in r.stdout
        ran += 1
        say(f"{'ok  ' if ok else 'FAIL'} liveview multi-client")
        if not ok:
            fails.append("liveview")
    say(f"smoke: {ran - len(fails)}/{ran} in {time.time() - t0:.0f}s")
    if fails:
        die("failed: " + ", ".join(fails))

def cmd_clean(a):
    sh(["make", "-s", "clean"], cwd=FPR, quiet=True, check=False)
    sh(["make", "-s", "clean"], cwd=QOS, quiet=True, check=False)
    say("clean")

def main():
    ap = argparse.ArgumentParser(prog="qos.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("build", help="bring the toolchain + hosts up to date")
    p.add_argument("what", nargs="?", default="host", choices=["fpr", "host", "native", "all"])
    p.set_defaults(f=cmd_build)

    p = sub.add_parser("run", help="compile + run one program (the pipeline)")
    p.add_argument("prog", help=".fpr or .sol, from anywhere in the tree")
    p.add_argument("--on", choices=["qosp", "virt", "sol"], default="qosp", help="qosp (hosted, default) | virt (bare-metal QEMU) | sol")
    p.add_argument("--port", help="FPR_PORT for the socket tier")
    p.add_argument("--harts", help="hart count")
    p.add_argument("--fresh-disk", action="store_true", help="delete qosp.disk first")
    p.add_argument("--expect", help="require this substring in the output")
    p.set_defaults(f=cmd_run)

    p = sub.add_parser("serve", help="host a LiveView app on a port")
    p.add_argument("prog")
    p.add_argument("--port", default="8000")
    p.set_defaults(f=cmd_serve)

    p = sub.add_parser("native", help="build + boot QOS Native under QEMU")
    p.add_argument("--apps", nargs="*", default=[], help=".qa files to seed onto a fresh disk image")
    p.add_argument("--smp", type=int, default=2)
    p.add_argument("--mem", default="256M")
    p.add_argument("--smoke", action="store_true", help="scripted boot-to-launcher check instead of a console")
    p.set_defaults(f=cmd_native)

    p = sub.add_parser("disk", help="seed a QLOG disk image (mkdisk)")
    p.add_argument("img")
    p.add_argument("size_mb", type=int)
    p.add_argument("apps", nargs="*")
    p.set_defaults(f=cmd_disk)

    p = sub.add_parser("commit", help="fpr commit into the .fpr store")
    p.add_argument("mod")
    p.add_argument("--major", action="store_true")
    p.set_defaults(f=cmd_commit)

    p = sub.add_parser("test", help="the fast smoke set (--all = check-all)")
    p.add_argument("legs", nargs="*", help="filter by label/prog substring")
    p.add_argument("--all", action="store_true")
    p.set_defaults(f=cmd_test)

    p = sub.add_parser("clean")
    p.set_defaults(f=cmd_clean)

    a = ap.parse_args()
    sys.exit(a.f(a) or 0)

if __name__ == "__main__":
    main()
