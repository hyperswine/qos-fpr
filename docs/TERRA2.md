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
| HQ               | the CoScad compound (models/hq): command building, silo, two watchtowers, a security fence, a turning dish; the enemy's carries an "HQ n" label |
| infantry (Soft)  | the CoScad soldier (models/infantry): helmet, pack, a rifle across the chest |
| heavy (Hard)     | the CoScad tank (models/tank, docs/MESHES.md): hull + a turret that swings onto the target |
| artillery        | a carriage and a barrel pointing at the enemy       |
| support          | the CoScad truck (models/truck): cab, bonnet, canvas-hooped bed, six wheels |
| ambush           | a face-down slab with a "?"                         |
| labels           | scene2d's 5x8 font as flat cubes in the scene: "atk/hp OW CHG *vet" over units, the enemy HQ's "HQ n", damage tags |
| the UI           | a 2D layer over the board (docs/UI2D.md): status bar, message, unit panel, banner, the hand as cards facing the viewer |

Animations: summon pop (scale + drop over 300 ms); attacks are
projectiles now -- a soldier fires a burst of four tracers from the
rifle's tip (55 ms apart, each crossing in 230 ms, elongated along the
aim and dropping to the target), a tank turns its turret onto the target
and fires one shell from the barrel at 60 ms (a flat arc, landing at the
midpoint) while the hull rocks back 90 milli and settles; both with a
muzzle flash and grey smoke puffs that rise, grow and fade, and the blow
at the 260 ms midpoint of the 520 ms attack.  Artillery / ambush shell
(a sphere on a parabola, 700 ms), retreat / advance slide (360 ms), hit
flash (white, 250 ms) with sparks that rise and fade, death
shrink-and-sink (420 ms), the turn banner.  The muzzle points come from
an integer sine (Bhaskara) over the aim yaw, so the enemy's rounds leave
its barrels too.

## Sound and feel

Sound is the second axis (docs/SOUND.md): every cue is a riff of
integer tones the host synthesizes -- the cursor ticks, a pick chirps, a
refusal buzzes, a call rises, an attack whooshes, a blow cracks, a
destroyed unit rumbles, rifles crack in bursts and cannons boom, the HQ
thuds and the camera shakes, artillery whistles, an ambush snarls, overwatch snaps, your turn chimes up, the
enemy's down, the game opens on an arpeggio and closes on one; victory
and defeat have their own.  Cues are queued on the model and played by
the tick, like the transcript, so a replayed game sounds identical.

Idle motion, so a board between actions is alive: every unit runs on
its own phase (a hash of its slot) over waves of the model's clock -- a
triangle wave and a "sweep" that holds at each end and moves briskly
between.  Soldiers shift their weight side to side, square up now and
then, and draw the rifle forward and back (the rifle is its own part, so
it rises, comes forward and swings a little in their hands).  Tank
turrets scan between actions, two sweeps of different periods summed so
the pattern never quite repeats, and snap onto the target when the unit
attacks.  Trucks idle with a fast, tiny bob, the canvas a beat behind.
The HQ dish turns.  All of it is a function of the clock, so a replayed
game moves the same way.

With it, the cheap extra dimensions: floating damage numbers (white on
a dark tag, rising and shrinking in front of the target), a camera
shake on kills and HQ hits (a hash of the clock, so replays shake the
same way), the cursor's unit bobbing, a title screen (ENTER to begin),
and a game-over screen (ENTER deals a new game with a new shuffle,
Q quits after the closing riff).

The cursor remembers the board: after a call it sits on the new unit,
after an attack on the attacker, and a new turn leaves it where it was;
esc returns to where the selection started.

## Polish, batch one

Motion arrives instead of stopping: an integer easing set (`easeOut`,
`easeIn`, `easeInOut`, a `backOut` that overshoots and settles) runs the
summon pop, the death shrink, the slides, the recoil, the damage tags
and sparks, the banner's scale-in, the card lift and the panel's
brighten-in.  Visual state chases the model: the cursor is a ring of
four amber strips that glides a third of the way to its slot every tick
and breathes; a hover clock (`hovT`) times the lifted card and the panel.
A summon is a card slab flying from the hand's edge (the enemy's from
beyond its HQ) to the slot on a small arc, shrinking and turning, the
unit popping up as it lands.

The look is one palette declared at the top of the program: a dusk sky
and ground, two desaturated factions with a light of each, amber as the
single accent, a danger red, and the 2D layer's ink and paper.  The
walker's lights list takes a second entry, the sky -- (fog and clear
colour, ambient tint) -- and the shader now mixes a cool ambient with
the warm sun and fogs by distance toward the sky, so the far compound
settles into the horizon; a backdrop wall and a ground rim carry the
gradient.  Every unit stands on a flat shadow ellipse; tiles carry a
light edge strip so the board reads as a board.

## Polish, batch two

Things fade now: the walker's instance colour carries an alpha
((r, g, b, a) beside the plain triple), and each mesh draws its opaque
instances first, then the translucent ones blended, depth-tested but
not depth-written, sorted far to near -- so smoke thins out, sparks and
damage tags dissolve, a destroyed unit fades as it shrinks, and the
scorch mark it leaves fades over twenty seconds.  The enemy's turn plays
under a veil, a translucent sheet over the board fading in and out over
400 ms, with a 260 ms beat between its actions so they read as decisions
rather than a burst.  The supply figure in the bar counts up and down one
a tick and stays amber while it moves.  Repeated cues vary in pitch by a
few percent from the clock, so four rifle cracks are four cracks.  On the
title screen the camera drifts slowly over the board until ENTER.

## Polish, batch three

