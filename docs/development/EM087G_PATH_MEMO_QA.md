# EM087G — path-level invalidation and vanilla pathfinder probe, 2026-11-26

**PARTIAL / EXPERIMENT, NOT owner accepted.** Base 0.1.92 exact archive SHA256 `0ef5c4890704808d5efdf21a2c654eb8ae58fcbd34f8320cc7bab87dea37624b`, GitHub `51eceb442ed7d8fdd487795f9d46e861e427f431`. Candidate 0.1.93 exact archive SHA256 `9d8db918f7fa279aa8ae96d59b4ca6a5d30eef0480b5e0e8867f964472bc8531`. User requested next stage and maximum use of vanilla rather than duplicating native mechanisms. Last owner-running 0.1.84; latest local maintenance candidate 0.1.86. Two gameplay files changed (info and technical_network_046), 157 files total, 99 PNG byte-identical. No modifications to helper lifecycle, 20 MW station contract, traction, coupling, bridge, prototypes or graphical assets.

## Actual changes / limits

- Reuse only physical path outcomes (positive certificate of actual native rail references or negative result) in an affected potential component during notified edits. Retain old deterministic sorted candidate selection and degree/triangle rules; do not assume previous selected copper edges remain valid after an edit. Every affected component still re-runs selector. No cached network ID, donor, energy grant or permission to supply current. Actual copper wire connections and their native IDs remain authority for power.
- Require unchanged component mast metadata, edit locations outside existing conservative 73-tile radius of both endpoints, positive dependency references still valid with matching position, force and surface. A path with no actual certificate is not stored. A previously skipped geometric pair is queried if required by new selection. Negative results are invalidated near edits; silent new paths are still recovered by full 600-tick replan. No persistent native rail adjacency graph is added; only memoized outcomes. Retain 60-tick real copper audit and 600-tick full physical replan. No alteration of existing normal/silent destruction watcher. Silent changes that neither invalidate reference nor move it (including direction/geometry and creations without events) are not universally covered between full audits. Compared with full replan, a notified unrelated edit can no longer incidentally catch a silent change outside invalidation bounds. Not a safety proof for all mod interactions.
- All native wire reads remain global; potential components still constructed globally. Reuse costs memory and native reference checks. Do not treat query count reduction as whole-function speedup. Additional storage has not been measured at very large scale.

## Native Factorio 2.1.24 build 87808

53 inherited scenarios PASS (48 explicit completion + 5 stand assertions); 100 moving trains, 800 motor wagons, 401 motors with 11 substations, no_path, 256 prototypes, 100 churn cycles, 48 substations, cargo GUI, hidden helper selection and blueprint restrictions, migration from 0.1.85. In addition 3 watcher tests (native, powered, migration/load previous 0.1.91 checkpoint), old four-corridor localplan, new 60-mast pathmemo, and new native-router. Total 59 successful exact candidate scenarios (54 explicit + 5 stands) before fresh disk roundtrip. First watch-native cap 650 was insufficient for final t661 assertion; corrected cap 680 PASS at t662. Preserve short-run log. Powered and disk replay residual 333333.33333334 J, no further delivery ticks220–260; restored power.

### 60 masts in one potential component

60 masts spaced 20 tiles, 644 real straight HSR rails, 117 geometric candidate pairs. At t200 silent cut between masts 15/16; second cut t240 between 45/46; raised repairs t280,320; cut again t360 and silent repair t400; all adjacent native mast network IDs assert expected split/rejoin at t203,243,283,323,363,601. PASS t602. Path query counters at event syncs:

| Tick | Fresh | Reused | Negative results reused |
|---:|---:|---:|---:|
| 201 | 11 | 50 | 0 |
| 241 | 11 | 52 | 3 |
| 281 | 9 | 52 | 3 |
| 321 | 9 | 50 | 0 |
| 361 | 11 | 50 | 0 |

