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
 *   tuple of 2..3 fields   -> one column per field, each unboxed
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
 * directly.  User products (non-tuple) go boxed because objects don't
 * carry field counts in this ABI (same limitation ARC's shallow free
 * documents); tuples' arities are known from their typeids.
 */
#include "fpr.h"

#define VL_B0 16 /* words in block 0; block j holds VL_B0 << j */
#define VL_DIR 24
#define VMAXCOLS 8

enum { VR_UNSET = 0, VR_INT = 1, VR_BOX = 2, VR_SOA = 3 };

typedef struct {
  uw nblk;
  uw *blk[VL_DIR];
} col_t;

/* field offsets here are mirrored by Codegen.hs (vec specialization):
 * len 8+0W | eltid 8+1W | elvar 8+2W | ncols 8+3W | kinds 8+4W | cols 8+5W */
typedef struct {
  uint32_t tid, var; /* var = rep */
  uw len, eltid, elvar, ncols, kinds; /* kinds bit i: column i unboxed */
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

static V h_new(V unit) {
  (void)unit;
  vec_t *x = (vec_t *)fpr_alloc(sizeof(vec_t));
  x->tid = T_VEC;
  x->var = VR_UNSET;
  x->len = 0;
  x->eltid = x->elvar = x->ncols = x->kinds = 0;
  for (int i = 0; i < VMAXCOLS; i++) x->cols[i] = 0;
  return (V)x;
}

static uw tuple_arity(uw tid) {
  if (tid == T_TUP2) return 2;
  if (tid == T_TUP3) return 3;
  return 0;
}

/* fix the layout from the first pushed value (the Sol rule) */
static void fix_layout(vec_t *x, V v) {
  if (ISINT(v)) {
    x->var = VR_INT;
    x->ncols = 1;
    x->kinds = 1;
  } else {
    uw ar = tuple_arity(TID(v));
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
  int unboxed = (x->kinds >> k) & 1;
  if (unboxed && !ISINT(f))
    fpr_cpanic("Vec: Int column got a non-Int (SoA layout is fixed by first push)");
  *vl_slot(x->cols[k], i) = unboxed ? (uw)UNTAG(f) : (uw)f;
}

static V get_cell(vec_t *x, uw k, uw i) {
  uw raw = *vl_slot(x->cols[k], i);
  return ((x->kinds >> k) & 1) ? TAG((sw)raw) : (V)raw;
}

static V h_push(V v, V vec) {
  vec_t *x = vchk(vec, "Vec.push: not a Vector");
  if (x->var == VR_UNSET) fix_layout(x, v);
  for (uw k = 0; k < x->ncols; k++)
    if (x->len == vl_cap(x->cols[k]->nblk)) vl_grow(x->cols[k]);
  switch (x->var) {
    case VR_INT:
      if (!ISINT(v)) fpr_cpanic("Vec.push: Int vector got a non-Int");
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
  switch (x->var) {
    case VR_INT:
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
  vec_t *x = vchk(vec, "Vec.set: not a Vector");
  if (!ISINT(iv)) fpr_cpanic("Vec.set: index not an Int");
  sw i = UNTAG(iv);
  if (i < 1 || (uw)i > x->len) fpr_cpanic("Vec.set: index out of range");
  switch (x->var) {
    case VR_INT:
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
  vfree(vchk(vec, "Vec.free: not a Vector"));
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
  V out = h_new((V)&fpr_unit);
  for (uw i = 0; i < x->len; i++) out = h_push(fpr_apply(f, row_at(x, i)), out);
  vfree(x);
  return out;
}

V fpr_vec_filter(V f, V vec) {
  vec_t *x = vchk(vec, "Vec.filter: not a Vector");
  V out = h_new((V)&fpr_unit);
  for (uw i = 0; i < x->len; i++) {
    V row = row_at(x, i);
    V keep = fpr_apply(f, row);
    if (!ISINT(keep) && ((hdr_t *)keep)->var) out = h_push(row, out);
  }
  vfree(x);
  return out;
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
  vfree(x);
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
  V lo = h_new((V)&fpr_unit), hi = h_new((V)&fpr_unit);
  for (uw i = 0; i < (uw)n; i++) lo = h_push(row_at(x, i), lo);
  for (uw i = (uw)n; i < x->len; i++) hi = h_push(row_at(x, i), hi);
  vfree(x);
  return mktup2(lo, hi);
}

/* ---- the discoverable-symbol table ------------------------------------ */
FPR_FN(fpr_g_Vec_x2enew, h_new, 1);
FPR_FN(fpr_g_Vec_x2epush, h_push, 2);
FPR_FN(fpr_g_Vec_x2elen, h_len, 1);
FPR_FN(fpr_g_Vec_x2eget, h_get, 2);
FPR_FN(fpr_g_Vec_x2eset, h_set, 3);
FPR_FN(fpr_g_Vec_x2emap, fpr_vec_map, 2);
FPR_FN(fpr_g_Vec_x2efilter, fpr_vec_filter, 2);
FPR_FN(fpr_g_Vec_x2efold, fpr_vec_fold, 3);
FPR_FN(fpr_g_Vec_x2efromList, h_fromList, 1);
FPR_FN(fpr_g_Vec_x2etoList, h_toList, 1);
FPR_FN(fpr_g_Vec_x2efree, h_free, 1);
FPR_FN(fpr_g_Vec_x2esplit, h_split, 2);
