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
 *   inputPoll u       -> (kind, a, b)   kind 0 = none (uniform shape)
 *
 * The Scene VALUE, in FPRISC terms (all numbers Int MILLI-units —
 * FPRISC has no floats; the walker divides by 1000):
 *
 *   scene  = (statics, dynamics, lights, camera)     4-tuple
 *   entity = (mesh, pos, yawMilli, scale, color)     5-tuple
 *   pos/scale/color = (x, y, z)                      triple
 *   light  = (pos, color)                            pair
 *   camera = (eye, target, fovMilli) triple, OR an Int = the
 *            2D case: eye distance in milli on +Z, origin target
 *   statics/dynamics/lights = lists of the above
 *
 * Input: keyboard is nonblocking stdin bytes; mouse is /dev/input/mice
 * (the kernel's 3-byte PS/2-style aggregate — works on a Linux console
 * with no window system at all; absent in containers/ssh, in which case
 * inputPoll simply never reports mouse events).  Events:
 *   (1, byte, 0)  key    (2, dx, dy)  mouse move    (3, buttons, 0)
 */
#include "fpr.h"
#include "hostlog.h"
#include "evdev_raw.h"
#ifdef FPR_DESKTOP_GL
#ifndef __APPLE__
#define GL_GLEXT_PROTOTYPES 1 /* GL/glcorearb.h gates prototypes on this;
                               * macOS's OpenGL/gl3.h always declares them */
#endif
#define GLFW_INCLUDE_GLCOREARB
#include <GLFW/glfw3.h>
#else
#include "evdev_raw.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl31.h>
#endif
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#ifndef FPR_DESKTOP_GL
#include "drm_scanout.h"
#endif

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
#define MAX_INST 16384 /* per mesh per tier: a 5x8 glyph is up to 40
                            * cube instances, and a text-heavy screen
                            * (the CLI, the browser listing) runs to
                            * thousands -- 4096 was sized for 3x5 */
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
#ifdef FPR_DESKTOP_GL
  GLFWwindow *window;
#else
  EGLDisplay dpy; EGLContext ctx;
#endif
  GLuint prog; GLint uProj, uView, uLightPos, uLightColor;
  GLuint fbo, fboColor, fboDepth;
  int w, h;
  mesh_t meshes[MAX_MESHES]; int nmeshes;
  int staticCompiled;
  uint64_t lastStatics; /* value identity of the compiled statics list */
  pthread_t boundTid; int haveTid; /* thread the context is current on */
#ifndef FPR_DESKTOP_GL
  drm_out_t drm; /* the monitor link (drm_scanout.h); .on = 0 offscreen */
#endif
} G;

#ifdef FPR_DESKTOP_GL
#define GFX_EVENT_CAP 64
typedef struct { int64_t kind, a, c; } gfx_event_t;
static gfx_event_t gfx_events[GFX_EVENT_CAP];
static unsigned gfx_event_read, gfx_event_write;
static double gfx_cursor_x, gfx_cursor_y;
static int gfx_have_cursor;
static int gfx_mouse_buttons;

static void gfx_event_push(int64_t kind, int64_t a, int64_t c) {
  unsigned next = (gfx_event_write + 1) % GFX_EVENT_CAP;
  if (next == gfx_event_read) gfx_event_read = (gfx_event_read + 1) % GFX_EVENT_CAP;
  gfx_events[gfx_event_write] = (gfx_event_t){kind, a, c};
  gfx_event_write = next;
}

/* GLFW keys become SYNTHETIC EVDEV -- translated to evdev
 * codes and injected into evdev_raw's decoder, so the modifier state
 * machine, the appkit keymap, and FPR_EVDEV replay determinism are
 * all untouched (under FPR_EVDEV the injection is dropped and the
 * explicit source wins).  Modifier keys are injected AS KEYS -- the
 * one machine tracks them; GLFW's `mods` bitmask is deliberately
 * ignored so there is exactly one source of shift truth. */
