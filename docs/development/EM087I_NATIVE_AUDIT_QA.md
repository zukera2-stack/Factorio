# EM087I — Vanilla First: exact mast singleton check and no-work bridge guard, 2026-11-26

**PARTIAL / EXPERIMENT, NOT accepted.** Base exact 0.1.94 / EM087H commit `c1ea587040ddabbcf0bc215700c41ad8a59a09a6`, archive SHA256 `229a75b0d14bf64c7a17542c16855e93b66a975616eaaddf23037f1da815702f`. Candidate 0.1.95 SHA256 `df0cd2857f11071e09ac1c4bf73d2682b062d57fa888bcfb832aaa8252a7ed4b`. Last owner-confirmed running archive 0.1.84, maintenance candidate 0.1.86. No main merge, release or owner installation.

## Changes

Exactly 3 changed gameplay files: info.json, scripts/mast_network_059.lua, scripts/power_bridge_058.lua. 157 total, all 99 PNG unchanged. In mast audit, native `real_connection_count==1` and origin-aware `is_connected_to` prove the exact sole expected physical connection. For any other state keep original enumeration, rejection, and repair; existing surface/force checks and connection verification unchanged. Native power bridge: skip corridor isolation scan only when `#candidates==0` after dispatch and idle/drain handling. `observe` has only phase-local table effects at this point, and those tables are not used afterwards if there are no candidates. All original isolation checks remain for every nonempty batch. Existing idle_or_drain may transfer previously buffered energy before this block; its behavior has not been changed, and this optimization is NOT a proof of every idle-drain isolation property. No persistent cache, no reduced audit frequencies, no change to HSR eligibility, station cap (20 MW), helper coupling, traction, paid energy or prototypes. Native C++ owns actual copper topology.

## Real engine regression

Factorio Linux headless 2.1.24 build 87808. Exact version 0.1.95: 53 inherited cases (48 explicit PASS + 5 native stand assertions) and 8 extra explicit cases (56 explicit PASS + 5 stands total). New mast-audit tests real visible mast with foreign player wire injected tick125, verified actually present tick126, removed by tick185; own script connection removed at185, verified absent186, restored245; wrong-origin player connection injected245, verified246, repaired305; explicit engine Test passed at tick306. Initial fixture injected at periodic audit tick120 and mistakenly expected it still present next tick; failed test log preserved, corrected rerun PASS. No game edits between the two attempts. Native connector equivalence, parent grouping switch, watcher and local replan, old disk checkpoint, no-path alerts, motor block boundaries, 100 simultaneous moving trains, 800 motors, fairness, 48 substations, 100 teardown cycles and old migration also passed. This is not Windows GUI validation; full invisibility of technical motors remains a mandatory pending acceptance requirement. Source exact game archive and patch verified, not an official release.

## Code-only same-version A/B benchmarks

Same saves, 0.1.94 info.json in both benchmark variants, two runs each. 480 ticks on 50/100 stationary stands, 1200 on long201. Regression processes finished before benchmark started. Not separate exact 0.1.95 migration-performance tests, nor whole-factory/moving UPS. Small sample and host variability; compare mean and peak separately. Source checksums and paid logs verified below.

| Stand | Base mean ms | New code mean ms | Change | Worst base/new ms | Checksums base/new |
|---|---:|---:|---:|---:|---|
| 50x2 | 19.6200 | 17.2055 | -12.31% | 485.909/409.360 | 2177348553/2177348553 |
| 100x2 | 39.2425 | 36.6980 | -6.48% | 876.568/1006.199 | 1612775364/1612775364 |
| long201 | 3.0900 | 2.9965 | -3.03% | 53.078/47.568 | 1283783239/1283783239 |

Recorded diagnostic line comparisons (ignore timestamp/path prefix):

- 50x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 300/300, equal, [EM069 BUFFER STOP]: 0/0, equal, [EM077 MOTOR STATE]: 2/2, equal
- 100x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 600/600, equal, [EM069 BUFFER STOP]: 0/0, equal, [EM077 MOTOR STATE]: 2/2, equal
- long201: [EM072 PAID LEDGER]: 40/40, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 40/40, equal, [EM065 CONTACT]: 40/40, equal, [EM060]: 2400/2400, equal, [EM069 BUFFER STOP]: 1198/1198, equal, [EM077 MOTOR STATE]: 4/4, equal

