# 0.1.49 — refinement and scale calibration v2 (development only)

User requested refinement of the approved autonomous locomotive design and comparison against existing rolling stock/contact wire before rendering 256 directions. Base: fb6f7bd38bf69f6ffc2c786dc3cc267d44ce7e3f. No game Lua/PNG/version changes.

## Geometry
- Refined original mesh shell with 13 cross sections, chamfered shoulders, tapered ends, separate rising color stripe, guards, panels, louvres, rivets and extended coupling rods. No windows, cab, or headlights. Simplified industrial style still differs from the approved detailed illustration; not final texture work.
- 318 components total, 292 common meshes and 13 per pantograph position. Both GLBs contain 305 meshes; all 292 common mesh vertex arrays byte-identical after export/reload.
- Exterior length with coupling tips 6.86 model units; body shell length 5.98, width 1.48, overall width 1.607; bogies centered about +/-2.036. Units provisionally map to tiles in horizontal orientation only. Wheel bottom Z=.02. Two rigid arm lengths 1.18 each solve the same planar inverse-kinematics geometry in both positions, with error under 1e-9. Upper carbon strip top Z=4.0627704, down Z=2.2625. This is a visual static pose check, not continuous animation or collision/clearance proof.

## Native reference and projection
- Official [Base 2.1.24 trains.lua](https://github.com/wube/factorio-data/blob/acf5a342afcb66c066b9d88d202e8622112da117/base/prototypes/entity/trains.lua): vanilla cargo wagon and locomotive joint_distance=4, connection_distance=3. Collision boxes x +/-0.6; y +/-2.4 (wagon) and +/-2.6 (locomotive). These are physics dimensions, not art bounding boxes. Art reference body ~6 and spacing ~7: [FFF 133](https://www.factorio.com/blog/post/fff-133). [RollingStockPrototype](https://lua-api.factorio.com/latest/prototypes/RollingStockPrototype.html), [RotatedSprite.apply_projection](https://lua-api.factorio.com/latest/types/RotatedSprite.html) support 45 degree dimetric camera and direction correction; no naive constant vertical/horizontal art length. Exact Factorio sprite pivot, projection index correction, joint and draw_data behavior still need native in-game verification. No actual wagon raster in comparison frame.
- 0.1.48 source catenary_visual_geometry_045.lua and mast_visual_034.lua: long mast south of straight horizontal rail 1.5 tiles, NORTH contact y=128, shift=-3.375 => contact screen offset above rail 2.875 tiles. Short mast north of rail 1.5 tiles, SOUTH contact y=137, shift=-.51125 => 2.870625 tiles. Mean 2.8728125 tiles =91.93 game px at 32/tile. At assumed orthographic pitch 45 degrees, upright collector Z=2.8728125*sqrt(2)=4.0627704. Previous model collector top Z=3.2625 => 18.1 game px short under this projection. Do not modify accepted wire heights. This result applies to the horizontal reference span and assumed ground pivot; other directions, curves, wire chords, render ordering and slope require a live probe, not a promise of exact contact everywhere.
- Optional calibrated renderer: 512x512 RGBA, ortho scale 4, fixed ground pivot approx (256,320), 64 source px/tile, scale .5 at 32 game px. Original model renderer default preserved. 8 sample orientations per state, not final native indices.
- Actual screenshot 2026-11-19_01-14-24.png from user's 047 test: bottom straight line mast locations (-16.5,2.5) and (12.5,2.5), logged separation 29 tiles, manually estimated 585 screen px or 20.17 px/tile at screenshot zoom. Crop x0..1100 y780..980. Left native-style locomotive is actual screenshot; right v2 render inserted with scale (585/29)/64 at (745,120) crop coordinates, without alteration to the track/wires. Contact line approx y61, rail center approx y120. Rendered collector head reaches roughly this level. Montage not game evidence. Native-style engine visible length approx 6.8-7 tiles, v2 6.86 model units including couplers. Actual vanilla wagon image not available in that frame: wagon comparison source-derived (shared joint/connection distances), visual train-coupling test pending.

## Reproduction
```sh
python scripts/sprites/refine_049.py --out build/qa/locomotive049_v2
```
Requires numpy, trimesh, vtk/EGL, Pillow. 16 frames, two GLBs. Refiner Git blob efdc37ae7c472476dd6fa9862ba93c616a10a947; renderer blob cdf89cb8ef3d17f4295aa70471f621b4167fbeda. Local QA images and GLBs not binary-committed; outputs are recreatable from source (screenshot montage uses user's original).
- preview_049.png SHA256 5279fc7c91e8613672ec892fbee30bbe35ea3344d6bb4cd88f4dc81090562ac0
- game_scale_comparison.png SHA256 a26462ba04c165db5b786f8ffdb9adb962af085905c9b46cd8150e392167297f
- locomotive_049_up.glb SHA256 35921fc550d7e7842a6502b8d8e46ca1f9b8e4f646ee88d90b041732244649d2
- locomotive_049_down.glb SHA256 93ed778c81a9fad465a9c0e214d16d4a7b2bc06afd71dbd617d2934bf671724c

## Remaining
Owner art review, actual separately rendered tint mask/shadow passes, native wheel alignment, direction/pivot and pantograph contact runtime probe including real vanilla wagon and both styles of masts, all axes and curves. Full atlas not yet generated. CI-only game ZIP rule unchanged. No runtime or main change.
