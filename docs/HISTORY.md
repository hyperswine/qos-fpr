# QOS: the design history, round by round

This is the project's accreted build log -- every drop's sections,
preserved in order, exactly as they were written when each piece
landed.  It is a DESIGN RECORD, not current documentation: later
rounds overturn earlier ones on purpose (round 1's "cooperative only,
a spinning actor starves the rest" was made false by fuel preemption;
the per-hart arena essay was made false by the slab refactor; the
"stacks leak on death" and "process growth blocks leak" caveats are
gone as categories).  Where a section was amended in place after a
later change, the amendment says so inline.  For what the system IS,
read README.md and the docs/ set; come here for WHY it got that way.

---

## The pipeline

```
demo.fpr --FPRISC.hs--> Core --Codegen.hs--> prog.s --gcc--> image.elf
                                              ^
                     crt0.S + runtime.c + hal.c (the fpr_g_ contract)
```

## Value representation

Uniform 64-bit `V`: ints are `(n<<1)|1`; everything else is an
8-aligned pointer to `[u32 typeid | u32 variant | u64 fields...]`.
Runtime typeids sit far above user space: STR 9000, PAP 9001,
Device 9002, Register 9003, Array-Bit 9004 (FPRISC builtins are 0..6,
user types 10+, record shapes 100+).

## The discoverable-symbol contract

Codegen name resolution: local slot → known global → core prim
(operators, `str`/`strcat`, `error`) → **everything else becomes an
extern `fpr_g_<mangled>`**. The compiler prints the assumed set:

```
assumed external symbols (the fpr_g_ HAL/runtime contract):
  BITMASK BITSET BITSHIFTR BITTEST band bitsBE bitsLE charAt device
  read reg32 reg8 strlen toInt write
```

`hal.c` satisfies it with static objects: PAPs pointing at C functions,
plus a single `device` lookup (see below). Linking a FPRISC program
against a different HAL retargets it; an unsatisfied name is a **link
error, not a runtime surprise** — the contract is checked before
anything boots.

## Devices are a table, not link symbols

`hal.c` holds one `devtable[]` array — `{name, dev_t, setup, ioctl}` per
peripheral — and FPRISC code does `device "uart"` to look one up by name
(linear scan; fine for a handful of devices, a real HAL would want a
sorted table or a build-time perfect hash). This is deliberately the
same shape the boot ROM's `fdt_parse` (see qos-boot-poc) would
populate: swap the static initializer for a DTB walk and nothing above
`hal.c` changes. `setup`/`ioctl` are optional per-device escape hatches
for behavior generic `read`/`write` on a flat register can't express
(DMA descriptor init, IRQ enable, ...) — `NULL` when unneeded.

## Tail calls and direct calls

Saturated applications of statically known targets (top-level globals
AND core prims — runtime.c exports `fpr_prim_fn_*` symbols precisely
for this) compile to **direct calls**: no `fpr_apply`, no intermediate
PAP allocation. In tail position they compile to frame teardown + `j`,
which generalizes TCO from self-recursion to **any** known saturated
tail call, mutual recursion included — the target builds its own frame
and returns straight to our caller through the restored `ra`.

Validation: a 5,000,000-deep self-recursive countdown previously died
of *heap* exhaustion (one intermediate PAP per `-`/`==` per iteration)
after TCO fixed the stack. With direct calls it completes with O(1)
stack **and** O(1) heap.

Partial application, over-saturation, computed heads, and `fpr_g_*`
HAL/runtime calls (whose arities the compiler deliberately does not
know) still go through `fpr_apply` — those intermediate PAPs still
allocate and are not reclaimed (freeing a consumed PAP is only safe
once compiler-inserted RC exists: a user-bound partial application can
be applied twice).

## Actors: spawn / send / receive / kill / yield / myself

`runtime/actors.c` + `runtime/ctx.S`, arriving through the same
`fpr_g_*` contract as the devices — **the compiler knows nothing about
actors**. Cooperative, single-hart, deliberately the one-hart shadow of
the QOS design:

- every actor is an ACB: own 32 KiB stack, own 64-slot ring mailbox,
  saved context (`ra sp gp tp s0..s11` — a ~40-line asm switch)
- `main` **is** actor 0, on the boot stack; no privileged scheduler
  thread, just whoever runs handing off via `fpr_ctx_switch`
- servers are plain tail-recursive FPRISC functions; state is the
  accumulator argument (Erlang shape), O(1) stack via TCO
- `spawn f` runs `f self`; body returning = actor death; `kill` marks
  DEAD (skipped when dequeued, self-kill switches away forever);
  send-to-dead is a silent no-op; program lives exactly as long as
  main's body; all-blocked = loud deadlock panic
- on one hart there's no concurrency so the mailbox needs no fences;
  the multi-hart runtime is where the Maude-verified SPSC + fence
  discipline slots in unchanged

### ARC promotion on send

The rule from the design discussion: basic values (tagged ints) cross
actor boundaries **by value**; anything heap-allocated is **promoted**
on `send` — an entry in a refcount table, count = cross-actor shares.
Statics (rodata strings, prim PAPs, devices) are immortal and exempt
via the heap-range check. `drop` decrefs; at zero the object returns
to the allocator's free list (the size-header + segregated-free-list
allocator upgrade exists exactly to make this reclamation real). Drops
are manual in the demos, standing in for the compiler's RC-insertion
pass. Reclamation is shallow — objects don't carry field counts; a
16-byte header (ABI v2) fixes that and deep equality at once.

Validation: `tests/ring.fpr` runs a **true 4-actor cycle** (knot
tied by delivering each hop its neighbor as its first message) passing
a token 100,000 hops — 100k promote/drop cycles through the ARC table
and free list, ~100k context switches, ending with `arcLive == 4`
(exactly the four never-dropped neighbor handles). This test found a
real bug: open-addressing deletion without tombstone reuse fills the
table at ~1k cycles; the probe now reuses the first tombstone seen.

## Full original FPRISC restored

`compiler/FPRISC.hs` is the complete original PoC again: the host
evaluator and the **linearity checker** are back, and `fprc` runs the
checker before codegen (compile aborts on violations — double-use or
non-use of a `Handle` is rejected exactly as in the original).
`programs/prelude.fpr` is prepended to every build: pure-FPRISC
`fromTo`/`mapV`/`sumV`, the SoA-style `zipV`/`fstV`/`sndV`/`mapFstV`/
`mapSndV`, and the linear `Handle` **with signatures**, which is what
feeds the checker its shapes.

New core prims wired through to the target: `print` (renders to UART,
matching the host evaluator's `render` — lists `[7, 8]`, atoms
`:done`, records `<t.v>`), `String.len`, and `!` (1-indexed list
lookup). `crt0` now hands main's return value to `fpr_exit`, which
prints `main => <value>` — so the value-returning original demos have
visible results on target.

All five original demos (`tests/orig1..5.fpr`) run on QEMU and
produce the hand-computed answers: the linear-handle pipeline (1341),
ML-style structures/functors/operator-shadowing, the SoA vector demo
(585), same-field-name shape dispatch (60), and the full syntax-sugar
torture test.

## What the demos prove (all passing)

- `demo.fpr` — devices: SCR/LCR write-readback, mtime, Array Bit
  endianness, hex printing via bit ops, console in FPRISC over raw MMIO
- `actors.fpr` — echo + stateful counter servers, cross-actor
  round-trips, ARC counts matching hand-prediction, kill semantics
- `ring.fpr` — the 100k-hop cycle above
- `orig1..5.fpr` — the original FPRISC demos, unmodified, on bare metal

```
make run PROG=tests/actors.fpr
```

## The glue: Device / Register / Array Bit

