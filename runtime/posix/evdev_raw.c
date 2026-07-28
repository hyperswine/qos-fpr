/* evdev_raw.c -- see evdev_raw.h.  The reading discipline handles all
 * three source shapes with one code path: nonblocking reads into an
 * accumulation buffer (a FIFO or a slow real device may deliver a
 * partial record; a pre-baked file delivers many at once), records
 * consumed one per poll so an MVU tick sees at most one event. */
#include "evdev_raw.h"

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifdef __linux__
#include <linux/input.h>
#else
/* Not Linux: no evdev bus, but the RECORD FORMAT still works -- the fd
 * FPR_EVDEV names is a tools/kbdsim.py FIFO or a pre-baked event file
 * carrying these same fixed-layout records.  Defining the wire struct
 * locally makes the simulated-keyboard/replay tier portable (macOS
 * included); only the /dev/input/eventN real-device shape is Linux. */
#include <sys/time.h>
struct input_event {
  struct timeval time;
  unsigned short type;
  unsigned short code;
  unsigned int value;
};
#define EV_KEY 0x01
#endif

static int ev_fd = -2; /* -2 untried, -1 unavailable */
static unsigned char buf[sizeof(struct input_event) * 32];
static size_t buflen;

static void ev_open(void) {
  if (ev_fd != -2) return;
  const char *path = getenv("FPR_EVDEV");
  if (!path || !*path) { ev_fd = -1; return; }
  /* O_NONBLOCK also makes a writer-less FIFO open succeed immediately */
  ev_fd = open(path, O_RDONLY | O_NONBLOCK);
}

int qos_evdev_poll(int64_t *kind, int64_t *a, int64_t *c) {
  ev_open();
  if (ev_fd < 0) return 0;
  /* top up the buffer (partial trailing records stay for next poll) */
  if (buflen < sizeof buf) {
    ssize_t n = read(ev_fd, buf + buflen, sizeof buf - buflen);
    if (n > 0) buflen += (size_t)n;
    /* n == 0: EOF -- a drained pre-baked file or a closed FIFO writer.
     * Keep the fd: a FIFO can gain a new writer; a file stays drained. */
  }
  /* consume whole records until an EV_KEY surfaces (one per poll) */
  while (buflen >= sizeof(struct input_event)) {
    struct input_event ev;
    memcpy(&ev, buf, sizeof ev);
    buflen -= sizeof ev;
    memmove(buf, buf + sizeof ev, buflen);
    if (ev.type == EV_KEY) {
      *kind = 4;
      *a = ev.code;
      *c = ev.value;
      return 1;
    }
    /* EV_SYN / EV_MSC / EV_LED ...: framing + metadata, skipped here */
  }
  return 0;
}
