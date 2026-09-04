# Terra II on QOS: the card game as an FP-RISC program

`fp-risc/programs/terra2.fpr` is the V1 rules of docs/TERRA2-V1.md, cut to
what proves the positional economy on a screen, running on QOS Portable's
GL host as one MVU program.  A first cut "to see if it works": it does.

    ./qos.py run programs/terra2.fpr          # a window (qosp-gl, GLFW)
    ./qos.py pack programs/terra2.fpr --bundle
    qos/tests-host/terra2-check.sh            # a scripted game under Xvfb

## The shape

Three pieces, and nothing hand-rolled twice:

* **`mods/glsvc.fpr`** -- the GLES scene walker (hal/unix/gfx.c) as a
  std.MVU render service.  One actor answers the Rv protocol: `Dims`
  (the window), `Render` (glRender of the scene the view built), `Poll`
  (inputPoll for the key drain).  `interactive_desktop_gl.fpr` had this as
  its own frame worker; now any program is `MVU.game me cfg (App init
  update subs view)` with `gl = spawn (GL.serve w h tag)` as both `input`
  and `render`.  The view's value is `(scene, snap)`: when `snap` changes
  the frame just drawn is read back to `/tmp/<tag>-<snap>.ppm`, which is
  how a headless run proves what it drew and how the P key is a
  screenshot in a live window.
* **the rules** -- a pure model record (two sides of `{hq, stock, deck,
  hand, fwd, rear}`, five unit records a row, id < 0 empty) and functions
  over it: `targetOk` (the +-1 column reach, cover, lanes), `resolveAttack`
  (overwatch intercept, ambush reveal, then the blow), `startTurn` (ready,
  veterancy every 3 turns, repair in the rear, supply = min(stock, 3) +
  rate, draw), `endTurn` (ENV damage at 4 / 10, discard to 7), `callCard`,
  and a greedy positional AI for the other side (`aiPlan`).
* **time** -- a 40 ms `STick`.  Player and AI both ENQUEUE actions
  (`ACall`, `AAttack`, `AOver`, `ARetreat`, `AAdvance`, `ACharge`,
  `AFire`, `AEnd`, `AStart`); the tick pops one at a time, plays its
  animation and applies the rule at the animation's midpoint, so what you
  see is when it happens.  Keys are buffered in the model and taken one
  per idle tick, so a replayed key file drives an identical game.

## The look

Hearthstone's camera: behind and above your hand, looking down the board
(`camera = ((0, 12500, 14800), (0, 0, 300), fov 1.0 rad)`).  Everything is
the walker's three meshes in milli units:

| thing            | solids                                              |
|------------------|-----------------------------------------------------|
| table, tiles     | a plane; a thin cube per slot, tinted by zone, lit by the cursor (yellow), the selection, a valid target (red) |
| HQ               | a block and a tower; the enemy's carries an "HQ n" label |
| infantry (Soft)  | a block body and a sphere head                      |
| heavy (Hard)     | a hull and a turret                                 |
| artillery        | a carriage and a barrel pointing at the enemy       |
| support          | a tower with a light roof                           |
| ambush           | a face-down slab with a "?"                         |
| hand             | standing slabs, the cursor's one lifted, text on the face |
| text             | scene2d's 5x8 font, one flat cube per lit cell (HUD, message line, labels "atk/hp OW CHG *vet", card faces) |

Animations: summon pop (scale + drop over 300 ms), attack lunge (out 70%
of the way to the target and back, 520 ms, the blow at the midpoint),
artillery / ambush shell (a sphere on a parabola, 700 ms), retreat /
advance slide (360 ms), hit flash (white, 250 ms) with sparks that rise
and fade, death shrink-and-sink (420 ms), the turn banner.

## Sound and feel

Sound is the second axis (docs/SOUND.md): every cue is a riff of
integer tones the host synthesizes -- the cursor ticks, a pick chirps, a
refusal buzzes, a call rises, an attack whooshes, a blow cracks, a
destroyed unit rumbles, the HQ thuds and the camera shakes, artillery
whistles, an ambush snarls, overwatch snaps, your turn chimes up, the
enemy's down, the game opens on an arpeggio and closes on one; victory
and defeat have their own.  Cues are queued on the model and played by
the tick, like the transcript, so a replayed game sounds identical.

With it, the cheap extra dimensions: floating damage numbers (white on
a dark tag, rising and shrinking in front of the target), a camera
shake on kills and HQ hits (a hash of the clock, so replays shake the
same way), the cursor's unit bobbing, a title screen (ENTER to begin),
and a game-over screen (ENTER deals a new game with a new shuffle,
Q quits after the closing riff).

## Keys

    arrows        cursor: left/right a card or a column, up/down a zone
                  (hand, your rear, your forward; when aiming: enemy
                  forward, enemy rear, the HQ)
    enter         pick the card / pick the unit / confirm the target
    esc           cancel
    on a unit     A attack  O overwatch (toggle)  R retreat  V advance
                  C charge  F fire  (artillery)
    1-5           jump to a column      space / E   end the turn
    P screenshot  S auto-screenshot at every animation midpoint   Q quit
    ENTER on the title screen begins; on the game-over screen, a new game

## Verified

`qos/tests-host/terra2-check.sh` (a check-all leg when xvfb-run and libglfw
are present) replays a key file through FPR_EVDEV and asserts the
transcript the rules print: your call, the lane attack on the HQ (15 ->
13), the AI's turn and call, a forward unit destroyed by the second
attack, a clean quit; plus the frames read back mid-lunge (960x600, not
blank) and the sound dump (a WAV as long as the run, 60+ tones in 25+
distinct bursts over 60% silence).  25 s under llvmpipe.  Frame cost: the whole board is ~2000-3000
cube instances a frame, well inside the walker's 16384 per mesh.

## Not in this cut

Tactics cards; every card text (Rally, Last Stand, Breakthrough, Hammer
Strike, Repair beyond Engineering Corps, ...); the Unsupplied rule (a
negative rate clamps the stockpile to 0); RECALL; redraw, requisition and
the mulligan; the first player's skipped Act phase; a second human (the AI
holds the far side); mouse input (the walker reports relative motion only,
so the game is keyboard-driven).  Overwatch, ambush, artillery, retreat,
advance and veterancy are implemented and reachable from the keys but only
the attack / call / AI paths are asserted by the scripted game -- the hand
is a shuffled deck, so a script exercising artillery needs a scenario
seed, which is the next thing to add.
