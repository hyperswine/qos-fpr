/* plic.c -- the QEMU virt PLIC, scoped to the wfi-wake design.
 *
 * This machine takes NO traps: mstatus.MIE stays off, so an enabled
 * interrupt PENDS, pops the hart out of wfi, and the hart loop
 * services it synchronously (the same discipline msip/mtip already
 * follow).  External device interrupts join that model here: a source
 * enabled for hart 0's M context raises MEIP, hart 0 wakes, and
 * actors.c's irq drain claims the source and delivers it to the actor
 * that bound it (Sys.irqBind) as a plain Int message.
 *
 * CLAIM-THEN-MASK: a level-triggered source (the 16550 keeps its line
 * high until RBR is read / THR refilled) would re-pend the instant we
 * completed it, and the drain loop would spin delivering the same irq
 * forever while the actor never got scheduled to service the device.
 * So the drain masks the source at claim time and the ACTOR re-arms
 * it (Sys.irqAck) after servicing the device -- if the line is still
 * high at re-arm, the gateway pends again and a fresh delivery
 * follows.  Exactly-once per ack, no storms.
 *
 * Only hart 0's M context is enabled (one drain point; deliveries
 * are ordinary sends, so the BOUND actor still runs wherever the
 * scheduler puts it -- donation and stealing included). */
#include "fpr.h"

#define PLIC_BASE 0x0c000000UL
#define PLIC_PRIO(src) ((volatile uint32_t *)(PLIC_BASE + 4u * (src)))
/* hart h's M-mode context is 2h on virt */
#define PLIC_ENABLE(ctx, src) \
  ((volatile uint32_t *)(PLIC_BASE + 0x2000UL + 0x80UL * (ctx) + 4UL * ((src) / 32)))
#define PLIC_THRESH(ctx) ((volatile uint32_t *)(PLIC_BASE + 0x200000UL + 0x1000UL * (ctx)))
#define PLIC_CLAIM(ctx) ((volatile uint32_t *)(PLIC_BASE + 0x200004UL + 0x1000UL * (ctx)))

#define CTX0 0 /* hart 0, M mode */

static void plic_set_enable(uw src, int on) {
  volatile uint32_t *e = PLIC_ENABLE(CTX0, src);
  uint32_t bit = 1u << (src % 32);
  if (on) *e |= bit;
  else *e &= ~bit;
}

void hal_irq_open(uw src) {
  *PLIC_PRIO(src) = 1;
  *PLIC_THRESH(CTX0) = 0;
  plic_set_enable(src, 1);
}

/* claim AND mask (see the essay); 0 = nothing pending */
sw hal_irq_claim(void) {
  uint32_t src = *PLIC_CLAIM(CTX0);
  if (!src) return 0;
  plic_set_enable(src, 0);
  *PLIC_CLAIM(CTX0) = src; /* complete now; the mask holds it off */
  return (sw)src;
}

/* the actor serviced the device: re-arm the source */
void hal_irq_ack(uw src) { plic_set_enable(src, 1); }
