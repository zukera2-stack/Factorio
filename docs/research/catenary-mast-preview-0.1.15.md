# Research 0.1.15 — non-mutating rail-side mast position preview

## 1. Research metadata

- **Feature:** preview two geometric mast candidates per engine-supplied signal slot, with collision hints and cantilever-facing indicators.
- **Opened:** 2026-11-14.
- **Branch:** `feature/catenary-preview-015`, based on `9916f11758491f29d3c89a8628ae2a78d6fe39d5` in `feature/catenary-visuals-014`.
- **Game target:** Factorio 2.1.20 build 87512, base 2.1 dependency; user modpack details for this test not independently verified.
- **Proposed version:** ElectrifiedMainline 0.1.15.
- **Research status:** ready for read-only experiment; gameplay unverified.

## 2. Exact behavior and boundaries

On an existing custom ВСМ rail, the player runs `/em-35kv-preview [offset]` (default 1 tile). The command finds the selected or nearest custom ВСМ rail (same scope as 0.1.14), gets engine rail signal slots, and paints **two possible mast bases** at offsets left/right perpendicular to each slot direction. Each base is annotated with the **existing eight-face arm sprite direction** (toward the reference slot) and a live `LuaSurface.can_place_entity` collision-check result. Colored circles and a short guide line disappear after 15 seconds.

This experiment **does not** create or teleport electric poles, rail signals, ghost entities or rails; register events or manipulate Undo; alter existing sprite/power-graph logic; validate HSR-only actual placement; or prove the arm reaches track center. The slot is a geometry reference, not proof of a correct overhead wire target. Offsetting from a signal slot is a hypothesis to inspect visually, not a physically calibrated placement rule.

## 3. Falsifiable acceptance test

1. Run command on selected straight custom ВСМ rail, with candidate offset `1` and optionally `1.5`; see labeled L/R candidates, direction toward reference points, temporary markers and collision state.
2. Repeat on curved-A, curved-B and half-diagonal rails; compare candidate bases against track center, mast silhouette and neighbors, and note which side/offset looks usable.
3. Run near vanilla rails with no custom ВСМ in 10 tiles; expect a message and zero preview objects.
4. Run with invalid parameters (`0`, `abc`, `4`); expect a usage message, no render objects.
5. Place/remove no entities with this command. Verify normal train signals, rails and existing masts remain unchanged; Undo/Redo should not get a new action from running the command.
6. API/rendering failures or incorrect orientation on curves falsify applicability of these candidate anchors; adjust geometry only in a later isolated experiment.

## 4. Analogue search and provenance

