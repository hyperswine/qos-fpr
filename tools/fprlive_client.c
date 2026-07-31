/* fprlive_client.c -- a networked FPRLive backend for linux (x86-64 / Pi 4).
 *
 * The server is programs/livenotes.fpr: an FP-RISC program that compiles
 * its app to the FPRLive ISA, emits the FPRL 1 image, and owns the model.
 * This client shares no code with it.  All it consumes is the image off
 * the socket, plus the live push stream.
 *
 *   HELLO             -> image ... ENDIMG          (once, at connect)
 *   E <keycode>       -> P <slot> <word> / PS <slot> <text> ... A
 *   GOLDEN            -> golden ... ENDGOLDEN      (--golden mode)
 *
 * Three conformance checks, same as the reference backend:
 *   semantic:  --script replays the image's timeline in lockstep and
 *              writes trace.txt; it must equal the server's golden.
 *   execution: the encoded ISA words run directly; no AST, no malloc
 *              after load; register file checked against nregs.
 *   timing:    the image's contract (draw cadence + key-to-present,
 *              WITH the server round trip inside it) is measured.
 *
 * Build:  cc -O2 -o fprlive_client tools/fprlive_client.c
 * Run:    ./fprlive_client [host] [port] --script          # conformance
 *         ./fprlive_client [host] [port] --golden > golden.txt
 *         ./fprlive_client [host] [port] --tty             # take notes
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <time.h>
#include <errno.h>
#include <termios.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>

 /* ---- static budget: nothing malloc'd after load ----------------------- */
#define MAXSTR    128
#define MAXCODE    64
#define MAXBIND    64
#define MAXNODE    64
#define MAXCELL    64
#define MAXKEY     32
#define MAXEVT    128
#define MAXWORD    64
#define NREGS       8
#define ARENA    2048
#define STRPOOL 16384
#define OUTLEN     64
#define PUSHLEN    64      /* one persistent buffer per Str cell */

typedef struct {
  int ty, nregs, ndeps, deps[8], npool, pool[8], nwords;
  uint32_t w[MAXWORD]; uint32_t hash;
} Code;
typedef struct { int node, target, attr, code; } Bind;
typedef struct { int parent, tag, nattrs, ak[8], av[8]; } NodeC;
typedef struct { int code, op, slot, arg; } KeyMap;
typedef struct { int at_ms, kind, a, b; } Evt;

static char  strpool[STRPOOL];  static int  strtop;
static char* strs[MAXSTR];      static int  nstr;
static Code  codes[MAXCODE];    static int  ncode;
static Bind  binds[MAXBIND];    static int  nbind;
static NodeC nodes[MAXNODE];    static int  nnode;
static KeyMap keys[MAXKEY];     static int  nkey;
static Evt   script[MAXEVT];    static int  nevt;
static int   cellty[MAXCELL];   static int  ncell;
static int   draw_hz_min, key_lat_us_max;

static int32_t cells[MAXCELL];
static char* arena[ARENA];
static int     arena_base;         /* nstr + MAXCELL: frame arena floor   */
static int     arena_top;
static char    pushbuf[MAXCELL][PUSHLEN];  /* persistent pushed Str cells */
static char    framepool[STRPOOL]; static int framepool_top;
static char    out[MAXBIND][OUTLEN];
static int     subs[MAXCELL][MAXBIND]; static int nsubs[MAXCELL];

static long long t0_ns;
static long long now_ns(void) {
  struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
  return (long long)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}
static long long since_us(void) { return (now_ns() - t0_ns) / 1000; }

static int      frames;
static long long last_frame_ns, max_gap_us;
static long long lat_us[512]; static int nlat; static long long max_lat_us;

static void die(const char* m) { fprintf(stderr, "client: %s\n", m); exit(2); }

/* ---- image parser (same grammar as the reference backend) ------------- */
static char* intern(const char* p, int len) {
  if (strtop + len + 1 > STRPOOL) die("string pool exhausted");
  char* d = strpool + strtop; memcpy(d, p, len); d[len] = 0;
  strtop += len + 1; return d;
}

