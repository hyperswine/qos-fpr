/* fpr.h — the value representation contract.
 *
 * Everything is a machine-word V (64-bit on rv64, 32-bit on rv32):
 *   integers: (n << 1) | 1     (XLEN-1 bit, tag in bit 0)
 *   else: 8-aligned pointer to [ u32 typeid | u32 variant | word fields... ]
 *
 * The generated assembly hard-codes exactly this layout (header loads at
 * 0/4, fields at 8 + W*i where W = XLEN/8), so this header and Codegen.hs
 * must move together.  `uw` is the word type: every field the generated
 * code touches is a `uw`, never a fixed-width 64-bit type.
 */
#ifndef FPR_H
#define FPR_H

#include <stddef.h>
#include <stdint.h>

typedef uintptr_t V;
typedef uintptr_t uw; /* one machine word: field / length / count type */
typedef intptr_t sw;

enum {
  T_UNIT = 0, T_BOOL = 1, T_LIST = 2, T_RESULT = 3,
  T_TUP2 = 4, T_TUP3 = 5, T_ATOM = 6,
  /* runtime-internal typeids, far above user types (10+) and shapes (100+) */
  T_STR = 9000, T_PAP = 9001, T_DEVICE = 9002, T_REGISTER = 9003, T_BITS = 9004,
  T_ACTOR = 9005, T_VEC = 9006, T_SSTR = 9007,
};

typedef struct { uint32_t tid, var; } __attribute__((aligned(8))) hdr_t;
typedef struct { uint32_t tid, var; uw fn, arity, nargs, args[]; } __attribute__((aligned(8))) pap_t;
typedef struct { uint32_t tid, var; uw fn, arity, nargs; } __attribute__((aligned(8))) pap0_t;
typedef struct { uint32_t tid, var; uw len; uint8_t bytes[]; } __attribute__((aligned(8))) str_t;
typedef struct { uint32_t tid, var; uw base; } __attribute__((aligned(8))) fpr_dev_t;
typedef struct { uint32_t tid, var /* = width in bytes */; uw addr; } __attribute__((aligned(8))) reg_t;
typedef struct { uint32_t tid, var /* = endian: 0 LE, 1 BE */; uw len, val; } __attribute__((aligned(8))) bits_t;

#define TAG(n) ((V)((((sw)(n)) << 1) | 1))
#define UNTAG(v) (((sw)(v)) >> 1)
#define ISINT(v) ((v) & 1)
#define TID(v) (((hdr_t *)(v))->tid)
#define BOOL(b) ((b) ? (V)&fpr_true : (V)&fpr_false)

extern const hdr_t fpr_true, fpr_false, fpr_unit;

/* ---- SMP: the per-hart control block ---------------------------------
 * Every hart's tp register points at its fpr_hart_t FOR THE LIFE OF THE
 * HART (set in boot code, saved/restored verbatim by fpr_ctx_switch --
 * actors never migrate, so an actor's saved tp is always its owner
 * hart's block).  The FIRST field is the fuel counter: generated code
 * decrements 0(tp) at every function entry.  That is the whole
 * codegen<->SMP contract: one register, one offset.
 *
 * The heap is split into per-hart arenas at boot; allocation and the
 * segregated free lists are hart-local and therefore LOCK-FREE.  A
 * block allocated on hart A and freed on hart B simply migrates to B's
 * free list -- the memory is shared and the bump pointers never revisit
 * carved space, so no double-allocation is possible.
 */
#ifndef FPR_NHARTS
#define FPR_NHARTS 2
#endif
#define FPR_NBUCKETS 512
#define FPR_RBUF_SZ 4096

struct fpr_acb; /* actors.c */

/* ---- per-actor slab pools (the slab refactor) -----------------------
 * Buddy is the ONE lower allocator (init'd over heap+proc regions at
 * boot).  Every actor owns a chain of slabs cut from buddy; fpr_alloc
 * bumps the current slab, actor death returns the chain.  A slab that
 * holds PROMOTED objects (escaped > 0, maintained under the ARC lock)
 * is ORPHANED on death instead of freed (owner = NULL) and returns to
 * buddy when its last promoted object is dropped -- cross-actor
 * references can never dangle.  Stacks are buddy blocks too and never
 * escape, so death always reclaims them: the v2 "stacks leak on death"
 * caveat is structurally gone.  Block header (16 bytes, alignment
 * preserved): [0] = total size, [1] = owning slab. */
