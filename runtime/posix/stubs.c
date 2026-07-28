/* stubs.c (posix) — capabilities the hosted HAL does not grant.
 *
 * Only the MMIO tier lives here now (the actor surface is the real
 * runtime/core/actors.c).  Programs that link these and never call
 * them cost nothing; programs that CALL them get an honest panic
 * naming the missing capability.  Programs whose own code references
 * capabilities with no stub at all (Pin.*, bitsLE, ...) fail at LINK
 * time with the fpr_g_ name -- the image's imports are its capability
 * manifest, and the posix HAL simply doesn't export the bus tier.
 */
#include "fpr.h"

/* the register tier, backed by net.c's pseudo-address dispatch: the
 * SAME reg_t/T_REGISTER values as virt, a different "bus" behind them */
uw fpr_posix_mmio_read(uw addr, uint32_t width);
void fpr_posix_mmio_write(uw addr, uw v, uint32_t width);

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
  return TAG((sw)fpr_posix_mmio_read(r->addr, r->var));
}
static V h_write(V rv, V x) {
  if (ISINT(rv) || TID(rv) != T_REGISTER) fpr_cpanic("write: not a Register");
  reg_t *r = (reg_t *)rv;
  uw v;
  if (ISINT(x)) v = (uw)UNTAG(x);
  else if (TID(x) == T_BITS) v = ((bits_t *)x)->val;
  else fpr_cpanic("write: value must be Int or Array Bit");
  fpr_posix_mmio_write(r->addr, v, r->var);
  return (V)&fpr_unit;
}
FPR_FN(fpr_g_reg8, h_reg8, 2);
FPR_FN(fpr_g_reg32, h_reg32, 2);
FPR_FN(fpr_g_read, h_read, 1);
FPR_FN(fpr_g_write, h_write, 2);

/* the pin bus: absent hardware, present SYMBOLS.  The svc URL router
 * (mods/svc.fpr) references every route it can dispatch, so a hosted
 * image that merely LINKS the funnel must not fail on the pin tier --
 * the capability gate still refuses ungranted /pins first, and a
 * GRANTED /pins on a host with no pin bus gets the honest panic. */
static V h_pin_mode(V n, V m) { (void)n; (void)m; fpr_cpanic("Pin.mode: no pin bus on the posix HAL"); return (V)&fpr_unit; }
static V h_pin_write(V n, V v) { (void)n; (void)v; fpr_cpanic("Pin.write: no pin bus on the posix HAL"); return (V)&fpr_unit; }
static V h_pin_read(V n) { (void)n; fpr_cpanic("Pin.read: no pin bus on the posix HAL"); return (V)&fpr_unit; }
FPR_FN(fpr_g_Pin_x2emode, h_pin_mode, 2);
FPR_FN(fpr_g_Pin_x2ewrite, h_pin_write, 2);
FPR_FN(fpr_g_Pin_x2eread, h_pin_read, 1);
static V h_pin_wire(V n, V f) { (void)n; (void)f; fpr_cpanic("Pin.wire: no pin bus on the posix HAL"); return (V)&fpr_unit; }
FPR_FN(fpr_g_Pin_x2ewire, h_pin_wire, 2);
