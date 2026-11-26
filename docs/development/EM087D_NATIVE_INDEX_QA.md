# EM087D — native network index (2026-11-26)

**PARTIAL / EXPERIMENT. Not owner-accepted or a release.** Base exact 0.1.89 EM087C, GitHub `80fe245f122e7cda6306fc7a705e17804d48fe7c`, ZIP SHA256 `a248628b6ceacaad37f51d63d9b5baf35bd64122e1cb7f60813a3414ca3a5c1d`. Target full experimental ZIP 0.1.90 SHA256 `b2721282661a508ef6840da95c59b9589519a663278c097b6b36b8d59af3ca34`. Two replacement files: info.json and traction_paid_065.lua. All 99 PNG, helper lifecycle, graphics, prototype geometry, bridge port checks, topology audits, and traction/battery rules unchanged. The user accepted investigation of native electrical topology, not a main merge or installation.

## Implemented

`active_bridge_index()` reads active import bridges once on first request per synchronous phase, using fresh real native subnetwork ID and force index. Preserves all validity and identity checks, minimum donor unit ID, 20 MW per eligible bridge count. `phase_bridge` index is local, not persisted. Separate instance in `requests` (before bridge settlement) and `fair_charge` (after bridge settlement and helper reconciliation). Existing sink_for_output checks current native port/output IDs again before creating, reusing or crediting a sink; credit_paid verifies actual native connected sink. EEI creation/teleport attaches a consumer, not a copper connection. Capacity uses the active bridge index in the latter phase; no path or permission cache between ticks. Demand phase lazily indexes existing valid native sinks by real network and force. No writes to train.speed; finite paid grant and max-min fairness untouched. The changed operation is traction-side bridge lookup, not the actual bridge solver or persistent incremental topology. Complexity of repeated source lookup falls from O(stations*distinct queried nets) to O(stations+queried nets) per phase when used. Cache may cost more for small/saturated stands.

## Sequential same-save A/B, Factorio Linux headless 2.1.24 build 87808

Code-only ZIP retains base info.json 0.1.89, to exclude extra version migration; exact 0.1.90 also tested functionally. Same input saves, two runs per variant, 480 ticks for 50/100 and 1200 for long201. No concurrent regressions during benchmark.

| Stand | Mean base ms | Mean code-only ms | Worst measured base / new ms | Native checksum |
|---|---:|---:|---:|---|
| 100x2 stationary | 38.508 | 38.371 | 773.510 / 688.637 | 1604236467 both runs each |
| 50x2 stationary | 14.632 | 16.166 | 301.115 / 307.947 | 1535528559 both runs each |
| long201 stationary | 2.690 | 2.691 | 47.517 / 57.436 | 1512069736 both runs each |

All 72 paired paid ledger lines, 72 native load, 72 contact records, 3300 station status records and 1198 buffer stop records match exactly after stripping log prefix. This does not prove all game states equivalent. 50 stand mean regressed ~10.5%; 100 mean essentially unchanged (-0.36%). Small sample and host scheduling variation; not sufficient to claim stable performance improvement for stationary trains. No actual version 0.1.90 A/B benchmark performed. Performance gate remains NOT MET.

## Active traction profile

Two *instrumented research copies*, base and code-only version, both execute real moving-100 test scenario. Profiler around only requests (bridge) and fair_charge (paid traction) at ticks 130..350 every 10 ticks, 23 samples per function and variant. Sequential runs with no other benchmarks. Different fixture unit numbers on fresh setup (not a same-save checksum comparison), exact same arrival/distance and paid-energy aggregate. Profiling adds overhead; this is function time, not overall UPS.

| Function | Base mean ms | Code-only mean ms | Base/new median ms | Base/new max ms |
|---|---:|---:|---:|---:|
| requests | 19.305 | 7.011 | 15.362 / 5.954 | 37.086 / 26.397 |
| fair_charge | 14.326 | 4.766 | 2.847 / 2.852 | 75.608 / 9.772 |
| Sum of means | 33.631 | 11.778 | — | — |

~65.0% reduction of summed mean sampled function times; fair_charge median essentially unchanged, improvement dominated by expensive active ticks. Both scenarios PASS at tick 501, simultaneous 100/100, visited 100/100, 7600 aggregate tile displacement, paid 601666666.66668 J, motor paid 135000000.00002 J. All 9 aggregate paid and native load records match. Unit IDs differ between fresh fixture runs, so no claim of byte-identical per-station lines. Profiler code not in patch. This gives evidence of useful active-traction improvement despite weak stationary results. Full movement benchmark from same save and total tick distribution remain needed.

## Native destruction notification (independent test only)

