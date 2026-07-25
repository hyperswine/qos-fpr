/* process.c -- System.qa's side of dynamic loading: the growth
 * callback handed to a running process, and the FPRISC-facing
 * Sys.loadElf primitive that ties buddy.c + elfload.c + proc_entry
 * together. docs/PROCESS-LOADING.md has the full design; this file is
 * the last mile that makes it callable from FPRISC.
 *
 * ONE arena, buddy_init'd once from fpr_rt_init's caller (see the hook
 * below); ONE concurrent process slot this pass (stated in the docs).
 */
#include "fpr.h"

/* set from system.fpr's boot path via a thin wrapper below; keeps
 * buddy_init out of the fully-shared fpr_rt_init (a plain machine boot
 * with no process loading has no reason to reserve/init this arena) */
void fpr_proc_arena_init(void) {
  /* slab refactor: buddy is init'd over heap+proc regions at boot
   * (fpr_rt_init) for EVERY image -- it is the machine's one lower
   * allocator now.  Sys.init stays in the boot protocol as a no-op so
   * existing system.fpr code keeps working unchanged. */
}

/* the callback wired into fpr_process_entry (runtime.c's fpr_alloc
 * calls it through fpr_grow_memory on bump exhaustion). Captures no
 * state -- single concurrent slot means "ask the one arena" is
 * unambiguous; a multi-slot future version would close over which
 * process is asking. */
/* ---- the storage SYSCALL channel ------------------------------------
 * A loaded process lives in its own scheduler world: it cannot `send`
 * to System.qa's actors.  Instead System.qa passes ONE C function
 * through the entry ABI; the process-side svc helpers call it, and it
 * -- running System.qa's code -- publishes into the storage actor
 * (spawned on hart 1, so it makes progress while hart 0 is inside the
 * process) with the dormant syscall mailbox as replyTo, then spins for
 * the Result.  Capability scoping is enforced HERE, structurally: a
 * process may only name the relative url "kv", which the trampoline
 * rewrites to apps/<id>/<id>.kv from the id System.qa bound at launch.
 * Tags: 2 append, 3 replay (the kv event-sourcing pair). */
static V g_store_actor;   /* Sys.bindStore, at boot (0 = diskless) */
static str_t *g_app_id;   /* Sys.bindApp, per launch */

static V g_sys_bind_store(V a) { g_store_actor = a; return (V)&fpr_unit; }
static V g_sys_bind_app(V idv) {
  if (ISINT(idv) || ((hdr_t *)idv)->tid != T_STR) fpr_cpanic("Sys.bindApp: id must be a String");
  g_app_id = (str_t *)idv;
  return (V)&fpr_unit;
}
FPR_FN(fpr_g_Sys_x2ebindStore, g_sys_bind_store, 1);
FPR_FN(fpr_g_Sys_x2ebindApp, g_sys_bind_app, 1);

/* N-tuples (N >= 4) are tid 4 (Tup2's tid) with N fields -- the
 * positional-pattern convention the whole system uses (caps is a
 * 6-tuple the same way). */
static V mktup4v(V a, V b, V c, V d) {
  hdr_t *t = (hdr_t *)fpr_alloc(8 + 4 * sizeof(uw));
  t->tid = T_TUP2;
  t->var = 0;
  V *f = (V *)((char *)t + 8);
  f[0] = a; f[1] = b; f[2] = c; f[3] = d;
  return (V)t;
}

sw qos_store_call(uw tag, const char *pay, uw plen, char *out, uw outcap) {
  if (!g_store_actor || !g_app_id) return -2; /* no disk / no app bound */
  if (tag != 2 && tag != 3) return -3;
  /* apps/<id>/<id>.kv */
  char url[128];
  uw n = 0;
  const char *pre = "apps/";
  for (const char *q = pre; *q; q++) url[n++] = *q;
  for (uw i = 0; i < g_app_id->len && n < 100; i++) url[n++] = (char)g_app_id->bytes[i];
  url[n++] = '/';
  for (uw i = 0; i < g_app_id->len && n < 120; i++) url[n++] = (char)g_app_id->bytes[i];
  const char *suf = ".kv";
  for (const char *q = suf; *q; q++) url[n++] = *q;

  V urlv = (V)fpr_mkstr((const uint8_t *)url, n);
  V payv = (V)fpr_mkstr((const uint8_t *)pay, plen);
  V mb = (V)fpr_syscall_mailbox();
  V msg = mktup4v(mb, TAG((sw)tag), urlv, payv);
  fpr_send_as((uw)mb, g_store_actor, msg);
  V r = fpr_syscall_wait_result();
  /* r = Ok s | Err s (builtin Result, variant 0/1), field at +8 */
  hdr_t *h = (hdr_t *)r;
  str_t *s = (str_t *)*(V *)((char *)h + 8);
  uw cp = s->len < outcap ? s->len : outcap;
  for (uw i = 0; i < cp; i++) out[i] = (char)s->bytes[i];
  return h->var == 0 ? (sw)cp : -1;
}

#define MAX_GRANTS 64
static void *grants[MAX_GRANTS];
static int ngrants;

static fpr_grant_t loader_grow_memory(uw want_bytes) {
  fpr_grant_t g = {0, 0};
  void *p = buddy_alloc(want_bytes);
  if (p) {
    g.ptr = p;
    g.size = buddy_block_usable_size(p);
    if (ngrants < MAX_GRANTS) grants[ngrants++] = p; /* reclaimed on exit */
  }
  return g;
}

