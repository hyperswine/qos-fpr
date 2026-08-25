/* tty_raw.c (posix) -- the TERMINAL input tier: fpr_g_inputPoll for
 * images built WITHOUT the GL stack (GFX=1 links gfx_fpr.c's poll
 * instead; the two are never in the same image -- see the Makefile).
 *
 * Source priority mirrors the gfx tier's discipline:
 *
 *   1. FPR_EVDEV set  -> qos_evdev_poll (evdev_raw.c): a kbdsim FIFO,
 *      a pre-baked event file, or a real /dev/input/eventN on Linux.
 *      Deterministic replay and the simulated keyboard keep working
 *      exactly as they do under GFX=1 / qosp.
 *   2. otherwise      -> RAW stdin.  If stdin is a tty it is switched
 *      to non-canonical no-echo mode (VMIN=0/VTIME=0: reads never
 *      block, matching the poll contract) and restored at exit and on
 *      SIGINT/SIGTERM; a pipe works too (tests feed bytes that way).
 *
 * Bytes are decoded to LINUX INPUT-EVENT KEYCODES -- the same codes
 * the evdev tier delivers -- so a program's key map (voxel.fpr's
 * applyKey table, mvu3d's update) works unchanged over either source.
 * Terminals only report presses, so every event is (4, code, 1); the
 * press/release distinction is what the evdev tier buys over this one.
 */
/* QOSP_HOST: compiled into the qosp HOST binary (haltab input tier) --
 * everything here is plain posix EXCEPT the fpr_g_inputPoll wrapper at
 * the bottom, which needs the app runtime.  The guard keeps ONE
 * implementation of the decode/raw-mode/winch discipline for both
 * dispatch worlds, per the haltab.c essay. */
#ifndef QOSP_HOST
#include "fpr.h"
#endif
#include <stdint.h>

#include <fcntl.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

int qos_evdev_poll(int64_t* kind, int64_t* a, int64_t* c); /* evdev_raw.c */

/* ---- raw-mode lifecycle --------------------------------------------- */

static int tty_state; /* 0 untried, 1 raw, -1 not a tty (pipe: still read) */
static struct termios tty_saved;

/* ---- terminal size ---------------------------------------------------
 * Reported through the SAME poll as keys, as kind 5: (5, cols, rows).
 * Dirty at startup (so a program learns its terminal on the first poll)
 * and again on every SIGWINCH; a poll with the flag set reports the
 * size BEFORE any queued key.  Size is read from whichever of stdout/
 * stdin is a tty -- a fully piped run (both redirected) never sees a
 * kind-5 event, so replay-style tests keep their exact event stream,
 * and the FPR_EVDEV tier is untouched (no sizes there either). */
static volatile sig_atomic_t win_dirty = 1;
static void tty_winch(int s) { (void)s; win_dirty = 1; }

static int win_poll(int64_t* kind, int64_t* a, int64_t* c) {
  struct winsize ws;
  int fd;
  if (!win_dirty) return 0;
  win_dirty = 0;
  fd = isatty(1) ? 1 : (isatty(0) ? 0 : -1);
  if (fd < 0 || ioctl(fd, TIOCGWINSZ, &ws)) return 0;
  if (!ws.ws_col || !ws.ws_row) return 0;
  *kind = 5; *a = (int64_t)ws.ws_col; *c = (int64_t)ws.ws_row;
  return 1;
}