static unsigned short gfx_glfw_to_evdev(int key) {
  switch (key) {
    case GLFW_KEY_A: return 30;  case GLFW_KEY_B: return 48;
    case GLFW_KEY_C: return 46;  case GLFW_KEY_D: return 32;
    case GLFW_KEY_E: return 18;  case GLFW_KEY_F: return 33;
    case GLFW_KEY_G: return 34;  case GLFW_KEY_H: return 35;
    case GLFW_KEY_I: return 23;  case GLFW_KEY_J: return 36;
    case GLFW_KEY_K: return 37;  case GLFW_KEY_L: return 38;
    case GLFW_KEY_M: return 50;  case GLFW_KEY_N: return 49;
    case GLFW_KEY_O: return 24;  case GLFW_KEY_P: return 25;
    case GLFW_KEY_Q: return 16;  case GLFW_KEY_R: return 19;
    case GLFW_KEY_S: return 31;  case GLFW_KEY_T: return 20;
    case GLFW_KEY_U: return 22;  case GLFW_KEY_V: return 47;
    case GLFW_KEY_W: return 17;  case GLFW_KEY_X: return 45;
    case GLFW_KEY_Y: return 21;  case GLFW_KEY_Z: return 44;
    case GLFW_KEY_1: return 2;   case GLFW_KEY_2: return 3;
    case GLFW_KEY_3: return 4;   case GLFW_KEY_4: return 5;
    case GLFW_KEY_5: return 6;   case GLFW_KEY_6: return 7;
    case GLFW_KEY_7: return 8;   case GLFW_KEY_8: return 9;
    case GLFW_KEY_9: return 10;  case GLFW_KEY_0: return 11;
    case GLFW_KEY_SPACE: return 57;
    case GLFW_KEY_ENTER: return 28;
    case GLFW_KEY_ESCAPE: return 1;
    case GLFW_KEY_BACKSPACE: return 14;
    case GLFW_KEY_TAB: return 15;
    case GLFW_KEY_MINUS: return 12;      case GLFW_KEY_EQUAL: return 13;
    case GLFW_KEY_LEFT_BRACKET: return 26;
    case GLFW_KEY_RIGHT_BRACKET: return 27;
    case GLFW_KEY_SEMICOLON: return 39;  case GLFW_KEY_APOSTROPHE: return 40;
    case GLFW_KEY_GRAVE_ACCENT: return 41;
    case GLFW_KEY_BACKSLASH: return 43;
    case GLFW_KEY_COMMA: return 51;      case GLFW_KEY_PERIOD: return 52;
    case GLFW_KEY_SLASH: return 53;
    case GLFW_KEY_UP: return 103;        case GLFW_KEY_DOWN: return 108;
    case GLFW_KEY_LEFT: return 105;      case GLFW_KEY_RIGHT: return 106;
    case GLFW_KEY_HOME: return 102;      case GLFW_KEY_END: return 107;
    case GLFW_KEY_PAGE_UP: return 104;   case GLFW_KEY_PAGE_DOWN: return 109;
    case GLFW_KEY_DELETE: return 111;    case GLFW_KEY_INSERT: return 110;
    case GLFW_KEY_LEFT_SHIFT: return 42; case GLFW_KEY_RIGHT_SHIFT: return 54;
    case GLFW_KEY_LEFT_CONTROL: return 29;
    case GLFW_KEY_RIGHT_CONTROL: return 97;
    case GLFW_KEY_LEFT_ALT: return 56;   case GLFW_KEY_RIGHT_ALT: return 100;
    case GLFW_KEY_CAPS_LOCK: return 58;
    default:
      if (key >= GLFW_KEY_F1 && key <= GLFW_KEY_F10)
        return (unsigned short)(59 + (key - GLFW_KEY_F1)); /* F1..F10 */
      if (key == GLFW_KEY_F11) return 87;
      if (key == GLFW_KEY_F12) return 88;
      return 0;
  }
}

