# TARGET=rv64 (default, QEMU virt) or TARGET=rv32 (QEMU virt-32).
# One toolchain: the riscv64-unknown-elf multilib gcc covers both.
TARGET ?= rv64
# number of harts compiled into the runtime AND given to QEMU (-smp).
# Harts beyond HARTS park in wfi; spawnOn h with h >= HARTS panics.
HARTS  ?= 2
CROSS  = riscv64-unknown-elf-

# ---- runtime layout ---------------------------------------------------
# runtime/core  portable runtime (allocator, actors, prims, vec, mod, qa)
# runtime/virt  QEMU-virt bare-metal machine layer (boot, ctx, MMIO HAL)
# runtime/qos   app-side runtime for .qa processes running ON QOS
# runtime/posix hosted-OS HAL (libc-backed; see runtime/posix/README.md)
RT_CORE_DIR = runtime/core
RT_VIRT_DIR = runtime/virt
RT_QOS_DIR  = runtime/qos
RT_POSIX_DIR = runtime/posix
RT_CORE = $(RT_CORE_DIR)/runtime.c $(RT_CORE_DIR)/actors.c $(RT_CORE_DIR)/bits.c $(RT_CORE_DIR)/vec.c $(RT_CORE_DIR)/sstr.c $(RT_CORE_DIR)/mod.c $(RT_CORE_DIR)/buddy.c
RT_VIRT = $(RT_VIRT_DIR)/crt0.S $(RT_VIRT_DIR)/ctx.S $(RT_VIRT_DIR)/ctx_fab.c $(RT_VIRT_DIR)/hal.c $(RT_VIRT_DIR)/net.c $(RT_VIRT_DIR)/blk.c
RT_INC  = -I$(RT_CORE_DIR) -I$(RT_VIRT_DIR)

ifeq ($(TARGET),rv32)
ARCHFLAGS = -march=rv32imac_zicsr -mabi=ilp32
QEMU      = qemu-system-riscv32
else
ARCHFLAGS = -march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany
QEMU      = qemu-system-riscv64
endif
FPRTGT ?= $(TARGET)

# RVV=1 layers the vector extension onto either target (QEMU: -cpu ...,v=true).
# No -march change needed: only fprc-emitted code uses V, and the .s
# carries `.option arch, +v` so gas accepts it; the C runtime never does.
ifeq ($(RVV),1)
QEMUCPU   = -cpu rv$(patsubst rv%,%,$(TARGET)),v=true,vlen=128
FPRCFLAGS += --rvv
else
QEMUCPU =
endif

CFLAGS = $(ARCHFLAGS) -DFPR_NHARTS=$(HARTS) \
         -ffreestanding -nostdlib -nostartfiles -O2 -Wall -Wextra \
         -fno-builtin -fno-stack-protector

# GNU coreutils' `timeout` isn't installed on macOS by default; use it (or
# Homebrew's `gtimeout`) when available, otherwise run without a time limit.
TIMEOUT := $(shell command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null)

# force MTTCG: without it QEMU may fall back to a single host thread and
# multi-hart programs run correct-but-not-parallel (psort shows ~1.0x)
ACCEL = -accel tcg,thread=multi

PROG ?= tests/demo.fpr
# DISK is referenced in prerequisite lists below, which make expands at
# READ time -- so it must be defined before any rule that names it.
DISK ?= disk.img

all: image.elf