Aiming shows its options: every slot the attacker can hit wears a
breathing red ring, the HQ a wider one and a pulse on the compound
itself, the amber cursor ring on the one being aimed at.  The hand
closes the gap a played card leaves (its ghost shrinks in place over 200
ms) and opens one for a dealt card (it grows in).  A struck HQ collects
craters in front of its compound.  The hovered unit's label brightens and
grows a step.  The title is a framed logo in the 2D layer over the
drifting board -- the name, a line about the two factions, a blinking
prompt, the keys -- with the bar and the hand hidden until the game
begins.

## The art pass

The look was cells and slabs; a modern surface wants type and rounded
glass.  The walker gained a real face -- DejaVu Sans Bold as a signed-
distance-field atlas and a text pass (docs/UI2D.md) -- and scene2d the
treatments to go with it (`Fs`, `Round`, `Shadow`, `Bga`, `Center`,
`Mid`).  The layer now runs at 960 x 600, one virtual px per window px,
and everything on it was redrawn: a glass status bar with chips (TURN,
YOU, ENEMY, ENV) and captioned figures; the message in the face; the
banner in a glass pill that grows in with the back-out ease; the unit
panel as a rounded glass card with a header band in the unit's kind
colour, stat chips for ATK/GEN and HP, and the keys that apply as key
caps; the hand as 124 x 150 rounded, shadowed cards -- a kind band with
the name and an amber cost badge (red when you cannot afford it), the
kind in small caps, big ATK/DEF figures -- the cursor's card lifted, lit
and rimmed amber, the ghost and the dealt card keeping their tweens.
The title is a glass card with the name at 64 px.  On the board the unit
labels, the HQ figure, the ambush "?" and the damage tags are text
entities standing over their units instead of glyph cells.

## The lifecycle

A packaged game has screens, and the model now says which one is up:
title, playing, paused, game over, keys, stats (`screen`).  Paused,
Keys and Stats freeze the tick -- animations, the AI and the supply
ticker stop, only keys are taken -- and the music ducks to half while
paused.  Esc with nothing selected pauses: a glass menu over the veiled
board with Resume, Restart, Stats, Keys and Quit, arrows and enter.
Restart asks first ("Abandon this game and deal a new one?") so a stray
key cannot wipe a game; the new deal keeps the profile, the settings
and the snapshot counter.  K and S open the Keys and Stats screens from
the title, the menu and game over, and esc, enter, K or S return to
where you came from.  The Keys screen is a table (`keymap`) that is also
the source of the unit panel's key caps, so the two cannot drift.

## The profile

The disk keeps a profile: one append-only record at `terra2/profile`
on the QLOG log through `std/fs` (the same service POS uses), a line per
event -- `start <seed>` when a game is dealt and `end <seed> win|loss
<rounds> <hqMe> <hqEn> <called> <lost> <destroyed> <damage>` when an HQ
falls.  Boot replays the log and folds it into totals; every line the
game writes is folded into the model's copy first, so the Stats screen
never lags the disk, and update flushes the pending lines after each
step (the rules never touch the service).  A start with no end is a
game abandoned.  Stats shows played / won / lost / abandoned and the
win rate, the best win in rounds, the average length, units called and
lost, and the recent games one line each.  The GL host opens
`qosp.disk` beside it (or `FPR_DISK`), so `./qos.py run` and a packed
bundle keep the profile between runs without any flag; with no disk the
game says so on the Stats screen and plays on.  Boot also asks the
storage service to compact (live records copied forward, the log
truncated -- idempotent), so a long-played disk does not fill with
superseded saves.

## Continue

The board is saved too: at `terra2/game`, whenever a turn of yours
begins (the state after income, nothing in flight -- `dirty` is set by
the turn start and the save goes out with the next flush that finds the
board idle) and cleared when an HQ falls.  Only what the rules need
goes out: both sides (HQ, supply, deck, hand, the two rows as eleven
numbers a unit), turn, ENV, the counters; never the animation, cursor
or queue.  Boot reads it back under the title -- the saved board is
what the camera drifts over -- and the prompt becomes "ENTER continue
turn N / N new game".  Continue picks up at that turn with no start
record; N deals fresh.

## Cards

C from the title, the pause menu or game over opens the Cards screen:
both factions as small cards eight to a row (name, cost badge, kind,
figures), the cursor's card in a detail line below with its full stats
and a line on what its kind does; arrows browse, up and down swap
faction.  The same card component the hand uses, so the screen doubles
as a check that every card in the table renders.

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
    M music on / off (Sunrise Over The Spire starts with the game)
    esc with nothing selected: pause (Resume / Restart / Cards / Stats / Keys / Quit)
    K keys, S stats, C cards: from the title, the pause menu and game over
    ENTER on the title screen begins (or continues the saved game; N deals
    fresh); on the game-over screen, a new game

## Verified

`qos/tests-host/terra2-check.sh` (a check-all leg when xvfb-run and libglfw
are present) replays a key file through FPR_EVDEV and asserts the
transcript the rules print: your call, the lane attack on the HQ (15 ->
13), the AI's turn and call, a forward unit destroyed by the second
attack, a clean quit; plus the frames read back mid-lunge (960x600, not
blank) and the sound dump (a WAV as long as the run, 60+ tones in 25+
distinct bursts over 60% silence).  A second run on the same fresh disk
walks the lifecycle -- the Keys, Stats and Cards screens, Continue into
the board the first run saved at its fourth turn, pause, Restart through
its confirm, Stats from the menu, quit -- and reads the first run's
start record back as one abandoned game.  25 s under llvmpipe.  Frame cost: the whole board is ~2000-3000
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