typedef struct fpr_slab {
  struct fpr_slab *next;
  struct fpr_pool *owner; /* NULL = orphaned (freed when escaped hits 0) */
  uw escaped;             /* promoted objects resident here (ARC lock) */
  char *hp, *end;
} fpr_slab_t;

typedef struct fpr_pool {
  fpr_slab_t *cur;  /* bump target; also the chain head */
  void **buckets;   /* FPR_NBUCKETS recycled-block heads, OUT-OF-LINE
                     * (CAS push any hart, owner drains).  Out-of-line
                     * so the array is reclaimed at actor death -- with
                     * it inline, every dead acb kept 4 KiB forever.
                     * Reuse is type-stable under arc_lock; a dead
                     * pool is unreachable by fpr_free (teardown
                     * orphans escaped slabs first).  runtime.c owns
                     * the recycler (bkt_take/bkt_put). */
  uw allocated;     /* gauge: bytes ever bumped by this owner */
} fpr_pool_t;
void **fpr_bkt_take(void);   /* runtime.c: bucket-array recycler */
void fpr_bkt_put(void **b);

fpr_pool_t *fpr_acb_pool(struct fpr_acb *a); /* actors.c: &a->pool */
void fpr_pool_reclaim(struct fpr_acb *a);    /* runtime.c: death teardown */
void *buddy_alloc(uw bytes);                 /* buddy.c */
void buddy_free(void *p);
uw buddy_block_usable_size(void *p);
uw buddy_free_bytes(void);
void *buddy_reserve_range(void *addr, uw bytes);
void buddy_release_range(void *addr, uw bytes);
void buddy_init(void *base, uw size);

typedef struct {
  sw fuel; /* MUST stay at offset 0: generated code does ld/sd 0(tp) */
  uw id;
  fpr_pool_t pool;                /* boot/hart-loop allocs (pre-actor, never freed) */
  struct fpr_acb *current;        /* running actor, 0 = in the hart loop */
  struct fpr_acb *rq_head, *rq_tail; /* local run queue (owner-only) */
  uw sched_ctx[16];               /* the hart loop's context */
  volatile uw idle;               /* 1 while polling with nothing to run */
  volatile uw epoch;              /* hart-loop iteration count: the
                                   * quiescence clock for deferred
                                   * channel-block reuse (actors.c) */
  uw fuel_preempts;
  char rbuf[FPR_RBUF_SZ];         /* per-hart render buffer (str/print) */
  int rpos;
  /* two-tier bounded-latency scheduler (docs/SCHED-MODEL.md) */
  struct fpr_acb *bl_head, *bl_tail; /* ready backlog (owner-only) */
  uw bl_len;
  uw rq_len;
  uw lcg; /* per-hart deterministic PRNG state (weighted default tier) */
} fpr_hart_t;

extern fpr_hart_t fpr_harts[FPR_NHARTS];
/* how many hart blocks are LIVE this run (threads actually started):
 * FPR_NHARTS is the compile-time cap and the static array size; the
 * hosted boots (posix main.c, qosapp entry.c) may run fewer -- env
 * FPR_HARTS, or the host's resolved core count under qosp.  Scheduler
 * scans, the deadlock detector, and spawnOn bounds all use this. */
extern uw fpr_live_harts;

#if defined(FPR_QOSAPP)
/* a loaded QOS Portable app image (runtime/qosapp): fixed-slot with no
 * dynamic loader behind it -- nothing registers a TLS block for the
 * image, and link-time @tpoff constants would index the HOST's TCB at
 * meaningless offsets.  Multi-hart (ABI v2) therefore BORROWS THE
 * HOST'S TLS: qosp keeps one __thread borrow block {hart, a6, a7} per
 * hart thread and publishes its thread-pointer displacement in the
 * boot record; entry.c lands it in fpr_g_tlsoff before anything else
 * runs.  The displacement is identical in every thread (static TLS),
 * so these accessors -- and the matching --target=qx64/qa64 emission
 * (X64.hs/A64.hs deTls passes) -- are per-hart-correct with zero app
 * TLS.  fpr_posix_hart/fpr_x64_a6/a7 become lvalue MACROS over the
 * block so the shared runtime sources read unchanged. */
