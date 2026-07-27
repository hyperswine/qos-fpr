/* net.c (posix) — the virt net contract over BSD sockets.
 *
 * Byte-compatible with runtime/virt/net.c's FPRISC surface, so
 * programs like programs/httpd.fpr compile UNCHANGED into a hosted
 * static binary:
 *
 *   netPoll d    -> Int     pump; 0 = no conn, 1 = open, 2 = open + rx
 *   netRead d    -> String  drain up to 1 KiB of buffered payload
 *   netWrite d s -> Int     send s (blocking, full)
 *   netClose d   -> Int     close the connection, keep listening
 *
 * The I/O itself lives in net_raw.c (plain C, no fpr.h) so this file
 * is only the V-typed skin: the SAME raw tier backs qosp's HAL table
 * (runtime/portable/haltab.c) -- one socket implementation, two
 * dispatch disciplines.  Same honest simplifications as virt: ONE
 * connection at a time, actor-side polling; FPR_PORT picks the port.
 */
#include "fpr.h"
#include "net_raw.h"

static V h_netPoll(V d) {
  (void)d;
  return TAG((sw)qos_netraw_poll());
}

static V h_netRead(V d) {
  (void)d;
  char buf[1024];
  int64_t n = qos_netraw_read(buf, sizeof buf);
  return (V)fpr_mkstr((const uint8_t *)buf, (uw)n);
}

static V h_netWrite(V d, V sv) {
  (void)d;
  if (ISINT(sv) || TID(sv) != T_STR) fpr_cpanic("netWrite: not a String");
  str_t *s = (str_t *)sv;
  return TAG((sw)qos_netraw_write((const char *)s->bytes, s->len));
}

static V h_netClose(V d) {
  (void)d;
  return TAG((sw)qos_netraw_close());
}

FPR_FN(fpr_g_netPoll, h_netPoll, 1);
FPR_FN(fpr_g_netRead, h_netRead, 1);
FPR_FN(fpr_g_netWrite, h_netWrite, 2);
FPR_FN(fpr_g_netClose, h_netClose, 1);

/* ---- the register tier: stubs.c's mkreg handlers land here ---------- */
uw fpr_posix_mmio_read(uw addr, uint32_t width) {
  (void)width;
  uint64_t out;
  if (qos_mmioraw_read(addr, &out) < 0)
    fpr_cpanic("posix HAL: read of an unmapped register");
  return (uw)out;
}

void fpr_posix_mmio_write(uw addr, uw v, uint32_t width) {
  (void)width;
  if (qos_mmioraw_write(addr, v) < 0)
    fpr_cpanic("posix HAL: write of an unmapped register");
}

/* ---- device discovery: the same table shape as virt hal.c ----------- */
static fpr_dev_t devcells[8]; /* filled from raw lookups, stable addresses */
static const char *devnames[8];
static int ndevcells;

static V h_device(V nameStr) {
  if (ISINT(nameStr) || TID(nameStr) != T_STR) fpr_cpanic("device: name must be a String");
  str_t *s = (str_t *)nameStr;
  for (int i = 0; i < ndevcells; i++) { /* served before: same cell */
    const char *n = devnames[i];
    size_t j = 0;
    for (; j < s->len && n[j] && n[j] == (char)s->bytes[j]; j++) {}
    if (j == s->len && n[j] == '\0') return (V)&devcells[i];
  }
  uint64_t base;
  if (qos_devraw_lookup((const char *)s->bytes, s->len, &base) && ndevcells < 8) {
    fpr_dev_t *d = &devcells[ndevcells];
    d->tid = T_DEVICE;
    d->var = 0;
    d->base = (uw)base;
    /* the name outlives us: copy into a static pool for re-lookup */
    static char pool[8][16];
    uw n = s->len < 15 ? s->len : 15;
    for (uw k = 0; k < n; k++) pool[ndevcells][k] = (char)s->bytes[k];
    pool[ndevcells][n] = 0;
    devnames[ndevcells] = pool[ndevcells];
    ndevcells++;
    return (V)d;
  }
  fpr_cpanic("device: unknown device name (posix HAL grants: uart clint net)");
  return 0;
}
FPR_FN(fpr_g_device, h_device, 1);
