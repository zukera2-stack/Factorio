# 0.1.45 — unified visible catenary geometry (research, 2026-11-18)

## 1. Provenance
Parent d3a1ff60eb15e3a37e19fc4a762b4466220b409a, 0.1.44. Stable main 0.1.42 remains untouched. Target Factorio 2.1.24 build 87808. User archive `2026-11-18_22-16-41.zip`, SHA256 `6eb0422b087441da787665ccccdc9eef4c09a980619534cf9c6314353b7aed10`; 11 screenshots, no new runtime log. Source PNGs extracted from Actions artifact 14447154704 (parent). Exact IDs and world positions cannot be recovered from images alone.

## 2. Observations (not graph proof)
| Screenshot | Visible observation |
| --- | --- |
| 22:16:41 | missing span upper/middle long masts |
| 22:17:20 | missing adjacent curved span |
| 22:18:10 | long-mast near-aligned ends; slanted droppers |
| 22:18:22 | long-mast chords visible on curve |
| 22:18:37 | near vertical conductors overlap |
| 22:18:47 | missing spans around intermediate long mast |
| 22:19:01 | gap at straight/curve transition |
| 22:20:00 | short-mast ends visibly above hanger |
| 22:20:35 | short-mast wires above consoles |
| 22:20:49 | short horizontal span near-aligned, droppers slanted |
| 22:21:13 | upper short mast wire ends displaced |

## 3. Acceptance
All 16 combinations of native mast type and 8 arm faces: endpoints at manually identified pixel landmarks on unchanged PNGs, integrated render arguments checked against those landmarks. Horizontal/vertical/diagonal/chord, mixed types, no stale duplicates, removal. In game: new save copy, build both sides around curve, screenshot ends, select each gap mast and collect read-only pair report, remove rail, undo/redo, robots, reload. No game acceptance without screenshots/log.

## 4. Analogue / API
Working local same-entity precedent: 0.1.42 accepted native poles with separate arm layer; `scripts/power_019.lua:51-67`, `scripts/ghost_mast_023.lua`, `prototypes/power_019.lua` at parent. 044 successful visible chords reuse `rendering.draw_sprite`. Official LuaRendering draw_sprite target is sprite center, with existing entity offset and scale; [runtime docs](https://lua-api.factorio.com/latest/classes/LuaRendering.html) retrieved 2.1.25, adjacent to installed 2.1.24; [ScriptRenderTarget](https://lua-api.factorio.com/latest/concepts/ScriptRenderTarget.html) 2.1.24. No new prototype flag or render API needed. No local Factorio binary/base install; existing accepted local analogue sufficient for pure coordinate refactor, not for changing topology.

## 5. Comparison
Arm is 512x384 at scale 0.5, 32 game pixels/tile, offset mast034.cantilever_shift(name) for both real and ghost. Old hidden helper FLOOR offsets and HEIGHT/VISUAL_OFFSET/visual_delta use a separate historical calibration, including conditional SHORT_NORTH south-only drop and STANDARD north-only lift. Difference of image shifts = 2.86375 tiles; **not identical to the actual old endpoint error**, which varies with face. PNG alpha inspection gives identical 132x83 motif translated/reflected. Contact chose center of lower triangular metal crossbar, messenger chose central upper metal clamp (existing art has no separate purpose-built messenger lug); both are explicit visual conventions, not a new asset. Test pixel mapping; preserve hidden anchor geometry as existing logical calibration.

## 6. Design / falsification
Single pixel landmark source for all 8 PNGs; convert as (pixel - image center)*0.5/32 + exact arm shift, independently of invisible helpers. Real mast position supplies origin. Keep chord; messenger interpolates its OWN endpoints and sags, limited lateral bow only near vertical, droppers terminate on actual sampled polyline. Preserve graphic bytes, prototype names, rail topology, native helper calibration, Undo, limits, MW=0. Missing edges: accepted graph rejects opposite side, uses approximate tangent and nearest rail center, scores degrees; other causes possible. No change of graph without new evidence. Add read-only pair report with graph/rail path/filters/current helper and draw status. If endpoints differ from atlas in engine, verify rendering projection/asset registration; if missing edges persist collect report before altering graph.

## 7–9. Implementation and verification
Pending implementation in separate commit; no engine test yet.
