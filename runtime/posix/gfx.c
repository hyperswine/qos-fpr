/* gfx.c (posix) — the GPU tier: a scene-driven render function.
 *
 * A C port of the gl_scene ES 3.1 renderer (es_renderer.hpp /
 * egl_headless.cpp — the Haskell-FFI original), re-seated as an FPRISC
 * HAL capability: instead of CScene structs crossing a Haskell FFI, the
 * render function WALKS AN FPRISC VALUE directly.  Same architecture as
 * the original: content-addressed mesh upload (each MeshId uploaded
 * once), the static/dynamic instance split (statics compiled to GPU
 * buffers once; dynamics re-uploaded per frame), one instanced draw per
 * (mesh, tier), offscreen FBO under surfaceless EGL, readback for
 * presentation.
 *
 * FPRISC surface (all linearized by ONE graphics service actor — the
 * GL context is thread-bound, so exactly one actor, pinned to its
 * spawn hart, may own these):
 *
 *   glInit w h        -> Int 1      create context + renderer (once)
 *   glRender scene    -> (draws, dynBytes)   walk + draw one frame
 *   glSavePpm path    -> Int 0/1    read back the FBO, write a PPM
 *   inputPoll u       -> 0 | (kind, a, b)    kbd/mouse event or none
 *
 * The Scene VALUE, in FPRISC terms (all numbers Int MILLI-units —
 * FPRISC has no floats; the walker divides by 1000):
 *
 *   scene  = (statics, dynamics, lights, camera)     4-tuple
 *   entity = (mesh, pos, yawMilli, scale, color)     5-tuple
 *   pos/scale/color = (x, y, z)                      triple
 *   light  = (pos, color)                            pair
 *   camera = (eye, target, fovMilli)                 triple
 *   statics/dynamics/lights = lists of the above
 *
 * Input: keyboard is nonblocking stdin bytes; mouse is /dev/input/mice
 * (the kernel's 3-byte PS/2-style aggregate — works on a Linux console
 * with no window system at all; absent in containers/ssh, in which case
 * inputPoll simply never reports mouse events).  Events:
 *   (1, byte, 0)  key    (2, dx, dy)  mouse move    (3, buttons, 0)
 */
