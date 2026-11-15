# 0.1.17 research — why native signal placement indicators cannot simply be inherited by electric poles

**Date:** 2026-11-14. **Scope:** read-only investigation / design decision; NO code change to version 0.1.16.  
**Branch:** `feature/catenary-snap-research-017` based on `feature/catenary-geometry-016` commit `76d2c9daaf3bc6474198a86e075a4e6412954d0f`.  
**Installed Factorio:** 2.1.20 build 87512, verified by user's 2026-11-14 log.  
**Screenshot references:** [0.1.16 scoped game result](../tests/catenary-geometry-0.1.16-2026-11-14.md).  
**Status:** mechanism **source-verified**; port to our mod **NOT implemented**; native Undo and train-block safety for any proxy unverified.

## 1. Observable behavior and acceptance criterion

The user supplied a screenshot while holding the native `rail-signal` item: many legal small green squares appear on **both sides along straight and curved rails**, not just near the two ends of a single rail. This behaviour is Factorio's native rail-signal placement preview. The user wants analogous **track-side pole placement**, *without* true signals, block changes, a disrupted native Upgrade Planner, or corrupted Undo/Redo. The user also requires the support to be placed only near custom ВСМ rails rather than on arbitrary vanilla tracks.

A successful future implementation would preview legal catenary mast bases on all four custom HSR geometries, let players choose the desired side, place exactly one real **electric-pole** with inventory correct, preserve robots/blueprints and make one native Ctrl+Z/Redo operation restore the actual pole, without creating persistent or momentary signal effects.

## 2. Working analogue discovered — source code, not speculation

