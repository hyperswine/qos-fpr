/* snd_raw.c -- see snd_raw.h.  One mixer thread, started lazily by the
 * first play; the device (or the dump, or nothing) is opened there,
 * so an app that never makes a sound never touches audio. */
#include "snd_raw.h"
#include "hostlog.h"

#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef QOSP_SND_ALSA
#include <alsa/asoundlib.h>
#endif
#ifdef QOSP_SND_AQ
#include <AudioToolbox/AudioToolbox.h>
#endif

#define RATE 44100
#define CHUNK 512      /* frames per mix: 11.6 ms */
#define NVOICE 24

typedef struct {
  int active, wave;
  double f0, f1, vol, phase;
  int64_t total, pos, delay; /* frames */
  unsigned rng;
} voice_t;

static voice_t voices[NVOICE];
static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static int started, have_dev;
static FILE *dump;
static long dump_frames;
static int64_t played;

/* ---- the synth ------------------------------------------------------ */
static double sample(voice_t *v) {
  double t = v->total > 0 ? (double)v->pos / (double)v->total : 1.0;
  double f = v->f0 + (v->f1 - v->f0) * t;
  v->phase += f / RATE;
  if (v->phase >= 1.0) v->phase -= floor(v->phase);
  double s;
  switch (v->wave) {
    case 1: s = v->phase < 0.5 ? 1.0 : -1.0; break;
    case 2: s = 4.0 * fabs(v->phase - 0.5) - 1.0; break;
    case 3: v->rng = v->rng * 1664525u + 1013904223u; s = (double)(int32_t)v->rng / 2147483648.0; break;
    case 4: s = 2.0 * v->phase - 1.0; break;
    default: s = sin(v->phase * 6.283185307179586); break;
  }
  double env = 1.0;
  double att = 0.002 * RATE;
  if (v->pos < att) env = (double)v->pos / att;
  if (t > 0.6) env *= (1.0 - t) / 0.4;
  return s * env * v->vol;
}

static void mix(int16_t *out, int n) {
  pthread_mutex_lock(&lock);
  for (int i = 0; i < n; i++) {
    double acc = 0;
    for (int k = 0; k < NVOICE; k++) {
      voice_t *v = &voices[k];
      if (!v->active) continue;
      if (v->delay > 0) { v->delay--; continue; }
      acc += sample(v);
      if (++v->pos >= v->total) v->active = 0;
    }
    /* soft clip: tanh keeps a chord from cracking */
    double s = tanh(acc * 0.8) * 32000.0;
    out[i] = (int16_t)s;
  }
  pthread_mutex_unlock(&lock);
}

/* ---- the dump -------------------------------------------------------- */
static void wav_header(FILE *f, long frames) {
  uint32_t data = (uint32_t)(frames * 2), riff = 36 + data, fmtlen = 16, rate = RATE, brate = RATE * 2;
  uint16_t one = 1, ch = 1, align = 2, bits = 16;
  fseek(f, 0, SEEK_SET);
  fwrite("RIFF", 1, 4, f); fwrite(&riff, 4, 1, f); fwrite("WAVEfmt ", 1, 8, f);
  fwrite(&fmtlen, 4, 1, f); fwrite(&one, 2, 1, f); fwrite(&ch, 2, 1, f);
  fwrite(&rate, 4, 1, f); fwrite(&brate, 4, 1, f); fwrite(&align, 2, 1, f); fwrite(&bits, 2, 1, f);
  fwrite("data", 1, 4, f); fwrite(&data, 4, 1, f);
}
static void dump_close(void) {
  if (!dump) return;
  wav_header(dump, dump_frames);
  fclose(dump);
  dump = 0;
  qos_hostlog("[snd] dump closed: %ld frames (%.1f s), %lld tones", dump_frames,
              (double)dump_frames / RATE, (long long)played);
}

/* ---- backends --------------------------------------------------------- */
#ifdef QOSP_SND_ALSA
static snd_pcm_t *pcm;
static int alsa_open(void) {
  if (snd_pcm_open(&pcm, "default", SND_PCM_STREAM_PLAYBACK, 0) < 0) return 0;
  if (snd_pcm_set_params(pcm, SND_PCM_FORMAT_S16_LE, SND_PCM_ACCESS_RW_INTERLEAVED, 1, RATE, 1, 60000) < 0) {
    snd_pcm_close(pcm); pcm = 0; return 0;
  }
  return 1;
}
static void alsa_write(int16_t *buf, int n) {
  snd_pcm_sframes_t r = snd_pcm_writei(pcm, buf, (snd_pcm_uframes_t)n);
  if (r < 0) snd_pcm_recover(pcm, (int)r, 1);
}
#endif

