# Factorio 2.1.20: why a real electric pole cannot inherit native rail-signal snap

Date: 2026-11-14. Branch: research/native-signal-mast-probe-019, parent 0.1.18 evidence at 8883b8990663349bbd0cae60b7e00d08e3460c25. Exact mod name ElectrifiedMainline 0.1.19.

## Desired contract
One LMB, green grid identical to vanilla rail signal, actual electric-pole entity, can build only beside custom ВСМ rails (never on vanilla rails and never away from rail), native Undo, native blueprint/ghosts/robots, absolutely no rail-signal proxies, no script destroy/recreate, no hidden terrain/permissions layer.

## Native type facts (sources and analogue)
- Vanilla `rail-signal` / `RailSignalPrototype` has special hard-coded rail-side placement UI; it becomes a *rail signal* and affects railway blocks. [Prototype API](https://lua-api.factorio.com/2.1.20/prototypes/RailSignalPrototype.html).
- `electric-pole` has no equivalent rail signal snapping flag, no reference to custom track entity types. [ElectricPolePrototype](https://lua-api.factorio.com/2.1.20/prototypes/ElectricPolePrototype.html).
- `rail-support` owns `not_buildable_if_no_rails` and `snap_to_spots_distance`, but is a support for **elevated rails**, is a different entity type, and cannot also be electric-pole; it does not filter to custom ВСМ rails. [RailSupportPrototype](https://lua-api.factorio.com/2.1.20/prototypes/RailSupportPrototype.html).
- `tile_buildability_rules` apply to ground tile masks, not adjacency to a named rail entity. Adding invisible/tiled permission infrastructure would modify terrain and is outside the native-entity design contract. [TileBuildabilityRule](https://lua-api.factorio.com/2.1.20/types/TileBuildabilityRule.html).
- `CustomInputPrototype` is a global binding, not conditional on cursor entity type; and `on_pre_build` is an event, not a cancellable native-placement veto. Existing 0.1.18 optional Alt+LMB demonstrates `player.build_from_cursor` and is native Undo-compatible on the user's exact Factorio 2.1.20 game test, but normal unmodified LMB still permits a pole outside ВСМ. [Custom input API](https://lua-api.factorio.com/2.1.20/prototypes/CustomInputPrototype.html), [LuaPlayer](https://lua-api.factorio.com/2.1.20/classes/LuaPlayer.html).
- Same-type third-party precedent AudricSan/Factorio-Mods ElectrifiedRailways source @ 3c9b713244c5721e7cb582ce5ee46381659323fb uses rail-signal proxy then destroy/replace with pole. NOT adopted: signal block, inventory and Undo risks. No borrowed code/assets.

## Hypothesis / smallest falsifiable experiment

Clone a true vanilla rail-signal as a **visibly and explicitly named 0.1.19 diagnostic entity and item**, without changing any real poles, custom HSR rails, train-control code, native Upgrade Planner, or existing Ctrl+Z logic. This item must show exact native green signal snap squares with normal LMB. Its placement on a ground rail must make a real **rail-signal**, not a pole, and may work on both vanilla and custom rails: this is a **counterexample test** to the notion of a built-in electric-pole HSR-only property.

**Test cases:**
1. Disposable save, empty test HSR track. Craft `em-35kv-native-placement-probe` for 1 iron plate, hold it, inspect native green squares; ordinary LMB builds a *rail-signal* and native Ctrl+Z/Ctrl+Y should work, check exact logs.
2. Repeat on vanilla straight rail. Observe whether native snap also offers positions; if yes, there is no prototype HSR-only filter.
3. Move away from tracks. Native rail signal should refuse to place; verify.
4. Compare an actual `em-35kv-catenary-pole` item: it remains a **real electric-pole** with 0.1.18 optional Alt+LMB overlay, **still placeable outside ВСМ with normal LMB**; 0.1.19 does not claim to solve this requirement.
5. Avoid moving trains and operational signals: the probe is a real signal and will change block segmentation if placed.
6. Verify HSR rail native Upgrade Planner and Undo unaffected by this isolated new item when the probe is not placed.

## Decision, no hacks

There is no supported same-entity native primitive satisfying **ALL** requirements. Thus do not ship a fake "native rail-only electric pole" feature or silently remove off-track poles after native construction. No unverified destructive interceptor or terrain rewriter. This 0.1.19 ZIP is a **proof ZIP only**, not the requested production placement system; the latter remains BLOCKED by engine API if strict no-proxy/no-hack requirement is maintained.

## Evidence labels
- Factorio 0.1.18 user log **game-tested**: multiple Alt+LMB builds and correct Undo/Redo for those positions; 2x on_pre_build each Alt click, 1x on_built_entity (not double entity).
- 0.1.19 native snap **implemented for experimental signal type**, engine gameplay currently **unverified**.
- Actual 35kV HSR-only native LMB **not implemented**, **blocked** by engine-type restrictions; unchanged.

## License
Official Factorio vanilla prototype deep-copy; no third-party code or graphics.
