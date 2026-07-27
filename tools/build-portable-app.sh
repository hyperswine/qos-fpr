#!/usr/bin/env bash

# build-portable-app.sh -- build a QOS-x86_64 app and wrap it in a .qa
# for QOS Portable (docs/QOS-PORTABLE.md).  build-process-app.sh's
# hosted sibling, with the one structural difference that defines the
# portable model: the slot address is a PUBLISHED CONSTANT
# (qos_abi.h's QOS_SLOT_BASE), not an address extracted from a
# system.elf symbol table -- so no prior build is required, and an
# app.qa built today loads under any qosp built tomorrow.
#
# Usage: tools/build-portable-app.sh <app.fpr> [manifest.toml] [out.qa]
#
# Without a manifest, a minimal loadMode="process" one is generated
# from the program's basename (no permissions -- fine for programs
# that enforce nothing via Sys.caps).

set -euo pipefail
APP_FPR="$1"; MANIFEST="${2:-}"; OUT_QA="${3:-app.qa}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

QOS_SLOT_BASE=0x40000000   # MUST match qos_abi.h + the Makefile
ARENA_END=0x50000000       # arena base + 256M, for the heap-span defsyms

BASE=$(basename "$APP_FPR" .fpr)
mkdir -p build
./fprc --target=qx64 --prelude=programs/prelude.fpr "$APP_FPR" "build/${BASE}-q.s"

RT="runtime/qosapp/entry.c runtime/qosapp/hal.c runtime/qosapp/support.c \
    runtime/core/runtime.c runtime/core/actors.c runtime/core/bits.c \
    runtime/core/vec.c runtime/core/sstr.c runtime/core/mod.c \
    runtime/core/buddy.c runtime/posix/ctx_x64.S"

gcc -O2 -Wall -Wextra -ffreestanding -nostdlib -nostartfiles -static \
  -fno-stack-protector -fno-asynchronous-unwind-tables -fno-pic \
  -DFPR_POSIX -DFPR_QOSAPP -DFPR_NHARTS=1 \
  -Iruntime/core -Iruntime/qosapp \
  -T runtime/qosapp/link-qosapp.ld -Wl,--defsym=QOS_SLOT_BASE=$QOS_SLOT_BASE \
  -Wl,--defsym=_heap_start=_proc_image_end -Wl,--defsym=_heap_end=_proc_image_end \
  -Wl,--defsym=_proc_arena_end=$ARENA_END \
  -Wl,--build-id=none -Wl,-z,noexecstack \
  "build/${BASE}-q.s" $(cat "build/${BASE}-q.s.units") $RT -o "build/${BASE}-q.elf"

if [ -z "$MANIFEST" ]; then
  MANIFEST="build/${BASE}-q.toml"
  printf 'name = "%s"\nid = "%s"\nentry = "n/a"\nversion = "1"\nloadMode = "process"\n' \
    "$BASE" "$BASE" > "$MANIFEST"
fi

python3 tools/mkqa.py "$MANIFEST" "build/${BASE}-q.elf" -o "$OUT_QA"
echo "run it:  ./qosp $OUT_QA        (make qosp first if needed)"
