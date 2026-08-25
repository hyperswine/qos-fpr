/* actors.c — actor runtime v3: MULTI-HART, ALL-SPSC.
 *
 * v2 gave every actor per-sender SPSC channels precisely so that going
 * multi-hart would be a FENCE INSERTION, not a redesign.  This is that
 * insertion, plus the scheduler restructure it forces:
 *
 *   TOPOLOGY.  Every ring in the system still has exactly one writer
 *   and one reader:
 *     - message channels: writer = the sender ACTOR (an actor runs on
 *       exactly one hart at a time and never migrates), reader = the
 *       owning actor.  The v2 storage is unchanged; head/tail crossings
 *       now carry acquire/release.
 *     - wake/spawn shipping: a FPR_NHARTS x FPR_NHARTS matrix of SPSC
 *       rings of acb pointers; writer = source hart, reader = owner
 *       hart.  No shared run queue, no CAS loop on a list, ever.
 *   The only non-ring shared-mutable state is the actor STATUS word
 *   (a 3-state CAS: the wake protocol needs consensus on who enqueues)
 *   and the ARC table (spin-locked in runtime.c).
 *
 *   SCHEDULER.  Each hart runs a hart loop on its boot stack: drain
 *   inbound wake rings into the local FIFO run queue, run one actor to
 *   its next safepoint (block / yield / fuel exhaustion / death), and
 *   loop.  Actors are PINNED to the hart that spawnOn named (plain
 *   spawn = current hart); `main` itself is actor 0 on hart 0, spawned
 *   like everyone else so the boot stack can become the hart loop.
 *
 *   FUEL is per-hart now: generated code decrements 0(tp) -- see the
 *   fpr_hart_t essay in fpr.h.  The quantum refill sites are unchanged.
 *
 *   THE BLOCK/WAKE PROTOCOL (the one lost-wakeup trap in this design):
 *     sender:   publish message (release rt)
 *               fence seq_cst
 *               if CAS(status, BLOCKED -> READY) succeeds: ship(acb)
 *     receiver: scan channels; if satisfied, take it
 *               CAS(status, READY -> BLOCKED); fence seq_cst
 *               RE-SCAN; if now satisfied: CAS back to READY, continue
 *               else switch to the hart loop
 *     Both sides put a seq_cst fence between "my write" and "their
 *     flag", the Dekker pattern; whoever loses the race still sees the
 *     other's write, so a message published while blocking is either
 *     re-scanned by the receiver or CAS-woken by the sender.  Spurious
 *     wakes and duplicate run-queue entries are possible and HARMLESS:
 *     all entries for an actor land on its one owner hart, so execution
 *     is always sequential; a stale entry for a BLOCKED actor is
 *     skipped by deq (each real wake re-ships).
 *
 *   DEADLOCK detection had to become global: an empty local queue just
 *   means the work is elsewhere.  Hart 0's loop declares deadlock only
 *   when (all harts idle) && (someone is blocked) && (the global
 *   activity counter has not moved) held stable across a long window --
 *   any in-flight send keeps its hart non-idle, so a stable window is a
 *   real deadlock, not a race.
 *
 * Lifetime semantics from v2 kept: body-return = death, send-to-dead =
 * silent no-op, stacks leak on death, selective receive by sender /
 * by Result type over the same rings.  kill of a RUNNING actor on
 * another hart is advisory: it lands at that actor's next safepoint.
 */
#include "fpr.h"

#ifndef FPR_STACK_SZ
#define FPR_STACK_SZ (256 * 1024)
#endif
#define STACK_SZ FPR_STACK_SZ
#define MAXSND 8    /* per-sender channels per actor */
#define RING_CAP 64 /* messages per channel; power of two */
#define XCAP 64     /* acb pointers per cross-hart wake ring */

#define FUEL_QUANTUM 2000 /* FPRISC function entries per scheduling slice */

enum { ST_READY, ST_BLOCKED, ST_DEAD };

/* one SPSC channel: bound to a single sender for the actor's lifetime */
typedef struct {
  uw sender;       /* sender id + 1; 0 = unbound (claimed by CAS) */
  uint32_t rh, rt; /* free-running head/tail; count = rt - rh */
  V ring[RING_CAP];
} chan_t;

typedef struct fpr_acb {
  uint32_t tid, var; /* var = status word (atomic; doubles as header) */
  uw ctx[16];        /* ra sp gp tp s0..s11 */
  chan_t *ch;        /* MAXSND channels, OUT-OF-LINE (see chblk below):
                      * the acb stays permanent (send-to-dead reads
                      * var), but its 8 KiB of rings is reclaimed at
                      * reap -- the permanent residue per dead actor is
                      * now ~sizeof(acb_t) ~= 250 B, which is what the
                      * "stated ceiling" always meant to say */
  uint32_t scan; /* round-robin cursor for fair receive (owner-only) */
  V entry;       /* PAP to run: body = entry(self); 0 for main */
  struct fpr_acb *next; /* run-queue link (owner hart only) */
  struct fpr_acb *bl_next; /* backlog link (owner hart only) */
  uw ready_at; /* g_adm stamp when it entered a backlog (aging tier) */
  uw weight;   /* selection weight for the randomized default tier (>=1) */
  char *stack;
  uw id;
  uw hart;         /* owner hart (donation can move it unless pin) */
  uw pin;          /* 1 = never donated: actor 0, and spawnOn-placed
                    * actors -- explicit placement is an affinity
                    * contract (a graphics actor's EGL context is bound
                    * to its hart's thread on hosted targets) */
  uw parent;              /* spawner's actor id (0 = the boot actor) */
  struct fpr_acb *all_nx; /* the all-actors ledger (monitor's walk) */
  fpr_slab_t *drop_pending; /* dropped-message slabs awaiting the next
                             * receive (fpr_drop_park in fpr.h): the
                             * borrow window the compiler's autodrop
                             * leans on ends there, so that's where
                             * the batch is released */
  fpr_pool_t pool; /* this actor's slabs + recycle buckets (slab refactor) */
} acb_t;

/* ---- deferred message-slab release (see fpr.h) ---------------------- */
void fpr_drop_park(fpr_slab_t *sl) {
  acb_t *a = fpr_hart()->current;
  if (!a) { fpr_slab_release(sl); return; } /* hart-loop context: no borrower */
  sl->next = a->drop_pending;
  a->drop_pending = sl;
}
static void drop_drain(acb_t *a) {
  fpr_slab_t *sl = a->drop_pending;
  if (!sl) return;
  a->drop_pending = 0;
  while (sl) {
    fpr_slab_t *nx = sl->next;
    fpr_slab_release(sl);
    sl = nx;
  }
}
void fpr_drop_drain_current(void) {
  acb_t *a = fpr_hart()->current;
  if (a) drop_drain(a);
}

