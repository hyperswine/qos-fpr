#!/bin/bash
# tools/voxel-check.sh -- build + run the FP-RISC voxel world, check that
# it is deterministic, and extract every emitted frame as a PPM.
set -u
cd "$(dirname "$0")/.."
make -s posix.bin PROG=programs/voxel.fpr >/dev/null 2>&1 || { echo "build FAILED"; exit 1; }

./posix.bin </dev/null > /tmp/voxel-1.txt 2>&1 || { echo "run FAILED"; tail -2 /tmp/voxel-1.txt; exit 1; }
./posix.bin </dev/null > /tmp/voxel-2.txt 2>&1 || { echo "run 2 FAILED"; exit 1; }

if cmp -s /tmp/voxel-1.txt /tmp/voxel-2.txt; then
  echo "determinism: PASS (two runs byte-identical)"
else
  echo "determinism: FAIL"; exit 1
fi

tr -d '\r' < /tmp/voxel-1.txt > /tmp/voxel.txt
grep -E "^(voxel|world|frame)" /tmp/voxel.txt

mkdir -p frames && rm -f frames/voxel-*.ppm
for n in $(grep -oP '(?<=^PPMBEGIN )\d+' /tmp/voxel.txt); do
  sed -n "/^PPMBEGIN $n\$/,/^PPMEND\$/p" /tmp/voxel.txt | sed '1d;$d' > "frames/voxel-$n.ppm"
done
echo "frames:"
for f in frames/voxel-*.ppm; do
  echo "  $f  $(sed -n 2p "$f")  md5 $(md5sum "$f" | cut -d' ' -f1)"
done

# the mechanics the brief asked for, asserted from the log
for want in "destroy " "place 9 at" "grounded" "airborne"; do
  grep -q "$want" /tmp/voxel.txt && echo "log has: $want" || { echo "MISSING: $want"; exit 1; }
done
echo "voxel-check: OK"
