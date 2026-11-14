# Research 0.1.16 — reduce mast candidates using the native rail-end location

**Opened:** 2026-11-14  
**Branch:** `feature/catenary-geometry-016`, from 0.1.15 at commit `727e998b5e4698298adc5a4f1b04c50bd5fba212`.  
**Target:** Factorio 2.1.20 build 87512, ElectrifiedMainline 0.1.16.  
**Status:** design/hypothesis; gameplay not tested.

## 1. Specific behavior and motivation

Seven user screenshots from [the 0.1.15 experiment](../tests/catenary-preview-0.1.15-screenshots-2026-11-14.md) show `/em-35kv-preview` successfully rendering **8 candidates from 4 signal locations on a straight rail**, and **10 from 5 signal locations on a curved rail**. Red and green collision indicators appear, but the curves contain overlapping labels and candidate sites; for one curve A slot two positions are both `CLEAR`. These are *not* approved mast placements. 0.1.15 used the **signal location** as both a reference and an offset origin.

0.1.16 will be **an isolated read-only experiment**: `/em-35kv-geometry [offset] [index]`. Its default offset is 1.5 tiles. It creates at most **four candidate bases**, one to each side of each selected HSR rail **end**. The candidate position and facing come from the rail-end's engine-defined `location.position` and `location.direction`, **not** from signal locations or the nearest rail entity center. A small numbered ring identifies each candidate, and one selected candidate gets a translucent preview of the project's existing Г-shaped facing sprite at its actual full size. The command never creates/teleports/destroys a mast, ghost, rail or signal, joins Undo, or transfers MW.

## 2. Native source and API checks (revision boundaries)

| API or implementation | Verified source/revision | What is actually known |
| --- | --- | --- |
| [LuaRailEnd.location](https://lua-api.factorio.com/latest/classes/LuaRailEnd.html) | Factorio Runtime Docs observed on 2026-11-14 (a 2.1.x latest page, not guaranteed identical to installed 2.1.20) | `location` is a `RailLocation` **of the rail end**, distinct from `in_signal_location` and `out_signal_location`. |
| [RailLocation](https://lua-api.factorio.com/latest/concepts/RailLocation.html) | Factorio API docs version **2.1.20** | Carries `position`, `direction`, `rail_layer`. Exact projected tangent interpretation needs gameplay check. |
| [LuaRendering.draw_sprite](https://lua-api.factorio.com/latest/classes/LuaRendering.html) | Factorio API docs version **2.1.24** | Can render a SpritePrototype by name with target, tint, players and finite TTL. Test runtime 2.1.20. |
| [LuaSurface.can_place_entity](https://lua-api.factorio.com/latest/classes/LuaSurface.html#can_place_entity) | Factorio API docs version **2.1.24** | Collision-only preflight query, not permission to build beside ВСМ. |
| Existing mast visuals | `ElectrifiedMainline/prototypes/power_019.lua`, `scripts/power_019.lua`, `scripts/overhead_geometry_012.lua` from branch parent `727e998` | `sprite="em-35kv-facing-"..face` is already used for existing poles; display offset `{0,-2.53125}`; face helper has eight compass faces. |
| Same-engine rail precedent | [RailSignalPlanner rail.lua lines 120–165](https://github.com/LeonSkills/FactorioMods/blob/bb63ebe6c839e122169b90635a1f108ab48d702b/mods/RailSignalPlanner/scripts/objects/rail.lua#L120-L165) commit `bb63ebe...` | Uses `get_rail_end` and signal positions. The public source inspected was Factorio 2.0; *not* proof of mast placement. |
| 0.1.15 in-game findings | [7 screenshots, 2026-11-14](../tests/catenary-preview-0.1.15-screenshots-2026-11-14.md) | Markers rendered on straight/curve A/curve B at offsets 1.0/1.5. No half-diagonal evidence. |

No working same-type `electric-pole` mod that uses native `LuaRailEnd.location` for actual placement has been verified. No third-party source copied.

## 3. Proposed minimal geometry and limitations

1. Select only the same **four** custom HSR rail prototypes as 0.1.15. If no selected/nearby HSR exists, print an informative message and draw nothing.
2. Read both `rail.get_rail_end(defines.rail_direction.front/back)` under `pcall` and inspect `end.location`. Skip non-ground or unavailable locations; do **not** silently fall back to arbitrary signal points.
3. For each end, angle `a = (location.direction % 16) * pi/8`; candidate base = `location.position ± offset * (cos(a),sin(a))`. This assumes the end direction follows the physical tangent and the given vector is the corresponding track-side normal. Both signs remain visible because **no side-choice algorithm has been accepted**.
4. Draw two **numbered rings per end**, at most 4 before de-duplication. Merge candidates whose base positions are within a small tolerance; do not suppress geometrically distinct positions merely because they share a tile.
5. Call `surface.can_place_entity` on each candidate. Mark `CLEAR` green, `BLOCKED` red, `API_ERR` magenta. These states do **not** guarantee overhead alignment, correct snap to pole placement grid, or exclusion of other rails.
6. Pick one candidate by explicit optional index or the nearest `CLEAR` to player position. Display only this candidate's real (currently installed in the mod) `em-35kv-facing-...` SpritePrototype at the same visual offset used by `scripts/power_019.lua`, with transparent tint, 15-second TTL and player-only visibility. Guide line points to **rail-end position**, not signal position or wire centerline. All labels are short, with detailed coordinates in console instead of long world text.
7. No new storage, prototype changes, surface mutation, event handlers or Undo modifications. Keep the 0.1.14 and 0.1.15 diagnostics for A/B comparison.
8. Abort gracefully on invalid offset/index or if rail-end API is unavailable. Never promise actual side-of-track restrictions from this read-only marker.

## 4. Observable test matrix (Factorio 2.1.20)

| Case | Expected | Evidence needed |
| --- | --- | --- |
| Straight E/W and N/S, offset 1.5 | <=4 candidate circles, one selected translucent mast sprite, arm points toward rail end | Screenshot + console |
| Curved A and curved B, offset 1.5 | <=4 rather than 10 candidates; no train signals constructed | Screenshot + console |
| Half-diagonal rail | <=4 markers and correct face; geometry could falsify normal assumption | Screenshot + console |
| Optional explicit index `/em-35kv-geometry 1.5 2` | highlight and sprite only candidate #2 | Screenshot |
| Empty ground/only vanilla | no marker and clear console message | Console |
| Invalid offset / index | no drawing; usage or out-of-range message | Console |
| Existing signals, poles and Undo | unchanged after this command; no native Undo entry created by preview | Game observation, log |

**Falsification criteria:** incorrectly oriented sprite on a curve/half-diagonal; missing valid rail-end location on a supported HSR rail; candidate markers on the center of track; matching an adjacent unselected rail rather than the selected rail. If this fails, refine the geometric model *before* real pole placement.

## 5. Expected implementation record

Create `scripts/mast_geometry_016.lua`, register one command via **top-level require** in `scripts/control.lua`, bump `info.json`, add mocked test and game test worksheet, and explicitly include **0.1.16** in GitHub Actions Lua 5.2 regression flow. Keep 0.1.15 tests active. Update `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml`, `docs/STATUS.md` and `CHANGELOG.md` atomically with source.

**Code, CI, real game results:** to be recorded after implementation. Static CI is not gameplay proof.
