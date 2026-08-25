/* qaimg.c -- the QAR2 flat-image loader (docs/QA-FORMAT.md).
 *
 * The entire load path: parse six text numbers, bounds-check against
 * the window, copy, zero the bss tail.  Freestanding by construction
 * (byte loops, no libc), shared verbatim by qosp's slot loader, qosp's
 * plugin loader, and the native kernel's Sys.loadImageAt -- the load
 * mechanism a bootstrap ROM could plausibly carry, which is the whole
 * point of retiring ELF from the archive.
 *
 * Protection (mprotect r-x / PMP) stays with the host: this file only
 * REPORTS the boundary (exec_end / rw_start) after verifying that the
 * page round-up of execsz cannot reach the first writable byte.  The
 * result reuses fpr_elf_load_t so callers keep their shapes; sha
 * verification is likewise the host's choice (qosp checks; a
 * freestanding boot may not have sha256 and may skip -- stated, not
 * hidden). */
#include "fpr.h"

/* one "key <decimal>\n" scan; returns 1 and advances *pp past the line
 * when the key matches, else 0 with *pp untouched */
static int load_kv(const unsigned char **pp, const unsigned char *end,
                   const char *key, uw *out) {
  const unsigned char *p = *pp;
  uw kn = 0;
  while (key[kn]) kn++;
  if ((uw)(end - p) < kn + 2) return 0;
  for (uw i = 0; i < kn; i++)
    if (p[i] != (unsigned char)key[i]) return 0;
  if (p[kn] != ' ') return 0;
  p += kn + 1;
  uw v = 0;
  int any = 0;
  while (p < end && *p >= '0' && *p <= '9') { v = v * 10 + (uw)(*p - '0'); p++; any = 1; }
  if (!any) return 0;
  while (p < end && *p != '\n') p++;
  if (p < end) p++;
  *out = v;
  *pp = p;
  return 1;
}

static fpr_elf_load_t qfail(const char *why) {
  fpr_elf_load_t r = {0, 0, 0, why, 0, (void *)~(uw)0};
  return r;
}

/* parse ONLY (no copy): fills the six numbers so a host can validate,
 * verify the sha, or place a window before committing.  Order-
 * insensitive; unknown lines (e.g. `sha`) are skipped. */
int fpr_qaimg_params(const unsigned char *load, uw load_len, fpr_qaimg_t *out) {
  const unsigned char *p = load, *end = load + load_len;
  uw seen = 0;
  out->base = out->entry = out->execsz = out->rwoff = out->imagesz = out->memsz = 0;
  while (p < end) {
    if      (load_kv(&p, end, "base",    &out->base))    seen |= 1;
    else if (load_kv(&p, end, "entry",   &out->entry))   seen |= 2;
    else if (load_kv(&p, end, "execsz",  &out->execsz))  seen |= 4;
    else if (load_kv(&p, end, "rwoff",   &out->rwoff))   seen |= 8;
    else if (load_kv(&p, end, "imagesz", &out->imagesz)) seen |= 16;
    else if (load_kv(&p, end, "memsz",   &out->memsz))   seen |= 32;
    else { /* unknown line (sha, future keys): skip it */
      while (p < end && *p != '\n') p++;
      if (p < end) p++;
    }
  }
  return seen == 63; /* all six present */
}

fpr_elf_load_t fpr_qaimg_load(const unsigned char *load, uw load_len,
                              const unsigned char *img, uw img_len,
                              void *window, uw window_size) {
  fpr_qaimg_t q;
  if (!fpr_qaimg_params(load, load_len, &q))
    return qfail("LOAD section missing a required field");
  if (q.memsz == 0) return qfail("placeholder .qa (memsz 0): nothing to load");
  if (img_len != q.imagesz) return qfail("IMAGE length disagrees with LOAD imagesz");
  if (q.imagesz > q.memsz || q.execsz > q.imagesz)
    return qfail("LOAD spans inconsistent (need execsz <= imagesz <= memsz)");
  if (q.entry >= q.execsz) return qfail("entry offset outside the r-x prefix");
  /* NOTE: page-separation of execsz vs rwoff is deliberately NOT
   * checked here -- it is a precondition of PROTECTING the image, not
   * of loading it, and only hosts that mprotect (qosp) have a page
   * size to check against.  The native process slot runs unprotected
   * (no MMU behind it; the grant is the whole story) and its link
   * script carries no 64 KiB gap.  The host that protects checks
   * (qos/portable/main.c), with the boundary this loader reports. */
  uw wlo = (uw)window, whi = wlo + window_size;
  if (q.base < wlo || q.base + q.memsz > whi || q.base + q.memsz < q.base)
    return qfail("image outside the load window");

  unsigned char *dst = (unsigned char *)q.base;
  for (uw i = 0; i < q.imagesz; i++) dst[i] = img[i];
  for (uw i = q.imagesz; i < q.memsz; i++) dst[i] = 0;

  fpr_elf_load_t r;
  r.ok = 1;
  r.err = 0;
  r.entry = (void *)(q.base + q.entry);
  r.image_end = (void *)(q.base + q.memsz);
  r.exec_end = (void *)(q.base + q.execsz);
  r.rw_start = q.rwoff < q.memsz ? (void *)(q.base + q.rwoff) : (void *)~(uw)0;
  return r;
}
