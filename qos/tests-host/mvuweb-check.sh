#!/bin/sh

# mvuweb-check.sh -- LV.server (programs/mods/liveview.fpr) end to end:
# build tests/mvuweb.fpr, host it under qosp with the socket tier on a
# scratch port, and drive the LiveView wire with curl --
#
#   GET  /             the page: generated CSS, the __LV__ seed, the
#                      livejs client, and (STick subscribed) the poll loop
#   POST bump          a delta   {"d":{"0":..}}       same statics
#   POST __poll        a delta carrying SERVER-SIDE tick progress
#   POST theme         a reshape {"s":[..],"d":[..]}  statics changed
#   POST quit          answered, then the run returns its result line
#
# Assumes fpr and qosp are already built (the check-all sweep's state).

set -e
cd "$(dirname "$0")"

PORT=${MVUWEB_PORT:-8123}
OUT=/tmp/mvuweb-check.out
CURL="curl -s --noproxy 127.0.0.1 --max-time 10"

(cd ../../fp-risc && make -s qos-app PROG=tests/mvuweb.fpr >/dev/null 2>&1)

rm -f "$OUT"
(cd .. && FPR_PORT=$PORT ./qosp --yes ../fp-risc/app.qa > "$OUT" 2>&1) &
QOSP=$!
trap 'kill $QOSP 2>/dev/null || true' EXIT
sleep 2

fail() { echo "mvuweb-check: FAIL: $1"; exit 1; }

PAGE=$($CURL "http://127.0.0.1:$PORT/")
echo "$PAGE" | grep -q 'id="lv-root"'        || fail "page: no lv-root"
echo "$PAGE" | grep -q 'window.__LV__'       || fail "page: no __LV__ seed"
echo "$PAGE" | grep -q 'data-slot'           || fail "page: livejs client missing"
echo "$PAGE" | grep -q 'setInterval'         || fail "page: STick poll script missing"
echo "$PAGE" | grep -q 'box-sizing'          || fail "page: generated CSS missing"
echo "  page: CSS + seed + livejs + poll script"

D1=$($CURL -X POST -d '{"msg":"bump","arg":"5"}' "http://127.0.0.1:$PORT/live/event")
echo "$D1" | grep -q '^{"d":{' || fail "bump: not a delta: got $D1"
echo "$D1" | grep -q '"0":"5"'   || fail "bump delta: got $D1"
D2=$($CURL -X POST -d '{"msg":"bump","arg":"1"}' "http://127.0.0.1:$PORT/live/event")
echo "$D2" | grep -q '"0":"6"' || fail "second bump delta: got $D2"
echo "  events: deltas ship one slot"

sleep 1
D3=$($CURL -X POST -d '{"msg":"__poll","arg":""}' "http://127.0.0.1:$PORT/live/event")
echo "$D3" | grep -q '"1":' || fail "poll: no server-side tick progress: got $D3"
echo "  subs: STick advanced the model while the socket was idle"

D4=$($CURL -X POST -d '{"msg":"theme","arg":""}' "http://127.0.0.1:$PORT/live/event")
echo "$D4" | grep -q '^{"s":\[' || fail "theme: expected a reshape: got $D4"
echo "$D4" | grep -q 'warm'     || fail "theme: reshaped statics lack the flipped class"
echo "  reshape: statics change ships the full split"

$CURL -X POST -d '{"msg":"quit","arg":""}' "http://127.0.0.1:$PORT/live/event" >/dev/null
sleep 1
grep -q "lv: server closed" "$OUT" || fail "quit: no result line ($(tail -1 "$OUT"))"
echo "  quit: MQuit answered the request and returned the result"

echo "mvuweb-check: ALL LEGS PASS"
