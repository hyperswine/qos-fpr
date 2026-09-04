# Meshes: a program carries its own geometry

The scene walker (hal/unix/gfx.c) draws named meshes; until now the
registry knew three, `cube`, `plane`, `sphere`, built in C.  A program
can now bring its own:

    glMesh name text   -> triangle count (-1: malformed)

`text` is whitespace-separated milli integers, nine per triangle (three
corners, x y z each), in the walker's frame (Y up, 1 unit = 1000).  The
host computes one flat normal per triangle and uploads the mesh once; the
name is then an `Ent` mesh id like the built-in three, instanced,
coloured and yawed the same way.  Re-registering a name replaces its
geometry.  The v8 slot `gfx_mesh_load` carries it across the ABI;
`mods/glsvc.fpr` registers a list of `(name, text)` pairs right after
`glInit`, from the one actor that owns the context:

    T = use "models/tank/tank".
    gl = spawn (GL.serve 960 600 "tag" T.meshes);

## From a model to that text: tools/mkmesh.py

    mkmesh.py out.fpr name=part.stl [name2=part2.stl] [--scale S] [--floor]

Reads binary or ASCII STL (the format every CAD tool exports and the
simplest to parse: 50 bytes a triangle), maps OpenSCAD's Z-up frame to the
walker's Y-up one ((x, y, z) -> (x, z, -y): +Y forward becomes -Z, the way
a player's unit faces), quantizes to milli and writes an FP-RISC module
with one string per part and a `meshes` list for `GL.serve`.  Nothing is
parsed at run time except our own decimal text, once, at init; the .qa
stays self-contained.  No normals are exported: flat shading per triangle
is the low-poly look, and the host has the triangle.

## The tank: models/tank

The first model is the heavy unit's tank, written in CoScad
(hyperswine/coscad) as two parts so the turret can move:

    tank_hull.coscad     tracks, body, sloped glacis, deck, exhausts
    tank_turret.coscad   turret box, roof, mantlet, an 8-sided gun, muzzle,
                         cupola -- its pivot at the origin

    coscad tank_hull.coscad && coscad tank_turret.coscad      # -> .scad
    xvfb-run -a openscad -o tank_hull.stl tank_hull.scad       # -> .stl
    xvfb-run -a openscad -o tank_turret.stl tank_turret.scad
    tools/mkmesh.py tank.fpr tank_hull=tank_hull.stl tank_turret=tank_turret.stl

172 and 124 triangles.  The .coscad, .scad, .stl and the generated
tank.fpr are all checked in, so a build needs none of the tools.  In
Terra II a heavy is `Ent "tank_hull"` plus `Ent "tank_turret"` 0.75 units
up, the hull yawed 0 for the player and pi for the enemy, and the turret
swung onto the target while the unit is the one lunging or firing (an
integer atan in `atanM`).  `tests/gfxmesh.fpr` draws three tanks with
yawed turrets and snapshots them; it is a check-all leg.

## The rest of the army: models/

Every unit type is now a CoScad model, split into parts where a second
colour or a moving piece wants one.  `models/build.sh` regenerates all
four stages (`COSCAD=... models/build.sh`); the results are checked in.

| model                | parts                                                    | triangles     | in Terra II |
|----------------------|----------------------------------------------------------|---------------|-------------|
| `tank/`              | `tank_hull`, `tank_turret` (pivot at the origin)          | 172 + 124     | Hard combat: hull in the side colour, turret a shade lighter, swung onto the target |
| `infantry/`          | `infantry` (body), `infantry_kit` (helmet, boots, pack, rifle) | 140 + 200 | Soft combat: body in the side colour, kit dark, 1.3x |
| `truck/`             | `truck` (chassis, bonnet, cab, bed), `truck_kit` (six wheels), `truck_canvas` (the hoop, tailboard) | 176 + 216 + 60 | support: body in the side colour, wheels dark, canvas khaki |
| `hq/`                | `hq` (slab, command building, silo with cap, two watchtowers), `hq_fence` (nine posts, panel, rails, lamps), `hq_dish` (pivot at the origin) | 270 + 736 + 140 | the HQ: buildings tinted by side, the fence steel, the dish white and turning |

Ten registered meshes plus the three built-in ones: 13 of the table's
16.  `tests/gfxmesh.fpr` is the showroom, all of them in one frame.

## Limits and next steps

* The mesh table holds 16 names (13 used) and 16,384 instances per mesh; a
  registered mesh has no vertex sharing, so triangles cost three vertices
  each -- fine for hundreds, think again for hundreds of thousands.
* Rotation is yaw only, as for every entity: a model that needs pitch
  (a gun elevating) needs a walker change, not a format change.
* OBJ would be a 40-line addition to mkmesh.py (v / f lines, fans for
  n-gons); it earns its place when a model wants named sub-objects in one
  file.
