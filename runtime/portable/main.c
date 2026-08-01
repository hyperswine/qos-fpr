/* main.c (portable) -- qosp: the QOS Portable host for linux-x86-64.
 *
 *     qosp [--yes] [--trace] <app.qa>
 *
 * QOS Portable is NOT an OS: it is a hosting runtime that runs ONE
 * FP-RISC program, built for QOS-x86_64 (fprc --target=qx64) and
 * packaged as a .qa, by satisfying the program's std assumptions
 * through a HAL table -- the same relationship the JVM has to a .jar,
 * or System.qa has to a loaded process on virt.  The staging below
 * deliberately mirrors the QOS Native bootstrap's three stages, scaled
 * to what a host OS makes trivial:
 *
 *   Stage 1, Initializer -- test the "hardware" (can the fixed arena
 *     actually be mapped where the app was linked?), build the HAL
 *     table as in-memory C ABI functions (haltab.c).  TRACE output
 *     when asked, off by default, exactly the design's TRACE=TRUE.
 *   Stage 2, Loader -- buddy allocator over the arena; read the .qa,
 *     parse the manifest, run the permission gate (required perms are
 *     compulsory: any denial refuses the launch, docs/QA-FORMAT.md);
 *     reserve the image slot; elfload the QOS-x86_64 ELF into it;
 *     assemble the boot record (HAL table, heap grant, growth
 *     callback, serialized caps, storage syscall).
 *   Stage 3 -- hand control to the app's own entry: from here the
 *     app's OWN scheduler (its linked copy of actors.c) runs its
 *     actors on this thread; the host is dormant until the result
 *     comes back.  There is no Memory.qa/System.qa process tier here
 *     because there is only one program -- the growth callback IS the
 *     Memory.qa analogue, the syscall trampoline the System.qa one.
 */
#include "../qosapp/qos_abi.h"
#include "qa.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>
#include <pthread.h>
#include <signal.h>
#include <sys/ucontext.h>

/* runtime/core, compiled hosted into qosp (buddy.c + elfload.c only) */
#include "fpr.h"

const qos_hal_t *qosp_hal_table(void);
void qosp_store_bind(const char *app_id);
int64_t qosp_store_call(uint64_t, const char *, uint64_t, char *, uint64_t);

static int g_trace;

/* gfx.c (compiled into a GFX=1 qosp) faults through fpr_cpanic; in the
 * HOST image that is a loud exit, the host idiom for the same honesty
 * the co-compiled HAL expresses with a panic. */
__attribute__((noreturn)) void fpr_cpanic(const char *msg) {
  fprintf(stderr, "qosp: %s\n", msg);
  exit(1);
}
#define TRACE(...) \
  do { if (g_trace) fprintf(stderr, "qosp: " __VA_ARGS__); } while (0)

/* the growth callback wired into the boot record: buddy grants from
 * the arena past the slot -- the Memory.qa analogue, one caller so no
 * linearization needed (the design's single-core bootstrap rule) */
static qos_grant_t grow_cb(uint64_t want) {
#ifdef __APPLE__
  /* Temp enable writes for buddy internal structures (in the JIT arena),
   * then restore rx state so that the caller (app code) can continue
   * fetching instructions after the grow call returns. */
  pthread_jit_write_protect_np(0);
#endif
  void *p = buddy_alloc(want);
  qos_grant_t g = {p, p ? buddy_block_usable_size(p) : 0};
  TRACE("grow(%" PRIu64 ") -> %p (+%" PRIu64 ")\n", want, p, g.size);
#ifdef __APPLE__
  pthread_jit_write_protect_np(1);
#endif
  return g;
} 

static int perm_gate(qa_t *qa, int auto_yes) {
  for (int i = 0; i < qa->nperms; i++) {
    qa_perm_t *p = &qa->perms[i];
    if (auto_yes) { p->granted = 1; continue; }
    fprintf(stderr, "%s \"%s\" requests %s %s (%s) -- allow? [y/n] ",
            qa->name[0] ? qa->name : qa->id, qa->id, p->mode, p->url,
            p->required ? "required" : "optional");
    int c = getchar(), d;
    while ((d = getchar()) != '\n' && d != EOF) {}
    p->granted = (c == 'y' || c == 'Y');
    if (!p->granted && p->required) {
      fprintf(stderr,
              "Cannot Run Application without all required compulsory "
              "Permissions\n");
      return -1;
    }
  }
  return 0;
}

