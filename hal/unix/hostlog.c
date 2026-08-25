/* hostlog.c -- see hostlog.h for the contract. */
#include "hostlog.h"

#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

/* pending lines from before the app registered its ring: replayed in
 * order at registration.  A rolling window -- if boot somehow emits
 * more than PEND_N lines, the OLDEST drop (stderr kept them all). */
#define PEND_N 32
#define PEND_W 160
static char pend[PEND_N][PEND_W];
static uint64_t pend_seq; /* total ever; live window = last PEND_N */
static void (*g_sink)(const char *line, uint64_t n);
static pthread_mutex_t hl_mu = PTHREAD_MUTEX_INITIALIZER;

void qos_hostlog(const char *fmt, ...) {
  char line[PEND_W];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(line, sizeof line, fmt, ap);
  va_end(ap);
  size_t n = strlen(line);
  while (n && line[n - 1] == '\n') line[--n] = 0; /* ring lines are unterminated */
  /* stderr always: journald keeps its record regardless of the app */
  fprintf(stderr, "%s\n", line);
  pthread_mutex_lock(&hl_mu);
  if (g_sink) {
    void (*s)(const char *, uint64_t) = g_sink;
    pthread_mutex_unlock(&hl_mu);
    s(line, n);
    return;
  }
  memcpy(pend[pend_seq % PEND_N], line, n + 1);
  pend_seq++;
  pthread_mutex_unlock(&hl_mu);
}

void qos_hostlog_set_sink(void (*sink)(const char *line, uint64_t n)) {
  pthread_mutex_lock(&hl_mu);
  g_sink = sink;
  uint64_t have = pend_seq < PEND_N ? pend_seq : PEND_N;
  uint64_t first = pend_seq - have;
  pthread_mutex_unlock(&hl_mu);
  if (!sink) return;
  /* replay outside the mutex: the sink takes the app's own locks */
  for (uint64_t i = first; i < first + have; i++) {
    const char *l = pend[i % PEND_N];
    sink(l, (uint64_t)strlen(l));
  }
}
