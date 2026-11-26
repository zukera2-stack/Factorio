# EM087F — локальный пересчёт потенциальных компонент, 2026-11-26

**PARTIAL / EXPERIMENT. Not accepted; no primary install.** Base 0.1.91 SHA256 `4c5ac930dac3303b160f0f4344a56335eb86bb9bd3575275a643cc2bb0a858c5`, GitHub `c39ccbffc6abd265c6f0426807c0f30d95ec0f1e`. Candidate 0.1.92 SHA256 `0ef5c4890704808d5efdf21a2c654eb8ae58fcbd34f8320cc7bab87dea37624b`. Last owner-running 0.1.84; latest local maintenance candidate 0.1.86. Four gameplay files changed, 157 files total, 99 unchanged PNG; no motor lifecycle, prototypes, traction payment, bridge changes. User authorized next experiment, not installation or merge.

## Implementation / boundaries

- Split all geometric candidate mast pairs (same surface/force, nonzero distance <= 40) into potential connected components before selecting wires. Partition by **all candidate pairs**, not actual selected copper links: degree <=5 and redundant-triangle rule can interact inside a component. Keep original global sort and exact original bounded physical path check for rebuilt groups; processing independent groups cannot influence those selection decisions.
- Carry processed rail change positions from `power019.on_tick` to `technical046.mark_dirty`. Rebuild groups whose mast records changed, whose previous dependencies are invalid, moved, changed force/surface, or whose mast is within conservative radius 73 tiles of an edit (64 path bound + 3 attachment + 6 coalesced cell allowance). Reuse unchanged group's selected edges and live LuaEntity dependency references. Generic dirty events (mast build/remove, audit failure), initial setup/configuration change, and independent 600-tick replan use full search. Existing 60-tick copper audit and per-phase fresh power checks unchanged. Share freshly resolved attachment refs with plan start lookup, reuse unchanged registration records. Native watchers still register actual dependencies; no global rail scan.
- This is a partial **component-local** planner, NOT arbitrary edge-local incremental graph. Candidate partition construction, anchor lookup and real wire audit still run globally. Parallel independent rail lines 40 tiles apart can be in the same potential component; a single continuous corridor may require full group replan. No guarantee on arbitrary script-side edits: unreported creation in other groups still waits for full audit, unreported direction/geometry changes without destroying/moving a dependency are not fully covered; the old full replan on an unrelated notified edit could have caught those earlier. No frequency reduction or claim of universal immediate correctness. Explicitly measure after adding further invalidation coverage; do not install as stable.

## Native tests: Factorio Linux headless 2.1.24 build 87808

- 53 inherited scenarios passed (48 explicit completion + 5 assertion stands); 100 moving trains, 800 wagons, 401 traction, 100 churn, 256 helper prototypes, 48 substations, GUI/blueprint restrictions, migration 0.1.85 included. Exact 0.1.92.
- Prior 0.1.91 watch scenarios native and powered, actual previous 0.1.91 disk checkpoint migrated and tested: 3 additional explicit PASS. Silent cut t200, split by t203, residual 333333.33333334 J, no later delivery t220..260, power restored. Earlier checkpoint used, not a fresh same-version disk roundtrip; native scenario reload_script t190 passed.
- New `em-watch-qa/localplan` exact candidate explicit PASS at tick602. Four real independent 3-mast corridors on same surface, one silent cut and raised repair: 1 rebuilt + 3 retained, 3/12 candidates each; simultaneous two silent cuts: 2 rebuilt + 2 retained, 6/12. Unaffected native network IDs checked, silent repair recovered by t601 full replan. Total exact candidate 57 successful scenarios (52 explicit completion + five stands).
- Extra instrumented stress: 50 independent three-mast corridors on same surface, 150 candidate pairs, 2200 real rails. Six silent cuts and six raised repairs in group 25, every cut/repair verifies all 49 unaffected native net IDs and correct split/rejoin. 2 fresh fixture runs per variant, all 4 PASS; 24 profiled sync calls per version. Test-only `helpers.create_profiler()` at M.sync; never used for gameplay decisions, no profiling code in actual patch. Candidate log 1 rebuilt/49 retained, 3/150 candidates in all 24 sync samples. Mean 42.572009625 -> 23.32333975 ms (-45.21%); max 81.447914 -> 50.504611 ms; median 40.284856 -> 18.793551 ms. Time of function sync, not full tick or active-traction UPS. No assertion that all factories scale similarly.
- Complete invisibility in native Windows train/station GUI still mandatory; not confirmed. Complex junctions, 100km, multiplayer, external mod compatibility, long duration and silent non-destruction edits not comprehensively tested. No new owner acceptance.

## Whole-tick stationary benchmarks