#define FPR_TLS /* accessed through the borrow block */
extern uw fpr_g_tlsoff; /* entry.c: boot->tls_off */
static inline char *fpr_tls_blk(void) {
  return (char *)__builtin_thread_pointer() + fpr_g_tlsoff;
}
#define fpr_posix_hart (*(fpr_hart_t **)fpr_tls_blk())
#define fpr_x64_a6 (*(uw *)(fpr_tls_blk() + 8))
#define fpr_x64_a7 (*(uw *)(fpr_tls_blk() + 16))
static inline fpr_hart_t *fpr_hart(void) { return fpr_posix_hart; }
#elif defined(FPR_POSIX)
/* hosted: no free per-thread register (tpidr_el0/fs belong to libc
 * TLS); the SAME thread-local that A64.hs/X64.hs make generated code
 * load.  __thread: each hart pthread carries its own, so actors see
 * their OWNER hart's block exactly as tp gives them on bare metal. */
#define FPR_TLS __thread
extern __thread fpr_hart_t *fpr_posix_hart;
static inline fpr_hart_t *fpr_hart(void) { return fpr_posix_hart; }
#else
static inline fpr_hart_t *fpr_hart(void) {
  fpr_hart_t *h;
  __asm__("mv %0, tp" : "=r"(h));
  return h;
}
#endif

/* test-and-test-and-set spinlock (AMO acquire/release; A is in imac) */
typedef struct { volatile uw v; } fpr_lock_t;
static inline void fpr_lock(fpr_lock_t *l) {
  for (;;) {
    if (!__atomic_exchange_n(&l->v, 1, __ATOMIC_ACQUIRE)) return;
    while (__atomic_load_n(&l->v, __ATOMIC_RELAXED)) __asm__ volatile("nop");
  }
}
static inline void fpr_unlock(fpr_lock_t *l) {
  __atomic_store_n(&l->v, 0, __ATOMIC_RELEASE);
}

/* ---- process loading (docs/PROCESS-LOADING.md) ------------------------
 * buddy.c: a power-of-two allocator over the reserved process arena
 * (_proc_arena_start.._proc_arena_end, defined in link.ld). Owned by
 * whichever image calls buddy_init -- System.qa, in this design.
 */
void buddy_init(void *base, uw size);
void *buddy_alloc(uw bytes);   /* NULL on exhaustion */
void buddy_free(void *p);
uw buddy_arena_size(void);
uw buddy_free_bytes(void);
void *buddy_reserve_range(void *addr, uw bytes);
void buddy_release_range(void *addr, uw bytes);
uw buddy_block_usable_size(void *p);

extern char _proc_arena_start[], _proc_arena_end[];

/* the memory-growth grant a process's fpr_alloc asks for on bump
 * exhaustion (runtime.c) -- ptr NULL means denied. fpr_grow_memory is
 * NULL for a normal machine boot (unchanged hard-panic-on-exhaustion
 * behavior there); a loaded process's entry point wires it to a
 * callback into System.qa's buddy allocator. */
typedef struct { void *ptr; uw size; } fpr_grant_t;
extern fpr_grant_t (*fpr_grow_memory)(uw want_bytes);
fpr_grant_t fpr_grow_counted(uw want_bytes); /* the counted gateway */

/* elfload.c: a minimal ELF32/ELF64 PT_LOAD segment loader. FIXED-SLOT
 * ONLY -- p_vaddr must already equal the intended physical load
 * address (no relocation is performed; see docs/PROCESS-LOADING.md for
 * why that is a real, stated scope limit, not an oversight). Segments
 * must fall entirely within [slot_base, slot_base+slot_size). */
