# API.md — the FP-RISC (fprc) builtins and prelude

Every builtin below states its intent, shows two different uses, and
notes the likeliest confusion. These are the names the compiler knows
(Infer's builtin environment) plus programs/prelude.fpr; the runtime
side of each is one C entry point (a per-(QOS,HW) constant in the WCET
model — FUEL-RC-ABI.md).

Language conventions that apply everywhere:
- Strict evaluation; all loops are tail calls (TCO to any known
  saturated tail call); every function entry is a fuel safepoint.
- Guards: `f x | e1, p <- e2, e3 = body.` — booleans and pattern
  guards, left to right; a pattern guard binds rightward and for the
  body, and falls through on non-match.
- Tuples are Tup2/Tup3 ONLY — wider shapes are declared constructors
  (a hard compile error says so). Cross-image shapes (messages) rely on
  content-addressed constructor tids: declare the type in ONE shared
  module and import it on both sides.
- 1-based string indexing; no floats (integer Int only).

## Actors

**spawn : (actor -> a) -> actor** — create an actor on the current
hart; its body is `entry(self)`.
```
w = spawn worker;
a = spawn (fn me -> serve me table);
```
Note: the entry closure is ARC-pinned into the child (the one incref
besides send). The child is NOT running yet in any observable order —
send it its config; do not race on globals.

**spawnOn : Int -> (actor -> a) -> actor** — spawn pinned to a hart.
```
st = spawnOn 1 (QLog.actor dsk);
w = spawnOn (imod i (harts 0)) worker;
```
Note: pinning is affinity for locality; the two-tier scheduler can
still DONATE its ready work to the steal FIFO under load, which
updates the owner hart. Pin services that own devices; let compute
migrate.

**send : actor -> msg -> Unit** — enqueue on the per-sender SPSC
channel; promotes the message into shared ARC.
```
u = send boss (n + 1);
u = send (stAct st) (Rpc me tag url pay);
```
Note: MAXSND = 8 distinct senders per actor for its lifetime —
"too many distinct senders" panics. Fan wide traffic through relays.
Send-to-dead is a status read, not a crash.

**receive : actor -> msg** — block for the next message (round-robin
fair across bound channels).
```
m = receive me;
Rpc replyTo tag url pay = receive me;
```
Note: blocking parks the actor; a message arriving CAS-wakes it into
the READY backlog. One mailbox, one message TYPE discipline: a case
that expects Rpc will panic on a stray Tick — envelope-normalize with
an adapter actor instead of widening the case.

**receiveFrom : Int -> msg** — receive from a specific sender id.
```
r = receiveFrom bossId;
ack = receiveFrom 0;
```
Note: sender IDs are the actor ids; use when ordering per-peer matters
and the fair scan would interleave.

**receiveRes : actor -> Result** — receive expecting builtin Ok/Err.
```
r = receiveRes me;
case receiveRes me of Ok s -> s | Err e -> error e.
```
Note: this is the RPC reply half of the storeRpc convention — pair it
with a send of the Rpc envelope.

**yield : actor -> Unit** — cooperative yield (back to the hart loop;
fresh fuel slice on resume).
```
u = yield me;
spinN me n = u = yield me; spinN me (n - 1).
```
Note: takes YOUR OWN handle — `yield 0` panics ("not the current
actor's handle"). Fuel exhaustion yields for you; explicit yield is
for politeness in long CPU loops between safepoint-visits.

**kill : actor -> Unit** / **myself : Int -> actor** — mark DEAD (the
hart loop reaps off-stack) / your own handle.
```
me = myself 0;
u = kill w;
```
Note: myself takes a dummy Int (convention: 0). A killed actor's acb
persists (it IS the value others hold); only stack/slabs reclaim.

## Scheduler (docs/SCHED-MODEL.md)

**schedTau : Int -> Int** / **schedSetTau : Int -> Unit** — read/set
the aging threshold, in machine-wide ADMISSIONS (not time).
```
t = schedTau 0;
u = schedSetTau 4;
```
Note: tau bounds worst-case backlog wait (tau + residents admissions);
lowering it trades randomized-fairness slots for determinism.

**schedMaxWait : Int -> Int** — max observed backlog wait, in
admissions, maintained by the admission path itself.
```
mw = schedMaxWait 0;
u = case mw <= tau + n of True -> print "in bound" | False -> error "!".
```
Note: this is the counter tests pin the MODEL against — it is the
mechanism measuring itself, not a stopwatch.

**schedSteals : Int -> Int** — deterministic-steal count.
```
s = schedSteals 0;
u = print "steals: {schedSteals 0}";
```
Note: machine-dependent count, machine-independent mechanism; 0 under
light load is correct (donation only past DONATE_HI).

**schedSetWeight : actor -> Int -> Unit** — selection weight for the
randomized default tier (>= 1).
```
u = schedSetWeight w 4;
u = schedSetWeight bg 1;
```
Note: weights shape EXPECTED share among un-aged actors only; they
appear nowhere in the worst-case bound — the aged tier ignores them.

## Fuel + harts

**fuelQuantum : Int -> Int** / **fuelPreempts : Int -> Int** — the
per-slice budget (function entries) / total involuntary preempts.
```
q = fuelQuantum 0;
u = print "preempts {fuelPreempts 0}";
```
Note: a fuel unit is "one function entry", not a duration — the
per-function instruction bound is the compiler's `# wcet:` segmax
(FPRC_WCET=1).

**hartId : Int -> Int** / **harts : Int -> Int** — where am I / how
many.
```
u = print "on hart {hartId 0} of {harts 0}";
target = imod key (harts 0);
```
Note: hartId is where you are RIGHT NOW — after a steal-migration a
long-lived actor may answer differently across yields.

## Strings

**str : a -> String** — render any value (interpolation `"{x}"`
desugars to it). `strcat`, `strlen`, `String.len`, `charAt` (1-based
code), `chr` (code -> 1-char string), `substr s i j` (1-based
inclusive), `parseInt` / `toInt`.
```
line = strcat name (strcat "," (str age));
c = charAt s 1;  d = substr s 2 4;
```
Note: charAt out of bounds panics, and `and2` is STRICT — guard bounds
with control flow (`case i <= n of ...`), never with and2, or the
"guarded" charAt evaluates anyway (the TUINotes bug).

**sstr*** — the small mutable string builder: sstrNew / sstrPush /
sstrPut / sstrAt / sstrLen / sstrClear / sstrFromStr / sstrToStr.
```
b = sstrPush (sstrNew 64) 104;
s = sstrToStr b2;
```
Note: for render buffers and per-frame text; not linear-checked like
Sol's BStr — discipline is on you.

## The Vec tier (SoA + SIMD)

Core (mirrors Sol, threading interrogations): Vec.new / push / len /
get / set / map / filter / fold / toList / fromList / free.
```
(n, v2) = Vec.len v;
tot = fstV (Vec.fold plus 0 v2);
```
Note: on rv64, map/filter/fold specialize to RVV kernels when RVV=1
(one fuel decrement per kernel INVOCATION — the G1 caveat).

SIMD family (typed columns, drive raster.fpr/voxel.fpr):
Vec.iota / dup / absv / sar / slice / split / burst / gather / blend /
eqS / ges / maxS / minS / axpb and the zip pairs zipAdd / zipSub /
zipMul / zipDiv / zipMax / zipMin / zipEq / zipLt.
```
xs = Vec.iota 64;                       # 1..64 column
ys = Vec.zipAdd xs (Vec.dup 64 10);     # elementwise +10
m  = Vec.ges xs (Vec.dup 64 32);        # lane mask
sel = Vec.blend m a b;                  # per-lane select
```
Note: these are COLUMN ops — one vector per operand, lanes aligned by
index; `eqS/maxS/minS/axpb` take a Scalar where the name says S.
Masks are 0/1 integer columns, combinable with zipMul.

## Bits + raw device tier

**band / bor / bxor / bitlen / bitsBE / bitsLE** and the HAL macros
**BITSET / BITCLEAR / BITMASK / BITTEST / BITSHIFTL / BITSHIFTR**.
```
flags2 = bor flags (BITSHIFTL 1 3);
on = BITTEST reg 5;
```
Note: the macro forms exist so DRIVER code never writes raw shifts on
MMIO values inline; ordinary arithmetic code just uses the operators.

**device : String -> Int** — look up a HAL device table entry (base
address / handle) by name. **reg32 / reg8** — MMIO register access
through it.
```
clint = device "clint";
v = reg32 clint 0;
```
Note: the ONLY tier allowed to touch addresses; everything above goes
through URL services. On posix these map to the hosted device table
(uart/stdio, clint/CLOCK_MONOTONIC, net/sockets) — same program, no
edits.

**read / write : the URL funnel** — service-routed IO
(`write "/dev/uart" s`, `read "/services/storage/kv"`), dispatched by
System.qa discovery on QOS and by the hosted svc funnel on portable
targets.
```
u = write "/dev/uart" "hi";
r = Svc.read caps "/services/storage/kv";
```
Note: capability-gated where caps exist — an ungranted URL faults
loudly by design, not silently no-ops.

## Block, net, input, GL

**blkPages / blkRead / blkWrite** — the append-only log's page tier.
```
n = blkPages 0;
u = blkWrite p buf;
```
Note: the log is append-only; "overwrite" is append + readLatest-wins
(how permission persistence works).

**netPoll / netRead / netWrite / netClose** — the socket/virtio tier
(httpd.fpr is the reference user).
```
c = netPoll 0;
u = netWrite c resp;
```
Note: poll-shaped, cooperative — no blocking C call holds the hart
(the HAL rule: bounded or yield, never spin).

**inputPoll** — evdev/host keyboard poll. **glInit / glRender /
glSavePpm** — the EGL/GLES tier (gfx builds link dynamic; everything
else static).
```
k = inputPoll 0;
u = glSavePpm "frames/f-{i}.ppm";
```
Note: glSavePpm is how the pixel-md5 determinism checks work — same
scene, same bytes.

## System / process tier

**Sys.init / Sys.harts / Sys.caps / Sys.arenaFree / Sys.loadElfAt /
Sys.bindApp / Sys.bindStore / Sys.storeReq** — System.qa's C
surface. **Apps.list / Apps.read** — the built-in .qa catalogue.
**Mod.resolve / Mod.has / Mod.fn** — hash-addressed module lookup at
runtime.
```
u = Sys.bindStore a (Rpc a 0 "" "");   # prototype hands C the tid
qa = Apps.read "TUINotes";
```
Note the bindStore shape: constructor tids are content-addressed, so C
cannot know them statically — the tag crosses the ABI as DATA at bind
time (a prototype value), never as a compile-time constant. Any future
C-side constructor follows the same rule.

**arcLive : a -> Int** / **drop : a -> Unit** / **heapUsed** — ARC
introspection, explicit decref, slab usage.
```
u = print "arc live: {arcLive 0}";
u = drop bigShared;
```
Note: ordinary values need no drop — they die with the actor. drop is
for values YOU promoted (sent/kept) and now relinquish early.

**print / error** — uart-routed print; panic the ACTOR (not the
machine) with a message.
```
u = print "boot ok";
badLen n c = error "length {n} vs {c}".
```
Note: error is the BEAM tier — the actor dies, its supervisor decides;
precondition-violation checks compile to exactly this.

## programs/prelude.fpr

fromTo a b (inclusive int range) · fstV / sndV / mapFstV / mapSndV
(pair projections/maps) · mapV / sumV / zipV / foldRes / lenRes (small
list helpers over builtin lists) · par2 / parWorker (spawn two
computations, join results) · newHandle / closeHandle · heapUsed.
```
xs = fromTo 1 10;
(a, b) = par2 (fn u -> slow1 0) (fn u -> slow2 0);
```
Note: par2 is the whole "parallel map" story at PoC scale — two actors,
two sends, two receives; it composes, and the scheduler does the rest.