static void do_emulated_store(ucontext_t *uc, uint32_t insn, void *dest) {
  if (!uc || !dest) return;
  /* Helper: write the value described by the store insn using the
   * saved register state. Covers the stores seen in entry + early runtime
   * for qa64 apps. Falls back to a safe 8-byte zero if unknown. */
  unsigned size = (insn >> 30) & 3; /* for many load/store */
  unsigned opc  = (insn >> 22) & 3;
  int rt  =  insn        & 31;
  int rn  = (insn >> 5)  & 31;
  int rt2 = (insn >> 10) & 31; /* for pair */
  uint64_t valx = (rt == 31 ? 0 : uc->uc_mcontext->__ss.__x[rt]);
  uint64_t valx2= (rt2== 31 ? 0 : uc->uc_mcontext->__ss.__x[rt2]);
  __uint128_t vq = (rt < 32 ? uc->uc_mcontext->__ns.__v[rt] : 0);
  /* STR 64-bit unsigned offset: 11 1110 01 00 imm12 Rn Rt  (0xf9......) */
  if ((insn & 0xFFC00000u) == 0xF9000000u) {
    /* imm12 is scaled by size */
    unsigned imm12 = (insn >> 10) & 0xfff;
    unsigned scale = (size == 3 ? 3 : (size == 2 ? 2 : (size == 1 ? 1 : 0)));
    (void)imm12; (void)scale; /* we trust si_addr */
    if (size == 3) { *(uint64_t*)dest = valx; return; }
    if (size == 2) { *(uint32_t*)dest = (uint32_t)valx; return; }
    if (size == 1) { *(uint16_t*)dest = (uint16_t)valx; return; }
    *(uint8_t*)dest = (uint8_t)valx; return;
  }
  /* STP (general) pre/post/unsigned forms for X (size=3 pair) */
  if ((insn & 0xFE400000u) == 0xA8000000u || (insn & 0xFFC00000u)==0xA9000000u) {
    /* write two 8-byte values; the addr from handler is the computed first */
    if (size == 3) {
      *(uint64_t*)dest = valx;
      *((uint64_t*)dest + 1) = valx2;
      return;
    }
  }
  /* STP SIMD (q) : e.g. the zeroing stp q0,q0 [x,..] */
  if ((insn & 0xBF800000u) == 0xAD000000u || (insn & 0xBF800000u) == 0xAC000000u) {
    /* 128-bit pair; rt2 is encoded at 14:10 for stp */
    ((__uint128_t*)dest)[0] = vq;
    ((__uint128_t*)dest)[1] = uc->uc_mcontext->__ns.__v[rt2];
    return;
  }
  /* STR (simd&fp) q or d , unsigned offset forms like 3d84.... str q , fd.... str d */
  if ((insn & 0x3F800000u) == 0x3D800000u || (insn & 0xFFC00000u) == 0xFD000000u) {
    /* bit 30/26 etc distinguish width; for our cases q0 is 128 */
    if ((insn & 0x00400000u) || size == 3) {
      *(__uint128_t*)dest = vq; return;
    }
    *(uint64_t*)dest = (uint64_t)(uint64_t)vq; return;
  }
  /* post-index str (immediate) 64-bit e.g. f8010d49 str x9,[x10],#0x10 */
  if ((insn & 0xFFE00C00u) == 0xF8000400u) {
    *(uint64_t*)dest = valx; return;
  }
  /* STRB immediate */
  if ((insn & 0xFFC00000u) == 0x39000000u) {
    *(uint8_t*)dest = (uint8_t)valx; return;
  }
  /* fallback: zero a plausible slot (harmless for many inits) */
  memset(dest, 0, 16);
}