These are actual calls to power.technical_path, not count of all candidate pairs. First cut: 11/61 queries re-evaluated, 81.97% fewer vs the selector without memo (same selector outcome, not independent counter in uninstrumented base). 117/117 geometric candidates still considered. Native rail segment fast path existing from EM087C; no new gameplay native pathfinder substitution.

### Native train pathfinder experiment (test only)

Direct C++ `game.train_manager.request_train_path`, shortest_path=true, return_path=true, starts/goals both rail ends, steps_limit 192. Real native test PASS t181. Straight HSR east/west both found=true, total_length=42 (includes rails, distinct from our center-distance metric). One actual one-way rail signal: east found=false, west found=true; native electric IDs still equal. Replacing one HSR rail by ordinary straight-rail: native route found=true, returned path contains one ordinary rail, but contact line correctly split. Therefore request_train_path is not an electrical-continuity oracle; must not reject a physically connected HSR line merely due to direction signals or accept ordinary track based on a train route. No comparative native pathfinder performance measured. Use native rail segment queries, native rail neighbor API, native destruction registration and copper real_connections/network_id; retain only special HSR eligibility, voltage isolation and source-paid traction in mod. API reference https://lua-api.factorio.com/latest/classes/LuaTrainManager.html and https://lua-api.factorio.com/latest/classes/LuaWireConnector.html (online docs may be newer than tested engine).

### Event replan profiling

Two fresh runs per variant, same 60-mast fixture, test-only helpers.create_profiler measuring M.sync, 5 event syncs each run, 10 per variant. All four runs PASS. Mean 16.2111524 -> 18.0282884 ms (+11.21%); max 23.249999 -> 30.942032 ms. Median 16.621095 -> 17.3006645 ms. Not a proven speed gain even though path call count reduced. Small sample, variability, versions differ (fresh init, not migration), no statistical guarantee. Initial automated regex omitted Duration: prefix and returned empty list; corrected from raw logs and updated parser. Do not treat profiling code as installed gameplay code. Investigate native API read costs rather than expanding caches blindly.


### Fresh same-version disk reload

Saved 0.1.93 at tick250 with two breaks and a populated path memo (real headless server). Loaded the exact disk ZIP (1002639 bytes) with same game version and QA scenario, verified both splits at t260, positive/negative reuse on subsequent repairs, further silent cut, restoration by full audit; explicit PASS t602. The first server attempt failed because the isolated saves directory did not exist; corrected fixture setup and repeated successfully. Gameplay unchanged. This adds one scenario, total **60/60** (55 explicit + 5 stands), plus four profiled runs. No Windows GUI or MP sync verification.

## Stationary whole-tick comparison

Same synthetic saves, code-only variant with same info version 0.1.92, two runs each, 480 ticks for 50/100, 1200 for long201. Full version performance A/B not run. Run in sequence after functional testing.

| Stand | Base mean ms | Code-only mean ms | Change | Worst base/new ms | Checksum base/new |
|---|---:|---:|---:|---:|---|
| 50x2 | 21.737 | 20.430 | -6.02% | 367.643/378.865 | 556739828/556739828 |
| 100x2 | 42.195 | 43.822 | +3.85% | 763.212/1006.722 | 3722375787/3722375787 |
| long201 | 3.722 | 3.532 | -5.09% | 89.319/99.232 | 2633033209/2633033209 |

Paired recorded logs (prefix removed):

- 50x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 300/300, equal, [EM069 BUFFER STOP]: 0/0, equal
- 100x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 600/600, equal, [EM069 BUFFER STOP]: 0/0, equal
- long201: [EM072 PAID LEDGER]: 40/40, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 40/40, equal, [EM065 CONTACT]: 40/40, equal, [EM060]: 2400/2400, equal, [EM069 BUFFER STOP]: 1198/1198, equal

## Decision / next

