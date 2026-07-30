# QOS — a vertically integrated FPRISC → RISC-V system

Naming, once and for all: the OS/platform is **QOS** (not "FPR OS"),
the compiled language is **FPRISC** (not "rhei0" or "sol" — `sol` is
reserved for the scripting language), and `.qa` = QOS App archive.

One repository holds the whole stack: the FPRISC compiler (Haskell →
RISC-V assembly), a bare-metal runtime (SMP actors, fuel preemption,
per-actor slab memory), System.qa (the app platform: permission-gated
capabilities, `.qa` apps loaded on demand from an append-only disk
log), a module system with separate compilation and content-addressed
identity, and a cell-buffer TUI engine — no libc, no OS underneath,
QEMU virt as the machine.

Runtime layout: `runtime/core` (portable runtime: allocator, actors,
prims), `runtime/virt` (QEMU-virt bare-metal machine layer: boot, ctx,
MMIO HAL, linker scripts), `runtime/qos` (app-side runtime for `.qa`
processes running ON QOS), `runtime/posix` (hosted HAL: libc-backed; x86-64 and aarch64 Linux as
static binaries, and macOS/Apple Silicon natively via `--target=a64mac`
— pthread-hart actors, sockets; see runtime/posix/README.md).

This file describes the system **as it stands**. The round-by-round
design log — why each piece got this way, including the essays on
value representation, the discoverable-symbol contract, tail calls,
the actor protocol, and everything since — is `docs/HISTORY.md`.

## Quickstart

    # toolchain: riscv64 gcc, qemu-system-riscv64/32, GHC 9.4+
    #            (fprc deps: megaparsec, mtl, containers; if cabal
    #             can't reach Hackage: cd compiler && ghc -O1 -o ../fprc Main.hs)
    make run PROG=tests/demo.fpr     # compile + boot one program
    make test                        # the whole regression suite
    make test TARGET=rv32            # same suite, 32-bit
    make run-system                  # boot System.qa (disk auto-seeded)

`make run-system` builds the `.qa` apps, seeds `disk.img` with them
(each as its own record on the append-only log, plus an index), and
boots System.qa, which asks for each app's permissions at launch.
QEMU exits cleanly on completion and with code 1 on panic (the sifive
test finisher via `hal_poweroff`), so everything is exit-code driven.

## Types: ML-style modules, row polymorphism, SString

The typed layer (July 2026) sits on top of the original untyped FPRISC
front-end, ported from the Sol scripting language's type system:

- **Sigs and structures.** `Foo = Sig { ... }.` declares a named row;
  `Bar = Struct Foo { ... }.` implements it. Generic code takes a
  `(s : Sig)` parameter; the compiler monomorphizes each call site by
  the concrete structure passed, so there is no runtime dictionary —
  `total (s : Add) xs` compiles to `total#Int` / `total#Str` clones.
- **HM + row polymorphism** (compiler/Infer.hs) infers and checks
  every program; operators (`+ - * /`) resolve by operand type — Int
  hits the primitive opcode, `Str.+` concatenates, and at a sig
  carrier the operator resolves to `s.(+)` internally (never surface
  syntax) and monomorphizes with the rest of the call.
- **The typed prelude** (programs/prelude.fpr) groups the HAL/runtime
  contract into namespaces: `Int`/`Str` (value structures implementing
  Arith/Eq/Ord/Add), `Actor` (send/recv/spawn/yield — namespace-only,
  since messages are polymorphic), `Mmio`/`Pin`/`Sys` (namespace-only
  HAL groupings), and `VList` (the SoA vector — namespace-only because
  `Vector` is a MONOMORPHIC opaque type with untyped columns, so it
  cannot satisfy a `t a`-shaped sig like `Functor`; that's a real
  type-theoretic fact, not an oversight — generic sequence code uses
  `List`, not `VList`). The flat HAL names (`send`, `strcat`,
  `Vec.push`) still work; the structures are additions.
- **SString**: a fixed 128-byte inline string (`SString 1 = Type Int.`,
  linear), backed by runtime/sstr.c. No heap, no ARC — the buffer lives
  wherever the caller put it, and linearity licenses in-place
  put/push/clear the same way it licenses Vector's in-place mutation.
  The width is hardcoded system-wide for now; `SString n` (an indexed/
  per-value width, bordering on dependent types) is a deliberate future
  step, not in this cut.