fpr_pool_t *fpr_acb_pool(struct fpr_acb *a) { return &a->pool; }

/* big raw blocks (stacks, acbs): buddy on a machine boot; inside a
 * loaded process, a grant from the loader (the process has no buddy).
 * Process-mode blocks are reclaimed wholesale at process exit. */
static void *big_block(uw n) {
  if (!fpr_is_process) return buddy_alloc(n);
  fpr_grant_t g = fpr_grow_counted(n, 4); /* big-block: stacks/acbs */
  return (g.ptr && g.size >= n) ? g.ptr : 0;
}

/* ---- process-mode spawn-side recycling ------------------------------
 * Grants are never returned to the loader, so without recycling every
 * spawn leaks a full stack grant and a mostly-empty acb grant --
 * frame-per-actor designs (pshell) burn the whole arena in seconds.
 *
 *   stacks: all STACK_SZ, so dead stacks go on a free list and the
 *           next spawn pops one (mirrors runtime.c's slab recycler);
 *   acbs:   PERMANENT by contract (the acb IS the actor value that
 *           send-to-dead reads), so they cannot be recycled -- but a
 *           bump arena carves many acbs from one grant instead of
 *           wasting a 64 KiB minimum grant on each 8 KiB acb. */
static void *stack_pool;
static fpr_lock_t stack_lock;
static char *acb_hp, *acb_end;

/* pool telemetry, always on, PULL-based (Sys.memStats reads them):
 * a print at an allocation site is a syscall inside the allocator */
uw fpr_stk_pushes, fpr_stk_misses, fpr_spawns, fpr_chb_carves;
static void stack_recycle(void *p);
static void *stack_block(void) {
  if (!fpr_is_process) return buddy_alloc(STACK_SZ);
  fpr_lock(&stack_lock);
  void *p = stack_pool;
  if (p) stack_pool = *(void **)p;
  else fpr_stk_misses++;
  fpr_unlock(&stack_lock);
  if (p) return p;
  /* SELF-TOPPING on a miss: take two, keep one warm.  A miss means
   * live+in-flight actors exceeded pool depth, so depth converges to
   * the real concurrency and each level is paid for at most once --
   * without this the boot immortals consume any fixed pre-warm and
   * the spawn-vs-death-epilogue race keeps finding an empty pool
   * (measured: 13 misses/8k spawns, ~12KB/s of permanent stacks). */
  void *spare = big_block(STACK_SZ);
  if (spare) stack_recycle(spare);
  return big_block(STACK_SZ);
}

static void stack_recycle(void *p) {
  fpr_lock(&stack_lock);
  *(void **)p = stack_pool;
  stack_pool = p;
  fpr_stk_pushes++;
  fpr_unlock(&stack_lock);
}

static acb_t *acb_block(void) {
  /* BOTH modes bump-carve: acbs are permanent by contract, and the
   * lower allocators have a 64 KiB floor (buddy's BUDDY_MIN_BLOCK, the
   * loader's grant rounding) -- one block per 250 B acb exhausted the
   * posix heap in ~1000 spawns on a Pi 4.  Carving packs ~250 acbs
   * into each floor-sized block. */
  uw sz = (sizeof(acb_t) + 15) & ~(uw)15;
  fpr_lock(&stack_lock);
  if (acb_hp + sz > acb_end) {
    uw want = 16 * sz;
    char *p;
    uw got;
    if (fpr_is_process && fpr_grow_memory) {
      /* no growlog here: this runs under stack_lock, and the trace
       * print is a uart SYSCALL under qosp -- printing inside an
       * allocator lock stalls the world and poisons the very numbers
       * the trace exists to collect (a lesson measured the hard way) */
      fpr_grant_t g = fpr_grow_counted(want, 5); /* stack pool */
      p = (char *)g.ptr;
      got = g.size;
    } else {
      p = (char *)buddy_alloc(want);
      got = p ? buddy_block_usable_size(p) : 0;
    }
    if (!p || got < sz) {
      fpr_unlock(&stack_lock);
      return 0;
    }
    acb_hp = p;
    acb_end = p + got;
  }
  acb_t *a = (acb_t *)acb_hp;
  acb_hp += sz;
  fpr_unlock(&stack_lock);
  return a;
}

/* ---- out-of-line channel blocks: type-stable, epoch-deferred --------
 * The acb permanence contract exists so a stale handle's send is a
 * harmless read of var==ST_DEAD.  But send CHECKS var and then TOUCHES
 * the channels -- so channel memory cannot be handed to anything else
 * while such a send may be in flight.  Two properties make reuse
 * sound:
 *
 *   TYPE-STABLE: a channel block is only ever reused as a channel
 *   block, so a racing access reads well-formed channel memory;
 *
 *   EPOCH-DEFERRED: every hart bumps h->epoch once per hart-loop
 *   iteration, and a send runs INSIDE one scheduler segment on its
 *   hart -- its hart's epoch cannot advance past it.  A reaped block
 *   parks on a limbo list stamped with every live hart's epoch and is
 *   reused only after each has advanced by 2: any send that loaded a
 *   stale var==READY has long since completed.
 *
 * Without this, frame-per-actor designs retire 8 KiB of dead rings
 * per frame forever (pshell exhausted a Pi 4's arena in minutes). */
typedef struct chblk {
  chan_t ch[MAXSND];
  struct chblk *nx;
  uw stamp[FPR_NHARTS];
} chblk_t;
static chblk_t *chb_free, *chb_limbo;
static fpr_lock_t chb_lock;

static int chb_matured(chblk_t *b) {
  for (uw i = 0; i < fpr_live_harts; i++)
    if (fpr_harts[i].epoch < b->stamp[i] + 2) return 0;
  return 1;
}

static chan_t *chb_take(void) {
  chblk_t *b = 0;
  fpr_lock(&chb_lock);
  /* matured limbo first, then the free list */
  chblk_t **pp = &chb_limbo;
  while (*pp) {
    if (chb_matured(*pp)) {
      b = *pp;
      *pp = b->nx;
      break;
    }
    pp = &(*pp)->nx;
  }
  if (!b && chb_free) {
    b = chb_free;
    chb_free = b->nx;
  }
  fpr_unlock(&chb_lock);
  if (!b) {
    /* fresh backing: the floor-sized block carves several channel
     * blocks; the extras seed the free list (type-stable forever) */
    uw sz = (sizeof(chblk_t) + 15) & ~(uw)15;
    uw want = sz * 4;
    fpr_chb_carves++;
    char *p = (char *)big_block(want);
    if (!p) return 0;
    uw got = fpr_is_process ? want : buddy_block_usable_size(p);
    if (got < sz) got = sz;
    b = (chblk_t *)p;
    fpr_lock(&chb_lock);
    for (char *q = p + sz; q + sz <= p + got; q += sz) {
      ((chblk_t *)q)->nx = chb_free;
      chb_free = (chblk_t *)q;
    }
    fpr_unlock(&chb_lock);
  }
  for (int i = 0; i < MAXSND; i++) {
    b->ch[i].sender = 0;
    b->ch[i].rh = b->ch[i].rt = 0;
  }
  return b->ch;
}

