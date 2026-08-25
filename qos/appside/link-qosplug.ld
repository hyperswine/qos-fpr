/* link-qosplug.ld -- a plugin .qa image: generated code + module table
 * ONLY, linked at a PLUG sub-slot (qos_abi.h: QOS_PLUG_BASE + slot *
 * 4 MiB) against the RUNNING shell image's own symbol addresses (the
 * PROVIDE() script `make plugsyms` generates from nm).  Everything the
 * plugin does not define -- the runtime C, the prelude unit, shared
 * mods -- resolves to the shell's copy; tids are content-derived, so
 * constructors built here pattern-match there.
 *
 * ENTRY is the MODULE TABLE, not code: mkqa.py records e_entry in the
 * LOAD section, qosp hands it back from tag 4, and fpr_mod_attach
 * registers it -- the table's address IS the plugin's identity.
 *
 * Two PT_LOADs, explicitly (the link-qosapp lesson): text+rodata r-x,
 * data+bss rw, ALIGN(0x10000) between them so the W^X boundary is real
 * on 4 K and 16 K pages alike.  PLUG_BASE arrives via --defsym from
 * the Makefile's sub-slot arithmetic. */
ENTRY(fpr_modtab)
PHDRS {
  text PT_LOAD;
  data PT_LOAD;
}
SECTIONS {
  . = PLUG_BASE;
  .text : { *(.text .text.*) } :text
  .rodata : ALIGN(16) { *(.rodata .rodata.*) *(.srodata*) } :text
  . = ALIGN(0x10000);
  .data : { *(.data .data.*) *(.sdata*) } :data
  .bss : { *(.bss .bss.*) *(.sbss*) *(COMMON) } :data
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
