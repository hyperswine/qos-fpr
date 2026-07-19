#!/usr/bin/env bash

# build-process-app.sh -- build a dynamically-loadable QOS process app
# and wrap it in a .qa with loadMode = "process" set.
# (docs/PROCESS-LOADING.md has the full design.)
#
# Usage: tools/build-process-app.sh <app.fpr> <manifest.toml> <out.qa> [rv32|rv64]
#
# Requires system.elf to already exist (`make system.elf` first) -- its
# _proc_arena_start is the slot address this app gets linked against.
# In practice that address is stable across changes to which OTHER apps
# are baked into system.elf's rodata (a 64 MiB heap sits between the
# code and the arena, absorbing ordinary code-size deltas), but if you
# see a "PT_LOAD segment falls outside the target slot" error after
# adding apps, rebuild system.elf, rerun this script, and re-genapps.

set -euo pipefail
APP_FPR="$1"; MANIFEST="$2"; OUT_QA="$3"; TARGET="${4:-rv64}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[ -f system.elf ] || { echo "system.elf not found -- run 'make system.elf' first" >&2; exit 1; }

if [ "$TARGET" = rv32 ]; then
  ARCHFLAGS="-march=rv32imac_zicsr -mabi=ilp32"; WORDSZ=4
else
  ARCHFLAGS="-march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany"; WORDSZ=8
fi

ARENA_HEX=$(riscv64-unknown-elf-nm system.elf | awk '/ _proc_arena_start$/{print $1}')
[ -n "$ARENA_HEX" ] || { echo "could not find _proc_arena_start in system.elf" >&2; exit 1; }
# the true first-allocation address is arena_base + sizeof(uw): buddy_alloc
# returns a pointer past its own bookkeeping header (docs/PROCESS-LOADING.md)
SLOT_BASE=$(printf '0x%x' $((0x$ARENA_HEX + WORDSZ)))
echo "target=$TARGET  _proc_arena_start=0x$ARENA_HEX  PROC_SLOT_BASE=$SLOT_BASE"

BASE=$(basename "$APP_FPR" .fpr)
./fprc --target="$TARGET" --prelude=programs/prelude.fpr "$APP_FPR" "build/${BASE}.s"

RT="runtime/proc_entry.c runtime/ctx.S runtime/runtime.c runtime/hal.c runtime/net.c runtime/blk.c runtime/actors.c runtime/buddy.c runtime/mod.c runtime/vec.c"
riscv64-unknown-elf-gcc $ARCHFLAGS -DFPR_NHARTS=1 -ffreestanding -nostdlib -nostartfiles -O2 \
  -Wl,--defsym=PROC_SLOT_BASE=$SLOT_BASE \
  -Wl,--defsym=_heap_start=_proc_image_end \
  -Wl,--defsym=_heap_end=_proc_image_end -Wl,--defsym=_proc_arena_end=0x84000000 \
  -T runtime/link-app.ld -Iruntime $RT "build/${BASE}.s" $(cat "build/${BASE}.s.units") -o "${BASE}.elf"

python3 tools/mkqa.py "$MANIFEST" "${BASE}.elf" -o "$OUT_QA"
echo "wrote $OUT_QA (loadMode=process; add it to QAPPS in the Makefile to ship it,"
echo "or point Apps.read at its id directly for a one-off test)"
