# QOS Portable -- the hosting runtime (linux-x86-64)

QOS Portable is **not an OS**. QOS Native is the OS -- real HALs,
per-hart schedulers, real services, on our own hardware. QOS Portable
is a *hosting runtime* that runs ONE FP-RISC program, built for a
QOS host-arch (here **QOS-x86_64**, `fprc --target=qx64`) and packaged
as a `.qa`, by satisfying the program's std assumptions on top of a
host OS -- the relationship the JVM has to a `.jar`, or System.qa has
to a loaded process on virt. On a Linux box this is the process a
systemd unit would `ExecStart=` directly.

Two images, one address space:

    qosp app.qa
    ~~~~ ~~~~~~
    the host (hosted C,        the app (freestanding QOS-x86_64 ELF in
    libc, sockets, files)      a QAR1 archive: generated qx64 code +
                               its own runtime/core copy + the
                               table-dispatching HAL)

## The three stages, scaled to a host

The boot deliberately mirrors the QOS Native bootstrap design
(Initializer -> Loader -> user-level QOS), with each stage doing what
that stage MEANS, minus what a host OS already provides:

1. **Initializer** (`runtime/portable/main.c` stage 1 + `haltab.c`) --
   "test the hardware, build the HAL table". The hardware test is: can
   the fixed arena actually be mapped at the address the app was
   linked against (`mmap MAP_FIXED_NOREPLACE`)? The HAL is built as
   the design states it: **a table of in-memory C ABI functions,
   delivered as one C pointer** (`qos_hal_t`, qos_abi.h). TRACE output
   via `--trace` / `QOSP_TRACE`, off by default.
2. **Loader** (stage 2) -- buddy allocator over the arena; read the
   `.qa`, parse the manifest, run the permission gate (required
   permissions are compulsory -- any denial refuses the launch,
   docs/QA-FORMAT.md's exact rule); reserve the image slot; elfload
   the ELF; assemble the boot record.
3. **The app's world** (stage 3) -- control passes to `qos_app_entry`
   and the app's own linked scheduler runs its actors. There is no
   Memory.qa / System.qa process tier because there is only one
   program: the growth callback IS the Memory.qa analogue (buddy
   grants from the host arena), the storage trampoline the System.qa
   one (`store.c`: tag 2 kv append / tag 3 replay onto
   `qos-store/<id>.kv`, capability-scoped by construction -- the app
   never names a path).

## The ABI (runtime/qosapp/qos_abi.h)

Everything crossing the host/app boundary is fixed-width C ABI data in
one versioned boot record: the HAL table pointer, the heap grant, the
growth callback, the serialized capability grant (System.qa's
`"appid\nurl mode\n"` format unchanged -- `Sys.caps` reads it, the
FPRISC side enforces it), and the storage syscall. The app's result
returns as a RENDERED string, not a V: the host has no FPRISC runtime
to interpret one.

The app image contains **no libc and no syscalls**. Every effect goes
through the table; the table's entries are the app's runtime
capability surface, and the link-time `fpr_g_` import set remains the
static one, exactly as on bare metal. The isolation is build-time, per
the hosted-target design: codegen never emits raw syscalls, and here
even the HAL's libc lives in the *other image*.

## QOS-x86_64: what the target means

`--target=qx64` is the plain x64 lowering plus one refinement
(X64.hs `deTlsQosApp`): the three thread-local cells the hosted
lowering uses (`fpr_posix_hart`, `fpr_x64_a6/a7`) become **plain
globals loaded RIP-relative**. Two reasons, both structural: a loaded
app is single-hart in this design pass (one hart = one writer, so a
global is correct), and a fixed-slot image has no dynamic loader
behind it -- nothing registers a TLS block, and link-time `@tpoff`
constants would index the HOST's `%fs` TCB. `FPR_QOSAPP` (fpr.h)
makes the C runtime's declarations match.

Fixed-slot loading means what it means on virt
(docs/PROCESS-LOADING.md): no relocation; internal references survive
because nothing moves; and there are no external references at all --
the table replaced them. The one improvement over the virt flow: the
slot address is a **published constant** (`QOS_SLOT_BASE`, 0x40000000),
not an address extracted from a system.elf symbol table, so an app.qa
built today loads under any qosp built tomorrow. link-qosapp.ld,
build-portable-app.sh, the Makefile, and qos_abi.h must agree on it
(the Makefile passes `--defsym` from one variable).

## The device story

The raw hosted device tier was factored out of runtime/posix/net.c
into **runtime/posix/net_raw.c** (plain C, no fpr.h): sockets, the
uart/clint pseudo-bus, discovery-by-name. It now has exactly two
consumers with one implementation:

- posix.bin: thin V-typed FPR_FN wrappers (net.c) -- the co-compiled
  hosted HAL, unchanged surface.
- qosp: the same functions as qos_hal_t table entries (haltab.c).

So `device "uart"`, LSR polling, mtime reads, and
netPoll/netRead/netWrite/netClose behave identically under both, and
programs/httpd.fpr serves its REST API unchanged from inside a `.qa`.

**The gfx tier crosses the table the same way** (GFX=1). The ES 3.1
renderer was split like net: runtime/posix/gfx.c is now the raw core
(gfx_raw.h -- context setup, the scene-value walker, FBO readback,
kbd/mouse polling) and gfx_fpr.c the V-typed wrappers for co-compiled
images; a GFX=1 qosp compiles the raw core into the HOST and fills the
table's nullable gfx entries. The one deliberate subtlety:
`gfx_render` receives the app's scene VALUE and the host walks it
READ-ONLY through the shared fpr.h layout -- valid because the two
images share one address space -- while all V-result construction
(the (draws, dynBytes) pair, input triples) happens app-side with the
app's own allocator, so no allocation ever crosses the boundary.
Mesa's dynamic linking stays concentrated in the host image (the one
boundary the static philosophy concedes); the app is freestanding
either way, and programs/gfxdemo.fpr renders pixel-identical frames
from inside a `.qa` (verified against the co-compiled path under
llvmpipe). A host built without GFX=1 leaves the entries NULL and the
app-side shim reports the missing capability honestly, stubs.c-style.