static void chb_limbo_put(chan_t *ch) {
  chblk_t *b = (chblk_t *)ch; /* ch is the block's first member */
  fpr_lock(&chb_lock);
  for (uw i = 0; i < FPR_NHARTS; i++)
    b->stamp[i] = (i < fpr_live_harts) ? fpr_harts[i].epoch : 0;
  b->nx = chb_limbo;
  chb_limbo = b;
  fpr_unlock(&chb_lock);
}

/* death reclamation (called from the hart loop, NEVER on the dying
 * actor's own stack): slabs via the ARC-locked teardown, stack -- which
 * cannot escape -- straight back to buddy.  Idempotent via stack=0. */
static void reap(acb_t *a) {
  if (!a->stack) return;
  drop_drain(a); /* dropped-message slabs the dead actor never received after */
  fpr_pool_reclaim(a);
  if (fpr_is_process) stack_recycle(a->stack);
  else buddy_free(a->stack);
  a->stack = 0;
  if (a->ch) {
    chb_limbo_put(a->ch); /* deferred: see the epoch essay above */
    a->ch = 0;
  }
  if (a->entry) { fpr_arc_decref(a->entry); a->entry = 0; } /* unpin the closure */
  /* the acb itself stays: it IS the actor value other actors hold
   * (send-to-dead reads a->var).  ~sizeof(acb_t) per actor, stated. */
}

extern void fpr_ctx_switch(uw *save, uw *load);
extern V fpr_fn_main(void);
extern void fpr_exit(V result);
extern void fpr_set_tp(fpr_hart_t *h);
extern volatile uint32_t fpr_shutdown;
extern void fpr_rvv_enable(void); /* mstatus.VS is per-hart; weak default defined in runtime.c */

/* hal.c: CLINT-based sleep/wake (see the wfi essay there) */
void hal_ipi_send(uw hart);
void hal_ipi_clear(uw hart);
void hal_timer_park(uw hart);
void hal_timer_arm(uw hart, uint64_t delta);
void hal_wfi_enable(void);
void hal_wfi(void);

/* ---- shared counters (the deadlock detector's whole world) ----------- */
static uw next_id;                 /* atomic fetch_add */
/* every acb ever, newest first (acbs are immortal, so the walk is
 * always safe; readers tolerate concurrent pushes -- push is a single
 * release store of the head) */
static acb_t *g_all;
static void ledger_push(acb_t *a) {
  acb_t *h;
  do {
    h = __atomic_load_n(&g_all, __ATOMIC_ACQUIRE);
    a->all_nx = h;
  } while (!__atomic_compare_exchange_n(&g_all, &h, a, 0, __ATOMIC_RELEASE,
                                        __ATOMIC_ACQUIRE));
}
static volatile uw g_blocked;      /* actors currently parked */
static volatile uw g_activity;     /* bumped on every ship/spawn */

/* ---- cross-hart wake rings: xr[src][dst], strictly SPSC -------------- */
typedef struct {
  uint32_t rh, rt;
  acb_t *ring[XCAP];
} xring_t;
static xring_t xr[FPR_NHARTS][FPR_NHARTS];

static void xpush(uw src, uw dst, acb_t *a) {
  xring_t *x = &xr[src][dst];
  /* single producer: only OUR rt moves; spin if the consumer lags */
  while (x->rt - __atomic_load_n(&x->rh, __ATOMIC_ACQUIRE) == XCAP)
    __asm__ volatile("nop");
  x->ring[x->rt % XCAP] = a;
  __atomic_store_n(&x->rt, x->rt + 1, __ATOMIC_RELEASE);
}

/* ---- the two-tier bounded-latency scheduler (docs/SCHED-MODEL.md) -----
 *
 * READY actors land in the per-hart BACKLOG (owner-only list) stamped
 * with the machine-wide admission counter g_adm. Admission into the
 * (bounded, FIFO) run queue picks per slot:
 *
 *   AGED TIER (deterministic): if any backlog actor has waited more
 *   than FPR_TAU admissions, the OLDEST such actor is admitted — no
 *   randomness, oldest-first. This tier alone carries the WCET bound:
 *   Wait(a) <= tau + (#earlier-stamped actors) * T_slot.
 *
 *   DEFAULT TIER (weighted random): otherwise a weighted reservoir
 *   pick over acb->weight, driven by a per-hart deterministic LCG.
 *   Randomness here decides only WHO runs among the un-aged — it
 *   shapes expected fairness and touches no worst case.
 *
 * Work stealing is DETERMINISTIC: a backlog past DONATE_HI donates its
 * oldest entries (stamps preserved) into a global FIFO under one lock
 * (same discipline as arc_lock); an idle hart pops the head — oldest
 * donated first, no victim scanning, no randomness. */

#ifndef FPR_TAU
#define FPR_TAU 64 /* aging threshold, in machine-wide admissions */
#endif
#ifndef RQ_CAP
#define RQ_CAP 4 /* run-queue admissions per refill batch */
#endif
#define DONATE_HI 4 /* backlog length that triggers donation */
#define SCAP 64     /* global steal FIFO capacity */

static uw g_tau = FPR_TAU;
static volatile uw g_adm;      /* machine-wide admission counter (the clock) */
static volatile uw g_max_wait; /* max observed backlog wait, in admissions */
static volatile uw g_steals;

static fpr_lock_t steal_lock;
static acb_t *steal_ring[SCAP];
static uw steal_h, steal_t;

static void backlog_add(fpr_hart_t *h, acb_t *a);

static void donate(fpr_hart_t *h) {
  /* publish our OLDEST UNPINNED entry; full ring = keep it local.
   * Pinned actors (actor 0, spawnOn placements) never migrate -- the
   * walk is bounded by the backlog, which donation itself keeps near
   * DONATE_HI. */
  acb_t *prev = 0, *a = h->bl_head;
  while (a && a->pin) { prev = a; a = a->bl_next; }
  if (!a) return;
  fpr_lock(&steal_lock);
  if (steal_t - steal_h < SCAP) {
    if (prev) prev->bl_next = a->bl_next;
    else h->bl_head = a->bl_next;
    if (h->bl_tail == a) h->bl_tail = prev;
    h->bl_len--;
    steal_ring[steal_t % SCAP] = a;
    steal_t++;
  }
  fpr_unlock(&steal_lock);
}

