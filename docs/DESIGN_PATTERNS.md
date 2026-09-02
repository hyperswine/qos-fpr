# DESIGN_PATTERNS.md — FP-RISC and Sol

Conventions that are fixed. The goal is that once these are learned, most
"should it be this way or that way" questions stop being questions. Anything
not listed here is situational and can be decided case by case.

## 0. Meta-rules

- **Decide a model, then be consistent.** The primary design question is
  always "what is the actual model M?" How it is spelled is secondary, as long
  as it is consistent with everything else and has no obvious defects
  (redundant or overlapping names, argument orders that don't follow the same
  scheme).
- **Pareto set → pick one → stick with it.** When several candidate models are
  non-dominated, enumerate them, choose one (randomly is fine), and commit. Do
  not reopen the decision without a new dominating argument.
- **Recognition over recall.** Docs, examples, and content-addressed search are
  the memory. Naming and features must be strict enough that a half-remembered
  name resolves by pattern.

## 1. Naming and call form

- **`Module.func` is the only call form** for builtins and APIs. No
  `object.method`, and never a mix of both (Elm, not Python).
- Modules are nouns (`List`, `Vec`, `Memory`, `MVU`, `FPRLive`); functions are
  verbs or verb-phrases.
- No two functions in scope should overlap in meaning. If two names could
  plausibly describe the same operation, one of them is wrong.

## 2. Argument order

One scheme for everything:

```
Module.func  <function>  <secondary data> <initializer> <main data>
```

- **Higher-order functions:** function first, then the collection, then any
  initializer last. `List.foldl f z xs` — the main data sits just before the
  end so it pipes: `xs |> List.map f z`
- **Two-collection functions** (`zip`, `merge`, `diff`): the "main" data is
  last, the other operand before it.
- **Configs** are the first argument after the function argument (if any) and
  before data; see §3.

## 3. Configs and secondary parameters

- **Definition.** A parameter is *secondary* if it does not change the core
  command or state machine of inputs → outputs, but shifts or adds to it:
  verbosity, caching, logging, retries, limits, formatting. A parameter that
  changes the *type* of the output is primary and gets its own positional slot.
- **All secondary parameters go in one record**, and the record contains the
  *entire* set of configs for that function. No optional trailing args, no
  keyword args, no half-in-record/half-positional splits.
- Every configurable function has a `Module.defaults` record; callers write
  `{ Module.defaults | verbose = True }`.

## 4. Application structure

- **MVU is the only application framework.** Do not reinvent MVU or introduce
  another architecture. Every app is `MVU.serve { init, update, view }`.
- **`view` returns a scene, not a widget tree:** `Scene2D`, `Scene3D`, or
  `None`. This is what lets one model cover web apps, desktop apps, games, and
  headless/remote services (which return `None`).
- **Remote:** `FPRLive` + MVU is the default and recommended way to develop
  and run anything remote — client/server apps, live sessions, telemetry.
- **Local:** local MVU is the recommended way for local apps.
- Effects and subscriptions are expressed as data returned from `update`, not
  performed inside it. If you find yourself needing a second lifecycle, the
  scene type or the command type is what should grow, not the framework.

## 5. Writing code

- **Prefer builtin composition to helpers.** Before writing a helper function, use the
  content-addressed search over docs, examples, and modules; copy or follow an
  existing pattern directly in place - dont spam helpers everywherem but still keep everything concise. A missing example for a feature is a bug in the corpus.
- **Recursion schemes and `|>` wherever possible.** Explicit recursion is the
  exception and should be justifiable on the spot.
- Examples are executable and part of the test sweep; they are the spec.

## 6. Open / to be pinned (proposed, not yet decided)

- A fixed verb vocabulary: one of `get` / `find` / `lookup`; one of `make` /
  `new` / `create`; etc.
- A rule for `Maybe` vs `Result` vs panic as the failure channel.
- Whether `Module.defaults` is the exact name, and whether config records are
  open or closed to extension.
