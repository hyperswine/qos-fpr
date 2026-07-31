/* runtime.c — allocator, generic apply, core prims, panic.
 *
 * The core prims here are exactly the names the DESUGARER can emit
 * (operators, str/strcat from interpolation, error). Everything else a
 * program references is deliberately NOT here: it arrives as a fpr_g_*
 * extern that hal.c (or any other module) satisfies at link time.
 */
#include "fpr.h"

const hdr_t fpr_true = {T_BOOL, 1};
const hdr_t fpr_false = {T_BOOL, 0};
const hdr_t fpr_unit = {T_UNIT, 0};

/* ---- allocator v2: bump + size header + segregated free list ---------
 * Every allocation carries its total size in a hidden 16-byte header
 * (16 to preserve alignment), which is what makes fpr_free -- and
 * therefore ARC reclamation -- possible at all. Freed blocks go into
 * exact-fit free lists by size class (16..4096 bytes, 16-byte step);
 * larger blocks (actor stacks) leak by design in this PoC. */
extern char _heap_start[], _heap_end[];

/* per-hart control blocks; tp points at ours (see fpr.h essay) */
fpr_hart_t fpr_harts[FPR_NHARTS];

/* process-loading growth hook; NULL for a normal machine boot */
fpr_grant_t (*fpr_grow_memory)(uw want_bytes) = 0;

/* the SMP release flag secondaries spin on.  Lives in .data (explicit
 * section + volatile) so it is 0 straight from the ELF image -- a
 * secondary that reaches its spin loop before hart 0 clears bss reads
 * a real 0, not garbage. */
#ifdef __APPLE__
__attribute__((section("__DATA,__data"))) volatile uint32_t fpr_smp_go = 0;
#else
__attribute__((section(".data"))) volatile uint32_t fpr_smp_go = 0;
#endif

void fpr_actors_init(void);       /* actors.c: global (hart 0, pre-release) */
void fpr_hart_main(int id);       /* actors.c: the hart loop */
void fpr_hart_secondary(int id);  /* actors.c: tp setup + hart loop */

/* emitted by fprc only under --rvv (sets mstatus.VS).  Weak no-op
 * default here so images built without --rvv link and never touch the
 * CSR: a --rvv unit's own (strong) definition from the generated
 * assembly overrides this one via ordinary weak/strong symbol
 * coalescing (true on both ELF and Mach-O; plain `extern ... weak`
 * with NO definition anywhere is what Apple's ld refuses to leave
 * unresolved). mstatus is PER-HART: every hart's init calls it. */
__attribute__((weak)) void fpr_rvv_enable(void) {}

static void hart_init(int id) {
  fpr_hart_t *h = &fpr_harts[id];
  h->id = (uw)id;
  h->pool.cur = 0;
  h->pool.allocated = 0;
  for (int i = 0; i < FPR_NBUCKETS; i++) h->pool.buckets[i] = 0;
  h->current = 0;
  h->rq_head = h->rq_tail = 0;
  h->idle = 0;
  h->fuel_preempts = 0;
  h->rpos = 0;
}

#ifdef FPR_POSIX
void fpr_set_tp(fpr_hart_t *h) { fpr_posix_hart = h; }
#else
void fpr_set_tp(fpr_hart_t *h) { __asm__ volatile("mv tp, %0" ::"r"(h)); }
#endif

void fpr_rt_init(void) {
  for (int i = 0; i < FPR_NHARTS; i++) hart_init(i);
  /* buddy over heap + process regions TOGETHER: the ONE lower
   * allocator (per-actor slabs, stacks, acbs, and process slots all
   * come from here).  Init before actors: actor 0's stack is a buddy
   * block.  Skipped when running AS a loaded process -- a process's
   * heap is the grant its loader handed it, not this machine's RAM. */
  if (!fpr_is_process) {
    /* buddy over the heap region: slabs, stacks, acbs, growth grants.
     * The process SLOT is not allocated at all -- images are LINKED at
     * _proc_arena_start, so that fixed range is the slot by identity
     * (one concurrent slot, per the stated design). */
#ifdef FPR_BUDDY_MIN
    uw minb = (uw)FPR_BUDDY_MIN;
#else
    uw minb = 64u * 1024;
#endif
    uw base = ((uw)_heap_start + (minb - 1)) & ~(uw)(minb - 1);
    buddy_init((void *)base, (uw)_heap_end - base);
  }
  fpr_set_tp(&fpr_harts[0]);
  fpr_rvv_enable();
  fpr_actors_init();
  /* everything above happens-before any secondary's first instruction */
  __atomic_store_n(&fpr_smp_go, 1, __ATOMIC_RELEASE);
}

