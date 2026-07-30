#!/bin/bash
# tools/raster-check.sh -- build + run the FP-RISC 3D pipeline PoC,
# verify determinism, extract the final frame.
set -u
cd "$(dirname "$0")/.."
# on aarch64
make posix-run POSIXARCH=a64 PROG=programs/raster.fpr > /dev/null || exit 1
# make -s posix.bin PROG=programs/raster.fpr >/dev/null || exit 1
./posix.bin < /dev/null > /tmp/raster-1.txt || exit 1
./posix.bin < /dev/null > /tmp/raster-2.txt || exit 1
if cmp -s /tmp/raster-1.txt /tmp/raster-2.txt; then
  echo "determinism: PASS (two runs byte-identical)"
else
  echo "determinism: FAIL"; exit 1
fi
grep -E "^frame|^raster" /tmp/raster-1.txt | tr -d '\r'
sed -n '/PPMBEGIN/,/PPMEND/p' /tmp/raster-1.txt | sed '1d;$d' | tr -d '\r' > frame8.ppm
echo "frame8.ppm: $(head -2 frame8.ppm | tail -1)  md5 $(md5sum frame8.ppm | cut -d' ' -f1)"