#include "fpr.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl31.h>
#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* ==== small math (vecmath.hpp, column-major, ported verbatim) ======== */
typedef struct { float x, y, z; } v3;
static v3 v3sub(v3 a, v3 b) { return (v3){a.x - b.x, a.y - b.y, a.z - b.z}; }
static float v3dot(v3 a, v3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
static v3 v3cross(v3 a, v3 b) {
  return (v3){a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
static v3 v3norm(v3 a) {
  float l = sqrtf(v3dot(a, a));
  return l > 0 ? (v3){a.x / l, a.y / l, a.z / l} : a;
}
typedef struct { float m[16]; } m4;
static m4 m4id(void) { m4 r = {{0}}; r.m[0] = r.m[5] = r.m[10] = r.m[15] = 1; return r; }
static m4 m4mul(m4 a, m4 b) {
  m4 r = {{0}};
  for (int c = 0; c < 4; c++)
    for (int rw = 0; rw < 4; rw++) {
      float s = 0;
      for (int k = 0; k < 4; k++) s += a.m[k * 4 + rw] * b.m[c * 4 + k];
      r.m[c * 4 + rw] = s;
    }
  return r;
}
static m4 m4translate(v3 t) { m4 r = m4id(); r.m[12] = t.x; r.m[13] = t.y; r.m[14] = t.z; return r; }
static m4 m4scale(v3 s) { m4 r = m4id(); r.m[0] = s.x; r.m[5] = s.y; r.m[10] = s.z; return r; }
static m4 m4rotY(float a) {
  m4 r = m4id();
  float c = cosf(a), s = sinf(a);
  r.m[0] = c; r.m[2] = s; r.m[8] = -s; r.m[10] = c;
  return r;
}
static m4 m4persp(float fovy, float aspect, float zn, float zf) {
  m4 r = {{0}};
  float f = 1.0f / tanf(fovy / 2.0f);
  r.m[0] = f / aspect; r.m[5] = f;
  r.m[10] = (zf + zn) / (zn - zf); r.m[11] = -1;
  r.m[14] = (2 * zf * zn) / (zn - zf);
  return r;
}
static m4 m4lookAt(v3 eye, v3 center, v3 up) {
  v3 f = v3norm(v3sub(center, eye));
  v3 s = v3norm(v3cross(f, up));
  v3 u = v3cross(s, f);
  m4 r = m4id();
  r.m[0] = s.x; r.m[4] = s.y; r.m[8] = s.z;
  r.m[1] = u.x; r.m[5] = u.y; r.m[9] = u.z;
  r.m[2] = -f.x; r.m[6] = -f.y; r.m[10] = -f.z;
  r.m[12] = -v3dot(s, eye); r.m[13] = -v3dot(u, eye); r.m[14] = v3dot(f, eye);
  return r;
}

/* ==== mesh data (mesh_data.hpp generators, C'd) ====================== */
/* interleaved [px py pz nx ny nz]; the registry is the one place a
 * MeshId string maps to geometry (content-addressing seam) */
#define MAX_VERTS (17 * 25 * 6)
#define MAX_IDX (16 * 24 * 6)
typedef struct { float v[MAX_VERTS]; int nv; uint32_t ix[MAX_IDX]; int ni; } rawmesh_t;

static void mesh_cube(rawmesh_t *m) {
  static const float F[6][15] = { /* n, v0..v3 (unit cube corners) */
      {0,0,1,  -1,-1,1,  1,-1,1,  1,1,1,  -1,1,1},
      {0,0,-1, 1,-1,-1, -1,-1,-1, -1,1,-1, 1,1,-1},
      {1,0,0,  1,-1,1,  1,-1,-1, 1,1,-1,  1,1,1},
      {-1,0,0, -1,-1,-1, -1,-1,1, -1,1,1, -1,1,-1},
      {0,1,0,  -1,1,1,  1,1,1,   1,1,-1,  -1,1,-1},
      {0,-1,0, -1,-1,-1, 1,-1,-1, 1,-1,1, -1,-1,1}};
  m->nv = m->ni = 0;
  for (int f = 0; f < 6; f++) {
    uint32_t base = (uint32_t)(m->nv / 6);
    for (int k = 0; k < 4; k++) {
      const float *v = &F[f][3 + k * 3];
      float out[6] = {v[0] * 0.5f, v[1] * 0.5f, v[2] * 0.5f, F[f][0], F[f][1], F[f][2]};
      memcpy(&m->v[m->nv], out, sizeof out);
      m->nv += 6;
    }
    uint32_t tri[6] = {base, base + 1, base + 2, base, base + 2, base + 3};
    memcpy(&m->ix[m->ni], tri, sizeof tri);
    m->ni += 6;
  }
}
static void mesh_plane(rawmesh_t *m) {
  static const float V[] = {-1,0,-1, 0,1,0,  1,0,-1, 0,1,0,
                            1,0,1,  0,1,0,  -1,0,1, 0,1,0};
  static const uint32_t I[] = {0, 1, 2, 0, 2, 3};
  memcpy(m->v, V, sizeof V); m->nv = 24;
  memcpy(m->ix, I, sizeof I); m->ni = 6;
}
static void mesh_sphere(rawmesh_t *m) { /* UV sphere r=0.5, 16x24 */
  const int stacks = 16, slices = 24;
  m->nv = m->ni = 0;
  for (int i = 0; i <= stacks; i++) {
    float phi = (float)i / stacks * 3.14159265f;
    for (int j = 0; j <= slices; j++) {
      float th = (float)j / slices * 6.2831853f;
      float nx = sinf(phi) * cosf(th), ny = cosf(phi), nz = sinf(phi) * sinf(th);
      float out[6] = {nx * 0.5f, ny * 0.5f, nz * 0.5f, nx, ny, nz};
      memcpy(&m->v[m->nv], out, sizeof out);
      m->nv += 6;
    }
  }
  for (int i = 0; i < stacks; i++)
    for (int j = 0; j < slices; j++) {
      uint32_t a = (uint32_t)(i * (slices + 1) + j), b = a + (uint32_t)slices + 1;
      uint32_t tri[6] = {a, b, a + 1, a + 1, b, b + 1};
      memcpy(&m->ix[m->ni], tri, sizeof tri);
      m->ni += 6;
    }
}

/* ==== renderer state (RenderCache, fixed-capacity C tables) ========== */
typedef struct { float model[16]; float color[3]; float pad; } inst_t;

#define MAX_MESHES 16
#define MAX_INST 4096 /* per mesh per tier */
typedef struct {
  char name[32];
  GLuint vao, vbo, ebo;
  GLsizei indexCount;
  GLuint staticVBO; GLsizei staticCount;
  GLuint dynVBO;
  /* per-frame staging (walker output) */
  inst_t *stage; int nstage;
} mesh_t;

static struct {
  int inited;
  EGLDisplay dpy; EGLContext ctx;
  GLuint prog; GLint uProj, uView, uLightPos, uLightColor;
  GLuint fbo, fboColor, fboDepth;
  int w, h;
  mesh_t meshes[MAX_MESHES]; int nmeshes;
  int staticCompiled;
} G;

static const char *kVS =
    "#version 310 es\n"
    "precision highp float;\n"
    "layout(location=0) in vec3 inPos;\n"
    "layout(location=1) in vec3 inNormal;\n"
    "layout(location=2) in vec4 iM0;\n"
    "layout(location=3) in vec4 iM1;\n"
    "layout(location=4) in vec4 iM2;\n"
    "layout(location=5) in vec4 iM3;\n"
    "layout(location=6) in vec3 iColor;\n"
    "uniform mat4 uView; uniform mat4 uProj;\n"
    "out vec3 vN; out vec3 vW; out vec3 vC;\n"
    "void main(){ mat4 model = mat4(iM0,iM1,iM2,iM3);\n"
    "  vec4 world = model*vec4(inPos,1.0); vW = world.xyz;\n"
    "  vN = mat3(model)*inNormal; vC = iColor;\n"
    "  gl_Position = uProj*uView*world; }\n";
static const char *kFS =
    "#version 310 es\n"
    "precision highp float;\n"
    "in vec3 vN; in vec3 vW; in vec3 vC;\n"
    "uniform vec3 uLightPos; uniform vec3 uLightColor;\n"
    "out vec4 fragColor;\n"
    "void main(){ vec3 n = normalize(vN);\n"
    "  vec3 l = normalize(uLightPos - vW);\n"
    "  float d = max(dot(n,l), 0.0);\n"
    "  fragColor = vec4(0.15*vC + d*vC*uLightColor, 1.0); }\n";

static GLuint gfx_shader(GLenum type, const char *src) {
  GLuint s = glCreateShader(type);
  glShaderSource(s, 1, &src, 0);
  glCompileShader(s);
  GLint ok = 0;
  glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
  if (!ok) {
    char log[1024];
    glGetShaderInfoLog(s, sizeof log, 0, log);
    fprintf(stderr, "gfx: shader error:\n%s\n", log);
    fpr_cpanic("gfx: shader compile failed");
  }
  return s;
}

/* egl_headless.cpp, C'd: surfaceless via the platform-display
 * extension, falling back to the default display.  PREFER_GBM and the
 * render-node path are the Pi-hardware upgrade, not ported yet. */
static EGLDisplay egl_display(const char **how) {
  PFNEGLGETPLATFORMDISPLAYEXTPROC getPlat =
      (PFNEGLGETPLATFORMDISPLAYEXTPROC)eglGetProcAddress("eglGetPlatformDisplayEXT");
  const char *exts = eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
  if (getPlat && exts && strstr(exts, "EGL_MESA_platform_surfaceless")) {
    EGLDisplay d = getPlat(0x31DD /* EGL_PLATFORM_SURFACELESS_MESA */, EGL_DEFAULT_DISPLAY, 0);
    if (d != EGL_NO_DISPLAY) { *how = "surfaceless"; return d; }
  }
  *how = "default";
  return eglGetDisplay(EGL_DEFAULT_DISPLAY);
}

void gfx_init(int w, int h) { /* raw export: gfx_raw.h */
  if (G.inited) return;
  const char *how = "?";
  G.dpy = egl_display(&how);
  if (G.dpy == EGL_NO_DISPLAY) fpr_cpanic("gfx: no EGL display (is Mesa installed?)");
  EGLint maj, min;
  if (!eglInitialize(G.dpy, &maj, &min)) fpr_cpanic("gfx: eglInitialize failed");
  eglBindAPI(EGL_OPENGL_ES_API);
  static const EGLint cfgAttr[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
                                   EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT, EGL_NONE};
  EGLConfig cfg; EGLint n = 0;
  eglChooseConfig(G.dpy, cfgAttr, &cfg, 1, &n);
  static const EGLint ctxAttr[] = {EGL_CONTEXT_MAJOR_VERSION, 3,
                                   EGL_CONTEXT_MINOR_VERSION, 1, EGL_NONE};
  G.ctx = eglCreateContext(G.dpy, n ? cfg : 0, EGL_NO_CONTEXT, ctxAttr);
  if (G.ctx == EGL_NO_CONTEXT) fpr_cpanic("gfx: eglCreateContext(ES 3.1) failed");
  if (!eglMakeCurrent(G.dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, G.ctx))
    fpr_cpanic("gfx: eglMakeCurrent (surfaceless) failed");
  fprintf(stderr, "[gfx] EGL %d.%d (%s)  %s / %s\n", maj, min, how,
          glGetString(GL_RENDERER), glGetString(GL_VERSION));

  GLuint vs = gfx_shader(GL_VERTEX_SHADER, kVS), fs = gfx_shader(GL_FRAGMENT_SHADER, kFS);
  G.prog = glCreateProgram();
  glAttachShader(G.prog, vs); glAttachShader(G.prog, fs);
  glLinkProgram(G.prog);
  GLint ok = 0;
  glGetProgramiv(G.prog, GL_LINK_STATUS, &ok);
  if (!ok) fpr_cpanic("gfx: program link failed");
  glDeleteShader(vs); glDeleteShader(fs);
  G.uProj = glGetUniformLocation(G.prog, "uProj");
  G.uView = glGetUniformLocation(G.prog, "uView");
  G.uLightPos = glGetUniformLocation(G.prog, "uLightPos");
  G.uLightColor = glGetUniformLocation(G.prog, "uLightColor");

  /* offscreen target: surfaceless EGL has no default framebuffer */
  G.w = w; G.h = h;
  glGenTextures(1, &G.fboColor);
  glBindTexture(GL_TEXTURE_2D, G.fboColor);
  glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, w, h);
  glGenRenderbuffers(1, &G.fboDepth);
  glBindRenderbuffer(GL_RENDERBUFFER, G.fboDepth);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, w, h);
  glGenFramebuffers(1, &G.fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, G.fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, G.fboColor, 0);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, G.fboDepth);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    fpr_cpanic("gfx: offscreen framebuffer incomplete");
  G.inited = 1;
}