- `reg8 dev off` / `reg32 dev off` → Register (width in the header)
- `read r` → Int, `write r v` → Unit (v may be Int or Array Bit)
- `bitsLE len v` / `bitsBE len v` / `toInt b`; BITSET/BITCLEAR/BITTEST
  index by *endianness semantics* (LE: bit 0 = LSB; BE: bit 0 = MSB),
  value canonical form stays LSB-0
- BITMASK/BITSHIFTL/BITSHIFTR/band/bor/bxor on ints

Why MMIO can't be optimized away or reordered, at three layers:
1. codegen is naive by construction — every application is a real
   `call`, no CSE/DCE/code motion exists to elide anything;
2. the C side dereferences `volatile` pointers;
3. `fence io,io` on both sides of each access pins device order to
   program order even on weakly-ordered real hardware.

## What the demo proves (all passing)

- console (`putc`/`puts`) written in FPRISC against raw LSR/THR registers
- UART SCR write/readback and LCR 8N1-via-BITSET readback: real
  round-trips through the device model
- CLINT mtime read twice across a print: advancing
- Array Bit LE/BE indexing divergence on the same value
- hex printer built from BITSHIFTR + BITMASK + band
- string interpolation (`"{expr}"` → strcat/str prims)


## The VFS shell: a URL-actor namespace with an MVU terminal on top

*(v1 — superseded by vfsh2 in round 2 below; the v1 source is removed,
this section is retained for the two design lessons at its end.)*

`vfsh.fpr` (was `make run PROG=programs/vfsh.fpr`, then type) was the
one-hart shadow of the QOS namespace design, all in FPRISC:

- **vfs actor** owns the tree (`FNode content | DNode entries | MNode
  actor`). Requests are `(replyTo, Ls|Cat|Stat path)` with the path as a
  segment list; replies are `Ok/Err`. Resolution that reaches an `MNode`
  always yields a forward: the vfs swaps in the path remainder, relays
  the app's reply, and knows nothing else about it — Plan 9 with
  mailboxes. `ls` marks mounts with `@`.
- **/proc** is an actor answering from live hardware: `cat /proc/uptime`
  reads the CLINT mtime at the moment of the read; `/proc/arc` and
  `/proc/heap` expose the runtime's own accounting.
- **/apps/counter** is an actor answering from live state: every
  `cat value` returns the count and bumps it — state is the server
  loop's tail-call accumulator, reads have side effects on purpose.
  `cd /apps/counter` works; relative paths resolve through the forward.
- **reader actor** polls UART RX (yield per miss), echoes, handles
  BS/DEL as `\b \b`, and sends completed lines as `Line s`.
- **terminal is main (actor 0)**, an MVU app: Model = `(cwd, pending)`,
  Msg = `Line`, view = the prompt, update = parse → VFS RPC → recurse.
  `ls cd cat stat pwd help exit`; `.`/`..`/absolute/relative paths;
  `exit` returns from main's body, which halts the machine — the
  program IS the session.

Two lessons the PoC taught immediately:

1. **The single-FIFO-mailbox interleave bug is real.** While the
   terminal awaits a VFS reply, the reader can deliver the next line
   first; the first scripted run panicked on it within four commands.
   The fix here is typed messages + stash-and-replay (`rpcWait` collects
   `Line`s, the loop drains them before blocking): selective receive,
   emulated. The real runtime's per-sender SPSC mailboxes make the
   problem structurally impossible — this is that design decision,
   earned empirically on 200 lines of shell.
2. **Codegen facts dictate allocation discipline.** 0-ary globals
   re-evaluate per reference, so registers are made once in `main` and
   threaded as arguments (accidentally the linear-token MMIO shape).
   The RX idle spin tests LSR bits with core-prim arithmetic (direct
   calls) instead of `BITTEST` (2-ary `fpr_g_` = one leaked PAP per
   call): verified via `cat /proc/heap` — per-command heap delta is a
   constant 16,272 bytes whether the gap contains 0.4 s or 5 s of idle
   polling. The per-command churn (mostly `write` PAPs, one per TX
   char) is the acknowledged leak that compiler-inserted RC erases;
   it bounds a session at ~2k commands on the 32 MiB heap.

New runtime prims: `chr : Int -> String` (inverse of `charAt`; the line
editor and splitter build strings with it) and `heapUsed` (bump-pointer
high-water, served at `/proc/heap`).

## Honest PoC simplifications

- **RC is manual** (`drop`): compiler-inserted RC — the pass your real
  pipeline already designs for — is what makes it automatic and makes
  freeing consumed apply-chain PAPs safe. Until then those PAPs leak.
- **Shallow ARC reclamation**: no field counts in headers (ABI v2)
- **Cooperative only**: a spinning actor starves the rest; `yield`
  provided; preemption = hardware timer, i.e. the real runtime's job
- Actor stacks (32 KiB) exceed the free-list max and leak on death
- Every application goes through `fpr_apply` (no direct-call
  optimization for saturated known calls)
- `==` is shallow on compound data (ints/strings/nullary tags only)
- `CIf` branches on the variant word assuming a Bool (well-typed
  programs only); arity ≤ 8; local recursive functions unsupported
  (recursion must be top-level — `CLet` is non-recursive)
- Linearity checker from FPRISC not wired in (this build drops the
  evaluator/checker; the real pipeline runs it before codegen)

## round 2: per-sender mailboxes, fuel scheduling, programs in the namespace

### per-sender SPSC channels (`runtime/actors.c`, rewritten)

Each actor now owns 8 lazily-bound single-producer channels (one per
sender, bound on first send) instead of one shared ring. This is the
same protocol shape the Maude model verified: no multi-writer ring, so
no write-write races to reason about, and FIFO is a *per-sender*
guarantee — exactly what the actor algebra needs and nothing more.

Three receive operations:

* `receive me` — fair round-robin over channels (rotating scan cursor)
* `receiveFrom me sender` — selective by sender, that channel only
* `receiveRes me` — selective by *type*: next `Ok`/`Err` from anyone,
  scanning past (and preserving) non-Result messages, Erlang-style.
  This is what "await the RPC reply" means once requests are forwarded:
  the client can't know who will answer.

Wake discipline stays dumb on purpose: senders wake blocked receivers
unconditionally; receivers re-check their predicate and re-block.
Spurious wakes are cheap; missed wakes are bugs. We buy the former to
structurally exclude the latter.

### fuel: compiler-inserted preemption (`compiler/Codegen.hs`)

Every supercombinator entry decrements a global fuel counter and traps
to the scheduler at zero (~4 instructions on the fast path, after the
arg spill so the safepoint call clobbers nothing live). Function entry
is the one safepoint every FPRISC loop must pass through: after lambda
lifting, any loop is a tail call to a top-level function — there is no
allocation-free, call-free way to spin. `vfsh2`'s clock program proves
the point: an actor that never yields and never blocks, counting down
in a tight tail loop, and the shell stays responsive through ~22k
involuntary preemptions per session. Cooperative scheduling with a
compiler-held knife.

`/proc/fuel` reports the quantum and preemption count.

### vfsh2: multiple programs, one namespace (`programs/vfsh2.fpr`)

Two independent programs boot alongside the shell and register
themselves in the tree at runtime via a `Mount` request — `/srv` is a
dynamic registry in the Plan 9 spirit:

* **clock** — `/srv/clock` (ticks, readme) fed by the never-yielding
  spinner; every few ticks it *writes a line to the terminal by VFS
  path*: `Write "/dev/term" "clock: tick N"`.
* **greet** — `/srv/greet`; `write /srv/greet ada` is ACKed immediately
  by the front actor, which delegates to a worker that later greets you
  through `/dev/term`. Write-to-a-path *is* message-to-an-actor.

The vfs never blocks: requests that belong to a mount are forwarded
with the *original* reply-to, so the mounted program answers the client
directly. No relay state, no deadlock cycles by construction —
`receiveRes` on the client side replaces v1's stash-and-replay.

