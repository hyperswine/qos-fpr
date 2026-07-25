/* main.c (posix) — hosted bootstrap: what crt0.S + fpr_rt_init +
 * fpr_actors_init do on virt, minus everything a host OS already did
 * (stacks, clocks, "SMP release").  One hart, no scheduler: main runs
 * on the C stack, straight through, exactly like virt's actor 0 --
 * the actor layer arrives when ctx switching gets a posix backend
 * (ucontext or one-pthread-per-hart; see README).
 */
#include "fpr.h"

/* the hosted stand-in for tp: generated a64 code loads this global
 * where generated rv64 code reads tp (see compiler/A64.hs).  */
fpr_hart_t *fpr_posix_hart;

extern char _heap_start[], _heap_end[];
extern V fpr_fn_main(void);
void fpr_exit(V result); /* runtime.c: render + hal_poweroff(0) */

int main(void) {
  fpr_hart_t *h = &fpr_harts[0];
  h->id = 0;
  h->fuel = 1u << 30; /* refilled by the posix fpr_fuel_exhausted */
  fpr_posix_hart = h;
  fpr_set_tp(h); /* posix: same global, keeps runtime.c unchanged */
  uw minb = 64u * 1024;
  uw base = ((uw)_heap_start + (minb - 1)) & ~(uw)(minb - 1);
  buddy_init((void *)base, (uw)_heap_end - base);
  fpr_exit(fpr_fn_main());
}