Same synthetic saves as EM087E, code-only candidate keeps info.json version 0.1.91; two sequential runs per variant. 480 ticks for 50/100, 1200 for long201. Native checksums may differ because persistent partition metadata and execution differ; compare measured energy logs, never claim bit-identical world. These are stationary fixture measurements and do not measure whole-tick cost under frequent events or 100 moving trains. Both variants load same older input saves, version-change initialization applies equally. Complete logs included.

| Stand | Base mean ms | Code-only mean ms | Change | Worst base/new ms | Checksum base/new |
|---|---:|---:|---:|---:|---|
| 50x2 | 19.056 | 18.586 | -2.46% | 442.623/426.540 | 2796242764/2796242764 |
| 100x2 | 43.025 | 42.090 | -2.17% | 1052.378/871.281 | 1944741676/1944741676 |
| long201 | 3.032 | 3.013 | -0.61% | 72.974/106.277 | 1596443813/1596443813 |

Paired recorded logs (prefix removed):

- 50x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 300/300, equal, [EM069 BUFFER STOP]: 0/0, equal
- 100x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 600/600, equal, [EM069 BUFFER STOP]: 0/0, equal
- long201: [EM072 PAID LEDGER]: 40/40, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 40/40, equal, [EM065 CONTACT]: 40/40, equal, [EM060]: 2400/2400, equal, [EM069 BUFFER STOP]: 1198/1198, equal

Gate NOT MET; no primary install. Next EM087G: path-level invalidation within large potential components, preserve global deterministic greedy selection; prove invalidation of both selected and previously rejected candidates; profile full periodic replan and reduce duplicate audit native reads only with evidence. Do not reduce independent checks before coverage for silent non-destruction changes is established. Maintain 20MW station, helper ownership, source-paid traction and complete hidden-helper GUI requirement.

## Direct Patch

Four replacements, zero deletions, approved build/verify PASS. ZIP SHA256 `31dc2b8412438a4b2b17c405343c637cbbb709aea2d9a5f3cea6bee73f1a81c6`; target tree `8eaecb50178fcd0c976e0c02806c7ba63156a64433627931cbfe570ab28ce3e6`. Only exact 0.1.91 isolated install. No main merge/release.

## Regression results

| Case | Status | seconds |
|---|---|---:|
| `alerts-nopath1` | PASS | 3.406 |
| `alerts-nopath201` | PASS | 4.516 |
| `alerts-nopath800` | PASS | 7.008 |
| `alerts-nopathdual201` | PASS | 4.157 |
| `alerts-nopathzero201` | PASS | 3.909 |
| `attach-bidir` | PASS | 5.249 |
| `attach-dual` | PASS | 3.763 |
| `attach-grow-retry` | PASS | 4.217 |
| `attach-same` | PASS | 3.354 |
| `attach-shrink-retry` | PASS | 4.363 |
| `audit-block` | PASS | 4.212 |
| `audit-churn` | PASS | 6.326 |
| `audit-churn100` | PASS | 18.217 |
| `audit-fair` | PASS | 4.477 |
| `audit-gui` | PASS | 4.014 |
| `audit-move` | PASS | 4.273 |
| `audit-offgrid` | PASS | 4.247 |
| `audit-ownerloss` | PASS | 3.283 |
| `audit-retain` | PASS | 3.137 |
| `audit-visibility` | PASS | 3.294 |
| `bench-100x2` | PASS | 13.190 |
| `bench-10x2` | PASS | 3.785 |
| `bench-1x2` | PASS | 3.641 |
| `bench-1x800` | PASS | 7.887 |
| `bench-50x2` | PASS | 6.841 |
| `extended-0` | PASS | 3.441 |
| `extended-1` | PASS | 3.594 |
| `extended-199` | PASS | 3.632 |
| `extended-200` | PASS | 4.252 |
| `extended-201` | PASS | 4.239 |
| `extended-400` | PASS | 4.493 |
| `extended-401` | PASS | 5.779 |
| `extended-600` | PASS | 6.243 |
| `extended-800` | PASS | 6.697 |
| `extended-dual201` | PASS | 4.515 |
| `extended-mixed` | PASS | 3.656 |
| `extended-ownerlossdual` | PASS | 3.647 |
| `extended-passive` | PASS | 3.234 |
| `extended-power401` | PASS | 7.742 |
| `extended-prototypes-retry` | PASS | 3.310 |
| `extended-split` | PASS | 3.653 |
| `extended-standalone` | PASS | 3.462 |
| `extended-vanilla` | PASS | 3.548 |
| `extended-zero201` | PASS | 3.819 |
| `migration085` | PASS | 2.032 |
| `moving-1` | PASS | 3.612 |
| `moving-10` | PASS | 5.616 |
| `moving-100` | PASS | 41.011 |
| `moving-50` | PASS | 21.547 |
| `native-corridor` | PASS | 3.758 |
| `native-segments` | PASS | 3.324 |
| `network-multi48` | PASS | 7.083 |
| `network-topology` | PASS | 4.364 |