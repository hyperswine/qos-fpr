/* proc_entry.c -- the process entry point (docs/PROCESS-LOADING.md).
 *
 * Compiled into an APP image in place of crt0.S. `fpr_process_entry`
 * is a PLAIN CALLABLE C FUNCTION (link-app.ld's ENTRY() just points
 * the ELF header's e_entry at it -- no assembly needed, since we are
 * not booting hardware here, we're being called by an already-running
 * loader on an already-running hart).
 *
 * What it does NOT do, on purpose, contrasted with crt0.S:
 *   - no secondary-hart wfi-park dance (a loaded process is single-hart
 *     in this design pass; SMP-within-a-process is future work)
 *   - no fpr_rvv_enable() call (mstatus.VS is hart-global; if the
 *     loader's hart already enabled it, it's already on for us)
 *   - no reading of fixed _heap_start/_heap_end linker symbols for the
 *     heap -- the CALLER hands us our arena, because it came from
 *     System.qa's buddy allocator, not from our own link
 */
#include "fpr.h"

/* the granted capability blob (System.qa serializes "appid\nurl mode\n"
 * lines).  Stashed at entry; the FPRISC side reads it via Sys.caps and
 * enforces its own gate -- equal strength to the co-compiled model,
 * since neither has hardware isolation behind it. */
static const unsigned char *g_caps_bytes;
static uw g_caps_len;
static V h_sys_caps(V d) {
  (void)d;
  return (V)fpr_mkstr(g_caps_bytes ? g_caps_bytes : (const unsigned char *)"", g_caps_len);
}
FPR_FN(fpr_g_Sys_x2ecaps, h_sys_caps, 1);

/* the storage syscall (System.qa's trampoline): tag 2 = kv append,
 * tag 3 = kv replay.  The FPRISC surface is Sys.storeReq. */
static sw (*g_syscall)(uw, const char *, uw, char *, uw);
static char g_sysout[256 * 1024];
static V h_sys_store_req(V tagv, V payv) {
  if (!ISINT(tagv)) fpr_cpanic("Sys.storeReq: tag must be an Int");
  if (ISINT(payv) || ((hdr_t *)payv)->tid != T_STR) fpr_cpanic("Sys.storeReq: payload must be a String");
  if (!g_syscall) return fpr_mkresult(1, "no syscall channel (standalone run)");
  str_t *s = (str_t *)payv;
  sw r = g_syscall((uw)UNTAG(tagv), (const char *)s->bytes, s->len, g_sysout, sizeof g_sysout);
  if (r == -2) return fpr_mkresult(1, "no disk");
  if (r < 0) return fpr_mkresult(1, "storage error");
  return fpr_mkresultn(0, g_sysout, (uw)r);
}
FPR_FN(fpr_g_Sys_x2estoreReq, h_sys_store_req, 2);

V fpr_process_entry(void *heap_base, uw heap_size, fpr_grant_t (*grow)(uw want_bytes),
                    const unsigned char *caps, uw caps_len,
                    sw (*syscall_fn)(uw, const char *, uw, char *, uw)) {
  extern char _bss_start[], _bss_end[];
  /* tp is a PHYSICAL CPU REGISTER, global to the hart -- fpr_set_tp
   * below repoints it at OUR OWN fpr_harts[0] so this image's
   * fpr_hart()/fpr_alloc work correctly while we run. But the CALLER
   * (System.qa) relies on tp pointing at ITS OWN hart struct for its
   * OWN fpr_alloc calls, and does not expect a plain function call to
   * silently repoint a register out from under it. Save it here,
   * restore it right before returning (every exit path -- there is
   * only one, the end of this function) or every fpr_alloc call in
   * System.qa after this returns reads through tp into the now-freed
   * process slot: hp/heap_end become garbage, and the FIRST symptom is
   * a spurious "heap exhausted" (or worse, silent corruption) with no
   * apparent connection to process loading at all. */
  fpr_hart_t *caller_h;
  __asm__ volatile("mv %0, tp" : "=r"(caller_h));
  /* elfload.c already zeroes each segment's memsz-filesz tail, which
   * covers .bss when the linker merges it into the same PT_LOAD as
   * .data (the common case with this MEMORY layout's single rwx
   * region) -- clearing it again here is cheap and makes this function
   * correct on its own, independent of that merging detail. */
  for (char *p = _bss_start; p < _bss_end; p++) *p = 0;

  fpr_hart_t *h = &fpr_harts[0];
  h->id = 0;
  /* slab refactor: the loader's grant IS this process's first slab --
   * same pool machinery as a machine boot, different lower allocator
   * (grants instead of buddy; see fpr_alloc's process branch). */
  h->pool.cur = 0;
  h->pool.allocated = 0;
  {
    fpr_slab_t *sl = (fpr_slab_t *)heap_base;
    sl->next = 0;
    sl->owner = &h->pool;
    sl->escaped = 0;
    sl->hp = (char *)(sl + 1);
    sl->end = (char *)heap_base + heap_size;
    h->pool.cur = sl;
    /* buckets are OUT-OF-LINE since the reclamation refactor (fpr.h:
     * `void **buckets`, recycled via fpr_bkt_take/bkt_put).  This
     * function predated that and zeroed buckets[i] as if the array
     * were inline -- 512 stores through the NULL left by the bss
     * clear, into unmapped low memory with no trap handler: the hart
     * wedged silently at every process launch.  fpr_bkt_take can't
     * serve us yet (fpr_is_process/grow aren't set until below, so it
     * would take the buddy path), and a 4 KiB grant round-trip is
     * silly when we are sitting on a fresh multi-hundred-KiB slab:
     * carve the array from our own slab -- it is part of this
     * process's fixed footprint and dies with the slot. */
    h->pool.buckets = (void **)sl->hp;
    sl->hp += FPR_NBUCKETS * sizeof(void *);
    for (int i = 0; i < FPR_NBUCKETS; i++) h->pool.buckets[i] = 0;
  }
  h->current = 0;
  h->rq_head = h->rq_tail = 0;
  h->idle = 0;
  h->fuel_preempts = 0;
  h->rpos = 0;
  fpr_set_tp(h);

  g_caps_bytes = caps;
  g_caps_len = caps_len;
  g_syscall = syscall_fn;
  fpr_grow_memory = grow;
  fpr_is_process = 1;
  fpr_process_done = 0;

  fpr_actors_init(); /* spawns actor 0 (main), enqueues it on hart 0 */
  fpr_hart_main(0);  /* runs hart_loop; returns when actor 0 finishes
                       * (fpr_is_process routes the exit through
                       * fpr_process_done instead of fpr_exit's halt --
                       * see the essay in actors.c) */
  /* fpr_process_result_get() reads THIS IMAGE's own actors.c copy of
   * fpr_process_result -- correct here because THIS image is the one
   * that just set it. Returning it (not leaving the caller to call the
   * same-named function itself) matters: the caller is a DIFFERENT
   * compiled image with its OWN same-named, unrelated copy of that
   * function and static -- calling it there would read garbage. */
  V result = fpr_process_result_get();
  fpr_set_tp(caller_h); /* give the physical register back before returning */
  return result;
}
