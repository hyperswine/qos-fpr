# FPRLive — LiveView over a websocket, for FP-RISC apps

`programs/mods/fprlive.fpr` is the browser driver for a per-session MVU
app served from the QOS socket tier (`qosp` / virt). It is the LiveView
idea — a page split into statics and dynamics, the server owning the
model, deltas on the wire — carried over a real websocket instead of the
long-poll in `liveview.fpr`, so an update reaches the screen without the
client asking. `tests/pos.fpr` is the worked example: the point-of-sale
app from `sol/examples/pos2.sol`, one register shared by many cashiers,
each browser tab a session with its own login and cart.

```
main = FL.serve { env = e, css = G.cssFor } (FL.App init update view subs).

  init   env                 -> model               shared by every session
  update env ev model        -> (model, List MC)    ev = EMsg sid msg arg
                                                       | ETick | EGone sid
  view   sid model           -> genview tree        rendered PER SESSION
  subs   model               -> List Sub            STick ms -> server ticks
```

The four functions are `std.mvu`'s Elm surface, unchanged — the same
`App` value a game driver or the long-poll driver runs. What FPRLive
adds is the wire and the session bookkeeping.

## The wire

```
GET /            the page: generated CSS, <div id=lv-root>, the __LV__
                 seed (statics + first dynamics), the client script
GET /ws          the RFC 6455 upgrade; Sec-WebSocket-Accept = base64(
                 sha1(key ++ GUID)), both computed in FPRISC
client -> server text frames   {"msg":"buy","arg":"2"}
server -> client text frames   {"s":[..],"d":[..]}   a full render, on
                                                     connect and on a reshape
                               {"d":{"3":".."}}      a delta, computed
                                                     against what THIS session
                                                     last saw
```

Every event — any session's message, or a server tick — runs `update`
once and then pushes to *every* open session: one register, many
screens, each re-rendered through its own `view sid model` and shipped
the smallest thing that brings it up to date. A session that a change
does not touch gets an empty delta, which is elided, so an idle tab is
silent.

SHA-1, base64, the frame parser and framer, and the mask/unmask are all
in the module (`fprlive.fpr`), in FPRISC over the 63-bit tagged int:
every 32-bit intermediate is masked before each shift so nothing
overflows the tag. There is no C in the handshake.

## The client

`programs/mods/fprlivejs.fpr` is the whole client, ~150 lines, served
inline. It opens one websocket, applies `{s,d}` and `{d}` messages by
`textContent` on `<span data-slot=i>` (so a dynamic carrying user input
can never become markup), and reconnects with backoff on an unexpected
close. Client-only state — Alpine-style locals declared in the view
tree (`x-data`, `data-set`/`data-val`, `data-show`, `data-text`, and a
new `data-input` for text fields) — never round-trips unless an event
carries it as its arg. The POS uses a local for the active tab (no
server involvement to switch tabs) and a local for the login field
(sent only when the cashier presses enter or the button).

## Refusals

The server answers a misbehaving peer with the RFC's close codes and
keeps serving everyone else:

| frame                                   | close |
|-----------------------------------------|-------|
| binary, or any non-text data opcode     | 1003  |
| fragmented (FIN=0), continuation, RSV set, unmasked | 1002 |
| over 4096 bytes (incl. any 64-bit length header) | 1009 |
| a client close                          | 1000  |
| server shutdown (`MQuit`)               | 1001 (to all) |

Malformed HTTP is answered too: an upgrade without a 24-byte
`Sec-WebSocket-Key` is `400`, a request head over 8 KB is `431`, an
unknown path is `404`, and a head that arrives in pieces is reassembled
and served.

## What the adversarial harness found

`qos/tests-host/fprlive-check.py` drives the POS as several websocket
clients, well-behaved and otherwise: two-cashier flows and per-session
deltas, XSS/quote/backslash/control-byte/`\u`-escape login names, bad
numeric args (negative, huge, non-numeric, unquoted), junk and non-JSON
frames, every refused frame shape above, coalesced and byte-trickled and
16-bit-length frames, malformed and slow HTTP, the 8-connection ceiling,
a 180-event three-cashier storm with the store's invariants checked
after each burst (stock never negative, revenue equals the sum of
receipts, receipt numbers dense), a non-reading peer, and a
quit-and-restart on the same disk. Everything the run exercises is a
leg of `check-all.sh`.

Fixing what it turned up shaped the final module:

- **A frame split across TCP reads panicked the server.** The parser
  returned "incomplete" but the loop had already overwritten the
  connection's buffer with the new bytes only. Fixed by threading the
  unconsumed bytes through `pushOne` and by handling frames that arrive
  behind the HTTP upgrade in the same segment.
- **A peer that vanished without a close frame left its session alive**
  for the next peer that landed on the recycled connection id. The
  socket tier (`hal/unix/net_raw.c`) now reports EOF — a FIN, a reset,
  or a failed write — as one empty `netRead`, which both servers
  (FPRLive and the long-poll `liveview.fpr`) take as `EGone`.
- **The process heap grew ~175 KB per event.** A socket loop runs in
  one actor pool, which is reclaimed only by a reset, so every rendered
  string it ever made was retained. The loop now takes `std.mvu`'s soft
  death: each turn sends its state to itself, `Sys.poolReset`s, and
  reads the state back, so the turn's temporaries die at the boundary.
  Constant-state memory is now flat — 14 MiB steady over 10,000 events;
  growth tracks only the receipt log, which is real state.
- **Quadratic string building** in the escapers, the join helpers, and
  the frame unmask (a `strcat acc x` per byte copies the whole prefix)
  raised the per-turn high-water mark on long strings. Rewritten to copy
  plain runs whole (`substr`) and join pieces pairwise (`Core.concat`,
  `Core.joinWith`).

## Readiness — is this ready to host a full web app?

For a single-box, low-concurrency app (a shop till, a dashboard, an
admin panel, an internal tool), the shape is there and holds up: real
websockets, per-session deltas, server push, escape-safe rendering, RFC
close codes, disk persistence across restarts, sub-2 ms round trips, and
flat memory under sustained load. The handshake and framing being in
FPRISC rather than C is a genuine result.

The limits are the socket tier's, and each is a known edge, not a bug:

- **8 connections** (`QOS_NET_MAXCONN`). Eight open tabs are eight
  websockets; the ninth page load waits in the listen backlog. This is
  the first thing to raise for anything public.
- **One server loop, blocking writes.** `netWrite` spins when a peer's
  socket buffer fills. A slow reader on a busy register would stall the
  loop until it drains or goes away; the harness confirms the spin is
  latent at 400 small deltas but real in principle. A production tier
  wants non-blocking writes with a per-connection out-queue.
- **No read timeout.** A peer that sends half a request head holds its
  slot until it closes. With 8 slots that is a cheap denial of service.
- **4 KiB frame cap, 8 KiB receive buffer, 1 KiB reads.** Fine for MVU
  events; a file upload needs fragmentation, which the parser refuses.
- **JSON `\u` escapes decode for the BMP only**; a surrogate pair
  (emoji) from a hand-written client becomes `??`. Browsers send raw
  UTF-8, so this bites only non-browser clients.
- **Header lookup is case-sensitive** (`Sec-WebSocket-Key`). Browsers
  send the canonical casing; a hand-rolled client must match.

None of these blocks the target the module was built for. They are the
list to work through before pointing it at the open internet.
