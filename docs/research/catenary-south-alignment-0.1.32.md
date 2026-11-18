# 0.1.32 - screenshot-calibrated south-side C mast visual endpoints

## Evidence
Four screenshots from user upload 2026-11-16_17-21-40.zip, taken 17:21:40, 17:22:59, 17:24:39 and 17:26:00. Factorio 2.1.20, 0.1.31 dual sprite suspension successfully rendered in game. Image comparison: the pair of C masts south of track has cable sprite endpoints visibly ABOVE their triangular insulator hangers. The poles north of the railway are visually better aligned. The user did not provide log for this screenshot set.

## Model
A C mast south of the track faces NORTH toward its rail. The floor offsets estimated in 0.1.28 for all 8 C arm orientations were reused by 0.1.30 sprite art, but the north-facing orientation is visibly offset. Fix only graphic endpoints in catenary_art_030.lua using M.visual_point:
  face=north => dx=-0.22, dy=+0.90 world tiles
  all seven other faces => dx=0, dy=0
Native helper electric poles remain at their previous physical positions, with real invisible copper connectors and 40-tile reach. No change to HSR topology (straight 32 / curved 16), C mast PNG, rail PNG, placement, native Undo, or electric traction (MW=0).

## Limitations
Visual correction is screenshot-derived, not yet verified in Factorio. Verify both south and north side pairs at matched zoom, save-load and Undo, then send new screenshots before main merge. Curves retain existing native copper appearance. No global utility-sprites override.