**Mod:** [Electrified Railways by AudricSan](https://mods.factorio.com/mod/ElectrifiedRailways), advertised on the public mod portal as Factorio 2.1 with catenary gates that snap like train signals.

**Repository:** [AudricSan/Factorio-Mods](https://github.com/AudricSan/Factorio-Mods/tree/3c9b713244c5721e7cb582ce5ee46381659323fb/ElectrifiedRailways), inspected main HEAD `3c9b713244c5721e7cb582ce5ee46381659323fb`, **source `info.json` says 0.3.26** while Mod Portal displayed **0.3.25**. Do not claim the user's installation includes this mod or that public GitHub source and released portal ZIP are byte-identical. **License GPL-3.0:** use conceptual API behavior only; DO NOT copy source/assets into our repository without separate licensing agreement.

Relevant primary source:

- [`prototypes/catenary.lua`](https://github.com/AudricSan/Factorio-Mods/blob/3c9b713244c5721e7cb582ce5ee46381659323fb/ElectrifiedRailways/prototypes/catenary.lua): the **catenary item** has `place_result = "er-catenary-slot"`, and that slot is a `table.deepcopy(data.raw["rail-signal"]["rail-signal"])` using the **rail-signal entity type**. This is what makes the *Factorio engine* supply built-in signal snapping and green installation squares **before the click**.
- [`scripts/catenary.lua` lines ~673–711](https://github.com/AudricSan/Factorio-Mods/blob/3c9b713244c5721e7cb582ce5ee46381659323fb/ElectrifiedRailways/scripts/catenary.lua#L673-L711): on construction the code **destroys that signal-like slot** and creates a real pole, with extra side/collision validation and removal/recreation as needed.
- [`scripts/catenary.lua` lines ~84–175 and ~621–670](https://github.com/AudricSan/Factorio-Mods/blob/3c9b713244c5721e7cb582ce5ee46381659323fb/ElectrifiedRailways/scripts/catenary.lua#L621-L670): separate geometric checks based on rail-end points, nearby track tangent, snapping and refund logic.
- [Mod changelog, 0.3.17](https://mods.factorio.com/mod/ElectrifiedRailways/changelog): documents deliberate switch to an actual signal-placement proxy to inherit engine snap preview.

**Precisely verified mechanism:** a **temporary real `rail-signal` entity prototype**, not a generic `electric-pole` property or an API call enabling signal snapping on arbitrary entity types. Source inspection is not proof that the trick is harmless to rail blocks, or that its Ctrl+Z/Redo/robots work the way our project requires.

## 3. Official Factorio API / compared prototype types

| Mechanism | Verified API / source | What it means for ElectrifiedMainline |
| --- | --- | --- |
| Native green rail-signal placement squares | [RailSignalPrototype](https://lua-api.factorio.com/latest/prototypes/RailSignalPrototype.html), Factorio docs observed 2.1.24 | Inherent to `rail-signal` type, not a switch on `ElectricPolePrototype`. A cloned signal can affect train block semantics while it exists. |
| Per-rail legal signal coordinates | [LuaRailEnd](https://lua-api.factorio.com/latest/classes/LuaRailEnd.html) `in_signal_location`, `out_signal_location` and optional alternatives | These positions include engine-defined direction/layer. For continuous placement, enumerate many nearby connected HSR rails, not only one selected rail's two ends. This is read-only and **does not** make an electric pole snap natively. |
| Track center and tangent | [LuaRailEnd.location](https://lua-api.factorio.com/latest/classes/LuaRailEnd.html), [RailLocation](https://lua-api.factorio.com/latest/concepts/RailLocation.html) | Position/direction of rail **end**, as 0.1.16 uses; not equivalent to every legal signal position, and cannot alone place a mast in the middle of a long curve. |
| Native building action | [LuaPlayer.can_build_from_cursor / build_from_cursor](https://lua-api.factorio.com/latest/classes/LuaPlayer.html) | Engine exposes checking/building from real cursor at a **specified position** and raises build events, consuming cursor items normally; exact native Undo/Redo grouping must be **tested**, not assumed. |
| Cursor-specific visuals | [ScriptRenderTargetTable](https://lua-api.factorio.com/latest/concepts/ScriptRenderTargetTable.html) | `cursor` and `build-cursor` render targets exist, but there is no documented general property `snap_like_rail_signal=true` for electric poles. Cursor visuals are not automatically the chosen rail-side coordinate. |
| Control event | [on_pre_build](https://lua-api.factorio.com/latest/events.html) | Raised before a player builds, but no documented API for cancelling an arbitrary build by returning false; `on_built_entity` happens after native placement. |
| Existing mast prototype | `ElectrifiedMainline/prototypes/power_019.lua` at `76d2c9d` | Our mast is a true `electric-pole` with disabled copper/network properties, eight-facing script sprite. Converting it into a `rail-signal` is disallowed. |

Official web docs above may show **2.1.24**, later than the user's running **2.1.20**. Confirm any optional/new API fields in a 2.1.20 game test before relying on them.

**Unrelated alternative:** `RailSupportPrototype` has special snapping fields for rail support, but its target is elevated-rail support mechanics, not general ground catenary poles; it does not supply the wanted API inheritance.

## 4. Risk analysis of the tempting proxy workaround

**Hypothetical port: catenary item -> cloned `rail-signal` proxy -> destroy proxy in `on_built_entity` -> create `electric-pole`.**

- **Train behaviour:** the placed proxy is a real signal prototype. It may briefly affect a block or pathfinder, depending on timing, even if destroyed within the same event; neither source code nor screenshot proves zero train-block effects.
- **Undo/Redo:** vanilla player's build action belongs to the **proxy signal**; the visible pole is created by a separate script action. Undo/Redo can become dissociated. A good-looking first placement is NOT proof of working Undo.
- **Inventory / quality / ownership:** converting one entity type to another demands checks for ghosts, bots, blueprints, item consumption/refund, quality, force and surface, scenario scripts, robot jobs and accidental duplicates. A prototype-only swap does not solve these.
- **Collision / side-selection:** engine signal slots are valid for signals, not guaranteed safe/ideal footprints for a large Г-shaped pole. Further offsets or placement tests are still required.
- **Other mods / native rail upgrades:** we must avoid any effect on native Upgrade Planner or rail signal/chain signal operation. The stable tested 0.1.8 Undo baseline must remain intact.

**Source-backed caution:** [Realistic Electric Trains Continued 0.6.1](https://mods.factorio.com/mod/Realistic_Electric_Trains_Continued_2SE) release notes explicitly describe a previous problem where plain poles were internally **hidden one-way signals**, affecting pathing on bidirectional lines, and a redesign of the entity type. This supports avoiding permanent signal-as-pole prototypes; it does NOT independently prove that AudricSan's transient proxy causes such issues.

**Decision:** do **not** import, copy or directly enable the signal-proxy approach in our main or current experimental game build. Keep it as a separately falsifiable option only if a truly safe implementation cannot provide an acceptable interface.

## 5. Proposed 0.1.17 experiments, safest first

### Phase A — pure read-only continuous rail-slot visualizer

1. Enumerate all **connected/nearby custom HSR rails** in a bounded corridor; retrieve `LuaRailEnd`'s real signal coordinates for each end, include alternative positions and deduplicate by position/direction/layer. Do not fake positions from `rail.position` alone.
2. Render the same green candidate squares as a **read-only LuaRendering layer**, but distinguish *engine signal reference* vs *candidate pole base*; enforce a minimum spacing for the user's desired 35 kV masts.
3. Compute local track centerline/tangent for each snapped slot using rail geometry; compare candidate mast footprint and arm reach. Use the project's graphics and collision checks only, never create a signal.
4. On a closed test track validate straight/cardinal, half-diagonal, both curves, both sides, parallel tracks, crossings, and occupied locations. Capture screenshots and console coordinates.
5. Acceptance: markers follow the whole rail corridor with visual quality comparable to vanilla indicators while staying **read-only** and causing zero rail block/Undo effects.

### Phase B — native-player-build hypothesis (only after A passes)

Use an *explicit user action* at a chosen candidate and investigate `LuaPlayer.can_build_from_cursor` then `build_from_cursor{position=...}` for a **real pole item**, not a signal proxy. Tests must prove item decrement, one real pole, native Ctrl+Z restoration and Ctrl+Y replacement, robot/blueprint/ghost behavior, invalid placement and no unrelated Undo actions. If build_from_cursor does not satisfy native Undo, do not recreate/teleport/force-join a replacement; document API limitation and find another native workflow.

### Phase C — native visual snapping proxy (separate sandbox only, if approved by evidence)

If literal built-in rail-signal green-square cursor preview is mandatory, a real `rail-signal`-derived **placement proxy** is the found precedent. Test a **disposable save with no trains** first, then instrument train blocks, signal and train routing, Undo/Redo, item and ghost lifecycle; require *zero transient block effects* and correct Undo before introducing any version of this pathway. Any failure rejects the proxy approach. Never replace the mast prototype itself with a rail signal. No third-party GPL code is copied.

## 6. Research evidence labels and rollback

- **Game-tested:** 0.1.16 read-only diagnostics on straight/curve A/curve B in Factorio 2.1.20, exact [log/screenshot scope](../tests/catenary-geometry-0.1.16-2026-11-14.md).
- **Source-verified external analogue:** AudricSan's 0.3.26 GitHub main at commit `3c9b713`, **not** portal 0.3.25 and **not** verified in user's modpack.
- **API-supported:** read-only rail-end signal coordinates, rendering targets, real cursor build methods as exposed in public 2.1.x docs.
- **Unverified/hypothesis:** safe real-mast native placement, Undo/Redo success with `build_from_cursor`, any transient proxy without block mutation.
- **Rollback:** this is **documentation-only** on an isolated `feature/catenary-snap-research-017` branch. It does not bump `info.json` (still 0.1.16), does not produce a new game build and does not touch stable `main`.