**Input is evdev** (runtime/posix/evdev_raw.c, behind the same
inputPoll capability). The reader consumes `struct input_event`
records -- the evdev wire format, what libevdev parses -- from the fd
FPR_EVDEV names, so ONE reader serves a real /dev/input/eventN (the Pi
console target), a live simulated keyboard (tools/kbdsim.py feeding a
FIFO), or a pre-baked event file for deterministic replay; kbdsim's
--uinput mode creates a genuine kernel virtual keyboard where
/dev/uinput exists. Raw evdev rather than libevdev-the-library, per
the input-stack decision: control input needs no layout translation
and static images want no extra dynamic dependency. EV_KEY events
surface as input kind 4, (4, keycode, value) with press/release/repeat
distinct -- which stdin can't say -- and inputPoll now always returns
a uniform (kind, a, b) triple, kind 0 = none (the Mod.resolve
"a miss is data" convention, so the typed layer can case on it).
programs/mvu3d.fpr is the reference: an explicitly MVU-structured 3D
program (model = data, pure update per event, pure view -> scene,
render only on model change, session bounded by clint mtime through
the register tier) that replays a kbdsim script to pixel-identical
frames, co-compiled and as a `.qa`.

Missing capabilities stay honest in both directions: an unknown device
name or unmapped register is an immediate loud failure. Windowed
presentation and the Pi KMS/DRM+GBM+EGL path slot in as additional
table entries in the host, exactly this shape.

## Building and running

    make qosp                                  # the host, once
    make portable-run PROG=tests/orig1.fpr     # compile + package + run
    tools/build-portable-app.sh programs/httpd.fpr   # standalone flow
    ./qosp app.qa                              # interactive permission gate
    ./qosp --yes app.qa                        # auto-grant (CI)

Flags/env: `--yes`/`QOSP_YES` auto-grants, `--trace`/`QOSP_TRACE`
narrates the stages, `FPR_PORT` picks the net port (default 8000).