/* content-addressed upload: a MeshId is uploaded once, ever */
static mesh_t *gfx_mesh(const char *name, uw len) {
  for (int i = 0; i < G.nmeshes; i++)
    if (strlen(G.meshes[i].name) == len && !memcmp(G.meshes[i].name, name, len))
      return &G.meshes[i];
  if (G.nmeshes == MAX_MESHES) fpr_cpanic("gfx: mesh table full");
  mesh_t *m = &G.meshes[G.nmeshes++];
  memset(m, 0, sizeof *m);
  if (len >= sizeof m->name) len = sizeof m->name - 1;
  memcpy(m->name, name, len);

  static rawmesh_t raw; /* big; static scratch — single-threaded by the service actor */
  if (!strcmp(m->name, "cube")) mesh_cube(&raw);
  else if (!strcmp(m->name, "plane")) mesh_plane(&raw);
  else if (!strcmp(m->name, "sphere")) mesh_sphere(&raw);
  else fpr_cpanic("gfx: unknown mesh id (registry: cube plane sphere)");

  glGenVertexArrays(1, &m->vao);
  glBindVertexArray(m->vao);
  glGenBuffers(1, &m->vbo);
  glBindBuffer(GL_ARRAY_BUFFER, m->vbo);
  glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)((size_t)raw.nv * sizeof(float)), raw.v, GL_STATIC_DRAW);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void *)0);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void *)(3 * sizeof(float)));
  glGenBuffers(1, &m->ebo);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m->ebo);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, (GLsizeiptr)((size_t)raw.ni * sizeof(uint32_t)), raw.ix,
               GL_STATIC_DRAW);
  m->indexCount = raw.ni;
  m->stage = malloc(MAX_INST * sizeof(inst_t));
  if (!m->stage) fpr_cpanic("gfx: instance staging alloc");
  return m;
}

