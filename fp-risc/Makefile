# fp-risc/Makefile — ONE language, four profiles (compiler/Target.hs).
#
#   make fprc                                # the compiler
#   make stdcheck FILE=std/checkdemo.fpr     # the std proof pass
#   make bare-metal PROG=tests/demo.fpr      # AOT + hal/virt -> image.elf
#   make bare-metal-run PROG=...             # ... booted under QEMU virt
#   make qos-app PROG=tests/hello.fpr        # AOT qx64 + qos/appside -> app.qa
#                                            # (run it: make -C ../qos portable-run)
#   make sol                                 # the HostedBytecode profile
#
# The C underneath is ../hal — a HAL, not an implementation: hal/core is
# the portable runtime contract, hal/virt the bare-metal machine layer,
# hal/unix the raw device layer.  Nothing in this directory contains
# machine-specific C.  The old co-compiled posix target is GONE:
# hosting on Unix is ../qos/portable's job.

HAL      = ../hal
QOS      = ../qos
HARTS   ?= 2
CROSS    = riscv64-unknown-elf-
PROG    ?= tests/demo.fpr
FILE    ?= std/checkdemo.fpr
QA_OUT  ?= app.qa
# where per-program intermediates go (qos.py points this at the
# project's .qos/build so an installed tree is never written to); the
# host stamp and the compiler's own build stay under build/
BUILD   ?= build
IMAGE   ?= image.elf

RT_CORE = $(HAL)/core/runtime.c $(HAL)/core/actors.c $(HAL)/core/bits.c \
          $(HAL)/core/vec.c $(HAL)/core/sstr.c $(HAL)/core/mod.c $(HAL)/core/buddy.c
RT_VIRT = $(HAL)/virt/crt0.S $(HAL)/virt/ctx.S $(HAL)/virt/ctx_fab.c \
          $(HAL)/virt/hal.c $(HAL)/virt/plic.c $(HAL)/virt/net.c $(HAL)/virt/blk.c $(HAL)/virt/memshim.c

ARCHFLAGS = -march=rv64imafdc_zicsr -mabi=lp64 -mcmodel=medany
# hosted (qosp) apps grant memory in QOSSLAB-byte slabs: the 256 KiB
# machine default is a per-actor and per-message floor that caps a
# thousand-session server at a few dozen; 32 KiB keeps the recycler's
# exact-fit reuse and makes a session cost what its state weighs
QOSSLAB ?= 32768
# the per-actor stack for hosted apps; an app whose loops are accumulator
# shaped (fprlive) builds with QOSSTACK=65536 for four times the sessions
QOSSTACK ?= 262144
QOSCFLAGS_EXTRA ?=
CFLAGS = $(ARCHFLAGS) -DFPR_NHARTS=$(HARTS) \
         -ffreestanding -nostdlib -nostartfiles -O2 -Wall -Wextra \
         -fno-builtin -fno-stack-protector
QEMU  = qemu-system-riscv64
ACCEL = -accel tcg,thread=multi

# ---- RVV: the vector tier, now shippable -------------------------------
# `make bare-metal-run PROG=... RVV=1` compiles Vec loops with --rvv
# (strip-mined vsetvli/vle/vadd), assembles with the V extension, and
# boots QEMU with a V-capable cpu.  The enable shim is emitted link-once
# (COMDAT), so multi-unit programs link cleanly.  Without RVV=1 nothing
# changes: no unit touches mstatus.VS and the images run on V-less cores.
ifeq ($(RVV),1)
FPRC_FLAGS += --rvv
ARCHFLAGS = -march=rv64imafdcv_zicsr -mabi=lp64 -mcmodel=medany
ACCEL += -cpu rv64,v=true
endif
TIMEOUT := $(shell command -v timeout 2>/dev/null || echo "")

all: fpr

# ---- THE tool: one binary, profiles as subcommands ---------------------
# fpr compile|sol|stdcheck|commit|versions.  The sol pipeline is linked
# in as Sol.* modules — sol is a profile of this binary, not a second
# executable.  `fprc` stays as a symlink for fprc-compatible callers
# (the qos/ Makefile): bare flags fall through to `fpr compile`.
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
FPR_HOST_STAMP := build/.fpr-host-$(UNAME_S)-$(UNAME_M)
ifeq ($(UNAME_S),Darwin)
GLLIBS :=
else
GLLIBS := -lEGL -lGL
endif
$(FPR_HOST_STAMP):
	@mkdir -p $(BUILD)
	@rm -f build/.fpr-host-*
	@touch $@