# ---- posix HAL: hosted images (runtime/posix/README.md) ---------------
# The a64 fprc target lowers the rv64 emission (the shared low-level
# RISC IR) to AArch64 ELF assembly; the posix HAL rebinds the virt
# HAL's contract onto libc.  Static by default: a hosted FPRISC image
# is ONE self-contained binary, same philosophy as the .qa archive.
# POSIXARCH=x64 (default): native x86-64 Linux, real actors on
# pthread harts, sockets.  POSIXARCH=a64: cross aarch64 + qemu-user.
# POSIXHARTS: pthread "harts" actors are multiplexed onto (the P4
# plan's N-to-2 shape).  FPR_PORT picks the net actor's port.
# POSIXARCH=a64 on a Darwin host targets macOS natively: fprc emits
# Mach-O syntax (--target=a64mac: _sym, @PAGE/@PAGEOFF, Darwin TLV for
# the hart cell), cc/clang assembles and links (dynamic -- Mach-O has
# no -static; the philosophy concedes libSystem the way GFX concedes
# Mesa), and the binary runs natively on Apple Silicon.  Everything
# else (runtime C, actors, sockets, the uart/clint pseudo-bus) is the
# same portable code.  GFX=1 stays Linux-only (EGL/evdev), but the
# FPR_EVDEV simulated-keyboard tier is portable (see evdev_raw.c).
UNAME_S := $(shell uname -s)
POSIXARCH ?= x64
POSIXHARTS ?= 2
ifeq ($(POSIXARCH),a64)
POSIXCTX = $(RT_POSIX_DIR)/ctx_a64.S
ifeq ($(UNAME_S),Darwin)
POSIXCC  ?= cc
POSIXRUN ?=
POSIXFPRTGT = a64mac
else
POSIXCC  ?= aarch64-linux-gnu-gcc
POSIXRUN ?= qemu-aarch64
POSIXFPRTGT = a64
endif
else
POSIXCC  ?= gcc
POSIXRUN ?=
POSIXFPRTGT = x64
POSIXCTX = $(RT_POSIX_DIR)/ctx_x64.S
endif
RT_POSIX = $(RT_POSIX_DIR)/hal.c $(RT_POSIX_DIR)/main.c $(RT_POSIX_DIR)/stubs.c \
           $(RT_POSIX_DIR)/net.c $(RT_POSIX_DIR)/net_raw.c $(RT_POSIX_DIR)/heap.S $(POSIXCTX)
# GFX=1 adds the GPU tier (runtime/posix/gfx.c): EGL + OpenGL ES 3.1
# via Mesa, keyboard/mouse polling.  The GL stack cannot be statically
# linked, so a gfx image links dynamic -- the display driver is the one
# boundary the static philosophy concedes, the same way the kernel is.
ifeq ($(GFX),1)
RT_POSIX += $(RT_POSIX_DIR)/gfx.c $(RT_POSIX_DIR)/gfx_fpr.c $(RT_POSIX_DIR)/evdev_raw.c
POSIXLIBS = -lEGL -lGLESv2 -lm
# generated code uses absolute .quad relocations in .rodata (fine when
# static); a dynamic gfx image must therefore be non-PIE
POSIXSTATIC = -no-pie
else
POSIXLIBS =
POSIXSTATIC = -static
endif
ifeq ($(UNAME_S),Darwin)
POSIXSTATIC =
ifeq ($(GFX),1)
$(error GFX=1 is Linux-only (EGL/evdev); the FPR_EVDEV keyboard sim works without it)
endif
endif
RT_POSIX_CORE = $(RT_CORE_DIR)/runtime.c $(RT_CORE_DIR)/actors.c $(RT_CORE_DIR)/bits.c $(RT_CORE_DIR)/vec.c $(RT_CORE_DIR)/mod.c \
                $(RT_CORE_DIR)/sstr.c $(RT_CORE_DIR)/buddy.c

build/posix-prog.s: fprc $(PROG) programs/prelude.fpr FORCE
	@mkdir -p build
	LC_ALL=C.UTF-8 ./fprc --target=$(POSIXFPRTGT) --prelude=programs/prelude.fpr $(PROG) $@

posix.bin: build/posix-prog.s $(RT_POSIX) $(RT_POSIX_CORE)
	$(POSIXCC) $(POSIXSTATIC) -O2 -Wall -Wextra -DFPR_POSIX -DFPR_NHARTS=$(POSIXHARTS) -I$(RT_CORE_DIR) \
	  build/posix-prog.s $$(cat build/posix-prog.s.units) $(RT_POSIX_CORE) $(RT_POSIX) -lpthread $(POSIXLIBS) -o $@

