# EM087J — Vanilla First: certified unreachable rail targets and idle buffer isolation, 2026-11-26

**PARTIAL / EXPERIMENT, NOT owner-accepted.** Base exact 0.1.95, EM087I commit `063d87a6cb491759f45fa9a63e27a00926e26339`, SHA256 `df0cd2857f11071e09ac1c4bf73d2682b062d57fa888bcfb832aaa8252a7ed4b`. Final 0.1.96 archive SHA256 `229415b1f3676b2f88b09408d67cf14b659a18031b114df5769d075cd23c268c`. Main remains `cf75656fda374824944311f26bbd454bc90ad45b`. Last owner-confirmed 0.1.84; maintenance candidate 0.1.86. No owner installation, merge or release.

## Exact source changes

Three changed game files: info.json, scripts/power_019.lua, scripts/power_bridge_058.lua. All 157 game files accounted for; 99 PNG unchanged. No helper lifecycle, train coupling, prototypes, power caps or accepted design changes. Full 600-tick planning and 60-tick audits unchanged.

1. The existing native straight HSR segment certificate already proved the complete cardinal chain with exactly 2-tile steps, same force/surface, and no reachable allowed outside continuation. A target absent from that chain or beyond the bounded path budget can be rejected without the redundant bounded Lua traversal. `false` is a proven negative; `nil` retains the previous exact walker for all uncertain cases (including reachable external continuations). No persistent cache or native train pathfinder substitution. This is an optimization of the existing strict proof, not removal of HSR validation. The 8192-tile segment size limit remains.
2. Found a pre-existing idle drain defect: a factory/corridor short introduced by a foreign wire left a charged output enabled. Both original 0.1.95 and initial path-only 0.1.96 reproduced it. On final 0.1.96, check native canonical parent keys before actual buffered discharge; own factory must not share a corridor parent. If equal to its own line key, reject immediately; otherwise lazily collect live corridor keys within the same synchronous phase. Freeze the existing interfaces via the existing reject/stop machinery; do not write off or generate energy. New-transfer isolation remains unchanged. This specifically closes the tested own-factory short case and protects idle drains against the own factory sharing a different corridor. Full cross-terminal short/switch fault coverage, unavailable API fallback cases and multi-mod concurrency not established; no claim that all electrical isolation failures are solved.

## Native fault reproduction and repair

Fixture: real 20 MW source, two consumers, three substations, five masts. Source/sink EEIs are the test fixture, no direct injection of joules into mod buffers. Tick239 stop sink B demand; tick240 charged output 166666.667 J; tick241 inject actual player-origin foreign copper wire between factory and mast. At tick242 factory/corridor network IDs equal. Original 0.1.95 and initial path-only 0.1.96: tick243 output buffer 55555.556 J with output flow 166666.667 J/tick; tick244 7936.508 J; tick245 184.570 J; tick246 0.102 J; explicit FAIL t247. This demonstrates improper continued output permission, not energy creation. Final fix: reject at t241, retained 333333.333 J (includes earlier input transferred in normal scheduling), t243..246 output flow zero and energy unchanged, t270 still frozen. Audit removes foreign wire; t305 networks separate, restart actual demand, by t365 received 9833333.333 J; explicit PASS tick366. Earlier fixture attempt had empty output; corrected by disabling load a tick earlier. The initial failures and shorter repaired run are preserved.

## Native gameplay regression

Real Linux headless Factorio 2.1.24 build 87808. Final exact 0.1.96: 53 inherited cases (48 explicit PASS + 5 stand assertions), 8 earlier extra explicit tests, 1 new fault/recovery test, total **62/62** (57 explicit + 5 stands). Native path oracle: 8935 comparisons, 3603 positive fast hits, exact length/curved/eligibility; straight/signal/vanilla rail/restore, native copper split/rejoin and alternate loop. 100 moving trains arrived, 7600 aggregate tiles, paid 601666666.66668 J including 135000000.00002 J motor, cargo and helper identities checked. Other cases include 401 motors/11 substations, 800 motors, 100 teardown cycles, 48 substations and old checkpoint load. Initial path-only batch interrupted by tool time limit; those results not counted for final. All final runs completed. Complete Windows native consist invisibility remains mandatory and unverified.

## Profiled 100-train same-version A/B (500 ticks, one run each)

Separate instrumentation builds, version 0.1.95 in both to exclude version migration; corrected profiler uses native localized log of LuaProfiler. First attempt printed only object references, retained as failed measurement. Tick600:

| Stage | Base ms | Final code ms |
|---|---:|---:|
| anchors | 74.872 | 9.261 |
| candidate grouping | 55.350 | 45.947 |
| path search | 510.189 | 162.440 |
| watch metadata | 34.858 | 25.557 |
| wire audit | 29.544 | 24.055 |
| connect | 8.126 | 6.657 |
| total technical046 | 714.428 | 275.273 |

