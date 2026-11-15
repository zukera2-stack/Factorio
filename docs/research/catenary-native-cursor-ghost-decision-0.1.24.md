# Decision: native cursor/ghost body, dynamic C cantilever — 0.1.24 candidate

**Decision date:** 2026-11-15. **Target:** Factorio 2.1.20 build 87512, ElectrifiedMainline 0.1.24 **future isolated art experiment**. Current working 0.1.23 remains unchanged until game-tested replacement.

## Direct evidence

[0.1.23 gameplay report](../tests/catenary-visual-0.1.23-user-test-2026-11-15.md) documents icon PASS, ghost/robots/undo PASS as observed, world cursor model missing. Real mast uses hidden native picture plus LuaRendering full C, so mouse placement preview currently renders only shadow. See `ElectrifiedMainline/prototypes/power_019.lua` and `ElectrifiedMainline/scripts/ghost_mast_023.lua`.

## Exact official API and working vanilla analogue

- [ElectricPolePrototype::pictures](https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html): a **RotatedSprite** as the pole's main entity picture. The engine consumes this image for regular pole graphics, native cursor placement and entity-ghost presentation. The corresponding [RotatedSprite](https://lua-api.factorio.com/latest/types/RotatedSprite.html) supports layers and `direction_count`; the user's 2.1.20 logs show placed electric poles always have direction 0, so eight directional mast selection **cannot** be solved by an ordinary R-key rotation of this entity.
- [EntityPrototype::placeable_position_visualization](https://lua-api.factorio.com/latest/prototypes/EntityPrototype.html) is a supplemental sprite, **not a promised replacement** for native `pictures`. [Wube Factorio data](https://github.com/wube/factorio-data/blob/master/space-age/prototypes/entity/entities.lua) uses it for a **cursor-box frame on the thruster**. Our 0.1.23 field didn't make the cursor model visible in the actual user's game. The previous interpretation that it would render the full mast was **incorrect**.
- [LuaRendering](https://lua-api.factorio.com/latest/classes/LuaRendering.html) draws a sprite at a provided world/entity target and auto-cleans entity-anchored render targets; our existing ghost overlay correctly follows real ghost entities. It does not claim to render the exact vanilla blurred ghost shader.
- [LuaPlayer](https://lua-api.factorio.com/latest/classes/LuaPlayer.html) exposes the cursor stack and cursor construction APIs; do not assume a `LuaPlayer.cursor_position` getter exists for continuous screen-to-world mouse tracking. [Events:on_pre_build](https://lua-api.factorio.com/latest/events.html) includes clicked position **at build time only**, too late for moving preview.
- [RadiusVisualisationSpecification](https://lua-api.factorio.com/latest/types/RadiusVisualisationSpecification.html) can display an extra sprite in cursor, but an electric-pole override binds its `distance` to `supply_area_distance`. Our distance must stay 0 to avoid enabling power range. Using range visualisation as a full pole model is not a robust demonstrated workaround, so **not selected**.
- [LuaEntity::color](https://lua-api.factorio.com/latest/classes/LuaEntity.html) does not allow electric poles to be made alpha-transparent at runtime (documented entity types do not include electric-pole). Thus enabling a full C `pictures` native image and trying to hide it only on built poles is not a reliable solution.

## Chosen architecture (next experiment, not yet implemented)

**Separate the C artwork into a fixed native base and a directed Lua arm**:

1. Generate **one common 512×384 RGBA mast body PNG** based on selected C art: lattice shaft, compact footing, no cantilever arm, no contact wire. Keep the original P0 anchor and render shift `{0,-2.53125}`, scale `0.5`.
2. In the `electric-pole` prototype, replace only the 1×1 hidden native sprite with that body and keep the existing base shadow layer. Native `pictures` will then display the mast body under cursor automatically, using Factorio's normal placement system. Real pole itself will also display this body.
3. For all eight approved C images, generate transparent **arm-only overlays** (single-sided cantilever, diagonal strut, insulator/contact point, any upper tip unique to direction), aligned to same P0 and P1. Runtime `rendering.draw_sprite` draws **ONLY the arm** on actual poles. The native shaft must not overlap a duplicate shaft in these overlays. Preserve the 0.1.22 RailEnd facing-selection algorithm.
4. For ghosts, engine automatically blurs/tints the **native shaft/body**. Existing `ghost_mast_023.lua` should draw **ONLY the direction-specific arm** with translucent blue tint; no double-drawing the body. The arm will be an approximation of vanilla ghost aesthetics, **not** identical engine shader effects. Preserve ghost creation, copy/paste, robot build, Undo/Redo, save/load events unchanged.
5. Remove the erroneous full-size `placeable_position_visualization` from the prototype or revert to an actual lightweight placement marker, after verifying that it doesn't hide the native body. Retain the approved SOUTH 64×64 inventory icon and current gentle circular ground slot indicators.
6. No Lua mouse polling, no fake proxy entities, no hidden rail signals, no item capsule placement, no change to physical pole names, grid, `supply_area_distance=0`, `maximum_wire_distance=0`, `connection_points` count 1, or construction lifecycle. User explicitly approved current placement/ghost behavior.

**Nonnegotiable art validation:** The eight source C sprites are not perfectly identical in their shafts; masks must be artistically normalized before gameplay. Do not simply composite opaque full frames. Initially produce just ONE trial native shaft and 2 arm overlays (south, northwest), inspect their P0/P1 alignment before all 8. If separation yields obvious artifacts at different facings, **do not silently ship**; keep 0.1.23 and investigate a different native rendering design.

## Acceptance / quality gates

1. Factorio 2.1.20 loads without electric-pole wire connection-picture count mismatch (prior 0.1.12/0.1.13 failure).
2. Held item shows a real mast shaft, not shadow only. No fake mouse cursor positions.
3. Real masts show exactly one shaft and exactly one cantilever; arms face track using 0.1.22 geometry.
4. A ghost shows blue native-style shaft plus tinted arm, and bots/copy/undo/remove/save/load remain unaffected.
5. Sprite dimensions, alpha, foot anchor and shift match current 0.1.23; icons, circle overlay unchanged.
6. End users test straight, curved A/B, half diagonal, parallel, blueprint, Shift+LMB ghost, robot build and Ctrl+Z/Ctrl+Y. CI static packaging is **not** a game test.
7. Do not merge to stable `main` 0.1.8 without explicit user approval.

**Implementation update 2026-11-15:** `feature/catenary-native-mast-body-024` implements the native shaft and eight arm overlays as experimental graphics. One common mast is extracted from exact original south C sprite with the cantilever area masked; each arm-only overlay is a directional C source masked to the cantilever joint/beam/insulator. The masks leave small seam/artistic differences on west/north orientations, intended for **game validation, not asserted final perfection**. No 0.1.24 runtime/game result yet. Original full sprites remain in the repository; backup via Git checkout is straightforward. CI [scripts/sprites/verify_024.py](../../scripts/sprites/verify_024.py) verifies SHA and 512x384 RGBA structural constraints. 0.1.24 ZIP is expected only after successful GitHub Actions.
