/* vec.c — the LINEAR SoA VList vector.
 *
 * Storage model
 * -------------
 * A Vector is columns; a column is a VList: a directory of geometrically
 * growing blocks (16, 32, 64, ... words).  Blocks are never reallocated
 * and never copied — push is O(1), a grown vector's old data stays where
 * it was, and every block up to the allocator's 8 KiB free-list ceiling
 * recycles exactly (no realloc-and-leak under this bump+freelist
 * allocator: that is WHY it's a VList and not a doubling array here).
 * Iteration is contiguous within a block, which is what the compiler's
 * specialized/vectorized loops stride over.
 *
 * Layout is fixed by the FIRST push (the Sol PoC rule, verbatim):
 *   Int                    -> 1 unboxed column           (rep VR_INT)
 *   tuple/record, 2..8 fields -> one column per field, each unboxed
 *                             if that field was an Int   (rep VR_SOA)
 *   anything else          -> 1 boxed column             (rep VR_BOX)
 * Unboxed columns hold RAW (untagged) machine words — the layout the
 * generated column loops and the RVV lanes consume with zero
 * marshalling.  Boxed columns hold V values as-is.
 *
 * LINEARITY IS WHAT MAKES THIS SOUND: `Vector 1 = ...` in the prelude
 * makes the checker enforce single ownership, which licenses in-place
 * mutation (push/set/map return the same reference as the "new" vector)
 * and licenses the compiler's specialized loops to write columns
 * directly.  Record values carry their field count in `var`; tuple
 * arities come from their typeids.  Wider products stay boxed.
 */
#include "fpr.h"
#include <limits.h>

#define VL_B0 16 /* words in block 0; block j holds VL_B0 << j */
#define VL_DIR 24
#define VMAXCOLS 8

/* VR_FLT: one raw FLOAT column.  It is a DECLARED rep, never inferred:
 * a float V is its bit pattern, so the runtime cannot tell one from a
 * pointer -- fix_layout's first-push rule is undecidable for floats
 * (the documented v1 hazard, here turned into an API instead of a
 * guess).  Vec.newAs declares the layout up front. */
enum { VR_UNSET = 0, VR_INT = 1, VR_BOX = 2, VR_SOA = 3, VR_FLT = 4 };

typedef struct {
  uw nblk;
  uw *blk[VL_DIR];
} col_t;

/* field offsets here are mirrored by Codegen.hs (vec specialization):
 * len 8+0W | eltid 8+1W | elvar 8+2W | ncols 8+3W | kinds 8+4W
 * | fkinds 8+5W | cols 8+6W
 * kinds bit i: column i is RAW (untagged machine word, not a V)
 * fkinds bit i: that raw word is IEEE FLOAT BITS -- stored and read
 * verbatim, never tagged.  fkinds is always a subset of kinds. */
typedef struct {
  uint32_t tid, var; /* var = rep */
  uw len, eltid, elvar, ncols, kinds, fkinds;
  col_t *cols[VMAXCOLS];
} vec_t;

/* ---- VList index math ------------------------------------------------ */

/* elements below block j: VL_B0 * (2^j - 1) */
static inline uw vl_cap(uw nblk) { return VL_B0 * (((uw)1 << nblk) - 1); }

/* floor(log2 q), q >= 1 — by hand: -nostdlib means no libgcc __clzdi2,
 * and the loop runs at most VL_DIR times */
static inline int vl_log2(uw q) {
  int j = 0;
  while (q >>= 1) j++;
  return j;
}

static inline uw *vl_slot(col_t *c, uw i) {
  int j = vl_log2(i / VL_B0 + 1);
  uw off = i - VL_B0 * (((uw)1 << j) - 1);
  return &c->blk[j][off];
}

static void vl_grow(col_t *c) {
  if (c->nblk >= VL_DIR) fpr_cpanic("Vec: vector too large");
  uw words = (uw)VL_B0 << c->nblk;
  c->blk[c->nblk++] = (uw *)fpr_alloc(words * sizeof(uw));
}

static col_t *col_new(void) {
  col_t *c = (col_t *)fpr_alloc(sizeof(col_t));
  c->nblk = 0;
  for (int j = 0; j < VL_DIR; j++) c->blk[j] = 0;
  return c;
}

static void col_free(col_t *c) {
  for (uw j = 0; j < c->nblk; j++) fpr_free((V)c->blk[j]); /* >8KiB: leaks, by policy */
  fpr_free((V)c);
}

/* ---- vector object ---------------------------------------------------- */

static vec_t *vchk(V v, const char *who) {
  if (ISINT(v) || TID(v) != T_VEC) fpr_cpanic(who);
  return (vec_t *)v;
}

