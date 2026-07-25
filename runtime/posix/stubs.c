/* stubs.c (posix) — the not-yet-hosted runtime surface.
 *
 * Two kinds of stub, on purpose:
 *  - fuel: generated code decrements h->fuel unconditionally (that IS
 *    the codegen contract), so hosted single-thread execution just
 *    refills it -- preemption is the scheduler's concern and there is
 *    no scheduler here yet.
 *  - actors/devices: panic with the capability's name.  The prelude
 *    unit links against the full Actor/Mmio contract, so the symbols
 *    must exist; a program that CALLS them on the posix HAL gets an
 *    honest runtime panic instead of a silent wrong answer.
 */
#include "fpr.h"

void fpr_fuel_exhausted(void) { fpr_hart()->fuel = 1u << 30; }

uw fpr_current_id(void) { return 0; }

/* referenced by fpr_rt_init (linked, not called on posix) */
void fpr_actors_init(void) {}
void fpr_hart_main(int id) { (void)id; fpr_cpanic("posix: no hart loop"); }
void fpr_hart_secondary(int id) { (void)id; fpr_cpanic("posix: no hart loop"); }

#define STUB1(sym, msg) \
  static V sym##_impl(V a) { (void)a; fpr_cpanic(msg); return 0; } \
  FPR_FN(sym, sym##_impl, 1)
#define STUB2(sym, msg) \
  static V sym##_impl(V a, V b) { (void)a; (void)b; fpr_cpanic(msg); return 0; } \
  FPR_FN(sym, sym##_impl, 2)

STUB1(fpr_g_spawn, "posix HAL: spawn (actors not hosted yet)");
STUB2(fpr_g_spawnOn, "posix HAL: spawnOn (actors not hosted yet)");
STUB2(fpr_g_send, "posix HAL: send (actors not hosted yet)");
STUB1(fpr_g_receive, "posix HAL: receive (actors not hosted yet)");
STUB2(fpr_g_receiveFrom, "posix HAL: receiveFrom (actors not hosted yet)");
STUB1(fpr_g_receiveRes, "posix HAL: receiveRes (actors not hosted yet)");
STUB1(fpr_g_yield, "posix HAL: yield (actors not hosted yet)");
STUB1(fpr_g_kill, "posix HAL: kill (actors not hosted yet)");
STUB1(fpr_g_myself, "posix HAL: myself (actors not hosted yet)");
STUB1(fpr_g_hartId, "posix HAL: hartId (actors not hosted yet)");
STUB1(fpr_g_harts, "posix HAL: harts (actors not hosted yet)");
STUB1(fpr_g_fuelQuantum, "posix HAL: fuelQuantum (actors not hosted yet)");
STUB1(fpr_g_fuelPreempts, "posix HAL: fuelPreempts (actors not hosted yet)");
STUB1(fpr_g_read, "posix HAL: read (no MMIO on a hosted image)");
STUB2(fpr_g_write, "posix HAL: write (no MMIO on a hosted image)");

/* actors.c isn't linked (its slab-refill path is portable but its
 * scheduler isn't yet); satisfy the two symbols runtime.c takes from
 * it.  h->current is always 0 hosted, so fpr_acb_pool is unreachable. */
volatile int fpr_is_process = 0;
fpr_pool_t *fpr_acb_pool(struct fpr_acb *a) { (void)a; fpr_cpanic("posix: acb pool"); return 0; }