### post-mortem: the frame that was 24 bytes short

The best bug of the round. `buildTree` (a deeply nested constructor
literal — the whole VFS tree in one expression) intermittently produced
a corrupted tree: probes walked it fine, then `graftSrv` saw garbage.
Not fuel (reproduced with fuel off), not the mailboxes (minimal repro
passed), not ARC.

Cause: frame sizing used `countLets body + 8` — a flat headroom for
call-argument staging. But staging *compounds*: arg *i* of a known call
is staged in slot `nxt+i` while its own evaluation runs above at
`nxt+i+1`, so nested constructor calls escalate the high-water mark
multiplicatively with depth. `buildTree` needed slots 24 bytes past its
frame; its own interior calls (`fpr_alloc`, constructor wrappers) then
landed frames exactly on the live below-sp temporaries. The tree was
born corrupted — in whichever fields happened to be staged deepest.

Fix: `slotsNeeded` computes the exact high-water mark by mirroring the
code generator's slot discipline (`CLet`: `max a (1+b)`; known call:
`max_i (i+1+slots(arg_i))`; everything else evaluates subterms at the
same level via the machine stack). An assembly-level audit now confirms
no function's deepest slot exceeds its frame. The estimate was
convention; the recursion is structure. Structure won, as usual.

## round 3: stui — a diffed cell-buffer TUI with stax embedded as its REPL

`programs/stui.fpr` composes three earlier pieces into one program: the
TuiPoc cell-buffer/widget/diff architecture (ported from the Haskell
original), the stax stack language (parser combinators → compiler → VM,
itself written in FPRISC), and the actor runtime (reader + ticker actors
feeding a terminal actor over per-sender mailboxes). Run it with

    make image.elf PROG=programs/stui.fpr
    python3 tools/tuidrive.py "1 2 + 3 4 + * ."          # typed, char by char
    python3 tools/tuidrive.py --paste "1 5 begin swap over * swap 1 - dup 0 = until drop ."

The screen is 80x24: title bar, a bordered REPL pane, a bordered sidebar
showing MVU state, last-frame wire stats, and *live runtime counters*
(heapUsed / fuelPreempts / arcLive — the program watches its own
allocator), and a status bar. stax commands typed at the prompt run in a
gas-bounded, total VM: division by zero, unknown ops, parse errors and
infinite loops (`1 begin 1 + dup 0 = until`) all come back as red log
lines instead of taking the machine down.

### The three layers, plus a fourth

- **Cells** are packed ints (`ch*256 + fg*16 + bg`), rows are lists,
  the frame is a list of rows. Blank rows are built once and shared —
  rows are immutable, so h identical rows are one row referenced h times.
- **Widgets** are `size -> rows` functions with an exact-size contract;
  `vbox`/`hbox` split via Fix/Flex (last flex soaks the remainder),
  borders and padding wrap. The layout is declared in one expression.
- **The diff renderer** compares old and new frames cell by cell, merges
  dirty runs closer than 4 cells, emits one cursor move per run and SGR
  only on color change. After the boot paint a command repaints ~25 of
  1920 cells (~100 bytes on the wire; the sidebar shows "saved 99%").
- **Dyn patches** (the FPRLive static/dyn split, buffer-shaped): a
  keystroke dirties exactly the input row and a tick exactly the sidebar,
  so those frames splice a freshly rendered region into the cached
  composed buffer and share every untouched row, instead of rebuilding
  the widget tree. Measured on target: a full view build is ~370 KB of
  allocation; a keystroke frame is ~16 KB; a tick frame ~180 KB.

### What the numbers mean (and the two bugs they found)

The bump allocator never frees, so the sidebar's heap gauge is a live
plot of exactly the garbage the real pipeline's Perceus-style RC pass
exists to erase. Two hot-path lessons, both measured before/after:

- A `case (o, n) of` **tuple scrutinee allocates the pair per call**. The
  diff walk did this per cell, so diffing two *identical* frames cost
  102 KB. Nested single-list cases made the same walk cost zero per
  unchanged cell (6.7 KB per no-op frame, all of it run bookkeeping).
- Threading SGR state as a 4-tuple rebuilt per cell was the same disease;
  packing it into one int (`fg*16+bg`) and threading plain args made the
  unchanged-color emit path allocation-free except the known `write` PAP.

There was also one honest-to-goodness logic bug the first frame caught:
`hcat`'s emptiness test conflated "no more buffers to check" with "a
buffer is exhausted", so every hbox rendered as zero rows and the status
bar arrived at row 2. All children have equal height by the size
contract, so the fix is to test only the first buffer — push the
invariant into structure and the fold disappears.

### Input batching

The reader actor blocks for one byte, then drains everything already in
flight (with a short yield-grace) into a single `Keys` batch — TuiPoc's
`drainInput`, actor-shaped. A pasted command is one message and one
frame; the terminal folds the whole batch through the editor, running
commands at each CR, before rendering once.

### Honest PoC simplifications

- ASCII borders (`+-|`), no Unicode box drawing over the 8-bit UART path.
- Arrow keys and other ESC sequences aren't parsed; printable + CR +
  backspace only. Stray ESC bytes are filtered, not decoded.
- Every emitted byte still costs one `write` PAP and every `charAt` one
  PAP (the known 2-ary fpr_g_ leak), so a session is heap-bounded: with
  the 96 MB PoC heap that's thousands of keystrokes, ~250 executed
  commands, or ~40 idle minutes of tick refreshes — all visible on the
  gauge as it happens.
- The Dyn-patch geometry (input row 21 cols 1..48, sidebar rows 3..20
  cols 52..77) is derived from the fixed 80x24 layout by hand rather
  than by the layout engine; FPRLive's gen_view is where that
  derivation is supposed to live.

## round 4: a network HAL module and a REST API in FPRISC