/* ---- copy-on-write sharing (rc in var bits 8+) -----------------------
 * var packs [rc:24 | rep:8].  rc is BIASED: 0 means one owner, n means
 * n+1 references.  Vec.dup and message deep-copy share by rc++ (O(1));
 * every WRITING op calls cow_wr first (private full copy when shared),
 * every consume goes through cow_rel (rc-- when shared, real free at
 * the last reference).  Reads (get, fold, gather's src) touch nothing.
 * The old law -- "one copy per CONSUMER, aliasing is silent corruption"
 * -- is gone: aliasing is now the mechanism.  Handles still follow
 * their owning POOL's lifetime, exactly as before.  Known hole: the
 * compiler's SPECIALIZED map/fold column loops write storage directly
 * without this check; the C fallbacks below own first.  Sharing today
 * happens via dup and messages, whose values feed the fixed-function
 * tier -- specialized sites on shared vectors are documented unsound
 * until the emitted layout guard also tests rc. */
#define VREP(x) ((x)->var & 0xffu)
static uw cow_rc(vec_t *x) { return __atomic_load_n(&x->var, __ATOMIC_ACQUIRE) >> 8; }
static void cow_inc(vec_t *x) { __atomic_add_fetch(&x->var, 256u, __ATOMIC_ACQ_REL); }
/* returns nonzero if this was the LAST reference (caller owns/frees) */
static int cow_dec(vec_t *x) {
  return (__atomic_fetch_sub(&x->var, 256u, __ATOMIC_ACQ_REL) >> 8) == 0 ? 1
         : 0;
}
static void vfree(vec_t *x); /* fwd */
static col_t *col_new(void);
static col_t *col_copy(col_t *c, uw len) {
  col_t *n = col_new();
  n->nblk = c->nblk;
  uw rem = len;
  for (uw j = 0; j < c->nblk; j++) {
    uw bn = ((uw)VL_B0 << j) < rem ? ((uw)VL_B0 << j) : rem;
    uw bytes = ((uw)VL_B0 << j) * sizeof(uw);
    n->blk[j] = (uw *)fpr_alloc(bytes);
    for (uw i = 0; i < bn; i++) n->blk[j][i] = c->blk[j][i];
    rem -= bn;
  }
  return n;
}
static vec_t *vcopy(vec_t *x) {
  vec_t *n = (vec_t *)fpr_alloc(sizeof(vec_t));
  n->tid = T_VEC;
  n->var = (uint32_t)VREP(x); /* rc 0: sole owner */
  n->len = x->len; n->eltid = x->eltid; n->elvar = x->elvar;
  n->ncols = x->ncols; n->kinds = x->kinds; n->fkinds = x->fkinds;
  for (int i = 0; i < VMAXCOLS; i++)
    n->cols[i] = x->cols[i] ? col_copy(x->cols[i], x->len) : 0;
  return n;
}
/* own before writing: shared -> private copy, rc-- on the original */
static vec_t *cow_wr(vec_t *x) {
  if (cow_rc(x) == 0) return x;
  vec_t *n = vcopy(x);
  cow_dec(x);
  return n;
}
/* release a consumed input: last ref really frees */
static void cow_rel(vec_t *x) {
  if (cow_dec(x)) vfree(x);
}

/* the deep copier's vec hook: sharing IS the copy for vectors */
void fpr_vec_share(V v) { cow_inc((vec_t *)v); }
void fpr_vec_release(V v) { cow_rel((vec_t *)v); }

static V h_new(V unit) {
  (void)unit;
  vec_t *x = (vec_t *)fpr_alloc(sizeof(vec_t));
  x->tid = T_VEC;
  x->var = VR_UNSET;
  x->len = 0;
  x->eltid = x->elvar = x->ncols = x->kinds = x->fkinds = 0;
  for (int i = 0; i < VMAXCOLS; i++) x->cols[i] = 0;
  return (V)x;
}

static uw tuple_arity(uw tid) {
  if (tid == T_TUP2) return 2;
  if (tid == T_TUP3) return 3;
  if (tid >= T_TUP4 && tid <= T_TUP8) return 4 + (tid - T_TUP4);
  return 0;
}

/* records: the compiler puts the FIELD COUNT in var (unused for shapes
 * -- one shape per tid), so a record VALUE is self-describing and a Vec
 * of records gets SoA columns by the same first-push rule as tuples.
 * Shape tids live in the content-addressed 0x00010000+ window
 * (FPRISC.hs shapeIdFor); >VMAXCOLS fields fall back to boxed. */
static uw value_arity(V v) {
  uw tid = TID(v);
  uw t = tuple_arity(tid);
  if (t) return t;
  if (tid >= 0x00010000 && tid < 0x00010000 + 0x0FF00000) {
    uw ar = ((hdr_t *)v)->var;
    return (ar >= 2 && ar <= VMAXCOLS) ? ar : 0;
  }
  return 0;
}

