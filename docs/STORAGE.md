# QOS storage: the append-only log as the system's one durable substrate

The default setup HAS a disk (`make run-system` attaches `disk.img`).
Everything durable lives in ONE append-only page log -- .qa app
archives, app kv streams, general files (text, binary blobs, toml),
and, in the planned elaboration, paged-out actor chunks. A boot with
no disk degrades: System.qa says so once and the storage services
answer `Err "no disk"` -- absence is data, not a fault.

## The layers

    blk.c (HAL)          pages, full stop: blkPages / blkRead / blkWrite
    mods/qlog.fpr        the QLOG format + the STORAGE ACTOR (a `use`
                         module -- separately compiled, hash-pinned in
                         system.fpr, same on-disk format as diskfs.fpr)
    System.qa            spawns the storage actor, owns the URL space,
                         gates access through capabilities

The format is diskfs's, unchanged: page 0 is `QLOG <head>`; a record
is a header page (`QREC <npages> <paylen> <url>` or a `QDEL`
tombstone) followed by whole payload pages. Nothing is ever rewritten
except the superblock head; recency is position. A raw dump of
disk.img reads like a session transcript.

## Two read disciplines over the same log

- **readLatest** (tag 1) -- the FILE read: the newest live record for
  a url wins. This is what a .qa, a text file, or a binary blob wants.
- **replayAll** (tag 3) -- the EVENT-SOURCE read: concatenate every
  live record for the url in log order; a tombstone resets the stream.

That second discipline is Sol's `Persistent` model mapped onto the
log. In Sol, `Persistent x` fields make the MSG (not the model)
durable: updates that touch a persistent field append the msg to an
append-only file, and startup replays the log by folding `update`.
Here the app's kv url IS that msg log: `svcKvAppend` logs one msg as
one QREC, `svcKvReplay` hands back the stream, and the app folds its
own update over it -- event sourcing with the app as the runner. A
`Persistent a` wrapper in the prelude plus a generic MVU runner that
diffs the persistent projection (Sol's Web.hs trick) is the next
elaboration; the on-disk shape is already exactly right for it.

## URL addressing and capability scoping

Every durable thing has a url. The scheme in force:

    apps/<Id>.qa               an installed app (overrides shipped rodata)
    apps/<Id>/<Id>.kv          that app's persistent kv msg stream
    sys/boots                  System.qa's own boot beat (one msg per boot)

An app never names a path. Its kv url is built by System.qa FROM THE
CAPABILITY (`kvUrl caps` = `apps/{capId}/{capId}.kv`), so an app
physically cannot address another app's stream -- scoping is
structural, not checked. `/services/storage` (write) is the manifest
permission; TUINotes ships with it optional and adapts on denial
("notes are session-only"). Verified in the suite: the two-boot
persistence regression saves notes on boot #1 and replays them on
boot #2 of the same image.

`.qa` install: `launch` asks the storage actor for `apps/<id>.qa`
first and falls back to the rodata registry -- disk is the install
target, rodata is the shipped set. STATUS UPDATE: the .qa apps are now
SEPARATE from System.qa's image and seeded into the initial disk by
tools/mkdisk.py (each as its own QLOG record, plus an `apps/index`
record for discovery).  System.qa lists apps from the disk index and
reads each .qa off the log ON DEMAND at launch -- verified end to end
including HelloProc, whose real ELF loads from disk into the process
slot.  Rodata remains only as the diskless fallback.

## The storage actor (and where it's going)

One actor, spawned by System.qa at boot, owns `(dev, head)` and is the
single writer -- which is the whole FCommit discipline for free.
Requests are 4-tuples `(replyTo, tag, url, payload)`, replies are
builtin `Ok`/`Err` Results (tid 3 -- stable across separately
compiled units), so `receiveRes` is the client's await.

Reads currently STREAM the log (index-free: correct first). The
elaboration path, in order, is the diskfs design promoted:
1. an in-memory index rebuilt by one boot scan (FSApp's shape);
2. lazily spawned per-url URActors -- "actors of System.qa that
   manage each file" -- with the vfs non-blocking forward discipline
   (original replyTo travels, the storage front never blocks);
3. GC: a sweep that copies live records forward and truncates -- the
   log's latest-wins semantics make liveness a per-url predicate, so
   GC needs no reference tracing, only the index.

## Planned: paging actors to disk (/actorchunks)

Under memory pressure, an actor (or a loaded process) that has
YIELDED or is blocked can have its **stack and heap copied out as one
chunk** to a reserved partition of the log mounted at `/actorchunks`,
and that memory reclaimed. Design points, fixed now so the runtime
work has a target:

- **The mailbox stays in memory.** Per-sender SPSC channels are the
  actor's identity to every sender; senders must be able to publish
  and the wake protocol must be able to fire without touching disk.
  The paged chunk is (stack, heap arenas, saved context) -- the parts
  only the actor itself reads.
- **Same log discipline, no compaction.** A page-out appends a chunk
  record (`QCHK <npages> <len> actorchunks/<actor-id>` in the QLOG
  grammar); a page-in reads the LATEST chunk for that id and appends
  nothing. Chunks are dead the moment the actor is resident again or
  exits, so GC is the ordinary latest-wins sweep -- and because
  chunks are short-lived and whole-record, there is nothing to
  compact, only pages to reclaim.
- **Page-in trigger** is the wake path: a sender's CAS(BLOCKED->READY)
  on a paged actor ships it to its owner hart as today, and the hart
  loop's dequeue notices the PAGED status and re-reads the chunk
  before switching in. Fuel preemption never pages (the actor is
  READY); only yield/block states are candidates.
- **What makes this cheap here**: per-actor slabs (the memory-model
  direction) make "the actor's heap" a copyable extent list instead
  of a liveness question, and the append-only heap discipline means
  a chunk is internally consistent by construction -- no write-back
  ordering to reason about. Actor paging is the payoff case for the
  slab refactor, and should land after it.
