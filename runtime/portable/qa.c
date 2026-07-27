/* qa.c -- the QAR1 container + manifest-TOML-subset reader (qa.h).
 * Mirrors the byte layout and rules in docs/QA-FORMAT.md; the FPRISC
 * launcher in system.fpr and this file must keep agreeing, so any
 * format change lands in both (and in tools/mkqa.py). */
#include "qa.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int fail(const char *why) {
  fprintf(stderr, "qa: %s\n", why);
  return -1;
}

/* one "NAME OFFSET LENGTH" table line; returns chars consumed or 0 */
static int table_line(const char *p, const char *end, char *name, uint64_t *off,
                      uint64_t *len) {
  const char *q = p;
  int n = 0;
  while (q < end && *q != ' ' && *q != '\n' && n < 31) name[n++] = *q++;
  name[n] = 0;
  if (q >= end || *q != ' ') return 0;
  *off = strtoull(q + 1, (char **)&q, 10);
  if (q >= end || *q != ' ') return 0;
  *len = strtoull(q + 1, (char **)&q, 10);
  if (q >= end || *q != '\n') return 0;
  return (int)(q + 1 - p);
}

static void copy_tok(char *dst, uint64_t cap, const char *src, uint64_t n) {
  if (n >= cap) n = cap - 1;
  memcpy(dst, src, n);
  dst[n] = 0;
}

/* the manifest: `key = value` lines, values "quoted" or bare;
 * [section.sub] opens a table (docs/QA-FORMAT.md's exact subset) */
static void parse_manifest(qa_t *qa) {
  const char *p = (const char *)qa->manifest;
  const char *end = p + qa->manifest_len;
  int in_req = 0, in_opt = 0;
  while (p < end) {
    const char *nl = memchr(p, '\n', (size_t)(end - p));
    const char *le = nl ? nl : end;
    /* trim */
    while (p < le && (*p == ' ' || *p == '\t')) p++;
    if (p < le && *p == '[') {
      in_req = (le - p >= 22) && !strncmp(p, "[permissions.required]", 22);
      in_opt = (le - p >= 22) && !strncmp(p, "[permissions.optional]", 22);
    } else if (p < le && *p != '#') {
      const char *eq = memchr(p, '=', (size_t)(le - p));
      if (eq) {
        const char *k = p, *ke = eq;
        while (ke > k && (ke[-1] == ' ' || ke[-1] == '\t')) ke--;
        const char *v = eq + 1;
        while (v < le && (*v == ' ' || *v == '\t')) v++;
        const char *ve = le;
        while (ve > v && (ve[-1] == ' ' || ve[-1] == '\t' || ve[-1] == '\r')) ve--;
        /* unquote both sides if quoted */
        uint64_t kn = (uint64_t)(ke - k), vn = (uint64_t)(ve - v);
        if (kn >= 2 && k[0] == '"' && k[kn - 1] == '"') { k++; kn -= 2; }
        if (vn >= 2 && v[0] == '"' && v[vn - 1] == '"') { v++; vn -= 2; }
        if (in_req || in_opt) {
          if (qa->nperms < QA_MAX_PERMS) {
            qa_perm_t *pm = &qa->perms[qa->nperms++];
            copy_tok(pm->url, sizeof pm->url, k, kn);
            copy_tok(pm->mode, sizeof pm->mode, v, vn);
            pm->required = in_req;
            pm->granted = 0;
          }
        } else if (kn == 4 && !strncmp(k, "name", 4))
          copy_tok(qa->name, sizeof qa->name, v, vn);
        else if (kn == 2 && !strncmp(k, "id", 2))
          copy_tok(qa->id, sizeof qa->id, v, vn);
        else if (kn == 8 && !strncmp(k, "loadMode", 8))
          copy_tok(qa->load_mode, sizeof qa->load_mode, v, vn);
      }
    }
    if (!nl) break;
    p = nl + 1;
  }
}

int qa_load(const char *path, qa_t *qa) {
  memset(qa, 0, sizeof *qa);
  FILE *f = fopen(path, "rb");
  if (!f) return fail("cannot open archive");
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  fseek(f, 0, SEEK_SET);
  if (sz <= 0) { fclose(f); return fail("empty archive"); }
  qa->bytes = malloc((size_t)sz + 1);
  qa->bytes[sz] = 0; /* strtoull in table_line stays in bounds at EOF */
  qa->len = (uint64_t)sz;
  if (fread(qa->bytes, 1, (size_t)sz, f) != (size_t)sz) {
    fclose(f);
    return fail("short read");
  }
  fclose(f);

  const char *p = (const char *)qa->bytes;
  const char *end = p + qa->len;
  if (qa->len < 5 || memcmp(p, "QAR1\n", 5)) return fail("bad magic (not QAR1)");
  p += 5;
  /* the section table: one line per section, blank line ends it */
  struct { char name[32]; uint64_t off, len; } secs[8];
  int nsecs = 0;
  while (p < end && *p != '\n') {
    if (nsecs >= 8) return fail("too many sections");
    int c = table_line(p, end, secs[nsecs].name, &secs[nsecs].off, &secs[nsecs].len);
    if (!c) return fail("malformed section-table line");
    nsecs++;
    p += c;
  }
  if (p >= end) return fail("truncated: no blank line after table");
  p++; /* the blank line: payloads start here */
  uint64_t pay0 = (uint64_t)(p - (const char *)qa->bytes);

  for (int i = 0; i < nsecs; i++) {
    if (pay0 + secs[i].off + secs[i].len > qa->len)
      return fail("section runs past end of archive");
    const unsigned char *sp = qa->bytes + pay0 + secs[i].off;
    if (!strcmp(secs[i].name, "MANIFEST")) {
      qa->manifest = sp;
      qa->manifest_len = secs[i].len;
    } else if (!strcmp(secs[i].name, "ELF")) {
      qa->elf = sp;
      qa->elf_len = secs[i].len;
    } /* unknown sections ignored by design */
  }
  if (!qa->manifest) return fail("no MANIFEST section");
  if (!qa->elf || qa->elf_len < 16) return fail("no usable ELF section");
  parse_manifest(qa);
  if (!qa->id[0]) return fail("manifest has no id");
  return 0;
}

void qa_free(qa_t *qa) {
  free(qa->bytes);
  qa->bytes = 0;
}

uint64_t qa_caps_serialize(const qa_t *qa, char *out, uint64_t cap) {
  uint64_t n = 0;
#define PUT(s, l)                                    \
  do {                                               \
    uint64_t _l = (l);                               \
    if (n + _l >= cap) return n;                     \
    memcpy(out + n, (s), _l);                        \
    n += _l;                                         \
  } while (0)
  PUT(qa->id, strlen(qa->id));
  PUT("\n", 1);
  for (int i = 0; i < qa->nperms; i++)
    if (qa->perms[i].granted) {
      PUT(qa->perms[i].url, strlen(qa->perms[i].url));
      PUT(" ", 1);
      PUT(qa->perms[i].mode, strlen(qa->perms[i].mode));
      PUT("\n", 1);
    }
#undef PUT
  out[n] = 0;
  return n;
}
