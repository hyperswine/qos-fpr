/* evdev_raw.h -- the evdev keyboard tier (net_raw.h's input sibling).
 *
 * Reads Linux `struct input_event` records -- the evdev wire format,
 * what libevdev parses -- from the fd named by FPR_EVDEV.  Raw evdev
 * rather than libevdev-the-library, per the input-stack decision: no
 * layout/character translation is wanted (control input only), and no
 * dynamic dependency lands in static images.  The point of speaking
 * the real wire format is that ONE reader serves every source:
 *
 *   FPR_EVDEV=/dev/input/event3   a real keyboard (Pi console target)
 *   FPR_EVDEV=/tmp/kbd.fifo       a live simulated device (tools/kbdsim.py)
 *   FPR_EVDEV=script.evd          a pre-baked deterministic event file
 *
 * EV_KEY events surface as input kind 4: (4, keycode, value) with
 * value 0 = release, 1 = press, 2 = autorepeat -- additive next to the
 * existing kinds (1 stdin byte, 2 mouse move, 3 mouse buttons), so
 * nothing downstream changes.  EV_SYN/EV_MSC are skipped here; an app
 * that wants SYN-framed batching can get it later as another kind. */
#ifndef QOS_EVDEV_RAW_H
#define QOS_EVDEV_RAW_H

#include <stdint.h>

/* 1 = event delivered (kind=4, a=keycode, c=value); 0 = none pending */
int qos_evdev_poll(int64_t *kind, int64_t *a, int64_t *c);

#endif