posix-run: posix.bin
	$(POSIXRUN) ./posix.bin

# ---- QOS Portable: host + QOS (x64 or a64) apps -----------------------
# QOS Portable is NOT an OS: qosp is a hosting runtime that runs ONE
# FP-RISC program built for a QOS target (fprc --target=qx64|qa64) and
# packaged as a .qa, by satisfying its std assumptions through a HAL table
# (runtime/qosapp/qos_abi.h; docs/QOS-PORTABLE.md).  The app image is a
# fixed-slot freestanding ELF (no libc, no syscalls -- every effect goes
# through the table); the host is an ordinary hosted binary carrying the
# buddy arena, the QAR1 loader, the permission gate, and the table.
#
#   make qosp                                    # the host, once
#   make portable-qa PROG=...                    # app.qa (QOSARCH=x64| a64)
#   make portable-run PROG=...                   # both + run (auto-grant)
#   make portable-qa QOSARCH=a64 PROG=...        # a64 app (e.g. on Pi)
QOS_SLOT_BASE = 0x40000000
QOSAPP_DIR   = runtime/qosapp
PORTABLE_DIR = runtime/portable
# non-pie: the host text must stay away from the fixed arena mapping
QOSP_SRC = $(PORTABLE_DIR)/main.c $(PORTABLE_DIR)/qa.c $(PORTABLE_DIR)/haltab.c \
           $(PORTABLE_DIR)/store.c $(RT_POSIX_DIR)/net_raw.c \
           $(RT_CORE_DIR)/buddy.c $(RT_CORE_DIR)/elfload.c
# GFX=1 compiles the raw renderer core (runtime/posix/gfx.c -- shared
# with the co-compiled HAL via gfx_raw.h) into the HOST and fills the
# table's gfx entries; Mesa and its dynamic linking stay concentrated
# in the host image, the app stays freestanding either way.
ifeq ($(GFX),1)
QOSP_SRC += $(RT_POSIX_DIR)/gfx.c $(RT_POSIX_DIR)/evdev_raw.c
QOSP_GFXFLAGS = -DQOSP_GFX
QOSP_LIBS = -lEGL -lGLESv2 -lm
else
QOSP_GFXFLAGS =
QOSP_LIBS =
endif
# flag stamp: a GFX=1 and a plain qosp are different binaries -- switching
# the flag must relink even though no source changed
QOSP_STAMP = build/.qosp-gfx$(GFX)
$(QOSP_STAMP):
	@mkdir -p build && rm -f build/.qosp-gfx* && touch $@
qosp: $(QOSP_SRC) $(QOSAPP_DIR)/qos_abi.h $(PORTABLE_DIR)/qa.h $(QOSP_STAMP)
	gcc -no-pie -O2 -Wall -Wextra -DFPR_POSIX -DFPR_NHARTS=1 $(QOSP_GFXFLAGS) \
	  -I$(RT_CORE_DIR) -I$(QOSAPP_DIR) -I$(RT_POSIX_DIR) $(QOSP_SRC) $(QOSP_LIBS) -o $@

# QOSARCH selects the *app* image architecture for QOS Portable.
#   QOSARCH=x64 (default): fprc --target=qx64 + ctx_x64.S (SysV, RIP-deTLS)
#   QOSARCH=a64:             fprc --target=qa64 + ctx_a64.S (A64, adrp-deTLS)
# The *host* qosp is always built for the build machine (native gcc).
# Use QOSCC to override the compiler/assembler for the app image only
# (e.g. aarch64-linux-gnu-gcc on an x86 build host).
QOSARCH ?= x64
ifeq ($(QOSARCH),a64)
QOSFPRTGT = qa64
QOSCTX    = $(RT_POSIX_DIR)/ctx_a64.S
QOSLD     = $(QOSAPP_DIR)/link-qosapp-a64.ld
QOSCC    ?= aarch64-linux-gnu-gcc
else
QOSFPRTGT = qx64
QOSCTX    = $(RT_POSIX_DIR)/ctx_x64.S
QOSLD     = $(QOSAPP_DIR)/link-qosapp.ld
QOSCC    ?= gcc
endif