static void load_line(const char* line) {
  if (line[0] == '#' || line[0] == '\n' || line[0] == 0) return;
  char tag[16]; int off = 0;
  if (sscanf(line, "%15s%n", tag, &off) != 1) return;

  if (!strcmp(tag, "FPRL")) {
    int v; sscanf(line + off, "%d", &v);
    if (v != 1) die("image version");
  }
  else if (!strcmp(tag, "contract"))
    sscanf(line + off, "%d %d", &draw_hz_min, &key_lat_us_max);
  else if (!strcmp(tag, "s")) {
    int i, len, k;
    sscanf(line, "s %d %d %n", &i, &len, &k);
    strs[i] = intern(line + k, len); if (i >= nstr) nstr = i + 1;
  }
  else if (!strcmp(tag, "c")) {
    int sl, ty; long v; sscanf(line, "c %d %d %ld", &sl, &ty, &v);
    cells[sl] = (int32_t)v; cellty[sl] = ty;
    if (sl >= ncell) ncell = sl + 1;
  }
  else if (!strcmp(tag, "k")) {
    int i, p = 0, n; unsigned h;
    sscanf(line, "k %d %x%n", &i, &h, &n); p = n;
    Code* c = &codes[i]; c->hash = h;
    sscanf(line + p, "%d %d %d%n", &c->ty, &c->nregs, &c->ndeps, &n); p += n;
    for (int j = 0; j < c->ndeps; j++) { sscanf(line + p, "%d%n", &c->deps[j], &n); p += n; }
    sscanf(line + p, "%d%n", &c->npool, &n); p += n;
    for (int j = 0; j < c->npool; j++) { sscanf(line + p, "%d%n", &c->pool[j], &n); p += n; }
    sscanf(line + p, "%d%n", &c->nwords, &n); p += n;
    for (int j = 0; j < c->nwords; j++) {
      unsigned w;
      sscanf(line + p, "%x%n", &w, &n); p += n; c->w[j] = w;
    }
    if (i >= ncode) ncode = i + 1;
  }
  else if (!strcmp(tag, "n")) {
    int i, p = 0, n; sscanf(line, "n %d%n", &i, &n); p = n;
    NodeC* nd = &nodes[i];
    sscanf(line + p, "%d %d %d%n", &nd->parent, &nd->tag, &nd->nattrs, &n); p += n;
    for (int j = 0; j < nd->nattrs; j++) {
      sscanf(line + p, "%d %d%n", &nd->ak[j], &nd->av[j], &n); p += n;
    }
    if (i >= nnode) nnode = i + 1;
  }
  else if (!strcmp(tag, "b")) {
    int i; Bind bd;
    sscanf(line, "b %d %d %d %d %d", &i, &bd.node, &bd.target, &bd.attr, &bd.code);
    binds[i] = bd; if (i >= nbind) nbind = i + 1;
  }
  else if (!strcmp(tag, "y")) {
    KeyMap k; sscanf(line, "y %d %d %d %d", &k.code, &k.op, &k.slot, &k.arg);
    keys[nkey++] = k;
  }
  else if (!strcmp(tag, "e")) {
    Evt e; sscanf(line, "e %d %d %d %d", &e.at_ms, &e.kind, &e.a, &e.b);
    script[nevt++] = e;
  }
}

/* ---- the machine: executes the image words directly ------------------- */
static int32_t sext11(uint32_t x) { return (x & 0x400) ? (int32_t)(x | ~0x7ffu) : (int32_t)x; }

static int32_t alloc_str(const char* s) {
  int len = strlen(s);
  if (arena_top >= ARENA || framepool_top + len + 1 > STRPOOL) die("frame arena full");
  char* d = framepool + framepool_top; memcpy(d, s, len + 1); framepool_top += len + 1;
  int h = arena_top++; arena[h] = d; return h;
}

static long long fuel_total;

