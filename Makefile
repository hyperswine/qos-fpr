# TARGET=rv64 (default, QEMU virt) or TARGET=rv32 (QEMU virt-32).
# One toolchain: the riscv64-unknown-elf multilib gcc covers both.
TARGET ?= rv64
# number of harts compiled into the runtime AND given to QEMU (-smp).
# Harts beyond HARTS park in wfi; spawnOn h with h >= HARTS panics.
HARTS  ?= 2
CROSS  = riscv64-unknown-elf-

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

fprc: compiler/Main.hs compiler/FPRISC.hs compiler/Codegen.hs compiler/Modules.hs
	cd compiler && cabal build -v0
	cp "$$(cd compiler && cabal list-bin fprc)" $@

build/prog.s: fprc $(PROG) programs/prelude.fpr FORCE
	@mkdir -p build
	LC_ALL=C.UTF-8 ./fprc --target=$(FPRTGT) $(FPRCFLAGS) --prelude=programs/prelude.fpr $(PROG) build/prog.s

image.elf: build/prog.s runtime/crt0.S runtime/ctx.S runtime/runtime.c runtime/hal.c runtime/net.c runtime/blk.c runtime/actors.c runtime/vec.c runtime/mod.c runtime/link.ld
	$(CROSS)gcc $(CFLAGS) -T runtime/link.ld -Iruntime \
	  runtime/crt0.S runtime/ctx.S build/prog.s $$(cat build/prog.s.units) runtime/runtime.c runtime/hal.c runtime/net.c runtime/blk.c runtime/actors.c runtime/vec.c runtime/mod.c runtime/buddy.c -o $@


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
runtime/apps_data.c: $(patsubst %,build/qa0/%.qa,$(QAPPS)) tools/genapps.py
	python3 tools/genapps.py --entries -- $(patsubst %,build/qa0/%.qa,$(QAPPS))

# FORCE: TARGET/HARTS change the flags but not the deps, so always
# relink (fprc's per-unit cache keeps the compile side cheap)
system.elf: FORCE fprc programs/system.fpr programs/prelude.fpr runtime/apps.c runtime/apps_data.c runtime/buddy.c runtime/elfload.c runtime/process.c runtime/crt0.S runtime/ctx.S runtime/runtime.c runtime/hal.c runtime/net.c runtime/blk.c runtime/actors.c runtime/vec.c runtime/mod.c runtime/link.ld
	./fprc --target=$(FPRTGT) --prelude=programs/prelude.fpr programs/system.fpr build/system.s
	$(CROSS)gcc $(CFLAGS) -T runtime/link.ld -Iruntime \
	  runtime/crt0.S runtime/ctx.S build/system.s $$(cat build/system.s.units) runtime/runtime.c runtime/hal.c runtime/net.c runtime/blk.c runtime/actors.c runtime/vec.c runtime/mod.c runtime/apps.c runtime/apps_data.c runtime/buddy.c runtime/elfload.c runtime/process.c -o $@

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
	rm -f apps/*.qa runtime/apps_data.c

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
