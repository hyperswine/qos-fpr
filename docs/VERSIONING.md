# Versioning: `fpr commit`, the .fpr store, and pkgstore

## The model

`mymod.fpr` is a mutable **scratch area** for the id `mymod` — not the
identity-bearing artifact. `fpr commit mymod.fpr` mints the identity:

    .fpr/store/<hash>.fpr     the exact source (content blob)
    .fpr/versions.db          append-only:  name version hash

The hash is the frontend's own pin hash — `Modules.hashAST` over the
pin-normalized tree, a Merkle root over the dependency tree — i.e. the
SAME hash the compiler already prints on every unpinned `use`. So a
committed version is addressable with syntax that already existed:

    M = use "mymod#824900fc92b96248".

Resolution order for a pinned use: the scratch file if its hash still
matches; otherwise `.fpr/store/<hash>.fpr` (with a note). The scratch
file drifting — or being deleted outright — no longer breaks pinned
consumers: the store entry is the identity, the file is a working copy.

## Semver by signature diff (checked at commit time)

* identical hash → no-op.
* prior signature ⊆ new signature (every exported name keeps its arity
  and declared sig; additions fine) → **patch** bump (v1.0 → v1.1).
* anything removed or changed → refused with the exact missing entries
  listed; `--major` mints v(N+1).0.

This subset check is the commit-time face of the LiveReload
row-compatibility question: any minor/patch version is safe to reload
into **by construction** — the check ran before the version could be
addressed by hash. Only major versions carry compatibility risk that
needs explicit runtime handling (`LiveReload` clauses).

## The pkgstore mapping

`.fpr/` is structurally pkgstore (tools' client.py/server.py), one
level down:

    .fpr/store/<hash>.fpr      =  store/<sha256>       (content blobs, dedup'd)
    .fpr/versions.db           =  index.db             (append-only bindings)
    same-version rebind error  =  the 409 invariant    ("bindings are immutable
                                                        — publish a new version")

So `fpr push` against a pkgstore is exactly: POST the blob to /upload,
POST the (name, version, hash) binding to /index — and `fpr pull` is
GET /index/{name} → GET /blob/{hash} → verify → drop into .fpr/store.
No new concepts on either side; pkgstore stays policy-free ("no auth,
no policy, no builds — policy lives on top") and the commit semantics
(signature-diff classification) stay client-side, exactly where
pkgstore's design says policy belongs. Wiring the two HTTP calls is
deliberately left as the seam — the formats already agree.

## Open question carried forward

Whether a dependent (mylib pinning mymod#h) is mechanically forced to
re-commit when its reference changes, or only when its own exported
signature changes as a consequence — old versions remain addressable
forever, so staying pinned indefinitely is at least *coherent*.
