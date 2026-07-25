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

## Not yet

- macOS/Mach-O (syntax layer on A64.hs, documented there).
- A System actor serving /services/net URL discovery over the socket
  tier (gfxdemo.fpr's registry actor is the shape; net still goes via
  the device table).
- Windowed presentation (a swap of displayActor's body + an EGL window
  surface) and the GBM render-node path for Pi hardware drivers.
- Blocking service actors parked on real syscalls (today: polling,
  like virt).