# an INSTALLED tree (../.installed, written by `qos.py install`) ships
# the binary: the rule is then a presence check, so `make qos-app` never
# reaches for ghc through the fprc prerequisite
ifneq ($(wildcard ../.installed),)
fpr:
	@test -x fpr || { echo "installed tree without fpr: reinstall (qos.py install / brew reinstall qos-fpr)"; exit 1; }
else
fpr: $(FPR_HOST_STAMP) compiler/*.hs compiler/Sol/*.hs compiler/cbits/fsx.c compiler/cbits/vecgpu.c compiler/cbits/handjit.c
	@if command -v cabal >/dev/null 2>&1; then \
	  cabal build exe:fpr && cp "$$(cabal list-bin fpr)" fpr; \
	else \
	  gcc -c compiler/cbits/fsx.c -o compiler/cbits/fsx.o && \
	  gcc -c compiler/cbits/vecgpu.c -o compiler/cbits/vecgpu.o && \
	  gcc -c compiler/cbits/handjit.c -o compiler/cbits/handjit.o && \
	  cd compiler && ghc -O0 -i. -o ../fpr Main.hs cbits/fsx.o cbits/vecgpu.o cbits/handjit.o $(GLLIBS); \
	fi
	ln -sf fpr fprc
endif

# build through cabal (declared FFI/libs in fp-risc.cabal).  Uses
# cabal-install when present, else the classic Setup path -- which
# resolves against the installed package db and needs no hackage
# index, so it works offline.
fpr-cabal:
	@if command -v cabal >/dev/null 2>&1; then \
	  cabal build exe:fpr && cp "$$(cabal list-bin fpr)" fpr; \
	else \
	  ghc -o build/Setup Setup.hs >/dev/null && \
	  ./build/Setup configure --ghc >/dev/null && \
	  ./build/Setup build 2>&1 | tail -1 && \
	  cp dist/build/fpr/fpr fpr; \
	fi
	ln -sf fpr fprc

fprc: fpr

# ---- the std proof pass ------------------------------------------------
stdcheck: fprc
	./fprc --stdcheck $(FILE)

# ---- BareMetal profile -------------------------------------------------
$(BUILD)/prog.s: fprc $(PROG) core/prelude.fpr FORCE
	@mkdir -p $(BUILD)
	LC_ALL=C.UTF-8 ./fprc --profile=bare-metal $(FPRC_FLAGS) --prelude=core/prelude.fpr $(PROG) $@

bare-metal: $(BUILD)/prog.s $(RT_VIRT) $(RT_CORE) $(HAL)/virt/link.ld
	$(CROSS)gcc $(CFLAGS) -T $(HAL)/virt/link.ld -I$(HAL)/core -I$(HAL)/virt \
	  $(RT_VIRT) $(BUILD)/prog.s $$(cat $(BUILD)/prog.s.units) $(RT_CORE) -o $(IMAGE)

bare-metal-run: bare-metal
	$(TIMEOUT) 20 $(QEMU) $(ACCEL) -machine virt -smp $(HARTS) -m 256M \
	  -nographic -bios none -kernel $(IMAGE)

# ---- QOSPortable profile: the app side ---------------------------------
# The .qa is freestanding at the published slot; every effect goes
# through the qos_hal_t table (qos/appside/hal.c).  The HOST is built
# separately: make -C ../qos portable.
QOS_SLOT_BASE  = 0x400000000
# the app's notion of "the heap" (fpr_in_heap) ends where the host's
# arena ends: MUST agree with qos/Makefile's ARENA_MB, or a grant above
# the line is mistaken for a static and shared by identity (found as
# random corruption past ~220 sessions when the host arena grew to 2 GiB)
ARENA_MB ?= 2048
PROC_ARENA_END := $(shell printf '0x%x' $$(( $(QOS_SLOT_BASE) + $(ARENA_MB) * 1048576 )))
QOSHARTS ?= 8
QOSAPP_RT_COMMON = $(QOS)/appside/entry.c $(QOS)/appside/hal.c $(QOS)/appside/support.c \
				   $(HAL)/core/runtime.c $(HAL)/core/actors.c $(HAL)/core/bits.c \
				   $(HAL)/core/vec.c $(HAL)/core/sstr.c $(HAL)/core/mod.c \
				   $(HAL)/core/buddy.c
QOSAPP_RT = $(QOSAPP_RT_COMMON) $(HAL)/unix/ctx_x64.S

$(BUILD)/qosapp-prog.s: fprc $(PROG) core/prelude.fpr FORCE
	@mkdir -p $(BUILD)
	LC_ALL=C.UTF-8 ./fprc --profile=qos-portable --prelude=core/prelude.fpr $(PROG) $@

$(BUILD)/qosapp.elf: $(BUILD)/qosapp-prog.s $(QOSAPP_RT) $(QOS)/appside/link-qosapp.ld
	gcc -O2 -Wall -Wextra -ffreestanding -nostdlib -nostartfiles -static \
	  -fno-stack-protector -fno-asynchronous-unwind-tables -fno-pic -mcmodel=large \
	  -DFPR_POSIX -DFPR_QOSAPP -DFPR_NHARTS=$(QOSHARTS) -DFPR_SLAB_SZ=$(QOSSLAB) -DFPR_STACK_SZ=$(QOSSTACK) $(QOSCFLAGS_EXTRA) \
	  -I$(HAL)/core -I$(QOS)/appside \
	  -T $(QOS)/appside/link-qosapp.ld -Wl,--defsym=QOS_SLOT_BASE=$(QOS_SLOT_BASE) \
	  -Wl,--defsym=_heap_start=_proc_image_end -Wl,--defsym=_heap_end=_proc_image_end \
	  -Wl,--defsym=_proc_arena_end=$(PROC_ARENA_END) \
	  -Wl,--build-id=none -Wl,-z,noexecstack \
	  $(BUILD)/qosapp-prog.s $$(cat $(BUILD)/qosapp-prog.s.units) $(QOSAPP_RT) -o $@

qos-app: $(BUILD)/qosapp.elf tools/mkqa.py
	@MF=$(BUILD)/qosapp-gen.toml; ID=$$(basename $(PROG) .fpr); \
	ABIV=$$(grep -m1 'define QOS_ABI_VERSION' $(QOS)/appside/qos_abi.h | grep -o '[0-9]\+' | head -1); \
	REV=$$(cat $(BUILD)/qosapp-prog.s.abirev 2>/dev/null || echo 0); \
	printf 'name = "%s"\nid = "%s"\nentry = "n/a"\nversion = "1"\nloadMode = "process"\nabi = "%s.%s"\n' $$ID $$ID $$ABIV $$REV > $$MF; \
	python3 tools/mkqa.py $$MF $(BUILD)/qosapp.elf -o $(QA_OUT)
	@echo "$(QA_OUT) built — run with: (cd ../qos && make portable && ./qosp --yes ../fp-risc/$(QA_OUT))"

# ---- QOS app for macOS (Apple Silicon) -----------------------------------
# qosp's in-process loader consumes fixed-slot ELF on every host.  Apple
# Clang + lld can cross-link that AArch64 ELF without a Linux sysroot because
# the app and runtime are freestanding.  The code still executes under Darwin,
# where x18 is platform-reserved, so the generic ELF compiler must not use it.
# Mach-O emission remains available separately for native macOS integration work.
$(BUILD)/qosapp-a64.s: fprc $(PROG) core/prelude.fpr FORCE
	@mkdir -p $(BUILD)
	LC_ALL=C.UTF-8 ./fprc --target=qa64 --prelude=core/prelude.fpr $(PROG) $@

$(BUILD)/qosapp-a64.elf: $(BUILD)/qosapp-a64.s $(QOSAPP_RT_COMMON) $(HAL)/unix/ctx_a64.S $(QOS)/appside/link-qosapp-a64.ld
	clang --target=aarch64-none-elf -fuse-ld=lld -O2 -Wall -Wextra \
	  -ffreestanding -nostdlib -nostartfiles -fno-stack-protector \
	  -fno-asynchronous-unwind-tables -fno-pic -ffixed-x18 -ffixed-x28 \
	  -DFPR_POSIX -DFPR_QOSAPP -DFPR_NHARTS=$(QOSHARTS) -DFPR_SLAB_SZ=$(QOSSLAB) -DFPR_STACK_SZ=$(QOSSTACK) $(QOSCFLAGS_EXTRA) \
	  -I$(HAL)/core -I$(QOS)/appside \
	  -T $(QOS)/appside/link-qosapp-a64.ld -Wl,--defsym=QOS_SLOT_BASE=$(QOS_SLOT_BASE) \
	  -Wl,--defsym=_heap_start=_proc_image_end -Wl,--defsym=_heap_end=_proc_image_end \
	  -Wl,--defsym=_proc_arena_end=$(PROC_ARENA_END) \
	  $(BUILD)/qosapp-a64.s $$(cat $(BUILD)/qosapp-a64.s.units) \
	  $(QOSAPP_RT_COMMON) $(HAL)/unix/ctx_a64.S -o $@

qos-app-macos: $(BUILD)/qosapp-a64.elf tools/mkqa.py
	@MF=$(BUILD)/qosapp-a64-gen.toml; ID=$$(basename $(PROG) .fpr); \
	ABIV=$$(grep -m1 'define QOS_ABI_VERSION' $(QOS)/appside/qos_abi.h | grep -o '[0-9]\+' | head -1); \
	REV=$$(cat $(BUILD)/qosapp-a64.s.abirev 2>/dev/null || echo 0); \
	printf 'name = "%s"\nid = "%s"\nentry = "n/a"\nversion = "1"\nloadMode = "process"\nabi = "%s.%s"\n' $$ID $$ID $$ABIV $$REV > $$MF; \
	python3 tools/mkqa.py $$MF $(BUILD)/qosapp-a64.elf -o $(QA_OUT)
	@echo "$(QA_OUT) built for Apple Silicon"

# ---- plugin .qa: a library image loaded into the RUNNING shell -----------
# Linked at a PLUG sub-slot (qos_abi.h: 0x408000000 + PLUGSLOT * 4 MiB,
# 8 slots) against the running app image's OWN symbol addresses -- a
# PROVIDE() script generated from nm.  The plugin carries only its own
# generated code + module table (ENTRY(fpr_modtab) in link-qosplug.ld);
# the runtime C, prelude, and any shared mods resolve to the shell's
# copy.  Load it from INSIDE: read apps/<id>.qa off qosp.disk with
# mods/qlog, hand the bytes to Sys.attachQa (tests/qload.fpr).
#
# TWO LAWS, both previously paid for in blood:
#   1. plugin targets DELIBERATELY do not depend on the app elf -- a
#      silent shell rebuild would desync every PROVIDE address
#      (SIGSEGV pc=0).  After ANY shell rebuild: make plugsyms[-macos],
#      then rebuild EVERY plugin, then reinstall the whole set.
#   2. qosp + app.qa + all plugin .qa's install as a matched set.
PLUGSLOT ?= 0
PLUGID    = $(basename $(notdir $(PROG)))
PLUG_OUT ?= $(PLUGID).qa
PLUGBASE  = $(shell printf '0x%x' $$(( 0x408000000 + $(PLUGSLOT) * 4194304 )))

plugsyms:
	@test -f $(BUILD)/qosapp.elf || { echo "build the shell first: make qos-app PROG=<shell>"; exit 1; }
	nm --defined-only $(BUILD)/qosapp.elf | \
	  awk '$$2 ~ /^[A-Z]$$/ && $$3 != "" && $$3 !~ /^\$$/ { printf "PROVIDE(%s = 0x%s);\n", $$3, $$1 }' > $(BUILD)/plugsyms-x64.ld
	@echo "plugsyms-x64.ld: $$(wc -l < $(BUILD)/plugsyms-x64.ld) shell symbols"

plugsyms-macos:
	@test -f $(BUILD)/qosapp-a64.elf || { echo "build the shell first: make qos-app-macos PROG=<shell>"; exit 1; }
	nm --defined-only $(BUILD)/qosapp-a64.elf | \
	  awk '$$2 ~ /^[A-Z]$$/ && $$3 != "" && $$3 !~ /^\$$/ { printf "PROVIDE(%s = 0x%s);\n", $$3, $$1 }' > $(BUILD)/plugsyms-a64.ld
	@echo "plugsyms-a64.ld: $$(wc -l < $(BUILD)/plugsyms-a64.ld) shell symbols"

plugin-qa: fprc core/prelude.fpr
	@test -f $(BUILD)/plugsyms-x64.ld || { echo "no plugsyms: make plugsyms first (after the shell build)"; exit 1; }
	@mkdir -p $(BUILD)
	LC_ALL=C.UTF-8 ./fprc --target=qx64 --plugin --prelude=core/prelude.fpr $(PROG) $(BUILD)/plug-$(PLUGID).s
	gcc -O2 -Wall -Wextra -ffreestanding -nostdlib -nostartfiles -static \
	  -fno-stack-protector -fno-asynchronous-unwind-tables -fno-pic -mcmodel=large \
	  -DFPR_POSIX -DFPR_QOSAPP -DFPR_NHARTS=$(QOSHARTS) -DFPR_SLAB_SZ=$(QOSSLAB) -DFPR_STACK_SZ=$(QOSSTACK) $(QOSCFLAGS_EXTRA) -I$(HAL)/core -I$(QOS)/appside \
	  -T $(QOS)/appside/link-qosplug.ld -T $(BUILD)/plugsyms-x64.ld \
	  -Wl,--defsym=PLUG_BASE=$(PLUGBASE) -Wl,--build-id=none -Wl,-z,noexecstack \
	  $(BUILD)/plug-$(PLUGID).s $$(cat $(BUILD)/plug-$(PLUGID).s.units) -o $(BUILD)/plug-$(PLUGID).elf
	@MF=$(BUILD)/plug-$(PLUGID)-gen.toml; \
	printf 'name = "%s"\nid = "%s"\nentry = "fpr_modtab"\nversion = "1"\nloadMode = "plugin"\n' $(PLUGID) $(PLUGID) > $$MF; \
	python3 tools/mkqa.py $$MF $(BUILD)/plug-$(PLUGID).elf -o $(PLUG_OUT) --shell-of $(QA_OUT)
	@echo "$(PLUG_OUT) built at sub-slot $(PLUGSLOT) ($(PLUGBASE)) -- install: make -C ../qos disk-seed QAS=..."

plugin-qa-macos: fprc core/prelude.fpr
	@test -f $(BUILD)/plugsyms-a64.ld || { echo "no plugsyms: make plugsyms-macos first (after the shell build)"; exit 1; }
	@mkdir -p $(BUILD)
	LC_ALL=C.UTF-8 ./fprc --target=qa64 --plugin --prelude=core/prelude.fpr $(PROG) $(BUILD)/plug-$(PLUGID)-a64.s
	clang --target=aarch64-none-elf -fuse-ld=lld -O2 -Wall -Wextra \
	  -ffreestanding -nostdlib -nostartfiles -fno-stack-protector \
	  -fno-asynchronous-unwind-tables -fno-pic -ffixed-x28 \
	  -DFPR_POSIX -DFPR_QOSAPP -DFPR_NHARTS=$(QOSHARTS) -DFPR_SLAB_SZ=$(QOSSLAB) -DFPR_STACK_SZ=$(QOSSTACK) $(QOSCFLAGS_EXTRA) -I$(HAL)/core -I$(QOS)/appside \
	  -T $(QOS)/appside/link-qosplug.ld -T $(BUILD)/plugsyms-a64.ld \
	  -Wl,--defsym=PLUG_BASE=$(PLUGBASE) \
	  $(BUILD)/plug-$(PLUGID)-a64.s $$(cat $(BUILD)/plug-$(PLUGID)-a64.s.units) -o $(BUILD)/plug-$(PLUGID)-a64.elf
	@MF=$(BUILD)/plug-$(PLUGID)-a64-gen.toml; \
	printf 'name = "%s"\nid = "%s"\nentry = "fpr_modtab"\nversion = "1"\nloadMode = "plugin"\n' $(PLUGID) $(PLUGID) > $$MF; \
	python3 tools/mkqa.py $$MF $(BUILD)/plug-$(PLUGID)-a64.elf -o $(PLUG_OUT) --shell-of $(QA_OUT)
	@echo "$(PLUG_OUT) built at sub-slot $(PLUGSLOT) ($(PLUGBASE)) -- install: make -C ../qos disk-seed QAS=..."

qos-app-macos-run: qos-app-macos
	$(MAKE) -C $(QOS) portable
	$(QOS)/qosp --yes $(QA_OUT)

qos-app-macos-object: fprc $(PROG) core/prelude.fpr
	@mkdir -p $(BUILD)
	LC_ALL=C.UTF-8 ./fprc --target=qa64mac --prelude=core/prelude.fpr $(PROG) $(BUILD)/qosapp-mac.s
	clang --target=arm64-apple-macos11 -c $(BUILD)/qosapp-mac.s -o $(BUILD)/qosapp-mac.o
	@echo "emitted $(BUILD)/qosapp-mac.s (Mach-O syntax, QOS-app cells)"

# ---- HostedBytecode profile: the sol package ---------------------------
sol: fpr
	@echo "the HostedBytecode profile is: ./fpr sol <script.sol>"

clean-cabal:
	rm -rf dist dist-newstyle build/Setup

clean:
	rm -rf build image.elf app.qa fpr fprc compiler/*.o compiler/*.hi compiler/Sol/*.o compiler/Sol/*.hi compiler/cbits/*.o

FORCE:
.PHONY: all stdcheck bare-metal bare-metal-run qos-app qos-app-macos qos-app-macos-run qos-app-macos-object sol clean FORCE
