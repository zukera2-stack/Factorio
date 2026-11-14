# 0.1.18 — cursor-visible native-slot guidance and true electric-pole building

## 1. Research metadata
- **Date:** 2026-11-14.
- **Branch:** feature/catenary-native-player-build-018, based on 0.1.17 gameplay evidence at e1b7d7fee177580841ce87efa6853e73116008a5.
- **Target:** Factorio 2.1.20 build 87512, Space Age and Bob's modpack from 0.1.17 user's log.
- **Status:** experimental, awaiting code and exact Factorio gameplay verification.

## 2. Concrete behavior

User asks for the signal-style green positions to appear **when the real 35 kV mast is in cursor**, with the ability to actually build that **same electric-pole** at an allowed HSR-adjacent position. No 16-tile spacing restriction, rail-signal proxy, destroy/recreate, script-managed inventory, or undo-index injection. Existing native LMB building, green Upgrade Planner, rail Undo/Redo must remain unchanged.

## 3. Acceptance tests
1. Load expendable HSR save, equip real `em-35kv-catenary-pole` item. Track-side colored small squares should automatically appear around the player while the mast is held; they should disappear after it is no longer held.
2. Compare square positions to native rail signal markers on straight NS/EW, curve A and B, half diagonal, dual-track junctions, and parallel track. No spacing algorithm may omit a safe slot.
3. Hover within about 1.25 tiles of any square and use **Alt + Left Click**: it should build the actual `em-35kv-catenary-pole` through `LuaPlayer.build_from_cursor`, using `LuaPlayer.can_build_from_cursor` preflight. No change to main build binding: plain Left Click still uses vanilla Factorio placement (including outside HSR if originally allowed).
4. Inspect entity type, actual position after native tile-grid snapping, cursor item count, collision rules, ghost/robot cases, Ctrl+Z/Ctrl+Y with separate negative cases (no HSR, blocked, too far, no item). Log the exact `on_pre_build`, `on_built_entity`, `on_undo_applied` records. **Undo ownership by scripted `build_from_cursor` remains unverified until observed in-game.**
5. Ensure HSR-native upgrade/Undo workflows unaffected; standard rail signals and trains unchanged. Observe both active trains and bidirectional signals if available.

## 4. Native mechanics / precedent

- **RailSignalPrototype** (Factorio 2.1.20) special entity category; internal cursor green squares are hard-coded for rail signals. An electric-pole item does not automatically receive this UI. Source: https://lua-api.factorio.com/2.1.20/prototypes/RailSignalPrototype.html.
- **ElectricPolePrototype**: place_result remains an actual electric-pole with no native rail-signal placement flags; https://lua-api.factorio.com/2.1.20/prototypes/ElectricPolePrototype.html.
- **LuaRailEnd**, `LuaEntity.get_rail_end`: exact native in/out/alternative signal locations from custom HSR rails, verified in 0.1.17 nine user game command runs (0 API errors), see docs/tests/catenary-corridor-0.1.17-2026-11-14.md.
- **LuaPlayer.can_build_from_cursor** and **LuaPlayer.build_from_cursor** (2.1.x API) are engine-owned cursor builds, item stack is reduced automatically, real `on_pre_build` / `on_built_entity` events are raised; https://lua-api.factorio.com/2.1.20/classes/LuaPlayer.html.
- **CustomInputPrototype**: `key_sequence="ALT + mouse-button-1"` with `consuming="game-only"` prevents simultaneous vanilla action on that **alternative** key, but has global Alt-LMB binding scope; normal Left Click unchanged. https://lua-api.factorio.com/2.1.20/prototypes/CustomInputPrototype.html. Event provides `cursor_position`; from Factorio Custom Input tutorial https://wiki.factorio.com/Tutorial:Script_interfaces.
- **Other mods**: AudricSan/Factorio-Mods ElectrifiedRailways source @ 3c9b713244c5721e7cb582ce5ee46381659323fb achieves literal signal snap by creating/destroying a rail-signal placement proxy. That approach is refused: creates transient signalling entity, risky for native train blocks and native Undo. Port Realistic_Electric_Trains_Continued_2SE mod portal version 0.6.1 (source revision not available) notes legacy hidden one-way signals on ordinary poles had to be removed due to broken bidirectional pathing. Source: https://mods.factorio.com/mod/Realistic_Electric_Trains_Continued_2SE.
- **Our current source**: `prototypes/power_019.lua` item `place_result` points directly at real `electric-pole`; `scripts/rail_slot_debug_014.lua` returns native slots; 0.1.17 `scripts/catenary_corridor_017.lua` demonstrates rendering, 9 user game sessions. `scripts/power_019.lua` draws G-arm after a genuine pole build. No other mod's source or assets copied.

