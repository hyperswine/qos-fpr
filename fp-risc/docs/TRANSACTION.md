# Sol transactions: the SCRIPT is the transaction

The unit of atomicity in the HostedBytecode profile is the **whole
script run**, not the individual `>` eval.  This was always what the
runtime did; this document makes it what the design *says*.

## The model

    fpr sol script.sol
    ├── snapshot        one read view of the world, taken at entry
    ├── > eval 1        ─┐
    ├── > eval 2         │  sequential PHASES of one transaction:
    ├── ...              │  same snapshot, same write journal
    ├── > eval N        ─┘
    └── commit          ONE atomic commit of the whole journal — or
                        nothing at all

Consequences, each of which is checked in the sweep:

1. **Abort is total.**  A panic in phase N unwrites phases 1..N-1.
   There is no partial state: either the whole script's effects land
   or none do.  (tests/txnabort.sol: phase one writes a file, phase
   two divides by zero, the file must not exist afterwards.)

2. **Retry is whole-script.**  A commit-time conflict (another
   transaction touched the read set) re-executes the ENTIRE script
   against a fresh snapshot — not the conflicting eval.  Phases may
   observe each other's in-transaction writes, so re-running a suffix
   would be unsound; re-running everything is both correct and simple.
   (`SOL_FORCE_RETRY=n` demonstrates: the script's phases all run
   n+1 times, the commit lands once.)

3. **`>` is sequencing, not scoping.**  Multiple evals exist for
   reading order and for interleaving with top-level definitions.
   They share one journal; splitting a script into more evals never
   changes what commits.

4. **Escapes are named.**  `realtime` blocks step outside the
   transaction (their effects are immediate and unjournaled); the
   runtime prints a notice when a run used one, because the word
   "atomically" in the commit line is only true of the journaled set.

## Why one commit and not one per eval

Per-eval commits would make `>` a semantic boundary: moving a binding
across evals could change crash behavior, and a script could be left
half-applied — exactly the "half-done mess" the fileops example
exists to rule out.  With script-level atomicity, `>` placement is a
readability choice, the crash contract is binary, and the retry story
has one rule instead of a rule per boundary.

## The commit line

    [sol] committed 2 file(s) atomically (whole-script transaction)

names the unit explicitly so a log reader knows the count covers the
entire run.