static void gfx_key_cb(GLFWwindow *window, int key, int scancode, int action, int mods) {
  (void)window; (void)scancode; (void)mods;
  if (action == GLFW_REPEAT) return; /* press/release only, like evdev discovery */
  unsigned short code = gfx_glfw_to_evdev(key);
  if (code) qos_evdev_inject(code, action != GLFW_RELEASE);
}

static void gfx_char_cb(GLFWwindow *window, unsigned int codepoint) {
  (void)window;
  gfx_event_push(1, codepoint, 0);
}

static void gfx_cursor_cb(GLFWwindow *window, double x, double y) {
  (void)window;
  if (gfx_have_cursor) gfx_event_push(2, (int64_t)(x - gfx_cursor_x), (int64_t)(gfx_cursor_y - y));
  gfx_cursor_x = x; gfx_cursor_y = y; gfx_have_cursor = 1;
}

static void gfx_mouse_cb(GLFWwindow *window, int button, int action, int mods) {
  (void)window; (void)mods;
  if (button >= 0 && button < 31) {
    if (action == GLFW_PRESS) gfx_mouse_buttons |= 1 << button;
    else if (action == GLFW_RELEASE) gfx_mouse_buttons &= ~(1 << button);
    gfx_event_push(3, gfx_mouse_buttons, 0);
  }
}
#endif

/* EGL contexts are thread-bound.  The graphics service actor's mailbox
 * is the intended serialization, but the multi-hart scheduler may
 * migrate an unpinned actor between hart threads -- so every entry
 * point rebinds if it finds itself on a new thread.  Callers are still
 * serialized (one graphics actor); this only moves the binding. */
static void gfx_bind_thread(void) {
  pthread_t self = pthread_self();
  if (G.haveTid && pthread_equal(G.boundTid, self)) return;
#ifdef FPR_DESKTOP_GL
  glfwMakeContextCurrent(G.window);
#else
  if (!eglMakeCurrent(G.dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, G.ctx))
    fpr_cpanic("gfx: eglMakeCurrent (thread rebind) failed");
#endif
  G.boundTid = self; G.haveTid = 1;
}

static const char *kVS =
#ifdef FPR_DESKTOP_GL
    "#version 330 core\n"
#else
    "#version 310 es\n"
    "precision highp float;\n"
#endif
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
#ifdef FPR_DESKTOP_GL
  "#version 330 core\n"
#else
    "#version 310 es\n"
    "precision highp float;\n"
#endif
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
    qos_hostlog("gfx: shader error: %s", log);
    fpr_cpanic("gfx: shader compile failed");
  }
  return s;
}

#ifndef FPR_DESKTOP_GL
int fpr_gpu_vec_axpb(uw *col, uw len, sw av, sw bv) {
  static GLuint program, buffer;
  static GLint uA, uB, uN;
  if (!G.inited || !G.haveTid || !pthread_equal(G.boundTid, pthread_self()) || len > UINT32_MAX)
    return 0;
  if (!program) {
    static const char *source =
        "#version 310 es\n"
        "layout(local_size_x=256) in;\n"
        "layout(std430, binding=0) buffer Data { int values[]; };\n"
        "uniform int uA; uniform int uB; uniform uint uN;\n"
        "void main(){ uint i=gl_GlobalInvocationID.x; if(i<uN) values[i]=uA*values[i]+uB; }\n";
    GLuint shader = gfx_shader(GL_COMPUTE_SHADER, source);
    program = glCreateProgram();
    glAttachShader(program, shader);
    glLinkProgram(program);
    glDeleteShader(shader);
    GLint ok = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &ok);
    if (!ok) { glDeleteProgram(program); program = 0; return 0; }
    uA = glGetUniformLocation(program, "uA");
    uB = glGetUniformLocation(program, "uB");
    uN = glGetUniformLocation(program, "uN");
    glGenBuffers(1, &buffer);
  }
  size_t bytes = (size_t)len * sizeof(int32_t);
  int32_t *values = malloc(bytes);
  if (!values) return 0;
  for (uw i = 0; i < len; i++) values[i] = (int32_t)(sw)col[i];
  glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer);
  glBufferData(GL_SHADER_STORAGE_BUFFER, (GLsizeiptr)bytes, values, GL_STREAM_COPY);
  glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, buffer);
  glUseProgram(program);
  glUniform1i(uA, (GLint)av);
  glUniform1i(uB, (GLint)bv);
  glUniform1ui(uN, (GLuint)len);
  glDispatchCompute((GLuint)((len + 255) / 256), 1, 1);
  glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT);
  void *mapped = glMapBufferRange(GL_SHADER_STORAGE_BUFFER, 0, (GLsizeiptr)bytes, GL_MAP_READ_BIT);
  if (!mapped) { free(values); return 0; }
  memcpy(values, mapped, bytes);
  glUnmapBuffer(GL_SHADER_STORAGE_BUFFER);
  for (uw i = 0; i < len; i++) col[i] = (uw)(sw)values[i];
  free(values);
  return 1;
}

