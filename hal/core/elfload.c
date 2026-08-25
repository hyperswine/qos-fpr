/* elfload.c -- a minimal ELF32/ELF64 PT_LOAD segment loader.
 *
 * FIXED-SLOT ONLY: this performs no relocation. Every PT_LOAD's
 * p_vaddr must already equal the physical address the segment should
 * live at (the app was linked against link-app.ld with PROC_SLOT_BASE
 * matching the caller's chosen slot -- docs/PROCESS-LOADING.md). This
 * loader's entire job is: validate, copy p_filesz bytes, zero the
 * (p_memsz - p_filesz) tail (this is how .bss ends up zeroed -- no
 * special-casing by section name, just the general ELF rule that
 * memsz can exceed filesz), and report where the entry point and the
 * image's high-water mark are.
 *
 * Hand-rolled structs instead of <elf.h>: this is freestanding code
 * with no libc, and the two layouts needed are small enough to state
 * directly (note ELF32 and ELF64 order their Phdr fields differently
 * -- flags is the SECOND field in Elf64_Phdr but the SEVENTH in
 * Elf32_Phdr, a classic trap for a copy-pasted loader).
 */
#include "fpr.h"

#define PT_LOAD 1
#define PF_X 1
#define PF_W 2

typedef struct {
  unsigned char e_ident[16];
  uint16_t e_type, e_machine;
  uint32_t e_version;
  uint64_t e_entry, e_phoff, e_shoff;
  uint32_t e_flags;
  uint16_t e_ehsize, e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx;
} Elf64_Ehdr;

typedef struct {
  uint32_t p_type, p_flags;
  uint64_t p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align;
} Elf64_Phdr;

typedef struct {
  unsigned char e_ident[16];
  uint16_t e_type, e_machine;
  uint32_t e_version, e_entry, e_phoff, e_shoff, e_flags;
  uint16_t e_ehsize, e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx;
} Elf32_Ehdr;

typedef struct {
  uint32_t p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align;
} Elf32_Phdr;

static fpr_elf_load_t fail(const char *why) {
  fpr_elf_load_t r = {0, 0, 0, why, 0, (void *)~(uw)0};
  return r;
}

/* one PT_LOAD segment, in a class-neutral shape, after we've decoded
 * either the 32- or 64-bit header variant */
typedef struct { uw type, flags, offset, vaddr, filesz, memsz; } seg_t;

static fpr_elf_load_t load_segments(const unsigned char *bytes, uw len, seg_t *segs, int nseg,
                                     void *slot_base, uw slot_size, uw entry) {
  uw sb = (uw)slot_base, se = sb + slot_size;
  uw max_end = 0, exec_end = 0, rw_start = ~(uw)0;
  for (int i = 0; i < nseg; i++) {
    if (segs[i].type != PT_LOAD) continue;
    if (segs[i].vaddr < sb || segs[i].vaddr + segs[i].memsz > se || segs[i].vaddr + segs[i].memsz < segs[i].vaddr)
      return fail("PT_LOAD segment falls outside the target slot");
    if (segs[i].offset + segs[i].filesz > len || segs[i].offset + segs[i].filesz < segs[i].offset)
      return fail("PT_LOAD segment data runs past the end of the archive");
    if (segs[i].filesz > segs[i].memsz)
      return fail("PT_LOAD filesz exceeds memsz (malformed ELF)");
    void *dst = (void *)segs[i].vaddr;
    for (uw k = 0; k < segs[i].filesz; k++) ((unsigned char *)dst)[k] = bytes[segs[i].offset + k];
    for (uw k = segs[i].filesz; k < segs[i].memsz; k++) ((unsigned char *)dst)[k] = 0; /* .bss tail */
    uw end = segs[i].vaddr + segs[i].memsz;
    if (end > max_end) max_end = end;
    if ((segs[i].flags & PF_X) && end > exec_end) exec_end = end;
    /* memsz==0: a degenerate empty segment (a data-less image emits
     * one) -- no writable byte exists, so it must not constrain the
     * W^X split */
    if ((segs[i].flags & PF_W) && segs[i].memsz && segs[i].vaddr < rw_start)
      rw_start = segs[i].vaddr;
  }
  if (max_end == 0) return fail("no PT_LOAD segments found");
  if (entry < sb || entry >= se) return fail("entry point falls outside the target slot");
  fpr_elf_load_t r = {(void *)entry, (void *)max_end, 1, 0, (void *)exec_end, (void *)rw_start};
  return r;
}

fpr_elf_load_t fpr_elf_load(const unsigned char *bytes, uw len, void *slot_base, uw slot_size) {
  if (len < 20 || bytes[0] != 0x7f || bytes[1] != 'E' || bytes[2] != 'L' || bytes[3] != 'F')
    return fail("not an ELF image (bad magic)");
  int is64 = bytes[4] == 2;
  if (bytes[4] != 1 && bytes[4] != 2) return fail("unknown ELF class");

  if (is64) {
    if (len < sizeof(Elf64_Ehdr)) return fail("ELF64 header truncated");
    const Elf64_Ehdr *eh = (const Elf64_Ehdr *)bytes;
    uw phoff = eh->e_phoff;
    uw phentsize = eh->e_phentsize;
    uw phnum = eh->e_phnum;
    if (phoff + phnum * phentsize > len || phentsize < sizeof(Elf64_Phdr))
      return fail("ELF64 program header table out of range");
    seg_t segs[64];
    if (phnum > 64) return fail("too many program headers (>64)");
    for (uw i = 0; i < phnum; i++) {
      const Elf64_Phdr *ph = (const Elf64_Phdr *)(bytes + phoff + i * phentsize);
      segs[i].type = ph->p_type;
      segs[i].flags = ph->p_flags;
      segs[i].offset = ph->p_offset;
      segs[i].vaddr = ph->p_vaddr;
      segs[i].filesz = ph->p_filesz;
      segs[i].memsz = ph->p_memsz;
    }
    return load_segments(bytes, len, segs, (int)phnum, slot_base, slot_size, eh->e_entry);
  } else {
    if (len < sizeof(Elf32_Ehdr)) return fail("ELF32 header truncated");
    const Elf32_Ehdr *eh = (const Elf32_Ehdr *)bytes;
    uw phoff = eh->e_phoff;
    uw phentsize = eh->e_phentsize;
    uw phnum = eh->e_phnum;
    if (phoff + phnum * phentsize > len || phentsize < sizeof(Elf32_Phdr))
      return fail("ELF32 program header table out of range");
    seg_t segs[64];
    if (phnum > 64) return fail("too many program headers (>64)");
    for (uw i = 0; i < phnum; i++) {
      const Elf32_Phdr *ph = (const Elf32_Phdr *)(bytes + phoff + i * phentsize);
      segs[i].type = ph->p_type;
      segs[i].flags = ph->p_flags;
      segs[i].offset = ph->p_offset;
      segs[i].vaddr = ph->p_vaddr;
      segs[i].filesz = ph->p_filesz;
      segs[i].memsz = ph->p_memsz;
    }
    return load_segments(bytes, len, segs, (int)phnum, slot_base, slot_size, eh->e_entry);
  }
}