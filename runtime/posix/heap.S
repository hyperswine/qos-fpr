/* heap.S — the posix stand-in for link.ld's memory map.
 *
 * Bare metal, _heap_start/_heap_end and the process arena are linker-
 * script symbols carving up physical RAM.  Hosted, the "RAM" is just a
 * big .bss block; the process arena is zero-sized (no process loading
 * in the posix HAL yet) but the symbols must exist and be ordered,
 * because fpr_in_heap() tests _heap_start <= p < _proc_arena_end.
 * Assembles unchanged for aarch64 and x86-64.  */

// changed from 16 heap_start
#ifdef __APPLE__
/* Mach-O: no .bss labels-in-sequence; an ordered .zerofill group in one
 * private section gives the same shape.  C sees `_heap_start` etc., so
 * the assembler names carry the extra Darwin underscore.  Ordering and
 * adjacency (heap_end == heap_start + 64 MiB) are verified by
 * tools/mac-smoke.sh via nm before anything runs. */
    .globl __heap_start, __heap_end, __proc_arena_start, __proc_arena_end
    .zerofill __DATA,__fprheap,__heap_start,67108864,14
    .zerofill __DATA,__fprheap,__heap_end,0,3
    .zerofill __DATA,__fprheap,__proc_arena_start,0,3
    .zerofill __DATA,__fprheap,__proc_arena_end,0,3
#else
    .bss
    .balign 65536
    .globl _heap_start, _heap_end, _proc_arena_start, _proc_arena_end
_heap_start:
    .space 64 * 1024 * 1024
_heap_end:
_proc_arena_start:
_proc_arena_end:
#endif