Do not adopt EM087G as an optimization: functional tests passed but event sync regressed 11.2%, 100 stationary trains regressed ~3.9%, performance gate NOT MET. Keep as research branch; use EM087F 0.1.92 as comparison base for next experiment, without assuming it is accepted. User explicitly prefers vanilla-first. Next prioritize profile of native wire audit and bridge reads; reduce redundant checks only with exact equivalence evidence. Explore native subnetwork accounting vs the verified topology policy, never equate electrical ID alone with allowed HSR path or assume native train routing is electrical continuity. Avoid adding layers of persistent Lua graph/cache without measured benefit. Do not change 60/600 cadence without safe coverage for silent edits. 100km, junctions, multiplayer, mod compatibility, long run, memory A/B and full Windows helper invisibility remain open. No main merge, release or primary install.

## Direct Patch

Two replacements, zero deletions, approved build/verify PASS. ZIP SHA256 `b1e5f966a83d5cd2b6f228444d25a38ba8903c233a2a381a00339fc4b6bd00ae`; target tree `5a85264832b69e907f3cc4f950f20adce986289a7f46f2f34f01667ea8726166`. Exact 0.1.92 isolated install only.

## Regression results

| Case | Status | seconds |
|---|---|---:|
| `alerts-nopath1` | PASS | 3.464 |
| `alerts-nopath201` | PASS | 4.562 |
| `alerts-nopath800` | PASS | 7.555 |
| `alerts-nopathdual201` | PASS | 4.750 |
| `alerts-nopathzero201` | PASS | 3.965 |
| `attach-bidir` | PASS | 5.257 |
| `attach-dual` | PASS | 3.364 |
| `attach-grow-retry` | PASS | 4.412 |
| `attach-same` | PASS | 3.467 |
| `attach-shrink-retry` | PASS | 4.267 |
| `audit-block` | PASS | 4.128 |
| `audit-churn` | PASS | 7.828 |
| `audit-churn100` | PASS | 16.368 |
| `audit-fair` | PASS | 4.304 |
| `audit-gui` | PASS | 3.401 |
| `audit-move` | PASS | 3.655 |
| `audit-offgrid` | PASS | 4.231 |
| `audit-ownerloss` | PASS | 4.065 |
| `audit-retain` | PASS | 3.795 |
| `audit-visibility` | PASS | 3.346 |
| `bench-100x2` | PASS | 12.887 |
| `bench-10x2` | PASS | 4.702 |
| `bench-1x2` | PASS | 3.172 |
| `bench-1x800` | PASS | 7.107 |
| `bench-50x2` | PASS | 8.400 |
| `extended-0` | PASS | 3.641 |
| `extended-1` | PASS | 3.764 |
| `extended-199` | PASS | 3.888 |
| `extended-200` | PASS | 3.648 |
| `extended-201` | PASS | 4.599 |
| `extended-400` | PASS | 4.239 |
| `extended-401` | PASS | 4.575 |
| `extended-600` | PASS | 6.317 |
| `extended-800` | PASS | 6.556 |
| `extended-dual201` | PASS | 3.960 |
| `extended-mixed` | PASS | 3.623 |
| `extended-ownerlossdual` | PASS | 3.696 |
| `extended-passive` | PASS | 3.237 |
| `extended-power401` | PASS | 8.640 |
| `extended-prototypes-retry` | PASS | 4.062 |
| `extended-split` | PASS | 3.745 |
| `extended-standalone` | PASS | 3.432 |
| `extended-vanilla` | PASS | 3.034 |
| `extended-zero201` | PASS | 3.847 |
| `migration085` | PASS | 2.081 |
| `moving-1` | PASS | 5.047 |
| `moving-10` | PASS | 5.499 |
| `moving-100` | PASS | 40.514 |
| `moving-50` | PASS | 25.978 |
| `native-corridor` | PASS | 4.127 |
| `native-segments` | PASS | 3.853 |
| `network-multi48` | PASS | 7.788 |
| `network-topology` | PASS | 4.177 |
| `watch-native` | PASS | — |
| `watch-powered` | PASS | — |
| `watch-disk-load` | PASS | — |
| `localplan` | PASS | — |
| `pathmemo` | PASS | — |
| `native-router` | PASS | — |
| `disk-reload` | PASS | — |
