/* stubs.c (posix) — capabilities the hosted HAL does not grant.
 *
 * Only the MMIO tier lives here now (the actor surface is the real
 * runtime/core/actors.c).  Programs that link these and never call
 * them cost nothing; programs that CALL them get an honest panic
 * naming the missing capability.  Programs whose own code references
 * capabilities with no stub at all (Pin.*, bitsLE, ...) fail at LINK
 * time with the fpr_g_ name -- the image's imports are its capability
 * manifest, and the posix HAL simply doesn't export the bus tier.
 */
#include "fpr.h"
#include <stdio.h>
#include <string.h>

static V h_file_read(V pathv) {
  if (ISINT(pathv) || ((hdr_t *)pathv)->tid != T_STR)
    fpr_cpanic("fileRead: path must be a String");
  str_t *pathstr = (str_t *)pathv;
  char path[1024];
  if (pathstr->len >= sizeof path) fpr_cpanic("fileRead: path too long");
  memcpy(path, pathstr->bytes, pathstr->len);
  path[pathstr->len] = 0;
  FILE *file = fopen(path, "rb");
  if (!file) fpr_cpanic("fileRead: open failed");
  if (fseek(file, 0, SEEK_END) || ftell(file) < 0) {
    fclose(file);
    fpr_cpanic("fileRead: seek failed");
  }
  long size = ftell(file);
  rewind(file);
  str_t *result = (str_t *)fpr_alloc(sizeof(str_t) + (uw)size);
  result->tid = T_STR; result->var = 0; result->len = (uw)size;
  if (fread(result->bytes, 1, (size_t)size, file) != (size_t)size) {
    fclose(file);
    fpr_cpanic("fileRead: read failed");
  }
  fclose(file);
  return (V)result;
}
FPR_FN(fpr_g_fileRead, h_file_read, 1);

/* the register tier, backed by net.c's pseudo-address dispatch: the
 * SAME reg_t/T_REGISTER values as virt, a different "bus" behind them */
uw fpr_posix_mmio_read(uw addr, uint32_t width);
void fpr_posix_mmio_write(uw addr, uw v, uint32_t width);

static V mkreg(V dev, V off, uint32_t width) {
  if (ISINT(dev) || TID(dev) != T_DEVICE) fpr_cpanic("reg: not a Device");
  if (!ISINT(off)) fpr_cpanic("reg: offset not an Int");
  reg_t *r = (reg_t *)fpr_alloc(sizeof(reg_t));
  r->tid = T_REGISTER;
  r->var = width;
  r->addr = ((fpr_dev_t *)dev)->base + (uw)UNTAG(off);
  return (V)r;
}
static V h_reg8(V d, V o) { return mkreg(d, o, 1); }
static V h_reg32(V d, V o) { return mkreg(d, o, 4); }
static V h_read(V rv) {
  if (ISINT(rv) || TID(rv) != T_REGISTER) fpr_cpanic("read: not a Register");
  reg_t *r = (reg_t *)rv;
  return TAG((sw)fpr_posix_mmio_read(r->addr, r->var));
}
static V h_write(V rv, V x) {
  if (ISINT(rv) || TID(rv) != T_REGISTER) fpr_cpanic("write: not a Register");
  reg_t *r = (reg_t *)rv;
  uw v;
  if (ISINT(x)) v = (uw)UNTAG(x);
  else if (TID(x) == T_BITS) v = ((bits_t *)x)->val;
  else fpr_cpanic("write: value must be Int or Array Bit");
  fpr_posix_mmio_write(r->addr, v, r->var);
  return (V)&fpr_unit;
}
FPR_FN(fpr_g_reg8, h_reg8, 2);
FPR_FN(fpr_g_reg32, h_reg32, 2);
FPR_FN(fpr_g_read, h_read, 1);
FPR_FN(fpr_g_write, h_write, 2);

/* the pin bus: absent hardware, present SYMBOLS.  The svc URL router
 * (mods/svc.fpr) references every route it can dispatch, so a hosted
 * image that merely LINKS the funnel must not fail on the pin tier --
 * the capability gate still refuses ungranted /pins first, and a
 * GRANTED /pins on a host with no pin bus gets the honest panic. */
