# Vec — the compute-bound default

`Vec a` is meant to be the type you reach for without thinking when
code is compute-bound: a growable array that stores records as
columns, fuses adjacent passes, and turns ordinary functional element
functions into dense column loops.  You should never write
`Vec.axpb` or `Vec.iadd` by hand.  `Vec.map (fn v -> a * v.x + c) vs`
is the API.

This file records the DECISIONS, not the code.  Where a decision was
contested, the losing option is named too, so a later reader knows it
was weighed rather than missed.

## 1. Representation: VList blocks, not realloc
A Vec is a directory of geometrically growing blocks (a VList), not
one slab that doubles by copying.  Push is amortized O(1) with NO
reallocation and no copy of live data, which matters more here than
in C++: the allocator is a bump+freelist per actor, so a realloc
strategy would churn the largest size classes exactly where the
freelist ceiling bites.  Iteration is per-block contiguous, which is
all the SIMD tier needs.

Consequence, accepted: indexing is a directory hop plus an offset,
not a single multiply.  Bulk operations amortize it away because they
walk blocks, and per-element random access is not the workload Vec
exists for.

## 2. Conversion from List is cheap and explicit

`List a` stays the cons-cell list — one slab per constructor, the
Haskell-shaped structure you want for symbolic and recursive code.
`Vec.fromList` / `Vec.toList` convert.  Nothing converts implicitly:
the cost is a traversal and the user should see it.

## 3. SoA by default for records

When the first value pushed into a Vec is a record, the vector takes
one COLUMN PER FIELD.  Records carry their field count in the value
header (`var`), so a record value is self-describing and the runtime
can pick the layout without a type-directed hint — this is what makes
"SoA by default" real rather than aspirational.

Bounds, stated: up to 8 fields (`VMAXCOLS`); wider records fall back
to boxed rows.  The layout is fixed by the FIRST push and every later
push must match it.  Storage and specialization have separate bounds:
the AOT record-map dualizer currently specializes outputs of up to 4
fields, so 5..8-field records are still SoA but their maps use the
generic row-by-row tier unless another specialization accepts the site.

### Record projections and updates are the lens surface

The record syntax is the element-function API; vectors do not introduce
separate column getters or setters:

  p.x                          # getter
  {p | x = p.x + 1}           # functional setter
  {p | pose.x = p.pose.x + 1} # composed nested setter

Projections infer through open rows, so a function that reads `.x` can
accept any record shape containing `x`.  An update evaluates its source
once and rebuilds the records along the named path from the leaf outward;
untouched fields are projected from the source.  This is lens-like
lowering, but there is no first-class `Lens` value and no mutable
`p.x = value` expression syntax.  `=` introduces bindings; the supported
setter spelling is `{p | path = value}`.

After lowering, a flat update has the same `CProj`/`CMk` shape as an
explicit record reconstruction.  Therefore a same-shape arithmetic
update inside `Vec.map` can dualize directly against columns and can
participate in adjacent-map fusion.  `tests/fuse.fpr` executes this path.
Nested record construction inside an output field currently makes the
AOT dualizer decline, so a nested-path update remains semantically correct
but runs through the reported generic tier.

## 4. Element functions get DUALIZED — no special vocabulary

The core promise.  A function passed to a `Vec.x` operation is
compiled against the column representation instead of against boxed
rows:

    Vec.map (fn s -> s.age + 1) students
      -- becomes, per column: out[i] = age[i] + 1

The compiler walks the element function to its record construction and
produces one unboxed dual per OUTPUT field, whose arguments are the
input columns it actually reads (plus captured scalars).  The loop
then runs in place over the columns with no boxing, no allocation, and
no `fpr_apply` per row.  `Mat4 * Vec4` is the same mechanism: the
operator elaborates to field arithmetic, which dualizes to axpb-shaped
column loops.  The user never names axpb.

When dualization does NOT apply the site still WORKS — it runs the
generic apply tier row by row — and the compiler SAYS SO:

    vec note: Vec.map over `f` runs in the GENERIC apply tier ...

Silence used to be the bug: a whole class of "specialized" loops was
emitted and never executed for ten rounds because nothing reported the
fallback.  A declined site is a performance fact the compiler owes the
programmer at compile time.

Known genuine declines today: element functions that pattern-match or
otherwise reconstruct opaquely, nested record updates/construction inside
an output field, record FOLDS (named element fns decline too, not just
lambdas -- fold duals are scalar-only), AOT record-map outputs over 4
fields, and boxed records over 8 fields.

Target caveat: on x64 (qosp on x86-64) the ENTIRE specialization tier
is off -- SysV has only 6 callee-saved registers and the spec loops
need s6+ -- so every Vec site runs the generic apply tier there, and
because the decline scan is gated on the same flag, x64 compiles emit
NO vec notes at all: the fallback is silent on exactly the target
where it is total.  a64 and rv64 keep the tier.  tests/fuse.fpr's
in-place witnesses accordingly hold on bare-metal/a64, not on qosp-x64.

