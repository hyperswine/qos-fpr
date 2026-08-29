# MEMORY v2 — the migration plan

docs/MEMORY.md states the v2 contract; this file maps every [pending]
marker to the mechanisms it replaces, file:line, in landing order.
The rule for the whole plan: each phase DELETES more mechanism than it
adds, and no phase changes what programs mean except where a verb
(`send_linear`, `send_arc`) makes a cost explicit that was implicit.

Done already (this branch):
* `buddy_realloc` — buddy.c, proven by qos/tests-host/buddy-check.sh
  (in-place grow via buddy-absorb, in-place shrink, copy fallback,
  coalescing intact after 20k randomized rounds).
* `fpr_pool_init` — fpr.h; all five pool creation sites route through
  it (this is the fix for the Sys.arena uninitialized-bigfree bug).
* Exponential backoff in `fpr_lock` — fpr.h (the transitional form of
  the no-hot-spin rule; deletion per site is phase 5).

## Phase 1 — one freelist-over-buddy helper (delete three recyclers)

The stack pool (hal/core/actors.c:156-187), the grant recycler
(hal/core/runtime.c:183-300), and the chblk backing store
(hal/core/actors.c:235-319) are all "freelist of fixed-size blocks
over a big block". Replace with ONE helper:

    fpr_fixed_t  fpr_fixed(uw blksz);       /* freelist over buddy   */
    void        *fpr_fixed_take(fpr_fixed_t*);
    void         fpr_fixed_put(fpr_fixed_t*, void*);

The chblk EPOCH discipline (deferred reuse across the send/reap race)
is correctness, not recycling — it stays, as a thin wrapper over the
helper. The bucket-ARRAY recycler (runtime.c bkt_take/bkt_put) also
folds in (blksz = 4 KiB). Inventory after phase 1: buddy, per-actor
pool, fpr_fixed. That is the whole list.

## Phase 2 — contiguous Vec on realloc (delete VList + bigfree)

* hal/core/vec.c: `col_t` becomes {base, cap} with ONE contiguous
  span; growth = `buddy_realloc` doubling on the native/qosp tier and
  the grant-realloc path on the process tier. Delete vl_slot/vl_grow/
  vl_cap/VL_B0 (vec.c:33-90) and every per-block walk below them.
* Column storage comes from buddy DIRECTLY (not the pool), so
  realloc applies and the pool's bigfree LIFO (runtime.c:353,477 and
  fpr.h) retires — big blocks were only ever pooled because VList
  couldn't realloc.
* fp-risc/compiler/Codegen.hs specialized loops (the emitters at
  ~1794-2442) drop their block-advance/guard machinery: base + i*w
  addressing shrinks every emitter. The WCET story is unchanged
  (doubling is amortized-O(1) push exactly as VList was; the copy is
  attributed to the push that grew, same as today's vl_grow).
* The layout is declared ONCE in a shared vec_layout.h; delete the
  hand-mirrored copies in hal/unix/gfx.c:761-787, gfx.c:443-446, and
  the `16 << j` literals in the GPU paths. GPU upload and the DRM
  scene walker become single-span memcpys.
* compiler/Sol/Val.hs's vec store mirrors the same change (it is
  already contiguous per column internally; only the FFI boundary
  shifts).
* Gate: tests/vecedge.fpr, vecfuse2, fvec/fvec2, matvec, dtree
  bit-for-bit, and the check-all Vec legs — all must stay green with
  IDENTICAL printed output.

## Phase 3 — the send triad (delete vec CoW)

* `send` = deep copy, NO exceptions. The vec CoW rc (vec.c:105-118,
  rc packed in `var`) exists only to make `Vec.dup` and message
  sharing O(1); with `send_linear` covering the hot path, delete it:
  `Vec.dup` becomes an honest copy, and BOTH CoW soundness holes
  (the Vec.filter in-place compaction, the specialized-tier writes
  that skip the rc test) cease to exist rather than get fixed.