/* fix the layout from the first pushed value (the Sol rule) */
static void fix_layout(vec_t *x, V v) {
  if (ISINT(v)) {
    x->var = VR_INT;
    x->ncols = 1;
    x->kinds = 1;
  } else {
    uw ar = value_arity(v);
    if (ar) {
      x->var = VR_SOA;
      x->eltid = TID(v);
      x->elvar = ((hdr_t *)v)->var;
      x->ncols = ar;
      x->kinds = 0;
      for (uw k = 0; k < ar; k++) {
        V f = *(V *)((char *)v + 8 + k * sizeof(uw));
        if (ISINT(f)) x->kinds |= (uw)1 << k;
      }
    } else {
      x->var = VR_BOX;
      x->ncols = 1;
      x->kinds = 0;
    }
  }
  for (uw k = 0; k < x->ncols; k++) x->cols[k] = col_new();
}

static void put_cell(vec_t *x, uw k, uw i, V f) {
  int raw = (x->kinds >> k) & 1, flt = (x->fkinds >> k) & 1;
  /* a float column stores the V verbatim -- it ALREADY is the bit
   * pattern.  No ISINT check is possible (nor meaningful): the width
   * came from the declaration, not from the value. */
  if (raw && !flt && !ISINT(f))
    fpr_cpanic("Vec: Int column got a non-Int (layout is fixed by the first push or by Vec.newAs)");
  *vl_slot(x->cols[k], i) = (raw && !flt) ? (uw)UNTAG(f) : (uw)f;
}

static V get_cell(vec_t *x, uw k, uw i) {
  uw raw = *vl_slot(x->cols[k], i);
  int unb = (x->kinds >> k) & 1, flt = (x->fkinds >> k) & 1;
  return (unb && !flt) ? TAG((sw)raw) : (V)raw;
}

/* Vec.newAs spec -- DECLARE the column layout instead of inferring it.
 * One char per column: 'i' Int (raw, tagged on read), 'd' F64, 's' F32
 * (both raw float bits), 'b' boxed (any V).  One char = a flat vector;
 * 2..8 chars = an SoA vector of tuples of that arity.
 *
 *   Vec.newAs "d"    a Vector of F64        (raw contiguous doubles)
 *   Vec.newAs "iddd" SoA rows (Int, F64, F64, F64)
 *
 * This exists because floats are raw bits: the first-push rule that
 * classifies Int/tuple/boxed cannot see a float at all, and guessing
 * would dereference a double as an object header.  Declaring is the
 * honest fix, and it doubles as the hook the specialized column loops
 * read to pick float instructions. */
static V h_newAs(V specv) {
  if (ISINT(specv) || TID(specv) != T_STR)
    fpr_cpanic("Vec.newAs: spec must be a String like \"d\" or \"iddd\"");
  str_t *sp = (str_t *)specv;
  if (sp->len < 1 || sp->len > VMAXCOLS)
    fpr_cpanic("Vec.newAs: spec must name 1..8 columns");
  vec_t *x = (vec_t *)h_new((V)&fpr_unit);
  x->ncols = sp->len;
  x->kinds = x->fkinds = 0;
  for (uw k = 0; k < sp->len; k++) {
    switch (sp->bytes[k]) {
      case 'i': x->kinds |= (uw)1 << k; break;
      case 'd':
      case 's': x->kinds |= (uw)1 << k; x->fkinds |= (uw)1 << k; break;
      case 'b': break;
      default: fpr_cpanic("Vec.newAs: spec chars are i (Int), d (F64), s (F32), b (boxed)");
    }
  }
  if (sp->len == 1) {
    x->var = (x->fkinds & 1) ? VR_FLT : ((x->kinds & 1) ? VR_INT : VR_BOX);
  } else {
    x->var = VR_SOA;
    x->eltid = sp->len == 2 ? T_TUP2 : sp->len == 3 ? T_TUP3 : T_TUP4 + (sp->len - 4);
    x->elvar = 0;
  }
  for (uw k = 0; k < x->ncols; k++) x->cols[k] = col_new();
  return (V)x;
}

/* an EMPTY vector with the same declared layout -- what map/filter must
 * build for a declared (float-bearing) source, since h_new + first-push
 * inference cannot recover a float layout from a float value. */
static V h_new_like(vec_t *src) {
  vec_t *x = (vec_t *)h_new((V)&fpr_unit);
  x->var = (uint32_t)VREP(src);
  x->eltid = src->eltid;
  x->elvar = src->elvar;
  x->ncols = src->ncols;
  x->kinds = src->kinds;
  x->fkinds = src->fkinds;
  for (uw k = 0; k < x->ncols; k++) x->cols[k] = col_new();
  return (V)x;
}