## 5. Fusion by default for adjacent passes

`Vec.map f (Vec.map g v)` — and the let-pipeline spelling when the
intermediate's only use is the immediately following map — compiles
to ONE pass over a synthesized composite.  Fused record pipelines
compose at the plan level: g's output field k is f's input column k,
so f's column reads substitute with g's field-k dual bodies.

Soundness comes from linearity, not from an effect analysis: both
passes mutate the same columns and return the same reference, so a
fused single pass leaves byte-identical final state and the
intermediate was never observable by anyone.

Bounds, stated: one captured side per fused pair; a 3+ chain fuses its
outer pair per compile (fixpoint is a follow-up); `Vec.fold` of a map
does NOT fuse, because fold returns the vector it was given and the
map's writes remain program-visible afterwards — that needs a
write-back fold variant, not a rewrite.

## 6. Filter is EAGER COMPACTION — decided, not defaulted

`Vec.filter` slides the kept rows down IN PLACE with two cursors and
shrinks `len`.  Zero allocation, and the vector stays dense.

The alternative — tombstones plus a bitmask plus incremental GC on
later `Vec.x` calls — was considered and rejected FOR THIS MACHINE:

  * Linearity means there is no sharing to preserve, so the copy that
    tombstones exist to avoid does not exist here.  A compacting
    filter allocates nothing.
  * Every downstream map/fold/zip/axpb would otherwise have to carry a
    mask through the SIMD tier.  Masked lanes poison exactly the loops
    Vec exists to make fast, and turn one dense pass into a
    predicated one on every target that lacks lane masking.
  * Incremental GC re-introduces unpredictable work into operations
    whose cost is currently a function of length alone — bad for a
    system with a WCET story.

Tombstones win when filters vastly outnumber scans over the same
vector.  That is not the games/scientific workload Vec is aimed at.
If a workload ever demands it, the right shape is a separate
`Vec.mask` view type, not a mode switch inside `Vec a`.

Blocks past the new length stay attached and recycle with the vector:
a VList does not return capacity early.

## 7. Linearity is the contract that makes it all sound

`Vec a` is linear.  In-place mutation, fusion, and compaction are all
licensed by single ownership — no structural sharing, no Rc traffic
per element operation.  Operations consume the vector and hand it
back (often inside a tuple, e.g. `Vec.fold` returns `(acc, vec)`).

Using a Vec non-linearly is a compile error, not a silent copy.  This
is deliberate: a silent deep copy of a compute-bound array is the
single worst thing a "helpful" runtime could do here.

Enforcement boundary, honestly stated (audit finding): the linearity
counter takes a variable's linear shape from its DECLARED signature
(and from linear PAP captures), not from inference.  A function with a
`: Vector -> ...` sig gets the exactly-once check; an UNANNOTATED
function -- `main` included -- can double-use or double-free a
let-bound Vec and compile "linearity OK" (the misuse then runs
silently).  Inference knows the type; the checker does not consult it
yet.  Until that lands, a `: ... Vector ...` sig on anything touching
a Vec is what buys the guarantee.

## 8. Tier structure

    declared float columns ('i'/'d'/'s'/'b')   -- widths chosen, not guessed
    dualized column loops (map / fold / mvmap) -- the default fast path
    C prim tier (axpb, zip*, gather, blend...) -- what the duals lower onto
    generic apply tier                         -- correct, reported, slow

Each tier is a fallback for the one above, and every fall is either a
compile-time note or a declared choice.

## Open, in agreed order

1. write-back fold (unlocks fold-of-map fusion)
2. fusion fixpoint for 3+ chains
3. record -> scalar projection maps (layout-changing: new 1-col output)
4. lambda-fold duals (the main remaining genuine decline)

## RVV status (audit, 2026-08)

The `--rvv` lowering (strip-mined `vsetvli` loops, `vle64/vadd.vv`
folds) is FUNCTIONALLY CORRECT: tests/fuse.fpr passes all seven
witnesses under `qemu -cpu rv64,v=true` when built with it.  But the
path is dormant and unshipped:

  * no Makefile rule passes `--rvv`; the default QEMU cpu has no V
    extension and ARCHFLAGS omits `v`, so the C prim tier compiles
    scalar on rv64 too (its autovectorization is real only on hosted
    x64/a64 baselines: adds/compares/blend take SSE2/NEON lanes,
    64-bit multiplies stay scalar below AVX-512)
  * `--rvv` emits a strong `fpr_rvv_enable` into the program AND into
    every module unit compiled with the flag, so any program that uses
    the prelude fails to link (multiple definition) -- the enable
    shim needs to move to the runtime or become link-once before the
    flag can ship
