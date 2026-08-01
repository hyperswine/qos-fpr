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
  void *p = buddy_alloc(want);
  qos_grant_t g = {p, p ? buddy_block_usable_size(p) : 0};
  TRACE("grow(%" PRIu64 ") -> %p (+%" PRIu64 ")\n", want, p, g.size);
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

static void bus_handler(int sig, siginfo_t *info, void *vctx) {
  /* Diagnostic only: report where the app faulted, then die.  The arena
   * is plain rw with an r-x code prefix (see stage 2), so any fault here
   * is a real bug in the app or the loader, not a protection artifact. */
  ucontext_t *uc = (ucontext_t *)vctx;
#ifdef __APPLE__
  uintptr_t pc = uc ? uc->uc_mcontext->__ss.__pc : 0;
#else
  uintptr_t pc = 0; (void)uc;
#endif
  void *addr = info ? info->si_addr : 0;
  int in_image = (pc >= QOS_SLOT_BASE && pc < QOS_SLOT_BASE + QOS_SLOT_SIZE);
  fprintf(stderr, "qosp: fatal %s: addr=%p pc=%#lx in_image=%d\n",
          sig == SIGBUS ? "SIGBUS" : "SIGSEGV", addr, (unsigned long)pc,
          in_image);
  fflush(stderr);
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
	void *arena =
      mmap((void *)QOS_ARENA_BASE, QOS_ARENA_SIZE, PROT_READ | PROT_WRITE,
           MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (arena != (void *)QOS_ARENA_BASE) {
    if (arena != MAP_FAILED) munmap(arena, QOS_ARENA_SIZE);
    fprintf(stderr,
            "qosp: cannot map the arena at %#lx (ASLR collision or RWX "
            "policy) -- the app image is linked at this address, so there "
            "is no fallback\n",
            QOS_ARENA_BASE);
    return 1;
  }
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

	/* Publish the code: the arena is a single rw anonymous mapping, but on
   * macOS arm64 a page can never be writable and executable at once, so
   * flip just the executable prefix of the image (the PF_X PT_LOADs, as
   * reported by elfload) to r-x and leave everything after it -- rodata
   * tail, data, bss, heap, and the buddy arena -- rw.  The linker script
   * places .text first and the RW segment on its own 64 KiB-aligned page,
   * so the 16 KiB host-page round-up never captures a writable byte.  On
   * Linux hosts the rw mapping already executes (no W^X policy for
   * MAP_ANON there), so the mprotect is Darwin-only; the icache clear is
   * needed on any arm64 host. */
#ifdef __APPLE__
  {
    uintptr_t pg = (uintptr_t)getpagesize();
    uintptr_t xend = ((uintptr_t)ld.exec_end + pg - 1) & ~(pg - 1);
    if (xend <= (uintptr_t)QOS_SLOT_BASE || ld.exec_end == 0) {
      fprintf(stderr, "qosp: image has no executable segment\n");
      return 1;
    }
    if ((uintptr_t)ld.rw_start < xend) {
      fprintf(stderr,
              "qosp: executable pages would capture writable image data "
              "(exec_end=%p rounds to %#lx, first rw byte at %p, page=%lu) "
              "-- relink with page-separated segments\n",
              ld.exec_end, (unsigned long)xend, ld.rw_start,
              (unsigned long)pg);
      return 1;
    }
    if (mprotect((void *)QOS_SLOT_BASE, xend - QOS_SLOT_BASE,
                 PROT_READ | PROT_EXEC)) {
      perror("qosp: mprotect(code, r-x)");
      return 1;
    }
    TRACE("stage 2: code [%#lx..%#lx) r-x, data+heap rw\n",
          (unsigned long)QOS_SLOT_BASE, (unsigned long)xend);
  }
#endif
  __builtin___clear_cache((char *)QOS_SLOT_BASE, (char *)ld.image_end);

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