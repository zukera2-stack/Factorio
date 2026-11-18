# 0.1.36 — derive SOUTH C-arm offset and lattice repair from screenshot

Evidence: user's uploaded 2026-11-16_21-51-56.zip containing
a 1650x928 zoomed Factorio screenshot. The shortened mast NORTH of
track is around x500, its triangular hanger ends ~y380. The
standard longer SOUTH-of-track mast around x831 has hanger ~y348
and footing ~y679, while the yellow world-placement indicator is
~y717. The screenshot's custom contact line is already ~y376–380.
All three comparisons indicate standard NATIVE/ARM art is too high
by approximately 32–35 SCREEN pixels, corresponding to the deliberately
added 0.40 WORLD tile shift in 0.1.34 at this screenshot zoom.

Decision: undo the 0.1.34 -0.40 displacement of the native STANDARD
mast and separate cantilever sprite. In mast_visual_034, standard
mast_shift changes -2.93125 -> -2.53125; cantilever_shift standard
changes -3.775 -> -3.375 (delta +0.40 tile). Keep hidden copper helper
and custom contact/messenger/dropper draw point EXACTLY at 0.1.35,
so the downward-moving triangular hanger meets the existing line
without moving the contact graphical line below the railway.

Lattice: 0.1.35 had mechanically stretched truss 141-source-row
diagonal brace band to 195 rows via bicubic resampling. On the image
this introduces an inharmonious truss overlay. 0.1.36 regenerates the
same 512x512 sprite from source 0.1.24 by repeating 54 native raster
rows 167..220 once after row220, with a 10-row blended stitch. The
top cap and footer portions remain byte-identical; total alpha
bbox stays (224,29,383,429). A built-in visual edge test rejects
sudden line discontinuities above a threshold and pixel comparison
guards original top and footer. Entire operation is deterministic;
source original immutable. Uses Pillow installed in existing CI
sprite generator step (no new external asset licensing).

Expected effect: standard mast base moves toward the cursor ground
marker, southern triangle lower by 0.40 tile and matches northern
triangle at roughly y380 in reference screenshot. We cannot infer
perfect in-game occlusion from a static screenshot; Factorio 2.1
gameplay visual confirmation is mandatory. Original short north C mast,
native electric link graph, 32/16/40 and Undo are untouched.