/* mirrors hal/core/vec.c col_t: cap at 0, base (contiguous) at W */
typedef struct {
  uw cap;
  uw *base;
} gfx_gpu_col_t;

int fpr_gpu_vec_fold_pair_sum(void *col0v, void *col1v, uw len, sw seed, sw *out) {
  static GLuint program, input[2], output;
  if (len < 65536 || !G.inited || !G.haveTid ||
      !pthread_equal(G.boundTid, pthread_self()) || len > UINT32_MAX)
    return 0;
  if (!program) {
    static const char *source =
        "#version 310 es\n"
        "layout(local_size_x=256) in;\n"
        "layout(std430, binding=0) readonly buffer Left { int left[]; };\n"
        "layout(std430, binding=1) readonly buffer Right { int right[]; };\n"
        "layout(std430, binding=2) writeonly buffer Sums { int sums[]; };\n"
        "uniform uint uN;\n"
        "void main(){ uint i=gl_GlobalInvocationID.x; if(i<uN) sums[i]=left[i]+right[i]; }\n";
    GLuint shader = gfx_shader(GL_COMPUTE_SHADER, source);
    program = glCreateProgram();
    glAttachShader(program, shader);
    glLinkProgram(program);
    glDeleteShader(shader);
    GLint ok = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &ok);
    if (!ok) { glDeleteProgram(program); program = 0; return 0; }
    glGenBuffers(2, input);
    glGenBuffers(1, &output);
  }
  gfx_gpu_col_t *cols[2] = {(gfx_gpu_col_t *)col0v, (gfx_gpu_col_t *)col1v};
  size_t bytes = (size_t)len * sizeof(int32_t);
  int32_t *values[2] = {malloc(bytes), malloc(bytes)};
  if (!values[0] || !values[1]) { free(values[0]); free(values[1]); return 0; }
  for (int k = 0; k < 2; k++) {
    sw *span = (sw *)cols[k]->base;
    for (uw i = 0; i < len; i++) {
      if (span[i] < INT32_MIN || span[i] > INT32_MAX) {
        free(values[0]); free(values[1]); return 0;
      }
      values[k][i] = (int32_t)span[i];
    }
  }
  for (uw i = 0; i < len; i++) {
    int64_t pair = (int64_t)values[0][i] + values[1][i];
    if (pair < INT32_MIN || pair > INT32_MAX) {
      free(values[0]); free(values[1]); return 0;
    }
  }
  for (int k = 0; k < 2; k++) {
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, input[k]);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (GLsizeiptr)bytes, values[k], GL_STREAM_COPY);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, (GLuint)k, input[k]);
  }
  glBindBuffer(GL_SHADER_STORAGE_BUFFER, output);
  glBufferData(GL_SHADER_STORAGE_BUFFER, (GLsizeiptr)bytes, 0, GL_STREAM_READ);
  glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, output);
  glUseProgram(program);
  glUniform1ui(glGetUniformLocation(program, "uN"), (GLuint)len);
  glDispatchCompute((GLuint)((len + 255) / 256), 1, 1);
  glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT);
  void *mapped = glMapBufferRange(GL_SHADER_STORAGE_BUFFER, 0, (GLsizeiptr)bytes, GL_MAP_READ_BIT);
  if (!mapped) { free(values[0]); free(values[1]); return 0; }
  int32_t *lane_sums = mapped;
  uw acc = (uw)seed;
  for (uw i = 0; i < len; i++) acc += (uw)(sw)lane_sums[i];
  glUnmapBuffer(GL_SHADER_STORAGE_BUFFER);
  free(values[0]); free(values[1]);
  *out = (sw)acc;
  return 1;
}
#endif

