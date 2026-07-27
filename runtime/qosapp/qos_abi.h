/* qos_abi.h -- the QOS Portable host <-> app ABI (docs/QOS-PORTABLE.md).
 *
 * Shared by runtime/portable (the qosp host, hosted C with libc) and
 * runtime/qosapp (the app-side runtime, freestanding).  This is the
 * bootstrap design's HAL contract realized on a host OS: "the HAL is a
 * table delivered as a C pointer, called like regular C functions" --
 * the app image contains NO libc and NO syscalls; every effect it can
 * have on the world goes through this table, and the table's entries
 * are the image's runtime capability surface (the link-time fpr_g_
 * import set remains the static one, exactly as on bare metal).
 *
 * Only fixed-width C ABI types cross the boundary: the host and the
 * app are separately linked images that happen to share an address
 * space, the same relationship System.qa has with a loaded process on
 * virt.  No V values cross it in v1 -- both sides build their own.
 */
#ifndef QOS_ABI_H
#define QOS_ABI_H

#include <stdint.h>

#define QOS_ABI_VERSION 1u

/* ---- the address plan (linux-x86-64) --------------------------------
 * The host is linked non-PIE (default 0x400000 text); the arena is a
 * fixed mmap well away from it.  The image SLOT is the arena's first
 * QOS_SLOT_SIZE bytes, reserved via buddy_reserve_range -- so unlike
 * build-process-app.sh there is no +wordsize header bias to extract
 * from a symbol table: the link address is a CONSTANT, and an app.qa
 * built today loads under any qosp built tomorrow.  Everything after
 * the slot is the buddy arena that growth grants come from. */
#define QOS_ARENA_BASE 0x40000000ul /* 1 GiB */
#define QOS_ARENA_SIZE (256ul << 20)
#define QOS_SLOT_SIZE (16ul << 20) /* matches link-app.ld's SLOT LENGTH */
#define QOS_SLOT_BASE QOS_ARENA_BASE

/* ---- the HAL table --------------------------------------------------
 * The entries mirror the obligations runtime/posix's co-compiled HAL
 * satisfies (hal.c, stubs.c/net.c), so the SAME FPRISC surface --
 * console via the uart register model, mtime via the clint model,
 * `device "name"` discovery, netPoll/netRead/netWrite/netClose --
 * works unchanged; only the dispatch is a table call instead of a
 * link-time bind.  Nullable tiers (gfx) are NULL when the host was
 * built without them; the app-side shim panics honestly on use,
 * matching stubs.c's missing-capability behavior. */
typedef struct {
  uint64_t version; /* QOS_ABI_VERSION */
  uint64_t nharts;  /* informational; v1 apps are single-hart */

  /* console + machine */
  void (*putc)(char c);
  void (*poweroff)(int code); /* terminates the "machine" (the host) */
  void (*wfi)(void);          /* idle pacing for the app's hart loop */

  /* the register tier: uart/clint pseudo-bus, same addresses as the
   * posix HAL's model (runtime/portable/haltab.c holds the dispatch) */
  uint64_t (*mmio_read)(uint64_t addr, uint32_t width);
  void (*mmio_write)(uint64_t addr, uint64_t v, uint32_t width);

  /* device discovery by name: 1 + *base filled, or 0 = unknown (the
   * app-side shim turns 0 into the same honest panic virt/posix use) */
  int (*dev_lookup)(const char *name, uint64_t len, uint64_t *base);

  /* net: the posix contract verbatim (one connection, poll-driven).
   * poll: 0 no conn, 1 open, 2 open+rx.  read drains into dst, returns
   * bytes.  write is blocking-full, returns len.  close keeps listening. */
  int64_t (*net_poll)(void);
  int64_t (*net_read)(char *dst, uint64_t cap);
  int64_t (*net_write)(const char *src, uint64_t len);
  int64_t (*net_close)(void);
} qos_hal_t;

/* ---- the memory-growth grant ---------------------------------------
 * Layout-identical to fpr_grant_t (fpr.h) on both sides -- kept as its
 * own named type here so the header stands alone for the host build. */
typedef struct {
  void *ptr; /* NULL = denied */
  uint64_t size;
} qos_grant_t;

/* ---- the boot record ------------------------------------------------
 * Everything the Loader stage hands the app, in one versioned struct
 * (the ABI can grow by appending fields; abi_version gates readers).
 * caps is System.qa's serialized grant format unchanged:
 * "appid\nurl mode\n" lines (docs/QA-FORMAT.md) -- the FPRISC side
 * reads it via Sys.caps and enforces its own gate, equal strength to
 * the bare-metal process model since neither has hardware behind it. */
typedef struct {
  uint64_t abi_version;
  const qos_hal_t *hal;
  void *heap_base; /* the app's first slab: slot space past the image */
  uint64_t heap_size;
  qos_grant_t (*grow)(uint64_t want_bytes); /* buddy grants from the host */
  const unsigned char *caps;
  uint64_t caps_len;
  /* the storage syscall channel, tag-compatible with System.qa's
   * trampoline (process.c): 2 = kv append, 3 = kv replay */
  int64_t (*syscall_fn)(uint64_t tag, const char *pay, uint64_t len,
                        char *out, uint64_t outcap);
} qos_boot_t;

/* ---- the entry ------------------------------------------------------
 * ENTRY(qos_app_entry) in link-qosapp.ld: the loader reads it from
 * e_entry, the way any ELF loader would.  A plain callable function,
 * same philosophy as fpr_process_entry -- we are being called by an
 * already-running host, not booting hardware.  The app's main-actor
 * result is RENDERED (str) into result_out (truncated to result_cap,
 * NUL-terminated) rather than returned as a V: the host has no FPRISC
 * runtime to interpret a V with, and the string form is what it would
 * print anyway.  Returns 0 on clean completion. */
typedef int64_t (*qos_app_entry_t)(const qos_boot_t *boot, char *result_out,
                                   uint64_t result_cap);

#endif /* QOS_ABI_H */