static int32_t run(const Code* c) {
  int32_t r[NREGS] = { 0 };
  for (int pc = 0;; pc++) {
    uint32_t w = c->w[pc];
    int op = w >> 26, d = (w >> 21) & 31, a = (w >> 16) & 31, b = (w >> 11) & 31;
    uint32_t imm = w & 0x7ff;
    fuel_total++;
    switch (op) {
    case 1:  r[d] = sext11(imm); break;
    case 2:  r[d] = sext11(imm) << 11; break;
    case 3:  r[d] = r[a] | (int32_t)imm; break;
    case 4:  r[d] = c->pool[imm]; break;
    case 5:  r[d] = cells[imm]; break;
    case 6:  r[d] = r[a]; break;
    case 7:  r[d] = r[a] + r[b]; break;
    case 8:  r[d] = r[a] - r[b]; break;
    case 9:  r[d] = r[a] * r[b]; break;
    case 10: r[d] = r[a] < r[b]; break;
    case 11: r[d] = r[a] == r[b]; break;
    case 12: r[d] = (r[a] == 0); break;
    case 13: {
      char buf[OUTLEN * 2];
      snprintf(buf, sizeof buf, "%s%s", arena[r[a]], arena[r[b]]);
      r[d] = alloc_str(buf);
    } break;
    case 14: {
      char buf[24];
      snprintf(buf, sizeof buf, "%d", r[a]); r[d] = alloc_str(buf);
    } break;
    case 15: if (r[a] == 0) pc = imm - 1; break;
    case 16: if (r[a] != 0) pc = imm - 1; break;
    case 17: pc = imm - 1; break;
    case 18: return r[a];
    default: die("bad opcode");
    }
  }
}

static void decode_into(char* dst, int ty, int32_t w) {
  if (ty == 0) snprintf(dst, OUTLEN, "%d", w);
  else if (ty == 1) snprintf(dst, OUTLEN, "%s", w ? "1" : "0");
  else              snprintf(dst, OUTLEN, "%s", arena[w]);
}

static void eval_bind(int i) {
  const Code* c = &codes[binds[i].code];
  decode_into(out[i], c->ty, run(c));
}

/* ---- reactive engine -------------------------------------------------- */
static void build_subs(void) {
  for (int i = 0; i < nbind; i++) {
    const Code* c = &codes[binds[i].code];
    for (int j = 0; j < c->ndeps; j++) {
      int sl = c->deps[j];
      subs[sl][nsubs[sl]++] = i;
    }
  }
}
static int dirty[MAXBIND], ndirty;
static void mark(int slot) {
  for (int j = 0; j < nsubs[slot]; j++) {
    int b = subs[slot][j], seen = 0;
    for (int k = 0; k < ndirty; k++) if (dirty[k] == b) seen = 1;
    if (!seen) dirty[ndirty++] = b;
  }
}
static void flush_dirty(void) {
  arena_top = arena_base; framepool_top = 0;
  for (int i = 0; i < ndirty; i++) eval_bind(dirty[i]);
  ndirty = 0;
}

/* ---- TUI -------------------------------------------------------------- */
static int use_tty;
static char framebuf[8192];

static int bind_for(int node, int target, int* idx) {
  for (int i = 0; i < nbind; i++)
    if (binds[i].node == node && binds[i].target == target) { *idx = i; return 1; }
  return 0;
}

static void compose(void) {
  int n = 0;
  n += snprintf(framebuf + n, sizeof framebuf - n,
    "+------------------------------------------------------+\n");
  for (int i = 0; i < nnode; i++) {
    int depth = 0; for (int p = nodes[i].parent; p >= 0; p = nodes[p].parent) depth++;
    int bi, hidden = bind_for(i, 3, &bi) && out[bi][0] == '0';
    char row[256]; int r = 0;
    r += snprintf(row + r, sizeof row - r, "%*s<%s>", depth * 2, "", strs[nodes[i].tag]);
    for (int j = 0; j < nodes[i].nattrs; j++)
      r += snprintf(row + r, sizeof row - r, " %s=%s",
        strs[nodes[i].ak[j]], strs[nodes[i].av[j]]);
    for (int b = 0; b < nbind; b++) {
      if (binds[b].node != i) continue;
      switch (binds[b].target) {
      case 0: r += snprintf(row + r, sizeof row - r, " %s", out[b]); break;
      case 1: r += snprintf(row + r, sizeof row - r, " %s=%s",
        strs[binds[b].attr], out[b]); break;
      case 2: r += snprintf(row + r, sizeof row - r, " class=%s", out[b]); break;
      case 3: break;
      }
    }
    if (hidden) r += snprintf(row + r, sizeof row - r, "   [hidden]");
    n += snprintf(framebuf + n, sizeof framebuf - n, "| %-52.52s |\n", row);
  }
  n += snprintf(framebuf + n, sizeof framebuf - n,
    "| %-52.52s |\n", "type + enter add   up/down sel   ^x del   ^q quit");
  n += snprintf(framebuf + n, sizeof framebuf - n,
    "+------------------------------------------------------+\n");
}

