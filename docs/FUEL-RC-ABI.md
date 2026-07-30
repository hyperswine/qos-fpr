# FUEL-RC-ABI.md — the cooperative-fuel, ARC, and C-ABI contract

The point of this document: state, in one place, exactly where fuel is
consumed, exactly where reference counts move, and exactly what the C
ABI boundary (generated code <-> runtime <-> HAL) guarantees — because a
WCET model for a version triple (FP-RISC compiler version, QOS version,
hardware version) can only be as tight as the loosest unstated part of
these three contracts. Everything below is verified against the current
tree (suites green on rv64 bare-metal QEMU, posix x64, posix a64); the
GAPS section is the honest remainder between this contract and a real
WCET bound.

## 1. Fuel — the cooperative execution quantum

**The invariant: every unbounded control path passes a fuel safepoint.**

Sites, exhaustively:

1. **Supercombinator entry** (Codegen, one check per generated
   function): decrement `0(tp)` (fpr_hart_t.fuel), branch-if-positive,
   else `call fpr_fuel_exhausted`. 6 instructions on the fast path,
   t0/t1 only. After lambda lifting ALL loops are tail calls to
   top-level functions, so every loop back-edge passes function entry —
   including allocation-free busy spins. This is why the check lives at
   entry and not in fpr_alloc.
2. **Clause-fallthrough join functions** (new, this change): a clause
   group whose fallthrough is bound as a join compiles the fallthrough
   as a saturated TAIL call into a lifted function — which is itself a
   supercombinator with the entry check. Consequence for the WCET
   model: falling through k clauses costs exactly k fuel units and O(1)
   stack, uniformly. (Before this change, fallthrough was inlined —
   zero fuel but potentially exponential code size; the accounting is
   now linear and countable.)
3. **Vector kernels** (typed and untyped `specFuel`): one decrement per
   kernel INVOCATION, not per element. A `Vec.map` over n elements is
   therefore ONE fuel unit of accounting for O(n) work — see GAPS.
4. **fpr_fuel_exhausted** (actors.c): bumps fuel_preempts, refills to
   FUEL_QUANTUM, and yields through the same descheduling path as
   block/yield/death — there is ONE way off a hart, which is what makes
   the scheduler's state machine auditable.

**Register/TLS mapping is per machine layer, semantics are identical:**
rv64 keeps the hart struct at `tp`; x64 lowers `mv t0, tp` to an
initial-exec TLS load; a64 uses adrp-based deTLS. The fuel cell is
always word 0 of the hart struct. Any new machine layer must preserve
"fuel is one load/dec/store/branch at a fixed offset" or the entry-cost
constant in the WCET model changes.

**The fpr_fuel_exhausted clobber contract:** it is a real C call and
clobbers a0..a7 — the entry stub spills params to frame slots BEFORE the
check, so the contract holds by construction. Anyone adding a safepoint
elsewhere must re-establish this (spill first, or prove nothing live in
argument registers).

## 2. ARC — escape-based reference counting

**The invariant: ordinary computation does zero RC work.** Values are
slab-allocated and owned by their actor; they die with the actor (or
with scope, via slab accounting). Reference counts exist ONLY for values
that escape an actor:

- `fpr_arc_incref` at exactly two promotion sites: **send** (the message
  becomes shared) and **spawn** (the entry closure is pinned into the
  child).
- `fpr_arc_decref` at consumption/death: entry unpin at actor death,
  explicit drop, teardown.
- Promotion also pins the owning slab (`escaped++`); the last escapee of
  an orphaned slab frees the whole slab.
- One global lock guards the ARC table; contention is bounded because
  promotion happens on SEND, which is rare next to computation — the
  SPSC ring story stays clean because the ARC table is the only
  shared-mutable structure that is not a single-producer ring.

Consequence for WCET: RC cost is attributable to MESSAGE COUNT, not to
allocation or data size. A hart's worst case is
(sends x incref-under-lock) + (received-messages x decref-under-lock),
and the lock hold time is a bounded probe of a fixed-size table
(ARC_CAP; table-full is a panic, i.e. a stated capacity limit, not a
degradation). The ring test pins the model end-to-end: "arc live after
100k promote/drop cycles: 4".

## 3. The C ABI boundary (generated code <-> runtime/HAL)

What generated code assumes when it calls C (`fpr_fuel_exhausted`,
`fpr_alloc`, `fpr_send*`, `fpr_hal_*`, service calls):

1. **Calling convention:** the machine layer's native C ABI (rv64
   lp64 / SysV x86-64 with the documented arg0 fixup / A64). Generated
   code spills its live state to frame slots before any C call.
