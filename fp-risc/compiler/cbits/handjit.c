/* handjit.c — executable memory for the hand-rolled JIT tier.
 * One job: take emitted bytes, return a callable address.
 * W^X honored: RW during copy, RX after. */
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>

void *hj_alloc(const uint8_t *buf, long n) {
  long sz = (n + 4095) & ~4095L;
  void *p = mmap(0, sz, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (p == MAP_FAILED) return 0;
  memcpy(p, buf, n);
  if (mprotect(p, sz, PROT_READ | PROT_EXEC) != 0) return 0;
  return p;
}
