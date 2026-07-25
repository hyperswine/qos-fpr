/* heap.S — the posix stand-in for link.ld's memory map.
 *
 * Bare metal, _heap_start/_heap_end and the process arena are linker-
 * script symbols carving up physical RAM.  Hosted, the "RAM" is just a
 * big .bss block; the process arena is zero-sized (no process loading
 * in the posix HAL yet) but the symbols must exist and be ordered,
 * because fpr_in_heap() tests _heap_start <= p < _proc_arena_end.
 * Assembles unchanged for aarch64 and x86-64.  */
    .bss
    .balign 65536
    .globl _heap_start, _heap_end, _proc_arena_start, _proc_arena_end
_heap_start:
    .space 64 * 1024 * 1024
_heap_end:
_proc_arena_start:
_proc_arena_end:
