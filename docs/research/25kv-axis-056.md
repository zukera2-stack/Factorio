# 0.1.56 decorative rail-axis research

## Evidence and analogue
Owner screenshots 2026-11-19_22-02-53.zip, especially second screenshot: parallel track gaps and oblique spans. Baseline commit e0620fc9d3dd82b734a6b1c86135e760ba37df0d (055). Read scripts/power_019.lua, catenary_visual_policy_047.lua, catenary_art_030.lua, ghost_mast_023.lua, mast_facing_022.lua and catenary_corridor_017.lua. Existing 017 corridor follows actual HSR connections; 022 projects to RailEnd geometry. Factorio API https://lua-api.factorio.com/latest/classes/LuaEntity.html documents get_rail_end and get_connected_rail returning neighbour and its end pointing back to origin. Latest docs are not guaranteed identical to owner's exact 2.1.24 build; existing exact API use confirmed in 017/022. No new prototype flags or engine writes.

## Hypothesis
Proximity ranking before route filtering consumes degree on parallel tracks; technical component gate can suppress otherwise valid decorative spans. Project each mast independently to nearest sampled rail centreline; walk each native connected end away from mast, stop at first mast, accept reciprocal choices within 32 arc tiles and reject looping shortcuts. No candidate from disconnected rail. At switches a single nearest reciprocal branch per direction is intentional; other branch requires own supports. Approximate Bezier arc, not exact native spline; game validation required. Keep physical taut contact chord between authentic mast anchors, no new rendering sprites. Keep technical network 046 and its rail association/path unchanged; no voltage implication.

## Tests
Pure Lua parallel lanes, intermediate mast, interruption/restoration, loop rejection, curve projection. Integration mock with native end locations and directions, ghosts, actual rendering, failed technical connection independent, intermediate pole. CI ZIP pending. Live tests: both mast sides, independent parallel routes, curves A/B, switches, rail removal/restore, blueprint ghosts, technical audit unchanged.

> **056 second CI blocker diagnosed:** run 44604091272 passes corrected 028/029 and 042 tests, then fails 048 visual geometry fixture at line 77 because its synthetic edge lacks the new axis=true contract. Preserve all 16 endpoint and lifecycle assertions; for 056 additionally assert unqualified edges are rejected and mark the synthetic accepted edge as axis-qualified. No runtime or graphics change. Full CI pending.