int fpr_in_heap(V v) { /* the buddy span: heap + process regions */
  return !ISINT(v) && (char *)v >= _heap_start && (char *)v < _proc_arena_end;
}

/* ---- the slab allocator (see the fpr.h essay) ----------------------- */
#ifndef FPR_SLAB_SZ
#define FPR_SLAB_SZ ((uw)256 * 1024)
#endif
#define SLAB_SZ FPR_SLAB_SZ

static fpr_pool_t *cur_pool(fpr_hart_t *h) {
  return h->current ? fpr_acb_pool(h->current) : &h->pool;
}

/* pop from this pool's bucket: the bucket head is CAS-pushed by any
 * hart (cross-actor drop-to-zero), so the owner drains by atomic
 * exchange -- ABA-free, and everything taken is exclusively ours. */
static void *bucket_take(fpr_pool_t *pool, uw idx) {
  void *head = __atomic_exchange_n(&pool->buckets[idx], (void *)0, __ATOMIC_ACQUIRE);
  if (!head) return 0;
  void *rest = *(void **)head;
  /* re-push the remainder (we own it; pushers only touch the head) */
  while (rest) {
    void *nx = *(void **)rest;
    void *old;
    do {
      old = __atomic_load_n(&pool->buckets[idx], __ATOMIC_RELAXED);
      *(void **)rest = old;
    } while (!__atomic_compare_exchange_n(&pool->buckets[idx], &old, rest, 0,
                                          __ATOMIC_RELEASE, __ATOMIC_RELAXED));
    rest = nx;
  }
  return head;
}

V fpr_alloc(V raw_bytes) {
  fpr_hart_t *h = fpr_hart();
  fpr_pool_t *pool = cur_pool(h);
  uw total = (((raw_bytes + 15) & ~(uw)15)) + 16;
  if (total <= (uw)16 * FPR_NBUCKETS) {
    uw idx = total / 16 - 1;
    void *p = bucket_take(pool, idx);
    if (p) {
      *(uw *)p = total; /* [1] (the slab ptr) survived recycling */
      return (V)((char *)p + 16);
    }
  }
  fpr_slab_t *sl = pool->cur;
  if (!sl || sl->hp + total > sl->end) {
    /* a loaded process grows through its loader's grant, exactly as
     * before -- its "slab" is whatever System.qa's buddy handed over */
    if (fpr_is_process && fpr_grow_memory) {
      uw want = total + sizeof(fpr_slab_t);
      if (want < SLAB_SZ) want = SLAB_SZ;
      fpr_grant_t g = fpr_grow_memory(want);
      if (!g.ptr || g.size < total + sizeof(fpr_slab_t))
        fpr_cpanic("heap exhausted (process arena growth denied)");
      sl = (fpr_slab_t *)g.ptr;
      sl->end = (char *)g.ptr + g.size;
    } else {
      uw want = total + sizeof(fpr_slab_t);
      if (want < SLAB_SZ) want = SLAB_SZ;
      sl = (fpr_slab_t *)buddy_alloc(want);
      if (!sl) fpr_cpanic("heap exhausted (buddy has no free block)");
      sl->end = (char *)sl + buddy_block_usable_size(sl);
    }
    sl->owner = pool;
    sl->escaped = 0;
    sl->hp = (char *)(sl + 1);
    sl->next = pool->cur;
    pool->cur = sl;
  }
  char *p = sl->hp;
  sl->hp += total;
  pool->allocated += total;
  *(uw *)p = total;
  *(fpr_slab_t **)(p + 8) = sl;
  return (V)(p + 16);
}

/* called ONLY from the ARC drop path, under arc_lock -- which is what
 * makes reading slab->owner race-free against death teardown (also
 * under arc_lock).  An orphaned slab's blocks are not recycled: the
 * whole slab goes back to buddy when its last promoted object drops. */
void fpr_free(V v) {
  char *p = (char *)v - 16;
  uw total = *(uw *)p;
  fpr_slab_t *sl = *(fpr_slab_t **)(p + 8);
  if (total == 0 || total > (uw)16 * FPR_NBUCKETS) return; /* huge or corrupt: stays in slab */
  if (!sl || !sl->owner) return;
  fpr_pool_t *pool = sl->owner;
  uw idx = total / 16 - 1;
  *(uw *)p = 0; /* poison size: crude double-free tripwire */
  void *old;
  do {
    old = __atomic_load_n(&pool->buckets[idx], __ATOMIC_RELAXED);
    *(void **)p = old;
  } while (!__atomic_compare_exchange_n(&pool->buckets[idx], &old, p, 0,
                                        __ATOMIC_RELEASE, __ATOMIC_RELAXED));
}

