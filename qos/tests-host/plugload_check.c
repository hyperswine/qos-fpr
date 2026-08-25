/* plugload_check.c -- stage-2 proof: qosp_load_plugin_bytes end to end,
 * minus only the FPRISC caller.  Driven by plugload-check.sh, which
 * builds a REAL stub plugin ELF through the REAL link-qosplug.ld,
 * wraps it with the REAL tools/mkqa.py, and passes the expected
 * addresses (from nm) in argv.  The harness links qosp's own objects
 * (-Dmain renames qosp's main away), maps the plugin window the way
 * qosp's Loader stage does, and then:
 *
 *   1. refuses garbage ("not a QAR2")
 *   2. loads the real .qa from BYTES -- table address must equal nm's
 *   3. EXECUTES the stub's exported function out of the r-x mapping
 *   4. verifies W^X (a write to the text page must fault -- checked
 *      via /proc/self/maps permissions rather than a signal dance)
 *   5. refuses a second, overlapping load
 *   6. refuses a one-byte-corrupted archive (sha256)
 */
#include "qos_abi.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

int64_t qosp_load_plugin_bytes(const char *bytes, uint64_t len, char *err,
                               uint64_t errcap);

static int fails;
#define CHECK(cond, name)                                   \
  do {                                                      \
    if (cond) printf("  ok   %s\n", name);                  \
    else { printf("  FAIL %s\n", name); fails++; }          \
  } while (0)

static unsigned char *slurp(const char *path, uint64_t *len) {
  FILE *f = fopen(path, "rb");
  if (!f) { perror(path); exit(2); }
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  fseek(f, 0, SEEK_SET);
  unsigned char *b = malloc((size_t)sz);
  if (fread(b, 1, (size_t)sz, f) != (size_t)sz) exit(2);
  fclose(f);
  *len = (uint64_t)sz;
  return b;
}

static int maps_has_rx(uintptr_t addr) {
  FILE *m = fopen("/proc/self/maps", "r");
  char line[256];
  int ok = 0;
  while (m && fgets(line, sizeof line, m)) {
    uintptr_t lo, hi;
    char perms[8];
    if (sscanf(line, "%lx-%lx %4s", &lo, &hi, perms) == 3 &&
        addr >= lo && addr < hi)
      ok = !strcmp(perms, "r-xp");
  }
  if (m) fclose(m);
  return ok;
}

int main(int argc, char **argv) {
  if (argc != 4) return fprintf(stderr, "usage: %s plug.qa tabaddr probeaddr\n", argv[0]), 2;
  uintptr_t want_tab = strtoul(argv[2], 0, 16);
  uintptr_t probe_at = strtoul(argv[3], 0, 16);

  /* the Loader stage's window map, harness edition */
  void *w = mmap((void *)QOS_PLUG_BASE, QOS_PLUG_SIZE, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NOREPLACE, -1, 0);
  if (w != (void *)QOS_PLUG_BASE) { perror("mmap plug window"); return 2; }

  char err[256];
  uint64_t len;
  unsigned char *qa = slurp(argv[1], &len);

  /* 1 -- garbage is named as such (the migration hint) */
  err[0] = 0;
  int64_t r = qosp_load_plugin_bytes("hello.qa", 8, err, sizeof err);
  CHECK(r < 0 && strstr(err, "not a QAR2"), "garbage refused: not a QAR2");

  /* 2 -- the real load, from bytes */
  err[0] = 0;
  r = qosp_load_plugin_bytes((const char *)qa, len, err, sizeof err);
  CHECK(r > 0, "load from BYTES succeeded");
  CHECK((uintptr_t)r == want_tab, "returned table address == nm's fpr_modtab");
  CHECK(((const uint64_t *)r)[0] == 0, "table readable (empty, zero-terminated)");

  /* 3 -- execute out of the mapping */
  uint64_t (*probe)(uint64_t) = (uint64_t (*)(uint64_t))probe_at;
  CHECK(probe(1) == 43, "plug_probe(1) == 43 executed from the window");

  /* 4 -- W^X is real */
  CHECK(maps_has_rx(probe_at), "text page is r-xp in /proc/self/maps");

  /* 5 -- overlap refused */
  err[0] = 0;
  r = qosp_load_plugin_bytes((const char *)qa, len, err, sizeof err);
  CHECK(r < 0 && strstr(err, "overlaps"), "second load refused: overlap");

  /* 6 -- corruption refused (flip one IMAGE byte, sha catches it) */
  qa[len - 1] ^= 0xff;
  err[0] = 0;
  r = qosp_load_plugin_bytes((const char *)qa, len, err, sizeof err);
  CHECK(r < 0 && strstr(err, "malformed"), "corrupt archive refused (sha256)");

  printf("plugload_check: %s\n", fails ? "FAIL" : "ALL PASS");
  return fails ? 1 : 0;
}
