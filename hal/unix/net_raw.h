/* net_raw.h -- the raw hosted device tier, factored out of net.c so it
 * has exactly two consumers with one implementation:
 *
 *   - runtime/posix/net.c: the CO-COMPILED hosted HAL (posix.bin) --
 *     thin V-typed FPR_FN wrappers over these calls.
 *   - runtime/portable/haltab.c: the QOS Portable host (qosp) -- these
 *     become entries in the qos_hal_t table an app image calls through.
 *
 * Plain C over libc, no fpr.h: nothing here knows about V values, so
 * it can live in an image with no FPRISC runtime at all.  Faults that
 * the co-compiled HAL turned into fpr_cpanic are RETURN CODES here;
 * each consumer escalates in its own idiom. */
#ifndef QOS_NET_RAW_H
#define QOS_NET_RAW_H

#include <stdint.h>

/* net: one connection at a time, poll-driven (the virt contract).
 * poll: 0 no conn, 1 open, 2 open + buffered rx.
 * read: drain up to cap bytes, returns count.
 * write: blocking-full, returns bytes actually placed (< len = peer
 *        closed under us).  close: drop the connection, keep listening.
 * setup binds/listens on FPR_PORT (default 8000); poll/read/write on a
 * never-setup listener report no-connection rather than faulting. */
void qos_netraw_setup(void); /* idempotent; exits loudly on bind failure */
int64_t qos_netraw_poll(void);
int64_t qos_netraw_read(char *dst, uint64_t cap);
int64_t qos_netraw_write(const char *src, uint64_t len);
int64_t qos_netraw_close(void);

/* the register tier: the uart/clint pseudo-bus (same addresses and
 * semantics as the virt console model).  0 = ok, -1 = unmapped. */
int qos_mmioraw_read(uint64_t addr, uint64_t *out);
int qos_mmioraw_write(uint64_t addr, uint64_t v);

/* device discovery by name (uart, clint, net); runs the device's
 * setup on first hit.  1 + *base filled, 0 = unknown. */
int qos_devraw_lookup(const char *name, uint64_t len, uint64_t *base);

/* the pseudo-bus addresses, shared with net.c's wrappers */
#define QOS_UART_BASE 0x1000u
#define QOS_CLINT_BASE 0x2000u

#endif
