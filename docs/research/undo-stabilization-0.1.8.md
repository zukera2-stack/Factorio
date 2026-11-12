# Undo stabilization 0.1.8

## Research before implementation
Date: 2026-11-12. Base: fb3e5ca6307cf09585d67cd83566fa16e07839a8, diagnostic/blueprint-rail-undo. Target: Factorio 2.1.20 build 87512. Test branch: test/undo-stabilization-018.

Native analogue: our 0.1.7 log factorio-current_20261112-144236: 20 straight rail upgrades, Undo and Redo; no undo-join messages. Same-type reference inspected during preceding audit: snouz/minimalist-rails, prototypes/entities.lua, commit 20abed0e195cc8786a8b8a53118b8cddebd8232d, mod 2.0.9. Base reference: wube/factorio-data tag 2.1.20 commit 40ec3dbe6f88a96899bbd2fefbd6800cac6c1e71. No third-party code copied; licensing not needed for removal of our experiment.

API: https://lua-api.factorio.com/latest/classes/LuaSurface.html (create_entity.undo_index), https://lua-api.factorio.com/latest/classes/LuaUndoRedoStack.html, https://lua-api.factorio.com/latest/prototypes/UpgradeItemPrototype.html. Inspected latest docs report 2.1.24, not exact installed 2.1.20. Index 1 denotes most recent operation, not immutable identity. Native upgrade ownership was verified in 2.1.20 by the earlier log.

Comparison: leave all prototype flags, geometry, collision, item mapping, groups and next_upgrade unchanged. Remove only blueprint join producers, consumer and transient storage. The selection tool owns pending_rail_replacements, independent of blueprint_undo_join. Its chain is selection -> order_deconstruction -> mined handler -> next-tick ghost creation; cancellation clears its own queue. Native handler only logs. Undo/Redo handlers only log.

Hypothesis: removing manual ghost joining eliminates accidental attachment to an unrelated action without changing native upgrades or selection-tool scheduling. Falsification: any lost selection queue or changed native upgrade behavior. Existing saved join marks are discarded, never replayed; existing selection tasks retained. Experiment remains in git history only. Rollback by selecting prior version on a backup save.

Acceptance: tests A-D in ElectrifiedMainline/TEST_UNDO_018.txt. B must respect LIFO: first Undo cancels the newer unrelated action, second cancels blueprint; Redo reverses that order. Do not expect Undo to skip the newest action.

## Results
Implementation removes join path. Static dependency and unchanged-prototype checks required before commit. All 0.1.8 game tests unverified; no new Factorio run. Historical 0.1.6/0.1.7 results remain historical. Known issues: selection-tool retry cleanup, diagnostics cost, item entity-data types, compatibility and energy placeholders remain out of scope. Build provenance recorded in docs/BUILD_018.yaml after source commit and packaging.
