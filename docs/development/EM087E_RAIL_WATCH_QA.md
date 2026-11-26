# EM087E — native rail path destruction watcher, 2026-11-26

**PARTIAL / EXPERIMENT. Not accepted, not for primary install.** Exact base 0.1.90 EM087D commit `f1ca72caf6b2b36cd30cb2cf3e414da7412999bf`, full SHA256 `b2721282661a508ef6840da95c59b9589519a663278c097b6b36b8d59af3ca34`. Target 0.1.91 SHA256 `4c5ac930dac3303b160f0f4344a56335eb86bb9bd3575275a643cc2bb0a858c5`. Four changed game files: info.json, scripts/control.lua, scripts/power_019.lua, scripts/technical_network_046.lua. All 157 files, 99 identical PNG; motor lifecycle/prototypes, traction payment and bridge untouched. Owner accepted work on native rail dependencies, not main merge or installation.

## Implementation and limits

- During the existing complete technical plan, collect actual LuaEntity references for the selected physical path, from certified native straight segment or the bounded walk's exact predecessor chain; include mast attachment rails even for isolated masts. No global rail scan or cross-tick permission cache. Preview remains non-mutating.
- `script.register_on_object_destroyed` registers current watched rails; store registration number and position/surface/force metadata. Reuse existing registration for still-needed unit IDs, discard Lua metadata for paths no longer selected. The engine registration remains until object destruction; old live-rail registration overhead under repeated topology edits not quantified. Event callback ignores untracked IDs.
- For a tracked rail, enqueue the ordinary local mast refresh; that phase marks technical graph dirty and completes full native copper replan before subsequent bridge/paid traction phases. This is event-driven invalidation, NOT an incremental edge-only graph. Retain 60 tick audit, 600 tick full replan; never assume event handles silent creation/rotation/teleport/force/surface edits. A newly placed rail without raised build may still need existing audit; silent replacement under a mast with stale attachment metadata remains open. Do not reduce audits yet.
- Initial prototype attempted get_entity_by_unit_number for rails: actual silent-cut test failed at tick203 because registered dependencies were not found. Corrected to real rail references from traversal and actual attachment lookup, then reran. First test fixture wrong Factorio version (2.0 vs 2.1), corrected. Test-mode auto_save did not yield file, actual server settings first lacked required description, then used complete local settings and server_save. All failed attempts retained; no claim test-mode autosave succeeded.

## Actual Factorio Linux headless 2.1.24 build 87808

Three additional successful real scenarios on exact final 0.1.91:

1. `watch.log`, explicit native PASS tick662. Direct copper cut/rejoin tick121/122; raised rail cut and restore; reload_script tick190, silent rail cut tick200, notification tick200, native network split checked tick203 (before old tick600 full audit), silent middle rail restore checked tick601, foreign copper link rejected at tick661. Not a guarantee of max 3 ticks in all circumstances.
2. `watch-powered.log`, PASS tick361. Real 3 substations, five masts, generator/consumers, actual rail signal on route. Silent cut tick200, split by203, residual 333333.33333334 J; no further delivery in interval 220..260; raised rebuild at260, 16333333.333333 J delivered by360. No free energy claim; finite post-cut buffer/transient measured.
3. `watch-disk-load.log`, PASS tick361. Real loopback server saved at tick180 (`watch-server-retry.log` Saving finished); disk checkpoint 627299 bytes. Reloaded with --test-save, silent cut on tick200 (notification same tick), same split, residual, zero later delivery and restored energy. Registration persisted through disk save/load. Server only local, not MP sync test. A test-mode save-phase completion marker alone was not accepted as proof.

All 53 prior cases pass on final 0.1.91 (48 explicit test completion + five assertion stands). Total 56 successful candidate scenarios. Logs and exact test inputs preserved. No Windows GUI/full hidden helper visibility, 100km, complex junctions, external mod compatibility, long-run live factory or MP determinism confirmation.

## Performance

Same synthetic input saves, 2 runs per version, 480 ticks for 50/100, 1200 for long201. Code-only candidate uses info.json 0.1.90 to exclude migration; not an actual-version A/B. Sequential after all regressions. Native checksums are expected to differ when object registrations and storage change; use measured functional/energy log comparison, not claim bit-identical state. Retain complete logs and results. Candidate is for correctness research; no full incremental performance improvement claim.

