/* link-qosapp.ld -- the fixed-slot linker script for QOS-x86_64 app
 * images (link-app.ld's hosted sibling; docs/QOS-PORTABLE.md).
 *
 * Unlike build-process-app.sh's flow, QOS_SLOT_BASE is a published
 * CONSTANT (qos_abi.h), not an address fished out of a system.elf
 * symbol table: the host reserves exactly this range in its arena via
 * buddy_reserve_range, so an app.qa built today loads under any qosp
 * built tomorrow.  The --defsym on the link line must match qos_abi.h
 * (the Makefile passes it from one place).
 *
 * Fixed-slot means the same thing it means on virt: no relocation is
 * performed at load; internal references survive because nothing
 * moves, and there ARE no external references -- every host call goes
 * through the boot record's table pointers (docs/PROCESS-LOADING.md's
 * limit section explains why this is the honest scope).
 *
 * ENTRY(qos_app_entry): a plain callable function; e_entry just tells
 * the loader where it is, the way any ELF loader reads it. */
OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)
ENTRY(qos_app_entry)

MEMORY { SLOT (rwx) : ORIGIN = QOS_SLOT_BASE, LENGTH = 16M }

SECTIONS {
  .text : { *(.text .text.*) } > SLOT
  .rodata : { *(.rodata .rodata.*) } > SLOT
  .data : { *(.data .data.* .got .got.plt) } > SLOT
  .bss (NOLOAD) : {
    . = ALIGN(8); _bss_start = .;
    *(.bss .bss.*) *(COMMON)
    . = ALIGN(8); _bss_end = .;
  } > SLOT
  . = ALIGN(16); _proc_image_end = .; /* where the heap hand-off starts */

  /DISCARD/ : { *(.note.* .comment .eh_frame .eh_frame_hdr .rela.*) }
}
