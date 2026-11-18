# 0.1.47 — relaxed cosmetic spans / HSR-gated electrical connections

## 1. Metadata
2026-11-19 user log (system date 2026-11-18), starting 046 docs commit e66e0273f01bf91f1186047618d4f4b168bebe59, branch experiment/25kv-relaxed-visual-hsr-gate-047. Factorio 2.1.24 (build 87808), Bob's mods and Space Age present. Main 042 untouched. Experimental.

## 2. Exact behavior and evidence
User requests simpler cosmetic wire conditions and stricter hidden electrical conditions. factorio-current(6).log, lines 59, 631–633, 728–755, 861–916, 925–938: 046 loaded and migrated; explicit script-connected for mast 2539/2516 (5.099 cells, HSR path 8.385, opposite sides), 2717/2778 (4 cells, same rail 1019, opposite sides), even though art says no-contact-edge. 26 pair checks including duplicates: 12 distance/path limits, 8 opposite-side, 2 degree/order, 4 drawn (15 script-connected reports). Ghost placed three times, removed twice, saves and user quit. No reported runtime error. Real script-origin connectivity is confirmed for reported pairs; network ID separation from factory remains unmeasured. Existing 046 visual graph (power_019) rejects curves over 16, opposite side, tangent and corridor; 046 technical planner ignores rail entirely.

## 3. Acceptance before edits
A. Reproduce pair 2539/2516 and 2717/2778 in copy of save; no visual gate based on side, tangent, curve or path length; visually connect as nearest candidates if degree available, and technical connect if HSR continuous.
B. Two near-rail masts on opposite isolated HSR segments: cosmetic possible, technical disallowed. Remove/rebuild middle custom rail: next graph refresh technical link breaks/restores; no vanilla rail bridge. Off-rail mast: no technical anchor, no cosmetic span. Technical cap 40 and five neighbours, visual 32 and two neighbours. Test distances 32/33, 40/41, same rail, parallel, curves, ghost, undo/redo, robot, save/reload.
C. Check /em-25kv-status and /em-25kv-pairs: actual script-connected and network IDs on technical helper, compare ordinary poles. No MW.

## 4. Analogue search / source
Our verified native probe 026/027, 028 and actual 046 gameplay log; same-type native inherited electric-pole connectors. Previous research 046 contains exact source/API provenance. Existing power_019 rail walk uses get_connected_rail with custom HSR whitelist, force/surface check and bounded distance, verified in 028 mock and 045/046 game diagnostics; reuse same API and extend bounded walk for 40-cell technical radius. No new engine APIs or prototypes, no need to invent new events. Factorio native Base automatic scheduling remains proprietary. Existing 046 ghost dry-run and 045 pixel anchors used unchanged. Source: scripts/power_019.lua and scripts/technical_network_046.lua at e66e0273f01bf91f1186047618d4f4b168bebe59. API references: https://lua-api.factorio.com/2.1.24/classes/LuaEntity.html and https://lua-api.factorio.com/2.1.24/classes/LuaWireConnector.html (prior version audit; no new API calls).

## 5. Decision
Visual: one deterministic planner on near-rail real mast nodes (plus one hypothetical ghost), distance <=32, nearest-first, <=2 neighbours, no tangent/side/curved/connected-path gate. To avoid obvious shortcut/parallel artifacts, prefer pairs whose projected rail attachment points are nearest; suppress candidate if it skips an intermediate eligible mast (relative-neighbourhood criterion on actual projected track points, with mast distance for ties); do not require continuity. Degenerate projection and competing close parallel tracks remain possible; player placement is the intended control. No electrical effect. Render straight/curved with same chord geometry and 32 limit (+4 endpoint registration allowance). Recompute deterministic visual plan consistently, preserve feeder (logical only).
Technical: same 046 zero-reach script origin, own helper, 40 cells and degree <=5. Both nodes must be near custom HSR with registered rail ID and connected HSR path, bounded walk up to 64 approximate center-distance tiles and 192 rail visits; same rail accepted. No side/tangent/curve-specific limits. No vanilla rails; force and surface matched. Bounded search may reject long detours by design. Remove anchors for off-rail masts; replan after rail edits on next tick, not only after mast edits. Keep audit. No power transfer.
 
## 6. Falsifiable hypothesis / stop
The actual rejected pairs become visually eligible and electrically connected if selected, and broken HSR invalidates technical links without suppressing cosmetic candidates near remaining rails. If script link disappears incorrectly or ordinary network IDs merge, stop before main merge. Keep 046 as rollback. No asset/prototype/Undo changes.
 
## 7–9. Implementation / validation
Implemented in code commit `8e760a4c6c2d40d7150407f9d05e4795b1badd18`: catenary_visual_policy_047 shared by built masts and placed single ghosts, independent HSR-gated technical script links, rail edit refresh, uniform visual reach, diagnostics and version-specific tests.


## 8. Automated evidence
- Build run [44408148534](https://github.com/zukera2-stack/Factorio/actions/runs/44408148534) and documentation run 44408148473 SUCCESS. Logs confirm 16 geometry combinations, actual rail traversal mock, same-rail/opposite-side pairs, 40-cell technical limit, broken/vanilla rail rejection, separate cosmetic choice, off-rail anchor cleanup, mock connection removal/recreation, ghost dry-run and cancellation, historical regression tests, PNG hashes. These are offline Lua tests, not game QA.
- [Artifact 14476051835](https://github.com/zukera2-stack/Factorio/actions/runs/44408148534/artifacts/14476051835) downloaded; inner ZIP CRC check, info.json 0.1.47, 70 entries, 16 PNGs, 321030 bytes, SHA256 `6b675712330cb092cd5128e20c680dcf9d349a6fbf8208d8f5f915c56338bbed`.

## 9. Outstanding QA
No run of Factorio 047 available. Compare visible spans and ghost at sharp turns, technical network IDs and factory isolation, real HSR break/rebuild, Undo/Redo and robot lifecycle. Projected-point nearest-neighbour heuristic can still draw links between very close parallel lines or omit spans in crowded arrangements; deliberately not a full automatic railway designer. Technical bounded walk: 64 approximate route tiles, 192 visits; may reject long detours. No energy transfer. Do not merge PR #25 without acceptance.