static void present(const char* why) {
  compose();
  long long t = now_ns();
  if (frames) {
    long long gap = (t - last_frame_ns) / 1000;
    if (gap > max_gap_us) max_gap_us = gap;
  }
  last_frame_ns = t; frames++;
  if (use_tty) { printf("\033[H\033[2J%s", framebuf); fflush(stdout); }
  else printf("--- frame %d  t=%lldms  (%s)\n%s", frames, since_us() / 1000, why, framebuf);
}

/* ---- the wire --------------------------------------------------------- */
static int sfd = -1;
static char rxbuf[65536]; static int rxlen;

static void net_send(const char* s) {
  size_t len = strlen(s), off = 0;
  while (off < len) {
    ssize_t n = write(sfd, s + off, len - off);
    if (n > 0) { off += n; continue; }
    if (n < 0 && errno == EINTR) continue;
    die("server went away");
  }
}

/* pull one \n-terminated line out of rxbuf; block up to timeout_ms for it.
 * returns 1 with the line (no \n) in dst, 0 on timeout. */
static int net_line(char* dst, int cap, int timeout_ms) {
  for (;;) {
    char* nl = memchr(rxbuf, '\n', rxlen);
    if (nl) {
      int len = nl - rxbuf;
      if (len >= cap) len = cap - 1;
      memcpy(dst, rxbuf, len); dst[len] = 0;
      int consumed = (nl - rxbuf) + 1;
      memmove(rxbuf, rxbuf + consumed, rxlen - consumed); rxlen -= consumed;
      return 1;
    }
    struct pollfd pf = { .fd = sfd, .events = POLLIN };
    int rv = poll(&pf, 1, timeout_ms);
    if (rv <= 0) return 0;
    ssize_t n = read(sfd, rxbuf + rxlen, sizeof rxbuf - rxlen);
    if (n <= 0) die("server closed the connection");
    rxlen += n;
  }
}

/* apply one push line; returns 1 if it was a push, 0 if it was the ack */
static int apply_push(const char* ln) {
  if (ln[0] == 'A' && ln[1] == 0) return 0;
  if (ln[0] == 'P' && ln[1] == 'S') {
    int slot, k;
    sscanf(ln, "PS %d %n", &slot, &k);
    snprintf(pushbuf[slot], PUSHLEN, "%s", ln + k);
    arena[nstr + slot] = pushbuf[slot];
    cells[slot] = nstr + slot;
    mark(slot);
  }
  else if (ln[0] == 'P') {
    int slot; long v;
    sscanf(ln, "P %d %ld", &slot, &v);
    cells[slot] = (int32_t)v;
    mark(slot);
  }
  return 1;
}

/* send a key upstream; apply pushes until the ack lands */
static void round_trip(int code) {
  char msg[32]; snprintf(msg, sizeof msg, "E %d\n", code);
  net_send(msg);
  char ln[256];
  while (net_line(ln, sizeof ln, 5000)) {
    if (!apply_push(ln)) return;
  }
  die("no ack from server");
}

static void local_op(int code) {
  for (int i = 0; i < nkey; i++) if (keys[i].code == code) {
    int sl = keys[i].slot;
    if (keys[i].op == 0) cells[sl] = keys[i].arg;
    else if (keys[i].op == 1) cells[sl] += keys[i].arg;
    else                      cells[sl] = !cells[sl];
    mark(sl);
  }
}

/* ---- trace ------------------------------------------------------------ */
static FILE* tracef; static int evt_ix;
static void dump_trace(void) {
  if (!tracef) return;
  for (int i = 0; i < nbind; i++) fprintf(tracef, "G %d %d %s\n", evt_ix, i, out[i]);
  evt_ix++;
}

