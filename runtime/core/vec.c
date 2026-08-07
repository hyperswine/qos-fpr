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
#include <limits.h>

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
  if (x->len && x->var != VR_INT) fpr_cpanic("SIMD tier: not an Int vector");
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
  vec_t *x = vnum(vec, "Vec.dup: not a Vector");
  V c = h_new((V)&fpr_unit);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) c = h_push(TAG(p[i]), c); });
  return mktup2(c, (V)x);
}

static V h_axpb(V av, V bv, V vec) {
  vec_t *x = vnum(vec, "Vec.axpb: not a Vector");
  sw a = UNTAG(av), b = UNTAG(bv);
  if (gpu_axpb_exact(x, a, b)) return (V)x;
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = a * p[i] + b; });
  return (V)x;
}

static V h_sar(V kv, V vec) {
  vec_t *x = vnum(vec, "Vec.sar: not a Vector");
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] >>= k; });
  return (V)x;
}

static V h_minS(V kv, V vec) {
  vec_t *x = vnum(vec, "Vec.minS: not a Vector");
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] < k ? p[i] : k; });
  return (V)x;
}

static V h_maxS(V kv, V vec) {
  vec_t *x = vnum(vec, "Vec.maxS: not a Vector");
  sw k = UNTAG(kv);
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] > k ? p[i] : k; });
  return (V)x;
}

static V h_ges(V kv, V vec) {
  vec_t *x = vnum(vec, "Vec.ges: not a Vector");
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
    vec_t *_d = vnum(dv, WHO), *_s = vzip2(dv, sv, WHO);                     \
    uw _r = _d->len;                                                         \
    for (uw _j = 0; _r; _j++) {                                              \
      uw _n = ((uw)VL_B0 << _j) < _r ? ((uw)VL_B0 << _j) : _r;               \
      sw *p = (sw *)_d->cols[0]->blk[_j], *q = (sw *)_s->cols[0]->blk[_j];   \
      for (uw _i = 0; _i < _n; _i++) { sw A = p[_i], B = q[_i]; p[_i] = (EXPR); } \
      _r -= _n;                                                              \
    }                                                                        \
    vfree(_s);                                                               \
    return (V)_d;                                                            \
  } while (0)

static V h_zipAdd(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipAdd", A + B); }
static V h_zipMul(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipMul", A * B); }
static V h_zipMin(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipMin", A < B ? A : B); }
static V h_zipLt(V dv, V sv)  { VS_ZIP(dv, sv, "Vec.zipLt", A < B); }
static V h_zipDiv(V dv, V sv) { VS_ZIP(dv, sv, "Vec.zipDiv", B == 0 ? 0 : A / B); }

/* gather: idx[i] := src[idx[i]] (out of range -> 0); src threads back */
static V h_gather(V iv, V sv) {
  vec_t *x = vnum(iv, "Vec.gather: not a Vector");
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
  vec_t *d = vnum(dv, "Vec.blend: not a Vector");
  if (m->len != d->len || s->len != d->len) fpr_cpanic("Vec.blend: length mismatch");
  uw r = d->len;
  for (uw j = 0; r; j++) {
    uw n = ((uw)VL_B0 << j) < r ? ((uw)VL_B0 << j) : r;
    sw *pd = (sw *)d->cols[0]->blk[j], *pm = (sw *)m->cols[0]->blk[j],
       *ps = (sw *)s->cols[0]->blk[j];
    for (uw i = 0; i < n; i++) pd[i] = pm[i] ? ps[i] : pd[i];
    r -= n;
  }
  vfree(m); vfree(s);
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
  vec_t *d = vnum(dv, "Vec.burst: not a Vector");
  if (!ISINT(ov)) fpr_cpanic("Vec.burst: offset not an Int");
  sw off = UNTAG(ov);
  if (off < 0 || (uw)off + s->len > d->len) fpr_cpanic("Vec.burst: out of range");
  VS_BLOCKS(s, {
    uw base = vl_cap(j); /* first index of block j */
    for (uw i = 0; i < n; i++) *(sw *)vl_slot(d->cols[0], (uw)off + base + i) = p[i];
  });
  vfree(s);
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
  vec_t *x = vnum(vec, "Vec.absv: not a Vector");
  VS_BLOCKS(x, { for (uw i = 0; i < n; i++) p[i] = p[i] < 0 ? -p[i] : p[i]; });
  return (V)x;
}

static V h_eqS(V kv, V vec) {
  vec_t *x = vnum(vec, "Vec.eqS: not a Vector");
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