/* death teardown (hart loop, after the switch OFF the actor's stack):
 * slabs with no escaped objects return to buddy now; the rest are
 * orphaned and return when their last promoted object is dropped.
 * The stack never escapes: always reclaimed. */
void fpr_arc_teardown_pool(fpr_pool_t *pool); /* below, with the ARC state */
void fpr_pool_reclaim(struct fpr_acb *a) {
  fpr_arc_teardown_pool(fpr_acb_pool(a));
}

/* ---- ARC: cross-actor sharing accounts ------------------------------
 * The rule from the design discussion: basic values (tagged ints) cross
 * actor boundaries by value; anything heap-allocated gets PROMOTED on
 * send -- an entry in the ARC table, count = number of cross-actor
 * shares. Static objects (rodata strings, prim PAPs, devices) are
 * immortal and skip the table via the heap-range check. `drop` decrefs;
 * at zero the object is returned to the free list. Reclamation is
 * SHALLOW: fields are not traversed (objects don't carry field counts
 * -- an ABI v2 with a 16-byte header would fix that, same change deep
 * equality wants). In the real compiler the RC-insertion pass emits
 * these drops; here the demo program does it by hand to show the
 * protocol working. */
#define ARC_CAP 1024
#define ARC_TOMB ((V)1)
static struct { V ptr; uw cnt; } arct[ARC_CAP];
static uw arc_live;

/* probe for v; on miss, the returned slot is the best insertion point
 * (first tombstone seen, else the empty that ended the probe) --
 * without tombstone reuse, heavy promote/drop cycling fills the table
 * with tombstones and kills it (found the hard way: a 100k-hop token
 * ring paniced "ARC table full" at ~1k cycles). */
static uw arc_probe(V v, int *found) {
  uw i = ((v >> 4) * (uw)2654435761UL) & (ARC_CAP - 1);
  uw first_tomb = ARC_CAP;
  for (uw n = 0; n < ARC_CAP; n++) {
    V p = arct[i].ptr;
    if (p == v) { *found = 1; return i; }
    if (p == 0) { *found = 0; return first_tomb != ARC_CAP ? first_tomb : i; }
    if (p == ARC_TOMB && first_tomb == ARC_CAP) first_tomb = i;
    i = (i + 1) & (ARC_CAP - 1);
  }
  *found = 0;
  if (first_tomb != ARC_CAP) return first_tomb;
  fpr_cpanic("ARC table full");
}

/* one lock for the whole table: promotion happens on SEND, which is
 * rare next to computation -- contention is negligible and the SPSC
 * story stays clean (the table is the ONLY shared-mutable structure
 * in the runtime that is not a single-producer ring). */
static fpr_lock_t arc_lock;

static fpr_slab_t *slab_of(V v) { return *(fpr_slab_t **)((char *)v - 8); }

void fpr_arc_incref(V v) {
  if (!fpr_in_heap(v)) return; /* ints + immortal statics: by value */
  fpr_lock(&arc_lock);
  int found;
  uw i = arc_probe(v, &found);
  if (!found) {
    arct[i].ptr = v;
    arct[i].cnt = 0;
    arc_live++;
    /* first promotion: this object now pins its slab (escape count) */
    fpr_slab_t *sl = slab_of(v);
    if (sl) sl->escaped++;
  }
  arct[i].cnt++;
  fpr_unlock(&arc_lock);
}

void fpr_arc_decref(V v) {
  if (!fpr_in_heap(v)) return;
  fpr_lock(&arc_lock);
  int found;
  uw i = arc_probe(v, &found);
  if (!found) { fpr_unlock(&arc_lock); return; } /* never shared: no-op */
  int dead = (--arct[i].cnt == 0);
  if (dead) {
    arct[i].ptr = ARC_TOMB; /* tombstone keeps probe chains intact */
    arc_live--;
    fpr_slab_t *sl = slab_of(v);
    if (sl) {
      sl->escaped--;
      if (!sl->owner && sl->escaped == 0 && !fpr_is_process) {
        /* last escapee of an orphaned slab: the whole slab goes home */
        buddy_free(sl);
      } else {
        fpr_free(v); /* under arc_lock: owner read is death-race-free */
      }
    }
  }
  fpr_unlock(&arc_lock);
}

/* death teardown, under the same lock that guards owner/escaped:
 * escape-free slabs return to buddy; the rest are orphaned. */
