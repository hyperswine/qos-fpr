/* hal.c (posix) — the hosted HAL binding: libc IS the board.
 *
 * The virt HAL's obligations, re-satisfied by a host OS's userspace:
 * console bytes to stdout, poweroff is exit(2), the CLINT sleep/wake
 * doorbells become a short nanosleep poll (correct-first: the wake
 * protocol's CAS/ring machinery in actors.c is untouched; a futex per
 * hart is the obvious upgrade), timers are no-ops (fuel preemption
 * still bounds every actor's slice; the deadlock detector samples on
 * every poll wakeup instead of a timer pace).
 *
 * The MMIO device surface (reg8/reg32/read/write) is deliberately
 * ABSENT -- a hosted image has no bus; see stubs.c.  The device TABLE
 * survives (net.c registers "net"): discovery-by-name is the portable
 * contract, per the devtable essay in runtime/virt/hal.c.
 */
#include "fpr.h"
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

void hal_putc(char c) {
  ssize_t r = write(1, &c, 1);
  (void)r; /* console loss is not an image error */
}

void hal_poweroff(int code) { exit(code); }
void fpr_park(void) { pause(); } /* FPR_PARK: unreachable after exit() */

/* ---- sleep/wake + timer obligations (actors.c) ---------------------- */
void hal_wfi_enable(void) {}
void hal_wfi(void) { /* poll pace; every path re-checks its rings after */
  struct timespec ts = {0, 200 * 1000};
  nanosleep(&ts, 0);
}
void hal_ipi_send(uw hart) { (void)hart; } /* wakeups land on the next poll */
void hal_ipi_clear(uw hart) { (void)hart; }
void hal_timer_park(uw hart) { (void)hart; }
void hal_timer_arm(uw hart, uw ticks) { (void)hart; (void)ticks; }

/* ---- first-activation contexts for ctx_x64.S / ctx_a64.S ------------ */
void fpr_ctx_fabricate(uw *ctx, void (*entry)(void), uw stack_top16,
                       fpr_hart_t *owner) {
  (void)owner; /* posix: the hart pointer is per-thread TLS, not a ctx slot */
  ctx[0] = (uw)(uintptr_t)entry;
#if defined(__x86_64__)
  /* jmp-entry must look like post-call state: entry %rsp == 8 mod 16,
   * or gcc's 16-byte spills inside the trampoline are misaligned */
  ctx[1] = stack_top16 - 8;
#else
  ctx[1] = stack_top16;
#endif
}
