/* entry.c (qosapp) -- qos_app_entry: proc_entry.c's hosted sibling.
 *
 * Same job as fpr_process_entry on virt (docs/PROCESS-LOADING.md):
 * turn a granted arena into a running single-hart FPRISC world and
 * hand back the main actor's result.  The differences are exactly the
 * platform's:
 *
 *   - the hart cell is a PLAIN GLOBAL (fpr_posix_hart, FPR_QOSAPP in
 *     fpr.h), not the tp register -- so there is no save/restore dance
 *     with the caller: the host's own hart state lives in the HOST
 *     image's TLS, a different symbol in a different image.  The
 *     whole tp essay in proc_entry.c dissolves.
 *   - the HAL arrives as a table pointer in the boot record instead of
 *     resolving at link time; qosapp/hal.c holds the dispatching
 *     implementations of the hal_* obligations and the fpr_g_ shims.
 *   - the result leaves as a rendered string, not a V (the host has no
 *     runtime to read a V with).
 */
#include "fpr.h"
#include "qos_abi.h"

/* the cells --target=qx64 code loads RIP-relative (X64.hs deTlsQosApp),
 * and runtime.c's arity-7/8 cast cases write (FPR_TLS = plain here) */
fpr_hart_t *fpr_posix_hart;
uw fpr_x64_a6, fpr_x64_a7;

const qos_hal_t *qos_hal; /* installed before anything can call out */

static const unsigned char *g_caps_bytes;
static uw g_caps_len;
static V h_sys_caps(V d) {
  (void)d;
  return (V)fpr_mkstr(g_caps_bytes ? g_caps_bytes : (const unsigned char *)"",
                      g_caps_len);
}
FPR_FN(fpr_g_Sys_x2ecaps, h_sys_caps, 1);

/* the storage syscall (the host's System.qa-analogue): tag 2 = kv
 * append, tag 3 = kv replay -- the FPRISC surface is Sys.storeReq,
 * byte-compatible with the virt process model's channel */
static int64_t (*g_syscall)(uint64_t, const char *, uint64_t, char *, uint64_t);
static char g_sysout[256 * 1024];
static V h_sys_store_req(V tagv, V payv) {
  if (!ISINT(tagv)) fpr_cpanic("Sys.storeReq: tag must be an Int");
  if (ISINT(payv) || ((hdr_t *)payv)->tid != T_STR)
    fpr_cpanic("Sys.storeReq: payload must be a String");
  if (!g_syscall) return fpr_mkresult(1, "no syscall channel (standalone run)");
  str_t *s = (str_t *)payv;
  int64_t r = g_syscall((uw)UNTAG(tagv), (const char *)s->bytes, s->len,
                        g_sysout, sizeof g_sysout);
  if (r == -2) return fpr_mkresult(1, "no disk");
  if (r < 0) return fpr_mkresult(1, "storage error");
  return fpr_mkresultn(0, g_sysout, (uw)r);
}
FPR_FN(fpr_g_Sys_x2estoreReq, h_sys_store_req, 2);

int64_t qos_app_entry(const qos_boot_t *boot, char *result_out,
                      uw result_cap) {
  extern char _bss_start[], _bss_end[];
  /* elfload.c zeroes memsz-filesz tails, which covers .bss when the
   * linker merges it into the loaded PT_LOAD; clearing again here is
   * cheap and makes this function correct on its own (same reasoning
   * as proc_entry.c).  NOTE this runs before any global above is
   * trusted -- it also zeroes them, which is their initial state. */
  for (char *p = _bss_start; p < _bss_end; p++) *p = 0;

  if (!boot || boot->abi_version != QOS_ABI_VERSION) return -1;
  qos_hal = boot->hal; /* first: panics from here on can reach putc */
  if (!qos_hal || qos_hal->version != QOS_ABI_VERSION) return -1;

  fpr_hart_t *h = &fpr_harts[0];
  h->id = 0;
  /* the loader's grant IS this process's first slab -- same pool
   * machinery as a machine boot, different lower allocator (grants
   * instead of buddy; fpr_alloc's process branch), verbatim the
   * proc_entry.c shape */
  h->pool.cur = 0;
  h->pool.allocated = 0;
  for (int i = 0; i < FPR_NBUCKETS; i++) h->pool.buckets[i] = 0;
  {
    fpr_slab_t *sl = (fpr_slab_t *)boot->heap_base;
    sl->next = 0;
    sl->owner = &h->pool;
    sl->escaped = 0;
    sl->hp = (char *)(sl + 1);
    sl->end = (char *)boot->heap_base + boot->heap_size;
    h->pool.cur = sl;
  }
  h->current = 0;
  h->rq_head = h->rq_tail = 0;
  h->idle = 0;
  h->fuel_preempts = 0;
  h->rpos = 0;
  fpr_set_tp(h); /* FPR_POSIX form: assigns the plain global */

  g_caps_bytes = boot->caps;
  g_caps_len = boot->caps_len;
  g_syscall = boot->syscall_fn;
  fpr_grow_memory = (fpr_grant_t (*)(uw))boot->grow; /* layout-identical */
  fpr_is_process = 1;
  fpr_process_done = 0;

  fpr_actors_init(); /* actor 0 (main) onto hart 0 */
  fpr_hart_main(0);  /* returns when actor 0 finishes (fpr_is_process
                      * routes the exit through fpr_process_done) */

  V result = fpr_process_result_get();
  /* render into the host's buffer: fpr_prim_fn_str allocates the
   * string in OUR arena, which stays mapped until the host tears the
   * arena down -- but copying out means the host never has to care */
  V s = fpr_prim_fn_str(result);
  str_t *st = (str_t *)s;
  uw n = st->len < result_cap - 1 ? st->len : result_cap - 1;
  for (uw i = 0; i < n; i++) result_out[i] = (char)st->bytes[i];
  result_out[n] = 0;
  return 0;
}
