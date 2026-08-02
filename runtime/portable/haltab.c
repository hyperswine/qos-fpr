/* haltab.c -- the Initializer stage's product: the HAL table.
 *
 * The bootstrap design's stage-1 job on this "board": build the HAL as
 * in-memory C ABI functions wrapping the platform's actual operations,
 * delivered to the loaded program as one table pointer.  The board is
 * libc; the operations are the SAME raw tier posix.bin co-compiles
 * (runtime/posix/net_raw.c) -- one implementation, two dispatch
 * disciplines, which is the whole point of the split.
 *
 * Unmapped-register faults are honest and immediate, matching the
 * co-compiled HAL's fpr_cpanic behavior: the app named a capability
 * this table does not carry, and continuing would lie about it. */
#include "../qosapp/qos_abi.h"
#include "../posix/net_raw.h"
#ifdef QOSP_GFX
#include "../posix/gfx_raw.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

static void t_putc(char c) {
  ssize_t r = write(1, &c, 1);
  (void)r; /* console loss is not an image error */
}

static void t_poweroff(int code) { exit(code); }

static void t_wfi(void) { /* poll pace, posix hal.c's value */
  static int wfi_count = 0;
  if ((++wfi_count % 1000) == 0) {
    fprintf(stderr, "[wfi %d]\n", wfi_count); fflush(stderr);
  }
  struct timespec ts = {0, 200 * 1000};
  nanosleep(&ts, 0);
} 

static uint64_t t_mmio_read(uint64_t addr, uint32_t width) {
  (void)width;
  uint64_t out;
  if (qos_mmioraw_read(addr, &out) < 0) {
    fprintf(stderr, "qosp HAL: app read an unmapped register (0x%llx)\n",
            (unsigned long long)addr);
    exit(1);
  }
  return out;
}

static void t_mmio_write(uint64_t addr, uint64_t v, uint32_t width) {
  (void)width;
  if (qos_mmioraw_write(addr, v) < 0) {
    fprintf(stderr, "qosp HAL: app wrote an unmapped register (0x%llx)\n",
            (unsigned long long)addr);
    exit(1);
  }
}

static qos_hal_t the_table = {
    .version = QOS_ABI_VERSION,
    .nharts = 1, /* main.c raises this (and installs start_hart) at boot */
    .putc = t_putc,
    .poweroff = t_poweroff,
    .wfi = t_wfi,
    .mmio_read = t_mmio_read,
    .mmio_write = t_mmio_write,
    .dev_lookup = qos_devraw_lookup,
    .net_poll = qos_netraw_poll,
    .net_read = qos_netraw_read,
    .net_write = qos_netraw_write,
    .net_close = qos_netraw_close,
#ifdef QOSP_GFX
    .gfx_init = gfx_init,
    .gfx_render = gfx_render_scene,
    .gfx_save_ppm = gfx_save_ppm,
    .gfx_input_poll = gfx_input_poll,
#endif /* else: NULL -- the app-side shim reports the missing capability */
};

const qos_hal_t *qosp_hal_table(void) { return &the_table; }

/* multi-hart wiring (ABI v2): the resolved live count and the host's
 * thread-creation callback, both owned by main.c */
void qosp_hal_set_smp(uint64_t nharts,
                      int (*sh)(uint64_t, void (*)(uint64_t))) {
  the_table.nharts = nharts;
  the_table.start_hart = sh;
}