- **No JIT, no inline eval.** FPRISC is natively compiled to RISC-V
  assembly; there is no `> expr.` top-level evaluation (that is Sol's
  scripting-tier feature) and no JIT tier to keep in sync with types.

tests/typed.fpr exercises all of the above end-to-end on QEMU (operator
dispatch, structure methods, one generic monomorphized twice, SString,
VList) and is part of `make test`.

## Layout

    compiler/       fprc: FPRISC.hs (front), Codegen.hs, Modules.hs, Main.hs
    runtime/        crt0/ctx, runtime.c (alloc+ARC), actors.c, hal.c,
                    buddy.c, net.c, blk.c, vec.c, mod.c,
                    elfload.c + process.c + proc_entry.c (dynamic loading),
                    apps.c + apps_data.c (rodata fallback registry)
    programs/       the platform: prelude, system.fpr (System.qa),
                    vfsh2, stui, httpd, diskfs
    programs/mods/  `use` modules: tui (the TUI engine), qlog (the
                    storage log + actor), timefmt
    apps/           .qa manifests + app sources (hello_proc is a real
                    dynamically loaded process)
    tests/          the suite + run-tests.sh (`make test`)
    tools/          mkqa, genapps, mkdisk, build-process-app, tuidrive
    docs/           SYSTEM-QA, QA-FORMAT, PROCESS-LOADING, STORAGE,
                    PINS, HISTORY

## The compiler and the module system

`fprc` compiles FPRISC to RISC-V assembly. Programs are built from
**separately compiled units**: the prelude, every `use`d module, and
the root each become their own `.s`, cached in `build/units/` under
the module's content hash — the Merkle hash IS the build cache key,
so an unchanged module is never recompiled. Cross-unit references
stay *known* (direct calls, 0-ary `call`, `fpr_obj_` value refs)
because the importer parsed the dep for hashing anyway. Typeids and
record-shape ids are **content-addressed** (fnv32 of unit-hash + type
name / of the sorted field set), so separately compiled units agree
on them with no shared counter; fprc aborts loudly on collision.

Structs travel through modules like everything else (July 2026, ported
back from Sol): a module can expose its surface as one structure —
`Rand = Struct { next, ... }` — and a consumer writes `M = use "rmod".
Rand = M.Rand.` then `Rand.next s`; dotted references whose head is a
struct qualify the head only (`Rand@hash.next`), both for the module's
own self-references and through aliases, so the flat expanded globals
and the monomorphizer see the same names.

Two module tiers, per the design decision:
- **Local**: `use "localmod.fpr"` — unpinned, relative, extension
  optional — just works, Sol-style. Pin with `#<hash>` to freeze.
- **Hash identity by URL**: `Mod.resolve hash name → (1, fn) | (0, 0)`
  (a miss is data), fronted in System.qa by the `/services/modules`
  capability resolving `"<hash>/<fn>"` URLs — the FPRLive wire shape.
  Today's backend is the link-time module table; a disk module store
  or a remote peer slots in behind the same URL.

## The runtime

**Actors**: spawn / send / receive / receiveFrom / receiveRes / kill /
yield, per-sender SPSC channels, actors pinned to harts, cross-hart
wake rings, fuel preemption (generated code decrements `0(tp)` per
function entry), global deadlock detection. Sender-channel slots are
keyed by acb pointer and a DEAD sender's drained slot is CAS-stolen
by the next new sender.

**Memory (the slab model)**: buddy over the heap region is the one
lower allocator. Every actor owns a chain of slabs (bump-within,
per-actor recycle buckets with CAS push); stacks and acbs are buddy
blocks. Actor **death reclaims**: the stack always, each slab unless
it holds promoted objects — those slabs are orphaned and return to
buddy when their last ARC ref drops (escape counts live in slab
headers, under the ARC lock, so cross-actor references never dangle).
Process exit frees its growth grants; the process slot is the fixed
linked region at `0x88000000`, not an allocation. `tests/slab.fpr`
churns ~390 MiB of actors through the 64 MiB heap and requires
`arcLive` to settle to 0. `heapUsed` answers "bytes THIS actor has
bumped".

## System.qa — the app platform

