/* snd_raw.h -- the raw SOUND tier (gfx_raw.h's audio sibling): a
 * procedural synthesizer and mixer, table-dispatched to the app as
 * ONE call.  No assets, no files: every sound is a tone descriptor
 * the app builds from integers, the same way every glyph on screen is
 * cubes from a bitmap.
 *
 *   qos_snd_play(wave, f0, f1, ms, vol, delay)  -> voice slot, -1 = dropped
 *
 *   wave   0 sine  1 square  2 triangle  3 noise  4 saw
 *   f0/f1  start / end frequency, Hz (a linear sweep over the tone)
 *   ms     duration          vol  0..1000 (milli full-scale)
 *   delay  ms before the tone starts (a riff = several calls, offset)
 *
 * Voices carry a 2 ms attack and a linear release over the last 40%
 * of the tone; 24 of them mix additively with a soft clip, 44.1 kHz
 * mono s16, on a background thread that owns the device.  Backends,
 * picked at build time by the qos Makefile: ALSA (Linux, -lasound),
 * AudioQueue (macOS, AudioToolbox), and always the WAV DUMP --
 * FPR_SND_DUMP=<path> writes the mix as it plays (wall-clock paced
 * when no device is open), which is how a headless run proves what it
 * sounded like.  No device and no dump = silent, logged once. */
#ifndef QOS_SND_RAW_H
#define QOS_SND_RAW_H

#include <stdint.h>

int qos_snd_play(int64_t wave, int64_t f0, int64_t f1, int64_t ms, int64_t vol, int64_t delay);

/* the music channel: one MP3, decoded as it plays (minimp3.h, public
 * domain) and looped, under the voices at vol/1000; an empty path or vol
 * 0 stops it.  1 playing, 0 off, -1 not found / not decodable.  Paths
 * resolve as given, under FPR_ASSETS, then beside the .qa. */
int qos_snd_music(const char *path, int64_t vol);
void qos_snd_set_assets(const char *qa_path);

#endif