void fpr_arc_teardown_pool(fpr_pool_t *pool) {
  fpr_lock(&arc_lock);
  if (fpr_is_process) { /* grant-backed slabs: freed with the slot at exit */
    pool->cur = 0;
    for (int i = 0; i < FPR_NBUCKETS; i++) pool->buckets[i] = 0;
    fpr_unlock(&arc_lock);
    return;
  }
  fpr_slab_t *sl = pool->cur;
  while (sl) {
    fpr_slab_t *nx = sl->next;
    if (sl->escaped == 0) buddy_free(sl);
    else sl->owner = 0; /* orphan: freed at last drop above */
    sl = nx;
  }
  pool->cur = 0;
  for (int i = 0; i < FPR_NBUCKETS; i++) pool->buckets[i] = 0;
  fpr_unlock(&arc_lock);
}

uw fpr_arc_live(void) { return arc_live; }

/* the CURRENT ACTOR's allocation gauge: bytes it has ever bumped from
 * its slabs (recycled-bucket hits do not re-count).  The per-hart
 * high-water mark died with the arenas; "what has THIS actor cost"
 * is the question the slab model can actually answer. */
static V g_heapUsed(V d) {
  (void)d;
  fpr_hart_t *h = fpr_hart();
  fpr_pool_t *pool = h->current ? fpr_acb_pool(h->current) : &h->pool;
  return TAG((sw)pool->allocated);
}

static V g_drop(V v) { fpr_arc_decref(v); return (V)&fpr_unit; }

/* substr s off len -- 1-indexed byte slice, clamped. Mechanism, not
 * policy: diskfs chunks payloads into pages (write) and takes the used
 * prefix of a page (read) with this; doing it via chr+strcat would be
 * one allocation PER BYTE of every page moved. */
static V g_substr(V sv, V off, V len) {
  if (ISINT(sv) || TID(sv) != T_STR) fpr_cpanic("substr: not a String");
  str_t *s = (str_t *)sv;
  sw o = UNTAG(off), l = UNTAG(len);
  if (o < 1) o = 1;
  if (l < 0) l = 0;
  if ((uw)(o - 1) >= s->len) { o = 1; l = 0; }
  if ((uw)l > s->len - (uw)(o - 1)) l = (sw)(s->len - (uw)(o - 1));
  return (V)fpr_mkstr(s->bytes + (o - 1), (uw)l);
}
static V g_arcLive(V d) { (void)d; return TAG(fpr_arc_live()); }

/* ---- panic ---------------------------------------------------------- */
static void praw(const char *s) {
  while (*s) {
    if (*s == '\n') hal_putc('\r');
    hal_putc(*s++);
  }
}

extern uw fpr_current_id(void);
static void pdec(uw u) {
  char b[24]; int i = 23;
  if (u == 0) b[i--] = '0';
  while (u) { b[i--] = '0' + (u % 10); u /= 10; }
  for (int j = i + 1; j <= 23; j++) hal_putc(b[j]);
}
void fpr_cpanic(const char *m) {
  praw("\n*** FPRISC PANIC [actor ");
  pdec(fpr_current_id());
  praw("]: ");
  praw(m);
  praw(" ***\n");
  hal_poweroff(1); /* QEMU: exit 1; real HW: no-op, park below */
  for (;;) FPR_PARK();
}

void fpr_panic(V s) {
  praw("\n*** FPRISC PANIC [actor ");
  pdec(fpr_current_id());
  praw("]: ");
  if (!ISINT(s) && TID(s) == T_STR) {
    str_t *t = (str_t *)s;
    for (uw i = 0; i < t->len; i++) hal_putc((char)t->bytes[i]);
  }
  praw(" ***\n");
  hal_poweroff(1); /* QEMU: exit 1; real HW: no-op, park below */
  for (;;) FPR_PARK();
}

volatile uint32_t fpr_shutdown; /* hart loops park when set */

void fpr_exit(V result) {
  extern void fpr_render_to_uart(V v); /* below */
  __atomic_store_n(&fpr_shutdown, 1, __ATOMIC_RELEASE);
  praw("\n[fpr] main => ");
  fpr_render_to_uart(result);
  praw("\n");
  hal_poweroff(0); /* QEMU: clean exit 0; real HW: no-op, park below */
  for (;;) FPR_PARK();
}

/* ---- generic apply --------------------------------------------------- */
/* A function value is a PAP: code addr + arity + args collected so far.
 * Saturation calls through an arity-dispatched cast; otherwise we copy
 * the PAP with one more arg (PAPs are immutable -- statics get shared). */
