# The 2D layer: scene2d over a 3D scene

A game wants a HUD, panels, a hand of cards facing the viewer -- and later
a mouse.  The scene walker draws one Scene per frame with one camera, so
the 2D UI is a SECOND PASS over the same frame (qosp v10):

    glRenderUi scene ui dist   -> (draws, dynBytes)

`scene` is drawn as `glRender` draws it; then, with the depth buffer
cleared and the colour kept, `ui` -- a List of Ent in mods/scene2d's
pixel space -- is drawn with the Int camera at `dist` milli on +Z looking
at the origin and a light behind the camera (faces carry their instance
colour).  One present at the end.  `mods/glsvc.fpr` takes the view's
value as `(scene, (ents, dist), snap)`; `(Nil, 0)` means no layer.

scene2d does the rest: a view AST (`Box attrs kids`, `Lbl attrs text`)
laid out like a miniature flexbox (`Row`/`Col`, `Pad`, `Gap`, `W`/`H`,
`Grow`, `Bg`/`Fg`/`Bord`, `Sc` for text scale) and emitted as thin cubes
-- one per box, border strip and lit glyph cell of its 5x8 font.
`S2.buildW (vw, vh) tree` gives the entities; `S2.camAt vh` the camera
distance.  Pick the virtual size as the window at an integer scale (Terra
II: 960 x 600 at 2x = 480 x 300) so every glyph cell is a whole number of
real pixels.

Terra II rebuilds its tree from the model every frame: a status bar and
the message at the top, a unit panel at the right (name, stats, mode,
the keys that apply), the banner in the middle, the hand along the bottom
as cards facing the viewer, the cursor's card lifted and bright.  About
4,000 cubes a frame for the layer, under the walker's 16,384 per mesh.

Every box has a rectangle in the 480 x 300 space, and that is what a
mouse will hit-test against: a click is a point in the same space, so
picking a card or a button is a rectangle test on the tree, no
raycasting.  Not wired yet -- the walker reports relative mouse motion
only -- but the layout is where it will hang.
