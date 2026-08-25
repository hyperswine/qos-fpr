# The memory model

No GC. Ever. Everything below is Rc, Arc, or linear ownership — and the
architecture is arranged so that Arc, the only genuinely dangerous one,
is small, audited, and owned by one service.

## The tiers, bottom to top

1. **Buddy (Memory.qa's mechanism).** One global buddy allocator hands
   out GRANTS to actors/processes. Single-owner during bootstrap;
   multicore use linearized behind Memory.qa. Nothing else talks to it.

2. **Per-actor slab pools.** An actor partitions its grant into slab
   pools (per-constructor/type for ADT data). Death returns clean slabs
   to the grant recycler wholesale — an actor's memory lifetime IS the
   actor's lifetime, no per-object discovery. Long-lived actors use
   `Sys.poolReset` at loop boundaries (soft death: the persistent
   frame-worker pattern) so "immortal" never means "accumulating".

3. **Rc — intra-actor, escape-free.** Tree/list data inside one actor
   is reference-counted at the existing safepoints. Rc reaching zero
   may return contiguous regions to the grant, and the same step is
   where slab defrag can form a returnable buddy block. Rc never
   crosses an actor boundary; there is nothing concurrent about it.

4. **Linear ownership — the DEFAULT for bulk data.** SoA Vectors,
   BStr-class buffers, frames: exactly one owner, mutation in place
   through the threaded handle, `Vec.free`/scope-exit returns the
   storage. Growth is realloc-by-doubling; release is all-at-once.
   Provably-scoped work uses arenas (bump, free wholesale).

5. **Arc — cross-actor escapes ONLY, policy owned by ARC.qa.** The
   incref/decref mechanism stays in the HAL (hal/core/runtime.c): it
   sits on the send/spawn hot path and a service round-trip there would
   be absurd. But everything DISCRETIONARY about Arc is one actor's
   business: **ARC.qa**, registered at `/services/arc` when loaded
   (programs/mods/arcsvc.fpr). Baselines, audits, leak verdicts,
   budgets — a conversation with that actor, not ambient introspection
   scattered through programs. Most code should never think about Arc
   at all; code that does (schedulers, shells, soak tests) asks the
   service.

   The end-state (docs/NOTES-clarifis.md §5): Arc's own refcounts are
   mutated only by messages it drains through its single mailbox, so
   ARC.qa needs no internal lock analogous to `arc_lock` — actor
   topology IS the serialization, the same argument as the linear-
   resource-owning services in tier 4. Registrants send their
   (actor_id, pid); the open primitive is monitor-style death
   notification (subscribe once, get told when a registrant dies
   without its cooperation) — a general missing primitive for ANY
   service with per-client registration, not Arc-specific.

## The laws (each one paid for already)

* **Drop what you receive.** Every received message root is dropped
  once read. An immortal actor that skips one drop keeps that root
  forever — tests/arcaudit.fpr shows ARC.qa catching exactly this.
* **Frames are structure, not garbage.** Double-buffer bulk data:
  two linear buffers, ping-pong by send (consume) / receive (re-own).
  Lifetime is the loop shape; nothing is ever "collected".
  tests/frames.fpr: 199 cross-actor frame bounces, arcLive delta 0.
* **A service owns its linear resource.** One actor holds the linear
  handle; being an actor with a mailbox IS the serialization. Nobody
  else can leak what nobody else can touch.
* **Copy on retain.** A nested value kept beyond drop-of-root is a
  dangling pointer; the retainer copies into its own pool. `"{x}"` is
  NOT a copy (single-segment interpolation is identity).
* **Never send live state.** Reply with a disposable copy of the
  spine; the receiver rightly drops what it receives.

## What "no GC" buys and costs

Buys: no pauses, no discovery phase, WCET stays compositional (free is
attributed to the operation that caused it), and the fpr-scheduler /
fuel model never has to model a collector. Costs: the five laws above
are LAWS — the compiler's linearity checker enforces tier 4, drop
discipline on message roots is enforced today by ARC.qa audits in CI
(the soak legs), and the honest next step is compiler-inserted drops
on receive paths so law 1 stops being manual at all.