static V h_push(V v, V vec) {
  vec_t *x = cow_wr(vchk(vec, "Vec.push: not a Vector"));
  if (VREP(x) == VR_UNSET) fix_layout(x, v);
  for (uw k = 0; k < x->ncols; k++)
    if (x->len == vl_cap(x->cols[k]->nblk)) vl_grow(x->cols[k]);
  switch (VREP(x)) {
    case VR_INT:
      if (!ISINT(v)) fpr_cpanic("Vec.push: Int vector got a non-Int");
      put_cell(x, 0, x->len, v);
      break;
    case VR_FLT: /* declared width; the value carries no evidence */
      put_cell(x, 0, x->len, v);
      break;
    case VR_BOX:
      put_cell(x, 0, x->len, v);
      break;
    case VR_SOA: {
      if (ISINT(v) || TID(v) != x->eltid)
        fpr_cpanic("Vec.push: tuple shape differs from first push");
      for (uw k = 0; k < x->ncols; k++)
        put_cell(x, k, x->len, *(V *)((char *)v + 8 + k * sizeof(uw)));
      break;
    }
  }
  x->len++;
  return (V)x;
}

/* reconstruct row i as a value — the deliberately slower escape hatch */
static V row_at(vec_t *x, uw i) {
  switch (VREP(x)) {
    case VR_INT:
    case VR_FLT:
    case VR_BOX:
      return get_cell(x, 0, i);
    default: {
      hdr_t *t = (hdr_t *)fpr_alloc(8 + x->ncols * sizeof(uw));
      t->tid = (uint32_t)x->eltid;
      t->var = (uint32_t)x->elvar;
      for (uw k = 0; k < x->ncols; k++)
        *(V *)((char *)t + 8 + k * sizeof(uw)) = get_cell(x, k, i);
      return (V)t;
    }
  }
}

static V mktup2(V a, V b) {
  hdr_t *t = (hdr_t *)fpr_alloc(8 + 2 * sizeof(uw));
  t->tid = T_TUP2;
  t->var = 0;
  *(V *)((char *)t + 8) = a;
  *(V *)((char *)t + 8 + sizeof(uw)) = b;
  return (V)t;
}

static V h_len(V vec) {
  vec_t *x = vchk(vec, "Vec.len: not a Vector");
  return mktup2(TAG((sw)x->len), (V)x);
}

/* 1-indexed, like `!` */
static V h_get(V iv, V vec) {
  vec_t *x = vchk(vec, "Vec.get: not a Vector");
  if (!ISINT(iv)) fpr_cpanic("Vec.get: index not an Int");
  sw i = UNTAG(iv);
  if (i < 1 || (uw)i > x->len) fpr_cpanic("Vec.get: index out of range");
  return mktup2(row_at(x, (uw)(i - 1)), (V)x);
}

static V h_set(V iv, V v, V vec) {
  vec_t *x = cow_wr(vchk(vec, "Vec.set: not a Vector"));
  if (!ISINT(iv)) fpr_cpanic("Vec.set: index not an Int");
  sw i = UNTAG(iv);
  if (i < 1 || (uw)i > x->len) fpr_cpanic("Vec.set: index out of range");
  switch (VREP(x)) {
    case VR_INT:
    case VR_FLT:
    case VR_BOX:
      put_cell(x, 0, (uw)(i - 1), v);
      break;
    default:
      if (ISINT(v) || TID(v) != x->eltid) fpr_cpanic("Vec.set: tuple shape differs");
      for (uw k = 0; k < x->ncols; k++)
        put_cell(x, k, (uw)(i - 1), *(V *)((char *)v + 8 + k * sizeof(uw)));
  }
  return (V)x;
}

static void vfree(vec_t *x) {
  for (uw k = 0; k < x->ncols; k++)
    if (x->cols[k]) col_free(x->cols[k]);
  fpr_free((V)x);
}

static V h_free(V vec) {
  cow_rel(vchk(vec, "Vec.free: not a Vector"));
  return (V)&fpr_unit;
}

/* ---- schemes: the generic (interpreted) tier -------------------------
 * These exist so EVERY well-typed program runs; the compiler's
 * specialized column loops (Codegen.hs) shadow them per call site when
 * the element function is statically known and arithmetic-only, and
 * TAIL-CALL BACK IN here when a runtime layout guard fails.  Exported
 * under stable direct names for exactly that fallback path. */

V fpr_vec_map(V f, V vec) {
  vec_t *x = vchk(vec, "Vec.map: not a Vector");
  /* float layouts are DECLARED, so they propagate: mapping a float
   * vector yields a float vector of the same widths.  The element
   * function must therefore be width-preserving (F64 -> F64) -- the
   * Vector type carries no element type to check that against, so it
   * is a stated contract, with Vec.toList as the escape hatch when the
   * shape really changes. */
  V out = x->fkinds ? h_new_like(x) : h_new((V)&fpr_unit);
  for (uw i = 0; i < x->len; i++) out = h_push(fpr_apply(f, row_at(x, i)), out);
  cow_rel(x);
  return out;
}

