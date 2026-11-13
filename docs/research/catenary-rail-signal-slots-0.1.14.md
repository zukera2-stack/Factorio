# Research 0.1.14 — signal-style catenary placement on ВСМ, without signal behavior

**Date:** 2026-11-13
**Research branch:** `feature/catenary-visuals-014`
**Baseline source:** `ElectrifiedMainline` 0.1.13, commit `1067ac1344b3bdf4088dffcf97c53b209f1ff989`
**Game target:** Factorio 2.1.20 build 87512
**Evidence status:** API/source-confirmed where stated; algorithm proposed; **not implemented or game-tested**.
**User intent:** 35 kV cantilever masts are placeable **only beside custom ВСМ rails**, align and orient like rail signals, but never change signal blocks/pathing or affect actual rail and chain signals.

## A. Visible acceptance requirements

1. If a player holds a 35 kV mast next to any of the **four custom HSR rail shapes**, a placement mechanism identifies an engine-defined track-side slot, chooses the correct mast/arm orientation, and puts the cantilever over the track, including diagonals and curves.
2. Without a custom HSR rail, a mast cannot **remain placed**. Ordinary vanilla rails must not qualify.
3. Two adjacent connected tracks must not cause a mast to snap toward the wrong track. Existing rail/chain signals must retain their actual function and placement space.
4. Strict rejection **before** normal placement with rail-signal-style green/red ghost would be a separate goal; an ordinary `electric-pole` does **not** inherit this hard-coded native UI mechanism.
5. Player manual placement, fast repeated placement, bots, blueprints/ghosts, save/load, Undo/Redo, rail upgrades, rail removal, two-track crossings, modded forces/surfaces must be exercised independently.
6. No real MW traction supply in this visual workstream.

## B. Official Factorio APIs and prototype constraints

