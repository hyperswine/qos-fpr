/* hal.c (qosapp) -- the app image's HAL: every obligation the runtime
 * has (hal_putc, the wfi/ipi/timer doorbells, ctx fabrication) and
 * every fpr_g_ device capability the image exports (device, the
 * register tier, net) dispatches through the qos_hal_t table the boot
 * record delivered.  This file plus entry.c is the whole platform
 * surface of a QOS Portable app: no libc, no syscalls, no link-time
 * binding to the host -- "the HAL is a table delivered as a C pointer,
 * called like regular C functions" (the bootstrap design), and the
 * safety mechanisms live in the FPRISC layer above, not here.
 */
#include "fpr.h"
#include "qos_abi.h"

extern const qos_hal_t *qos_hal; /* entry.c installs it first thing */

/* ---- the hal_* obligations (actors.c / runtime.c contract) ---------- */
void hal_putc(char c) { qos_hal->putc(c); }
void hal_poweroff(int code) { qos_hal->poweroff(code); }
void fpr_park(void) {
  for (;;) qos_hal->wfi();
}

void hal_wfi_enable(void) {}
void hal_wfi(void) { qos_hal->wfi(); } /* poll pace; rings re-checked after */
void hal_ipi_send(uw hart) { (void)hart; } /* single-hart image */
void hal_ipi_clear(uw hart) { (void)hart; }
void hal_timer_park(uw hart) { (void)hart; }
void hal_timer_arm(uw hart, uw ticks) { (void)hart; (void)ticks; }

/* ---- first-activation contexts for ctx_x64.S ------------------------
 * (posix hal.c's rule, verbatim: jmp-entry must look like post-call
 * state -- entry %rsp == 8 mod 16 -- or gcc's 16-byte spills inside
 * the trampoline are misaligned.) */
void fpr_ctx_fabricate(uw *ctx, void (*entry)(void), uw stack_top16,
                       fpr_hart_t *owner) {
  (void)owner; /* the hart pointer is the plain global, not a ctx slot */
  ctx[0] = (uw)(uintptr_t)entry;
  ctx[1] = stack_top16 - 8;
}

/* ---- the register tier (stubs.c's mkreg handlers, table-backed) ----- */
static V mkreg(V dev, V off, uint32_t width) {
  if (ISINT(dev) || TID(dev) != T_DEVICE) fpr_cpanic("reg: not a Device");
  if (!ISINT(off)) fpr_cpanic("reg: offset not an Int");
  reg_t *r = (reg_t *)fpr_alloc(sizeof(reg_t));
  r->tid = T_REGISTER;
  r->var = width;
  r->addr = ((fpr_dev_t *)dev)->base + (uw)UNTAG(off);
  return (V)r;
}
static V h_reg8(V d, V o) { return mkreg(d, o, 1); }
static V h_reg32(V d, V o) { return mkreg(d, o, 4); }
static V h_read(V rv) {
  if (ISINT(rv) || TID(rv) != T_REGISTER) fpr_cpanic("read: not a Register");
  reg_t *r = (reg_t *)rv;
  return TAG((sw)qos_hal->mmio_read(r->addr, r->var));
}
static V h_write(V rv, V x) {
  if (ISINT(rv) || TID(rv) != T_REGISTER) fpr_cpanic("write: not a Register");
  reg_t *r = (reg_t *)rv;
  uw v;
  if (ISINT(x)) v = (uw)UNTAG(x);
  else if (TID(x) == T_BITS) v = ((bits_t *)x)->val;
  else fpr_cpanic("write: value must be Int or Array Bit");
  qos_hal->mmio_write(r->addr, v, r->var);
  return (V)&fpr_unit;
}
FPR_FN(fpr_g_reg8, h_reg8, 2);
FPR_FN(fpr_g_reg32, h_reg32, 2);
FPR_FN(fpr_g_read, h_read, 1);
FPR_FN(fpr_g_write, h_write, 2);

/* ---- device discovery through the table ----------------------------- */
static fpr_dev_t devcells[8];
static char devnames[8][16];
static int ndevcells;