/* filter is EAGER COMPACTION, deliberately (the design decision, made
 * explicit): under linearity there is no sharing to preserve, so the
 * kept rows slide down IN PLACE with two cursors and len shrinks --
 * zero allocation, and every later map/fold/zip/axpb stays dense and
 * mask-free.  Tombstones + bitmask + incremental GC would only win
 * when filters vastly outnumber scans; that is not this machine's
 * workload, and masked lanes would poison the whole SIMD tier.
 * Blocks beyond the new length stay attached (they recycle with the
 * vector; a VList never returns capacity early).  docs/VEC.md. */
V fpr_vec_filter(V f, V vec) {
  vec_t *x = vchk(vec, "Vec.filter: not a Vector");
  uw j = 0;
  for (uw i = 0; i < x->len; i++) {
    V row = row_at(x, i);
    V keep = fpr_apply(f, row);
    if (!ISINT(keep) && ((hdr_t *)keep)->var) {
      if (j != i)
        for (uw k = 0; k < x->ncols; k++)
          *vl_slot(x->cols[k], j) = *vl_slot(x->cols[k], i);
      j++;
    }
  }
  x->len = j;
  return (V)x;
}

V fpr_vec_fold(V f, V z, V vec) {
  vec_t *x = vchk(vec, "Vec.fold: not a Vector");
  V acc = z;
  for (uw i = 0; i < x->len; i++) acc = fpr_apply(fpr_apply(f, acc), row_at(x, i));
  return mktup2(acc, (V)x);
}

static V h_fromList(V xs) {
  V out = h_new((V)&fpr_unit);
  while (!ISINT(xs) && TID(xs) == T_LIST && ((hdr_t *)xs)->var == 1) {
    out = h_push(*(V *)((char *)xs + 8), out);
    xs = *(V *)((char *)xs + 8 + sizeof(uw));
  }
  return out;
}

static V h_toList(V vec) {
  vec_t *x = vchk(vec, "Vec.toList: not a Vector");
  V acc = 0;
  /* Nil */
  hdr_t *nil = (hdr_t *)fpr_alloc(8);
  nil->tid = T_LIST;
  nil->var = 0;
  acc = (V)nil;
  for (uw i = x->len; i > 0; i--) {
    hdr_t *c = (hdr_t *)fpr_alloc(8 + 2 * sizeof(uw));
    c->tid = T_LIST;
    c->var = 1;
    *(V *)((char *)c + 8) = row_at(x, i - 1);
    *(V *)((char *)c + 8 + sizeof(uw)) = acc;
    acc = (V)c;
  }
  cow_rel(x);
  return acc;
}

/* split after element n: (first n, rest).  Both halves are FRESH vectors
 * (each hart sorts its own — a shared block chain would put two writers
 * on one ring, which this design never allows); the original is consumed
 * (linearity: the caller no longer owns it). */
static V h_split(V nv, V vec) {
  vec_t *x = vchk(vec, "Vec.split: not a Vector");
  if (!ISINT(nv)) fpr_cpanic("Vec.split: count not an Int");
  sw n = UNTAG(nv);
  if (n < 0) n = 0;
  if ((uw)n > x->len) n = (sw)x->len;
  V lo = x->fkinds ? h_new_like(x) : h_new((V)&fpr_unit);
  V hi = x->fkinds ? h_new_like(x) : h_new((V)&fpr_unit);
  for (uw i = 0; i < (uw)n; i++) lo = h_push(row_at(x, i), lo);
  for (uw i = (uw)n; i < x->len; i++) hi = h_push(row_at(x, i), hi);
  cow_rel(x);
  return mktup2(lo, hi);
}

/* ---- the discoverable-symbol table ------------------------------------ */
FPR_FN(fpr_g_Vec_x2enew, h_new, 1);
FPR_FN(fpr_g_Vec_x2epush, h_push, 2);
FPR_FN(fpr_g_Vec_x2elen, h_len, 1);
FPR_FN(fpr_g_Vec_x2eget, h_get, 2);
FPR_FN(fpr_g_Vec_x2eset, h_set, 3);
/* the 0-BASED names.  get/set are 1-based (the standing trap); at/put
 * are the same ops with the index the rest of the system uses.  New
 * code should use at/put; get/set stay for existing callers -- the
 * rename makes the base visible at the call site instead of flipping
 * every program in one breaking sweep. */