Apps are `.qa` archives (mini-TOML manifest + payload,
`docs/QA-FORMAT.md`), **separate from System.qa's image and loaded
from disk on demand**: `tools/mkdisk.py` seeds `disk.img` with each
built `.qa` as its own log record plus an `apps/index` record;
System.qa discovers from the index and reads each `.qa` off the log
at launch (rodata is the diskless fallback). Every launch goes
through the permission gate; a capability is a granted `(url, mode)`.
ALL of app IO is two functions — `Svc.read caps url` and `Svc.write
caps url v` (programs/mods/svc.fpr, the Sol read/write collapse
upstreamed): one router derives the needed capability from the URL
itself ('/'-boundary prefix against the granted set), checks it ONCE,
and dispatches — display, keyboard(+/poll), clock, /services/modules
(miss is data), /services/storage/kv (the storage-actor RPC, with the
app-scoped kv URL built from the capability so cross-app addressing
stays structurally impossible), /pins/<n>(+/mode).  The historical
`svc*` names survive as wrappers over the funnel, so app code is
untouched; a service that forgets its own gate can no longer exist,
because services are not functions any more — they are routes.
tests/svcurl.fpr runs the router on the hosted HAL.  Apps never see a
device register.

Two load modes today:
- **process** (`docs/PROCESS-LOADING.md`): a real ELF, linked at the
  pinned slot, loaded by `Sys.loadElfAt`. The granted set rides the
  entry ABI as a serialized blob; the process reads it back with
  `Sys.caps` and enforces its own gate (hello_proc demonstrates:
  display denied ⇒ zero console bytes, a refusal string rendered by
  the loader).
- **name-dispatch** (deprecated, being retired): the three TUI apps
  are still co-compiled pending the port of their service surface to
  the process side; storage-for-processes needs either a syscall
  trampoline or async process execution — the open design question.

Apps render through `mods/tui.fpr` — packed cell buffers, vbox/hbox
fix/flex layout, borders, and the ANSI diff renderer — with every
emitting function taking a writer, so rendering flows through the
display capability. `svcPollKey` (nonblocking) is what makes apps
dynamic: the launcher ticks a live clock between keystrokes, the
clock app repaints only changed digit cells and rotates its colour
each minute, the notes editor live-persists each committed line.

## Storage

One append-only QLOG page log (`docs/STORAGE.md`) carries installed
`.qa`s, each app's persistent kv msg stream (`apps/<Id>/<Id>.kv` —
Sol's `Persistent` model as event sourcing: append msgs, replay
folds), and System.qa's boot beat. The log is owned by a storage
actor (`mods/qlog.fpr`) reached only through `/services/storage`; an
app's kv url is built FROM its capability, so cross-app addressing is
structurally impossible. Diskless boots degrade: storage answers
`Err "no disk"`. Planned next, in order: boot-scan index, per-url
URActors, GC sweep, and paging actors to `/actorchunks` (design fixed
in STORAGE.md; unblocked by the slab model).

## The test suite

`make test` runs `tests/run-tests.sh`: the program suite on rv64 and
rv32, each with pinned expected output, expected-panic support
(smpdead passes BY deadlocking), plus the two-boot storage
persistence regression and the ~390 MiB slab churn test. Everything
is exit-code driven.

## Honest current limitations

One process slot, run synchronously inside System.qa's launch call;
processes can't reach the storage actor yet (separate scheduler
state per image); the TUI apps are co-compiled until their services
port; QLOG reads stream the log index-free; net is the stated
single-connection PoC stack.
Each of these is a stated scope line, not an accident — the history
file records how every previous one of these lines got erased.

## FP-RISC + SOL CABAL

To install:

```
cabal install exe:fprc --installdir="$HOME/.local/bin" --install-method=copy
cabal install exe:sol  --installdir="$HOME/.local/bin" --install-method=copy

# IF LLVM 22
cabal install exe:sol --installdir="$HOME/.local/bin" --install-method=copy -f llvm22

# IF already installed
cabal install exe:sol --installdir="$HOME/.local/bin" --install-method=copy -f llvm22 --overwrite-policy=always
```

To delete:

```
rm ~/.local/bin/fprc ~/.local/bin/sol
rm -rf ~/.cabal/store/ghc-*/fprc-* ~/.cabal/store/ghc-*/sol-*
```

No need to source anything either if ~/.local/bin is symlinked.

On Mac:

```
make posix-run POSIXARCH=a64 PROG=tests/actors.fpr
```

When using build.sol, do e.g.

```
# first, change the input of the thing first, then the output will be built e.g. sched and out is the binary file sched-a64
sol tools/build.sol
./sched-a64
```