## Status and blockers

Keep as experiment; 100-train 60 UPS gate not established. No claim of eliminating all electrical network duplication: physical HSR eligibility and independent foreign-wire audit remain essential. Need controlled full-version moving same-save benchmarks, separate idle-drain isolation fault injection, complex junctions, 100km, long-run memory, MP/mod compatibility, and Windows native GUI. Future work should focus on measured costs rather than another persistent cache. Do not alter accepted rules or install on owner's primary game without acceptance. Next proposal: profile global technical anchor audit vs bridge and measure idle/active phase costs separately, then decide whether to simplify rather than extend the experimental topology.

## Delivery

Approved direct_patch.py build and verify PASS 0.1.94 -> 0.1.95, three files, no deletions. Patch SHA256 3678293ed0a8e9d741df9cf1c932a4b7fe641b33ec84394c83835e317262ac5e. Only apply to exact tested 0.1.94 experimental base, not owner 0.1.84. Full candidate archived separately. No official CI or merge. Reproduction scripts refer to previous local fixture directories; supplied test sources and saves allow reconstructing them.

## Regression cases

| Case | Status | Seconds |
|---|---|---:|
| `alerts-nopath1` | PASS | 3.610 |
| `alerts-nopath201` | PASS | 4.146 |
| `alerts-nopath800` | PASS | 7.271 |
| `alerts-nopathdual201` | PASS | 4.279 |
| `alerts-nopathzero201` | PASS | 4.518 |
| `attach-bidir` | PASS | 5.312 |
| `attach-dual` | PASS | 3.921 |
| `attach-grow-retry` | PASS | 4.096 |
| `attach-same` | PASS | 3.441 |
| `attach-shrink-retry` | PASS | 4.387 |
| `audit-block` | PASS | 3.914 |
| `audit-churn` | PASS | 6.215 |
| `audit-churn100` | PASS | 21.340 |
| `audit-fair` | PASS | 4.676 |
| `audit-gui` | PASS | 3.455 |
| `audit-move` | PASS | 3.661 |
| `audit-offgrid` | PASS | 4.478 |
| `audit-ownerloss` | PASS | 3.545 |
| `audit-retain` | PASS | 3.208 |
| `audit-visibility` | PASS | 3.399 |
| `bench-100x2` | PASS | 14.085 |
| `bench-10x2` | PASS | 3.390 |
| `bench-1x2` | PASS | 3.374 |
| `bench-1x800` | PASS | 8.235 |
| `bench-50x2` | PASS | 7.209 |
| `extended-0` | PASS | 4.602 |
| `extended-1` | PASS | 4.117 |
| `extended-199` | PASS | 3.629 |
| `extended-200` | PASS | 5.044 |
| `extended-201` | PASS | 4.605 |
| `extended-400` | PASS | 4.240 |
| `extended-401` | PASS | 5.173 |
| `extended-600` | PASS | 5.846 |
| `extended-800` | PASS | 6.394 |
| `extended-dual201` | PASS | 4.347 |
| `extended-mixed` | PASS | 4.231 |
| `extended-ownerlossdual` | PASS | 4.186 |
| `extended-passive` | PASS | 3.026 |
| `extended-power401` | PASS | 8.066 |
| `extended-prototypes-retry` | PASS | 3.447 |
| `extended-split` | PASS | 3.916 |
| `extended-standalone` | PASS | 3.592 |
| `extended-vanilla` | PASS | 3.126 |
| `extended-zero201` | PASS | 4.250 |
| `migration085` | PASS | 2.396 |
| `moving-1` | PASS | 3.706 |
| `moving-10` | PASS | 5.093 |
| `moving-100` | PASS | 39.197 |
| `moving-50` | PASS | 21.178 |
| `native-corridor` | PASS | 4.110 |
| `native-segments` | PASS | 3.617 |
| `network-multi48` | PASS | 7.025 |
| `network-topology` | PASS | 4.303 |
| `mast-audit` | PASS | — |
| `watch-native` | PASS | — |
| `watch-powered` | PASS | — |
| `watch-disk-load` | PASS | — |
| `localplan` | PASS | — |
| `native-router` | PASS | — |
| `native-wire` | PASS | — |
| `native-switch` | PASS | — |