static void gfx_bind_instances(GLuint vbo) {
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  for (int i = 0; i < 4; i++) {
    GLuint loc = (GLuint)(2 + i);
    glEnableVertexAttribArray(loc);
    glVertexAttribPointer(loc, 4, GL_FLOAT, GL_FALSE, sizeof(inst_t),
                          (void *)(size_t)(i * 4 * sizeof(float)));
    glVertexAttribDivisor(loc, 1);
  }
  glEnableVertexAttribArray(6);
  glVertexAttribPointer(6, 3, GL_FLOAT, GL_FALSE, sizeof(inst_t),
                        (void *)offsetof(inst_t, color));
  glVertexAttribDivisor(6, 1);
}

/* ==== the FPRISC scene walker ======================================== */
/* value layout (fpr.h/runtime.c): Int = (n<<1)|1; objects = hdr{tid,var}
 * + V fields at +8.  T_LIST var 0/1 = Nil/Cons(head,tail); tuples tid 4
 * (triples tid 5), arity implied by this schema. */
static float fmilli(V v) {
  if (!ISINT(v)) fpr_cpanic("gfx: expected Int (milli-units) in scene");
  return (float)UNTAG(v) / 1000.0f;
}
static V *fields(V v, uint32_t tid, const char *what) {
  if (ISINT(v) || TID(v) != tid) fpr_cpanic(what);
  return (V *)((char *)v + 8);
}
static v3 walk_v3(V v) {
  V *f = fields(v, 5, "gfx: expected (x, y, z) triple");
  return (v3){fmilli(f[0]), fmilli(f[1]), fmilli(f[2])};
}
/* entity = (mesh, pos, yawMilli, scale, color): stage one instance */
static void walk_entity(V v) {
  V *f = fields(v, 4, "gfx: expected entity 5-tuple");
  V ms = f[0];
  if (ISINT(ms) || TID(ms) != T_STR) fpr_cpanic("gfx: entity mesh must be a String");
  str_t *s = (str_t *)ms;
  mesh_t *m = gfx_mesh((const char *)s->bytes, s->len);
  if (m->nstage == MAX_INST) fpr_cpanic("gfx: too many instances of one mesh");
  inst_t *it = &m->stage[m->nstage++];
  v3 pos = walk_v3(f[1]);
  float yaw = fmilli(f[2]);
  v3 sc = walk_v3(f[3]);
  v3 col = walk_v3(f[4]);
  m4 model = m4mul(m4translate(pos), m4mul(m4rotY(yaw), m4scale(sc)));
  memcpy(it->model, model.m, sizeof it->model);
  it->color[0] = col.x; it->color[1] = col.y; it->color[2] = col.z;
}
static void walk_list(V v, void (*each)(V)) {
  for (;;) {
    if (ISINT(v) || TID(v) != T_LIST) fpr_cpanic("gfx: expected a list in scene");
    hdr_t *h = (hdr_t *)v;
    if (h->var == 0) return;
    V *f = (V *)((char *)v + 8);
    each(f[0]);
    v = f[1];
  }
}
static void stage_clear(void) {
  for (int i = 0; i < G.nmeshes; i++) G.meshes[i].nstage = 0;
}

