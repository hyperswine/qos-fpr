# runtime/qos — the app-side runtime: QOS is the platform

What a `.qa` process links against when it runs ON QOS: no crt0, no
device table, no scheduler of its own — the kernel image (built from
runtime/core + runtime/virt) already runs all of that. A process gets:

- `proc_entry.c` — the process entry/exit protocol (docs/PROCESS-LOADING.md):
  arena handoff, fpr_is_process routing, result delivery to the loader.
- The syscall-shaped subset of the fpr_g_ contract, satisfied by the
  KERNEL's exports rather than by local implementations: send/receive
  (actors), read/write (URLs through System.qa), spawn.

This is the "codegen against QOS without the kernel stuff" target: the
same compiled code that would link against runtime/virt+core in a
machine image instead links against this thin layer and gets its
capabilities from System.qa's permission grants at launch.

Skeleton status: proc_entry.c is real (HelloProc runs through it);
the clean separated header for the process-facing surface — the QOS
analogue of a libc — is the open item. Today the contract is implicit
in what link-app.ld + the kernel export set resolve.
