# runtime/posix — the hosted HAL: libc is the board

An FPRISC program compiled with `--target=a64` plus this directory is a
single static hosted binary: same compiler, same portable core
(`runtime/core`), same discoverable-symbol contract — with the virt
machine layer's obligations re-satisfied by the host OS's userspace
instead of MMIO.

    make posix-run PROG=tests/orig1.fpr      # cross + qemu-user
    make posix-run POSIXCC=gcc POSIXRUN=     # native on arm64 Linux

## How the pieces line up

| virt (bare metal)                  | posix (hosted)                       |
|------------------------------------|--------------------------------------|
| crt0.S boot, per-hart stacks       | the host did all of it; `main.c`     |
| link.ld heap/arena regions         | `heap.S` .bss block, same symbols    |
| tp holds the hart pointer          | `fpr_posix_hart` global (A64.hs makes generated code load it) |
| hal.c UART MMIO                    | `hal.c` write(1)/exit                |
| device table / Pin / Mmio          | absent on purpose: reaching for them is a **link error naming the capability** |
| actors.c scheduler + ctx.S         | not yet: single hart, main on the C stack, actor prims panic by name |

The capability story is the point: a hosted image that only computes
links against nothing but the core prims; the moment a program touches
`Pin.read` or `device`, the link fails with `fpr_g_Pin_x2eread` — the
same "the image's imports ARE its capability manifest" property the
.qa manifest gives on QOS, enforced by the linker on a host.

## The a64 target (compiler/A64.hs)

`--target=a64` does not add a second code generator. Codegen.hs's rv64
emission only ever uses a ~20-mnemonic, flags-free, 16-byte-aligned,
direct-control-flow subset of RISC-V — a de-facto portable RISC IR —
and A64.hs lowers that subset 1:1 to AArch64 under a register map that
agrees with AAPCS64 everywhere the code touches C (a0-a7 = x0-x7,
callee/caller-saved partitions line up), so translated FPRISC calls
the C runtime with no shims. Naive by design: no LDP/STP fusion, no
CSEL, one cmp per branch. Correct first; the fusion peepholes are
where performance work would go.

## Known next steps

- **macOS/Mach-O**: same instructions; `:lo12:` becomes `@PAGE/@PAGEOFF`,
  C-visible symbols grow a leading `_`, section directives change.
  A syntax layer over A64.hs, not a new translation.
- **Actors**: ctx switching needs a posix backend (ucontext fibers or
  N-actors-per-pthread, matching the P4 plan's N-to-2 mapping); until
  then the fuel check refills and never yields.
- **The System actor / URL surface**: `/home/...` → `$HOME` resolution,
  `/dev/keyboard` behind an event loop — the hosted System.qa
  discussed in the design notes. The HAL boundary here is where those
  actors' backing implementations (open/read/write, sockets) live.