static V h_device(V nameStr) {
  if (ISINT(nameStr) || TID(nameStr) != T_STR)
    fpr_cpanic("device: name must be a String");
  str_t *s = (str_t *)nameStr;
  for (int i = 0; i < ndevcells; i++) {
    const char *n = devnames[i];
    uw j = 0;
    for (; j < s->len && n[j] && n[j] == (char)s->bytes[j]; j++) {}
    if (j == s->len && n[j] == '\0') return (V)&devcells[i];
  }
  uint64_t base;
  if (qos_hal->dev_lookup((const char *)s->bytes, s->len, &base) &&
      ndevcells < 8 && s->len < 16) {
    fpr_dev_t *d = &devcells[ndevcells];
    d->tid = T_DEVICE;
    d->var = 0;
    d->base = (uw)base;
    for (uw k = 0; k < s->len; k++) devnames[ndevcells][k] = (char)s->bytes[k];
    devnames[ndevcells][s->len] = 0;
    ndevcells++;
    return (V)d;
  }
  fpr_cpanic("device: capability not granted by this host's HAL table");
  return 0;
}
FPR_FN(fpr_g_device, h_device, 1);

/* ---- net: the posix contract, table transport ----------------------- */
static V h_netPoll(V d) {
  (void)d;
  return TAG((sw)qos_hal->net_poll());
}
static V h_netRead(V d) {
  (void)d;
  char buf[1024];
  int64_t n = qos_hal->net_read(buf, sizeof buf);
  return (V)fpr_mkstr((const uint8_t *)buf, (uw)n);
}
static V h_netWrite(V d, V sv) {
  (void)d;
  if (ISINT(sv) || TID(sv) != T_STR) fpr_cpanic("netWrite: not a String");
  str_t *s = (str_t *)sv;
  return TAG((sw)qos_hal->net_write((const char *)s->bytes, s->len));
}
static V h_netClose(V d) {
  (void)d;
  return TAG((sw)qos_hal->net_close());
}
FPR_FN(fpr_g_netPoll, h_netPoll, 1);
FPR_FN(fpr_g_netRead, h_netRead, 1);
FPR_FN(fpr_g_netWrite, h_netWrite, 2);
FPR_FN(fpr_g_netClose, h_netClose, 1);

/* ---- gfx: the nullable table tier ----------------------------------
 * The renderer (and Mesa's dynamic linking) lives in the HOST image --
 * the one boundary the static philosophy concedes, kept concentrated
 * there; the app stays freestanding.  A host built without GFX=1
 * leaves these entries NULL, and calling one is a missing capability,
 * reported the same honest way stubs.c reports the bus tier. */
static void need_gfx(void) {
  if (!qos_hal->gfx_init)
    fpr_cpanic("gfx: capability not granted by this host (build qosp with GFX=1)");
}
static V h_glInit(V wv, V hv) {
  need_gfx();
  if (!ISINT(wv) || !ISINT(hv)) fpr_cpanic("glInit: w h must be Ints");
  qos_hal->gfx_init((int)UNTAG(wv), (int)UNTAG(hv));
  return TAG(1);
}
static V h_glRender(V scene) {
  need_gfx();
  int64_t draws, dynBytes;
  qos_hal->gfx_render((uint64_t)scene, &draws, &dynBytes);
  V *r = (V *)fpr_alloc(24);
  ((hdr_t *)r)->tid = 4; ((hdr_t *)r)->var = 0; /* (draws, dynBytes) */
  r[1] = TAG((sw)draws); r[2] = TAG((sw)dynBytes);
  return (V)r;
}
static V h_glSavePpm(V pathv) {
  need_gfx();
  if (ISINT(pathv) || TID(pathv) != T_STR) fpr_cpanic("glSavePpm: path must be a String");
  str_t *p = (str_t *)pathv;
  char path[256];
  uw n = p->len < sizeof path - 1 ? p->len : sizeof path - 1;
  for (uw i = 0; i < n; i++) path[i] = (char)p->bytes[i];
  path[n] = 0;
  return TAG(qos_hal->gfx_save_ppm(path));
}
static V h_inputPoll(V u) {
  (void)u;
  need_gfx();
  /* uniform shape (Mod.resolve convention): (0, 0, 0) = no event */
  int64_t kind = 0, a = 0, c = 0;
  qos_hal->gfx_input_poll(&kind, &a, &c);
  V *t = (V *)fpr_alloc(32);
  ((hdr_t *)t)->tid = 5; ((hdr_t *)t)->var = 0; /* triple */
  t[1] = TAG((sw)kind); t[2] = TAG((sw)a); t[3] = TAG((sw)c);
  return (V)t;
}
FPR_FN(fpr_g_glInit, h_glInit, 2);
FPR_FN(fpr_g_glRender, h_glRender, 1);
FPR_FN(fpr_g_glSavePpm, h_glSavePpm, 1);
FPR_FN(fpr_g_inputPoll, h_inputPoll, 1);
