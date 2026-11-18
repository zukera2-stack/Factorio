# Contact / messenger / dropper sprites and curve QA — 0.1.43

**Experiment only.** Branch `experiment/25kv-sprite-wires-043` forked from `main` 0.1.42; stable main remains unchanged.

## Art format and provenance

Three PNG assets produced from the user-approved Factorio-style copper contact wire, gray steel messenger cable and riveted steel/copper vertical dropper. Files use transparent RGBA PNG:
- `graphics/entity/25kv/contact-043.png` — 128×10.
- `graphics/entity/25kv/messenger-043.png` — 128×10.
- `graphics/entity/25kv/dropper-043.png` — 10×32.

The runtime sprite prototypes in `prototypes/catenary_art_030.lua` keep width, height and `flags={"no-crop"}` from 0.1.42. These are literal PNG assets in the mod, not runtime-generated raster files. SHA-256 and dimensions are enforced by `scripts/verify_043_assets.py`.

## Graph and rendering

`power_019.rail_path_info` already traverses actual connected ВСМ rails; 0.1.43 extends its Dijkstra-like search to carry a *parent-linked sequence of rail entity centre coordinates*. A curved contact edge stores the route. `art030.curve_geometry` maps internal rail centres into the connector-to-connector wire frame, smooths with Catmull-Rom and samples into short textured straight PNG segments, plus steel messenger droop and copper-riveted vertical droppers. This is an **approximation of the visual route**, not Factorio's exact curved rail spline or an exact pantograph contact wire offset.

Straight spans also use multiple shorter copper segments for consistent texture; existing attachment coordinates and `NORTH_DROP=2.02` remain untouched. `em-25kv-contact-anchor` still stores the native curved electrical-connector graph; `draw_copper_wires=false` hides the former stock copper representation. No MW traction.

## Automated evidence and remaining risks

- `tests/25kv_curve_sprites_043.lua` checks endpoints, non-collinear sampled curve shape, 16-tile curve limit, messenger height, dropper count, and a mocked `rendering.draw_sprite` integration that draws all three 043 sprite families and reuses IDs on re-sync.
- `scripts/verify_043_assets.py` checks PNG dimensions, RGBA, checksum, names and visibility flags. CI packages the 043 PNGs and verifies ZIP bytes.
- Geometry is **not guaranteed to coincide with the native rail spline on one or two curved rail entities**, because rail entity centres are not the engine's full path geometry. Catmull-Rom can produce edge artifacts at sharp turn transitions. Curves need **user's in-game screenshot** before promotion.
- Verify straight, curved A/B, half diagonal, junctions, a removed middle rail, Undo/Redo, ghosts/robots and save/reload using `TEST_CURVE_043.txt`. Check no remnants of the native brown wire and no ghost double drawing.
- If preview differs from in-game rail centre, adjust curve sampling in another experimental revision; **do not adjust approved mast sprites or NORTH_DROP**.

External Factorio API reference: https://lua-api.factorio.com/latest/classes/LuaRendering.html ; https://lua-api.factorio.com/latest/classes/LuaEntity.html .
