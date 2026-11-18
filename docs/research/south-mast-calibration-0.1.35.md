# 0.1.35 - screenshot-measured southern mast correction

User uploaded 2026-11-16_20-21-29.zip (one 1927x1080 screenshot).
On straight ВСМ, two parallel lower contact wires have strong horizontal
edges around raster y559 and y586 (same source image), measured separation
~27 rendered pixels. This is the primary quantitative constraint; the
visual wire-to-triangle hanger touch still requires screenshot QA.

The source native C shaft is 512x384 RGBA, scale 0.5. Mast source alpha
bbox is (224,19)-(383,365); its 0.1.33 NORTH-short counterpart is
(224,19)-(383,295). Original 0.1.34 standard native image is at shift
-2.53125-0.40 tiles. The asset has no horizontal arm (arm is a separate
LuaRendering sprite per orientation). To raise the SOUTH triangular hanger
by 27 screen pixels WITHOUT MOVING ITS FOUNDATION, create a 512x512
canvas with 64 source-row upper padding, lengthen middle truss band
source y166..307 by 54 rows, and paste original bottom y307..384 at
new y371..448. Original top y19 now y29 and old footer y365 now y429.
When image centre changes 192->256 source rows, relative upper bbox
moves -54 rows = -27 rendered px; relative lower bbox remains invariant.
The ribbed truss is resized continuously, not duplicated with a visible seam.

`scripts/mast_visual_034.lua` provides SOUTH_EXTEND_TILES=54*0.5/32
=0.84375. Standard C arm drawn at mast_shift minus SOUTH_EXTEND_TILES;
Northern short mast keeps previous native/art geometry. Undo/blueprints
are unchanged native prototypes.

The user asked to restore SOUTH native wire attachment to before
0.1.34: remove helper_delta -0.40 for standard face=north, so hidden
copper connectors remain at the old logical tip. Custom textured art
gets a separate draw-only visual_delta= -0.40 -0.84375 tile relative
to the helper. Because the helper itself moves down +0.40, net change
in visible contact art is -0.84375 tile = -27px, matching the C arm.
It does not change normal factory copper sprites or transfer MW.

This change will alter the visual height of standard masts in other
facings, because Factorio electric-pole native pictures are not
switchable by connected railway side; other six orientations are not
game-verified. Tested mock contract: the hidden helper in all standard
orientations returns to pre-0.1.34 values, northern helper unchanged.
Factorio gameplay screenshots and load/Undo remain required. Main 0.1.24
is not modified.