2. **Fuel:** C code does NOT consume fuel. The fuel model bounds
   GENERATED-code time between safepoints; every C call is a black box
   whose duration is a per-(QOS version, HW version) constant that the
   WCET model must supply per entry point. This is a feature for
   modelling (C entry points are enumerable) and a hazard for anyone
   adding an unbounded loop to a HAL function — a HAL call that blocks
   or spins does so OUTSIDE the fuel budget and holds the hart.
   Rule: HAL functions must be O(bounded) or must themselves yield via
   the actor machinery (the syscall mailbox pattern), never spin.
3. **RC/ownership:** arguments passed to HAL/runtime calls are BORROWED
   — the callee does not decref, and must incref (promote) anything it
   stores beyond the call (send/spawn are exactly this, and they do).
   Return values are owned by the caller's actor slab like any
   allocation. There is no other convention in the tree; any new HAL
   entry that retains a pointer without promotion is a use-after-death
   bug against actor teardown.
4. **Preemption:** cooperative only, from generated code's perspective —
   a hart switches actors only at safepoints (fuel/block/yield/death).
   Interrupt handlers on bare metal enqueue work for service actors;
   they do not preempt an actor mid-computation into another actor.
   This is load-bearing for both the linear-ownership story (no
   torn in-place mutation) and WCET composition (an actor's segment
   between safepoints is uninterruptible-by-peers).

## 4. Toward WCET(fprc_v, qos_v, hw_v)

With the three contracts above, a WCET bound for an actor program
decomposes as:

    T(segment) = sum over basic blocks of instruction cost   [fprc_v, hw_v]
               + entries x fuel-check constant               [fprc_v, hw_v]
               + sum over C calls of C-entry-point bound     [qos_v, hw_v]
               + sends x promotion bound + recvs x decref bound  [qos_v, hw_v]

and scheduler-level latency is FUEL_QUANTUM x (worst instructions per
fuel unit) per runnable peer — WHICH IS EXACTLY WHERE THE GAPS BITE:

**GAPS (the difference between this document and a real model):**

- **G1 — fuel unit != bounded time. [CLOSED at the compiler]** fprc now
  computes, per emitted function, the maximum IR-instruction count on
  any path between consecutive safepoint events (entry check, kernel
  checks, calls/jumps into fpr_fn_*), by walking the emitted assembly
  as a CFG — a DAG, since all loops are tail calls; a back-edge would
  report UNBOUNDED loudly, and none exists anywhere in the tree. Every
  function gets a `# wcet:` comment (segmax, exit-tail for chaining,
  ccall count); `FPRC_WCET=1` prints the table and program max
  (System.qa: 212 functions, max segment 221 IR insns). Counts are
  pre-lowering IR — the per-target lowering factor and cycles-per-insn
  belong to hw_v. What remains of G1 proper: A fuel unit is "one function
  entry", but the work between two entries is a function BODY, and a
  body with a long straight-line vector kernel (one fuel per kernel
  call, O(n) lanes) or a huge literal fold can be arbitrarily long.
  For WCET the model needs max-instructions-between-safepoints as a
  COMPILER-EMITTED constant per program (fprc can compute it per
  function; kernels need per-invocation lane caps or a fuel decrement
  per N lanes with N chosen so N x lane-cost <= the quantum's time
  target on hw_v).
- **G2 — C entry points are unbounded by construction today.** The
  table of HAL/runtime entry points with per-(qos_v, hw_v) time bounds
  does not exist yet. It is enumerable (the extern surface of
  runtime/core + the machine layer) and most entries are trivially
  bounded; the exceptions to chase are anything that loops on device
  state. QEMU's timing generosity hides exactly these.
- **G3 — the ARC lock is global.** The decref/incref bound above is
  per-op, but cross-hart contention on arc_lock makes the worst case
  (harts x concurrent promotions) x probe cost. Fine at current scale,
  stated here so nobody discovers it inside a deadline.
- **G4 — allocator: fpr_alloc's bump path is O(1), but bucket refill /
  buddy free (slab orphan return) are not constant and run under
  arc_lock in the teardown path. Needs a stated bound or deferral off
  the hot path before hard deadlines.
- **G5 — version pinning.** The module system content-addresses the
  AST, so a COMPILER AST-schema change re-hashes byte-identical source
  (this change did: guard slot Maybe->list re-pinned mods/mymod{,2};
  system.fpr's timefmt/qlog/tui pins need the same when it compiles
  again). For the immutable triple this is actually the right
  behavior — a pin is valid per fprc_v — but it should be SAID: a
  version triple fixes (compiler AST schema + codegen), (runtime C +
  HAL surface), (timing constants), and pins do not survive fprc_v
  bumps.

The order to close them: G1 (compiler-emitted per-function safepoint
distance) and G2 (the HAL bound table) are the two that turn this
contract into numbers; G3/G4 are engineering under known locks; G5 is a
sentence in the release discipline.
