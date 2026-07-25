/* mod.c — dynamic dispatch over the compile-time module table.
 *
 * Codegen emits `fpr_modtab`: zero-terminated (hash, name, PAP) word
 * triples, one per remote-callable module export.  `Mod.fn hash name`
 * resolves a function value from a module HASH and an export name —
 * the same (hash, name) pair FPRLive ships over the wire, so a remote
 * call and a local one go through the identical lookup.  The hash of a
 * used module is at hand because the module alias itself evaluates to
 * its hash string:
 *
 *     M = use "mymod#4f2a...".
 *     f = Mod.fn M "double".      # == M.double, resolved at runtime
 *
 * Pinned hashes make this safe to do late: the table can only ever
 * contain the exact code the hash names.
 */
#include "fpr.h"

/* weak: only the root unit of a build with modules emits the table;
 * module-free images simply have none. */
extern const uw fpr_modtab[] __attribute__((weak));

static int str_eq(const str_t *a, const str_t *b) {
  if (a->len != b->len) return 0;
  for (uw i = 0; i < a->len; i++)
    if (a->bytes[i] != b->bytes[i]) return 0;
  return 1;
}

static V h_modfn(V hash, V name) {
  if (ISINT(hash) || TID(hash) != T_STR) fpr_cpanic("Mod.fn: hash not a String");
  if (ISINT(name) || TID(name) != T_STR) fpr_cpanic("Mod.fn: name not a String");
  const str_t *h = (const str_t *)hash, *n = (const str_t *)name;
  for (const uw *p = fpr_modtab; p && p[0]; p += 3)
    if (str_eq((const str_t *)p[0], h) && str_eq((const str_t *)p[1], n))
      return (V)p[2];
  fpr_cpanic("Mod.fn: no such (hash, name) in the module table");
}

/* does the image carry this module at all? (a remote node answering an
 * FPRLive resolve probe wants exactly this predicate) */
static V h_modhas(V hash) {
  if (ISINT(hash) || TID(hash) != T_STR) fpr_cpanic("Mod.has: hash not a String");
  const str_t *h = (const str_t *)hash;
  for (const uw *p = fpr_modtab; p && p[0]; p += 3)
    if (str_eq((const str_t *)p[0], h)) return BOOL(1);
  return BOOL(0);
}

/* Mod.resolve hash name -> (1, fn) | (0, 0)  -- the URL-service
 * resolver contract: a MISS IS DATA, not a panic.  /services/modules
 * (system.fpr) answers through this; an FPRLive remote resolver
 * answers probes with exactly this shape.  Mod.fn keeps its loud
 * contract for callers who pinned a hash and consider absence a bug. */
static V mktup2(V a, V b) {
  hdr_t *t = (hdr_t *)fpr_alloc(8 + 2 * sizeof(uw));
  t->tid = T_TUP2;
  t->var = 0;
  *(V *)((char *)t + 8) = a;
  *(V *)((char *)t + 8 + sizeof(uw)) = b;
  return (V)t;
}
static V h_modresolve(V hash, V name) {
  if (ISINT(hash) || TID(hash) != T_STR) fpr_cpanic("Mod.resolve: hash not a String");
  if (ISINT(name) || TID(name) != T_STR) fpr_cpanic("Mod.resolve: name not a String");
  const str_t *h = (const str_t *)hash, *n = (const str_t *)name;
  for (const uw *p = fpr_modtab; p && p[0]; p += 3)
    if (str_eq((const str_t *)p[0], h) && str_eq((const str_t *)p[1], n))
      return mktup2(TAG(1), (V)p[2]);
  return mktup2(TAG(0), TAG(0));
}

FPR_FN(fpr_g_Mod_x2efn, h_modfn, 2);
FPR_FN(fpr_g_Mod_x2ehas, h_modhas, 1);
FPR_FN(fpr_g_Mod_x2eresolve, h_modresolve, 2);
