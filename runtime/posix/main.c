/* main.c (posix) — hosted boot: what crt0.S does on virt, done by the
 * host instead.  fpr_rt_init is the SAME portable init virt runs
 * (buddy over the heap, hart blocks, actors_init fabricating actor 0
 * around fpr_fn_main); harts are pthreads; the scheduler, mailboxes,
 * fuel preemption and deadlock detector are runtime/core/actors.c,
 * byte-for-byte the bare-metal ones.  This is the P4 plan's shape --
 * N actors multiplexed onto a fixed few kernel threads -- with Linux
 * playing the part of the IDF boot.
 */
#include "fpr.h"
#include <pthread.h>

/* the hosted stand-in for tp (one per hart THREAD): generated x64/a64
 * code TLS-loads this where generated rv64 code reads tp. */
__thread fpr_hart_t *fpr_posix_hart;

#if defined(__x86_64__)
/* X64.hs's staging cells for SysV stack args 7/8 (see the a6/a7 rules
 * in the lowering header): written at arg staging, read by the very
 * next call's spill -- per hart thread, hence TLS, like tp above. */
__thread uw fpr_x64_a6, fpr_x64_a7;
#endif

static void *hart_thread(void *arg) {
  fpr_hart_secondary((int)(uintptr_t)arg); /* sets tp, joins the loop */
  return 0;
}

int main(void) {
  fpr_rt_init(); /* runtime/core: buddy, hart blocks, actor 0, smp_go */
  for (uintptr_t i = 1; i < FPR_NHARTS; i++) {
    pthread_t t;
    if (pthread_create(&t, 0, hart_thread, (void *)i))
      fpr_cpanic("posix: pthread_create");
  }
  fpr_hart_main(0); /* never returns: fpr_exit -> hal_poweroff -> exit */
}