Official runtime docs `https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#register_on_object_destroyed`, `https://lua-api.factorio.com/latest/events.html#on_object_destroyed` describe registration surviving save/load and delivery at end of current or following tick. Real 2.1.24 probe registered a HSR rail twice (same registration ID), reloaded Lua at tick 5, destroyed rail with raise_destroy=false at tick 10, received exactly one on_object_destroyed event tick 10, zero script_raised_destroy events. Explicit PASS at tick14. This is isolated notification test, not proof of immediate electrical disconnect in full mod. Next design: index path dependencies by registered rail IDs, invalidate affected path certificates on destruction before next settlement; compare native alternative path, segment membership and masts. Retain independent audit for silent creation/rotation/teleport/force changes, and unresolved dependencies. Do not remove 60/600 audits until proof. Disk save/load registration not directly tested in this probe; reload_script is not disk reload.

## Direct Patch / acceptance

`EM087D_native_index_EXPERIMENT_Direct_Patch_from_0.1.89.zip` SHA256 `43659633b3b4ee4bc858b454cf8958311bb4a5fa94ae800aed56cb6a7f347efd`, target tree SHA256 `92801342c8d64f2042afa979519be714befc1908172fadb24fb30d343fba339a`; approved direct_patch.py build and verify PASS, two replacement files and no deletions. Only exact 0.1.89 isolated install. Full archive in library. Last owner-running 0.1.84; maintenance candidate 0.1.86. Windows native train GUI full invisibility remains mandatory and unverified. No main/merge/release. 100km, complex junctions, long-running factory, MP, external mods, actual-version performance, persistent incremental graph remain open. No battery/regen stage until performance gate is addressed. Next focus: register silent rail destructions and native parent-network observations, plus equal-save moving benchmarks and long duration.

## Final regression

Exact packaged 0.1.90: 53/53 prior cases pass (48 explicit native test completions and 5 stand assertion cases); independent destruction watcher PASS, 54 successful candidate scenarios in total. Two separately instrumented 100-moving runs also pass. No regression detected in exercised scenarios.

| Case | Status | seconds |
|---|---|---:|
| `alerts-nopath1` | PASS | 3.780 |
| `alerts-nopath201` | PASS | 4.147 |
| `alerts-nopath800` | PASS | 8.238 |
| `alerts-nopathdual201` | PASS | 5.124 |
| `alerts-nopathzero201` | PASS | 3.811 |
| `attach-bidir` | PASS | 5.260 |
| `attach-dual` | PASS | 3.338 |
| `attach-grow-retry` | PASS | 4.622 |
| `attach-same` | PASS | 3.450 |
| `attach-shrink-retry` | PASS | 4.401 |
| `audit-block` | PASS | 3.848 |
| `audit-churn` | PASS | 6.986 |
| `audit-churn100` | PASS | 16.565 |
| `audit-fair` | PASS | 4.045 |
| `audit-gui` | PASS | 4.054 |
| `audit-move` | PASS | 4.126 |
| `audit-offgrid` | PASS | 3.894 |
| `audit-ownerloss` | PASS | 3.797 |
| `audit-retain` | PASS | 3.390 |
| `audit-visibility` | PASS | 3.355 |
| `bench-100x2` | PASS | 12.714 |
| `bench-10x2` | PASS | 3.763 |
| `bench-1x2` | PASS | 3.696 |
| `bench-1x800` | PASS | 7.099 |
| `bench-50x2` | PASS | 6.899 |
| `extended-0` | PASS | 3.378 |
| `extended-1` | PASS | 3.554 |
| `extended-199` | PASS | 3.640 |
| `extended-200` | PASS | 4.098 |
| `extended-201` | PASS | 3.899 |
| `extended-400` | PASS | 4.434 |
| `extended-401` | PASS | 4.974 |
| `extended-600` | PASS | 5.664 |
| `extended-800` | PASS | 6.392 |
| `extended-dual201` | PASS | 4.330 |
| `extended-mixed` | PASS | 3.492 |
| `extended-ownerlossdual` | PASS | 3.399 |
| `extended-passive` | PASS | 3.434 |
| `extended-power401` | PASS | 6.889 |
| `extended-prototypes-retry` | PASS | 3.044 |
| `extended-split` | PASS | 3.815 |
| `extended-standalone` | PASS | 3.357 |
| `extended-vanilla` | PASS | 2.980 |
| `extended-zero201` | PASS | 3.604 |
| `migration085` | PASS | 2.172 |
| `moving-1` | PASS | 3.334 |
| `moving-10` | PASS | 5.238 |
| `moving-100` | PASS | 40.852 |
| `moving-50` | PASS | 19.982 |
| `native-corridor` | PASS | 3.653 |
| `native-segments` | PASS | 3.691 |
| `network-multi48` | PASS | 8.579 |
| `network-topology` | PASS | 4.560 |