## Not yet

- Multi-hart apps (the entry fabricates one hart; SMP-within-a-process
  is future work on virt too).
- aarch64 (a `qa64` target is the same one-pass de-TLS over A64.hs's
  lowering; the ABI header is already word-size clean).
- TLS-terminating net tier; blocking service actors parked on real
  syscalls (polling today, like virt and posix).

## Multi-hart (ABI v2): the TLS borrow

v1 apps were single-hart for one structural reason: the de-TLS pass.
A fixed-slot .qa has no loader-registered TLS block, so the three
thread-local cells (the hart pointer; x64's a6/a7 arg-staging cells)
were rewritten to plain globals -- correct only while one hart meant
one writer.

v2 keeps the image TLS-free and gets per-hart cells anyway by
BORROWING THE HOST'S TLS.  qosp declares one `__thread` borrow block
`{hart, a6, a7}` per hart thread and publishes its displacement from
the thread pointer in the boot record (`tls_off`); the executable's
static TLS block sits at the same displacement in every thread, so one
constant serves all harts.  entry.c lands it in the plain global
`fpr_g_tlsoff` before anything else runs; `--target=qx64/qa64` rewrite
every TLS access to index through it (x64: a two-instruction load, and
push/pop-guarded stores for the staging cells; a64: the same
four-instruction footprint with x16 scratch), and fpr.h's FPR_QOSAPP
accessors give the shared C runtime the identical view.

Threads come from the host -- the app is freestanding -- via the
appended-at-the-end `hal.start_hart` (NULLABLE: a NULL is an honest
single-hart host).  `hal.nharts` is the host's RESOLVED count: env
`FPR_HARTS`, else the online-core count; the app clamps to its own
compile cap (`QOSHARTS`, default 8) and `Sys.harts`/`harts` report the
live number.  The scheduler's scans, the deadlock detector, and
spawnOn bounds all follow `fpr_live_harts`; explicit `spawnOn`
placement now PINS an actor (the donation tier skips it) -- placement
is an affinity contract, which is exactly what a GL-owning service
actor needs.  `FPR_HARTS=1` is the determinism switch: those runs stay
byte-identical to posix.bin and to qa64 under qemu.

Two host-side truths this surfaced: a plain rw anonymous mapping is
NOT executable on modern Linux (the r-x mprotect over the image's PF_X
prefix now runs on every host, not just Darwin), and the linker
scripts now emit two PT_LOADs (text+rodata r-x / data+bss rw, 64 KiB
apart) so that boundary is real on 4 KiB and 16 KiB page hosts alike.

## pshell: the startup shell (programs/pshell.fpr)

A keyboard-driven 2D shell rendered entirely through the scene
walker's GLES backend.  mods/scene2d.fpr is the gen_view bridge: a
Box/Lbl/Slot view AST with typed attrs, an integer measure/place
layout in 320x240 virtual pixels, a 3x5 rect font, and `build tree ->
(statics, slots)` / `dyns slots vals` -- the LiveView static/dynamic
split mapped onto the walker's static/dynamic GPU buffers.  Statics
recompile only when the retained statics VALUE changes (screen or
focus), which the walker now detects by value identity; steady-state
frames re-upload only the changed glyphs, and the RENDER tile shows
the walker's own draws/dynBytes as the proof.

The shell is gfxdemo's service-actor architecture with the graphics
and display actors `spawnOn 0` (pinned; the EGL context is
thread-bound and gfx.c also rebinds defensively on a thread change),
and a fresh worker actor per frame (voxel-interactive's shape) so
per-frame allocation dies with its actor.  NOTES commits persist
through `Sys.storeReq` -- the qosp kv trampoline, or an `FPR_STORE`
file on co-compiled posix, same framing -- and replay at boot.

    tools/pshell-check.sh          # both paths, snapshots, persistence
    systemd/qos-pshell.service     # the SBC boot story
    tools/kbdsim.py --tty FIFO     # the ssh virtual keyboard (raw
                                   # termios in, evdev bytes out)