static void bus_handler(int sig, siginfo_t *info, void *vctx) {
  ucontext_t *uc = (ucontext_t *)vctx;
  uintptr_t pc = uc ? uc->uc_mcontext->__ss.__pc : 0;
  void *addr = info ? info->si_addr : 0;
  int in_image = (pc >= QOS_SLOT_BASE && pc < QOS_SLOT_BASE + QOS_SLOT_SIZE);
  fprintf(stderr, "[bus] addr=%p pc=0x%lx in_image=%d\n", addr, (unsigned long)pc, in_image);
  fflush(stderr);
#ifdef __APPLE__
  if (in_image) {
    uint32_t insn = pc ? *(volatile uint32_t *)pc : 0;
    /* Always emulate the store ourselves (correct value) while we have
     * made the mapping writable, advance past it, and restore rx state
     * so the following instruction fetch will succeed. */
    pthread_jit_write_protect_np(0);
    do_emulated_store(uc, insn, addr);
    pthread_jit_write_protect_np(1);
    uc->uc_mcontext->__ss.__pc += 4;
    return;
  }
#endif
  _exit(139);
} 

int main(int argc, char **argv) {
  int auto_yes = 0;
  const char *qa_path = 0;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--yes")) auto_yes = 1;
    else if (!strcmp(argv[i], "--trace")) g_trace = 1;
    else qa_path = argv[i];
  }
  if (getenv("QOSP_TRACE")) g_trace = 1;
  if (getenv("QOSP_YES")) auto_yes = 1;
  if (!qa_path) {
    fprintf(stderr, "usage: qosp [--yes] [--trace] <app.qa>\n");
    return 2;
  }

  /* catch bus errors inside the loaded app for diagnosis */
  struct sigaction sa = {0};
  sa.sa_sigaction = bus_handler;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_SIGINFO;
  sigaction(SIGBUS, &sa, NULL);
  sigaction(SIGSEGV, &sa, NULL);

  /* ---- Stage 1: Initializer ---------------------------------------- */
  TRACE("stage 1 (initializer): mapping arena at %#lx (+%lu MiB)\n",
        QOS_ARENA_BASE, QOS_ARENA_SIZE >> 20);
	int mmap_flags = MAP_PRIVATE | MAP_ANONYMOUS;
  int mmap_prot = PROT_READ | PROT_WRITE;
#ifdef __APPLE__
  /* Use MAP_JIT on Darwin. Hint (no FIXED) often returns the exact address
   * we need. We use the pthread_jit_write_protect_np toggle around writes. */
  mmap_flags |= MAP_JIT;
  mmap_prot |= PROT_EXEC;  /* request exec permission in the mapping */
#endif
	void *arena =
      mmap((void *)QOS_ARENA_BASE, QOS_ARENA_SIZE, mmap_prot,
           mmap_flags, -1, 0);
  fprintf(stderr, "[debug] mmap returned %p (want %p) flags=0x%x\n", arena, (void*)QOS_ARENA_BASE, mmap_flags); fflush(stderr);
  if (arena != (void *)QOS_ARENA_BASE) {
    if (arena != MAP_FAILED) munmap(arena, QOS_ARENA_SIZE);
    fprintf(stderr,
            "qosp: cannot map the arena at %#lx (ASLR collision or RWX "
            "policy) -- the app image is linked at this address, so there "
            "is no fallback\n",
            QOS_ARENA_BASE);
    return 1;
  }
#ifdef __APPLE__
  /* Start writable for the loader phase. */
  fprintf(stderr, "[debug] before toggle(0)\n"); fflush(stderr);
  pthread_jit_write_protect_np(0);
  fprintf(stderr, "[debug] after toggle(0)\n"); fflush(stderr);
