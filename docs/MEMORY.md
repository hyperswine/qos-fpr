# The memory model (v2)

No GC. Ever. Three regimes — **linear by default, Rc as the fallback,
ARC only by explicit promotion** — over ONE dumb allocator contract:
`alloc / realloc / dealloc`, nothing else. The allocators assume
nothing and discover nothing; every lifetime decision is made by the
program (compiler-inserted linear frees, Rc dec sites, drop laws), and
the allocator just executes it.

Sections marked **[pending]** are contract the code has not caught up
with yet; docs/MEMORY-V2-PLAN.md maps each one to the mechanisms it
replaces, file:line. Everything else is live.

## The regimes

1. **Linear — the default.** Bulk data (SoA Vectors, BStr-class
   buffers, frames, models, scenes) has exactly one owner, is mutated
   in place through the threaded handle, and is freed at its one
   consume point (`Vec.free`, scope exit, autodrop). Growth is
   realloc-by-doubling; release is all-at-once. Provably-scoped work
   uses arenas (bump, free wholesale). Linear data carries NO
   refcount of any kind — not Rc, not CoW rc (the vec CoW is gone;
   the specialized column loops are sound by construction, not by
   documented exception).

2. **Rc — the fallback, intra-actor only.** Tree/list data that
   genuinely needs sharing inside one actor is reference-counted at
   the existing safepoints. Rc never crosses an actor boundary;
   there is nothing concurrent about it — inc/dec are plain stores.
   Rc-zero calls `dealloc`; that is the whole protocol.

3. **ARC — cross-actor, by explicit promotion only.** Nothing is
   ever promoted implicitly. `sendArc` gives OWNERSHIP of the object
   to **ARC.qa**, which spawns a small manager actor for it; the
   refcount is structurally atomic because it only changes by
   INC/DEC messages drained through that manager's single mailbox —
   actor topology IS the serialization, no lock anywhere in the
   mechanism. A promoted object is frozen (immutable) at promotion,
   so holders read through the pointer directly while their count is
   live; DEC-to-zero has the manager dealloc and die.
   **[pending: today's mechanism is still the HAL's locked ARC
   table + escaped-slab counts]**

## Sending — three verbs, no hidden modes

* **`send` deep-copies. No exceptions.** One message = one ownerless
  slab, vectors included (header, cols, and column spans all land in
  it — vec_layout.h is the contract); nothing is shared, nothing can
  dangle, and drop-of-root frees all of it. LIVE.
* **`sendLinear` moves.** Ownership transfers to the receiver; the
  sender's binding is consumed by the linearity checker (reuse after
  a move is refused by name). A received message root transfers as
  the SAME pointer — no copy, no count change; the one standing ARC
  count changes hands — so a relay chain (the frames loop,
  tests/frames.fpr + tests/sendlin.fpr) is zero-copy end to end.
  Anything else deep-copies and releases what the sender owned. LIVE.
