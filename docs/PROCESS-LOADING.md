# Dynamic ELF process loading, the buddy allocator, and per-process slabs

This replaces the `Apps.run` name-dispatch fast path documented in
docs/SYSTEM-QA.md with a real loader. It is scoped honestly: this is
**fixed-slot loading**, not general position-independent relocation --
the distinction matters and is explained below, because overclaiming it
would mislead anyone building on top of this.

## Why fixed-slot, not general relocation

FPRISC links with `-mcmodel=medany`. On RISC-V, medany code accesses
every symbol -- its own functions, string literals, PAP objects, AND
calls into the shared runtime ABI (`fpr_alloc`, `fpr_apply`, `fpr_g_*`
HAL functions) -- through `auipc`+`addi` pairs: **PC-relative**, with
the *displacement* baked in by the linker at build time.

That has one useful consequence and one hard limit:

- USEFUL: if you copy an ENTIRE linked image, unchanged, to a new base
  address, every *internal* reference (a function calling another
  function in the same image, a load of its own string literal) still
  resolves correctly, because both the PC and the target moved by the
  same delta. No relocation table needed for internal references.
- THE LIMIT: a call from the app INTO the shared runtime (or vice
  versa) has its displacement computed at LINK time from the
  *specific* addresses of both sides. If the app is loaded anywhere
  other than the exact address the linker assumed, that displacement
  is now wrong. There is no relocation table to fix it up -- fprc
  doesn't emit one, and this pass does not add one.

So: an app that will be dynamically loaded must be **linked against a
known, fixed load address** (a "slot") ahead of time. "Dynamic" here
means *which* slot it lands in and *when* it's loaded -- decided at
runtime, from a `.qa` archive -- not that the address is arbitrary.
True general relocation (or PIC/GOT-based addressing) would remove this
constraint; it is a compiler feature, not a loader feature, and is
explicitly out of scope for this pass. It's a clean seam to add later:
nothing here assumes fixed-slot loading is permanent.

## The three new pieces

### 1. The buddy allocator (`runtime/buddy.c`)

A textbook power-of-two buddy allocator over a RESERVED PROCESS ARENA
(`_proc_arena_start`.._proc_arena_end in link.ld, disjoint from
System.qa's own heap). Order 0 = `BUDDY_MIN_BLOCK` (64 KiB); orders
increase by doubling up to the whole arena. Each returned block has a
1-word header immediately before it recording its order, so `buddy_free`
doesn't require the caller to remember the size. Free lists per order,
coalescing by XOR-ing the buddy bit on free (standard algorithm).

This owns TWO different jobs, both real:
- Handing out the initial CODE+HEAP slot for a freshly loaded process
  (one big block, sized to fit the ELF image plus a starting heap).
- Handing out ADDITIONAL blocks later when a running process's own
  allocator runs out (the "ask System.qa for more memory" path) --
  these don't need to be contiguous with the first block; they're pure
  heap, not code, so non-adjacency is fine.

### 2. The process entry convention (`runtime/proc_entry.S`, link-app.ld)

An app destined for dynamic loading is NOT linked with the normal
`crt0.S`/`_start` (that does GLOBAL machine bring-up -- clearing bss,
parking secondary harts, calling `fpr_rt_init` -- which would stomp on
the ALREADY-RUNNING System.qa if invoked mid-flight). It links against
`link-app.ld` (fixed origin = the one supported slot address this pass,
`PROC_SLOT_BASE`) and exposes `fpr_process_entry(heap_base, heap_size,
request_more_fn)` as a plain callable function instead of a reset
vector.

`fpr_process_entry`:
- clears its OWN bss (the copy-in step doesn't zero it; the entry does,
  using its own linker-provided `_bss_start`/`_bss_end` -- these are
  process-local symbols, disjoint from System.qa's, because the app is
  a SEPARATE compiled image)
- sets hart 0's arena from the (heap_base, heap_size) parameters instead
  of reading fixed linker symbols (single-hart per process in this
  pass -- SMP-within-a-loaded-process is future work)
- stashes `request_more_fn` for `fpr_alloc`'s exhaustion path (see
  below)
- spawns actor 0 (`main`) and runs the SAME hart_loop/ctx_switch
  scheduler the top-level boot uses -- no scheduler code was duplicated