| Kind | Source (exact location) | Revision / API version | Verified use and limitation |
| --- | --- | --- | --- |
| Native | [LuaRailEnd](https://lua-api.factorio.com/latest/classes/LuaRailEnd.html), [RailLocation](https://lua-api.factorio.com/latest/concepts/RailLocation.html) | public docs observed 2.1.17 and 2.1.20 respectively | End supplies in/out/optional alternate signal locations with position, direction, rail layer. |
| Native | [LuaRendering](https://lua-api.factorio.com/latest/classes/LuaRendering.html), [LuaSurface.can_place_entity](https://lua-api.factorio.com/latest/classes/LuaSurface.html#can_place_entity) | public docs observed 2.1.24 | Temporary circles, lines and text; collision query without entity creation; exact 2.1.20 execution must be tested. |
| Adjacent same rail API | [LeonSkills RailSignalPlanner rail.lua lines 120–165](https://github.com/LeonSkills/FactorioMods/blob/bb63ebe6c839e122169b90635a1f108ab48d702b/mods/RailSignalPlanner/scripts/objects/rail.lua#L120-L165) | `bb63ebe6c839e122169b90635a1f108ab48d702b`, repo source mod info 2.0.2 / Factorio 2.0 | Consumes rail-end signal locations for real signal planning. Not a same-type electric pole preview; no source copied. |
| Own 0.1.14 | `ElectrifiedMainline/scripts/rail_slot_debug_014.lua` | `9916f11` branch baseline | Uses four ВСМ rail names and deduplicates slot locations. Reuse for read-only experiment. |
| Own 0.1.12 | `ElectrifiedMainline/scripts/overhead_geometry_012.lua` | 0.1.14 branch baseline | Maps position-to-reference vector to the existing 8-facing graphics names. |

No working same-type `electric-pole` mod that exposes these exact signal-slot-based hypothetical candidate positions was established; this remains a **read-only diagnostic**, not a placement implementation. The earlier 0.1.14 analogue search is recorded in [catenary-rail-signal-slots-0.1.14.md](catenary-rail-signal-slots-0.1.14.md).

## 5. API / prototype comparison

| Behavior | Factorio API | Existing code | 0.1.15 scope |
| --- | --- | --- | --- |
| Train block semantics | `LuaRailEnd` geometry is read-only; real `RailSignalPrototype` changes train logic | custom mast is `electric-pole` | no signal entities |
| Entity/placement/Undo | `LuaSurface.can_place_entity` is a collision check only | actual mast remains an ordinary pole | no builds/refunds/Undo calls |
| Graphics facing | `LuaRendering.draw_circle/draw_line/draw_text` creates temporary render objects | 8 custom faces via `overhead_geometry_012.face` | guide-line **estimate**, no visible sprite modification |
| Rail type filter | `LuaEntity.get_rail_end`, `RailLocation.rail_layer` | `rail_slot_debug_014.collect` and `.nearest_rail` | only the four custom ground ВСМ shapes |
| Curves | `RailLocation.direction` is an engine-defined direction, not guaranteed local rail tangent | old `rail_tangent` approximates nearest rail center | two symmetric normals as **hypotheses**, never auto-choose |

Target API exact version availability varies: RailLocation docs were 2.1.20, LuaRendering and can_place_entity 2.1.24, LuaRailEnd 2.1.17. Source inspection does not establish execution correctness in the installed game.

## 6. Hypothesis and minimal design

- Use `angle = (slot.direction % 16) * pi / 8`. A screen/world normal to the signal's facing is `(cos(angle), sin(angle))` under Factorio direction 0=north/4=east. Candidate bases are `slot.position ± offset * normal`.
- Use `view.face(candidate.position, slot.position)` to show the **proposed** cantilever-facing compass direction. This points at a **signal reference**, not necessarily the track's contact-wire centerline.
- Query `surface.can_place_entity{name="em-35kv-catenary-pole", position=..., direction=defines.direction.north, force=rail.force}`. Report the answer as **collision clear/blocked**, not proof of permitted HSR-only placement.
- Skip non-ground slots. Bound offset to 0.5–3.0 tiles. Maximum marker count is 2 × number of slots returned by one rail (typically small). Render only for invoking player with TTL 900 ticks.
- Avoid new global storage and event handlers. Require module at control script parsing time (0.1.14 runtime require regression).
- **Rejected:** instantly teleport/recreate actual masts; clone invisible train signals; guess a single "best" side from curved rail entity center. All may damage geometry, signal blocks or Undo behavior.
- **Rollback:** drop branch or revert preview module/command; saves are not migrated.
- **Failure conditions:** wrong normal handedness, misleading direction at curve ends, user-observed collision disagreements, unexpected API errors or duplicate confusing markers.

## 7. Implementation record

Implemented in `ElectrifiedMainline/scripts/mast_preview_015.lua` and registered at control.lua parse time (commit `d07755c0f3491003d7bc7558b5f0c3b84c7d1d80`). Added mocked checks `tests/35kv_preview_015.lua`, test plan `TEST_PREVIEW_015.txt`, metadata version 0.1.15, CI build workflow and synchronized PROJECT_STATE/AI_CONTEXT. No external code/assets copied. CI: GitHub Actions [build #43572452213](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213) passed Lua 5.2 syntax, 0.1.13 visual tests, 0.1.14 signal-slot tests and the new 0.1.15 mocked candidate/collision tests; produced [ZIP artifact #14105370603](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213/artifacts/14105370603). [Documentation CI #43572508712](https://github.com/zukera2-stack/Factorio/actions/runs/43572508712) passed. **No actual Factorio 2.1.20 session for 0.1.15 yet.**

## 8. Game experiment

**Partial in-game screenshot confirmation (2026-11-14):** seven user-supplied screenshots show the 0.1.15 command rendering candidate rings, guide lines and CLEAR/BLOCKED labels on straight horizontal/vertical rails and curves A/B at offsets 1.0 and 1.5. See [detailed per-file observation table](../tests/catenary-preview-0.1.15-screenshots-2026-11-14.md). All shown commands list 0 non-ground slots skipped and no API_ERR. At offset 1.5 curve A has 6 CLEAR/4 BLOCKED among 10 candidates; `alternative_in` slot 3 has *two* CLEAR candidates, so collision results do not establish a unique position. Curved markers/labels crowd each other. Exact Factorio build not printed on screenshots; screenshots do not prove actual mast alignment, HSR-only placement or Undo/Redo. The earlier **0.1.14** screenshot only established 4 signal markers on one track.

## 9. Evidence labels and next step

**API-confirmed** at documented versions: temporary rendering and collision checks are available, rail slots expose positions/directions. **Game screenshot-tested (limited):** visible 0.1.15 marker command on horizontal/vertical straight and curved A/B rails at offsets 1.0/1.5. **Unverified:** safe offset, intended mast/arm position, half-diagonal, negative cases, Undo/Redo, and exact game build identification. Next: install 0.1.15 test ZIP from Actions and compare one straight, one half-diagonal and both curves with screenshots, no placement.

## 10. Source use

No third-party code or artwork is copied; implementation is to be original and uses documented engine APIs and the project's own geometric helper.