static V h_pin_mode(V n, V m) { (void)n; (void)m; fpr_cpanic("Pin.mode: no pin bus on the posix HAL"); return (V)&fpr_unit; }
static V h_pin_write(V n, V v) { (void)n; (void)v; fpr_cpanic("Pin.write: no pin bus on the posix HAL"); return (V)&fpr_unit; }
static V h_pin_read(V n) { (void)n; fpr_cpanic("Pin.read: no pin bus on the posix HAL"); return (V)&fpr_unit; }
FPR_FN(fpr_g_Pin_x2emode, h_pin_mode, 2);
FPR_FN(fpr_g_Pin_x2ewrite, h_pin_write, 2);
FPR_FN(fpr_g_Pin_x2eread, h_pin_read, 1);
static V h_pin_wire(V n, V f) { (void)n; (void)f; fpr_cpanic("Pin.wire: no pin bus on the posix HAL"); return (V)&fpr_unit; }
FPR_FN(fpr_g_Pin_x2ewire, h_pin_wire, 2);

/* Sys.storeReq -- the storage syscall channel, hosted.  Under qosp the
 * host's kv trampoline serves this (runtime/portable/store.c); the
 * co-compiled posix image gets the same record framing against a file
 * named by FPR_STORE, or the standalone "no disk" Result when unset --
 * matching entry.c's no-channel behavior, so a program like pshell
 * runs identically both ways. */
#include <stdlib.h>
static V h_store_req(V tagv, V payv) {
  if (ISINT(tagv) == 0) fpr_cpanic("Sys.storeReq: tag must be an Int");
  if (ISINT(payv) || ((hdr_t *)payv)->tid != T_STR)
    fpr_cpanic("Sys.storeReq: payload must be a String");
  const char *path = getenv("FPR_STORE");
  if (!path || !*path) return fpr_mkresult(1, "no disk");
  str_t *s = (str_t *)payv;
  uw tag = (uw)UNTAG(tagv);
  if (tag == 2) {
    FILE *f = fopen(path, "ab");
    if (!f) return fpr_mkresult(1, "storage error");
    fprintf(f, "%llu\n", (unsigned long long)s->len);
    fwrite(s->bytes, 1, s->len, f);
    fputc('\n', f);
    fclose(f);
    return fpr_mkresult(0, "");
  }
  if (tag == 3) {
    static char out[256 * 1024];
    FILE *f = fopen(path, "rb");
    uw n = 0;
    if (f) {
      char line[32];
      while (fgets(line, sizeof line, f)) {
        unsigned long long rl = strtoull(line, 0, 10);
        if (n + rl > sizeof out) break;
        if (fread(out + n, 1, rl, f) != rl) break;
        n += rl;
        fgetc(f);
      }
      fclose(f);
    }
    return fpr_mkresultn(0, out, n);
  }
  if (tag == 5) { /* record index: "seq off len" per record (see store.c) */
    static char out[64 * 1024];
    FILE *f = fopen(path, "rb");
    uw n = 0;
    if (f) {
      char line[32];
      unsigned long long off = 0, seq = 0;
      while (fgets(line, sizeof line, f)) {
        unsigned long long rl = strtoull(line, 0, 10);
        unsigned long long hdr = (unsigned long long)strlen(line);
        char rec[64];
        int rn = snprintf(rec, sizeof rec, "%llu %llu %llu\n", seq, off + hdr, rl);
        if (n + (uw)rn > sizeof out) break;
        memcpy(out + n, rec, (size_t)rn);
        n += (uw)rn;
        if (fseek(f, (long)rl + 1, SEEK_CUR)) break;
        off += hdr + rl + 1;
        seq++;
      }
      fclose(f);
    }
    return fpr_mkresultn(0, out, n);
  }
  return fpr_mkresult(1, "storage error");
}
FPR_FN(fpr_g_Sys_x2estoreReq, h_store_req, 2);


/* Sys.attachQa on the co-compiled posix image: same contract as under
 * qosp, host = ourselves.  Reads qos-apps/<name> (or ./<name>), parses
 * the QAR1 container minimally (magic + manifest_len header), maps the
 * plugin slot (qos_abi.h addresses; unmapped in a posix process, so a
 * MAP_FIXED_NOREPLACE anonymous mapping first), elf-loads, applies the
 * W^X split, and registers the module table. */
