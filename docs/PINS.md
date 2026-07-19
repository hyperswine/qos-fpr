# GPIO pins: the raw Pin tier, /pins URLs, and signal-level testing

The C HAL carries a raw 32-pin bank: `Pin.mode n dir` / `Pin.write n v`
/ `Pin.read n`, runtime-reconfigurable -- what pad does what is a
RUNTIME decision.  THIS backend is the QEMU sim (out latches;
`Pin.wire a b`, sim-only, jumpers an out-pin to an in-pin -- how
tests/pins.fpr emulates a matrix keypress with zero hardware); a
silicon backend replaces the bodies with the target's GPIO MMIO.

System.qa serves the bank as the `/pins` capability (svcPinMode /
svcPinWrite / svcPinRead, mode "rw"), and `/services/keypad` is the
proof that "typical FPRISC wraps pins into services": svcKeypadScan
runs mods/matrixkpd.fpr -- a 4x4 scan whose pin FUNCTIONS and pin MAP
are both values -- over svcPin*, with the map read from the
`sys/pinmap.keypad` storage url (default "4 5 6 7 8 9 10 11").
Remapping a differently-soldered board is ONE storage write, no
rebuild.  An SPI OLED service is the same pattern over the bit-banged
SPI bus (mods/bbspi.fpr).

(The slot-clobber bug this section once tracked is FIXED: slotsNeeded
now counts cross-unit known-call arg spills; tests/slotclobber.fpr is
the permanent regression.  Unwire by out-of-range src remains the
convention -- it reads well.)

## Signal-level testing without silicon

The sim carries a LOGIC ANALYZER: every Pin.write records (pin, value)
in a trace ring (Pin.tclear / Pin.tlen / Pin.tget).  mods/bbspi.fpr
bit-bangs SPI mode 0 over any pin surface (the bus is one value:
(pinW, pinR, sck, mosi, miso)); mods/oled.fpr is the SSD1306-shaped
driver over it (DC/CS framing, the canonical AE 8D 14 AF wake).
tests/bbspi.fpr proves the whole path the way a slave would: it
DECODES THE CAPTURED WAVEFORM -- sampling mosi at each sck rising
edge -- and requires the reconstruction to match the bytes sent, plus
full-duplex echo through a mosi->miso jumper and the OLED init
verified byte-for-byte off the wire.  "Are the signals generally
working" is a suite row on every target.

## Frozen: silicon pin routing

The ESP32 pin-routing work (IOMUX/GPIO-matrix routing, the Rust
algebraic HAL with pin-explicit Uart/Spi/Kpd opens, and the C3
register appendix) was frozen at step 19 -- see the step19 archive.
Future silicon targets (FPGA) will grow their own Pin.* backend
beneath this same portable surface.
