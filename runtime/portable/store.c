/* store.c -- qosp's System.qa-analogue storage trampoline.
 *
 * Tag-compatible with the virt process model's channel (process.c /
 * proc_entry.c): tag 2 = kv append, tag 3 = kv replay, and capability
 * scoping is enforced HERE, structurally -- the app never names a
 * path; the host derives qos-store/<id>.kv from the id it bound at
 * launch, exactly the way System.qa rewrites the relative "kv" url to
 * apps/<id>/<id>.kv.  The append-only discipline maps onto O_APPEND:
 * records go on the end, replay returns the whole log, readers fold.
 *
 * A record is the payload's bytes, length-prefixed ("%lu\n" + bytes +
 * "\n") so binary payloads survive round trips; replay concatenates
 * the raw record payloads in append order, which is what the FPRISC
 * kv fold consumes. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

static char g_path[192];

void qosp_store_bind(const char *app_id) {
  mkdir("qos-store", 0755); /* best-effort; open errors are the real gate */
  snprintf(g_path, sizeof g_path, "qos-store/%s.kv", app_id);
}

int64_t qosp_store_call(uint64_t tag, const char *pay, uint64_t plen, char *out,
                        uint64_t outcap) {
  if (!g_path[0]) return -2; /* no app bound: "no disk" to the app */
  if (tag == 2) { /* append */
    FILE *f = fopen(g_path, "ab");
    if (!f) return -1;
    fprintf(f, "%llu\n", (unsigned long long)plen);
    fwrite(pay, 1, plen, f);
    fputc('\n', f);
    fclose(f);
    return 0;
  }
  if (tag == 3) { /* replay: concatenated record payloads */
    FILE *f = fopen(g_path, "rb");
    if (!f) return 0; /* nothing appended yet: empty replay */
    uint64_t n = 0;
    char line[32];
    while (fgets(line, sizeof line, f)) {
      unsigned long long rl = strtoull(line, 0, 10);
      if (n + rl > outcap) break; /* honest truncation at capacity */
      if (fread(out + n, 1, rl, f) != rl) break;
      n += rl;
      fgetc(f); /* the record's trailing newline */
    }
    fclose(f);
    return (int64_t)n;
  }
  return -3;
}
