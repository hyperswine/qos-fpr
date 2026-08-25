/* net_raw.c -- the raw hosted device tier (see net_raw.h).  This is
 * net.c's I/O logic verbatim, minus every fpr.h type: the extraction
 * exists so qosp (runtime/portable) and posix.bin share ONE socket and
 * pseudo-bus implementation instead of drifting copies. */
#include "net_raw.h"
#include "hostlog.h"

#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/socket.h>
#include <unistd.h>

#define RXCAP 8192

static int lfd = -1, cfd = -1;
static uint8_t rx[RXCAP];
static uint32_t rxlen;

void qos_netraw_setup(void) {
  if (lfd >= 0) return;
  int port = 8000;
  const char *p = getenv("FPR_PORT");
  if (p && *p) port = atoi(p);
  lfd = socket(AF_INET, SOCK_STREAM, 0);
  if (lfd < 0) { qos_hostlog("net: socket"); exit(2); }
  int one = 1;
  setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  struct sockaddr_in a;
  memset(&a, 0, sizeof a);
  a.sin_family = AF_INET;
  a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  a.sin_port = htons((uint16_t)port);
  /* restarting a server across TIME_WAIT is normal, not an error */
  setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  if (bind(lfd, (struct sockaddr *)&a, sizeof a)) {
    qos_hostlog("net: bind (port busy?)");
    exit(2);
  }
  if (listen(lfd, 4)) { qos_hostlog("net: listen"); exit(2); }
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

int64_t qos_netraw_poll(void) {
  net_pump();
  if (cfd < 0) return 0;
  return rxlen ? 2 : 1;
}

int64_t qos_netraw_read(char *dst, uint64_t cap) {
  net_pump();
  uint32_t n = rxlen > cap ? (uint32_t)cap : rxlen;
  memcpy(dst, rx, n);
  if (n) {
    memmove(rx, rx + n, rxlen - n);
    rxlen -= n;
  }
  return (int64_t)n;
}

int64_t qos_netraw_write(const char *src, uint64_t len) {
  if (cfd < 0) return 0;
  uint64_t off = 0;
  while (off < len) {
    ssize_t n = write(cfd, src + off, len - off);
    if (n > 0) { off += (uint64_t)n; continue; }
    if (n < 0 && errno == EAGAIN) continue; /* spin: PoC blocking send */
    return (int64_t)off; /* peer closed under us */
  }
  return (int64_t)len;
}

int64_t qos_netraw_close(void) {
  if (cfd >= 0) { close(cfd); cfd = -1; }
  rxlen = 0;
  return 0;
}

/* ---- the register tier: a 16550-ish uart over stdio ----------------
 * (net.c's model, moved whole: LSR always reports THR empty; DR
 * follows a nonblocking stdin peek; mtime is 10MHz-ish ticks from
 * CLOCK_MONOTONIC at virt's offset.) */
#define CLINT_MTIME (QOS_CLINT_BASE + 49144) /* virt's mtime offset, honored */
#define UART_THR (QOS_UART_BASE + 0)
#define UART_RBR (QOS_UART_BASE + 0)
#define UART_LCR (QOS_UART_BASE + 3)
#define UART_LSR (QOS_UART_BASE + 5)
#define UART_SCR (QOS_UART_BASE + 7)

static int stdin_pending = -1;
static uint8_t uart_lcr, uart_scr;

static void stdin_peek(void) {
  if (stdin_pending >= 0) return;
  int fl = fcntl(0, F_GETFL);
  fcntl(0, F_SETFL, fl | O_NONBLOCK);
  uint8_t b;
  if (read(0, &b, 1) == 1) stdin_pending = b;
  fcntl(0, F_SETFL, fl);
}

int qos_mmioraw_read(uint64_t addr, uint64_t *out) {
  switch (addr) {
    case UART_LCR:
      *out = uart_lcr;
      return 0;
    case UART_LSR: {
      stdin_peek();
      *out = 0x20u | (stdin_pending >= 0 ? 0x01u : 0u); /* THRE | DR */
      return 0;
    }
    case UART_SCR:
      *out = uart_scr;
      return 0;
    case CLINT_MTIME: {
      struct timespec ts;
      clock_gettime(CLOCK_MONOTONIC, &ts);
      *out = (uint64_t)ts.tv_sec * 10000000u + (uint64_t)ts.tv_nsec / 100u;
      return 0;
    }
    case UART_RBR: {
      stdin_peek();
      if (stdin_pending < 0) { *out = 0; return 0; }
      *out = (uint64_t)stdin_pending;
      stdin_pending = -1;
      return 0;
    }
    default:
      return -1;
  }
}

int qos_mmioraw_write(uint64_t addr, uint64_t v) {
  switch (addr) {
    case UART_THR: {
      char c = (char)v;
      ssize_t r = write(1, &c, 1);
      (void)r;
      return 0;
    }
    case UART_LCR:
      uart_lcr = (uint8_t)v;
      return 0;
    case UART_SCR:
      uart_scr = (uint8_t)v;
      return 0;
    default:
      return -1;
  }
}

/* ---- device discovery: the same table shape as virt hal.c ----------- */
typedef struct {
  const char *name;
  uint64_t base;
  void (*setup)(void);
} rawdev_t;

void qos_blkraw_setup(void); /* blk_raw.h -- linked wherever this table is */

static rawdev_t rawdevs[] = {
    {"uart", QOS_UART_BASE, 0},
    {"clint", QOS_CLINT_BASE, 0},
    {"net", 0, qos_netraw_setup},
    {"blk", 0, qos_blkraw_setup},
};
#define NRAWDEVS (sizeof(rawdevs) / sizeof(rawdevs[0]))

int qos_devraw_lookup(const char *name, uint64_t len, uint64_t *base) {
  for (size_t i = 0; i < NRAWDEVS; i++) {
    const char *n = rawdevs[i].name;
    size_t j = 0;
    for (; j < len && n[j] && n[j] == name[j]; j++) {}
    if (j == len && n[j] == '\0') {
      if (rawdevs[i].setup) rawdevs[i].setup();
      *base = rawdevs[i].base;
      return 1;
    }
  }
  return 0;
}