typedef V (*F1)(V);
typedef V (*F2)(V, V);
typedef V (*F3)(V, V, V);
typedef V (*F4)(V, V, V, V);
typedef V (*F5)(V, V, V, V, V);
typedef V (*F6)(V, V, V, V, V, V);
typedef V (*F7)(V, V, V, V, V, V, V);
typedef V (*F8)(V, V, V, V, V, V, V, V);

static V callf(uw fn, uw ar, V *a) {
  switch (ar) {
    case 1: return ((F1)fn)(a[0]);
    case 2: return ((F2)fn)(a[0], a[1]);
    case 3: return ((F3)fn)(a[0], a[1], a[2]);
    case 4: return ((F4)fn)(a[0], a[1], a[2], a[3]);
    case 5: return ((F5)fn)(a[0], a[1], a[2], a[3], a[4]);
    case 6: return ((F6)fn)(a[0], a[1], a[2], a[3], a[4], a[5]);
#if defined(FPR_POSIX) && defined(__x86_64__)
    /* x64 lowering convention: args 7/8 travel in TLS cells, not SysV
     * stack slots -- that keeps generated tail calls to arity-7/8
     * functions plain jmps (TCO intact).  This C boundary fills the
     * cells and calls through the 6-register cast; the lowered callee
     * reads the cells in its prologue (see compiler/X64.hs). */
    case 7: {
      extern FPR_TLS uw fpr_x64_a6;
      fpr_x64_a6 = (uw)a[6];
      return ((F6)fn)(a[0], a[1], a[2], a[3], a[4], a[5]);
    }
    case 8: {
      extern FPR_TLS uw fpr_x64_a6, fpr_x64_a7;
      fpr_x64_a6 = (uw)a[6];
      fpr_x64_a7 = (uw)a[7];
      return ((F6)fn)(a[0], a[1], a[2], a[3], a[4], a[5]);
    }
#else
    case 7: return ((F7)fn)(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
    case 8: return ((F8)fn)(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]);
#endif
  }
  fpr_cpanic("apply: arity > 8");
}

V fpr_apply(V f, V a) {
  if (ISINT(f)) fpr_cpanic("apply: applied an integer");
  pap_t *p = (pap_t *)f;
  if (p->tid != T_PAP) fpr_cpanic("apply: not a function value");
  uw n = p->nargs;
  if (n + 1 == p->arity) {
    V args[8];
    for (uw i = 0; i < n; i++) args[i] = p->args[i];
    args[n] = a;
    return callf(p->fn, p->arity, args);
  }
  pap_t *q = (pap_t *)fpr_alloc(sizeof(pap_t) + p->arity * 8);
  q->tid = T_PAP;
  q->var = 0;
  q->fn = p->fn;
  q->arity = p->arity;
  q->nargs = n + 1;
  for (uw i = 0; i < n; i++) q->args[i] = p->args[i];
  q->args[n] = a;
  return (V)q;
}

/* whole-spine application: rargs points at the LAST argument, with each
 * argument 16 bytes apart going UP (the codegen push discipline).
 * Saturating allocates nothing; under-saturation builds exactly ONE
 * pap; over-saturation loops.  This is why a tight FPRISC loop over
 * 2-ary HAL prims (charAt in strEq in hasCap in svcPollKey) allocates
 * zero bytes instead of a 48-byte PAP per argument. */
V fpr_applyN(V f, uw n, V *rargs) {
#define RARG(i) (rargs[(16 / sizeof(uw)) * (n - 1 - (i))]) /* 16-byte push stride */
  for (;;) {
    if (ISINT(f)) fpr_cpanic("apply: applied an integer");
    pap_t *p = (pap_t *)f;
    if (p->tid != T_PAP) fpr_cpanic("apply: not a function value");
    uw have = p->nargs, need = p->arity - have;
    if (n < need) { /* still partial: ONE pap with everything so far */
      pap_t *q = (pap_t *)fpr_alloc(sizeof(pap_t) + p->arity * 8);
      q->tid = T_PAP;
      q->var = 0;
      q->fn = p->fn;
      q->arity = p->arity;
      q->nargs = have + n;
      for (uw i = 0; i < have; i++) q->args[i] = p->args[i];
      for (uw i = 0; i < n; i++) q->args[have + i] = RARG(i);
      return (V)q;
    }
    V args[8];
    for (uw i = 0; i < have; i++) args[i] = p->args[i];
    for (uw i = 0; i < need; i++) args[have + i] = RARG(i);
    V r = callf(p->fn, p->arity, args);
    if (n == need) return r;
    /* over-saturated: the result must itself be applicable */
    n -= need;
    // could (void) to silence
    rargs = rargs; /* remaining logical args are 0..n-1: same base */
    f = r;
  }
#undef RARG
}