Profiled whole tick avg 38.018 -> 33.761 ms, max 819.740 -> 400.824 ms, both checksum 1536273116. Before the idle repair (path-only intermediate) separate profile gave path search 59.689 ms, total technical046 180.040 ms, peak 436.743 ms; do NOT attribute that number to the final code. Large host variance; no universal guarantee. At tick600 final art030 40.563 ms, bridge058 12.767 ms, paid 32.759 ms; further profiling needed.

## Uninstrumented final code-only A/B

Same exact saves and version number 0.1.95 in both, 480 ticks for 50/100, 1200 ticks long201, one run per variant, no concurrent regression. No full-version migration performance or same-save moving performance benchmark. Sample size small; compare mean and maximum separately.

| Stand | Base mean ms | Final mean ms | Base max ms | Final max ms | Checksum |
|---|---:|---:|---:|---:|---:|
| 50x2 | 14.984 | 15.258 | 379.496 | 221.735 | 1007386487 |
| 100x2 | 36.870 | 33.285 | 724.190 | 397.873 | 3546774067 |
| long201 | 3.135 | 2.732 | 25.594 | 57.536 | 616494488 |

All paired engine checksums and diagnostics matched: 36 paid ledger lines, 36 native sink load, 36 contact, 1650 station status, 599 buffer-stop, 4 motor-state lines (counts per variant). Earlier path-only pair on 50 trains 17.962 -> 16.269 ms, max 337.266 -> 184.078; not final candidate result. On final 50 mean +1.83%; 100 mean -9.72% and peak -45.06%; long201 mean -12.85%, peak increased. 60 UPS not established.

## Delivery and next step

Approved Direct Patch build/verify PASS 0.1.95 -> 0.1.96, three replacements, no deletion. Patch SHA256 c90114553c74b7835218630d882b434a5ab437963475fb8716eecbbbf4513098. Use only exact experimental base, not primary owner game. The safety fix should be considered for a separate maintenance backport after review (do not silently change owner files). Candidate remains experimental. Next prioritize measured steady bridge/traction and visual costs, avoid multiplying Lua graph/cache structures; repeat controlled measurements with more samples, actual full-version moving saves and safety fault matrix, including native switches, peer short, all auto/manual modes, force/surface, long-run, 100km, MP/mods and Windows native train GUI. Retain audit cadence until evidence supports changing it.

## Final regression case list

| Case | Status | Seconds |
|---|---|---:|
| alerts-nopath1 | PASS | 4.630 |
| alerts-nopath201 | PASS | 5.204 |
| alerts-nopath800 | PASS | 7.200 |
| alerts-nopathdual201 | PASS | 4.274 |
| alerts-nopathzero201 | PASS | 3.849 |
| attach-bidir | PASS | 6.479 |
| attach-dual | PASS | 3.200 |
| attach-grow-retry | PASS | 4.242 |
| attach-same | PASS | 3.417 |
| attach-shrink-retry | PASS | 3.834 |
| audit-block | PASS | 4.856 |
| audit-churn | PASS | 7.163 |
| audit-churn100 | PASS | 17.303 |
| audit-fair | PASS | 4.641 |
| audit-gui | PASS | 4.562 |
| audit-move | PASS | 4.763 |
| audit-offgrid | PASS | 4.452 |
| audit-ownerloss | PASS | 3.394 |
| audit-retain | PASS | 3.443 |
| audit-visibility | PASS | 3.345 |
| bench-100x2 | PASS | 12.949 |
| bench-10x2 | PASS | 5.041 |
| bench-1x2 | PASS | 4.137 |
| bench-1x800 | PASS | 6.554 |
| bench-50x2 | PASS | 8.420 |
| extended-0 | PASS | 3.254 |
| extended-1 | PASS | 3.357 |
| extended-199 | PASS | 3.848 |
| extended-200 | PASS | 3.700 |
| extended-201 | PASS | 4.102 |
| extended-400 | PASS | 4.555 |
| extended-401 | PASS | 5.072 |
| extended-600 | PASS | 5.576 |
| extended-800 | PASS | 6.964 |
| extended-dual201 | PASS | 5.006 |
| extended-mixed | PASS | 3.710 |
| extended-ownerlossdual | PASS | 3.582 |
| extended-passive | PASS | 3.537 |
| extended-power401 | PASS | 8.981 |
| extended-prototypes-retry | PASS | 3.151 |
| extended-split | PASS | 4.623 |
| extended-standalone | PASS | 3.296 |
| extended-vanilla | PASS | 3.702 |
| extended-zero201 | PASS | 3.741 |
| migration085 | PASS | 2.637 |
| moving-1 | PASS | 3.911 |
| moving-10 | PASS | 5.362 |
| moving-100 | PASS | 34.473 |
| moving-50 | PASS | 15.670 |
| native-corridor | PASS | 3.706 |
| native-segments | PASS | 3.455 |
| network-multi48 | PASS | 7.191 |
| network-topology | PASS | 4.447 |
| mast-audit | PASS | — |
| watch-native | PASS | — |
| watch-powered | PASS | — |
| watch-disk-load | PASS | — |
| localplan | PASS | — |
| native-router | PASS | — |
| native-wire | PASS | — |
| native-switch | PASS | — |
| idle-fault-recovery | PASS | — |
