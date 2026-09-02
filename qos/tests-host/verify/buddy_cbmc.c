/* buddy_cbmc.c -- CBMC harness: a 4-block arena, one nondeterministic
 * alloc/free cycle, the allocator's contract as assertions (inside the
 * arena, usable >= request, free-bytes conservation) plus CBMC's own
 * bounds/pointer checks on every path.  ~5 min of SAT; see verify.sh. */
#include "fpr.h"
#define MIN 64u
#define NB 4u
static char arena[MIN * NB] __attribute__((aligned(64)));
uw nondet_uw(void);
int main(void) {
  buddy_init(arena, MIN * NB);
  uw free0 = buddy_free_bytes();
  uw n = nondet_uw(); __CPROVER_assume(n >= 1 && n <= 2 * MIN);
  void *p = buddy_alloc(n);
  if (p) {
    __CPROVER_assert((char *)p >= arena && (char *)p + n <= arena + MIN * NB, "inside arena");
    __CPROVER_assert(buddy_block_usable_size(p) >= n, "usable covers request");
    buddy_free(p);
  }
  __CPROVER_assert(buddy_free_bytes() == free0, "conservation");
  return 0;
}
