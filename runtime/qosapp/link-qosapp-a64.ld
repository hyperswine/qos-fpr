/* link-qosapp-a64.ld -- fixed-slot linker script for QOS-aarch64 app images.
 * Same layout and contract as link-qosapp.ld; only OUTPUT_FORMAT/ARCH differ.
 */
OUTPUT_FORMAT("elf64-littleaarch64")
OUTPUT_ARCH(aarch64)
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
  . = ALIGN(16); _proc_image_end = .;

  /DISCARD/ : { *(.note.* .comment .eh_frame .eh_frame_hdr .rela.*) }
}
