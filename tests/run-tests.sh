#!/usr/bin/env bash
# tests/run-tests.sh -- the QOS regression suite.
#
#   make test                  # from the repo root (default TARGET/HARTS)
#   make test TARGET=rv32
#
# Each row: name|make-vars|stdin|expected-grep[;grep...]
#   - a test PASSES when `make run` exits 0 AND every grep matches
#     (fpr_exit now drives the QEMU sifive test finisher, so completion
#     is exit 0 and any FPRISC panic is a nonzero exit -- no timeouts
#     are waited out on the happy path)
#   - "!" before the name marks an EXPECTED-PANIC test: it passes when
#     the run exits NONZERO and the greps match (smpdead: the deadlock
#     detector firing loudly IS the pass condition)
#   - "S" in the vars column marks an SMP test (multi-hart)
set -u
cd "$(dirname "$0")/.."

TARGET="${TARGET:-rv64}"
PASS=0; FAIL=0; SKIP=0; FAILED=""

# name|vars|stdin|expected greps (all must match)
TESTS='
demo|||all device tests done
actors|||actor demo done
ring|||arc live after 100k promote/drop cycles: 4
smp|S||smp smoke done
smpstress|S||20000 cross-hart blocking round trips survived
!smpdead|S||deadlock
psort|S||psort OK
vectest|||vec generic tier OK
vecbench|||vecbench done
vectime|||vectime done
slotclobber|||released: key = 0;pins done
ttp229|||idle map = 65535;key (active-low) = 6;key (active-high) = 5;ttp229 done
bbspi|||echo ok: True;wire matches sent: True;oled init correct: True;bbspi done
pins|||out latch readback = 1;wired in-pin reads = 1;pressed (row2-col2 jumper): key = 5;released: key = 0;pins done
slab|||slab churn total = 300  arcLive after = 0
modtest|||dispatch by hash + name;Mod.has V2    = True
tuitest|||glyphRow: 47;glyphRows: 5;clockrows: 24;tuitest done
modurl|||good url : hit, f 21 = 42;bad fn   : miss (as data);bad hash : miss (as data);modurl done
stax|||PARSE ERROR: unexpected input;:done
orig1|||main => 1341
orig2|||shadowed (+): 2 + 3    = 7;typeid plus strings    = 5
orig3|||main => 585
orig4|||main => 60
orig5|||ok 100;:done
typed|||ops: 42 fprisc;generic: total Int=10 total Str=abc;sstring: len=2 at1=104 str=hi;vlist: fold=60
precond|||amount: 80 100 75 75 0 7;avg: 30 0  precond done
vsimd|||axpb/sar: [2, 3, 5, 6, 8, 9];gather:   [40, 10, 20, 0];blit:     [7, 7, 50, 7, 52, 7, 7, 7];vsimd done
patguard|||patguard done
sched|||sched done
!precondviol|||precondition violated: double requires (n > 0), got n=-3 (in poke)
'

echo "$TESTS" | while IFS='|' read -r name vars stdin expects; do
  [ -z "$name" ] && continue
  want_fail=0
  case "$name" in "!"*) want_fail=1; name="${name#!}";; esac

  makevars=""
  case "$vars" in *S*)
    :;;
  esac

  out=/tmp/fpr-test-$name.log
  if [ -n "$stdin" ]; then
    printf '%s' "$stdin" | make -s run PROG="tests/$name.fpr" TARGET="$TARGET" $makevars > "$out" 2>&1
  else
    make -s run PROG="tests/$name.fpr" TARGET="$TARGET" $makevars > "$out" 2>&1 < /dev/null
  fi
  rc=$?

  ok=1
  if [ "$want_fail" -eq 1 ]; then
    [ "$rc" -eq 0 ] && ok=0
  else
    [ "$rc" -ne 0 ] && ok=0
    grep -q "FPRISC PANIC" "$out" && ok=0
  fi
  # split expects on ';' and require each
  rest="$expects"
  while [ -n "$rest" ]; do
    case "$rest" in *";"*) e="${rest%%;*}"; rest="${rest#*;}";; *) e="$rest"; rest="";; esac
    grep -qF "$e" "$out" || ok=0
  done

  if [ "$ok" -eq 1 ]; then echo "PASS $name"; echo P >> /tmp/fpr-test-tally
  else echo "FAIL $name  (log: $out, exit $rc)"; echo "F $name" >> /tmp/fpr-test-tally; fi
done

# ---- storage: the two-boot persistence regression (System.qa + QLOG) ----
# boot 1 on a FRESH disk: grant storage to TUINotes, save two notes;
# boot 2 on the SAME disk: NO y-keys -- every permission (launcher's 4
# + notes' 3) must replay from the persisted sys/perms records -- and
# the log must show boot #2 and 2 notes.
D=/tmp/fpr-test-disk.img; rm -f "$D"
printf 'yyyy1yyynote one\nnote two\n.\nqq' | make -s run-system TARGET="$TARGET" DISK="$D" > /tmp/fpr-test-storage1.log 2>&1
printf '1.\nxq'                             | make -s run-system TARGET="$TARGET" DISK="$D" > /tmp/fpr-test-storage2.log 2>&1
if grep -q "boot #1" /tmp/fpr-test-storage1.log && grep -q "persisted to storage" /tmp/fpr-test-storage1.log \
   && grep -q "boot #2" /tmp/fpr-test-storage2.log && grep -q "2 note(s) on disk" /tmp/fpr-test-storage2.log \
   && [ "$(grep -c 'remembered y' /tmp/fpr-test-storage2.log)" -eq 7 ] \
   && ! grep -q '\[y/N\]' /tmp/fpr-test-storage2.log; then
  echo "PASS storage (two-boot persistence + remembered perms)"; echo P >> /tmp/fpr-test-tally
else
  echo "FAIL storage  (logs: /tmp/fpr-test-storage{1,2}.log)"; echo "F storage" >> /tmp/fpr-test-tally
fi
rm -f "$D"

# tally (the while ran in a subshell)
PASS=$(grep -c '^P' /tmp/fpr-test-tally 2>/dev/null || true)
FAIL=$(grep -c '^F' /tmp/fpr-test-tally 2>/dev/null || true)
SKIP=$(grep -c '^S' /tmp/fpr-test-tally 2>/dev/null || true)
FAILED=$(grep '^F ' /tmp/fpr-test-tally 2>/dev/null | cut -d' ' -f2 | tr '\n' ' ')
rm -f /tmp/fpr-test-tally
echo "----------------------------------------"
echo "pass $PASS  fail $FAIL  skip $SKIP  (TARGET=$TARGET)"
[ -n "$FAILED" ] && echo "failed: $FAILED"
[ "${FAIL:-0}" -eq 0 ]