/* egl_headless.cpp, C'd: surfaceless via the platform-display
 * extension, falling back to the default display.  PREFER_GBM and the
 * render-node path are the Pi-hardware upgrade, not ported yet. */
#ifndef FPR_DESKTOP_GL
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
#endif

void gfx_init(int w, int h) { /* raw export: gfx_raw.h */
  if (G.inited) return;
#ifdef FPR_DESKTOP_GL
  if (w <= 0) w = 1280;
  if (h <= 0) h = 720;
  if (!glfwInit()) fpr_cpanic("desktopgl: glfwInit failed");
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);
#endif
  G.window = glfwCreateWindow(w, h, "FPRISC Desktop GL", 0, 0);
  if (!G.window) fpr_cpanic("desktopgl: glfwCreateWindow failed");
  glfwMakeContextCurrent(G.window);
  glfwSetKeyCallback(G.window, gfx_key_cb);
  glfwSetCharCallback(G.window, gfx_char_cb);
  glfwSetCursorPosCallback(G.window, gfx_cursor_cb);
  glfwSetMouseButtonCallback(G.window, gfx_mouse_cb);
  glfwSwapInterval(1);
  G.boundTid = pthread_self(); G.haveTid = 1;
  qos_hostlog("[desktopgl] GLFW  OpenGL %s  %s",
              glGetString(GL_VERSION), glGetString(GL_RENDERER));
#else
  /* AUTO RESOLUTION: w or h of 0 means "the display's own mode" --
   * probe the scanout FIRST so the FBO is created at exactly the
   * monitor's resolution (1:1 blit, whole screen, no scaling).  With
   * no display (or FPR_DRM=0) the classic 640x480 stands, so headless
   * runs and replay checks are unchanged. */
  if (w <= 0 || h <= 0) {
    drm_scanout_init(&G.drm, 0, 0);
    if (G.drm.on) {
      w = (int)G.drm.mw;
      h = (int)G.drm.mh;
      G.drm.gw = w;
      G.drm.gh = h;
      G.drm.rd = (unsigned char *)malloc((size_t)w * h * 4);
      if (!G.drm.rd) G.drm.on = 0;
    } else {
      /* headless: FPR_GFX_SIZE=WxH forces a size (development aid for
       * exercising the wide-layout path without a display) */
      const char *e = getenv("FPR_GFX_SIZE");
      w = 640;
      h = 480;
      if (e && sscanf(e, "%dx%d", &w, &h) != 2) { w = 640; h = 480; }
      if (w < 64 || h < 64 || w > 8192 || h > 8192) { w = 640; h = 480; }
    }
  }
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
  G.boundTid = pthread_self(); G.haveTid = 1;
  qos_hostlog("[gfx] EGL %d.%d (%s)  %s / %s", maj, min, how,
              glGetString(GL_RENDERER), glGetString(GL_VERSION));
