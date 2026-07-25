/* hal.c (posix) — the hosted HAL binding: libc IS the board.
 *
 * The virt HAL's contract, re-satisfied with the host OS's userspace:
 * console bytes go to stdout, poweroff is exit(2).  The device table /
 * MMIO surface (device/reg8/read/write) is deliberately ABSENT: a
 * hosted image has no bus, and any program that reaches for it gets a
 * link error naming exactly the capability the posix HAL doesn't
 * grant -- the same discoverable-symbol contract as everywhere else.
 */
#include <stdlib.h>
#include <unistd.h>

void hal_putc(char c) {
  ssize_t r = write(1, &c, 1);
  (void)r; /* console loss is not an image error */
}

void hal_poweroff(int code) { exit(code); }
