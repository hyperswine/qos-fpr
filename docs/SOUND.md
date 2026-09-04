# Sound: the procedural synth tier (qosp v7)

QOS Portable plays sound the way it draws: from integers the program
builds, through one table-dispatched call, with the host owning the
device.  No samples, no asset files.

    sndPlay (wave, f0, f1, ms, vol, delay)   -> voice slot, -1 = dropped

| field | meaning                                                   |
|-------|-----------------------------------------------------------|
| wave  | 0 sine, 1 square, 2 triangle, 3 noise, 4 saw              |
| f0 f1 | start and end frequency in Hz, swept linearly over `ms`   |
| ms    | duration                                                  |
| vol   | 0..1000, milli full-scale                                 |
| delay | ms before the tone starts (a riff = several calls, offset)|

Every voice carries a 2 ms attack and a linear release over its last
40%; 24 voices mix additively through a soft clip at 44.1 kHz mono.
The mixer is one background thread in the host (`hal/unix/snd_raw.c`),
started by the first call, so a program that never makes a sound never
touches audio.

## Backends

Picked by `qos/Makefile` at build time:

* **ALSA** on Linux when `libasound2-dev` is installed (`pkg-config
  alsa`); without it the build still succeeds and the host is silent.
* **AudioQueue** on macOS (AudioToolbox), pull-driven: the queue's
  callback runs the mixer.
* **The dump**, always: `FPR_SND_DUMP=<path>` writes the mix as a WAV
  while it plays, wall-clock paced when no device is open.  That is how
  a headless run under Xvfb proves what it sounded like
  (`qos/tests-host/terra2-check.sh` asserts the length, the number of
  distinct bursts and the share of silence).

The host logs which it got, once: `[snd] ALSA default device`,
`[snd] no ALSA device (silent)`, `[snd] dumping the mix to ...`.

## The chain

`fpr` types `sndPlay` (Infer.hs); the app-side shim
(`qos/appside/hal.c`, `h_sndPlay`) reads the 6-tuple and calls the
table's `snd_play`, the v7 slot appended to `qos_hal_t`
(`qos/appside/qos_abi.h`).  `QOS_ABI_VERSION` is 7: an app built after
this refuses a pre-v7 host at the gate, as every ABI addition does.

## Cues as data: mods/sfx.fpr

A riff is a list of tones; `Sfx.play riff` plays one, `Sfx.playAll`
a frame's worth.  The module carries the vocabulary a card game needs:
`cursor`, `pick`, `cancel`, `refuse`, `toggle` (the UI); `call`,
`attack`, `hit`, `kill`, `hqHit`, `shot`, `charge`, `ambush`,
`intercept`, `move` (the table); `yourTurn`, `enemyTurn`, `turnOver`
(the clock); `open`, `close`, `victory`, `defeat` (the frame).  Terra II
queues cues on its model (`cue m Sfx.hit`) and the tick plays them,
the same way its transcript is printed -- so a replayed game sounds
the same every run.