static V mktup2v(V a, V b) {
  hdr_t *t = (hdr_t *)fpr_alloc(8 + 2 * sizeof(uw));
  t->tid = T_TUP2;
  t->var = 0;
  *(V *)((char *)t + 8) = a;
  *(V *)((char *)t + 8 + sizeof(uw)) = b;
  return (V)t;
}

/* Sys.loadElfAt : String -> Int -> Int -> (Int, String)
 * Takes the ARCHIVE bytes plus an (offset, length) slice -- reading
 * the ELF payload straight out of the .qa string's own backing bytes,
 * NOT a pre-sliced copy. This matters: the FPRISC-level `substr` helper
 * (system.fpr) builds strings one strcat'd character at a time, which
 * is fine for a ~200-byte manifest and O(n^2)-catastrophic for a
 * multi-KB ELF payload (a 49 KB slice allocated over a billion
 * transient bytes before this fix). Section offsets are cheap to
 * compute in FPRISC (system.fpr already does, for MANIFEST); the
 * PAYLOAD BYTES should never round-trip through FPRISC-level string
 * building at all. fst = 1 success / 0 failure; snd = the process's
 * rendered result on success, or a human-readable failure reason.
 * Argument-type errors still panic, matching every other HAL
 * primitive's convention; a malformed ELF PAYLOAD is reported through
 * the tuple instead, so a caller (System.qa's launcher) can keep
 * running and show the user what went wrong -- the same way "No such
 * app" and "Bad .qa" already do in system.fpr. */
static V g_sys_load_elf_at(V qastr, V offv, V lenv, V capsv) {
  if (ISINT(capsv) || ((hdr_t *)capsv)->tid != T_STR)
    fpr_cpanic("Sys.loadElfAt: caps must be a String (the serialized grant blob)");
  if (ISINT(qastr) || ((hdr_t *)qastr)->tid != T_STR)
    fpr_cpanic("Sys.loadElfAt: first argument must be a String (the .qa archive bytes)");
  if (!ISINT(offv) || !ISINT(lenv))
    fpr_cpanic("Sys.loadElfAt: offset/length must be Ints");
  str_t *qa = (str_t *)qastr;
  sw off = UNTAG(offv), len = UNTAG(lenv);
  if (off < 0 || len < 0 || (uw)off + (uw)len > qa->len)
    fpr_cpanic("Sys.loadElfAt: (offset, length) out of range for this archive");
  const unsigned char *bytes = qa->bytes + off;
  uw blen = (uw)len;

  /* the image is LINKED at _proc_arena_start: the fixed region IS the
   * slot (one concurrent process, per the docs) -- no allocation, no
   * fragmentation interplay with the slab heap.  Growth grants still
   * come from buddy and are reclaimed on exit. */
  void *slot = _proc_arena_start;
  uw slot_size = (uw)(_proc_arena_end - _proc_arena_start);
  if (blen + (64 * 1024) > slot_size)
    return mktup2v(TAG(0), (V)fpr_mkstr((const uint8_t *)"image larger than the process slot", 34));

  ngrants = 0;
  fpr_elf_load_t r = fpr_elf_load(bytes, blen, slot, slot_size);
  if (!r.ok) {
    uw n = 0; while (r.err[n]) n++;
    return mktup2v(TAG(0), (V)fpr_mkstr((const uint8_t *)r.err, n));
  }

  void *heap_base = r.image_end;
  uw heap_size = (uw)slot + slot_size - (uw)heap_base;

  /* the process's OWN fpr_process_entry returns its result directly --
   * see the note in proc_entry.c about why this must not be fetched
   * via a same-named function call from THIS (System.qa's) image. */
  str_t *cs = (str_t *)capsv;
  V (*entry)(void *, uw, fpr_grant_t (*)(uw), const unsigned char *, uw,
             sw (*)(uw, const char *, uw, char *, uw)) =
      (V (*)(void *, uw, fpr_grant_t (*)(uw), const unsigned char *, uw,
             sw (*)(uw, const char *, uw, char *, uw)))r.entry;
  V result = entry(heap_base, heap_size, loader_grow_memory, cs->bytes, cs->len,
                   qos_store_call);
  V rendered = fpr_prim_fn_str(result); /* render() the SAME way `str`/print do -- runtime.c */
  /* slab refactor: growth blocks ARE tracked now -- everything the
   * process begged for goes back with the slot.  The ~3 MiB/run leak
   * PROCESS-LOADING.md recorded is gone as a category. */
  for (int i = 0; i < ngrants; i++) buddy_free(grants[i]);
  ngrants = 0;
  return mktup2v(TAG(1), rendered);
}

FPR_FN(fpr_g_Sys_x2eloadElfAt, g_sys_load_elf_at, 4);

/* Sys.init : Unit -> Unit -- must be called once, before the first
 * Sys.loadElf, by whichever image owns the process arena (System.qa's
 * boot path). Not folded into fpr_rt_init: plenty of images link
 * runtime.c without ever linking buddy.c/process.c (every demo that
 * isn't System.qa), so this stays an opt-in call, not a hook everyone
 * pays for. */
static V g_sys_init(V d) { (void)d; fpr_proc_arena_init(); return (V)&fpr_unit; }
FPR_FN(fpr_g_Sys_x2einit, g_sys_init, 1);

/* introspection: how much of the process arena is currently free */
static V g_sys_arena_free(V d) { (void)d; return TAG((sw)buddy_free_bytes()); }
FPR_FN(fpr_g_Sys_x2earenaFree, g_sys_arena_free, 1);