#endif

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
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
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
#ifndef FPR_DESKTOP_GL
  /* the monitor link (explicit-size path; the auto path probed above) */
  if (!G.drm.on && !G.drm.fd) drm_scanout_init(&G.drm, w, h);
#endif
}

void gfx_dims(int *w, int *h) { /* raw export: gfx_raw.h */
  *w = G.inited ? G.w : 0;
  *h = G.inited ? G.h : 0;
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
/* scene (4 fields) and entity (5 fields) arrived as flat tuples in the
 * PoC -- which the compiler now honestly rejects (Tup2/Tup3 only), so
 * they are app-declared CONSTRUCTORS (e.g. Scene s d l c / Ent m p y
 * s c in gfxdemo.fpr).  Constructor payloads lay out exactly like
 * tuple payloads (hdr + V fields at +8) and the walker's contract is
 * POSITIONAL, so any 4-/5-field heap value works: check only that it
 * is a heap object and read the fields. */
static V *nfields(V v, const char *what) {
  if (ISINT(v)) fpr_cpanic(what);
  return (V *)((char *)v + 8);
}
static v3 walk_v3(V v) {
  V *f = fields(v, 5, "gfx: expected (x, y, z) triple");
  return (v3){fmilli(f[0]), fmilli(f[1]), fmilli(f[2])};
}
/* entity = (mesh, pos, yawMilli, scale, color): stage one instance */
static void walk_entity(V v) {
  V *f = nfields(v, "gfx: expected entity (Ent mesh pos yaw scale color)");
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

/* ---- packed-dynamics vector reader ----------------------------------
 * The walker may run HOST-SIDE (qosp) against an APP-side vector, so
 * it reads the storage raw -- these mirrors restate vec.c's layout,
 * which is PINNED ("field offsets here are mirrored by Codegen.hs"):
 * one contiguous span per column (cap at 0, base at W). */
typedef struct { uw cap; uw *base; } gfx_col_t;
typedef struct {
  uint32_t tid, var;
  uw len, eltid, elvar, ncols, kinds, fkinds; /* fkinds: float columns */
  gfx_col_t *cols[1];
} gfx_vec_t;

static sw gfx_vec_int_at(V vec, uw i) {
  gfx_vec_t *x = (gfx_vec_t *)vec;
  if (ISINT(vec) || x->ncols < 1)
    fpr_cpanic("gfx: packed dynamics: not an Int vector");
  if (i >= x->len) fpr_cpanic("gfx: packed dynamics: index out of range");
  gfx_col_t *c = x->cols[0];
  /* unboxed Int columns (kinds bit 0) store RAW sw words; boxed store
   * tagged values -- match get_cell's convention exactly */
  uw raw = c->base[i];
  /* a float column here would be IEEE bits, not a number this packer
   * can use -- refuse rather than reinterpret (vec.c's fkinds) */
  if (x->fkinds & 1) fpr_cpanic("gfx: packed dynamics: float column, expected Int");
  if (x->kinds & 1) return (sw)raw;
  V v = (V)raw;
  if (!ISINT(v)) fpr_cpanic("gfx: packed dynamics: element not an Int");
  return UNTAG(v);
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
  gfx_bind_thread();
  V *f = nfields(scene, "gfx: scene must be (Scene statics dynamics lights camera)");
  int draws = 0; sw dynBytes = 0;

  /* statics: compiled to GPU buffers ONCE PER STATICS VALUE.  Value
   * identity is the invalidation: a shell that flips screens hands a
   * different (immutable, retained) statics list, and the compiled
   * buffers rebuild -- the gen_view discipline, on GPU buffers.  Same
   * pointer = same value here because the app RETAINS the list it
   * passes (a freed-and-recycled address cannot still be handed in). */
  if (G.staticCompiled && G.lastStatics != (uint64_t)f[0]) {
    for (int i = 0; i < G.nmeshes; i++) {
      mesh_t *m = &G.meshes[i];
      if (m->staticVBO) { glDeleteBuffers(1, &m->staticVBO); m->staticVBO = 0; }
      m->staticCount = 0;
    }
    G.staticCompiled = 0;
  }
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
    G.lastStatics = (uint64_t)f[0];
  }

  /* dynamics: staged from the value and re-uploaded, every frame.
   * Two shapes are accepted:
   *   a LIST of Ent values -- the general walk; or
   *   (vecHandle, n)       -- PACKED dynamics: n cube instances laid
   *                           out [x y z yaw sx sy sz r g b] * n in
   *                           one Int vector.  The app owns the vector
   *                           (typically double-buffered, mutated in
   *                           place with Vec.set) and no per-frame
   *                           list is ever allocated -- the gen_view
   *                           delta as a linear framebuffer handle. */
  stage_clear();
  {
    V dyn = f[1];
    int packed = 0;
    if (!ISINT(dyn) && TID(dyn) == 4) { /* a 2-tuple, not a list cell */
      V *df = (V *)((char *)dyn + 8);
      if (!ISINT(df[0]) && ISINT(df[1])) {
        uw n = (uw)UNTAG(df[1]);
        mesh_t *m = gfx_mesh("cube", 4);
        if (n > MAX_INST) fpr_cpanic("gfx: packed dynamics: too many instances");
        for (uw i = 0; i < n; i++) {
          uw b = i * 10;
          sw w[10];
          for (int k = 0; k < 10; k++)
            w[k] = gfx_vec_int_at(df[0], b + (uw)k);
          inst_t *it = &m->stage[m->nstage++];
          v3 pos = {(float)w[0] / 1000.0f, (float)w[1] / 1000.0f, (float)w[2] / 1000.0f};
          v3 sc = {(float)w[4] / 1000.0f, (float)w[5] / 1000.0f, (float)w[6] / 1000.0f};
          v3 col = {(float)w[7] / 1000.0f, (float)w[8] / 1000.0f, (float)w[9] / 1000.0f};
          m4 model = m4mul(m4translate(pos),
                           m4mul(m4rotY((float)w[3] / 1000.0f), m4scale(sc)));
          memcpy(it->model, model.m, sizeof it->model);
          it->color[0] = col.x; it->color[1] = col.y; it->color[2] = col.z;
        }
        packed = 1;
      }
    }
    if (!packed) walk_list(f[1], walk_entity);
  }
  for (int i = 0; i < G.nmeshes; i++) {
    mesh_t *m = &G.meshes[i];
    if (!m->nstage) continue;
    if (!m->dynVBO) glGenBuffers(1, &m->dynVBO);
    glBindBuffer(GL_ARRAY_BUFFER, m->dynVBO);
    glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)((size_t)m->nstage * sizeof(inst_t)), m->stage,
                 GL_DYNAMIC_DRAW);
    dynBytes += (sw)((size_t)m->nstage * sizeof(inst_t));
  }

  /* Camera: an INT is the 2D case -- the eye distance in milli, looking
   * at the origin with the standard fov.  That form exists because a
   * TUPLE here is a heap value nested in a per-frame message, and a
   * nested heap value gets no ARC entry of its own: its slab is either
   * pinned with the root or reclaimed while the walker still needs it.
   * An Int is immediate, so the frame path allocates nothing at all --
   * this is what a 20-minute "heap exhausted" fuse on a Pi cost.
   * The tuple form stays for the 3D scenes that move the camera. */
  m4 view, proj;
  if (ISINT(f[3])) {
    float z = (float)UNTAG(f[3]) / 1000.0f;
    view = m4lookAt((v3){0, 0, z}, (v3){0, 0, 0}, (v3){0, 1, 0});
    proj = m4persp(0.927f, (float)G.w / (float)G.h, 0.1f, 100.0f);
  } else {
    V *cam = fields(f[3], 5, "gfx: camera must be (eye, target, fovMilli)");
    view = m4lookAt(walk_v3(cam[0]), walk_v3(cam[1]), (v3){0, 1, 0});
    proj = m4persp(fmilli(cam[2]), (float)G.w / (float)G.h, 0.1f, 100.0f);
  }
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
#ifdef FPR_DESKTOP_GL
  {
    int fbw, fbh;
    glfwGetFramebufferSize(G.window, &fbw, &fbh);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, G.fbo);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBlitFramebuffer(0, 0, G.w, G.h, 0, 0, fbw, fbh, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    glfwSwapBuffers(G.window);
    glfwPollEvents();
  }