/* ==== the raw surface (gfx_raw.h) ====================================
 * The V-CONSTRUCTING layer was factored out (gfx_fpr.c) the same way
 * net.c's socket tier was (net_raw.c), and for the same reason: this
 * core has exactly two consumers -- the co-compiled posix HAL, and
 * qosp's HAL table.  What stays here is allocation-free with respect
 * to the FPRISC heap: gfx_render_scene WALKS the scene value read-only
 * (fine across images: qosp shares the app's address space and fpr.h
 * layout), and results leave through out-params; whichever side wraps
 * this builds its V results with ITS OWN allocator. */
int gfx_render_scene(uint64_t scenev, int64_t *draws_out, int64_t *dyn_bytes_out) {
  V scene = (V)scenev;
  if (!G.inited) fpr_cpanic("glRender: glInit first");
  V *f = fields(scene, 4, "gfx: scene must be (statics, dynamics, lights, camera)");
  int draws = 0; sw dynBytes = 0;

  /* statics: compiled to GPU buffers exactly once (first frame) */
  if (!G.staticCompiled) {
    stage_clear();
    walk_list(f[0], walk_entity);
    for (int i = 0; i < G.nmeshes; i++) {
      mesh_t *m = &G.meshes[i];
      if (!m->nstage) continue;
      glGenBuffers(1, &m->staticVBO);
      glBindBuffer(GL_ARRAY_BUFFER, m->staticVBO);
      glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)((size_t)m->nstage * sizeof(inst_t)), m->stage,
                   GL_STATIC_DRAW);
      m->staticCount = m->nstage;
    }
    G.staticCompiled = 1;
  }

  /* dynamics: staged from the value and re-uploaded, every frame */
  stage_clear();
  walk_list(f[1], walk_entity);
  for (int i = 0; i < G.nmeshes; i++) {
    mesh_t *m = &G.meshes[i];
    if (!m->nstage) continue;
    if (!m->dynVBO) glGenBuffers(1, &m->dynVBO);
    glBindBuffer(GL_ARRAY_BUFFER, m->dynVBO);
    glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)((size_t)m->nstage * sizeof(inst_t)), m->stage,
                 GL_DYNAMIC_DRAW);
    dynBytes += (sw)((size_t)m->nstage * sizeof(inst_t));
  }

  /* camera + first light out of the value */
  V *cam = fields(f[3], 5, "gfx: camera must be (eye, target, fovMilli)");
  m4 view = m4lookAt(walk_v3(cam[0]), walk_v3(cam[1]), (v3){0, 1, 0});
  m4 proj = m4persp(fmilli(cam[2]), (float)G.w / (float)G.h, 0.1f, 100.0f);
  v3 lp = {5, 5, 5}, lc = {1, 1, 1};
  V lv = f[2];
  if (!ISINT(lv) && TID(lv) == T_LIST && ((hdr_t *)lv)->var == 1) {
    V *lf = (V *)((char *)lv + 8);
    V *l0 = fields(lf[0], 4, "gfx: light must be (pos, color)");
    lp = walk_v3(l0[0]); lc = walk_v3(l0[1]);
  }

  glBindFramebuffer(GL_FRAMEBUFFER, G.fbo);
  glViewport(0, 0, G.w, G.h);
  glEnable(GL_DEPTH_TEST);
  glClearColor(0.06f, 0.07f, 0.09f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glUseProgram(G.prog);
  glUniformMatrix4fv(G.uView, 1, GL_FALSE, view.m);
  glUniformMatrix4fv(G.uProj, 1, GL_FALSE, proj.m);
  glUniform3f(G.uLightPos, lp.x, lp.y, lp.z);
  glUniform3f(G.uLightColor, lc.x, lc.y, lc.z);

  for (int i = 0; i < G.nmeshes; i++) {
    mesh_t *m = &G.meshes[i];
    if (!m->staticCount && !m->nstage) continue;
    glBindVertexArray(m->vao);
    if (m->staticCount) {
      gfx_bind_instances(m->staticVBO);
      glDrawElementsInstanced(GL_TRIANGLES, m->indexCount, GL_UNSIGNED_INT, 0, m->staticCount);
      draws++;
    }
    if (m->nstage) {
      gfx_bind_instances(m->dynVBO);
      glDrawElementsInstanced(GL_TRIANGLES, m->indexCount, GL_UNSIGNED_INT, 0, m->nstage);
      draws++;
    }
  }
  *draws_out = draws;
  *dyn_bytes_out = dynBytes;
  return 0;
}

