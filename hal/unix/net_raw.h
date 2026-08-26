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

/* net: MULTI-CONNECTION, poll-driven (the virt contract, abi v6).
 * Connections are numbered 1..QOS_NET_MAXCONN; 0 is never a valid id.
 * poll:  pump (accept + read every open connection); returns the id
 *        of a connection with buffered rx bytes, else 0.  Ids rotate
 *        fairly so one busy peer cannot starve the rest.
 * read:  drain up to cap buffered bytes of connection id.
 * write: blocking-full on id; returns bytes placed (< len = peer
 *        closed under us; 0 = no such connection).
 * close: drop connection id, keep listening.
 * setup binds/listens on FPR_PORT (default 8000); poll/read/write on a
 * never-setup listener report no-connection rather than faulting. */
#define QOS_NET_MAXCONN 8
void qos_netraw_setup(void); /* idempotent; exits loudly on bind failure */
int64_t qos_netraw_poll(void);
int64_t qos_netraw_read(int64_t id, char *dst, uint64_t cap);
int64_t qos_netraw_write(int64_t id, const char *src, uint64_t len);
int64_t qos_netraw_close(int64_t id);

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