/* ---- modes ------------------------------------------------------------ */
static void fetch_image(void) {
  net_send("HELLO\n");
  char ln[4096];
  while (net_line(ln, sizeof ln, 5000)) {
    if (!strcmp(ln, "ENDIMG")) break;
    load_line(ln);
  }
  if (!nnode) die("no image from server");
  for (int i = 0; i < nstr; i++) arena[i] = strs[i];
  for (int i = 0; i < ncell; i++)                 /* Str cells own a push slot */
    if (cellty[i] == 2) {
      snprintf(pushbuf[i], PUSHLEN, "%s", strs[cells[i]]);
      arena[nstr + i] = pushbuf[i]; cells[i] = nstr + i;
    }
  arena_base = nstr + MAXCELL;
  build_subs();
  int maxregs = 0;
  for (int i = 0; i < ncode; i++) if (codes[i].nregs > maxregs) maxregs = codes[i].nregs;
  if (maxregs > NREGS) die("image needs a larger register file than this backend has");
}

static int mode_golden(void) {
  net_send("GOLDEN\n");
  char ln[4096];
  while (net_line(ln, sizeof ln, 5000)) {
    if (!strcmp(ln, "ENDGOLDEN")) return 0;
    puts(ln);
  }
  die("golden truncated"); return 2;
}

static int mode_script(void) {
  tracef = fopen("trace.txt", "w");
  t0_ns = now_ns(); last_frame_ns = t0_ns;
  for (int i = 0; i < nbind; i++) { arena_top = arena_base; framepool_top = 0; eval_bind(i); }
  present("boot");

  int hb_ms = 1000 / draw_hz_min / 2;
  for (int e = 0; e < nevt; ) {
    long long ev_at_us = (long long)script[e].at_ms * 1000;
    long long left_ms = (ev_at_us - since_us()) / 1000;
    if (left_ms > 0) {
      struct pollfd pf = { .fd = sfd, .events = POLLIN };
      int rv = poll(&pf, 1, left_ms < hb_ms ? (int)left_ms : hb_ms);
      if (rv > 0) {
        char ln[256]; if (net_line(ln, sizeof ln, 0)) apply_push(ln);
        if (ndirty) { flush_dirty(); present("push"); } continue;
      }
      if (since_us() < ev_at_us) { present("heartbeat"); continue; }
    }
    if (script[e].kind == 0) {
      long long sent_us = since_us();
      local_op(script[e].a);              /* optimistic */
      round_trip(script[e].a);            /* authoritative */
      flush_dirty(); dump_trace(); present("key");
      long long l = since_us() - sent_us;
      lat_us[nlat++] = l; if (l > max_lat_us) max_lat_us = l;
    }
    else {
      flush_dirty(); dump_trace();        /* idle checkpoint */
    }
    e++;
  }
  fclose(tracef);
  net_send("Q\n");

  long long elapsed = since_us();
  double hz = frames / (elapsed / 1e6);
  long long gap_budget = 1000000LL / draw_hz_min;
  int ok_draw = max_gap_us <= gap_budget;
  int ok_lat = max_lat_us <= key_lat_us_max;
  long long sum = 0; for (int i = 0; i < nlat; i++) sum += lat_us[i];

  printf("\n=== CONFORMANCE ==========================================\n");
  printf("ran %lld ms, %d frames presented, %.2f Hz average\n", elapsed / 1000, frames, hz);
  printf("instructions retired: %lld\n\n", fuel_total);
  printf("  draw cadence   worst gap %6lld us   budget %6lld us   %s\n",
    max_gap_us, gap_budget, ok_draw ? "PASS" : "FAIL");
  printf("  key latency    worst     %6lld us   budget %6d us   %s\n",
    max_lat_us, key_lat_us_max, ok_lat ? "PASS" : "FAIL");
  printf("                 mean      %6lld us over %d key events  (server round trip included)\n",
    nlat ? sum / nlat : 0, nlat);
  printf("\nwrote trace.txt (%d checkpoints x %d binds)\n", evt_ix, nbind);
  return (ok_draw && ok_lat) ? 0 : 1;
}