#else
  /* scanout present: FBO -> dumb buffer, every rendered frame */
  if (G.drm.on) {
    glReadPixels(0, 0, G.w, G.h, GL_RGBA, GL_UNSIGNED_BYTE, G.drm.rd);
    drm_scanout_present(&G.drm);
  }
#endif
  return 0;
}

int gfx_save_ppm(const char *path) {
  if (!G.inited) fpr_cpanic("glSavePpm: glInit first");
  gfx_bind_thread();
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
#ifdef FPR_DESKTOP_GL
int gfx_input_poll(int64_t *kind_out, int64_t *a_out, int64_t *c_out) {
  gfx_bind_thread();
  glfwPollEvents(); /* fires the callbacks: keys inject into evdev_raw */
  /* keys come back through the ONE decoder (modifier biasing, replay
   * precedence); the local queue keeps only mouse + char events */
  if (qos_evdev_poll(kind_out, a_out, c_out)) return 1;
  if (gfx_event_read == gfx_event_write) {
    *kind_out = 0; *a_out = 0; *c_out = 0;
    return 0;
  }
  gfx_event_t event = gfx_events[gfx_event_read];
  gfx_event_read = (gfx_event_read + 1) % GFX_EVENT_CAP;
  *kind_out = event.kind; *a_out = event.a; *c_out = event.c;
  return 1;
}
#else
#include <termios.h>
static struct termios gfx_tty_orig;
static int gfx_tty_restore_armed;
static void gfx_tty_restore(void) {
  if (gfx_tty_restore_armed) tcsetattr(0, TCSANOW, &gfx_tty_orig);
}
static int mice_fd = -2; /* -2 = untried, -1 = unavailable */
int gfx_input_poll(int64_t *kind_out, int64_t *a_out, int64_t *c_out) {
  /* evdev keyboard first (FPR_EVDEV -- a real event node, a simulated
   * device FIFO, or a pre-baked event file; evdev_raw.h): press AND
   * release arrive as distinct (4, keycode, value) events, which is
   * what a control-input consumer actually wants and stdin can't say */
  if (qos_evdev_poll(kind_out, a_out, c_out)) return 1;
  /* keyboard: one nonblocking stdin byte.  If stdin is a TERMINAL,
   * flip it raw once (no canonical buffering, no echo) so keys arrive
   * as they are pressed -- typing straight into the qosp/posix.bin
   * terminal then drives the shell live, no FIFO needed.  Restored at
   * exit. */
  static int raw_done = 0;
  if (!raw_done) {
    raw_done = 1;
    if (isatty(0)) {
      static struct termios orig;
      if (tcgetattr(0, &orig) == 0) {
        struct termios t = orig;
        t.c_lflag &= ~(tcflag_t)(ICANON | ECHO);
        t.c_cc[VMIN] = 0;
        t.c_cc[VTIME] = 0;
        tcsetattr(0, TCSANOW, &t);
        gfx_tty_orig = orig;
        gfx_tty_restore_armed = 1;
        atexit(gfx_tty_restore);
      }
    }
  }
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
    if (mice_fd == -2) {
      mice_fd = open("/dev/input/mice", O_RDONLY | O_NONBLOCK);
      if (mice_fd < 0)
        qos_hostlog("[input] no mouse at /dev/input/mice: %s", strerror(errno));
    }
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
#endif
