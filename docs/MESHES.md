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

## Limits and next steps

* The mesh table holds 16 names and 16,384 instances per mesh; a
  registered mesh has no vertex sharing, so triangles cost three vertices
  each -- fine for hundreds, think again for hundreds of thousands.
* Rotation is yaw only, as for every entity: a model that needs pitch
  (a gun elevating) needs a walker change, not a format change.
* OBJ would be a 40-line addition to mkmesh.py (v / f lines, fans for
  n-gons); it earns its place when a model wants named sub-objects in one
  file.