| Stand | Base mean ms | Code-only mean ms | Change | Worst base/new ms | Checksum base/new |
|---|---:|---:|---:|---:|---|
| 50x2 | 15.777 | 18.176 | +15.20% | 282.210/380.220 | 795879977/459770866 |
| 100x2 | 38.453 | 40.514 | +5.36% | 706.741/810.380 | 3549769304/3232621275 |
| long201 | 2.497 | 3.153 | +26.30% | 73.349/47.414 | 3176383464/924697466 |

Paired recorded logs (prefix removed):

- 50x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 300/300, equal, [EM069 BUFFER STOP]: 0/0, equal
- 100x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 600/600, equal, [EM069 BUFFER STOP]: 0/0, equal
- long201: [EM072 PAID LEDGER]: 40/40, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 40/40, equal, [EM065 CONTACT]: 40/40, equal, [EM060]: 2400/2400, equal, [EM069 BUFFER STOP]: 1198/1198, equal

Gate NOT MET; no primary install. Same-version checksums differ; deterministic repetition within each variant does not prove cross-version identical state. Registration metadata adds work and the candidate still fully re-plans. Next: use dependency-specific invalidation and measure the graph/audit cost; do not decrease independent audits until coverage for silent creation/attachment changes established. Preserve 20MW station, helper ownership and native GUI invisibility requirements.

## Direct Patch

Four replacements, zero deletions, approved build/verify PASS. ZIP SHA256 `83b99e57f68abb4958bbe8737145b754f5b72b623c9c8d2d5dae4cd7473011f2`; target tree `8699baf53a951337cdcb145882195a4cb6daa22440a1d3bf42ea735ec6edb8af`. Only exact 0.1.90 isolated install. No main merge/release.

## Regression results

| Case | Status | seconds |
|---|---|---:|
| `alerts-nopath1` | PASS | 3.342 |
| `alerts-nopath201` | PASS | 4.427 |
| `alerts-nopath800` | PASS | 7.559 |
| `alerts-nopathdual201` | PASS | 4.455 |
| `alerts-nopathzero201` | PASS | 3.696 |
| `attach-bidir` | PASS | 5.006 |
| `attach-dual` | PASS | 3.859 |
| `attach-grow-retry` | PASS | 4.003 |
| `attach-same` | PASS | 3.350 |
| `attach-shrink-retry` | PASS | 4.094 |
| `audit-block` | PASS | 4.145 |
| `audit-churn` | PASS | 6.107 |
| `audit-churn100` | PASS | 18.979 |
| `audit-fair` | PASS | 4.549 |
| `audit-gui` | PASS | 3.799 |
| `audit-move` | PASS | 3.907 |
| `audit-offgrid` | PASS | 4.497 |
| `audit-ownerloss` | PASS | 3.181 |
| `audit-retain` | PASS | 3.179 |
| `audit-visibility` | PASS | 4.076 |
| `bench-100x2` | PASS | 14.335 |
| `bench-10x2` | PASS | 3.739 |
| `bench-1x2` | PASS | 3.706 |
| `bench-1x800` | PASS | 6.716 |
| `bench-50x2` | PASS | 7.547 |
| `extended-0` | PASS | 3.818 |
| `extended-1` | PASS | 3.337 |
| `extended-199` | PASS | 3.381 |
| `extended-200` | PASS | 4.084 |
| `extended-201` | PASS | 4.428 |
| `extended-400` | PASS | 4.597 |
| `extended-401` | PASS | 4.794 |
| `extended-600` | PASS | 6.233 |
| `extended-800` | PASS | 6.525 |
| `extended-dual201` | PASS | 4.427 |
| `extended-mixed` | PASS | 3.613 |
| `extended-ownerlossdual` | PASS | 3.694 |
| `extended-passive` | PASS | 3.092 |
| `extended-power401` | PASS | 7.940 |
| `extended-prototypes-retry` | PASS | 3.725 |
| `extended-split` | PASS | 3.413 |
| `extended-standalone` | PASS | 3.408 |
| `extended-vanilla` | PASS | 3.136 |
| `extended-zero201` | PASS | 3.670 |
| `migration085` | PASS | 2.071 |
| `moving-1` | PASS | 3.701 |
| `moving-10` | PASS | 5.081 |
| `moving-100` | PASS | 39.970 |
| `moving-50` | PASS | 19.548 |
| `native-corridor` | PASS | 3.917 |
| `native-segments` | PASS | 3.432 |
| `network-multi48` | PASS | 7.141 |
| `network-topology` | PASS | 4.314 |