# the app image: generated QOS-target code + its OWN copy of the portable
# runtime (the process model's shape, docs/PROCESS-LOADING.md) + the
# table-dispatching HAL, linked freestanding at the published constant
# slot (no system.elf symbol extraction -- see link-qosapp.ld).
QOSAPP_RT = $(QOSAPP_DIR)/entry.c $(QOSAPP_DIR)/hal.c $(QOSAPP_DIR)/support.c \
            $(RT_CORE_DIR)/runtime.c $(RT_CORE_DIR)/actors.c $(RT_CORE_DIR)/bits.c \
            $(RT_CORE_DIR)/vec.c $(RT_CORE_DIR)/sstr.c $(RT_CORE_DIR)/mod.c \
            $(RT_CORE_DIR)/buddy.c $(QOSCTX)
build/qosapp-prog.s: fprc $(PROG) programs/prelude.fpr FORCE
	@mkdir -p build
	LC_ALL=C.UTF-8 ./fprc --target=$(QOSFPRTGT) --prelude=programs/prelude.fpr $(PROG) $@

build/qosapp.elf: build/qosapp-prog.s $(QOSAPP_RT) $(QOSLD)
	$(QOSCC) -O2 -Wall -Wextra -ffreestanding -nostdlib -nostartfiles -static \
	  -fno-stack-protector -fno-asynchronous-unwind-tables -fno-pic \
	  -mno-outline-atomics \
	  -DFPR_POSIX -DFPR_QOSAPP -DFPR_NHARTS=1 \
	  -I$(RT_CORE_DIR) -I$(QOSAPP_DIR) \
	  -T $(QOSLD) -Wl,--defsym=QOS_SLOT_BASE=$(QOS_SLOT_BASE) \
	  -Wl,--defsym=_heap_start=_proc_image_end -Wl,--defsym=_heap_end=_proc_image_end \
	  -Wl,--defsym=_proc_arena_end=0x50000000 \
	  -Wl,--build-id=none -Wl,-z,noexecstack \
	  build/qosapp-prog.s $$(cat build/qosapp-prog.s.units) $(QOSAPP_RT) -o $@

# manifest: $(QAMANIFEST) if given, else a generated loadMode=process one
portable-qa: build/qosapp.elf tools/mkqa.py
	@if [ -n "$(QAMANIFEST)" ]; then MF=$(QAMANIFEST); else \
	  MF=build/qosapp-gen.toml; \
	  ID=$$(basename $(PROG) .fpr); \
	  printf 'name = "%s"\nid = "%s"\nentry = "n/a"\nversion = "1"\nloadMode = "process"\n' $$ID $$ID > $$MF; \
	fi; \
	python3 tools/mkqa.py $$MF build/qosapp.elf -o app.qa

portable-run: qosp portable-qa
	./qosp --yes app.qa

fprc: compiler/Main.hs compiler/FPRISC.hs compiler/Codegen.hs compiler/Modules.hs compiler/A64.hs compiler/X64.hs compiler/Infer.hs compiler/Struct.hs compiler/Precond.hs
	cd compiler && cabal build -v0
	cp "$$(cd compiler && cabal list-bin fprc)" $@

build/prog.s: fprc $(PROG) programs/prelude.fpr FORCE
	@mkdir -p build
	LC_ALL=C.UTF-8 ./fprc --target=$(FPRTGT) $(FPRCFLAGS) --prelude=programs/prelude.fpr $(PROG) build/prog.s

image.elf: build/prog.s $(RT_VIRT) $(RT_CORE) $(RT_VIRT_DIR)/link.ld
	$(CROSS)gcc $(CFLAGS) -T $(RT_VIRT_DIR)/link.ld $(RT_INC) \
	  $(RT_VIRT) build/prog.s $$(cat build/prog.s.units) $(RT_CORE) -o $@