#ifdef QOSP_SND_AQ
/* AudioQueue pulls: its callback mixes straight into the queue buffer;
 * the thread below then only serves the dump. */
static AudioQueueRef aq;
static void aq_cb(void *ud, AudioQueueRef q, AudioQueueBufferRef b) {
  (void)ud;
  int n = (int)(b->mAudioDataBytesCapacity / 2);
  mix((int16_t *)b->mAudioData, n);
  b->mAudioDataByteSize = (UInt32)(n * 2);
  if (dump) { fwrite(b->mAudioData, 2, (size_t)n, dump); dump_frames += n; }
  AudioQueueEnqueueBuffer(q, b, 0, 0);
}
static int aq_open(void) {
  AudioStreamBasicDescription d = {0};
  d.mSampleRate = RATE; d.mFormatID = kAudioFormatLinearPCM;
  d.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
  d.mBitsPerChannel = 16; d.mChannelsPerFrame = 1; d.mBytesPerFrame = 2;
  d.mFramesPerPacket = 1; d.mBytesPerPacket = 2;
  if (AudioQueueNewOutput(&d, aq_cb, 0, 0, 0, 0, &aq) != noErr) return 0;
  for (int i = 0; i < 3; i++) {
    AudioQueueBufferRef b;
    if (AudioQueueAllocateBuffer(aq, CHUNK * 2, &b) != noErr) return 0;
    aq_cb(0, aq, b);
  }
  return AudioQueueStart(aq, 0) == noErr;
}
#endif

/* ---- the mixer thread -------------------------------------------------- */
static void *mixer(void *ud) {
  (void)ud;
  int16_t buf[CHUNK];
  for (;;) {
#ifdef QOSP_SND_AQ
    if (have_dev) { /* the queue's callback does the work */
      struct timespec ts = {0, 50 * 1000000};
      nanosleep(&ts, 0);
      continue;
    }
#endif
    mix(buf, CHUNK);
    if (dump) { fwrite(buf, 2, CHUNK, dump); dump_frames += CHUNK; }
#ifdef QOSP_SND_ALSA
    if (have_dev) { alsa_write(buf, CHUNK); continue; }
#endif
    /* no device: pace the dump on the wall clock so delays and lengths
     * mean what they say in the file */
    struct timespec ts = {0, (long)(CHUNK * 1000000000L / RATE)};
    nanosleep(&ts, 0);
  }
  return 0;
}

static void start(void) {
  started = 1;
  const char *dp = getenv("FPR_SND_DUMP");
  if (dp && *dp) {
    dump = fopen(dp, "wb");
    if (dump) { wav_header(dump, 0); atexit(dump_close); qos_hostlog("[snd] dumping the mix to %s", dp); }
    else qos_hostlog("[snd] FPR_SND_DUMP %s: cannot open", dp);
  }
#ifdef QOSP_SND_ALSA
  have_dev = alsa_open();
  qos_hostlog("[snd] %s", have_dev ? "ALSA default device, 44.1 kHz mono" : "no ALSA device (silent)");
#elif defined(QOSP_SND_AQ)
  have_dev = aq_open();
  qos_hostlog("[snd] %s", have_dev ? "AudioQueue output, 44.1 kHz mono" : "AudioQueue unavailable (silent)");
#else
  qos_hostlog("[snd] no audio backend in this build (silent)");
#endif
  pthread_t th;
  pthread_create(&th, 0, mixer, 0);
  pthread_detach(th);
}

int qos_snd_play(int64_t wave, int64_t f0, int64_t f1, int64_t ms, int64_t vol, int64_t delay) {
  pthread_mutex_lock(&lock);
  if (!started) start();
  int slot = -1;
  for (int k = 0; k < NVOICE; k++)
    if (!voices[k].active) { slot = k; break; }
  if (slot >= 0) {
    voice_t *v = &voices[slot];
    v->active = 1;
    v->wave = (int)wave;
    v->f0 = (double)f0; v->f1 = (double)f1;
    v->vol = (vol < 0 ? 0 : vol > 1000 ? 1000 : (double)vol) / 1000.0;
    v->phase = 0;
    v->total = ms > 0 ? ms * RATE / 1000 : 1;
    v->pos = 0;
    v->delay = delay > 0 ? delay * RATE / 1000 : 0;
    v->rng = 0x9e3779b9u ^ (unsigned)played;
    played++;
  }
  pthread_mutex_unlock(&lock);
  return slot;
}