static acb_t *steal(fpr_hart_t *h) {
  acb_t *a = 0;
  fpr_lock(&steal_lock);
  if (steal_h != steal_t) {
    a = steal_ring[steal_h % SCAP];
    steal_h++;
  }
  fpr_unlock(&steal_lock);
  if (a) {
    a->hart = h->id; /* migrates; stamp is preserved (global clock) */
    g_steals++;
  }
  return a;
}

static void backlog_add(fpr_hart_t *h, acb_t *a) {
  a->bl_next = 0;
  a->ready_at = g_adm; /* stamped in admission time */
  if (!a->weight) a->weight = 1;
  if (h->bl_tail) h->bl_tail->bl_next = a;
  else h->bl_head = a;
  h->bl_tail = a;
  h->bl_len++;
  if (h->bl_len > DONATE_HI) donate(h);
}

/* one O(backlog) scan: unlink DEAD/BLOCKED, find the oldest aged actor,
 * and run the weighted reservoir over the rest in the same pass */
static acb_t *select_backlog(fpr_hart_t *h) {
  acb_t *prev = 0, *a = h->bl_head;
  acb_t *aged = 0, *aged_prev = 0;
  acb_t *pick = 0, *pick_prev = 0;
  uw total = 0;
  while (a) {
    acb_t *nx = a->bl_next;
    uint32_t st = __atomic_load_n(&a->var, __ATOMIC_ACQUIRE);
    if (st != ST_READY) {
      /* unlink; DEAD reaps, BLOCKED re-ships on its real wake */
      if (prev) prev->bl_next = nx; else h->bl_head = nx;
      if (h->bl_tail == a) h->bl_tail = prev;
      h->bl_len--;
      if (st == ST_DEAD) reap(a);
      a = nx;
      continue;
    }
    if (g_adm - a->ready_at > g_tau) {
      if (!aged || a->ready_at < aged->ready_at) { aged = a; aged_prev = prev; }
    }
    total += a->weight;
    h->lcg = h->lcg * 1103515245u + 12345u;
    if ((h->lcg >> 16) % total < a->weight) { pick = a; pick_prev = prev; }
    prev = a;
    a = nx;
  }
  acb_t *sel = aged ? aged : pick;
  acb_t *sp = aged ? aged_prev : pick_prev;
  if (sel) {
    if (sp) sp->bl_next = sel->bl_next; else h->bl_head = sel->bl_next;
    if (h->bl_tail == sel) h->bl_tail = sp;
    h->bl_len--;
  }
  return sel;
}

/* admit up to RQ_CAP backlog actors into the FIFO run queue */
static void refill(fpr_hart_t *h) {
  while (h->rq_len < RQ_CAP) {
    acb_t *a = select_backlog(h);
    if (!a) return;
    uw adm = __atomic_add_fetch(&g_adm, 1, __ATOMIC_RELAXED);
    uw wait = adm - a->ready_at;
    if (wait > g_max_wait) g_max_wait = wait;
    a->next = 0;
    if (h->rq_tail) h->rq_tail->next = a;
    else h->rq_head = a;
    h->rq_tail = a;
    h->rq_len++;
  }
}

static void enq(fpr_hart_t *h, acb_t *a) { backlog_add(h, a); }

static acb_t *deq(fpr_hart_t *h) {
  refill(h);
  while (h->rq_head) {
    acb_t *a = h->rq_head;
    h->rq_head = a->next;
    if (!h->rq_head) h->rq_tail = 0;
    h->rq_len--;
    uint32_t st = __atomic_load_n(&a->var, __ATOMIC_ACQUIRE);
    /* skip stale entries: DEAD forever; BLOCKED re-ships on real wake */
    if (st == ST_DEAD) reap(a); /* slab refactor: reclaim off its stack */
    if (st == ST_READY) return a;
  }
  return 0;
}

static void drain(fpr_hart_t *h) {
  for (uw s = 0; s < FPR_NHARTS; s++) {
    xring_t *x = &xr[s][h->id];
    uint32_t rt = __atomic_load_n(&x->rt, __ATOMIC_ACQUIRE);
    while (x->rh != rt) {
      acb_t *a = x->ring[x->rh % XCAP];
      __atomic_store_n(&x->rh, x->rh + 1, __ATOMIC_RELEASE);
      enq(h, a);
    }
  }
}

/* ship a runnable actor to its owner hart's queue */
static void ship(acb_t *a) {
  fpr_hart_t *h = fpr_hart();
  __atomic_fetch_add(&g_activity, 1, __ATOMIC_RELAXED);
  if (a->hart == h->id) {
    enq(h, a);
  } else {
    xpush(h->id, a->hart, a); /* publish the work... */
    hal_ipi_send(a->hart);    /* ...THEN raise msip (Dekker with the sleeper) */
  }
}

/* ---- the hart loop ----------------------------------------------------
 * Runs on the boot stack.  Every actor's block/yield/death switches back
 * here; picking the next actor switches out.  Hart 0 moonlights as the
 * deadlock detector. */
#define DETECT_TICKS 300000 /* 30 ms of CLINT time between detector samples */
#define DETECT_QUIET 8      /* consecutive silent samples before declaring */

/* process-loading (docs/PROCESS-LOADING.md): a dynamically loaded app
 * runs its OWN instance of this whole file (a separate compiled image,
 * fpr_process_entry.c calls fpr_hart_main directly instead of crt0
 * doing the machine-wide boot dance). Its actor-0 completion needs to
 * RETURN to the C caller (the loader) instead of halting the machine
 * -- fpr_exit does the latter, unconditionally, which would be wrong
 * here. fpr_is_process / fpr_process_done / fpr_process_result reuse
 * the EXISTING to_sched()/ctx_switch machinery (already exercised by
 * every block/yield/fuel-exhaustion path) rather than inventing a
 * second control-transfer mechanism: setting fpr_process_done just
 * makes hart_loop's normal loop condition fail, so it returns like any
 * other C function -- no extra ctx_switch, no unwinding trick needed.
 * Both flags are 0 forever for a normal machine boot: zero behavior
 * change there. */
volatile int fpr_is_process = 0;
volatile int fpr_process_done = 0;
static V fpr_process_result;