- on actor 0's completion, instead of `fpr_exit` (which halts the WHOLE
  MACHINE), ctx-switches back to the caller (System.qa's loader) via a
  saved context, so control genuinely returns instead of parking in wfi

That last point reuses `fpr_ctx_switch` -- already-tested machinery --
rather than inventing a new control-transfer mechanism. It's wired
through a single new hook, `fpr_exit_hook`, a weak function pointer
that `actors.c`'s trampoline calls instead of `fpr_exit` when set. The
top-level boot never sets it (unchanged behavior: `fpr_exit` halts as
always); the process entry sets it before scheduling.

### 3. Multi-arena growth in `fpr_alloc` (runtime.c)

Each `fpr_hart_t` gained a SECOND (hp, heap_end) pair is not needed --
instead, on bump-arena exhaustion, `fpr_alloc` now calls
`fpr_request_more_memory(bytes)` (a per-process function pointer set by
`fpr_process_entry`, NULL for the top-level boot -- exhaustion there is
still a hard panic, unchanged). If granted, the hart's arena pointer
retargets to the new block and the allocation retries once. This is a
small, real change: the existing segregated free-list "slab" behavior
(the `buckets[512]` array, already a size-classed slab allocator in
spirit) is untouched; only what happens when the BUMP POINTER hits the
end of its current arena changes.

On the LOADER side (System.qa), `request_more_fn` is a closure over
"this process's buddy allocator handle": each call does one
`buddy_alloc`, hands back (ptr, size), or returns NULL when the arena
itself is exhausted (a real, user-visible out-of-memory, not silently
swallowed).

## Building a process app

    make system.elf                                     # 1. the host, defines the slot
    tools/build-process-app.sh apps/hello_proc.fpr \
        apps/HelloProc.toml apps/HelloProc.qa rv64      # 2. link app AT that slot, wrap
    make system.elf                                     # 3. re-link: bakes the .qa in

The two-pass shape is inherent, not clumsiness: the app must be linked
against the host's process-arena address, and the host embeds the
resulting `.qa` in its own rodata. `build-process-app.sh` reads
`_proc_arena_start` out of `system.elf` with `nm` rather than
hard-coding it, and adds `sizeof(uw)` -- `buddy_alloc` returns a
pointer PAST its own header, so the first allocation lands at
`arena_base + 8` (rv64) / `+ 4` (rv32), not at `arena_base`. Getting
that wrong is not subtle: `fpr_elf_load` rejects the image outright
with "PT_LOAD segment falls outside the target slot".

An app opts in via `loadMode = "process"` in its manifest. Anything
else (or omitting it) keeps the co-compiled name-dispatch path, which
is what TUIAppLauncher/TUINotes/TUIClock use.

## Three bugs this design walked into (recorded, because they are the
## kind that reappear)

1. **`tp` is a physical register, not a variable.** `fpr_process_entry`
   points `tp` at the process's own hart struct so its `fpr_alloc`
   works. It must restore the caller's `tp` before returning, or every
   subsequent `fpr_alloc` in System.qa reads through `tp` into the
   freed process slot. The symptom is a spurious "heap exhausted" in
   the HOST, arbitrarily later, with nothing pointing back at process
   loading. `g_heapUsed` hides it too (it walks `fpr_harts[]` by index,
   not via `tp`), so heap introspection looks healthy while allocation
   is broken.

2. **Same-named functions in two images are two different functions.**
   `fpr_process_result_get()` exists in BOTH the host's and the
   process's copy of `actors.c`. The host calling it reads its OWN
   static, never the process's. The result must come back as
   `fpr_process_entry`'s return value.

3. **`substr` on a multi-KB payload is quadratic.** The FPRISC-level
   `substr` builds a string one `strcat` at a time -- fine for a 200-byte
   manifest, fatal for a 49 KB ELF section (a billion-plus transient
   bytes; it exhausts the heap before loading anything). Hence
   `Sys.loadElfAt qa off len`: FPRISC computes the offsets, C reads the
   bytes in place. Payload bytes must never round-trip through
   FPRISC-level string building.

## What this does NOT do (stated plainly)

- No memory protection between System.qa and a loaded process. There is
  no MMU/PMP setup in this runtime; a buggy or hostile process can
  still write anywhere. Isolation is a separate, larger feature.
- Single concurrent process slot. The buddy allocator can hand out
  many blocks, but only ONE fixed link address (`PROC_SLOT_BASE`) is
  wired up and tested this pass. Multiple concurrent slots need either
  N separately-linked app builds (one per slot address) or true
  relocation -- both are natural extensions of this design, not
  redesigns of it.
- No SMP inside a loaded process (single hart). The host (System.qa)
  can still be multi-hart; the guest process runs on whichever hart's
  loader thread called into it.
- Memory growth is a direct, synchronous C function-pointer callback
  (real, tested), not yet an async actor message crossing between the
  host's and guest's SEPARATE actor systems (they are genuinely
  disjoint instances, each with its own mailbox/ARC tables). Making it
  a true message send needs an inter-process message bridge -- a
  natural next step once this synchronous version is proven.
- Growth blocks leak on process exit. `Sys.loadElfAt` frees the
  process's initial slot, but every block handed out later by
  `loader_grow_memory` is untracked and never returned to the buddy
  allocator. Measured: HelloProc (100k-element list, 6 growth events)
  leaves ~3 MiB of the 32 MiB arena unreclaimed per run. Fixing it
  needs a per-process block list -- deliberately not done here, since
  it interacts with the ownership question above.
- A process-loaded app gets NO capability set. `fpr_process_entry`
  spawns actor 0 exactly like the top-level boot does: a bare `main`
  with no arguments. So the permission grants the user just approved
  are NOT handed to it, and it reaches the HAL directly through
  whatever it links. `Apps.run` (name dispatch) DOES pass `caps`. This
  is the single biggest gap between the two paths and the obvious next
  piece of work: the process ABI needs to carry the granted
  capabilities, or the permission model stops meaning anything for
  process-loaded apps.
