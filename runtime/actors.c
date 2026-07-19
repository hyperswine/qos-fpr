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
  chan_t ch[MAXSND];
  uint32_t scan; /* round-robin cursor for fair receive (owner-only) */
  V entry;       /* PAP to run: body = entry(self); 0 for main */
  struct fpr_acb *next; /* run-queue link (owner hart only) */
  char *stack;
  uw id;
  uw hart;         /* pinned owner hart */
  fpr_pool_t pool; /* this actor's slabs + recycle buckets (slab refactor) */
} acb_t;

fpr_pool_t *fpr_acb_pool(struct fpr_acb *a) { return &a->pool; }

/* big raw blocks (stacks, acbs): buddy on a machine boot; inside a
 * loaded process, a grant from the loader (the process has no buddy).
 * Process-mode blocks are reclaimed wholesale at process exit. */
static void *big_block(uw n) {
  if (!fpr_is_process) return buddy_alloc(n);
  fpr_grant_t g = fpr_grow_memory ? fpr_grow_memory(n) : (fpr_grant_t){0, 0};
  return (g.ptr && g.size >= n) ? g.ptr : 0;
}

/* death reclamation (called from the hart loop, NEVER on the dying
 * actor's own stack): slabs via the ARC-locked teardown, stack -- which
 * cannot escape -- straight back to buddy.  Idempotent via stack=0. */
static void reap(acb_t *a) {
  if (!a->stack) return;
  fpr_pool_reclaim(a);
  if (!fpr_is_process) buddy_free(a->stack); /* process blocks: freed with the slot */
  a->stack = 0;
  if (a->entry) { fpr_arc_decref(a->entry); a->entry = 0; } /* unpin the closure */
  /* the acb itself stays: it IS the actor value other actors hold
   * (send-to-dead reads a->var).  ~sizeof(acb_t) per actor, stated. */
}

extern void fpr_ctx_switch(uw *save, uw *load);
extern V fpr_fn_main(void);
extern void fpr_exit(V result);
extern void fpr_set_tp(fpr_hart_t *h);
extern volatile uint32_t fpr_shutdown;
void fpr_rvv_enable(void) __attribute__((weak)); /* mstatus.VS is per-hart */

/* hal.c: CLINT-based sleep/wake (see the wfi essay there) */
void hal_ipi_send(uw hart);
void hal_ipi_clear(uw hart);
void hal_timer_park(uw hart);
void hal_timer_arm(uw hart, uint64_t delta);
void hal_wfi_enable(void);
void hal_wfi(void);

/* ---- shared counters (the deadlock detector's whole world) ----------- */
static uw next_id;                 /* atomic fetch_add */
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

/* ---- per-hart run queue (owner-only, no atomics) ---------------------- */
static void enq(fpr_hart_t *h, acb_t *a) {
  a->next = 0;
  if (h->rq_tail) h->rq_tail->next = a;
  else h->rq_head = a;
  h->rq_tail = a;
}

static acb_t *deq(fpr_hart_t *h) {
  while (h->rq_head) {
    acb_t *a = h->rq_head;
    h->rq_head = a->next;
    if (!h->rq_head) h->rq_tail = 0;
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
  hal_wfi_enable(); /* mie on, mstatus.MIE off: wfi wakes, never traps */
  for (;;) {
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
      for (int i = 0; i < FPR_NHARTS; i++)
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
  for (int i = 0; i < FPR_NHARTS; i++) hal_timer_park((uw)i);
  main_acb.tid = T_ACTOR;
  main_acb.var = ST_READY;
  for (int i = 0; i < MAXSND; i++) main_acb.ch[i].sender = 0;
  main_acb.scan = 0;
  main_acb.entry = 0; /* trampoline runs fpr_fn_main + fpr_exit */
  main_acb.id = 0;
  main_acb.hart = 0;
  char *stk = (char *)big_block(STACK_SZ);
  if (!stk) fpr_cpanic("boot: no block for actor 0's stack");
  main_acb.pool.cur = 0;
  main_acb.pool.allocated = 0;
  for (int i = 0; i < FPR_NBUCKETS; i++) main_acb.pool.buckets[i] = 0;
  main_acb.stack = stk;
  for (int i = 0; i < 16; i++) main_acb.ctx[i] = 0;
  main_acb.ctx[0] = (uw)(uintptr_t)trampoline;
  main_acb.ctx[1] = ((uw)stk + STACK_SZ) & ~(uw)15;
  main_acb.ctx[3] = (uw)&fpr_harts[0]; /* tp */
  enq(&fpr_harts[0], &main_acb);
}

void fpr_hart_main(int id) { /* boot stack becomes the hart loop */
  hart_loop(&fpr_harts[id]);
}

void fpr_hart_secondary(int id) {
  fpr_set_tp(&fpr_harts[id]);
  if (fpr_rvv_enable) fpr_rvv_enable(); /* mstatus.VS is per-hart */
  hart_loop(&fpr_harts[id]);
}

/* ---- FPRISC-facing API ------------------------------------------------ */

static V spawn_on(uw hart, V f) {
  if (hart >= FPR_NHARTS) fpr_cpanic("spawnOn: no such hart (raise HARTS= at build time)");
  if (ISINT(f) || TID(f) != T_PAP) fpr_cpanic("spawn: argument must be a function");
  acb_t *a = (acb_t *)big_block(sizeof(acb_t));
  char *stk = (char *)big_block(STACK_SZ);
  if (!a || !stk) fpr_cpanic("spawn: buddy has no free block");
  a->pool.cur = 0;
  a->pool.allocated = 0;
  for (int i = 0; i < FPR_NBUCKETS; i++) a->pool.buckets[i] = 0;
  fpr_arc_incref(f); /* the entry closure escapes into the child: pin it */
  a->tid = T_ACTOR;
  a->var = ST_READY;
  for (int i = 0; i < MAXSND; i++) a->ch[i].sender = 0;
  a->scan = 0;
  a->entry = f;
  a->next = 0;
  a->stack = stk;
  a->id = __atomic_add_fetch(&next_id, 1, __ATOMIC_RELAXED);
  a->hart = hart;
  for (int i = 0; i < 16; i++) a->ctx[i] = 0;
  a->ctx[0] = (uw)(uintptr_t)trampoline;
  a->ctx[1] = ((uw)stk + STACK_SZ) & ~(uw)15;
  a->ctx[3] = (uw)&fpr_harts[hart]; /* tp = the OWNER hart's block */
  /* everything above happens-before the ship (ring release / same-hart
   * program order), so the owner hart sees a fully built acb */
  ship(a);
  return (V)a;
}

static V a_spawn(V f) { return spawn_on(fpr_hart()->id, f); }
static V a_spawn_at(V hv, V f) {
  if (ISINT(hv) == 0) fpr_cpanic("spawnOn: hart must be an Int");
  return spawn_on((uw)UNTAG(hv), f);
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
    for (int i = 0; i < MAXSND; i++) syscall_mb.ch[i].sender = 0;
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
static V g_harts(V d) { (void)d; return TAG(FPR_NHARTS); }

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
FPR_FN(fpr_g_harts, g_harts, 1);
FPR_FN(fpr_g_fuelQuantum, g_fuel_quantum, 1);
FPR_FN(fpr_g_fuelPreempts, g_fuel_preempts, 1);

/* debug: which actor is panicking (called from fpr_cpanic) */
uw fpr_current_id(void) {
  fpr_hart_t *h = fpr_hart();
  return h && h->current ? h->current->id : 900 + (h ? h->id : 99);
}

V fpr_process_result_get(void) { return fpr_process_result; }