static V h_at(V iv, V vec) {
  if (!ISINT(iv)) fpr_cpanic("Vec.at: index not an Int");
  return h_get(TAG(UNTAG(iv) + 1), vec);
}
static V h_put(V iv, V v, V vec) {
  if (!ISINT(iv)) fpr_cpanic("Vec.put: index not an Int");
  return h_set(TAG(UNTAG(iv) + 1), v, vec);
}
FPR_FN(fpr_g_Vec_x2eat, h_at, 2);
FPR_FN(fpr_g_Vec_x2eput, h_put, 3);
FPR_FN(fpr_g_Vec_x2emap, fpr_vec_map, 2);
FPR_FN(fpr_g_Vec_x2efilter, fpr_vec_filter, 2);
FPR_FN(fpr_g_Vec_x2efold, fpr_vec_fold, 3);
FPR_FN(fpr_g_Vec_x2enewAs, h_newAs, 1);
FPR_FN(fpr_g_Vec_x2efromList, h_fromList, 1);
FPR_FN(fpr_g_Vec_x2etoList, h_toList, 1);
FPR_FN(fpr_g_Vec_x2efree, h_free, 1);
FPR_FN(fpr_g_Vec_x2esplit, h_split, 2);

/* ==== the numeric SIMD tier ============================================
 * Element-wise ops over ONE unboxed Int column, striding the raw block
 * words contiguously -- the loops below are exactly the shapes RVV/NEON
 * name (vadd.vx, vmul.vv, vmerge.vvm, vluxei, vmslt), written so the C
 * compiler's autovectorizer takes them on hosted targets.  Two vectors
 * of equal length share an IDENTICAL block partition (the directory is
 * index-structured), so zips pair blocks and stay contiguous.
 *
 * Linearity discipline: unary ops mutate in place and return the same
 * vector; zips mutate dst in place and CONSUME src (freed) -- dup first
 * if you need it again; gather/slice thread the read-only operand back
 * in a tuple; blend consumes mask and src.  Int column only: anything
 * else panics (this is the numeric tier, not the generic one).      */

/* the whole tier compiles under the full vectorizer regardless of the
 * build's baseline -O level: these loops ARE the SIMD, so the pragma is
 * part of the contract, not an optimization hint.
 *
 * What actually vectorizes today: adds, min/max, compares, ges, blend
 * and burst take SSE2/NEON lanes (paddq / cmgt / vmerge shapes).  The
 * 64-bit MULTIPLIES (axpb, zipMul) stay scalar on hosted baselines --
 * SSE has no 64-lane multiply below AVX-512, NEON none at all -- and
 * become vmul.vx/.vv at SEW=64 on the RVV target this tier is shaped
 * for.  Element width is the machine word by design (16.16 products
 * need the headroom); narrowing lanes to buy host multipliers would
 * trade away correctness for a benchmark. */
#pragma GCC push_options
#pragma GCC optimize("O3,tree-vectorize")

static vec_t *vnum(V v, const char *who) {
  vec_t *x = vchk(v, who);
  /* the integer SIMD tier (axpb/sar/minS/zipAdd/...) is Int-only: a
   * float vector is REFUSED here rather than reinterpreted, since its
   * words are IEEE bits and `a * p[i] + b` on them is nonsense.  Float
   * lanes are the compiler's specialized column loops (Codegen.hs) and
   * Vec.map over F64 -- not these fixed-function ops (v1). */
  if (x->len && VREP(x) != VR_INT)
    fpr_cpanic("SIMD tier: not an Int vector (float vectors: use Vec.map / the specialized loops)");
  return x;
}

/* Optional hosted GPU tier.  A strong backend definition may replace
 * this default.  It must leave blocks untouched when returning zero. */
__attribute__((weak)) int fpr_gpu_vec_axpb(uw *const *blocks, uw len, sw a, sw b) {
  (void)blocks; (void)len; (void)a; (void)b;
  return 0;
}

__attribute__((weak)) int fpr_gpu_vec_fold_pair_sum(void *col0, void *col1,
                                                     uw len, sw seed, sw *out) {
  (void)col0; (void)col1; (void)len; (void)seed; (void)out;
  return 0;
}

static int gpu_axpb_exact(vec_t *x, sw a, sw b) {
  if (x->len < 65536 || a < INT32_MIN || a > INT32_MAX ||
      b < INT32_MIN || b > INT32_MAX)
    return 0;
  uw rem = x->len;
  for (uw j = 0; rem; j++) {
    uw n = ((uw)VL_B0 << j) < rem ? ((uw)VL_B0 << j) : rem;
    sw *p = (sw *)x->cols[0]->blk[j];
    for (uw i = 0; i < n; i++) {
      if (p[i] < INT32_MIN || p[i] > INT32_MAX) return 0;
      int64_t product = (int64_t)(int32_t)a * (int64_t)(int32_t)p[i];
      if (product < INT32_MIN || product > INT32_MAX) return 0;
      int64_t result = product + (int64_t)(int32_t)b;
      if (result < INT32_MIN || result > INT32_MAX) return 0;
    }
    rem -= n;
  }
  return fpr_gpu_vec_axpb(x->cols[0]->blk, x->len, a, b);
}