# ---- System.qa: the .qa app platform (docs/QA-FORMAT.md) --------------------
# QAPPS lists the app manifests; ENTRIES their FPRISC entry symbols. mkqa
# bundles each manifest (+ placeholder ELF) into a .qa; genapps bakes the
# .qa blobs and the entry->PAP table into runtime/apps_data.c.
# TUIAppLauncher/TUINotes/TUIClock are co-compiled, name-dispatched apps
# (share System.qa's own caps-gated services). HelloProc is a REAL
# dynamically-loaded process (docs/PROCESS-LOADING.md) -- its .qa is
# built separately by tools/build-process-app.sh, which needs an
# already-linked system.elf to extract the process-arena slot address
# from, so it is NOT a pattern-rule target here (that would be
# circular: system.elf's own rodata embeds HelloProc.qa). Run
# `make system.elf && tools/build-process-app.sh apps/hello_proc.fpr
# apps/HelloProc.toml apps/HelloProc.qa && make system.elf` (the
# second pass picks up the freshly built HelloProc.qa) if you need to
# regenerate it; the checked-in apps/HelloProc.qa already reflects the
# current system.elf's slot address and rebuilds do not normally need
# to touch it (see the note in build-process-app.sh about why the
# address is stable across ordinary code-size changes).
QAPPS   = TUIAppLauncher TUINotes TUIClock HelloProc

# the rodata fallback registry needs only MANIFESTS: placeholder .qa's
# in build/qa0/ feed genapps, breaking the system.elf <-> real-.qa
# cycle (real ELF .qa's in apps/ are the DISK artifacts, built after).
# TUIAppLauncher (the builtin shell) still gets its real .qa here.
apps/TUIAppLauncher.qa: apps/TUIAppLauncher.toml tools/mkqa.py
	python3 tools/mkqa.py $< -o $@
build/qa0/%.qa: apps/%.toml tools/mkqa.py
	@mkdir -p build/qa0
	python3 tools/mkqa.py $< -o $@
$(RT_CORE_DIR)/apps_data.c: $(patsubst %,build/qa0/%.qa,$(QAPPS)) tools/genapps.py
	python3 tools/genapps.py --entries -- $(patsubst %,build/qa0/%.qa,$(QAPPS))

# FORCE: TARGET/HARTS change the flags but not the deps, so always
# relink (fprc's per-unit cache keeps the compile side cheap)
system.elf: FORCE fprc programs/system.fpr programs/prelude.fpr $(RT_CORE_DIR)/apps.c $(RT_CORE_DIR)/apps_data.c $(RT_CORE_DIR)/elfload.c $(RT_CORE_DIR)/process.c $(RT_VIRT) $(RT_CORE) $(RT_VIRT_DIR)/link.ld
	./fprc --target=$(FPRTGT) --prelude=programs/prelude.fpr programs/system.fpr build/system.s
	$(CROSS)gcc $(CFLAGS) -T $(RT_VIRT_DIR)/link.ld $(RT_INC) \
	  $(RT_VIRT) build/system.s $$(cat build/system.s.units) $(RT_CORE) $(RT_CORE_DIR)/apps.c $(RT_CORE_DIR)/apps_data.c $(RT_CORE_DIR)/elfload.c $(RT_CORE_DIR)/process.c -o $@

# the DEFAULT setup has a disk: the append-only log carries /apps
# overrides, app kv streams, and general files (docs/STORAGE.md)
# the three process apps are REAL ELFs linked against the pinned slot:
# built after system.elf (two-pass, per docs/PROCESS-LOADING.md)
# real file rules (not PHONY): a .qa rebuilds only when its sources
# change, so $(DISK) -- which depends on the .qa files -- reseeds only
# then, and kv persistence survives plain reruns.  system.elf is an
# ORDER-ONLY prerequisite: it must exist (the pinned slot symbol), but
# its always-relink FORCE must not make the .qa look stale.
BPTGT = $(if $(filter rv64,$(TARGET)),rv64,rv32)
PROCDEPS = programs/mods/procapp.fpr programs/mods/tui.fpr programs/prelude.fpr tools/build-process-app.sh build/qatarget fprc
# a stamp that changes ONLY when TARGET changes: .qa ELFs are
# target-specific, so a target switch must rebuild them (and reseed
# the disk), while plain reruns must NOT.
build/qatarget: FORCE
	@mkdir -p build; [ "$$(cat build/qatarget 2>/dev/null)" = "$(TARGET)" ] || echo $(TARGET) > build/qatarget
