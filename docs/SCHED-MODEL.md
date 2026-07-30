# SCHED-MODEL.md — the two-tier bounded-latency work-stealing scheduler

Implemented in runtime/core/actors.c, shared verbatim by every machine
layer (virt harts, posix kthreads, qosapp process worlds). This
document is the model the implementation is pinned against; the
constants live in one place at the top of the scheduler section and are
part of qos_v for the WCET triple.

## The design

Per hart: a **backlog** (owner-only list of READY actors, each stamped
with the machine-wide admission counter `g_adm` on entry) feeding a
bounded FIFO **run queue** (refilled up to RQ_CAP per pass). Admission
picks per slot, two tiers:

1. **Aged tier — deterministic.** If any backlog actor has waited more
   than `tau` admissions (`g_adm - ready_at > g_tau`), the OLDEST such
   actor is admitted, oldest-first, no randomness. Runtime-tunable via
   `schedSetTau`; default `FPR_TAU = 64`.
2. **Default tier — weighted random.** Otherwise a single-pass weighted
   reservoir over `acb->weight` (default 1, settable per actor), driven
   by a per-hart LCG seeded from the hart id — deterministic given the
   seed and history, "random" only in the model sense.

**Work stealing — deterministic.** A backlog longer than `DONATE_HI`
donates its oldest entry (stamp preserved — the clock is global) into
one machine-wide FIFO under a single lock (same discipline and same
cost argument as `arc_lock`). An idle hart pops the head before
sleeping: oldest donated work first, no victim scanning, no randomness,
and the migrated actor keeps its age.

`ready` means exactly what the actor machinery already meant: not
deliberately parked — either it fuel-yielded / cooperatively yielded,
or it was blocked in `receive` on an empty mailbox and a message
arrived (the wake CAS ships it). DEAD and re-BLOCKED entries are
unlinked during the selection scan, as `deq` always did.

## The bound

Let A = READY actors resident on a hart (plus anything it steals), and
T_slot the worst-case wall time of one admission slot. Once an actor's
age exceeds tau it outranks every un-aged actor on its hart, and among
aged actors it is served oldest-first. Only actors with an EARLIER
stamp can be admitted ahead of it, and each admission consumes one
slot, so:

    Wait(a)  <=  tau * T_slot  +  A * T_slot            (admissions)

Donation/stealing only tightens this: a donated actor keeps its stamp,
and the steal FIFO serves oldest-donated-first, so migration never
resets aging (the sched.fpr flood phase shows measured max wait
FALLING when stealing engages). T_slot itself decomposes exactly along
the WCET triple (FUEL-RC-ABI.md):

    T_slot <= FUEL_QUANTUM * segmax * c(hw)     [G1: compiler-emitted]
            + sum of C-entry bounds on the path  [G2 table]
            + sched overhead: drain (O(rings)) + one O(backlog) scan
              + steal-lock hold (O(1) pop under the lock)

The randomized tier appears NOWHERE in the bound. It only chooses which
un-aged actor runs, so it shapes expected fairness (weights) while the
worst case is carried entirely by the deterministic tier — which is the
whole point: weighted-random default + deterministic aging + FIFO
stealing is still a system you can pin against a (fprc_v, qos_v, hw_v)
triple.

## Verification

tests/sched.fpr (in run-tests.sh, HARTS=2) pins three things against
the runtime's OWN counters (`schedMaxWait` is maintained by the
admission path itself, in admission units, so the test checks the
model against the mechanism rather than against a stopwatch):

- liveness: 8 ping-pong workers x 200 rounds all complete;
- the aging bound: with `schedSetTau 4`, measured max wait stayed
  within tau + residents (observed 4 vs bound 16);
- deterministic stealing: a burst phase floods one hart's backlog past
  DONATE_HI and asserts `schedSteals > 0` (observed 1000 on rv64 QEMU,
  132 on posix x64 — machine-dependent count, machine-independent
  mechanism).

## Stated limits (the honest remainder)

- `g_max_wait` and `g_steals` are updated without atomics on the
  multi-writer path (monotonic counters, benign races; introspection,
  not correctness).
- The steal lock is global, like arc_lock: contention is bounded by
  donation frequency, stated here so it is found in a document and not
  inside a deadline (same class as G3).
- The backlog scan is O(resident actors) per admission — it is inside
  T_slot above; a hart hosting thousands of ready actors pays it, and
  an indexed aged-queue is the known upgrade if that ever binds.
- Weights are per-actor and honored, but nothing sets them yet except
  the default of 1; `schedSetWeight` exists for when priority classes
  arrive.