## 5. Prototype comparison
| Aspect | Vanilla rail signal | Our mast 0.1.17 | Proposed 0.1.18 |
|---|---|---|---|
| Entity type | rail-signal, participates in blocks | electric-pole, isolated wires | same real electric-pole |
| Item placement | native signal rail-slot snapping | native ordinary pole grid | native grid at engine signal-reference positions, explicit alternative action |
| Cursor hints | built-in native green squares | none | LuaRendering small squares while item held, **not claimed native UI** |
| Build + inventory | engine | vanilla Left Click | `player.build_from_cursor` with preflight, not `surface.create_entity` |
| Undo | engine | native normal LMB | must verify actual `build_from_cursor` undo independently; no manual Undo injection |
| Blocks/signals | affects blocks | no signal | no signal entity is ever created |
| Rail restriction | signal only near rail | none | Alt-LMB only near slots of four custom HSR rails; ordinary Left Click remains free |

## 6. Hypothesis, minimal design, falsification

Use exactly engine `LuaRailEnd` signal positions, normalize to the real pole's 1x1 native tile center (not pretend a pole can occupy rail-signal half-grid), deduplicate, present all available local markers while holding the actual item, and Alt-LMB build the item through `LuaPlayer.build_from_cursor`. No invented arc geometry or 16-tile spacing. Render colors based on **`player.can_build_from_cursor`**, with surface collision-only results as distinction for blocked vs out-of-reach.

The overlay is not the hard-coded rail-signal graphics, and does **not** alter vanilla Left Click. The mechanic will be rejected if Alt-LMB builds a signal, duplicates an entity, consumes two items, violates normal collision rules, does not maintain correct arm visuals, or unexpectedly corrupts independent Undo. If native scripted build cannot preserve Undo, we will not ship it as verified; normal vanilla LMB at a marked location remains the safe fallback.

Rollback: switch to 0.1.17 build/branch; stable main 0.1.8 untouched.

## 7–9. To complete after code/static CI/user game test

Record changed files, actual API loading, exact screenshots/log, cursor consumption, real position, Undo/Redo result, and negative tests separately. Lua syntax and ZIP packaging are not Factorio gameplay evidence.

## 10. Licensing
No third-party code or art copied. Only official semantics and observed behavior are used.


## 7. Implementation and static test record, 2026-11-14

- Source commit: 78a010cb44995ba71bcfe8e5337a7f63070eff8f on feature/catenary-native-player-build-018.
- Changed: new scripts/catenary_cursor_018.lua, prototypes/catenary_cursor_input_018.lua, data.lua and scripts/control.lua loading/input registration, locale ru/en, info.json v0.1.18, tests/35kv_cursor_build_018.lua, .github/workflows/build-mod.yml, in-game test plan, synchronized state/status/changelog.
- Official native player API: real electric-pole item and place_result remain unchanged; nearest native HSR `LuaRailEnd` reference adapted to 1x1 electric-pole grid, native `can_build_from_cursor` preflight, then `build_from_cursor`. No pseudo signal, no `surface.create_entity`, entity destruction, scripted refunds, Undo injection or 16-tile restriction. Alt+LMB custom binding has global input scope; plain LMB untouched.
- **STATIC CI PASS:** [Build #43601951663](https://github.com/zukera2-stack/Factorio/actions/runs/43601951663) from source commit 78a010cb44995ba71bcfe8e5337a7f63070eff8f; [download ZIP artifact #14115959103](https://github.com/zukera2-stack/Factorio/actions/runs/43601951663/artifacts/14115959103). Lua 5.2 syntax, all mock tests 0.1.13-0.1.18 including new cursor placement test, and versioned ZIP packaging passed. [Docs CI #43601951644](https://github.com/zukera2-stack/Factorio/actions/runs/43601951644) PASS. Game load/real item Ctrl+Z/Ctrl+Y remain unverified.
- **NOT GAME TESTED:** data-stage/game load, input conflict with other controls/mods, actual placement position/inventory, native Undo/Redo for `build_from_cursor`, rail geometry alignment. Mock test cannot prove any of these.


## 8–9. Partial Factorio 2.1.20 user game result (2026-11-14)

[Complete log and screenshot evaluation](../tests/catenary-native-player-build-0.1.18-2026-11-14.md): holding the real pole renders green/red track-side squares; one Alt+LMB at tick 49936 invokes engine construction of a real electric-pole at (30.5,-17.5). No Lua errors, normal pole Undo and normal ghost/robot Undo/Redo observed. However, no Undo/Redo target matching **(30.5,-17.5)**; Alt-specific native Undo remains unverified. Tick 49936 contains two pre-build events but one built-entity; double inventory consumption not proven and needs a controlled count. Gameplay status: IMPLEMENTED + PARTIALLY GAME-TESTED; final native-Undo-safe mast snapping NOT YET VERIFIED. No source fix until narrower evidence.
