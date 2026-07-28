# runtime/posix — the hosted HAL: libc as the board

FPRISC programs compile to **self-contained static Linux executables**:
the full bare-metal runtime — buddy allocator, per-actor slabs, the
actor scheduler with per-sender SPSC mailboxes, fuel preemption, the
deadlock detector — linked against a HAL whose "board" is libc.

    make posix-run PROG=tests/actors.fpr                # x86-64, native
    make posix-run POSIXARCH=a64 PROG=tests/orig1.fpr   # aarch64 via qemu-user
    make posix.bin PROG=programs/httpd.fpr && ./posix.bin
    curl localhost:8000/run -d '{"prog":"1 2 + ."}'

## What is shared and what is per-host

`runtime/core/actors.c` is the bare-metal scheduler, byte-for-byte:
it turned out to be portable C11 atomics plus exactly three machine
obligations, and the posix HAL satisfies those instead of replacing
the design:

- **fpr_ctx_switch** — ctx_x64.S / ctx_a64.S, the cooperative switch
  (callee-saved integer state only, same contract as virt/ctx.S).
- **fpr_ctx_fabricate** — first-activation state (hal.c); x86 fakes
  post-`call` stack alignment with an 8-byte bias.
- **hal_wfi / ipi / timer** — the CLINT doorbells become a 200µs
  nanosleep poll; every wake path re-checks its rings afterwards, so
  the block/wake CAS protocol is untouched.  A futex per hart is the
  obvious upgrade; correctness does not depend on it.

Harts are **pthreads** (POSIXHARTS, default 2), `fpr_posix_hart` is
`__thread`, and generated code TLS-loads it wherever rv64 code reads
tp.  This is the P4 bring-up plan's shape — N actors multiplexed onto
a fixed few kernel threads — prototyped on Linux first.

## Devices

Discovery is the same table-by-name contract as virt hal.c:

- **uart** — a 16550-ish register model over stdio: LSR polling and
  THR writes work, so console programs run unchanged (stubs.c holds
  the reg8/read/write tier over pseudo-addresses).
- **clint** — mtime reads from CLOCK_MONOTONIC at virt's offset.
- **net** — netPoll/netRead/netWrite/netClose over BSD sockets
  (net.c), byte-compatible with virt's virtio-net surface: one
  connection at a time, actor-side polling.  FPR_PORT picks the port
  (default 8000).  programs/httpd.fpr compiles unchanged.