apps/HelloProc.qa: apps/hello_proc.fpr apps/HelloProc.toml $(PROCDEPS)
	bash tools/build-process-app.sh apps/hello_proc.fpr apps/HelloProc.toml $@ $(BPTGT)
apps/TUIClock.qa: apps/tuiclock.fpr apps/TUIClock.toml $(PROCDEPS)
	bash tools/build-process-app.sh apps/tuiclock.fpr apps/TUIClock.toml $@ $(BPTGT)
apps/TUINotes.qa: apps/tuinotes.fpr apps/TUINotes.toml $(PROCDEPS)
	bash tools/build-process-app.sh apps/tuinotes.fpr apps/TUINotes.toml $@ $(BPTGT)
procapps: apps/HelloProc.qa apps/TUIClock.qa apps/TUINotes.qa
.PHONY: procapps

run-system: system.elf procapps $(DISK)
	$(QEMU) $(ACCEL) -machine virt $(QEMUCPU) -smp $(HARTS) -m 256M \
	  -nographic -bios none -kernel system.elf $(BLKFLAGS)

run: image.elf
	$(TIMEOUT) 20 $(QEMU) $(ACCEL) -machine virt $(QEMUCPU) -smp $(HARTS) -m 256M \
	  -nographic -bios none -kernel image.elf

test:
	@tests/run-tests.sh

asm: build/prog.s
	@sed -n '1,80p' build/prog.s

clean:
	rm -rf build fprc image.elf system.elf sys*.elf compiler/dist-newstyle
	rm -f apps/*.qa $(RT_CORE_DIR)/apps_data.c

FORCE:

.PHONY: all run run-net run-system test asm clean FORCE

# user-mode (slirp) networking: host localhost:8000 -> guest 10.0.2.15:80
NETFLAGS = -netdev user,id=n0,hostfwd=tcp:127.0.0.1:8000-:80 \
           -device virtio-net-device,netdev=n0

run-net: image.elf
	$(TIMEOUT) 60 $(QEMU) $(ACCEL) -machine virt $(QEMUCPU) -smp $(HARTS) -m 256M -nographic -bios none -kernel image.elf $(NETFLAGS)

# ---- disk: virtio-blk backed by a flat raw image ---------------------------
# 8 MiB = 2048 pages. `make wipe-disk` to reformat (the diskfs program
# formats an unrecognized superblock on boot, so wiping is enough).
BLKFLAGS = -drive file=$(DISK),if=none,format=raw,id=hd0 -device virtio-blk-device,drive=hd0

# the initial disk is SEEDED with the built .qa apps (each its own QLOG
# record + an apps/index): System.qa loads apps from disk on demand;
# rodata is only the diskless fallback.  Rebuilt when any .qa changes
# (a fresh install; kv streams start clean -- dev semantics).
QA_APPS = apps/TUIAppLauncher.qa apps/TUINotes.qa apps/TUIClock.qa apps/HelloProc.qa
$(DISK): $(QA_APPS) tools/mkdisk.py
	python3 tools/mkdisk.py $(DISK) 8 $(QA_APPS)

wipe-disk:
	rm -f disk.img

run-disk: image.elf $(DISK)
	$(TIMEOUT) 60 $(QEMU) $(ACCEL) -machine virt $(QEMUCPU) -smp $(HARTS) -m 256M \
	  -nographic -bios none -kernel image.elf $(BLKFLAGS)

.PHONY: run-disk wipe-disk