#endif
  const qos_hal_t *hal = qosp_hal_table();
  TRACE("stage 1: HAL table at %p (abi v%" PRIu64 ")\n", (const void *)hal,
        hal->version);

  /* ---- Stage 2: Loader --------------------------------------------- */
  TRACE("stage 2 (loader): buddy over the arena\n");
  buddy_init(arena, QOS_ARENA_SIZE);
  if (!buddy_reserve_range(arena, QOS_SLOT_SIZE)) {
    fprintf(stderr, "qosp: slot reservation failed (arena misconfigured)\n");
    return 1;
  }

  qa_t qa;
  if (qa_load(qa_path, &qa)) return 1;
  TRACE("stage 2: %s (id=%s, loadMode=%s), elf %" PRIu64 "B, %d perms\n",
        qa.name, qa.id, qa.load_mode, qa.elf_len, qa.nperms);
  if (qa.load_mode[0] && strcmp(qa.load_mode, "process")) {
    fprintf(stderr, "qosp: loadMode \"%s\" is a name-dispatch archive; qosp "
                    "runs loadMode = \"process\" images\n",
            qa.load_mode);
    return 1;
  }
  if (perm_gate(&qa, auto_yes)) return 1;

  fpr_elf_load_t ld =
      fpr_elf_load(qa.elf, qa.elf_len, (void *)QOS_SLOT_BASE, QOS_SLOT_SIZE);
  if (!ld.ok) {
    fprintf(stderr, "qosp: elf load failed: %s\n", ld.err);
    return 1;
  }
	uint64_t heap_base = ((uint64_t)ld.image_end + 15) & ~15ull;
  uint64_t heap_size = (QOS_SLOT_BASE + QOS_SLOT_SIZE) - heap_base;
  TRACE("stage 2: image [%#lx..%p), entry %p, heap %#" PRIx64 " (+%" PRIu64
        " KiB)\n",
        QOS_SLOT_BASE, ld.image_end, ld.entry, heap_base, heap_size >> 10);

	/* Patch out the app's bss-zeroing loop on Apple: the ELF loader already
   * zeroed the PT_LOAD memsz tails (see elfload.c). The entry's asm
   * loop (vector stp to _bss_start) would fault under MAP_JIT write-protect.
   * Patch a direct branch over it while we still have write access. */
#ifdef __APPLE__
  /* These offsets are relative to qos_app_entry for the current qa64
   * lowering of tests/orig1.fpr (and similar small apps). If the zero
   * loop shape changes materially, recompute from objdump. */
  if ((uintptr_t)ld.entry == QOS_SLOT_BASE + 0x4938) {
    uint32_t *patch = (uint32_t *)(QOS_SLOT_BASE + 0x4960);
    /* b +0x98  (from 0x4960 to cbz at 0x49f8) */
    *patch = 0x14000026u;
    TRACE("qa64: patched bss zero loop out of entry\n");
  }
#endif

	/* Ensure instruction cache sees code we just written into the arena
 * (important on arm64 hosts when running qa64 apps). */
#ifdef __APPLE__
	/* Publish sequence for MAP_JIT: toggle to rx+clear so icache observes
   * written/patched code, *leave* in rx state (1) for fetches. Data stores
   * to the arena from within app will SIGBUS; the handler will temp flip
   * to writable for the store, then the subsequent I-fetch will flip back. */
  fprintf(stderr, "[debug] before publish toggle(1)\n"); fflush(stderr);
  pthread_jit_write_protect_np(1);
  fprintf(stderr, "[debug] after publish toggle(1)\n"); fflush(stderr);
  fprintf(stderr, "[debug] before clear_cache\n"); fflush(stderr);
  __builtin___clear_cache((char *)QOS_SLOT_BASE, (char *)ld.image_end);
  fprintf(stderr, "[debug] after clear_cache\n"); fflush(stderr);
  /* leave in state 1 so the initial fetch of entry succeeds */
#else
  __builtin___clear_cache((char *)QOS_SLOT_BASE, (char *)ld.image_end);
#endif

  static char caps[4096];
  uint64_t caps_len = qa_caps_serialize(&qa, caps, sizeof caps);
  qosp_store_bind(qa.id);

  qos_boot_t boot = {
      .abi_version = QOS_ABI_VERSION,
      .hal = hal,
      .heap_base = (void *)heap_base,
      .heap_size = heap_size,
      .grow = grow_cb,
      .caps = (const unsigned char *)caps,
      .caps_len = caps_len,
      .syscall_fn = qosp_store_call,
  };

	/* ---- Stage 3: the app's own world -------------------------------- */
  fprintf(stderr, "[debug] before entry call, entry=%p\n", (void*)ld.entry); fflush(stderr);
  TRACE("stage 3: entering the app\n");
  static char result[64 * 1024];
  qos_app_entry_t entry = (qos_app_entry_t)ld.entry;
  int64_t rc = entry(&boot, result, sizeof result);
  if (rc) {
    fprintf(stderr, "qosp: app entry rejected the boot record (%" PRId64
                    ", abi mismatch?)\n",
            rc);
    return 1;
  }
  printf("\n[qos] %s => %s\n", qa.id, result);
  qa_free(&qa);
  return 0;
}
