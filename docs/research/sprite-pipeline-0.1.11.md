# Sprite pipeline research — ElectrifiedMainline 0.1.11-dev

## 1. Research metadata
- Date: 2026-11-13.
- Branch: `feature/sprite-pipeline-0111`, based on 0.1.10 commit `592253eef2af581af73a56375148696524f18856`.
- User game: Factorio 2.1.20 build 87512; installed mod graphics: 0.1.10.
- Official online docs actually inspected: **latest 2.1.24** (NOT 2.1.20; 2.1.20 URLs were unavailable in web research).
- Status: API study complete for design; implementation, data-stage and game testing pending.

## 2. Exact task and acceptance
Build an independently reproducible pipeline accepting artist-created transparent source PNGs (including images generated with an image model) and producing sprites, a human-readable QA report, contact sheets and a manifest of verified dimensions/scale/shift. Reject corrupted stripe-pattern images, opaque/checkerboard backgrounds, cropped geometry, alpha halos and incorrect image dimensions. Do not silently substitute a new image for a failed source. No changes to 0.1.10 power graph or Undo.

## 3. Native analogue / code provenance
- Native electric poles: `data.raw["electric-pole"]["small-electric-pole"]` is the base prototype cloned by our `ElectrifiedMainline/prototypes/power_019.lua`; its `pictures` field is inherited unchanged. Exact installed Base sprite sheets were **not inspected** because game files are not in this repository. The current mod is the exact inspected analogue source, not proof of new art integration.
- Native substation: `data.raw["electric-pole"]["substation"]` cloned in the same source file. No art modification planned at this stage.
- Current contact/feeder wires: `ElectrifiedMainline/scripts/power_019.lua` uses `rendering.draw_line` and stores render IDs. Replacing them with textured sprites will be a later, separate game-tested change.
- Third-party mods: no external source code or art used. Licensing must be checked for any imported asset.

## 4. Official API study (latest 2.1.24, **not version matched**)
| Topic | Official API | Consequence |
|---|---|---|
| Pole graphics | https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html | `pictures` is `RotatedSprite`; `connection_points` are for native wires; `maximum_wire_distance`, `draw_copper_wires`, `auto_connect_up_to_n_wires` are independent from decorative graphics |
| Rotated entity sprites | https://lua-api.factorio.com/latest/types/RotatedSprite.html | `filename`, `width`/`height` or `size`, `direction_count`, `scale`, `shift`, `layers`, `draw_as_shadow`; if `layers` exists, put all actual sprite definitions inside the layers array |
| Sprite parameter semantics | https://lua-api.factorio.com/latest/types/SpriteParameters.html | `shift` measured in tiles, `scale` scales sprite at normal zoom; `draw_as_shadow` belongs on a sprite layer |
| Dynamic world sprites | https://lua-api.factorio.com/latest/classes/LuaRendering.html | `rendering.draw_sprite` takes `sprite`, `target`, `surface`, optional `orientation`, `x_scale`, `y_scale`, `render_layer`; `rendering.draw_line` remains supported |
| Sprite registration | https://lua-api.factorio.com/latest/prototypes/SpritePrototype.html | Data-stage sprite registration required before using a named mod sprite in runtime; exact SpritePath syntax must be confirmed before integration |

The RotatedSprite documentation explicitly notes a maximum input texture width of 8192 px for its spritesheet layout. Pipeline will conservatively enforce **both dimensions <=8192**; the height check is a project QA policy, not a cited Factorio engine limit.

## 5. Current code versus desired art
- Current `em-35kv-catenary-pole`: clone of `small-electric-pole` with `maximum_wire_distance=0`, `supply_area_distance=0`, `auto_connect_up_to_n_wires=0`, `draw_copper_wires=false`, `draw_circuit_wires=false`. New art must not alter these fields.
- Current visual wires: two simple lines for contact and one blue line for feeder. A stretched horizontal PNG alone cannot represent all curves, sag and wire support geometry; later runtime work must align textured segments to graph edges and verify orientation in game.
- A PNG file does not prove correct in-game scale, pivot or shadow sorting. That requires an actual data-stage prototype and Factorio 2.1.20 screenshot.

## 6. Falsifiable minimal design
1. Keep all generated previews **outside** the mod folder until human art approval.
2. Define a machine-readable asset spec with expected pixel dimensions, anchor pixel, scale, min alpha coverage and min transparent margin.
3. Generate deterministic illustrative source images for CI smoke tests; production mode accepts only externally supplied transparent PNGs, never substitutes demo art.
4. Normalize RGBA, strip hidden RGB from transparent pixels, validate alpha/edge/colour variety, crop limits, anchor proximity and dimensions; fail closed.
5. Emit 2x-ready RGBA PNGs, calculated Factorio `shift` in tiles, SHA-256 manifest, and side-by-side preview on dark/light/checker backgrounds.
6. Add negative tests for repeating 8-pixel vertical stripes, opaque background, missing alpha, truncated art, incorrect dimensions.
7. In a **separate** commit after art approval, wire a real `RotatedSprite` prototype and registered wire sprite, then run Factorio data-stage + save/Undo/Redo tests.

## 7. Stop conditions / limitations
- Static validation is NOT an image aesthetics judge and cannot prove a perfect Factorio art match. A human reviews a contact sheet at normal game zoom.
- Documentation version mismatch 2.1.24 vs installed 2.1.20 remains unresolved until game load.
- No power transfer, rail signal snapping or rail topology behavior is modified by this pipeline.
- No third-party art or game sprite files copied.
