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
#include <sys/ioctl.h>
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

#include <stdio.h>

/* Up to MAXKBD simultaneous sources.  FPR_EVDEV names ONE explicit
 * source (device node, kbdsim FIFO, or a pre-baked file) and, for
 * replay determinism, DISABLES discovery.  With it unset, Linux hosts
 * AUTO-DISCOVER real keyboards: scan /dev/input/event0..31 and keep
 * every node whose EV_KEY capability bitmap covers the letter block
 * (KEY_Q..KEY_M, 16..50) -- the same classification the qos-shell shim
 * used; mice/buttons/lid switches all fail it.  Every attempt is
 * logged once to stderr, because "plugged a keyboard in and nothing
 * happened" is otherwise undiagnosable: the usual cause is the process
 * not being in the `input` group (EACCES), and the log says so. */
#define MAXKBD 8
static int ev_fds[MAXKBD];
static int ev_nfds;
static int ev_tried;
static unsigned char buf[sizeof(struct input_event) * 32];
static size_t buflen;
static int shift_held, ctrl_held, alt_held, caps_on;

/* the letter block, in keycode order: q..p, a..l, z..m */
static int is_letter_code(unsigned code) {
  return (code >= KEY_Q && code <= KEY_P) || (code >= KEY_A && code <= KEY_L) ||
         (code >= KEY_Z && code <= KEY_M);
}

#ifdef __linux__
static int is_keyboard(int fd) {
  unsigned long evbits = 0;
  unsigned long keybits[(KEY_MAX + 1) / (8 * sizeof(long)) + 1];
  if (ioctl(fd, EVIOCGBIT(0, sizeof evbits), &evbits) < 0) return 0;
  if (!(evbits & (1ul << EV_KEY))) return 0;
  memset(keybits, 0, sizeof keybits);
  if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof keybits), keybits) < 0) return 0;
  for (int code = KEY_Q; code <= KEY_M; code++)  /* 16..50: the letters */
    if (!(keybits[code / (8 * sizeof(long))] &
          (1ul << (code % (8 * sizeof(long))))))
      return 0;
  return 1;
}
#endif

static void ev_open(void) {
  if (ev_tried) return;
  ev_tried = 1;
  const char *path = getenv("FPR_EVDEV");
  if (path && *path) {
    /* O_NONBLOCK also makes a writer-less FIFO open succeed immediately */
    int fd = open(path, O_RDONLY | O_NONBLOCK);
    if (fd >= 0) {
      ev_fds[ev_nfds++] = fd;
      fprintf(stderr, "[input] FPR_EVDEV source: %s\n", path);
    } else
      fprintf(stderr, "[input] FPR_EVDEV %s: %s\n", path, strerror(errno));
    return; /* explicit source = no discovery (replay determinism) */
  }
#ifdef __linux__
  int denied = 0;
  for (int i = 0; i < 32 && ev_nfds < MAXKBD; i++) {
    char p[32];
    snprintf(p, sizeof p, "/dev/input/event%d", i);
    int fd = open(p, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
      if (errno == EACCES) { denied++; fprintf(stderr, "[input] %s: permission denied\n", p); }
      continue;
    }
    if (is_keyboard(fd)) {
      char name[64] = "?";
      ioctl(fd, EVIOCGNAME(sizeof name), name);
      fprintf(stderr, "[input] keyboard: %s (%s)\n", p, name);
      ev_fds[ev_nfds++] = fd;
    } else
      close(fd);
  }
  if (!ev_nfds)
    fprintf(stderr, denied
                ? "[input] no readable keyboards (add the user to the `input` group)\n"
                : "[input] no keyboards discovered (evdev falls back to stdin)\n");
#endif
}

int qos_evdev_poll(int64_t *kind, int64_t *a, int64_t *c) {
  ev_open();
  if (!ev_nfds) return 0;
  /* top up the buffer from every source (partial trailing records stay
   * for next poll).  Interleaving across sources at record granularity
   * is fine: each read appends whole-record multiples in practice, and
   * the parser below is byte-accurate regardless. */
  for (int i = 0; i < ev_nfds && buflen < sizeof buf; i++) {
    ssize_t n = read(ev_fds[i], buf + buflen, sizeof buf - buflen);
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
      static int first = 1;
      if (first) {
        first = 0;
        fprintf(stderr, "[input] first key event: code %u value %d\n",
                (unsigned)ev.code, (int)ev.value);
      }
      /* MODIFIER STATE lives here, in the one place that sees every
       * event of every source.  A keyboard reports shift as its own
       * press/release around the key, so a stateless decoder can
       * never produce '?' or '"' -- and the app layer would have to
       * carry modifier state through its model to do it instead.
       * Held modifiers are reported by BIASING the keycode: shifted
       * keys arrive as code + KEYBIAS_SHIFT, so a keymap stays a
       * plain table lookup and unshifted codes are untouched.
       * Caps lock toggles and applies to letters only (it is a lock,
       * not a shift -- caps+2 is still '2'). */
      if (ev.code == KEY_LEFTSHIFT || ev.code == KEY_RIGHTSHIFT) {
        if (ev.value != 2) shift_held = ev.value ? 1 : 0;
        continue; /* the modifier itself is not a keypress */
      }
      if (ev.code == KEY_LEFTCTRL || ev.code == KEY_RIGHTCTRL) {
        if (ev.value != 2) ctrl_held = ev.value ? 1 : 0;
        continue;
      }
      if (ev.code == KEY_LEFTALT || ev.code == KEY_RIGHTALT) {
        if (ev.value != 2) alt_held = ev.value ? 1 : 0;
        continue;
      }
      if (ev.code == KEY_CAPSLOCK) {
        if (ev.value == 1) caps_on = !caps_on;
        continue;
      }
      int bias = 0;
      if (shift_held) bias += 1000;
      if (ctrl_held) bias += 4000;
      if (alt_held) bias += 8000;
      if (caps_on && !shift_held && is_letter_code(ev.code)) bias += 1000;
      if (caps_on && shift_held && is_letter_code(ev.code)) bias -= 1000;
      *kind = 4;
      *a = ev.code + bias;
      *c = ev.value;
      return 1;
    }
    /* EV_SYN / EV_MSC / EV_LED ...: framing + metadata, skipped here */
  }
  return 0;
}