static V g_sys_harts(V d) { (void)d; return TAG(FPR_NHARTS); }
FPR_FN(fpr_g_Sys_x2eharts, g_sys_harts, 1);

/* builtin Result constructors for C-side service code */
V fpr_mkresultn(uw variant, const char *s, uw n) {
  hdr_t *h = (hdr_t *)fpr_alloc(8 + sizeof(uw));
  h->tid = T_RESULT;
  h->var = (uint32_t)variant;
  *(V *)((char *)h + 8) = (V)fpr_mkstr((const uint8_t *)s, n);
  return (V)h;
}
V fpr_mkresult(uw variant, const char *s) {
  uw n = 0;
  while (s[n]) n++;
  return fpr_mkresultn(variant, s, n);
}

/* ---- strings --------------------------------------------------------- */
str_t *fpr_mkstr(const uint8_t *src, uw n) {
  str_t *s = (str_t *)fpr_alloc(sizeof(str_t) + n);
  s->tid = T_STR;
  s->var = 0;
  s->len = n;
  for (uw i = 0; i < n; i++) s->bytes[i] = src[i];
  return s;
}

/* ---- core prims ------------------------------------------------------ */
V fpr_prim_fn__x2b(V a, V b) { return TAG(UNTAG(a) + UNTAG(b)); }
V fpr_prim_fn__x2d(V a, V b) { return TAG(UNTAG(a) - UNTAG(b)); }
V fpr_prim_fn__x2a(V a, V b) { return TAG(UNTAG(a) * UNTAG(b)); }
V fpr_prim_fn__x2f(V a, V b) {
  if (UNTAG(b) == 0) fpr_cpanic("division by zero");
  return TAG(UNTAG(a) / UNTAG(b));
}
V fpr_prim_fn__x3c(V a, V b) { return BOOL(UNTAG(a) < UNTAG(b)); }
V fpr_prim_fn__x3e(V a, V b) { return BOOL(UNTAG(a) > UNTAG(b)); }
V fpr_prim_fn__x3c_x3d(V a, V b) { return BOOL(UNTAG(a) <= UNTAG(b)); }
V fpr_prim_fn__x3e_x3d(V a, V b) { return BOOL(UNTAG(a) >= UNTAG(b)); }

/* == : ints by value; strings by content; other data SHALLOW (header
 * only) -- enough for bools/units/nullary tags. PoC limitation, on
 * purpose: deep structural equality needs per-type field counts. */
static int veq(V a, V b) {
  if (ISINT(a) || ISINT(b)) return a == b;
  hdr_t *x = (hdr_t *)a, *y = (hdr_t *)b;
  if (x->tid != y->tid || x->var != y->var) return 0;
  if (x->tid == T_STR) {
    str_t *s = (str_t *)a, *t = (str_t *)b;
    if (s->len != t->len) return 0;
    for (uw i = 0; i < s->len; i++)
      if (s->bytes[i] != t->bytes[i]) return 0;
  }
  return 1;
}
V fpr_prim_fn__x3d_x3d(V a, V b) { return BOOL(veq(a, b)); }
V fpr_prim_fn__x21_x3d(V a, V b) { return BOOL(!veq(a, b)); }

/* ---- render: matches the host evaluator's `render` output ----------- */
/* Lists "[1, 2]", atoms ":done", bools, unit "()", tuples via the
 * generic "<t.v fields>" form for known-arity builtins, bare "<t.v>"
 * for user types and record shapes (no field counts in headers yet). */
/* render buffers are PER HART (fpr_hart_t.rbuf): `str` and string
 * interpolation run concurrently on different harts. */
#define rbuf (fpr_hart()->rbuf)
#define rpos (fpr_hart()->rpos)
/* Overflow used to be SILENT: `if (rpos < CAP) ...` dropped every
 * character past 4095 and returned a short string, so a large
 * interpolation ("{bigString}") produced a truncated page with no
 * error anywhere -- valid HTML, cut mid-token. Renders are bounded by
 * design (this buffer is per-hart and fixed), so overflowing it is a
 * program error and says so. The common case that USED to hit this --
 * interpolating a value that is already a String -- no longer routes
 * through the buffer at all; see fpr_prim_fn_str. */
