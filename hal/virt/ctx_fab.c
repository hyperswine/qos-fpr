/* ctx_fab.c (virt) — fabricate a first-activation context for ctx.S:
 * ra = the trampoline, sp = the fresh stack, tp = the owner hart. */
#include "fpr.h"
void fpr_ctx_fabricate(uw *ctx, void (*entry)(void), uw stack_top16,
                       fpr_hart_t *owner) {
  ctx[0] = (uw)(uintptr_t)entry;
  ctx[1] = stack_top16;
  ctx[3] = (uw)owner; /* tp */
}
