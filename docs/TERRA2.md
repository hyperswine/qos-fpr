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