#include <sys/mman.h>
#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE MAP_FIXED
#endif
#define QOS_PLUG_BASE_P 0x408000000ul
#define QOS_PLUG_SIZE_P (16ul << 20)
int fpr_mod_attach(const uw *tab);
static V h_attach_qa(V namev) {
  if (ISINT(namev) || ((hdr_t *)namev)->tid != T_STR)
    fpr_cpanic("Sys.attachQa: name must be a String");
  /* v1 scope: plugins are linked against the QOSP shell image's
   * addresses (build/qosapp.elf).  A co-compiled posix binary has its
   * own layout, so loading that image here would call into the wrong
   * addresses -- refuse honestly; the caller falls back.  (posix
   * plugin support = the same recipe against posix.bin's nm, later.) */
  if (1) return fpr_mkresult(1, "plugin loading is qosp-only (v1)");
  static int loaded;
  if (loaded) return fpr_mkresult(1, "plugin slot already occupied");
  str_t *s = (str_t *)namev;
  char path[256];
  snprintf(path, sizeof path, "qos-apps/%.*s", (int)s->len, (const char *)s->bytes);
  FILE *f = fopen(path, "rb");
  if (!f) {
    snprintf(path, sizeof path, "%.*s", (int)s->len, (const char *)s->bytes);
    f = fopen(path, "rb");
  }
  if (!f) return fpr_mkresult(1, "no such plugin");
  static unsigned char qab[8 << 20];
  size_t qn = fread(qab, 1, sizeof qab, f);
  fclose(f);
  if (qn < 6 || memcmp(qab, "QAR1\n", 5) != 0)
    return fpr_mkresult(1, "not a QAR1 container");
  /* QAR1 is TEXT-framed (qa.c): "QAR1\n", then "NAME off len\n" lines,
   * a blank line, then the payload bytes the offsets index into */
  const char *q = (const char *)qab + 5, *qend = (const char *)qab + qn;
  const unsigned char *elf = 0;
  uw elflen = 0;
  unsigned long eoff = 0, elen = 0;
  int have = 0;
  while (q < qend && *q != '\n') {
    char nm[32];
    unsigned long o, l;
    if (sscanf(q, "%31s %lu %lu", nm, &o, &l) != 3)
      return fpr_mkresult(1, "malformed QAR1 table");
    if (!strcmp(nm, "ELF")) { eoff = o; elen = l; have = 1; }
    while (q < qend && *q != '\n') q++;
    q++;
  }
  if (q >= qend || !have) return fpr_mkresult(1, "no ELF section");
  q++; /* the blank line */
  uw pay0 = (uw)(q - (const char *)qab);
  if (pay0 + eoff + elen > qn) return fpr_mkresult(1, "truncated container");
  elf = qab + pay0 + eoff;
  elflen = elen;
  if (mmap((void *)QOS_PLUG_BASE_P, QOS_PLUG_SIZE_P, PROT_READ | PROT_WRITE,
           MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NOREPLACE, -1,
           0) == MAP_FAILED)
    return fpr_mkresult(1, "plugin slot mmap failed");
  fpr_elf_load_t ld =
      fpr_elf_load(elf, elflen, (void *)QOS_PLUG_BASE_P, QOS_PLUG_SIZE_P);
  if (!ld.ok) return fpr_mkresult(1, ld.err);
  uintptr_t pg = 4096;
  uintptr_t xend = ((uintptr_t)ld.exec_end + pg - 1) & ~(pg - 1);
  if (ld.exec_end == 0 || (uintptr_t)ld.rw_start < xend)
    return fpr_mkresult(1, "plugin not page-separated");
  if (mprotect((void *)QOS_PLUG_BASE_P, xend - QOS_PLUG_BASE_P,
               PROT_READ | PROT_EXEC))
    return fpr_mkresult(1, "plugin mprotect failed");
  __builtin___clear_cache((char *)QOS_PLUG_BASE_P, (char *)ld.image_end);
  if (fpr_mod_attach((const uw *)ld.entry))
    return fpr_mkresult(1, "module registry full");
  fprintf(stderr, "[plug] %s: table at %p\n", path, ld.entry);
  loaded = 1;
  return fpr_mkresult(0, "");
}
FPR_FN(fpr_g_Sys_x2eattachQa, h_attach_qa, 1);