static void remit(char c) {
  if (rpos >= FPR_RBUF_SZ - 1)
    fpr_cpanic("str/print: render buffer full (4096B) -- build large "
               "strings with strcat, not interpolation");
  rbuf[rpos++] = c;
}
static void remits(const char *s) { while (*s) remit(*s++); }
static void rdec(sw n) {
  char b[24];
  int i = 23;
  int neg = n < 0;
  uw u = neg ? (uw)(-n) : (uw)n;
  if (u == 0) b[i--] = '0';
  while (u) { b[i--] = '0' + (u % 10); u /= 10; }
  if (neg) b[i--] = '-';
  for (int j = i + 1; j <= 23; j++) remit(b[j]);
}
static void render(V v);
static void rfields(V *f, int n) { /* "<t.v f1 f2>" tail */
  for (int i = 0; i < n; i++) { remit(' '); render(f[i]); }
}
static void render(V v) {
  if (ISINT(v)) { rdec(UNTAG(v)); return; }
  hdr_t *h = (hdr_t *)v;
  V *f = (V *)((char *)v + 8);
  switch (h->tid) {
    case T_STR: {
      str_t *s = (str_t *)v;
      for (uw i = 0; i < s->len; i++) remit((char)s->bytes[i]);
      break;
    }
    case T_BOOL: remits(h->var ? "True" : "False"); break;
    case T_UNIT: remits("()"); break;
    case T_ATOM: remit(':'); render(f[0]); break;
    case T_LIST:
      if (h->var == 0) { remits("[]"); break; }
      remit('[');
      for (V c = v;;) {
        V *cf = (V *)((char *)c + 8);
        render(cf[0]);
        c = cf[1];
        if (ISINT(c) || ((hdr_t *)c)->tid != T_LIST || ((hdr_t *)c)->var != 1) break;
        remits(", ");
      }
      remit(']');
      break;
    case T_RESULT: remits("<3."); rdec(h->var); rfields(f, 1); remit('>'); break;
    case T_TUP2:
      remit('('); render(f[0]); remits(", "); render(f[1]); remit(')');
      break;
    case T_TUP3:
      remit('('); render(f[0]); remits(", "); render(f[1]); remits(", ");
      render(f[2]); remit(')');
      break;
    case T_BITS: rdec((sw)((bits_t *)v)->val); break;
    case T_PAP: remits("<fn>"); break;
    default: remit('<'); rdec(h->tid); remit('.'); rdec(h->var); remit('>'); break;
  }
}

V fpr_prim_fn_str(V v) {
  /* a String renders as itself: return it unchanged rather than
   * copying it through the fixed render buffer. This is what makes
   * "{s}" safe for strings of any size (and it saves the copy). */
  if (!ISINT(v) && TID(v) == T_STR) return v;
  rpos = 0;
  render(v);
  return (V)fpr_mkstr((const uint8_t *)rbuf, (uw)rpos);
}

fpr_lock_t fpr_con_lock; /* console: one LINE at a time across harts */

V fpr_prim_fn_print(V v) {
  rpos = 0;
  render(v);
  fpr_lock(&fpr_con_lock);
  for (int i = 0; i < rpos; i++) {
    if (rbuf[i] == '\n') hal_putc('\r');
    hal_putc(rbuf[i]);
  }
  hal_putc('\r');
  hal_putc('\n');
  fpr_unlock(&fpr_con_lock);
  return (V)&fpr_unit;
}

/* String.len -- mangled: '.' = _x2e */
V fpr_prim_fn_String_x2elen(V s) {
  str_t *t = (str_t *)s;
  if (ISINT(s) || t->tid != T_STR) fpr_cpanic("String.len: not a string");
  return TAG(t->len);
}

/* ! : list lookup, 1-indexed */
V fpr_prim_fn__x21(V xs, V iv) {
  sw i = UNTAG(iv);
  V c = xs;
  for (;;) {
    if (ISINT(c) || TID(c) != T_LIST || ((hdr_t *)c)->var != 1)
      fpr_cpanic("!: index out of range");
    V *f = (V *)((char *)c + 8);
    if (i == 1) return f[0];
    c = f[1];
    i--;
  }
}

V fpr_prim_fn_strcat(V a, V b) {
  str_t *x = (str_t *)a, *y = (str_t *)b;
  if (ISINT(a) || ISINT(b) || x->tid != T_STR || y->tid != T_STR)
    fpr_cpanic("strcat: not strings");
  str_t *s = (str_t *)fpr_alloc(sizeof(str_t) + x->len + y->len);
  s->tid = T_STR;
  s->var = 0;
  s->len = x->len + y->len;
  for (uw i = 0; i < x->len; i++) s->bytes[i] = x->bytes[i];
  for (uw i = 0; i < y->len; i++) s->bytes[x->len + i] = y->bytes[i];
  return (V)s;
}