* `send_linear` moves ownership: the message carries the root; vec
  columns and big blocks reparent O(1) (they are buddy blocks — the
  transfer is a header/owner update), the small spine deep-copies
  into the receiver's pool like any message. Compiler surface:
  builtinEnv entry with a consume-linearity shape (Infer.hs derives
  shapes from builtinEnv already — extend that table, never a
  parallel one), Codegen call emission, Sol VM parity, and the
  frames idiom in std/ moves onto it (tests/frames.fpr is the gate:
  199 bounces, arcLive 0, now with zero copies).
* `send_arc` promotes by OWNERSHIP TRANSFER to ARC.qa (phase 4).

## Phase 4 — ARC.qa owns promotion (delete the ARC table + orphan slabs)

Today: a 1024-entry open-addressed table under arc_lock
(runtime.c:874-948) that PANICS when full, plus escaped-counts and
orphaned slabs (fpr.h slab comments) so cross-actor references never
dangle. v2:

* `send_arc` freezes the object and moves it into ARC.qa's pool
  (deep-copy once at promotion — promotion is rare by definition);
  ARC.qa spawns a manager actor per object; INC/DEC are messages to
  that manager; the count is structurally atomic because the mailbox
  linearizes it. DEC-to-zero: dealloc + manager exits.
* Holders read through the raw pointer while their count is live
  (the object is frozen); no read ever messages anyone.
* Needs the missing primitive MEMORY.md already names: monitor-style
  death notification (subscribe once, get told when a registrant
  dies), so a holder's crash DECs its counts. General-purpose — any
  registration service wants it.
* Delete: arc_lock, the table, the tombstone machinery, slab
  `escaped`/orphaning, and the `total==0` poison tripwire — the
  interaction of three refcounts becomes the interaction of one
  count in one mailbox. Capacity is now ARC.qa's pool: exhaustion is
  a refused promotion (an Err to the sender), never a machine panic.
* mods/arcsvc.fpr keeps its stats/baseline/audit protocol on top —
  unchanged surface, real ownership underneath.

## Phase 5 — delete the locks (each behind its owner)

fpr_lock now backs off exponentially (done); the end-state deletes
each site by giving the structure one owner:

| lock                      | site                    | owner in v2                         |
|---------------------------|-------------------------|-------------------------------------|
| buddy_lock                | hal/core/buddy.c        | Memory.qa mailbox (grants are rare) |
| grant_lock                | hal/core/runtime.c:235  | retires with phase 1's fpr_fixed    |
| arc_lock                  | hal/core/runtime.c      | retires with phase 4                |
| ledger/reap               | hal/core/actors.c       | owner-hart only + messages          |
| grow_mu / store_mu        | qos/portable/main.c     | the storage/growth trampoline actor |
| gfx statics cache         | hal/unix/gfx.c          | the render service actor (already   |
|                           |                         | single-caller in practice)          |

Rules that hold from today onward: an actor that must wait yields
(receive / safepoint), never spins; any remaining CAS loop backs off
exponentially (fpr_backoff); no new fpr_lock site lands without a row
in this table naming the owner that will delete it.

## Phase 6 — masked filter (branch-light conditionals)

After phase 2, `Vec.filter` stops compacting in place per element:

* filter writes a mask column (predicate evaluated branchlessly —
  cmov/SIMD lanes, no per-element taken/not-taken branch);
* scans (map/fold/zip) FUSE the mask — the fixed-function tier and
  the specialized loops both read it as a lane select;
* density is restored by explicit `Vec.compact` or automatically at
  `Sys.poolReset` — a frame-boundary event, one pass, branch-light.

This inverts vec.c's old comment (which chose eager compaction to
keep scans mask-free); the v2 judgment is that per-element branching
in filter poisons the wide path more than a fused mask does, and the
compaction pass at the loop boundary restores density where the old
argument wanted it. If a workload proves otherwise, `Vec.compact`
directly after filter IS the old behavior — the policy moved to the
program, which is where this codebase puts policy.

## Test strategy

* buddy-check.sh: in check-all as a host leg (done).
* Phases 2/3: the existing golden legs are the gate (dtree
  bit-for-bit, frames, arcaudit, vec legs, Sol parity legs) — output
  must be IDENTICAL; a phase that changes a golden line is wrong.
* Phase 4: arcaudit.fpr gains a leg where a holder dies without
  DECing and the death notification balances the count.
* Every deleted mechanism takes its dead declarations with it
  (fpr.h's duplicated buddy block included).