int gfx_save_ppm(const char *path) {
  if (!G.inited) fpr_cpanic("glSavePpm: glInit first");
  int w = G.w, h = G.h;
  unsigned char *pix = malloc((size_t)w * h * 4);
  if (!pix) return 1;
  glBindFramebuffer(GL_FRAMEBUFFER, G.fbo);
  glFinish();
  glPixelStorei(GL_PACK_ALIGNMENT, 1);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, pix);
  FILE *fp = fopen(path, "wb");
  if (!fp) { free(pix); return 1; }
  fprintf(fp, "P6\n%d %d\n255\n", w, h);
  for (int y = h - 1; y >= 0; y--) { /* GL is bottom-up; PPM top-down */
    const unsigned char *src = pix + (size_t)y * w * 4;
    for (int x = 0; x < w; x++) fwrite(src + x * 4, 1, 3, fp);
  }
  fclose(fp);
  free(pix);
  return 0;
}

/* ==== input ========================================================== */
static int mice_fd = -2; /* -2 = untried, -1 = unavailable */
int gfx_input_poll(int64_t *kind_out, int64_t *a_out, int64_t *c_out) {
  /* keyboard: one nonblocking stdin byte */
  int fl = fcntl(0, F_GETFL);
  fcntl(0, F_SETFL, fl | O_NONBLOCK);
  unsigned char b;
  ssize_t r = read(0, &b, 1);
  fcntl(0, F_SETFL, fl);
  int kind = 0; sw a = 0, c = 0;
  if (r == 1) { kind = 1; a = b; }
  else {
    /* mouse: /dev/input/mice, the kernel's PS/2-style aggregate --
     * works on a bare Linux console; simply absent under ssh/containers */
    if (mice_fd == -2) mice_fd = open("/dev/input/mice", O_RDONLY | O_NONBLOCK);
    if (mice_fd >= 0) {
      unsigned char pkt[3];
      if (read(mice_fd, pkt, 3) == 3) {
        signed char dx = (signed char)pkt[1], dy = (signed char)pkt[2];
        if (dx || dy) { kind = 2; a = dx; c = dy; }
        else { kind = 3; a = pkt[0] & 7; }
      }
    }
  }
  *kind_out = kind; *a_out = a; *c_out = c;
  return kind != 0;
}