/* iterate one column's blocks: sw *p over contiguous runs of n words,
 * block index in j (VL_B0<<j words at base vl_cap(j)) */
#define VS_BLOCKS(x, BODY)                                           \
  do {                                                               \
    uw _rem = (x)->len;                                              \
    for (uw j = 0; _rem; j++) {                                      \
      uw n = ((uw)VL_B0 << j) < _rem ? ((uw)VL_B0 << j) : _rem;      \
      sw *p = (sw *)(x)->cols[0]->blk[j];                            \
      (void)p;                                                       \
      BODY;                                                          \
      _rem -= n;                                                     \
    }                                                                \
  } while (0)

static V h_iota(V nv) {
  if (!ISINT(nv)) fpr_cpanic("Vec.iota: not an Int");
  sw n = UNTAG(nv);
  V v = h_new((V)&fpr_unit);
  for (sw i = 0; i < n; i++) v = h_push(TAG(i), v);
  return v;
}

static V h_dup(V vec) {
  vec_t *x = vchk(vec, "Vec.dup: not a Vector");
  cow_inc(x); /* CoW: both names share until one writes */
  return mktup2((V)x, (V)x);
}

static V h_axpb(V av, V bv, V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.axpb: not a Vector"));
  sw a = UNTAG(av), b = UNTAG(bv);
  if (gpu_axpb_exact(x, a, b)) return (V)x;
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = a * p[i] + b; });
  return (V)x;
}

static V h_sar(V kv, V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.sar: not a Vector"));
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] >>= k; });
  return (V)x;
}

static V h_minS(V kv, V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.minS: not a Vector"));
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] < k ? p[i] : k; });
  return (V)x;
}

static V h_maxS(V kv, V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.maxS: not a Vector"));
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] > k ? p[i] : k; });
  return (V)x;
}

static V h_ges(V kv, V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.ges: not a Vector"));
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] >= k; });
  return (V)x;
}

/* zips: dst op= src, contiguously over the shared block partition */
static vec_t *vzip2(V dv, V sv, const char *who) {
  vec_t *d = vnum(dv, who), *s = vnum(sv, who);
  if (d->len != s->len) fpr_cpanic("SIMD tier: zip length mismatch");
  return s; /* caller pairs blocks itself */
}
#define VS_ZIP(dv, sv, WHO, EXPR)                                            \
  do {                                                                       \
    vec_t *_d = cow_wr(vnum(dv, WHO)), *_s = vzip2(dv, sv, WHO);             \
    uw _r = _d->len;                                                         \
    for (uw _j = 0; _r; _j++) {                                              \
      uw _n = ((uw)VL_B0 << _j) < _r ? ((uw)VL_B0 << _j) : _r;               \
      sw *p = (sw *)_d->cols[0]->blk[_j], *q = (sw *)_s->cols[0]->blk[_j];   \
      for (uw _i = 0; _i < _n; _i++) { sw A = p[_i], B = q[_i]; p[_i] = (EXPR); } \
      _r -= _n;                                                              \
    }                                                                        \
    cow_rel(_s);                                                             \
    return (V)_d;                                                            \
  } while (0)

