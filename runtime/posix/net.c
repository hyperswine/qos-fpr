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
 * Same honest simplifications as virt: ONE connection at a time (the
 * listener stays open; the next accept happens after netClose), and
 * the device is discovered by NAME through the same table shape as
 * virt hal.c -- `device "net"` calls net_setup, which binds/listens.
 * FPR_PORT (default 8000) picks the port, mirroring QEMU's hostfwd.
 *
 * Concurrency note: the fds are nonblocking and the pump runs inside
 * whichever actor calls netPoll/netRead -- the actor POLLS, exactly
 * like virt's virtio pump, so a server actor stays runnable and the
 * scheduler/deadlock-detector semantics carry over untouched.  A
 * blocking-accept service actor parked on a real syscall is the
 * System-actor upgrade path, not this PoC.
 */
#include "fpr.h"
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/socket.h>
#include <unistd.h>

#define RXCAP 8192

static int lfd = -1, cfd = -1;
static uint8_t rx[RXCAP];
static uint32_t rxlen;

static void net_setup(void) {
  if (lfd >= 0) return;
  int port = 8000;
  const char *p = getenv("FPR_PORT");
  if (p && *p) port = atoi(p);
  lfd = socket(AF_INET, SOCK_STREAM, 0);
  if (lfd < 0) fpr_cpanic("net: socket");
  int one = 1;
  setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  struct sockaddr_in a;
  memset(&a, 0, sizeof a);
  a.sin_family = AF_INET;
  a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  a.sin_port = htons((uint16_t)port);
  if (bind(lfd, (struct sockaddr *)&a, sizeof a)) fpr_cpanic("net: bind (port busy?)");
  if (listen(lfd, 4)) fpr_cpanic("net: listen");
  fcntl(lfd, F_SETFL, O_NONBLOCK);
}

static void net_pump(void) {
  if (lfd < 0) return;
  if (cfd < 0) {
    cfd = accept(lfd, 0, 0);
    if (cfd < 0) return; /* EAGAIN: nobody there */
    fcntl(cfd, F_SETFL, O_NONBLOCK);
    int one = 1;
    setsockopt(cfd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
  }
  while (rxlen < RXCAP) {
    ssize_t n = read(cfd, rx + rxlen, RXCAP - rxlen);
    if (n > 0) { rxlen += (uint32_t)n; continue; }
    if (n == 0 && rxlen == 0) { close(cfd); cfd = -1; } /* peer gone, drained */
    break; /* EAGAIN or buffered EOF: serve what we have */
  }
}

static V h_netPoll(V d) {
  (void)d;
  net_pump();
  if (cfd < 0) return TAG(0);
  return TAG(rxlen ? 2 : 1);
}

static V h_netRead(V d) {
  (void)d;
  net_pump();
  uint32_t n = rxlen > 1024 ? 1024 : rxlen;
  str_t *s = fpr_mkstr(rx, n);
  if (n) {
    memmove(rx, rx + n, rxlen - n);
    rxlen -= n;
  }
  return (V)s;
}

static V h_netWrite(V d, V sv) {
  (void)d;
  if (ISINT(sv) || TID(sv) != T_STR) fpr_cpanic("netWrite: not a String");
  if (cfd < 0) return TAG(0);
  str_t *s = (str_t *)sv;
  uw off = 0;
  while (off < s->len) {
    ssize_t n = write(cfd, s->bytes + off, s->len - off);
    if (n > 0) { off += (uw)n; continue; }
    if (n < 0 && errno == EAGAIN) continue; /* spin: PoC blocking send */
    return TAG((sw)off); /* peer closed under us */
  }
  return TAG((sw)s->len);
}

static V h_netClose(V d) {
  (void)d;
  if (cfd >= 0) { close(cfd); cfd = -1; }
  rxlen = 0;
  return TAG(0);
}

FPR_FN(fpr_g_netPoll, h_netPoll, 1);
FPR_FN(fpr_g_netRead, h_netRead, 1);
FPR_FN(fpr_g_netWrite, h_netWrite, 2);
FPR_FN(fpr_g_netClose, h_netClose, 1);

/* ---- the register tier: a 16550-ish uart over stdio ----------------
 * Programs written against the virt console (`device "uart"`, LSR
 * polling, THR writes) run unchanged: the "bus" is two pseudo-address
 * ranges dispatched by read/write below.  LSR always reports THR
 * empty; DR follows a nonblocking stdin peek.  This is the hosted
 * analogue of virt's MMIO -- same FPRISC contract, libc transport. */
#define CLINT_BASE 0x2000
#define CLINT_MTIME (CLINT_BASE + 49144) /* virt's mtime offset, honored */

#define UART_BASE 0x1000
#define UART_THR (UART_BASE + 0) /* write: a byte to stdout */
#define UART_RBR (UART_BASE + 0) /* read: a byte from stdin, 0 if none */
#define UART_LSR (UART_BASE + 5) /* read: line status */

static int stdin_pending = -1;
static void stdin_peek(void) {
  if (stdin_pending >= 0) return;
  int fl = fcntl(0, F_GETFL);
  fcntl(0, F_SETFL, fl | O_NONBLOCK);
  uint8_t b;
  if (read(0, &b, 1) == 1) stdin_pending = b;
  fcntl(0, F_SETFL, fl);
}

uw fpr_posix_mmio_read(uw addr, uint32_t width) {
  (void)width;
  switch (addr) {
    case UART_LSR: {
      stdin_peek();
      return 0x20u | (stdin_pending >= 0 ? 0x01u : 0u); /* THRE | DR */
    }
    case CLINT_MTIME: { /* mtime: 10MHz-ish ticks from CLOCK_MONOTONIC */
      struct timespec ts;
      clock_gettime(CLOCK_MONOTONIC, &ts);
      return (uw)ts.tv_sec * 10000000u + (uw)ts.tv_nsec / 100u;
    }
    case UART_RBR: {
      stdin_peek();
      if (stdin_pending < 0) return 0;
      uw b = (uw)stdin_pending;
      stdin_pending = -1;
      return b;
    }
    default:
      fpr_cpanic("posix HAL: read of an unmapped register");
      return 0;
  }
}

void fpr_posix_mmio_write(uw addr, uw v, uint32_t width) {
  (void)width;
  if (addr == UART_THR) { hal_putc((char)v); return; }
  fpr_cpanic("posix HAL: write of an unmapped register");
}

/* ---- device discovery: the same table shape as virt hal.c ----------- */
typedef struct {
  const char *name;
  fpr_dev_t dev;
  void (*setup)(void);
} devtable_entry_t;

static devtable_entry_t devtable[] = {
    {"uart", {T_DEVICE, 0, UART_BASE}, 0},
    {"clint", {T_DEVICE, 0, CLINT_BASE}, 0},
    {"net", {T_DEVICE, 0, 0}, net_setup},
};
#define NDEVICES (sizeof(devtable) / sizeof(devtable[0]))

static V h_device(V nameStr) {
  if (ISINT(nameStr) || TID(nameStr) != T_STR) fpr_cpanic("device: name must be a String");
  str_t *s = (str_t *)nameStr;
  for (size_t i = 0; i < NDEVICES; i++) {
    const char *n = devtable[i].name;
    size_t j = 0;
    for (; j < s->len && n[j] && n[j] == (char)s->bytes[j]; j++) {}
    if (j == s->len && n[j] == '\0') {
      if (devtable[i].setup) devtable[i].setup();
      return (V)&devtable[i].dev;
    }
  }
  fpr_cpanic("device: unknown device name (posix HAL grants: uart clint net)");
  return 0;
}
FPR_FN(fpr_g_device, h_device, 1);
