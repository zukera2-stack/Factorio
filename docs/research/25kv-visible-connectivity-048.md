# 0.1.48 — visible continuity from verified technical connectivity

## 1. Metadata
Start 155ba91e6081df3f5a317116ada862606012425b, experimental branch experiment/25kv-visible-connectivity-048; target Factorio 2.1.24 build 87808; Bob's mods, Space Age. Main remains 0.1.42. User accepted 047 visual test as successful, requested only matching visible spans to electrical continuity. No change to 047 nearest-neighbour planner, 045 geometry, graphics, prototypes, Undo or actual energy transfer.

## 2. Observed behavior
User log factorio-current(7).log: lines 59, 631–633 confirm 047 load/migration; 634–665 eight mast placements; 695–719 two normal poles, three HSR deletions, native Undo and robot revival; 740–744 mast ghost and robot build; 754–757 off-rail mast; 763–774 further four rail deletions/restorations; 783–786 clean exit. User reports successful visual test but a visually intact line after HSR gap is misleading. Log has no EM047 network IDs/pair inspection, so no live electrical isolation proof. 046 log established native script-origin links. In 047, art.sync blindly renders every cosmetic candidate independently of actual technical wiring.

## 3. Acceptance
A. Two actual masts, valid HSR, script-connected: visible span. Remove intermediate HSR: on rail queue processing native prohibited connection is removed, cosmetic candidate may persist but artwork removed. Restore real HSR: artwork returns after confirmed native connection. Ghost rails do not count.
B. A–B–C with verified script A–B–C, no direct A–C: same component allows cosmetic A–C if candidate and bounded HSR path valid. Remove B or fail native connect: no false A–C span. Unauthorized factory connection or merely planned link must not qualify. Equal network IDs alone insufficient. Bounded local HSR path also required so distant loop cannot falsely bridge nearby separate tracks. A genuine bounded alternate HSR path may still qualify, as the electrical network remains connected.
C. Ghost: one hypothetical mast, dry-run same 047 technical planner using real HSR, same visual planner, no entity creation or game state mutation. No preview across disconnected HSR; predicted links cannot guarantee engine success on revival. On actual build apply confirmed-link gate. Verify ghost cancellation, native Undo, robots, save/reload.
D. No energization condition: connected unpowered lines remain visible. No MW/traction, no new UI indicator today. Technical-only links may still exist with no visible candidate (32 vs 40 and degrees), intentionally unchanged.

## 4. Analogue and source
Existing 026/027 native probe and 046 game script links; source scripts/technical_network_046.lua at 155ba91e6081df3f5a317116ada862606012425b uses LuaWireConnector.is_connected_to(cb,defines.wire_origin.script), verified in 046 diagnostics. 047 power_019.technical_path uses existing LuaEntity.get_connected_rail, same force/surface, HSR names, bounded 64 approximate cells/192 visits. Reuse only these established API calls; no new prototype or engine event/API. LuaWireConnector docs https://lua-api.factorio.com/2.1.24/classes/LuaWireConnector.html (existing audit in 046). Native Factorio visible copper represents actual links, not energy; retain established script-only invisible topology and 047 visual candidates. No claim of exact Base algorithm.

## 5. Minimal design
Compute stable connected component labels (minimum mast unit number) over *confirmed own allowed script links* after technical sync and 60-tick audit, not planned edges or equal network IDs. Only consider valid registered anchors, matching surface/force, and actual connector is_connected_to(script). Cosmetic render gate requires same confirmed component AND existing bounded HSR path between candidate endpoints. Preserve all candidate selection and geometry. Reorder initialization technical before rendering; mark art/ghost dirty after component changes as well as existing rail/mast edits. Diagnostic distinguishes no HSR path, technical split, drawn, no candidate. Ghost predicts components using same planned technical graph on copied live nodes plus hypothetical node; requires bounded HSR path; no writes or helpers. It is a forecast, not proof. Avoid refactor of electrical planner or renderer geometry.

## 6. Falsification
Reject if cosmetic bridge persists over disconnected HSR and separate verified components, or valid indirect connection loses its span merely because no direct technical edge exists. Reject if preview creates real entities, graph changes, ordinary wires join, old art changes, or native Undo breaks. Offline tests are not Factorio QA.

## 7–9. Implementation / evidence
Implemented in code commit `9afb6beef2c8542d86d4cd8ce6673ed95fe3bf0b`: verified script-edge component labels, render gate (component + bounded HSR), ghost dry-run planned components, technical-before-art initialization, component change dirty propagation, diagnostic status, regression tests.


## 8. Automated evidence (not live Factorio)
- Build run [44411407669](https://github.com/zukera2-stack/Factorio/actions/runs/44411407669) SUCCESS; docs run 44411407655 SUCCESS. Job 135180206691 logs confirm 16 endpoint combinations; confirmed indirect components; missing/refused native script connection hides span; equal mocked network IDs insufficient; rail break/restore; off-rail anchor removal; ghost preview and removal; unchanged 16 PNGs. Historical regressions passed.
- [Artifact 14475494795](https://github.com/zukera2-stack/Factorio/actions/runs/44411407669/artifacts/14475494795) downloaded. Inner ElectrifiedMainline_0.1.48.zip CRC verified, info.json version 0.1.48, 71 entries, 16 PNGs, 322746 bytes, SHA256 `0b157f746cc2d3b258cae9594c117c3929637e22fe414da30bfc068009d6493a`.

## 9. Outstanding QA
No live 048 run available. Verify visual disappearance after HSR break and restoration after actual rail revival, no false missing spans on the accepted 047 layout, script-wire component and actual network IDs, ordinary grid isolation, ghost cleanup, Undo/Redo, save/reload, performance at scale. A valid bounded alternate HSR route can retain continuity. Technical-only links can remain invisible under independent 047 visual limits. Preview is a forecast, not native success proof; 60-tick audit detects unsignalled wire changes, rail edits refresh through existing queue. No voltage/traction/power delivery. Draft PR #26 not approved to merge.