`runtime/net.c` adds the third device to the HAL: a virtio-net driver
(both legacy v1 and modern v2 MMIO register layouts, probed across the
virt machine's eight slots), polled like everything else — no interrupts.
On top of the frame layer it implements a deliberately minimal transport:
an ARP responder, IPv4 without fragmentation, and a one-connection TCP
with no retransmit and fire-and-forget sends. That is sound here and
only here: the link is QEMU slirp, local and lossless. The honest
framing is a hardware TCP-offload engine the HAL happens to implement
in C; a FPRISC TCP is future work and net.c is the contract it replaces.
The FPRISC surface is four functions in the established fpr_g_ style:

    netPoll d    -> Int      pump the NIC; 0 none / 1 open / 2 open+data
    netRead d    -> String   drain up to 1 KiB of buffered payload
    netWrite d s -> Int      send, segmented at 1200 bytes
    netClose d   -> Int      FIN and free the slot

`programs/httpd.fpr` puts the stax VM behind a JSON REST API. Everything
above the byte stream is FPRISC: request accumulation (headers, then
Content-Length worth of body), HTTP parsing, routing, JSON escaping and
a small JSON string-field extractor. Run and poke it:

    make image.elf PROG=programs/httpd.fpr && make run-net
    curl localhost:8000/status
    curl localhost:8000/run -d '{"prog":"1 5 begin swap over * swap 1 - dup 0 = until drop ."}'
    # -> {"ok":true,"lines":["output: 120","stack: []"]}

Validated end to end: GET / and /status, POST /run (arith, factorial),
errors as data (`1 0 /` and gas exhaustion come back as stax log lines;
missing JSON field is a 400; unknown route a 404), a 1.6 KB request body
spanning several TCP segments, a multi-KB response spanning several TX
segments, and four parallel curls (the single-connection stack ignores
SYNs while busy; slirp retries them, so clients serialize and all
complete). ~65 KB of heap per simple request — thousands of requests per
boot on the PoC heap, with `/status` reporting the gauge live.

MEMORY MODEL (the slab refactor): buddy over the heap region is the
ONE lower allocator.  Every actor owns a chain of slabs (bump-within,
per-actor recycle buckets with CAS push); stacks and acbs are buddy
blocks.  Actor DEATH reclaims: stack always, slabs unless they hold
promoted objects -- those are ORPHANED and return to buddy when their
last ARC ref drops (the escape count lives in the slab header, under
the ARC lock, so cross-actor references can never dangle).  Spawn pins
the entry closure; reap unpins it.  Sender-channel slots are reclaimed
too: keys are acb pointers, and a DEAD sender's drained slot is
CAS-stolen by the next new sender (previously 8 short-lived senders
exhausted MAXSND forever).  Process exit frees its growth grants; the
process slot is the fixed linked region, not an allocation.
tests/slab.fpr churns ~390 MiB of actors through the 64 MiB heap and
requires arcLive to settle to 0.  The v2 caveats "stacks leak on
death" and "growth blocks leak on process exit" are gone as
categories.  heapUsed now answers "bytes THIS actor has bumped".

Honest simplifications, all in one place (net.c header): static IP
10.0.2.15 (slirp's default, no DHCP), guest port 80 only, one connection
at a time, no retransmit/no congestion control/no TIME_WAIT, checksums
computed on TX and trusted on RX.

Two FPRISC-authoring notes this round surfaced: string literals have no
`\r` escape (CRLF is `strcat (chr 13) (chr 10)`), and `{` inside a
string literal always opens interpolation — JSON written in FPRISC escapes
every brace (`\{`, `\}`).

## Disk: an append-only page log under /srv/disk

`runtime/blk.c` + `programs/diskfs.fpr`
(`make disk.img && make run-disk PROG=programs/diskfs.fpr`).

**The HAL is pages, full stop.** blk.c is a polled virtio-blk driver
(legacy v1 and modern v2, same probe shape as net.c, DeviceID 2 so net and
blk coexist across the 8 virt slots) whose entire FPRISC surface is:

```
blkPages d       -> Int      capacity in 4 KiB pages
blkRead d p      -> String   the 4096 bytes of page p
blkWrite d p s   -> Int      write s (<= 4096, zero-padded) to page p
```

Any page can be read or overwritten directly — that the layer above only
ever appends is policy, and the policy is FPRISC. Two runtime enablers:
`substr` (1-indexed byte slice — chunking payloads via chr+strcat would be
an allocation per byte moved) and free-list size classes extended to 8 KiB
so the streaming pattern (read page → inspect → drop) recycles page
Strings instead of leaking one per step.

**The log.** Page 0 is the superblock `QLOG <head>`. A record is a header
page — `QREC <npages> <paylen> <url>` or a `QDEL` tombstone — followed by
whole payload pages, so records and payloads are PAGE-ALIGNED and a reader
that knows where a record starts does arithmetic, not byte offsets.
Recency is position: the latest record for a url wins; `rm` appends a
tombstone; nothing is ever rewritten except the superblock head. The
format is textual on purpose — a raw dump of disk.img reads like a session
transcript, and the on-disk parser is `takeWord`.

**FSApp** (mounted at /srv/disk) owns the META side: the in-memory index,
rebuilt by one boot-time scan over header pages; `ls`/dir-`stat`; page
ALLOCATION (`FAlloc` bumps head in memory, `FCommit` publishes index +
superblock — the single-writer discipline that keeps append-only sound);
and DISCOVERY: the first data request on /srv/disk/name lazily spawns the
URActor for that url and forwards with the ORIGINAL replyTo — the vfs
non-blocking-relay discipline, one level down.

**URActors** own one url each and move the actual bytes. A "file" is a
logical thing reconstructed from pages through the HAL, and both read
strategies from the design are live and visible from the shell:

- `cat` is the INDEXED read: `FLookup` to FSApp, then read exactly the
  payload pages of the latest record.
- `stat` deliberately ignores the index and STREAMS: read a page, parse
  the header, keep it if the url matches, drop it and leap `npages` if
  not — the answer says so
  (`file 25 bytes record @ page 3 (2 pages) [found by streaming log scan]`).

Writes append directly: FAlloc the range, blkWrite header + payload
chunks, FCommit. Crash before commit leaves the OLD head on disk and the
orphan pages get overwritten by the next writer (with multiple writers in
flight, commits must land in alloc order — the multi-writer fix is a WAL
sequence number in the header, one more takeWord).

**/srv/boots is persistent MVU in miniature**: Model = boot count, init =
replay (cat its own url through the namespace: vfs → FSApp → lazily
spawned URActor → indexed page read), update = write-through append.
Reboot on the same disk.img and the count climbs. The stax web-app VM's
persistence story is exactly this shape: Model out through a URActor on
update, Model back by replay at boot.

Validated end to end (three boots on one image, legacy AND modern
virtio): format-on-first-boot, replay, shadowing, tombstone + ls hiding
+ resurrection, a 6000-byte 3-page record byte-exact across reboot, and
the boot counter climbing 1 → 4.

---

## New in this drop: rv32, use-modules, and the SoA VList

### 1. Dual-target codegen: `--target=rv32|rv64`

Everything word-sized in both the compiler and the runtime funnels
through one parameterization (`Target` in Codegen.hs; `uw`/`REG_S`/`WSZ`
in fpr.h/asm.h).  The value representation is identical modulo W:
header `u32 tid | u32 var` at 0/4, fields at `8 + W*i`, tagged ints
`(n<<1)|1`.  Virtio descriptors keep their hardware-mandated `uint64_t`
fields on both targets.

    make TARGET=rv32 run          # qemu-system-riscv32 -machine virt
    make TARGET=rv64 run

ESP32-class parts: rv32 output uses only I, M and Zicsr instructions
(no A-extension in emitted code), so retargeting an rv32imc part is a
`-march` change on the C side plus a HAL port; `li`/`la` are pseudo and
assemble fine on imc.

### 2. Content-addressed file modules: `use` — now SEPARATELY COMPILED

(Updated: as of the module-system rework, `use` is a separate-compilation
boundary. The prelude, every used module, and the root program each
compile to their OWN .s unit, cached in build/units/ under the module's
content hash — the hash IS the build cache key, so an unchanged module
is never recompiled. Cross-unit references stay KNOWN — direct calls,
0-ary `call`, fpr_obj_ value refs — because the importer parsed the dep
for hashing anyway and therefore knows every export's arity. Typeids
and record-shape ids are CONTENT-ADDRESSED (fnv32 of unit-hash + type
name / of the sorted field set), so separately compiled units agree on
them with no shared counter; fprc aborts loudly on the astronomically
unlikely collision. fprc writes `<out>.s.units`, the list of unit
objects the link needs; a plain `use "localmod.fpr"` — unpinned,
relative, extension optional — just works, Sol-style.)

    MyMod = use "mods/mymod".                 # unpinned: compiler prints the hash
    MyMod = use "mods/mymod#ddbe5fa48f1a5018" # pinned: identity frozen

    x   = MyMod.x.               # values through the alias
    r   = MyMod.f "hi".          # functions
    T   = MyMod.T.               # types/constructors alias across the boundary
    h   = "{MyMod}".             # the alias ITSELF evaluates to the hash string

The hash is FNV-1a-64 over the module's AST with its own `use` specs
normalized to their resolved dep hashes -- a Merkle root over the
dependency tree, insensitive to comments/whitespace, sensitive to any
semantic edit anywhere below.  Pinning a stale hash is a compile error
that prints both hashes.  Two versions of "the same" module coexist in
one image (top-level names are qualified `name@hash16` internally), which
is the append-only/immutable versioning story: an upgrade ADDS a module,
it never mutates one.

Every module export lands in a zero-terminated `(hash, name, PAP)`
rodata table, and the runtime exposes

    d = Mod.fn MyMod "double";   # dispatch by (module hash, function name)
    Mod.has MyMod                # is that hash linked into this image?

which is the local half of FPRLive remote calling: a remote peer asks
for `hash#fn`, never for a link-order index.

The resolver contract grew a data-shaped variant and a URL front:

    Mod.resolve hash name    ->  (1, fn) | (0, 0)     # a MISS IS DATA

and in System.qa, `/services/modules` is a capability-gated service
whose URLs are `<hash>/<fn>` — `svcModFn caps "<hash>/pad2"` — so an
app carries only the (hash, name) identity, the FPRLive wire shape, and
System.qa resolves it. Today's backend is the link-time module table;
a disk `.qa` module store or a remote FPRLive peer slots in behind the
same URL by changing svcModFn only. TUIClock demonstrates the whole
flow: its manifest requests `/services/modules` as OPTIONAL, the
granted path formats the clock with a pad2 resolved at runtime from
`mods/timefmt`'s hash, and denial (or a miss) adapts to the builtin
formatter — resolution failure is a mode, not a fault.
`tests/modurl.fpr` pins the split + hit/miss contract.

### 3. The LINEAR SoA VList vector, three tiers deep

`Vector` is declared linear in the prelude; single ownership licenses
in-place mutation everywhere below.  Layout is fixed by the first push
(the Sol PoC rule): Int -> one unboxed raw-word column; (Int, Int[, Int])
tuples -> one unboxed column per field (SoA); anything else -> boxed.
Columns are VLists: directories of geometrically growing blocks
(16, 32, 64, ... words), so push is O(1) with no realloc-and-copy and
blocks up to the allocator's 8 KiB freelist ceiling recycle exactly.

API (vector always LAST, for pipelines): `Vec.new push len get set map
filter fold fromList toList free`.

Tiers, per call site, decided at compile time + a runtime layout guard:

* **generic** (vec.c): always correct, `fpr_apply` per element; rows are
  reconstructed on demand.  Every guard failure tail-jumps here.
* **specialized** (`Vec.map f v` etc. where `f` is a statically known
  top-level function whose closed call graph is arithmetic-only --
  ints, arith/cmp prims, if/case-on-Bool, let, recursion allowed):
  an unboxed clone `fpr_ufn_f` (raw ints in registers, native add/mul/
  slt) driven by a block-striding column loop.  map and filter run IN
  PLACE.  `Vec.fold` over an SoA vector additionally DUALIZES `f`:
  field projections of the tuple parameter become per-column cursor
  loads and the tuple is never materialized; the guard checks the
  vector's eltid/elvar/columns match what `f`'s pattern demanded.
  Measured on QEMU (20k elements): ~7.6x over generic.
* **RVV** (`--rvv` / `make RVV=1`): straight-line +,-,* map bodies
  strip-mine through `vsetvli`/`vle`/`vadd.vv`/`vmul.vx`/`vse`, and
  `Vec.fold (\a b -> a + b)` accumulates with tail-undisturbed adds and
  one `vredsum`.  The emitted .s carries `.option arch, +v`; the image
  enables mstatus.VS via a weak `fpr_rvv_enable` hook only when built
  with --rvv, so non-RVV images run on V-less cores untouched.
  HONESTY NOTE: under QEMU TCG the vector loop is SLOWER than the
  scalar specialized loop (lane-per-helper-call emulation); the tier
  exists for real V silicon, not for the emulator.

Fuel: specialized loops decrement once per BLOCK; the unboxed clones
keep the per-entry check, so the safepoint contract survives even
collatz-style recursion inside a map.

Caveat carried over from the Sol JIT: a comparison-returning function
mapped over an Int vector stores raw 0/1.

---

## New in this drop: multi-hart SMP

`make HARTS=2 run` (the default; also `-DFPR_NHARTS` + `-smp` if driving
gcc/QEMU by hand).  `make HARTS=4` works the same way.  Harts beyond
HARTS park in wfi at boot; `spawnOn h` with `h >= HARTS` panics.

### The shape of it

Actor runtime v3 keeps v2's promise: because every mailbox was already
a per-sender SPSC channel, going multi-hart was fence insertion plus a
scheduler restructure -- no multi-writer anything was ever added.
Every ring in the system has exactly one writer and one reader:

* **message channels** (unchanged storage): writer = the sending actor
  (an actor runs on one hart at a time and never migrates), reader =
  the owning actor.  Producer publishes the slot then release-stores
  `rt`; consumer acquire-loads `rt`, takes with owner-only shifts,
  release-stores `rh` (which is the producer's full-check).
* **wake/spawn shipping**: an NHARTS x NHARTS matrix of SPSC rings of
  acb pointers, writer = source hart, reader = owner hart.  There is no
  shared run queue; each hart drains its column into a private FIFO.

The only shared-mutable non-rings are the actor STATUS word (a 3-state
CAS) and the ARC table (one spinlock in runtime.c; promotion happens on
send, which is rare next to compute).

### Scheduling, fuel, memory

Each hart runs a hart loop on its boot stack; actors are pinned where
`spawnOn` put them (`spawn` = current hart), and `main` is actor 0 on
hart 0, spawned like everyone else.  Fuel became per-hart by making the
generated code decrement `0(tp)` -- tp points at the hart's control
block forever, ctx-switched verbatim (fpr.h has the essay).  The heap
splits into per-hart arenas at boot: alloc/free are hart-local and
LOCK-FREE; a block freed on a foreign hart just migrates to that hart's
free list (bump pointers never revisit carved space, so migration
cannot double-allocate).

### The block/wake protocol (the one lost-wakeup trap)

    sender:   publish message (release rt); FENCE seq_cst;
              CAS(status BLOCKED->READY) -- the winner ships the acb
    receiver: CAS(status READY->BLOCKED); FENCE seq_cst;
              RE-CHECK the receive predicate (any / from-sender / Result);
              satisfied -> CAS back and continue, else switch away

Both sides put a seq_cst fence between *my write* and *their flag* --
the Dekker pairing -- so a message published while blocking is either
re-seen by the receiver or CAS-woken by the sender.  Duplicate run-queue
entries are possible and harmless: all entries for an actor land on its
one owner hart (execution is always sequential) and deq skips non-READY
entries.  `smpstress.fpr` = 20,000 cross-hart BLOCKING round trips, one
full block/wake on each side per trip, both targets.

### Sleeping instead of spinning: wfi + CLINT IPIs

Idle harts sleep in `wfi` with `mie.MSIE|MTIE` set and `mstatus.MIE`
CLEAR -- pending+enabled wakes the wfi but is never taken, so the whole
system still has no trap vector.  `ship()` to a remote hart raises that
hart's msip AFTER pushing the work; the sleeper clears its msip BEFORE
its final queue check (Dekker again, with msip as the flag), so a post
after the clear leaves the doorbell pending and the wfi falls through.
mtimecmp RESETS TO 0 in QEMU (= permanently pending): every hart's
compare is parked at ~0 during init or nothing would ever sleep.

CLINT MMIO stays off the hot path: fuel preempts bounce through the
hart loop without touching the doorbell; only the about-to-sleep path
pays for it (this halved sequential psort time under QEMU).

Deadlock detection went global and timer-paced: hart 0 wakes every
30 ms even without a doorbell and declares deadlock only when (all
harts idle) && (someone blocked) && (the activity counter frozen) held
across 8 straight samples -- an in-flight send keeps its hart non-idle
or bumps the counter.  `smpdead.fpr` proves it panics loudly.

### Synchronous actor block groups

The prelude grew fork/join sugar over plain actors:

    (fa, gb) = par2 h f a g b     # f a on hart h, g b HERE, join both

`parWorker` is one round of receive (parent, f, a) -> reply Ok (f a);
`receiveRes` is the join (it steps over unrelated traffic).
`psort.fpr` sorts the two halves of a 6000-element Vector in parallel:
`Vec.split` (new: consumes the linear vector, returns two fresh halves
-- shared block chains would put two writers on one ring, which this
design never allows), `par2 1 sortVec lo sortVec hi`, merge, verify:
identical checksums sequential vs parallel on rv64 and rv32.

HONESTY NOTE, measurement: this container gives QEMU ONE host core, so
wall-clock "speedup" is meaningless here -- psort reports ~1.0x with
the wfi runtime (and the 1.75x the earlier spin-idle runtime showed was
an artifact of the idle spin taxing the sequential leg).  What the
suite DOES establish under MTTCG's fine-grained interleaving is the
memory-model story: fences, CAS protocol, IPI ordering, ARC under
contention.  On a multi-core host or real silicon the same binary gets
real overlap.  Always pass `-accel tcg,thread=multi` (the Makefile
does): without it QEMU may fall back to one thread and cross-hart
latency becomes host-timeslice-bound.

Caveats, stated plainly: `kill` of an actor RUNNING on another hart is
advisory (lands at its next safepoint); per-sender channel slots are
MAXSND=8 per actor; virtio net/blk polling is still hart-0-only; actor
stacks still leak on death.  On ESP32-class dual-core parts the same
design maps to the per-core software-interrupt registers instead of
CLINT msip.

---

## New in this drop: the algebraic HAL, in Rust

`rust/` is a cargo workspace that puts a Rust HAL behind the exact same
`fpr_g_*` discoverable-symbol contract hal.c uses -- the C runtime and
the generated code cannot tell the difference.  Three crates:

* **fpr-abi** -- fpr.h transliterated: `V`, tagged ints, `#[repr(C)]`
  mirrors of the object headers, `want_int`/`want_str`/`want_handle`
  argument decoders, `mk_str`/`mk_tup2`/`mk_handle` builders (they call
  the C `fpr_alloc`, so allocation stays per-hart and SMP-aware), and a
  `fpr_fn!` macro that lays down static PAP objects byte-identical to
  C's `FPR_FN`.  Rust panics route into `fpr_cpanic`: one panic story.

* **fpr-hal** -- the algebraic surface, prelude-declared LINEAR:

      Uart 1 = Type Int.                     Spi 1 = Type Int.
      Uart.open  : Int -> Uart.              Spi.open  : Int -> Spi.
      Uart.write : String -> Uart -> Uart.   Spi.xfer  : String -> Spi -> (String, Spi).
      Uart.avail : Uart -> (Int, Uart).      Spi.close : Spi -> Unit.
      Uart.readN : Int -> Uart -> (String, Uart).
      Uart.close : Uart -> Unit.

  Every operation consumes the handle and returns it; `close` consumes
  it for good.  A use-after-close or a leaked port is a COMPILE error
  (uncomment the marked line in tests/uartspi.fpr to see the checker
  reject it), which is why the Rust side needs no mutex and no
  critical-section machinery: the type system is the lock.  Two
  backends behind mutually exclusive features:
    - `qemu-virt`: ns16550 UART; SPI is a documented loopback (the virt
      board has no SPI controller).  RUN AND VERIFIED here, rv32 and
      rv64: FPRISC writes the wire, reads piped bytes back, and the
      full-duplex xfer round-trips `\x01\x02\x03` payloads (the string
      lexer grew `\r`, `\0` and `\xHH` escapes for exactly this).
    - `esp32p4`: register-level drivers over the `esp32p4` PAC
      (svd2rust from Espressif's SVD), compiled for
      riscv32imafc-unknown-none-elf -- the P4's actual triple.
      COMPILE-VERIFIED, NOT YET RUN ON SILICON.  UART rides the
      ROM-configured console FIFOs (no clock/pin init needed for the
      boot UART); SPI2 follows the TRM GP-SPI sequence (doutdin
      full-duplex, W0.. staging, ms_dlen, update/usr) and expects bus
      clocking/muxing from the boot stage.

* **fpr-hal-esphal** -- the answer to "can we use esp-hal": the same
  eight exports implemented over esp-hal 1.1.1's OWN drivers
  (`Uart::new` + `write`/`read`/`read_ready`, `Spi::transfer`), built
  against ESP32-C6.  Released esp-hal (1.1.1, May 2026) does NOT ship
  ESP32-P4 support -- it is in progress on git main -- so this crate is
  the adapter that becomes the P4 backend by flipping one chip feature
  when upstream lands.  The embedding inverts on real boards: Rust owns
  reset, `esp_hal::init()` brings up clocks, `fpr_esphal_init()`
  stashes the drivers, then Rust calls `fpr_rt_init` / `fpr_hart_main`
  and FPRISC takes over.

Build/link (QEMU): `make RUSTHAL=1 PROG=tests/uartspi.fpr run` --
cargo builds core itself for the bare-metal triple (build-std via
RUSTC_BOOTSTRAP on stable >= 1.88) and the .a joins the normal gcc
link line.  ABI notes: riscv32imac-unknown-none-elf is ilp32, matching
the C side exactly; the P4 triple defaults to ilp32f, so a real P4 link
builds the C/generated side with `-march=rv32imafc -mabi=ilp32f`.
FPRISC's rv32 output is I/M/Zicsr-only and does not care.

What is honestly missing for first boot on a P4-NANO: a P4 linker
script + image packaging (espflash / ESP-IDF 2nd-stage expectations),
per-core software interrupts in place of CLINT msip for the SMP wake
path, and silicon time for the SPI2 driver.  The ABI, the drivers, and
the linearity story are done and demonstrated.

---

## New in this drop: WiFi, BLE keyboard, the speaker question, and TARGET=c3

The algebraic surface grew four linear types (prelude, `rust/fpr-hal`):

    Wifi.up scan connect ip down          Ble.up scan kbOpen down
    Kb.read close                         Spk.open play stats close

Scan results are Strings (tab/newline joined): FPRISC list constructors
get per-program typeids, so String is the stable ABI.  `Ble.kbOpen`
goes THROUGH the Ble handle -- radio-before-keyboard is a type fact.

### Tested in QEMU (rv32 + rv64 + the c3 configuration)

`tests/btwifi.fpr`: WiFi state machine (wrong password rejected,
right one yields an IP), BLE scan, then the keyboard -- piped stdin is
ENCODED into real 8-byte HID boot reports and pushed through
`fpr-hid`'s decoder, the SAME crate the ESP32 backend feeds with ATT
notifications.  "Hi, FPR!" round-trips shift modifiers and all: the
decoder that ships is the decoder the suite runs.  The sim "speaker"
accounts every PCM sample; a square wave generated in FPRISC (the new
`\xHH` escapes) reports exactly samples=512 rms=80 ms=64.

### The real radio: rust-radio/fpr-hal-radio (ESP32-C3)

A separate, version-pinned workspace (esp-wifi 0.15.1 was released
against esp-hal 1.0.0-rc.0; its unstable-feature coupling should not
drag the main workspace off 1.1.1).  COMPILE-VERIFIED for
riscv32imc-unknown-none-elf, all fifteen fpr_g_ exports present; not
yet run on a board.  Inside:

* WiFi: esp-wifi's blocking controller -- start / scan_n / connect /
  is_connected over Espressif's blob.  `Wifi.ip` reports MAC + link
  state, not an address, BY DESIGN: FPRISC has its own net layer, and
  the C3 story is feeding it esp-wifi's netdev the way virtio-net
  feeds it on QEMU -- that marriage is future work, stated as such.
* BLE keyboard: RAW HCI over esp-wifi's BleConnector plus a ~300-line
  ATT client (hci.rs) -- scan with name parsing, LE Create Connection,
  service/characteristic discovery, boot-protocol select, CCCD
  subscribe, notification loop into fpr-hid.  Why not an async host
  stack: the HAL is blocking, trouble-host wants a newer bt-hci than
  esp-wifi 0.15 exports, and 300 auditable lines beat an executor.
  Two flagged silicon risks: pairing (keyboards demand encryption
  before notifying; SMP Just-Works is ~80 lines, deferred) and the
  CCCD-is-value-handle-plus-one shortcut.
* The speaker, answered honestly: the C3 is BLE 5.0 only.  No BR/EDR
  means NO A2DP; no LE ISO means NO LE Audio.  A BT speaker cannot be
  driven from a C3 with standard profiles -- hardware fact, and
  Spk.open on this backend says exactly that.  Real paths: original
  ESP32 + ESP-IDF A2DP source, a custom GATT stream between two chips
  you both program, or wired I2S from the C3.  The algebra above is
  identical for all three; only the backend changes.

### TARGET=c3

`make TARGET=c3 run` builds the WHOLE stack for the C3's actual ISA --
RV32IMC, no A extension.  runtime/atomic_shim.c supplies libatomic
(single-core, IRQ-off RMW; it #errors if FPR_NHARTS != 1 rather than
be subtly wrong about SMP), HARTS is forced to 1, and QEMU runs the
exact configuration with `-cpu rv32,a=false,zawrs=false`.  Verified:
demo, actors, vecbench, uartspi, btwifi all pass with ZERO amo/lr/sc
instructions in the final image (objdump-checked), Rust included
(riscv32imc build of fpr-hal).  What TARGET=c3 is NOT yet: a flashable
C3 firmware -- that needs the C3 linker script/ROM layout and espflash
packaging, same short list as the P4.

---

## New in this drop: `.qa` app archives, static permissions, System.qa

A userspace-architecture layer on top of the existing VFS-actors +
disk-log + TUI: QOS app archives (`.qa`), a compulsory static
permission flow, and `System.qa` as the launcher/FSProcess.

    make run-system                 # rv64
    make run-system TARGET=rv32
    make run-system TARGET=c3       # ESP32-C3 ISA (RV32IMC, 1 hart, no A)

Full detail in `docs/QA-FORMAT.md` (the archive byte layout) and
`docs/SYSTEM-QA.md` (the bootstrap + permission model). In short:

* A `.qa` (`QAR1` magic + section table + payloads) bundles a MANIFEST
  (mini-TOML: id, entry symbol, and the permission set) with the app's
  ELF. The permissions travel WITH the code and cannot be separated.
* `System.qa` is `main` (actor 0): it brings up the algebraic HAL,
  reads `startup = "TUIAppLauncher"` from its config, and launches that
  app through the SAME permission gate every app uses.
* The gate parses the manifest, asks the user to grant each required +
  optional permission, then: all required granted -> the app runs with
  ONLY the granted capabilities (URL-addressed services, checked at
  each call); any required denied -> `Cannot Run Application without
  all required compulsory Permissions` and no launch; optional denied
  -> launch proceeds and the app adapts.
* `TUIAppLauncher` is "just an app": a paginated grid of app icons with
  a clock/count/page header, built only on `/services/{apps,display,
  keyboard,clock}`. Picking an app re-enters the launcher's `launch`
  service -- an app that launches apps. Shipped demo apps: TUINotes (a
  line editor with an optional `/services/net` capability) and TUIClock.
* Apps live as rodata (`runtime/apps.c` + generated `apps_data.c`);
  a disk-backed `/apps` overrides by id. Tools: `tools/mkqa.py` builds
  archives, `tools/genapps.py` bakes the rodata registry.

The ELF-in-ELF loader is the one deferred piece: today `launch`
resolves the manifest `entry` against co-compiled apps by name
(`Apps.entry`/`Apps.run`, the existing module-dispatch path). The `.qa`
ELF section is bundled and hashed but not yet mapped; when the loader
lands, only `runEntry` grows a `LaunchElf` branch -- no app, manifest,
or permission-flow change. Verified end to end (boot -> launcher gate
-> grid -> nested launch -> app -> return) on rv64, rv32, and c3, both
grant and deny paths, with zero atomic instructions in the c3 image.

---

## New in this drop: pin-explicit devices, and REAL dynamic ELF loading

Two pieces: the static pin primitive the HAL was missing, and the
ELF-in-ELF loader the `.qa` architecture was built around.

### 1. Devices on arbitrary pins (`docs/PINS.md`)

    Spi.openPins : Int -> Int -> Int -> Int -> Int -> Spi.   # port sck mosi miso cs
    Kpd.openPins : Int -> ... -> Kpd.                        # 4 rows + 4 cols
    Kpd.read     : Kpd -> (Int, Kpd).

An ESP32 has no discovery for a soldered-on display or keypad, so the
pins must be named. `backend_p4_pins.rs` does the real work: IO MUX to
hand a pad to the GPIO matrix, then `func_out_sel_cfg(pin)` /
`func_in_sel_cfg(signal)` to route GP-SPI2's four signals (note the
asymmetry: output indexed by pin, input by signal). The 4x4 keypad
deliberately uses PLAIN GPIO -- a matrix scan drives and reads pins
directly and gains nothing from signal routing. Handles stay linear, so
`Spi.close` genuinely unroutes the pads it claimed (pin numbers ride in
the handle's cookie).

Fixed the P4 backend's real gap along the way: its SPI2 ran the full TRM
register sequence but never touched IOMUX, so it could not reach a
physical pin at all. VERIFIED in the QEMU sim on rv32 + rv64
(`tests/pindevice.fpr`: SPI loopback round-trips `\xAA\x55init`, the
keypad decodes keystrokes through the same `fpr-hid` decoder the BLE
keyboard uses). The P4 register path is compile-verified only.

### 2. Dynamic ELF process loading (`docs/PROCESS-LOADING.md`)

`runEntry`'s `LaunchElf` seam is now real. An app with
`loadMode = "process"` in its manifest is loaded from its `.qa`'s ELF
section into a buddy-allocated slot and run as a genuinely separate
process -- its own actor system, its own heap.

    System.qa  --buddy_alloc--> slot --elfload--> fpr_process_entry
         ^                                              |
         |          fpr_grow_memory (heap exhausted)    |
         +----------------------------------------------+

- `runtime/buddy.c`: power-of-two allocator over a reserved 32 MiB
  arena, unit-tested standalone (exhaustion, scrambled-order coalescing,
  mixed sizes, payload integrity).
- `runtime/elfload.c`: PT_LOAD segment loader, ELF32/ELF64.
- `runtime/proc_entry.c` + `link-app.ld`: apps link at a fixed slot
  address and expose `fpr_process_entry` as a plain callable, not a
  reset vector -- no crt0, no machine bring-up, no stomping the running
  host.
- Growth: on bump exhaustion a process's `fpr_alloc` calls back into
  System.qa's buddy allocator and retries. The existing segregated
  free-lists (already a slab allocator in spirit) are untouched.

VERIFIED end to end on rv32 + rv64: boot -> permission gate -> launcher
grid -> HelloProc loads, builds a 100k-element list across **6 growth
round-trips**, exits cleanly -> grid redraws -> a *different* app
(TUIClock, name-dispatched) runs correctly afterward. Both loading paths
coexist; the full SMP suite (smp, smpdead, psort, actors, demo) still
passes on the shared `actors.c` changes.

**Scope, stated plainly**: this is FIXED-SLOT loading, not general
relocation. `-mcmodel=medany` makes an image internally position-
independent, but calls into the shared runtime have link-time
displacements, so apps are linked against a known slot address; "dynamic"
means which slot and when. True relocation is a compiler feature, not a
loader one. Also honest: no memory protection (no MMU/PMP), one
concurrent slot, growth blocks leak on exit (~3 MiB/run for HelloProc),
and **a process-loaded app receives no capability set** -- `Apps.run`
passes `caps`, `fpr_process_entry` does not, so the permission model
currently means nothing for process-loaded apps. That's the next piece
of work, and `docs/PROCESS-LOADING.md` says so.

Three bugs worth recording (all in the docs): `tp` is a physical
register and must be restored or the HOST's allocator silently breaks
later; same-named functions in two images are two different functions
(the result must be returned, not re-fetched); and FPRISC-level `substr`
is quadratic, so ELF payload bytes never round-trip through it
(`Sys.loadElfAt qa off len` reads in place).

## The idle-loop allocation storm (a slab-model dividend, the hard way)

Field report: an interactively idle launcher exhausted the whole heap
in ~2 seconds ("heap exhausted (buddy has no free block)") -- never
seen in CI because the piped test inputs always pressed keys and quit
before a single tick elapsed.  Two invisible allocation categories,
tolerated forever by the old never-free arenas, became fatal the
moment memory was real:

1. Curried extern application: `charAt s i` compiled to
   `fpr_apply(fpr_apply(fpr_g_charAt, s), i)` -- a 48-byte PAP per
   argument, sitting inside strEq inside hasCap inside svcPollKey.
   Fixed in codegen + runtime: application SPINES with unknown heads
   now emit ONE `fpr_applyN` call; saturating allocates nothing,
   under-saturation builds exactly one pap, over-saturation loops.
2. Nullary constructors: every produced True/False/Nil/Unit allocated
   a fresh 8-byte header.  veq compares structurally (tid+var), so
   nullary CMk now references an immortal per-unit static.

Also caught along the way: the build/units cache was keyed by SOURCE
hash only, so a codegen change silently served stale unit assembly --
unit filenames now carry a codegenRev tag.  After the fixes, a
20-second idle soak samples fewer than one allocation per 65536 --
the "idle polling claims NOTHING" property, now enforced by a memory
model that makes violating it fatal instead of invisible.

## The slot-clobber hunt (diagnosis half-done, honestly pinned)

The pins work surfaced a crash blamed on "negative arguments through
fpr_applyN".  The real mechanism, proven by substitution: ANY prim
binop as an extern argument in one specific frame shape spills its
operand temps into a slot still live for a later read -- (100 - 1)
fails exactly like (0 - 1), bare literals never do.  The corrupted
slot is later read as a list and the Nil/Cons case meets a small int:
the exact panic observed.  Root cause not yet landed (countLets' temp
bound vs the block allocator's reuse for repeated `_` binds are the
suspects); tests/slotclobber.fpr pins the failing shape as an
EXPECTED-PANIC row, so the suite flips loudly the day the allocator
is fixed.  A model bug report: the wrong first theory is preserved
because the substitution test that killed it is the useful part.

## The slot-clobber, closed

Root cause: `slotsNeeded`'s isKnown consulted prog and primArities but
NOT the cross-unit ext map introduced with separate compilation -- so
a 3-arg module call's argument spills went uncounted, the frame came
up short, one temp spilled below sp, and the timer trap (which uses
the stack below sp asynchronously) ate it whenever it fired inside
the store-to-load window.  One omitted lookup explained every
symptom at once: the timing dependence, the frame-shape dependence,
the rv32 immunity (4-byte slots kept the same count in-frame), and
why literals were safe while any prim expression crashed.  Latent
since the separate-compilation drop; caught by a keypad test; the
"+2 paranoia" bound had been absorbing it the whole time.

## Signals without silicon (and two compiler hardenings for free)

The pin sim gained a trace ring -- a logic analyzer -- and the proof
style changed with it: tests now DECODE THE WAVEFORM (mosi sampled at
sck rising edges, as a slave would) and require the reconstruction to
equal the bytes sent.  Bit-banged SPI mode 0 (mods/bbspi) and an
SSD1306-shaped OLED driver (mods/oled) ride the same pin-functions-
as-values pattern as the keypad.  Building them caught two compiler
defects: xfGo's 9 params tripped the 8-arg ABI, and the unit cache
SWALLOWED that error while serving the lazily-half-written EMPTY .s
as a valid cached unit -- the assembly is now forced before the cache
write, so unit-compile errors are loud and no partial file survives.
The C3 routing was verified by inspection: backend_p4_pins' matrix
logic is chip-independent; the port is a PAC swap plus signal
numbers, with the raw-tier register map recorded in PINS.md.

## Launcher polish + the notes editor returns (as a process)

The shell no longer lists itself; picks renumber over the three real
apps.  TUINotes got its full TUI editor back -- green border, live
header (session count + storage tag), scrolling list pane, inverse
input line -- now rendered by a LOADED PROCESS through mods/tui over
its own console, with every committed line persisted through the
syscall channel at the moment of commit.  A field crash of the clock
app traced to STALE-CODEGEN .qa's (built pre-slotfix, maximally
timing-exposed): fprc is now a dependency of the process-app rules,
so compiler changes rebuild the apps.  Also unearthed: the storage
test's input string had never matched a step-10 edit and was passing
by accident (a stray grant-y became a note character); the counts are
now exact.

## First-silicon kit: board file, TTP229 driver, flashable bench

The bench hardware turned out kinder than a matrix: the "16-key
Arduino pad" is a TTP229 (self-scanning, 2-wire serial), so
mods/ttp229.fpr is 16 clock pulses and a fold -- proven in sim by
Pin.feed, a pattern stimulus that answers the clocks the way the chip
would, both active levels swept.  boards/c3bench.fpr is the single
source of truth for the wiring; `make bench-c3` links the bench
program against hal_c3sil.c (real UART0 FIFO, real GPIO matrix +
IO MUX per the PINS.md appendix, rdcycle delays, honest sim stubs)
under the C3 memory map, sized to the 176 KiB DRAM (24K stacks, 16K
slabs, 4K buddy blocks, preemption off).  43 KiB of text, entry at
IRAM base.  The bench sequence is chosen so the first flash debugs
ADDRESSES, not protocol: all-pixels-on needs zero RAM writes, and a
touch toggles it while printing the key.  Compile-verified only;
FLASH-C3.md says so out loud.

## First flash, first lesson: dual-mapped SRAM

The bench image's maiden flash died in the ROM loader (ets_loader.c +
TG0WDT loop) after loading one segment.  The field log made the bug
legible from the armchair: C3 SRAM1 is one physical RAM dual-mapped
at IRAM 0x4038_0000 and DRAM 0x3FC8_0000, and the linker script had
placed text and data at the SAME physical offset through the two
views.  The corrected map splits the physical RAM by offset; the same
pass disarms the four ROM-armed watchdogs (RTC, SWD, TIMG0/1) at HAL
first-touch, since a directly-booted app inherits them live.  A
reset-loop serial log turned out to be a perfectly good debugger.

## The esp-hal pivot

Two field iterations of hand-rolled boot (dual-mapped SRAM overlap,
then ROM-loader window rules) bought the lesson: on this silicon, the
boot chain and register map are ecosystem problems with ecosystem
answers.  rust-c3bench/ hosts the unchanged FPRISC runtime inside
esp-rs: esp_hal::init owns clocks and watchdogs, linkall.x owns the
memory map, espflash owns the boot chain, and the SVD-generated PAC
owns every register -- the pin-routing Rust mirrors backend_p4_pins'
shape on the C3's own SVD, so nothing is hand-transcribed anymore.
The fpr_g_ contract crosses one C shim to four #[no_mangle] Rust
functions; the generated bench assembly assumes exactly that surface
and nothing else.  Compile-verified on the C side here; the Rust
build happens where the toolchain lives, one `cargo run --release`
from a flashing monitor.