* **`sendArc` shares — the ONE promotion path.** The pointer crosses,
  the object is frozen by contract, and the count is the number of
  HOLDERS: the sender's standing share is created at first promotion,
  each send adds the receiver's, every holder releases with `drop`
  (tests/sendarc.fpr: one tuple, three holders, balanced). A Vector
  is refused — linear bulk moves or copies, never shares. LIVE on
  the v1 mechanism; **[pending: the mechanism underneath moves from
  the HAL's table+lock to the mailbox-serialized ARC.qa]**

## The allocator contract

* **Buddy (Memory.qa's mechanism).** One global power-of-two buddy
  hands out grants — process slots, growth, and the backing for the
  fixed-block needs (stacks, acbs, channel blocks). It implements all
  three ops: `buddy_alloc`, `buddy_realloc` (in place whenever the
  block is the low half and its buddy is free — the natural substrate
  for realloc-by-doubling), `buddy_free`.
* **The one freelist discipline.** Every recycled-block pool in the
  runtime is the same structure — `fpr_freelist_t`: a locked LIFO of
  free blocks, each node carrying its capacity, taken first-fit
  (fpr.h; stacks, bucket arrays, channel-block extras, and the
  variable-size grant pool are its four instances). What stays at a
  call site is POLICY: where a miss fills from, telemetry, and any
  deferred-reuse discipline layered on top (the chblk epoch limbo).
* **Per-actor pool.** An actor's grant becomes a bump slab chain plus
  two recycling tiers, both exact-fit: the size-class buckets below
  the 8 KiB ceiling and the bigfree LIFO above it. Death returns the
  chain wholesale — an actor's memory lifetime IS the actor's
  lifetime. Long-lived actors `Sys.poolReset` at loop boundaries.
  `fpr_realloc` is the pool's third op: copy-based, with the freed
  predecessor recycling exactly, so a doubling ladder reuses its own
  history. **[pending: in-place growth for bulk storage arrives when
  columns sit on Memory.qa's buddy, where buddy_realloc provides it]**
* Nothing else. A recycler that is not an `fpr_freelist_t` instance,
  a pool tier, or buddy itself is debt.

## Vectors: contiguous, branch-light

A Vector's column is ONE contiguous span (live — the VList block
chain is gone). Growth is `realloc`-by-doubling; `Vec.get`/scan
pointer math is base + i·width, no block walk, no per-index log2.
Every consumer reads the same span: codegen's specialized/RVV loops
stride it as one run, the gfx scene walker and GPU upload lost their
block-walk mirrors.

Conditional operations do not branch per element: `Vec.filter` and
friends write a MASK (branchless predicate evaluation, SIMD-friendly),
scans fuse the mask, and density is restored by an explicit
`Vec.compact` or automatically at `Sys.poolReset` — compaction is a
frame-boundary event, not a per-element decision. **[pending]**

## Concurrency: nothing blocks, nothing spins hot

* An actor that must wait YIELDS (receive, fuel safepoint) — it never
  holds a core.
* Any CAS retry loop backs off EXPONENTIALLY (capped) before trying
  again — contention degrades bandwidth, never livelocks a hart.
  `fpr_lock` implements this today as the transitional form.
* The end-state has no locks at all: each shared structure is owned
  by one actor and mutated only through its mailbox — buddy/grants
  behind Memory.qa, promotion behind ARC.qa, the same argument as the
  linear-resource-owning services. **[pending: the remaining lock
  sites and their owners are inventoried in MEMORY-V2-PLAN.md]**

## The laws (each one paid for already)

* **Drop what you receive.** Every received message root is dropped
  once read — compiler-discharged on the common shapes (autodrop),
  ARC.qa audits backstop the rest (tests/arcaudit.fpr).
* **Frames are structure, not garbage.** Double-buffer bulk data,
  ping-pong by `sendLinear` (consume) / receive (re-own). Lifetime
  is the loop shape; nothing is ever "collected". (tests/frames.fpr:
  199 cross-actor bounces, arcLive delta 0.)
* **A service owns its linear resource.** One actor holds the linear
  handle; the mailbox is the serialization.
* **Copy on retain.** A nested value kept beyond drop-of-root is a
  dangling pointer; the retainer copies into its own pool.
* **Never send live state.** Reply with a disposable copy — or
  `sendLinear` the real thing and stop owning it. There is no third
  option, which is the point.

## What "no GC" buys and costs

Buys: no pauses, no discovery phase, WCET stays compositional (free
is attributed to the operation that caused it), and the scheduler /
fuel model never has to model a collector. Costs: the laws above are
LAWS — the linearity checker enforces regime 1, autodrop discharges
law 1 on the common shapes, and what the compiler cannot prove stays
manual and reported. The v2 point is that the RUNTIME'S side of the
bargain also stays small: two allocators, three ops, three regimes,
and every "clever" mechanism beyond that either becomes one of these
or gets deleted.