typedef struct { void *entry; void *image_end; int ok; const char *err;
                 void *exec_end; /* high-water mark of PF_X PT_LOADs (0 if none) */
                 void *rw_start; /* low-water mark of PF_W PT_LOADs ((void*)-1 if
                                  * none); together these let a hosted loader
                                  * mprotect code r-x and leave data rw (macOS
                                  * arm64 forbids w+x on one page) */
} fpr_elf_load_t;
fpr_elf_load_t fpr_elf_load(const unsigned char *bytes, uw len, void *slot_base, uw slot_size);

/* proc_entry.c: compiled into an APP image (not the top-level boot).
 * Plain callable function -- ENTRY(fpr_process_entry) in link-app.ld
 * just points the ELF header's e_entry at it, no assembly needed. */
V fpr_process_entry(void *heap_base, uw heap_size, fpr_grant_t (*grow)(uw want_bytes),
                    const unsigned char *caps, uw caps_len,
                    sw (*syscall_fn)(uw, const char *, uw, char *, uw));

/* actors.c: process-mode flags/result (see the essay in actors.c) */
extern volatile int fpr_is_process;
extern volatile int fpr_process_done;
V fpr_process_result_get(void);
V fpr_prim_fn_str(V v); /* runtime.c: render() a value to a String, same as `str`/print */
extern void fpr_hart_main(int id); /* actors.c: runs hart_loop; returns when fpr_process_done */
extern void fpr_actors_init(void); /* actors.c: sets up actor 0 on hart 0 */
void fpr_proc_arena_init(void);
void fpr_set_tp(fpr_hart_t *h); /* runtime.c */
/* park-forever, portably: rv wfi on metal, a libc pause when hosted
 * (only reached if hal_poweroff ever returns -- real-HW behavior) */
#ifdef FPR_POSIX
void fpr_park(void);
#define FPR_PARK() fpr_park()
#else
#define FPR_PARK() __asm__ volatile("wfi")
#endif
/* boot entry points (virt: called from crt0.S; posix: from main.c) */
void fpr_rt_init(void);          /* runtime.c: buddy, harts, actor 0 */
void fpr_hart_main(int id);      /* actors.c: hart 0's loop */
void fpr_hart_secondary(int id); /* actors.c: secondary hart's loop */
void fpr_ctx_fabricate(uw *ctx, void (*entry)(void), uw stack_top16,
                       fpr_hart_t *owner); /* ctx layer (virt/posix) */ /* process.c: buddy_init over _proc_arena_start.._end */

V fpr_alloc(V raw_bytes); /* bump + free list; arg is a RAW byte count, not tagged */
void fpr_free(V obj);     /* returns to the free list (sizes <= 8 KiB) */
int fpr_in_heap(V v);     /* heap pointer (promotable) vs int/immortal static */
void fpr_arc_incref(V v);
void fpr_arc_decref(V v);
uw fpr_arc_live(void);
V fpr_apply(V f, V a);
V fpr_applyN(V f, uw n, V *rargs);
V fpr_send_as(uw sender_key, V av, V m);
void *fpr_syscall_mailbox(void);
V fpr_syscall_wait_result(void);
V fpr_mkresult(uw variant, const char *s);
V fpr_mkresultn(uw variant, const char *s, uw n);
void fpr_panic(V str_obj) __attribute__((noreturn));
void fpr_cpanic(const char *msg) __attribute__((noreturn));
str_t *fpr_mkstr(const uint8_t *src, uw n);

void hal_putc(char c); /* hal.c: raw console for panics + runtime */
void hal_poweroff(int code); /* hal.c: terminate the machine if the
                              * platform can (QEMU virt: sifive test
                              * finisher).  May return (real silicon:
                              * no-op); callers park in wfi after. */

/* static PAP definition helper: NAME must already be mangled */
#define FPR_FN(sym, cfn, ar) \
  const pap0_t sym = {T_PAP, 0, (uw)(uintptr_t)(cfn), (ar), 0}

#endif

/* SString: fixed 128-byte inline string (sstr.c). len is the live count. */
#define SSTR_CAP 128
typedef struct { uint32_t tid, var; uw len; uint8_t bytes[SSTR_CAP]; } __attribute__((aligned(8))) sstr_t;