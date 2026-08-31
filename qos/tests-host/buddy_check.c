/* buddy_check.c -- host-side proof of buddy.c, including the realloc
 * op (the third leg of the alloc/realloc/dealloc contract,
 * docs/MEMORY.md).  Run via tests-host/buddy-check.sh, which compiles
 * buddy.c with FPR_BUDDY_MIN=4096 so every path is cheap to reach.
 *
 * Legs:
 *   inplace  -- a 4-block arena, one order-2 root: grow order0->1->2
 *               stays AT THE SAME ADDRESS (buddy-absorb), overgrow
 *               refuses with the original intact, shrink returns the
 *               upper halves (a fresh alloc succeeds again)
 *   copy     -- a live neighbor blocks in-place growth: realloc moves,
 *               payload byte-identical, neighbor untouched
 *   stress   -- randomized alloc/realloc/free with per-slot fill
 *               patterns; ends with free-bytes exactly restored
 */
#include "fpr.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MIN ((uw)4096) /* must match -DFPR_BUDDY_MIN in buddy-check.sh */
static uw usable(int order) { return (MIN << order) - sizeof(uw); }

static int fails;
static void ck(int ok, const char *what) {
  printf("  %s %s\n", ok ? "ok " : "FAIL", what);
  if (!ok) fails++;
}

static void leg_inplace(void) {
  void *arena = aligned_alloc(MIN, 4 * MIN);
  buddy_init(arena, 4 * MIN);
  char *a = buddy_alloc(usable(0));
  ck(a != 0, "inplace: order-0 alloc");
  memset(a, 0x5a, usable(0));
  char *b = buddy_realloc(a, usable(1));
  ck(b == a, "inplace: grow 0->1 absorbs the free buddy, same address");
  char *c = buddy_realloc(b, usable(2));
  ck(c == b, "inplace: grow 1->2 same address (whole arena)");
  ck(c && c[100] == 0x5a, "inplace: payload survives in-place growth");
  ck(buddy_realloc(c, usable(3)) == 0, "inplace: overgrow refused (NULL)");
  ck(buddy_block_usable_size(c) == usable(2),
     "inplace: original intact after refusal");
  char *d = buddy_realloc(c, usable(0));
  ck(d == c, "inplace: shrink 2->0 same address");
  ck(buddy_alloc(usable(0)) != 0, "inplace: shrink returned the halves");
  free(arena);
}

static void leg_copy(void) {
  void *arena = aligned_alloc(MIN, 4 * MIN);
  buddy_init(arena, 4 * MIN);
  char *a = buddy_alloc(usable(0));
  char *b = buddy_alloc(usable(0)); /* the buddy above a: blocks growth */
  ck(a && b && b != a, "copy: two order-0 neighbors");
  memset(a, 0x11, usable(0));
  memset(b, 0x22, usable(0));
  char *a2 = buddy_realloc(a, usable(1));
  ck(a2 != 0 && a2 != a, "copy: blocked growth moves the block");
  ck(a2 && a2[7] == 0x11 && a2[usable(0) - 1] == 0x11,
     "copy: payload byte-identical after the move");
  ck(b[7] == 0x22, "copy: neighbor untouched");
  char *n = buddy_realloc(0, usable(0));
  ck(n != 0, "copy: realloc(NULL) allocates");
  free(arena);
}

static void leg_stress(void) {
  enum { NSLOT = 24, ROUNDS = 20000 };
  void *arena = aligned_alloc(MIN, 64 * MIN);
  buddy_init(arena, 64 * MIN);
  uw base_free = buddy_free_bytes();
  struct { char *p; uw n; } slot[NSLOT] = {0};
  srand(1234);
  for (int r = 0; r < ROUNDS; r++) {
    int i = rand() % NSLOT;
    uw n = (uw)(rand() % (int)(4 * MIN)) + 1;
    if (!slot[i].p) {
      char *p = buddy_alloc(n);
      if (!p) continue; /* exhaustion is a legal answer */
      memset(p, i + 1, n);
      slot[i].p = p; slot[i].n = n;
    } else if (rand() % 3) {
      uw keep = slot[i].n < n ? slot[i].n : n;
      char *p = buddy_realloc(slot[i].p, n);
      if (!p) continue; /* original intact by contract */
      for (uw k = 0; k < keep; k++)
        if (p[k] != (char)(i + 1)) {
          ck(0, "stress: payload lost across realloc");
          printf("    slot %d round %d byte %lu\n", i, r, (unsigned long)k);
          goto out;
        }
      memset(p, i + 1, n);
      slot[i].p = p; slot[i].n = n;
    } else {
      buddy_free(slot[i].p);
      slot[i].p = 0;
    }
  }
  ck(1, "stress: 20000 rounds, every payload intact");
out:
  for (int i = 0; i < NSLOT; i++)
    if (slot[i].p) buddy_free(slot[i].p);
  ck(buddy_free_bytes() == base_free,
     "stress: free bytes exactly restored (coalescing complete)");
  free(arena);
}

int main(void) {
  printf("== buddy_check ==\n");
  leg_inplace();
  leg_copy();
  leg_stress();
  if (fails) { printf("buddy_check: %d FAILURE(S)\n", fails); return 1; }
  printf("buddy_check: ALL LEGS PASS\n");
  return 0;
}