static void hart_loop(fpr_hart_t *h) {
  uw last_act = 0, stable = 0;
  h->lcg = h->id * 2654435761u + 12345u; /* decorrelated, deterministic */
  hal_wfi_enable(); /* mie on, mstatus.MIE off: wfi wakes, never traps */
  for (;;) {
    h->epoch++; /* the quiescence clock (see chblk above) */
    if (fpr_process_done) return; /* process mode: clean C return to the loader */
    if (__atomic_load_n(&fpr_shutdown, __ATOMIC_ACQUIRE))
      for (;;) hal_wfi();
    /* hot path first, NO MMIO: fuel preempts and local yields bounce
     * through here thousands of times a second */
    drain(h);
    acb_t *n = deq(h);
    if (!n) {
      /* nothing visible: arm the sleep protocol.  Clear our doorbell,
       * fence, and look AGAIN -- anything shipped after the clear
       * re-raises msip and the wfi below falls straight through. */
      hal_ipi_clear(h->id);
      __atomic_thread_fence(__ATOMIC_SEQ_CST);
      drain(h);
      n = deq(h);
    }
    if (n) {
      h->idle = 0;
      stable = 0;
      h->current = n;
      fpr_ctx_switch(h->sched_ctx, n->ctx);
      h->current = 0;
      /* body-return / kill marked it DEAD before switching back; we are
       * on the hart-loop stack now, so ITS stack is safe to reclaim */
      if (__atomic_load_n(&n->var, __ATOMIC_ACQUIRE) == ST_DEAD) reap(n);
      continue;
    }
    /* nothing local: deterministic steal — oldest donated work first */
    {
      acb_t *s = steal(h);
      if (s) { backlog_add(h, s); continue; }
    }
    h->idle = 1;
    if (h->id == 0) {
      /* deadlock detector, timer-paced: hart 0 wakes every DETECT_TICKS
       * even with no doorbell, samples the world, sleeps again.  A real
       * deadlock is (everyone idle) && (someone parked) && (the global
       * activity counter frozen) across DETECT_QUIET samples; any send
       * in flight keeps its hart non-idle or bumps the counter. */
      uw act = __atomic_load_n(&g_activity, __ATOMIC_RELAXED);
      uw blk = __atomic_load_n(&g_blocked, __ATOMIC_RELAXED);
      int all_idle = 1;
      for (uw i = 0; i < fpr_live_harts; i++)
        if (!fpr_harts[i].idle) all_idle = 0;
      if (all_idle && blk > 0 && act == last_act) {
        if (++stable > DETECT_QUIET)
          fpr_cpanic("actors: deadlock -- every hart idle, someone blocked, nothing moving");
      } else {
        stable = 0;
        last_act = act;
      }
      hal_timer_arm(0, DETECT_TICKS); /* re-arm clears MTIP until then */
    }
    hal_wfi(); /* sleeps unless msip/mtip is already pending again */
  }
}

/* switch from the current actor back to this hart's loop */
static void to_sched(void) {
  fpr_hart_t *h = fpr_hart();
  acb_t *p = h->current;
  fpr_ctx_switch(p->ctx, h->sched_ctx); /* returns when re-scheduled */
  fpr_hart()->fuel = FUEL_QUANTUM;      /* fresh slice on resume */
}

/* the compiler-inserted fuel check (0(tp) hit zero) lands here */
void fpr_fuel_exhausted(void) {
  fpr_hart_t *h = fpr_hart();
  h->fuel_preempts++;
  h->fuel = FUEL_QUANTUM;
  enq(h, h->current); /* still runnable: back of our own queue */
  to_sched();
}

/* first activation of a spawned actor lands here (fabricated ra) */
static void trampoline(void) {
  fpr_hart_t *h = fpr_hart();
  acb_t *a = h->current;
  h->fuel = FUEL_QUANTUM;
  if (a->entry == 0) {          /* actor 0: main itself */
    V r = fpr_fn_main();
    if (fpr_is_process) {       /* return to the loader, don't halt the machine */
      fpr_process_result = r;
      fpr_process_done = 1;
      to_sched();
      fpr_cpanic("actors: process resumed after its own exit");
    }
    fpr_exit(r);                /* normal boot: halts the machine */
  }
  fpr_apply(a->entry, (V)a);
  __atomic_store_n(&a->var, ST_DEAD, __ATOMIC_SEQ_CST);
  to_sched();
  fpr_cpanic("actors: dead actor resumed");
}

/* ---- channels --------------------------------------------------------- */

/* the target's channel for messages FROM a given sender; a free slot is
 * claimed by CAS on the sender field -- two first-time senders on
 * different harts race politely for slots.
 *
 * SLOT RECLAMATION (the slab-refactor companion fix): the key is the
 * sender's acb POINTER (acbs are immortal, so its status word is
 * always readable).  A slot whose sender is DEAD with a drained ring
 * (rh == rt) is claimable by CAS from the dead key -- without this,
 * every short-lived sender permanently consumed one of the receiver's
 * MAXSND slots, and a spawn/reply/die loop exhausted them at 8. */