- **evdev keyboard** (with GFX=1's input tier) — evdev_raw.c reads
  `struct input_event` records from the fd FPR_EVDEV names: a real
  /dev/input/eventN, a tools/kbdsim.py FIFO (simulated keyboard), or a
  pre-baked event file (deterministic replay).  EV_KEY surfaces as
  input kind 4 with press/release distinct; inputPoll returns a
  uniform (kind, a, b) triple, kind 0 = none.  programs/mvu3d.fpr is
  the MVU-structured reference client.
- **gpu** (GFX=1) — gfx.c, a C port of the gl_scene ES 3.1 renderer:
  glInit / glRender / glSavePpm walk an FPRISC Scene VALUE (milli-unit
  fixed point) into instanced ES draws under surfaceless EGL, with the
  content-addressed mesh registry and static/dynamic split intact.
  inputPoll reads keyboard (stdin) and mouse (/dev/input/mice).  The
  GL context is thread-bound: exactly one graphics service actor owns
  it, pinned by the no-migration owner-hart model — its mailbox IS the
  GPU lock.  programs/gfxdemo.fpr is the URL-addressed reference:
  System discovery actor + graphics/display/input service actors.
  GFX=1 links dynamic (-no-pie): Mesa is the one boundary the static
  philosophy concedes, the way the kernel is for syscalls.
      make posix-run GFX=1 PROG=programs/gfxdemo.fpr

The capability story is build-time, as designed: the image's
unresolved `fpr_g_` imports ARE its capability manifest.  A program
that names a capability this HAL does not export fails at LINK time
with the capability's name; MMIO reads of unmapped addresses panic
with an honest message.

## The x86-64 lowering in one breath

compiler/X64.hs lowers the shared rv64 emission; the four mismatches
(hardware call/ret vs ra, SysV stack alignment, the rax/rdi arg0
split, two-operand arithmetic) each have a local rule documented in
its header.  Args 7/8 travel in TLS cells (fpr_x64_a6/a7) rather than
SysV stack slots so tail calls stay plain jmps — TCO holds at every
arity; runtime.c's cast table fills the cells at the C boundary.
Vec-loop specialization is disabled on x64 (six callee-saved
registers cannot host the s6+ loops); the generic C vec path runs
instead.  SSE/AVX column loops for SoA VLists are the natural next
step and slot in exactly where the RVV flag does today.

## Relation to QOS Portable

This HAL CO-COMPILES program + runtime into one hosted binary. QOS
Portable (runtime/portable + runtime/qosapp, docs/QOS-PORTABLE.md) is
the other discipline over the SAME device tier: the program is a
separately built QOS-x86_64 `.qa` loaded fixed-slot by the `qosp`
host, with dispatch through a HAL table instead of link-time binding.
net.c's raw I/O was factored into net_raw.c, and gfx.c into a raw
renderer core (gfx_raw.h) + gfx_fpr.c V-wrappers, so both disciplines
share one socket/pseudo-bus and one renderer implementation.

## macOS (Apple Silicon)

`make posix-run POSIXARCH=a64` on a Darwin host builds and runs
NATIVELY: the Makefile detects Darwin and switches fprc to
`--target=a64mac` — the promised syntax layer over the same a64
lowering.  Four differences, all in A64.hs:

- every C-visible symbol grows the Mach-O underscore (definitions,
  .globl, call/la/.quad references); `.L` locals become `L`, the
  assembler-private prefix; `.section .rodata` becomes `__TEXT,__const`.
- `adrp/:lo12:` becomes `adrp _sym@PAGE` / `add _sym@PAGEOFF`.
- big immediates are movz/movk chains on BOTH syntaxes now (the old
  `ldr =imm` literal pool was gas-ELF-only; the Linux a64 suite
  regression-tests the shared encoding).
- `mv rd, tp` (the per-entry fuel-cell read) cannot be a local-exec
  `:tprel:` load — Darwin TLS is TLV descriptors.  The lowering emits
  the standard Darwin sequence (adrp/ldr the descriptor, blr its
  thunk), safe mid-function because dyld's `_tlv_get_addr` preserves
  every register except x0/x16/x17; x0 (arg0) and x30 (ra) are saved
  around it.  The C side's `__thread` hart cell uses the same TLV
  machinery, so both sides agree by construction.

The runtime side: heap.S grows a Mach-O branch (an ordered `.zerofill`
group standing in for the .bss label sequence — `nm -n` shows
`__heap_end` at exactly start + 64 MiB), ctx_a64.S spells its one
symbol through a `SYM()` cpp guard, and evdev_raw.c defines the
`input_event` wire struct locally off-Linux so the FPR_EVDEV
simulated-keyboard/replay tier stays portable.  Linking is dynamic —
Mach-O has no `-static`; libSystem is the concession, the way Mesa is
for GFX.  GFX=1 stays Linux-only (EGL/evdev hardware tier).

First boot on a Mac: `sh tools/mac-smoke.sh` (verifies the heap symbol
layout with nm, then runs the actor, typed-layer, svc-funnel, and
slab-churn tests).  Status: the full emission surface — every test
program plus the 207-supercombinator System.qa and httpd, with all
their units — assembles clean under `clang --target=arm64-apple-macos11`
(validated in CI-like fashion off-Mac); the runtime C is POSIX-clean by
inspection.  End-to-end link + run wants a real arm64 Mac, which is
what the smoke script is for.

## Not yet

- A System actor serving /services/net URL discovery over the socket
  tier (gfxdemo.fpr's registry actor is the shape; net still goes via
  the device table).  The `mods/svc.fpr` URL funnel is the front half
  of this: net joins as one more route behind `Svc.read`/`Svc.write`.
- Windowed presentation (a swap of displayActor's body + an EGL window
  surface) and the GBM render-node path for Pi hardware drivers.
- Blocking service actors parked on real syscalls (today: polling,
  like virt).