/* ascii / escape -> evdev keycode for the interactive TUI */
static int tty_keycode(void) {
  unsigned char c;
  if (read(0, &c, 1) != 1) return -1;
  if (c == 27) {                       /* ESC [ A/B, ESC [ 3 ~ */
    unsigned char s[3] = { 0 };
    if (read(0, s, 1) == 1 && s[0] == '[' && read(0, s + 1, 1) == 1) {
      if (s[1] == 'A') return 103;
      if (s[1] == 'B') return 108;
      if (s[1] == '3') { if (read(0, s + 2, 1) < 0) {} return 111; }
    }
    return -2;
  }
  if (c == 17) return -9;              /* ^q: quit */
  if (c == 24) return 111;             /* ^x: delete selected */
  if (c == '\r' || c == '\n') return 28;
  if (c == 127 || c == 8) return 14;
  if (c == ' ') return 57;
  static const char* low = "abcdefghijklmnopqrstuvwxyz";
  static const int   lowc[] = { 30,48,46,32,18,33,34,35,23,36,37,38,50,49,24,25,16,19,31,20,22,47,17,45,21,44 };
  const char* p = strchr(low, c | 32);
  if (p && (c | 32) >= 'a' && (c | 32) <= 'z') return lowc[p - low];
  if (c >= '0' && c <= '9') { static const int dig[] = { 11,2,3,4,5,6,7,8,9,10 }; return dig[c - '0']; }
  return -2;
}

static struct termios tio_saved;
static void tty_restore(void) { tcsetattr(0, TCSANOW, &tio_saved); printf("\033[?25h\n"); }

static int mode_tty(void) {
  use_tty = 1;
  tcgetattr(0, &tio_saved); atexit(tty_restore);
  struct termios t = tio_saved;
  t.c_lflag &= ~(ICANON | ECHO); t.c_cc[VMIN] = 1; t.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &t);
  printf("\033[?25l");

  t0_ns = now_ns(); last_frame_ns = t0_ns;
  for (int i = 0; i < nbind; i++) { arena_top = arena_base; framepool_top = 0; eval_bind(i); }
  present("boot");

  int hb_ms = 1000 / draw_hz_min / 2;
  for (;;) {
    struct pollfd pf[2] = { {.fd = 0, .events = POLLIN },
                            {.fd = sfd, .events = POLLIN } };
    int rv = poll(pf, 2, hb_ms);
    if (rv == 0) { present("heartbeat"); continue; }
    if (pf[1].revents & POLLIN) {
      char ln[256];
      if (net_line(ln, sizeof ln, 0)) apply_push(ln);
      if (ndirty) { flush_dirty(); present("push"); }
    }
    if (pf[0].revents & POLLIN) {
      int code = tty_keycode();
      if (code == -9) break;
      if (code < 0) continue;
      local_op(code);
      if (ndirty) { flush_dirty(); present("key"); }   /* optimistic frame */
      round_trip(code);
      if (ndirty) { flush_dirty(); present("push"); }  /* authoritative */
    }
  }
  net_send("Q\n");
  return 0;
}

int main(int argc, char** argv) {
  const char* host = "127.0.0.1"; int port = 8790;

  enum { GOLDEN, SCRIPT, TTY } mode = SCRIPT;

  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--golden")) mode = GOLDEN;
    else if (!strcmp(argv[i], "--script")) mode = SCRIPT;
    else if (!strcmp(argv[i], "--tty")) mode = TTY;
    else if (strchr(argv[i], '.') || strchr(argv[i], ':')) host = argv[i];
    else port = atoi(argv[i]);
  }

  struct addrinfo hints = { .ai_family = AF_INET, .ai_socktype = SOCK_STREAM }, * res;

  char ps[16]; snprintf(ps, sizeof ps, "%d", port);

  if (getaddrinfo(host, ps, &hints, &res)) die("resolve");

  sfd = socket(res->ai_family, res->ai_socktype, 0);

  if (connect(sfd, res->ai_addr, res->ai_addrlen)) die("connect (is livenotes running?)");
  int one = 1; setsockopt(sfd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);

  if (mode == GOLDEN) return mode_golden();

  fetch_image();

  int totalwords = 0; for (int i = 0; i < ncode; i++) totalwords += codes[i].nwords;

  if (mode == SCRIPT)
    printf("backend: linux TUI over TCP, %d regs, %d-handle frame arena\n"
      "image:   %d nodes, %d binds, %d codes (%d words / %d bytes), %d cells\n"
      "contract: >= %d draws/sec, key-to-present <= %d us (round trip included)\n\n",
      NREGS, ARENA, nnode, nbind, ncode, totalwords, totalwords * 4, ncell,
      draw_hz_min, key_lat_us_max);

  return mode == SCRIPT ? mode_script() : mode_tty();
}