static void tty_restore(void) {
  if (tty_state == 1) tcsetattr(0, TCSAFLUSH, &tty_saved);
}
static void tty_sig(int s) {
  tty_restore();
  signal(s, SIG_DFL);
  raise(s);
}
static void tty_init(void) {
  if (tty_state) return;
  signal(SIGWINCH, tty_winch);
  if (!isatty(0)) {
    /* a pipe: VMIN/VTIME don't apply, so an empty read would BLOCK the
     * frame loop -- make it nonblocking (the tty path gets the same
     * never-block contract from VMIN=0/VTIME=0) */
    fcntl(0, F_SETFL, fcntl(0, F_GETFL, 0) | O_NONBLOCK);
    tty_state = -1;
    return;
  }
  if (tcgetattr(0, &tty_saved)) { tty_state = -1; return; }
  struct termios t = tty_saved;
  t.c_lflag &= (tcflag_t)~(ICANON | ECHO); /* ISIG stays: ^C still works */
  t.c_cc[VMIN] = 0;
  t.c_cc[VTIME] = 0;
  if (tcsetattr(0, TCSAFLUSH, &t)) { tty_state = -1; return; }
  atexit(tty_restore);
  signal(SIGINT, tty_sig);
  signal(SIGTERM, tty_sig);
  tty_state = 1;
}

/* ---- byte queue + decode -------------------------------------------- */

static unsigned char q[64];
static size_t qn;
static int esc_stale; /* a lone ESC seen last poll with nothing after */

static void topup(void) {
  if (qn < sizeof q) {
    ssize_t n = read(0, q + qn, sizeof q - qn);
    if (n > 0) qn += (size_t)n;
  }
}
static void shift(size_t k) {
  memmove(q, q + k, qn - k);
  qn -= k;
}

/* Linux input-event-codes for the keys the demos map:
 *   w 17  a 30  s 31  d 32  x 45  f 33  c 46  v 47  space 57  q 16
 *   1..9 -> 2..10   0 -> 11   arrows: up 103 down 108 left 105 right 106 */
static int code_of(unsigned char b) {
  switch (b) {
  case 'w': case 'W': return 17;
  case 'a': case 'A': return 30;
  case 's': case 'S': return 31;
  case 'd': case 'D': return 32;
  case 'x': case 'X': return 45;
  case 'f': case 'F': return 33;
  case ' ': return 57;
  case 'q': case 'Q': return 16;
  case 'c': case 'C': return 46;
  case 'v': case 'V': return 47;
  case '0': return 11;
  default: return (b >= '1' && b <= '9') ? (int)(b - '1') + 2 : 0;
  }
}

/* one key per poll, the evdev tier's record discipline */
int qos_tty_poll(int64_t* kind, int64_t* a, int64_t* c) {
  tty_init();
  if (win_poll(kind, a, c)) return 1;
  topup();
  while (qn) {
    if (q[0] == 27) {
      if (qn >= 3 && q[1] == '[') {
        unsigned char f = q[2];
        shift(3);
        esc_stale = 0;
        int code = f == 'A' ? 103 : f == 'B' ? 108 : f == 'C' ? 106
          : f == 'D' ? 105 : 0;
        if (!code) continue;
        *kind = 4; *a = code; *c = 1;
        return 1;
      }
      if (qn == 1) {
        /* maybe a split escape sequence: give it one poll to complete */
        if (!esc_stale) { esc_stale = 1; return 0; }
        shift(1);
        esc_stale = 0;
        continue;
      }
      shift(1); /* ESC + non-'[': not a sequence we decode */
      continue;
    }
    int code = code_of(q[0]);
    shift(1);
    if (!code) continue;
    *kind = 4; *a = code; *c = 1;
    return 1;
  }
  return 0;
}

/* ---- the obligation (app tier only) ---------------------------------- */
#ifndef QOSP_HOST
static V h_inputPoll(V u) {
  (void)u;
  /* uniform triple, gfx_fpr.c's shape: (0, 0, 0) means no event */
  int64_t kind = 0, a = 0, c = 0;
  if (getenv("FPR_EVDEV")) qos_evdev_poll(&kind, &a, &c);
  else qos_tty_poll(&kind, &a, &c);
  V* t = (V*)fpr_alloc(32);
  ((hdr_t*)t)->tid = 5; ((hdr_t*)t)->var = 0; /* triple */
  t[1] = TAG((sw)kind); t[2] = TAG((sw)a); t[3] = TAG((sw)c);
  return (V)t;
}
FPR_FN(fpr_g_inputPoll, h_inputPoll, 1);
#endif /* !QOSP_HOST */