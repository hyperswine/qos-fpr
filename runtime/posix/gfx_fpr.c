/* gfx_fpr.c (posix) -- the V-typed skin over the raw GPU tier
 * (gfx_raw.h), for CO-COMPILED GFX=1 images.  Same split discipline as
 * net.c over net_raw.c: this file only converts between FPRISC values
 * and the raw calls; the renderer itself lives in gfx.c and is shared
 * byte-for-byte with qosp's HAL table.  The FPRISC surface is
 * unchanged from before the split:
 *
 *   glInit w h     -> (w, h)   0 0 = auto     glRender scene -> (draws, dynBytes)
 *   glSavePpm path -> Int 0/1              inputPoll u    -> 0 | (kind, a, b)
 */
#include "fpr.h"
#include "gfx_raw.h"

static V h_glInit(V wv, V hv) {
  if (!ISINT(wv) || !ISINT(hv)) fpr_cpanic("glInit: w h must be Ints");
  gfx_init((int)UNTAG(wv), (int)UNTAG(hv));
  /* returns the SETTLED size: with 0 0 that is the display's own mode
   * (or 640x480 headless) -- the app lays out to what it actually got */
  int w = 0, h = 0;
  gfx_dims(&w, &h);
  V *r = (V *)fpr_alloc(24);
  ((hdr_t *)r)->tid = 4; ((hdr_t *)r)->var = 0;
  r[1] = TAG(w); r[2] = TAG(h);
  return (V)r;
}

static V h_glRender(V scene) {
  int64_t draws, dynBytes;
  gfx_render_scene((uint64_t)scene, &draws, &dynBytes);
  /* result: (draws, dynBytes) -- a pair built the mkbits way */
  V *r = (V *)fpr_alloc(24);
  ((hdr_t *)r)->tid = 4; ((hdr_t *)r)->var = 0;
  r[1] = TAG((sw)draws); r[2] = TAG((sw)dynBytes);
  return (V)r;
}

static V h_glSavePpm(V pathv) {
  if (ISINT(pathv) || TID(pathv) != T_STR) fpr_cpanic("glSavePpm: path must be a String");
  str_t *p = (str_t *)pathv;
  char path[256];
  uw n = p->len < sizeof path - 1 ? p->len : sizeof path - 1;
  for (uw i = 0; i < n; i++) path[i] = (char)p->bytes[i];
  path[n] = 0;
  return TAG(gfx_save_ppm(path));
}

static V h_inputPoll(V u) {
  (void)u;
  /* uniform shape, the Mod.resolve convention: a miss is data the
   * typed layer can case on -- (0, 0, 0) means no event pending */
  int64_t kind = 0, a = 0, c = 0;
  gfx_input_poll(&kind, &a, &c);
  V *t = (V *)fpr_alloc(32);
  ((hdr_t *)t)->tid = 5; ((hdr_t *)t)->var = 0; /* triple */
  t[1] = TAG((sw)kind); t[2] = TAG((sw)a); t[3] = TAG((sw)c);
  return (V)t;
}

FPR_FN(fpr_g_glInit, h_glInit, 2);
FPR_FN(fpr_g_glRender, h_glRender, 1);
FPR_FN(fpr_g_glSavePpm, h_glSavePpm, 1);
FPR_FN(fpr_g_inputPoll, h_inputPoll, 1);
