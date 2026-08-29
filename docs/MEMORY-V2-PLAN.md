# MEMORY v2 — the migration plan

docs/MEMORY.md states the v2 contract; this file maps every [pending]
marker to the mechanisms it replaces, file:line, in landing order.
The rule for the whole plan: each phase DELETES more mechanism than it
adds, and no phase changes what programs mean except where a verb
(`send_linear`, `send_arc`) makes a cost explicit that was implicit.

Done on this branch — foundations, then phases 1 and 2:
* `buddy_realloc` — buddy.c, proven by qos/tests-host/buddy-check.sh
  (in-place grow via buddy-absorb, in-place shrink, copy fallback,
  coalescing intact after 20k randomized rounds).
* `fpr_pool_init` — fpr.h; all five pool creation sites route through
  it (this is the fix for the Sys.arena uninitialized-bigfree bug).
* Exponential backoff in `fpr_lock` — fpr.h (the transitional form of
  the no-hot-spin rule; deletion per site is phase 5).

## Phase 1 — one freelist discipline **[LANDED]**

Landed as `fpr_freelist_t` / `fpr_fl_take` / `fpr_fl_put` (fpr.h,
runtime.c) — first-fit over capacity-carrying nodes rather than the
planned fixed-size-only helper, because the grant pool's blocks vary
in size and first-fit covers the fixed-size users trivially. Its four
instances: the stack pool, the bucket-array recycler, the chblk carve
extras, and the grant pool. The chblk EPOCH limbo stays as its own
discipline on top (correctness, not recycling); the acb bump arena
got its own lock instead of borrowing the stack pool's. Verified:
the full qosp-reachable golden set byte-identical.

## Phase 2 — contiguous Vec on realloc **[LANDED]**

* hal/core/vec.c: `col_t` is {cap, base} — ONE contiguous span, base
  at word offset 1 (the slot the old directory kept blk[0] in, so
  Codegen's colBlk0 pins unchanged). vl_slot/vl_grow/vl_cap/VL_DIR
  and every per-block walk deleted; the SIMD tier (VS_BLOCKS/VS_ZIP,
  blend, burst, gather) runs single spans.
* Growth is `fpr_realloc` (runtime.c): copy-based through the pool
  tiers, the freed predecessor recycling exactly. TWO DEVIATIONS
  from the plan, recorded: (a) columns still allocate through the
  pool, not buddy-direct — one allocation path is simpler, and the
  process tier has no buddy under it anyway; in-place growth arrives
  when bulk storage sits behind Memory.qa. (b) bigfree therefore
  STAYS: it is the pool's exact-fit recycler for ALL big payloads
  (strings included), and it is precisely what makes the realloc
  ladder cheap. Its deletion moves to the Memory.qa phase.
* Codegen.hs: specBlock reads base + done·W and hands the whole
  remainder as one chunk (the loop shape and all five emitters keep
  their structure; the next-block arm is now just the exit recheck);
  the filter write cursor lost its per-block refill; mvmap and the
  SoA fold dual load base-relative cursors. RVV strip-mining now
  runs whole-column. fvec2's asm greps (fadd.d, the VR_FLT guard)
  still hold.
* hal/unix/gfx.c: both mirrors ({cap, base}) and the GPU
  marshalling loops became straight copies; fpr_gpu_vec_axpb now
  takes the raw span. portable-gl builds; the DRM branch
  syntax-checks.
* Sol needed NO change: its vec store is Haskell-side (Val.hs), not
  a reader of this layout.
* Verified: the golden set byte-identical except two footprint
  diagnostics, both explained and accepted — bigfree.fpr's steady
  arena reads 5MB (doubling transiently holds old+new; still flat
  over 40 cycles, the actual invariant) and matvec's negative-control
  heap delta shifted (smaller). dtree stays bit-for-bit; all three
  Sol tiers agree; pathnotes/livereload (plugins, hot-swap, disk)
  green; buddy-check green.

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
| fpr_freelist_t mu ×4      | fpr.h (phase 1)         | one discipline now; each instance   |
| (stacks/bkts/chb/grants)  |                         | retires behind Memory.qa with buddy |
| acb_lock                  | hal/core/actors.c       | Memory.qa (acb carving is a grant)  |
| chb_lock (epoch limbo)    | hal/core/actors.c       | owner-hart epochs + messages        |
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
