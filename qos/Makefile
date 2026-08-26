# qos/Makefile — the QOS backend, built SEPARATELY from fp-risc.
#
#   make portable          # qosp: the QOS Portable host (unix)
#   make portable-run      # qosp running ../fp-risc/app.qa
#   make native            # qos-native.elf: the kernel (system.fpr) for QEMU virt
#   make native-run        # boot it as a kernel with a seeded disk
#
# QOS Portable is NOT an OS: qosp hosts ONE FP-RISC .qa by satisfying
# its std assumptions through the qos_hal_t table.  QOS Native IS the
# OS: system.fpr compiled AOT for RISC-V, linked with hal/{core,virt},
# loaded by QEMU as the kernel.  Both consume ../hal — the C layer is
# a HAL, not an implementation.  The kernel is itself an FP-RISC
# program, so `native` invokes ../fp-risc/fprc as a TOOL; the build
# products and dependency graph stay entirely on this side.

HAL    = ../hal
FPR    = ../fp-risc
FPRC   = $(FPR)/fprc
HARTS ?= 2
QOSHARTS ?= 8
CROSS  = riscv64-unknown-elf-
QEMU   = qemu-system-riscv64
ACCEL  = -accel tcg,thread=multi
TIMEOUT := $(shell command -v timeout 2>/dev/null || echo "")
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
HOST_LDFLAGS :=
DESKTOP_GL_LIBS := $(shell pkg-config --libs glfw3 2>/dev/null) -framework OpenGL -lpthread -lm
else
HOST_LDFLAGS := -no-pie
DESKTOP_GL_LIBS := $(shell pkg-config --libs glfw3 2>/dev/null) -lGL -lpthread -lm
endif
DESKTOP_GL_CFLAGS := $(shell pkg-config --cflags glfw3 2>/dev/null)

# ---- QOS Portable: the qosp host ---------------------------------------
QOSP_SRC = portable/main.c portable/qa.c portable/haltab.c portable/store.c \
           portable/compile.c \
           $(HAL)/unix/net_raw.c $(HAL)/unix/blk_raw.c $(HAL)/unix/hostlog.c \
           $(HAL)/unix/tty_raw.c $(HAL)/unix/evdev_raw.c \
           $(HAL)/core/buddy.c $(HAL)/core/qaimg.c

# the shell's half of the ABI stamp is DERIVED from the authoritative
# source (Codegen.hs codegenRev), not hardcoded -- the first stamped
# build caught main.c's #define 7 lagging a rev-8 compiler within the
# hour.  Falls back to main.c's #define if the compiler tree is absent.
CODEGEN_REV := $(shell grep -m1 '^codegenRev = ' $(FPR)/compiler/Codegen.hs 2>/dev/null | grep -o '[0-9]\+' | head -1)
REV_FLAG := $(if $(CODEGEN_REV),-DQOSP_CODEGEN_REV=$(CODEGEN_REV),)

portable: $(QOSP_SRC) appside/qos_abi.h portable/qa.h $(FPR)/compiler/Codegen.hs
	gcc $(HOST_LDFLAGS) -O2 -Wall -Wextra -DFPR_POSIX -DQOSP_HOST -DFPR_NHARTS=$(QOSHARTS) $(REV_FLAG) \
	  -I$(HAL)/core -I$(HAL)/unix -Iappside $(QOSP_SRC) -o qosp

portable-run: portable
	./qosp --yes $(FPR)/app.qa

# ---- QOS Portable with the desktop-GL gfx tier --------
# GLFW window + OpenGL 3.3-core shaders; keys arrive as SYNTHETIC EVDEV
# (gfx.c translates GLFW keycodes and injects them into evdev_raw's one
# modifier machine, so the appkit keymap and FPR_EVDEV replay are
# untouched).  The same source builds on macOS (OpenGL/gl3.h declares
# prototypes; Linux needs GL_GLEXT_PROTOTYPES, set in gfx.c).
QOSP_GL_SRC = $(QOSP_SRC) $(HAL)/unix/gfx.c
portable-gl: $(QOSP_GL_SRC) appside/qos_abi.h portable/qa.h $(FPR)/compiler/Codegen.hs
	gcc $(HOST_LDFLAGS) -O2 -Wall -Wextra -DFPR_POSIX -DQOSP_HOST -DFPR_NHARTS=$(QOSHARTS) $(REV_FLAG) \
	  -DQOSP_GFX -DFPR_DESKTOP_GL \
	  $(DESKTOP_GL_CFLAGS) -I$(HAL)/core -I$(HAL)/unix -Iappside $(QOSP_GL_SRC) -o qosp-gl \
	  $(DESKTOP_GL_LIBS)