static V h_zipAdd(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipAdd", A + B); }
static V h_zipMul(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipMul", A * B); }
static V h_zipMin(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipMin", A < B ? A : B); }
static V h_zipLt(V dv, V sv)  { VS_ZIP(dv, sv, "Vec.zipLt", A < B); }
static V h_zipDiv(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipDiv", B == 0 ? 0 : A / B); }

/* gather: idx[i] := src[idx[i]] (out of range -> 0); src threads back */
static V h_gather(V iv, V sv) {
  vec_t *x = cow_wr(vnum(iv, "Vec.gather: not a Vector"));
  vec_t *s = vnum(sv, "Vec.gather: not a Vector");
  VS_BLOCKS(x, {
    for (uw i = 0; i < n; i++) {
      sw ix = p[i];
      p[i] = (ix >= 0 && (uw)ix < s->len) ? *(sw *)vl_slot(s->cols[0], (uw)ix) : 0;
    }
  });
  return mktup2((V)x, (V)s);
}

/* blend: dst[i] := mask[i] ? src[i] : dst[i]; mask and src consumed */
static V h_blend(V mv, V sv, V dv) {
  vec_t *m = vnum(mv, "Vec.blend: not a Vector");
  vec_t *s = vnum(sv, "Vec.blend: not a Vector");
  vec_t *d = cow_wr(vnum(dv, "Vec.blend: not a Vector"));
  if (m->len != d->len || s->len != d->len) fpr_cpanic("Vec.blend: length mismatch");
  uw r = d->len;
  for (uw j = 0; r; j++) {
    uw n = ((uw)VL_B0 << j) < r ? ((uw)VL_B0 << j) : r;
    sw *pd = (sw *)d->cols[0]->blk[j], *pm = (sw *)m->cols[0]->blk[j],
       *ps = (sw *)s->cols[0]->blk[j];
    for (uw i = 0; i < n; i++) pd[i] = pm[i] ? ps[i] : pd[i];
    r -= n;
  }
  cow_rel(m); cow_rel(s);
  return (V)d;
}

/* slice: fresh copy of [off, off+n) (0-based); original threads back */
static V h_slice(V ov, V nv, V vec) {
  vec_t *x = vnum(vec, "Vec.slice: not a Vector");
  if (!ISINT(ov) || !ISINT(nv)) fpr_cpanic("Vec.slice: bounds not Ints");
  sw off = UNTAG(ov), n = UNTAG(nv);
  if (off < 0 || n < 0 || (uw)(off + n) > x->len) fpr_cpanic("Vec.slice: out of range");
  V c = h_new((V)&fpr_unit);
  for (sw i = 0; i < n; i++) c = h_push(TAG(*(sw *)vl_slot(x->cols[0], (uw)(off + i))), c);
  return mktup2(c, (V)x);
}

/* burst: dst[off..] := src, contiguously; src consumed */
static V h_burst(V ov, V sv, V dv) {
  vec_t *s = vnum(sv, "Vec.burst: not a Vector");
  vec_t *d = cow_wr(vnum(dv, "Vec.burst: not a Vector"));
  if (!ISINT(ov)) fpr_cpanic("Vec.burst: offset not an Int");
  sw off = UNTAG(ov);
  if (off < 0 || (uw)off + s->len > d->len) fpr_cpanic("Vec.burst: out of range");
  VS_BLOCKS(s, {
    uw base = vl_cap(j); /* first index of block j */
    for (uw i = 0; i < n; i++) *(sw *)vl_slot(d->cols[0], (uw)off + base + i) = p[i];
  });
  cow_rel(s);
  return (V)d;
}

/* ---- the DDA lanes: subtract, compare-equal, max, abs, scalar-eq ----
 * Voxel traversal needs per-lane axis selection (which tMax is smallest),
 * per-lane sign handling, and per-lane block-id tests; these are the
 * remaining shapes for that (vsub.vv, vmseq.vv/.vx, vmax.vv). */

static V h_zipSub(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipSub", A - B); }
static V h_zipEq(V dv, V sv)  { VS_ZIP(dv, sv, "Vec.zipEq", A == B); }
static V h_zipMax(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipMax", A > B ? A : B); }

static V h_absv(V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.absv: not a Vector"));
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] < 0 ? -p[i] : p[i]; });
  return (V)x;
}

static V h_eqS(V kv, V vec) {
  vec_t *x = cow_wr(vnum(vec, "Vec.eqS: not a Vector"));
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] == k; });
  return (V)x;
}

#pragma GCC pop_options

FPR_FN(fpr_g_Vec_x2eiota, h_iota, 1);
FPR_FN(fpr_g_Vec_x2edup, h_dup, 1);
FPR_FN(fpr_g_Vec_x2eaxpb, h_axpb, 3);
FPR_FN(fpr_g_Vec_x2esar, h_sar, 2);
FPR_FN(fpr_g_Vec_x2eminS, h_minS, 2);
FPR_FN(fpr_g_Vec_x2emaxS, h_maxS, 2);
FPR_FN(fpr_g_Vec_x2eges, h_ges, 2);
FPR_FN(fpr_g_Vec_x2ezipAdd, h_zipAdd, 2);
FPR_FN(fpr_g_Vec_x2ezipMul, h_zipMul, 2);
FPR_FN(fpr_g_Vec_x2ezipMin, h_zipMin, 2);
FPR_FN(fpr_g_Vec_x2ezipLt, h_zipLt, 2);
FPR_FN(fpr_g_Vec_x2ezipDiv, h_zipDiv, 2);
FPR_FN(fpr_g_Vec_x2egather, h_gather, 2);
FPR_FN(fpr_g_Vec_x2eblend, h_blend, 3);
FPR_FN(fpr_g_Vec_x2eslice, h_slice, 3);
FPR_FN(fpr_g_Vec_x2eburst, h_burst, 3);
FPR_FN(fpr_g_Vec_x2ezipSub, h_zipSub, 2);
FPR_FN(fpr_g_Vec_x2ezipEq, h_zipEq, 2);
FPR_FN(fpr_g_Vec_x2ezipMax, h_zipMax, 2);
FPR_FN(fpr_g_Vec_x2eabsv, h_absv, 1);
FPR_FN(fpr_g_Vec_x2eeqS, h_eqS, 2);