V fpr_prim_fn_error(V s) { fpr_panic(s); }

void fpr_render_to_uart(V v) {
  rpos = 0;
  render(v);
  for (int i = 0; i < rpos; i++) {
    if (rbuf[i] == '\n') hal_putc('\r');
    hal_putc(rbuf[i]);
  }
}

/* string helpers exposed through the fpr_g_ contract (1-indexed, FPRISC) */
static V g_charAt(V s, V i) {
  str_t *t = (str_t *)s;
  if (ISINT(s) || t->tid != T_STR) fpr_cpanic("charAt: not a string");
  sw k = UNTAG(i);
  if (k < 1 || (uw)k > t->len) fpr_cpanic("charAt: index out of range");
  return TAG(t->bytes[k - 1]);
}
static V g_strlen(V s) {
  str_t *t = (str_t *)s;
  if (ISINT(s) || t->tid != T_STR) fpr_cpanic("strlen: not a string");
  return TAG(t->len);
}

/* parseInt : String -> Int — decimal, leading '-' allowed, stops at the
 * first non-digit. Empty or all-non-digit yields 0 (the pI idiom). */
static V g_parseInt(V sv) {
  if (ISINT(sv) || ((str_t *)sv)->tid != T_STR) fpr_cpanic("parseInt: not a String");
  str_t *s = (str_t *)sv;
  uw i = 0;
  sw sign = 1, acc = 0;
  if (i < s->len && s->bytes[i] == '-') { sign = -1; i++; }
  for (; i < s->len; i++) {
    uint8_t c = s->bytes[i];
    if (c < '0' || c > '9') break;
    acc = acc * 10 + (c - '0');
  }
  return TAG(sign * acc);
}

/* chr : Int -> String -- the inverse of charAt. One byte. The line
 * editor and path splitter build strings incrementally with this. */
static V g_chr(V c) {
  if (!ISINT(c)) fpr_cpanic("chr: not an Int");
  uint8_t b = (uint8_t)UNTAG(c);
  return (V)fpr_mkstr(&b, 1);
}

/* ---- static PAP objects (symbol names = mangled FPRISC names) ---------- */
FPR_FN(fpr_prim_obj__x2b, fpr_prim_fn__x2b, 2);       /* +  */
FPR_FN(fpr_prim_obj__x2d, fpr_prim_fn__x2d, 2);       /* -  */
FPR_FN(fpr_prim_obj__x2a, fpr_prim_fn__x2a, 2);       /* *  */
FPR_FN(fpr_prim_obj__x2f, fpr_prim_fn__x2f, 2);       /* /  */
FPR_FN(fpr_prim_obj__x3d_x3d, fpr_prim_fn__x3d_x3d, 2);    /* == */
FPR_FN(fpr_prim_obj__x21_x3d, fpr_prim_fn__x21_x3d, 2);    /* != */
FPR_FN(fpr_prim_obj__x3c, fpr_prim_fn__x3c, 2);        /* <  */
FPR_FN(fpr_prim_obj__x3e, fpr_prim_fn__x3e, 2);        /* >  */
FPR_FN(fpr_prim_obj__x3c_x3d, fpr_prim_fn__x3c_x3d, 2);    /* <= */
FPR_FN(fpr_prim_obj__x3e_x3d, fpr_prim_fn__x3e_x3d, 2);    /* >= */
FPR_FN(fpr_prim_obj_strcat, fpr_prim_fn_strcat, 2);
FPR_FN(fpr_prim_obj_print, fpr_prim_fn_print, 1);
FPR_FN(fpr_prim_obj_String_x2elen, fpr_prim_fn_String_x2elen, 1);
FPR_FN(fpr_prim_obj__x21, fpr_prim_fn__x21, 2);
FPR_FN(fpr_prim_obj_str, fpr_prim_fn_str, 1);
FPR_FN(fpr_prim_obj_error, fpr_prim_fn_error, 1);

FPR_FN(fpr_g_charAt, g_charAt, 2);
FPR_FN(fpr_g_strlen, g_strlen, 1);
FPR_FN(fpr_g_chr, g_chr, 1);
FPR_FN(fpr_g_parseInt, g_parseInt, 1);
FPR_FN(fpr_g_substr, g_substr, 3);
FPR_FN(fpr_g_drop, g_drop, 1);
FPR_FN(fpr_g_arcLive, g_arcLive, 1);
FPR_FN(fpr_g_heapUsed, g_heapUsed, 1);