static chan_t *chan_for(acb_t *a, uw skey, int create) {
  uw key = skey;
  for (;;) {
    chan_t *free_slot = 0;
    uw free_expect = 0;
    for (int i = 0; i < MAXSND; i++) {
      uw s = __atomic_load_n(&a->ch[i].sender, __ATOMIC_ACQUIRE);
      if (s == key) return &a->ch[i];
      if (!free_slot) {
        if (s == 0) { free_slot = &a->ch[i]; free_expect = 0; }
        else if (__atomic_load_n(&((acb_t *)s)->var, __ATOMIC_ACQUIRE) == ST_DEAD) {
          chan_t *c = &a->ch[i];
          uint32_t rt = __atomic_load_n(&c->rt, __ATOMIC_ACQUIRE);
          if (c->rh == rt) { free_slot = c; free_expect = s; } /* dead + drained */
        }
      }
    }
    if (!create) return 0;
    if (!free_slot) fpr_cpanic("send: too many distinct senders for this actor (MAXSND)");
    if (free_expect == 0) free_slot->rh = free_slot->rt = 0; /* fresh slot */
    /* a stolen slot keeps rh==rt where they stand: the CAS's acquire
     * side gives the new sender a coherent view of both counters */
    uw expect = free_expect;
    if (__atomic_compare_exchange_n(&free_slot->sender, &expect, key, 0,
                                    __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
      return free_slot;
    /* lost the race: rescan (our key may now exist, or steal elsewhere) */
  }
}

/* CAS BLOCKED -> READY; the winner ships the actor to its owner hart */
static void wake(acb_t *a) {
  uint32_t exp = ST_BLOCKED;
  if (__atomic_compare_exchange_n(&a->var, &exp, ST_READY, 0,
                                  __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST))
    ship(a);
}

/* park the current actor unless `pred(a, arg)` already holds.  The
 * seq_cst fence between the status store and the re-scan is the other
 * half of the Dekker pairing with a_send. */
typedef int (*pred_t)(acb_t *, uw);

static void block_unless(acb_t *a, pred_t pred, uw arg) {
  uint32_t exp = ST_READY;
  if (!__atomic_compare_exchange_n(&a->var, &exp, ST_BLOCKED, 0,
                                   __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST)) {
    to_sched(); /* killed under our feet: park forever (deq skips DEAD) */
    fpr_cpanic("actors: dead actor resumed");
  }
  __atomic_thread_fence(__ATOMIC_SEQ_CST);
  if (pred(a, arg)) { /* a message slid in while we were deciding */
    exp = ST_BLOCKED;
    __atomic_compare_exchange_n(&a->var, &exp, ST_READY, 0,
                                __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    return; /* whether we or a waker flipped it, we are READY */
  }
  __atomic_fetch_add(&g_blocked, 1, __ATOMIC_RELAXED);
  to_sched();
  __atomic_fetch_sub(&g_blocked, 1, __ATOMIC_RELAXED);
}

/* channel emptiness/content tests (consumer side: acquire on rt) */
static uint32_t ch_count(chan_t *c) {
  return __atomic_load_n(&c->rt, __ATOMIC_ACQUIRE) - c->rh;
}

static int p_any(acb_t *a, uw unused) {
  (void)unused;
  for (int i = 0; i < MAXSND; i++)
    if (a->ch[i].sender && ch_count(&a->ch[i])) return 1;
  return 0;
}

static int p_from(acb_t *a, uw sid) {
  chan_t *c = chan_for(a, sid, 0);
  return c && ch_count(c);
}

static int p_res(acb_t *a, uw unused) {
  (void)unused;
  for (int i = 0; i < MAXSND; i++) {
    chan_t *c = &a->ch[i];
    if (!c->sender) continue;
    uint32_t rt = __atomic_load_n(&c->rt, __ATOMIC_ACQUIRE);
    for (uint32_t k = c->rh; k != rt; k++) {
      V m = c->ring[k % RING_CAP];
      if (!ISINT(m) && TID(m) == T_RESULT) return 1;
    }
  }
  return 0;
}

/* remove the message at logical position k (rh <= k < rt), shifting the
 * head side down one -- all touched slots are consumer-owned (< rt). */
static V take_at(chan_t *c, uint32_t k) {
  V m = c->ring[k % RING_CAP];
  for (uint32_t j = k; j > c->rh; j--)
    c->ring[j % RING_CAP] = c->ring[(j - 1) % RING_CAP];
  __atomic_store_n(&c->rh, c->rh + 1, __ATOMIC_RELEASE); /* frees a slot */
  return m;
}

/* ---- boot: hart entry points (called from crt0) ----------------------- */

static acb_t main_acb; /* actor 0 */

void fpr_actors_init(void) { /* hart 0, before fpr_smp_go */
  for (uw i = 0; i < fpr_live_harts; i++) hal_timer_park(i);
  main_acb.tid = T_ACTOR;
  main_acb.var = ST_READY;
  main_acb.ch = chb_take();
  if (!main_acb.ch) fpr_cpanic("boot: no memory for actor 0's channels");
  main_acb.scan = 0;
  main_acb.entry = 0; /* trampoline runs fpr_fn_main + fpr_exit */
  main_acb.id = 0;
  main_acb.hart = 0;
  main_acb.pin = 1; /* the result carrier never migrates */
  main_acb.parent = 0;
  ledger_push(&main_acb);
  char *stk = (char *)stack_block();
  if (!stk) fpr_cpanic("boot: no block for actor 0's stack");
  main_acb.pool.cur = 0;
  main_acb.pool.bigfree = 0;
  main_acb.drop_pending = 0;
  main_acb.pool.allocated = 0;
  static void *main_bkts[FPR_NBUCKETS]; /* actor 0 lives forever */
  main_acb.pool.buckets = main_bkts;
  main_acb.stack = stk;
  for (int i = 0; i < 16; i++) main_acb.ctx[i] = 0;
  fpr_ctx_fabricate(main_acb.ctx, (void (*)(void))trampoline,
                    ((uw)stk + STACK_SZ) & ~(uw)15, &fpr_harts[0]);
  enq(&fpr_harts[0], &main_acb);
}

void fpr_hart_main(int id) { /* boot stack becomes the hart loop */
  hart_loop(&fpr_harts[id]);
}

void fpr_hart_secondary(int id) {
  fpr_set_tp(&fpr_harts[id]);
  fpr_rvv_enable(); /* mstatus.VS is per-hart */
  hart_loop(&fpr_harts[id]);
}

/* ---- FPRISC-facing API ------------------------------------------------ */

static V spawn_on(uw hart, V f, uw pin) {
  fpr_spawns++;
  if (hart >= fpr_live_harts) fpr_cpanic("spawnOn: no such hart (Sys.harts is the live count)");
  if (ISINT(f) || TID(f) != T_PAP) fpr_cpanic("spawn: argument must be a function");
  acb_t *a = (acb_t *)acb_block();
  char *stk = (char *)stack_block();
  if (!a || !stk) fpr_cpanic("spawn: buddy has no free block");
  a->pool.cur = 0;
  a->pool.bigfree = 0;
  a->drop_pending = 0;
  a->pool.allocated = 0;
  a->pool.buckets = fpr_bkt_take(); /* zeroed; teardown returns it */
  if (!a->pool.buckets) fpr_cpanic("spawn: no memory for a bucket array");
  f = fpr_msg_copy(f); /* the entry closure crosses like any message:
                        * deep-copied, so captures never dangle into
                        * the spawner's pool */
  fpr_arc_incref(f); /* pinned for the child's lifetime */
  a->tid = T_ACTOR;
  a->var = ST_READY;
  a->ch = chb_take(); /* cleared by chb_take */
  if (!a->ch) fpr_cpanic("spawn: no memory for a channel block");
  a->scan = 0;
  a->entry = f;
  a->next = 0;
  a->stack = stk;
  a->id = __atomic_add_fetch(&next_id, 1, __ATOMIC_RELAXED);
  a->hart = hart;
  a->pin = pin;
  {
    acb_t *cur = fpr_hart()->current;
    a->parent = cur ? cur->id : 0;
  }
  ledger_push(a);
  for (int i = 0; i < 16; i++) a->ctx[i] = 0;
  /* first-activation state is machine-specific (x86 needs a stack-
   * alignment bias; rv needs tp) -- the ctx layer owns fabrication */
  fpr_ctx_fabricate(a->ctx, (void (*)(void))trampoline,
                    ((uw)stk + STACK_SZ) & ~(uw)15, &fpr_harts[hart]);
  /* everything above happens-before the ship (ring release / same-hart
   * program order), so the owner hart sees a fully built acb */
  ship(a);
  return (V)a;
}

static V a_spawn(V f) { return spawn_on(fpr_hart()->id, f, 0); }
static V a_spawn_at(V hv, V f) {
  if (ISINT(hv) == 0) fpr_cpanic("spawnOn: hart must be an Int");
  return spawn_on((uw)UNTAG(hv), f, 1); /* explicit placement pins */
}

/* the send core, sender key EXPLICIT: a_send passes the current acb;
 * the SYSCALL TRAMPOLINE (process.c) passes its dormant reply mailbox
 * so a loaded process -- which lives in its own scheduler world -- can
 * still publish into System.qa's storage actor. */
V fpr_send_as(uw sender_key, V av, V m) {
  if (ISINT(av) || TID(av) != T_ACTOR) fpr_cpanic("send: target is not an actor");
  acb_t *a = (acb_t *)av;
  if (__atomic_load_n(&a->var, __ATOMIC_ACQUIRE) == ST_DEAD)
    return (V)&fpr_unit; /* silent no-op */
  chan_t *c = chan_for(a, sender_key, 1);
  /* single producer: our rt is private; check the consumer's rh */
  if (c->rt - __atomic_load_n(&c->rh, __ATOMIC_ACQUIRE) == RING_CAP)
    fpr_cpanic("send: per-sender channel full");
  m = fpr_msg_copy(m); /* DEEP COPY: the receiver gets a self-contained
                        * slab; nothing the sender does afterward can
                        * touch it, and drop-of-root frees all of it */
  fpr_arc_incref(m); /* promotion: heap values become shared on send */
  c->ring[c->rt % RING_CAP] = m;
  __atomic_store_n(&c->rt, c->rt + 1, __ATOMIC_RELEASE); /* publish */
  __atomic_thread_fence(__ATOMIC_SEQ_CST); /* Dekker: publish before flag read */
  wake(a);
  return (V)&fpr_unit;
}

static V a_send(V av, V m) {
  return fpr_send_as((uw)fpr_hart()->current, av, m);
}

/* ---- the SYSCALL MAILBOX (process.c's trampoline) -------------------
 * A dormant acb that is never scheduled: var is pinned ST_READY so a
 * sender's wake CAS(BLOCKED->READY) always fails -- replies are
 * PUBLISHED but nothing ever ships this acb to a run queue.  The
 * trampoline (not an actor; it runs on the process's stack) spin-scans
 * its channels for the next T_RESULT.  Single caller by construction:
 * one process slot, one synchronous syscall at a time. */
static acb_t syscall_mb;
void *fpr_syscall_mailbox(void) {
  if (syscall_mb.tid != T_ACTOR) {
    syscall_mb.tid = T_ACTOR;
    syscall_mb.var = ST_READY; /* pinned: wake CAS never matches */
    syscall_mb.hart = 0;
    static chblk_t syscall_chb; /* static: the mailbox never dies */
    syscall_mb.ch = syscall_chb.ch;
  }
  return &syscall_mb;
}

V fpr_syscall_wait_result(void) {
  acb_t *a = &syscall_mb;
  for (;;) {
    for (int i = 0; i < MAXSND; i++) {
      chan_t *c = &a->ch[i];
      if (!__atomic_load_n(&c->sender, __ATOMIC_ACQUIRE)) continue;
      uint32_t rt = __atomic_load_n(&c->rt, __ATOMIC_ACQUIRE);
      for (uint32_t k = c->rh; k != rt; k++) {
        V m = c->ring[k % RING_CAP];
        if (!ISINT(m) && TID(m) == T_RESULT) return take_at(c, k);
      }
    }
    __asm__ volatile("" ::: "memory"); /* spin; hart 1 serves storage */
  }
}

/* fair receive: round-robin over channels, FIFO within a channel */
static V a_receive(V me) {
  fpr_hart_t *h = fpr_hart();
  if (ISINT(me) || (acb_t *)me != h->current)
    fpr_cpanic("receive: not the current actor's handle");
  acb_t *a = h->current;
  drop_drain(a); /* the previous activation's borrows are dead here */
  for (;;) {
    for (int n = 0; n < MAXSND; n++) {
      chan_t *c = &a->ch[(a->scan + n) % MAXSND];
      if (c->sender && ch_count(c)) {
        a->scan = (a->scan + n + 1) % MAXSND;
        return take_at(c, c->rh);
      }
    }
    block_unless(a, p_any, 0);
  }
}

/* selective receive by SENDER: only that sender's channel, FIFO */
static V a_receive_from(V me, V fromv) {
  fpr_hart_t *h = fpr_hart();
  if (ISINT(me) || (acb_t *)me != h->current)
    fpr_cpanic("receiveFrom: not the current actor's handle");
  if (ISINT(fromv) || TID(fromv) != T_ACTOR)
    fpr_cpanic("receiveFrom: sender is not an actor");
  acb_t *a = h->current;
  drop_drain(a); /* the previous activation's borrows are dead here */
  uw sid = (uw)fromv; /* the key IS the sender's acb */
  for (;;) {
    chan_t *c = chan_for(a, sid, 0);
    if (c && ch_count(c)) return take_at(c, c->rh);
    block_unless(a, p_from, sid);
  }
}

/* selective receive by TYPE: next T_RESULT from any channel */
static V a_receive_res(V me) {
  fpr_hart_t *h = fpr_hart();
  if (ISINT(me) || (acb_t *)me != h->current)
    fpr_cpanic("receiveRes: not the current actor's handle");
  acb_t *a = h->current;
  drop_drain(a); /* the previous activation's borrows are dead here */
  for (;;) {
    for (int n = 0; n < MAXSND; n++) {
      chan_t *c = &a->ch[(a->scan + n) % MAXSND];
      if (!c->sender) continue;
      uint32_t rt = __atomic_load_n(&c->rt, __ATOMIC_ACQUIRE);
      for (uint32_t k = c->rh; k != rt; k++) {
        V m = c->ring[k % RING_CAP];
        if (!ISINT(m) && TID(m) == T_RESULT) return take_at(c, k);
      }
    }
    block_unless(a, p_res, 0);
  }
}

static V a_yield(V me) {
  fpr_hart_t *h = fpr_hart();
  if (ISINT(me) || (acb_t *)me != h->current)
    fpr_cpanic("yield: not the current actor's handle");
  enq(h, h->current);
  to_sched();
  return (V)&fpr_unit;
}

static V a_kill(V av) {
  if (ISINT(av) || TID(av) != T_ACTOR) fpr_cpanic("kill: target is not an actor");
  acb_t *a = (acb_t *)av;
  __atomic_store_n(&a->var, ST_DEAD, __ATOMIC_SEQ_CST);
  if (a == fpr_hart()->current) {
    to_sched(); /* never resumed: deq skips DEAD */
    fpr_cpanic("actors: dead actor resumed");
  }
  return (V)&fpr_unit;
}

static V a_myself(V dummy) {
  (void)dummy;
  return (V)fpr_hart()->current;
}

static V g_hart_id(V d) { (void)d; return TAG((sw)fpr_hart()->id); }
static V g_harts(V d) { (void)d; return TAG((sw)fpr_live_harts); }

/* scheduler introspection + tuning (docs/SCHED-MODEL.md) */
static V g_sched_tau(V d) { (void)d; return TAG((sw)g_tau); }
static V g_sched_set_tau(V n) { g_tau = (uw)UNTAG(n); return (V)&fpr_unit; }
static V g_sched_max_wait(V d) { (void)d; return TAG((sw)g_max_wait); }
static V g_sched_steals(V d) { (void)d; return TAG((sw)g_steals); }
static V g_sched_set_weight(V av, V w) {
  ((acb_t *)av)->weight = (uw)UNTAG(w) ? (uw)UNTAG(w) : 1;
  return (V)&fpr_unit;
}

/* fuel introspection, for /proc */
static V g_fuel_quantum(V d) { (void)d; return TAG(FUEL_QUANTUM); }
static V g_fuel_preempts(V d) {
  (void)d;
  uw t = 0;
  for (int i = 0; i < FPR_NHARTS; i++) t += fpr_harts[i].fuel_preempts;
  return TAG((sw)t);
}

/* ---- the discoverable-symbol table ------------------------------------ */
FPR_FN(fpr_g_spawn, a_spawn, 1);
FPR_FN(fpr_g_spawnOn, a_spawn_at, 2);
FPR_FN(fpr_g_send, a_send, 2);
FPR_FN(fpr_g_receive, a_receive, 1);
FPR_FN(fpr_g_receiveFrom, a_receive_from, 2);
FPR_FN(fpr_g_receiveRes, a_receive_res, 1);
FPR_FN(fpr_g_yield, a_yield, 1);
FPR_FN(fpr_g_kill, a_kill, 1);
FPR_FN(fpr_g_myself, a_myself, 1);
FPR_FN(fpr_g_hartId, g_hart_id, 1);
FPR_FN(fpr_g_schedTau, g_sched_tau, 1);
FPR_FN(fpr_g_schedSetTau, g_sched_set_tau, 1);
FPR_FN(fpr_g_schedMaxWait, g_sched_max_wait, 1);
FPR_FN(fpr_g_schedSteals, g_sched_steals, 1);
FPR_FN(fpr_g_schedSetWeight, g_sched_set_weight, 2);
FPR_FN(fpr_g_harts, g_harts, 1);
FPR_FN(fpr_g_fuelQuantum, g_fuel_quantum, 1);
FPR_FN(fpr_g_fuelPreempts, g_fuel_preempts, 1);

/* debug: which actor is panicking (called from fpr_cpanic) */
uw fpr_current_id(void) {
  fpr_hart_t *h = fpr_hart();
  return h && h->current ? h->current->id : 900 + (h ? h->id : 99);
}

V fpr_process_result_get(void) { return fpr_process_result; }


/* ---- introspection: the monitor's window ----------------------------
 * Sys.actLive ()      -> live (non-DEAD) actor count
 * Sys.actInfo i       -> the i-th live actor (ledger order = newest
 *                        first) as [id, status, parent, code]:
 *                        status 0 ready / 1 blocked; parent = the
 *                        spawner's id; code = the entry closure's
 *                        function address, which is ATTRIBUTION: an
 *                        address inside a plugin sub-slot names the
 *                        app that owns the actor.  Out of range -> [].
 * The ledger is append-only over immortal acbs, so walking it is
 * always safe; counts are a snapshot, racing spawns tolerated. */
static V mklist4(uw a, uw b, uw c, uw d) {
  hdr_t *nil = (hdr_t *)fpr_alloc(8);
  nil->tid = T_LIST;
  nil->var = 0;
  V list = (V)nil;
  uw vals[4] = {d, c, b, a};
  for (int i = 0; i < 4; i++) {
    V *cell = (V *)fpr_alloc(24);
    ((hdr_t *)cell)->tid = T_LIST;
    ((hdr_t *)cell)->var = 1;
    cell[1] = TAG((sw)vals[i]);
    cell[2] = list;
    list = (V)cell;
  }
  return list;
}

/* Sys.stkStats () -> [spawns, stackPushes, stackMisses, chbCarves]:
 * the pool ledger, PULL-based -- reading a counter is the only safe
 * telemetry an allocation path gets (see the growlog lesson above) */
static V g_stkStats(V u) {
  (void)u;
  return mklist4(fpr_spawns, fpr_stk_pushes, fpr_stk_misses, fpr_chb_carves);
}
FPR_FN(fpr_g_Sys_x2estkStats, g_stkStats, 1);

static V g_actLive(V u) {
  (void)u;
  uw n = 0;
  for (acb_t *a = __atomic_load_n(&g_all, __ATOMIC_ACQUIRE); a; a = a->all_nx)
    if (__atomic_load_n(&a->var, __ATOMIC_ACQUIRE) != ST_DEAD) n++;
  return TAG((sw)n);
}

static V g_actInfo(V iv) {
  sw want = UNTAG(iv);
  for (acb_t *a = __atomic_load_n(&g_all, __ATOMIC_ACQUIRE); a; a = a->all_nx) {
    uint32_t st = __atomic_load_n(&a->var, __ATOMIC_ACQUIRE);
    if (st == ST_DEAD) continue;
    if (want-- == 0) {
      uw code = 0;
      if (a->entry && !ISINT(a->entry)) code = ((uw *)a->entry)[1];
      return mklist4(a->id, st == ST_BLOCKED ? 1 : 0, a->parent, code);
    }
  }
  hdr_t *nil = (hdr_t *)fpr_alloc(8);
  nil->tid = T_LIST;
  nil->var = 0;
  return (V)nil;
}
FPR_FN(fpr_g_Sys_x2eactLive, g_actLive, 1);
FPR_FN(fpr_g_Sys_x2eactInfo, g_actInfo, 1);