# ---- QOS Portable, aarch64 cross (verifies the x28 hart discipline
portable-a64: $(QOSP_SRC) appside/qos_abi.h portable/qa.h
	aarch64-linux-gnu-gcc -static -O2 -Wall -Wextra -DFPR_POSIX -DQOSP_HOST -DFPR_NHARTS=$(QOSHARTS) \
	  -I$(HAL)/core -I$(HAL)/unix -Iappside $(QOSP_SRC) -o qosp-a64 -lpthread

# ---- QOS Native: the kernel --------------------------------------------
RT_CORE = $(HAL)/core/runtime.c $(HAL)/core/actors.c $(HAL)/core/bits.c \
          $(HAL)/core/vec.c $(HAL)/core/sstr.c $(HAL)/core/mod.c $(HAL)/core/buddy.c
RT_VIRT = $(HAL)/virt/crt0.S $(HAL)/virt/ctx.S $(HAL)/virt/ctx_fab.c \
          $(HAL)/virt/hal.c $(HAL)/virt/plic.c $(HAL)/virt/net.c $(HAL)/virt/blk.c $(HAL)/virt/memshim.c
ARCHFLAGS = -march=rv64imafdc_zicsr -mabi=lp64 -mcmodel=medany
CFLAGS = $(ARCHFLAGS) -DFPR_NHARTS=$(HARTS) \
         -ffreestanding -nostdlib -nostartfiles -O2 -Wall -Wextra \
         -fno-builtin -fno-stack-protector

# the rodata fallback registry: placeholder .qa's from the manifests
QAPPS = TUIAppLauncher TUINotes TUIClock HelloProc
build/qa0/%.qa: $(FPR)/apps/%.toml $(FPR)/tools/mkqa.py
	@mkdir -p build/qa0
	python3 $(FPR)/tools/mkqa.py $< -o $@

build/apps_data.c: $(patsubst %,build/qa0/%.qa,$(QAPPS)) $(FPR)/tools/genapps.py
	python3 $(FPR)/tools/genapps.py --entries --out $@ -- $(patsubst %,build/qa0/%.qa,$(QAPPS))

build/system.s: $(FPRC) $(FPR)/programs/system.fpr $(FPR)/core/prelude.fpr FORCE
	@mkdir -p build
	LC_ALL=C.UTF-8 $(FPRC) --profile=qos-native --prelude=$(FPR)/core/prelude.fpr \
	  $(FPR)/programs/system.fpr $@

native: build/system.s build/apps_data.c $(RT_VIRT) $(RT_CORE) $(HAL)/virt/link.ld
	$(CROSS)gcc $(CFLAGS) -T $(HAL)/virt/link.ld -I$(HAL)/core -I$(HAL)/virt \
	  $(RT_VIRT) build/system.s $$(cat build/system.s.units) $(RT_CORE) \
	  $(HAL)/core/apps.c build/apps_data.c $(HAL)/core/qaimg.c $(HAL)/core/process.c \
	  -o qos-native.elf

disk.img: $(FPR)/tools/mkdisk.py
	python3 $(FPR)/tools/mkdisk.py disk.img 8

# ---- the portable disk ---------------------------------------------------
# qosp.disk is a QLOG image -- the SAME format native-run's disk.img
# uses, seeded by the SAME tool.  qosp creates a blank one on first
# `device "blk"` (FPR_DISK / FPR_DISK_MB override path and size);
# `make disk-seed QAS="a.qa b.qa"` installs built .qa apps onto it as
# apps/<Id>.qa records plus the apps/index, ready for the System.qa
# loading path.
disk-seed: $(FPR)/tools/mkdisk.py
	python3 $(FPR)/tools/mkdisk.py qosp.disk 8 $(QAS)

native-run: native disk.img
	$(TIMEOUT) 25 $(QEMU) $(ACCEL) -machine virt -smp $(HARTS) -m 256M \
	  -nographic -bios none -kernel qos-native.elf \
	  -drive file=disk.img,if=none,format=raw,id=hd0 -device virtio-blk-device,drive=hd0

clean:
	rm -rf build qosp qos-native.elf disk.img

FORCE:
.PHONY: portable portable-run native native-run clean FORCE
