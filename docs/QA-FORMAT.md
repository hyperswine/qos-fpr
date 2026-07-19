# The `.qa` archive (QOS App Archive)

A `.qa` is the QOS analogue of macOS `.app`, drastically simpler. It is a
flat archive of a manifest plus a bundled executable, with a fixed
section table. Design goals: (1) statically inspectable before anything
runs, (2) the permission set is *in* the archive and cannot be separated
from the code, (3) trivially parseable by the FPRISC launcher with only
`charAt`/`String.len`/`strcat`.

## On-disk layout (one contiguous byte string)

    QAR1\n                       magic + format version, newline-terminated
    <section-table>                one line per section, blank line ends the table
    \n
    <section payloads back to back>

Section-table line:  `NAME OFFSET LENGTH\n`  (decimal, space-separated).
OFFSET is relative to the first payload byte (i.e. just past the blank
line that ends the table). Two sections are defined in v1:

    MANIFEST   the app manifest (see below)
    ELF        the bundled QOS RISC-V ELF (the compiled app image)

Unknown sections are ignored by design, so v2 can add ICON, SIG, etc.
without breaking a v1 launcher.

## The manifest (a minimal TOML subset)

Only what the launcher needs; a real TOML lib is overkill on bare metal.

    name = "TUI Notes"
    id = "TUINotes"
    entry = "tuinotes_main"          # symbol the co-compiled app runs from
    version = "1"

    [permissions.required]
    "/services/keyboard" = "read"
    "/services/display"  = "write"

    [permissions.optional]
    "/services/net" = "write"

Rules the parser enforces:
- lines are `key = value`, values are `"quoted"` or bare tokens
- `[section.subsection]` opens a table; keys until the next `[` belong to it
- a permission key is a service URL, its value is the requested mode
  (`read` / `write` / `readwrite`); the launcher matches on (url, mode)
- everything under `[permissions.required]` is COMPULSORY: if the user
  denies any one, the app does not run and the launcher shows
  "Cannot Run Application without all required compulsory Permissions"
- `[permissions.optional]` grants are asked for too, but a denial there
  does not block launch; the app simply won't be handed that capability

## The launch contract

1. System.qa's launcher reads `/apps/<Id>.qa`, parses the section table,
   then the MANIFEST section.
2. It presents every required + optional permission to the user.
3. If all *required* permissions are granted -> the app is launched:
   the launcher resolves `entry` to a capability-parameterized closure
   and runs it inside the caller's process, passing ONLY the granted
   capabilities (URL-addressed handles to System.qa services).
4. If any required permission is denied -> refusal message, no launch.
   Re-launching repeats the whole flow from step 2 (grants are not
   remembered in this PoC -- a deliberate simplification; a real QOS
   would persist a grant table per (app-id, permission)).

## Where the ELF fits (and why name-dispatch today)

The ELF section carries the real compiled app. QOS does not yet have a
runtime ELF-in-ELF loader (relocation + a per-FSProcess address space +
an entry trampoline -- a separate build). Until it lands, the launcher
resolves `entry` against apps CO-COMPILED into the System image and
dispatched by name, exactly like the existing `Mod.fn hash name` path.
The ELF bytes are still bundled, still hashed into the archive, and the
seam where the loader plugs in is a single message (`LaunchElf`) in
System.qa -- so the swap from name-dispatch to true loading touches one
function, not the architecture or any app.

## Status notes (post launch-path work)

`loadMode = "process"` marks a real dynamically loaded ELF; its
`entry` field is vestigial (`"n/a"` by convention -- the ABI is
`fpr_process_entry`, docs/PROCESS-LOADING.md, which now carries the
serialized capability grant).  For name-dispatch apps `entry` still
names the co-compiled symbol; that mode is deprecated and dies when
the TUI apps finish converting.