| API/prototype | Confirmed behavior | Implication |
| --- | --- | --- |
| [`LuaEntity.get_rail_end`](https://lua-api.factorio.com/latest/classes/LuaEntity.html) | Available for Rails; returns `LuaRailEnd` bound to front/back of rail | Use the **actual custom ВСМ rail instance**, not a guessed tangent or signal entity |
| [`LuaRailEnd`](https://lua-api.factorio.com/latest/classes/LuaRailEnd.html) | Exposes `out_signal_location`, `in_signal_location` and optional alternate positions | Engine provides **signal-style snap coordinates** without having to construct signals |
| [`RailLocation`](https://lua-api.factorio.com/latest/concepts/RailLocation.html) | Fields: `position`, `direction`, `rail_layer` | Can align a mast/ghost, select ground-only, then align art/arm toward rail center |
| [`LuaSurface.find_entities_filtered`](https://lua-api.factorio.com/latest/classes/LuaSurface.html) | Search by name, position and radius; collision-based filter | Restrict eligible anchor rails to the **exact four HSR prototype names** |
| [`LuaSurface.can_place_entity`](https://lua-api.factorio.com/latest/classes/LuaSurface.html) | Checks whether a candidate entity can be built at a specified position and direction | Check collisions for mast footprint and avoid native signal slots; a successful collision check alone does **not** prove presence of HSR |
| [`on_pre_build`, `on_built_entity`](https://lua-api.factorio.com/latest/events.html) | First event reports placement intention/coordinates; latter runs after the build | Script can validate after construction, but `on_pre_build` does not expose a documented veto/cancel switch |
| [`ElectricPolePrototype`](https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html) | Ordinary pole pictures use RotatedSprite and electrical connection fields, not rail-signal attachment logic | The existing mast **can remain a nonconducting electric-pole**, with rendering for eight faces; native signal snap is not inherited |
| [`RailSignalPrototype`](https://lua-api.factorio.com/latest/prototypes/RailSignalPrototype.html) | It is a train-control signal prototype, with no documented setting to become a decorative/non-block-dividing signal | Do **not** retype hidden 35 kV mast as `rail-signal`; this risks changing train blocks |
| [`RailSupportPrototype`](https://lua-api.factorio.com/latest/prototypes/RailSupportPrototype.html) | Has `not_buildable_if_no_rails` and `snap_to_spots_distance` but is for **elevated-rail supports**; non-dummy prototype requires Space Age | Not suitable for required ground-level custom masts or minimal base-only mod dependency |

**Documentation version note:** Live API search results have displayed snapshots from 2.1.17 through 2.1.24 (including 2.1.20 for `RailLocation`), so this is an API-backed proposal, **not a run of the exact 2.1.20 game binary**. Do not assume identical engine-placement preview semantics from the docs alone.

## C. Verified source analogues (examined directly on GitHub)

### 1. Rail Signal Planner: actual engine-computed anchor coordinates

- Repository: [LeonSkills/FactorioMods](https://github.com/LeonSkills/FactorioMods)
- Examined commit: `bb63ebe6c839e122169b90635a1f108ab48d702b`, branch `master`
- Exact file [`mods/RailSignalPlanner/scripts/objects/rail.lua`, lines 120–165](https://github.com/LeonSkills/FactorioMods/blob/bb63ebe6c839e122169b90635a1f108ab48d702b/mods/RailSignalPlanner/scripts/objects/rail.lua#L120-L165)
- Observed behavior: loops over rail `defines.rail_direction`, gets `rail.get_rail_end(rail_direction)`, retrieves `out_signal_location.position/direction/rail_layer` and incoming/alternate positions. In separate `objects/signal.lua`, it checks `surface.can_place_entity` and constructs signal ghosts/real signals for its own purpose. **Our mod should use just the coordinates, not those signal creations or planner code.**
- Source version: `info.json` in this observed `master` reports **2.0.2 / Factorio 2.0**; public mod portal has later 2.1 releases. **Those sources are not claimed byte-equal or same version.** The engine API mechanism is the useful part.

### 2. Factorio base prototypes: why signal types are not decoration

- Repository: [wube/factorio-data](https://github.com/wube/factorio-data)
- Examined commit: `acf5a342afcb66c066b9d88d202e8622112da117`, branch `master`
- Exact file [`base/prototypes/entity/trains.lua`, lines 1648–1691](https://github.com/wube/factorio-data/blob/acf5a342afcb66c066b9d88d202e8622112da117/base/prototypes/entity/trains.lua#L1648-L1691)
- Observed: both signals have their own `rail-signal`/`rail-chain-signal` type, 16-direction native placement and separate picture sets. This is not the same prototype mechanism as `electric-pole`. GitHub master and the installed 2.1.20 file may differ; the project's copied `Исходник_v2.1.20b/trains.lua` was also inspected.

### 3. Rail Signal Planner / placement and a negative catenary example

- [Mod portal: Rail Signal Planner](https://mods.factorio.com/mod/RailSignalPlanner) confirms maintained 2.1 support including diagonal and curved rail geometries; GitHub source version mismatch above is disclosed.
- [Realistic Electric Trains Continued](https://mods.factorio.com/mod/Realistic_Electric_Trains_Continued_2SE) publicly reports that former *plain* poles were previously implemented as hidden one-way signals and caused pathing problems on bidirectional tracks. After changing entity type, existing poles were removed on migration. **Description-only evidence**: this mod's portal says source N/A, so implementation code was not inspected.
- [Electrified Railways by AudricSan](https://mods.factorio.com/mod/ElectrifiedRailways) (2.1) describes snapping catenary gates to fixed rail-side slots and visually centered double overhead wires. **Description-only evidence**: the exact GitHub source repository and code were not verified via accessible links in this session; do not copy or imply its implementation has been examined.
- [RailTools source](https://github.com/dewiniaid/RailTools): inspected `librail.lua` and repo metadata; this older rail tool builds genuine signal ghosts and is an API/geometry inspiration, not a ready-made no-signal mast placement engine. Source not compatible with Factorio 2.1 out of the box.

## D. Current 0.1.13 implementation vs requirements

- [`prototypes/power_019.lua`](../../ElectrifiedMainline/prototypes/power_019.lua) creates `em-35kv-catenary-pole` by cloning `small-electric-pole`, disabling copper reach and rendering a hidden base sprite.
- [`scripts/power_019.lua`](../../ElectrifiedMainline/scripts/power_019.lua) detects nearest HSR rail within radius 3 after placement and renders one of eight facing sprite prototypes. A mast **without rail is allowed to remain**, but it prints a warning and draws an east-facing fallback. It never uses `get_rail_end`.
- The present nearest-rail visual algorithm uses the **rail entity center** and approximation for tangents. For a curved rail, the rail entity center is not necessarily the correct physical point to attach a signal-like mast. This can explain some unsatisfactory alignment, but exact gameplay causality remains unverified.
- Power-graph logic and Undo handling should remain separate from the proposed placement resolver.

## E. Recommended original design — no copied source, no new signals

**Phase 1: deterministic rail-side slot resolver.**
1. Search within bounded radius around the target for only `em-high-speed-straight-rail`, `em-curved-high-speed-rail`, `em-curved-high-speed-rail-b` and `em-half-diagonal-high-speed-rail`. Filter force/surface as appropriate.
2. For each candidate HSR rail, inspect both `rail.get_rail_end(defines.rail_direction.front/back)`. Read `out_signal_location`, `in_signal_location` and optional alternatives. Filter `rail_layer == defines.rail_layer.ground`.
3. Keep valid position and direction. Normalize into a **deduplicated candidate set** (on shared rail endpoints, two rail ends can return the same slot). Rank by distance to cursor and track side, deterministic tie break on rail identity and coordinates. Avoid occupied real signal/chain-signal positions if the mast footprint would collide.
4. Choose the mast's actual position from an **independently tested dedicated mast slot** derived from the native signal location (possibly offset from signal, not assumed exactly equal to it). Then `surface.can_place_entity` checks actual mast collision; a cross-track occupancy/minimum spacing check rules out duplicates and unintended neighbouring line.
5. Derive arm facing and wire anchor **from the chosen rail/slot's actual geometry** and the mast's final position, not from a second nearest-center query. Persist associated rail identity / geometric slot key.
6. If there are no qualifying custom rails, the placement request must be rejected via a tested build workflow. Not merely a no-rail warning.

**Phase 2: input/placement integration**, select after prototype test:
- **A. Current native item + post-build validation/snap**: minimal UI change; can reject invalid player placement after the build event. Must investigate item refund and native Undo/Redo, callbacks for robots and ghosts; avoid immediate blind `teleport` or destruction and cannot promise native pre-place green/red preview.
- **B. Dedicated placement tool**: own tool selects a track slot and creates a pole ghost (or construction request) only when HSR is present. Best way to guarantee no intentionally off-rail creation before placing, but more UX and undo/blueprint integration work. Evaluate as a separate prototype test.
- **Never C. Clone rail-signal/chain-signal and make it invisible**: unsafe railway semantics.
- **Never D. Clone rail-support** for ground poles: elevated-support behavior and Space Age requirement are unrelated.

### Proposed independent experiment (read-only, before mutation)

On a copy of a game save with four ВСМ shapes, implement a DEBUG command that displays the 2–4 engine-reported RailLocations of the nearest custom rail as tiny colored points with small direction arrows, and count unique slot positions. It should **not spawn any signal or move/delete an existing pole**. Print `rail.name`, `rail.direction`, front/back, slot `position/direction/rail_layer` in log. Check both sides of a 90° curve and an intersection. Once the marker geometry is observed, choose an offset and the actual user-facing builder. This is the minimal falsifiable first test.

## F. Regression / test matrix for any later 0.1.14 code

| Test | Expected | Current evidence |
| --- | --- | --- |
| Ground custom straight, two sides | Correct mast/arm, near engine slot | Not tested |
| Half-diagonal and both curved A/B | Stable slots, no clipping | Not tested |
| Vanilla rail only or empty ground | Pole cannot remain | Not implemented |
| Crossing / parallel ВСМ | No wrong-rail snap/duplicate | Not tested |
| Native signal and chain signal next to mast | No conflicts, no changed train blocks | Not tested |
| Player fast-build / ghosts / blueprint / bots | Correct inventories and construction | Not tested |
| Undo/Redo after place and invalid request | Native history stays coherent | Not tested |
| Build mast before rail ghost | No permanently orphaned mast; deterministic behavior | Not tested |
| Remove HSR after build | Mast remains inactive/marked as appropriate; no stray wire | Policy TBD |
| Save/reload and multiplayer | Deterministic slot choice and wire rendering | Not tested |
| 100+ supports | No pathological per-tick scanning | Not tested |

## G. Decision

**Yes, the placement geometry of signals is reusable via a public runtime API, without creating rail signal entities.** It is not a drop-in `ElectricPolePrototype` property that enforces building exclusively near particular rail prototypes, nor will it automatically provide native signal UI. The recommended next step is a small **read-only slot visualizer**, then separately select a safe placement method and run in-game Undo tests. This record changes **documentation only**. No new mod behavior, prototype or release has been implemented.
