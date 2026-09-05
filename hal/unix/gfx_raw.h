/* gfx_raw.h -- the raw GPU tier (net_raw.h's gfx sibling).  One
 * implementation (gfx.c: EGL/ES 3.1 context, the scene-value walker,
 * FBO readback, kbd/mouse polling), two consumers:
 *
 *   - runtime/posix/gfx_fpr.c: V-typed FPR_FN wrappers, co-compiled
 *     into a GFX=1 posix image.
 *   - runtime/portable/haltab.c: the same functions as qos_hal_t table
 *     entries in a GFX=1 qosp.
 *
 * gfx_render_scene takes the scene VALUE as a uint64_t: the walker
 * reads it through fpr.h's layout macros, read-only and allocation-
 * free -- valid across images because host and app share one address
 * space (docs/QOS-PORTABLE.md).  Faults inside (malformed scene,
 * missing context) are fpr_cpanic on the co-compiled side and the
 * host's own loud-exit fpr_cpanic definition inside qosp. */
#ifndef QOS_GFX_RAW_H
#define QOS_GFX_RAW_H

#include <stdint.h>

void gfx_init(int w, int h); /* create context + renderer (once);
                              * w==0||h==0 = AUTO: size to the display */
void gfx_dims(int *w, int *h); /* the FBO size gfx_init settled on */
int gfx_render_scene(uint64_t scenev, int64_t *draws, int64_t *dyn_bytes);
/* the same, then a 2D layer (a List of Ent, scene2d's pixel space at dist
 * milli) over it: depth cleared, colour kept, then presented */
int gfx_render_overlay(uint64_t scenev, uint64_t ui, int64_t dist, int64_t *draws, int64_t *dyn_bytes);
int gfx_save_ppm(const char *path); /* 0 ok, 1 io failure */
int64_t gfx_mesh_load(const char *name, const char *text, uint64_t len); /* triangles, -1 bad */
int gfx_input_poll(int64_t *kind, int64_t *a, int64_t *c); /* 1 = event */

#endif
