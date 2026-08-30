# Source spans: the staged plan

Post-parse diagnostics were location-free strings — the single biggest
usability gap, and the one that gets more expensive to fix every
month.  The fix is staged so each step ships value without touching
the AST until the machinery to do that safely exists.

## Step 0 — span-proof module identity  [LANDED]

`hashAST` (Modules.hs) hashes the POSITIONLESS tree: `stripPosTops`
(FPRISC.hs) erases any future source-position node before hashing.
Today it is the identity, so the hash string is bit-compatible with
every existing pin (the sketch-tier check-all leg's printed pin is
the regression test); from now on spans can never churn a pinned
module hash.

## Step 1 — bind-level anchors, no AST change  [LANDED]

Every diagnostic carrying the `in NAME:` prefix — all Infer errors
(the per-clause prefixer), every linearity error (lcheck now prefixes
its body/guard errors too) — is anchored to `file:line:` of NAME's
definition by the error sinks (Compile.hs, Sol/Main.hs):

* top declarations start at COLUMN 0 by the grammar, so `bindAnchors`
  (FPRISC.hs) finds a bind's line by scanning for its name at line
  starts — the signature line when one precedes the clauses, which is
  the better anchor anyway;
* spliced modules anchor to THEIR files: Modules.hs computes each
  unit's anchors at parse (ModUnit.muAnchors) and qualifies the keys
  with the unit hash, so `in leak@abc123:` resolves to the module
  source, not the root;
* struct-expanded and generated binds have no col-0 definition and
  simply pass through unanchored — graceful, never wrong.

check-all's "spans" leg holds the contract: a type error anchors to
the sig line, a linearity error to the bind, a module bind to its own
file.

## Step 2 — statement precision via a locator  [NEXT]

Most error texts name a token (a variable, an operator, a field).
Given the bind's line range (its anchor to the next top's), scan for
the named token and report file:line:col; say so when ambiguous.
Printer-only, still no AST change.

## Step 3 — real spans, bounded  [LATER]

One wrapper node `SMark !Int SExpr` at BLOCK-STATEMENT and CASE-ARM
granularity, ids into a side table of parser positions.  Bounded
churn: the traversals are shared now (one desugar, transformE/EP),
each pass skips SMark in one place, and step 0's strip keeps every
pin intact.  Infer's marker-site machinery (newSite / markerPrefix)
is the in-tree model for threading ids and rewriting them out; holes
and operator sites get real spans the day the wrapper lands.

Not chosen: a span field in every constructor.  Best precision, but
it touches every pattern match in every pass at once — statement
granularity via the wrapper reaches most of the value for a fraction
of the churn, and can widen later if it earns it.

## The LSP tie-in

The `Name -> (file, line)` anchor map plus `fpr typecheck`-style
check-only runs is exactly what an LSP diagnostics provider consumes
(the NOTES.txt cache idea); step 1 is deliberately its first day.
