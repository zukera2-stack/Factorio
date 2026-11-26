# EM087K — steady phase / native isolation QA (2026-11-26)

**PARTIAL / EXPERIMENT — NOT owner-accepted.**

Base 0.1.96: `229415b1f3676b2f88b09408d67cf14b659a18031b114df5769d075cd23c268c`, Git parent `4096f3e3cc1295a4cc4ab95ec5f640c28191460b`. Candidate 0.1.97: `1f7f840ac4242b1e4cb2fba9b7c138b986b0498f981a5a8c1f723485ea1ec179`. Exact engine Factorio 2.1.24 build 87808, linux64 headless. Separate local directories only. Main and owner game untouched. Last maintenance candidate remains 0.1.86; last confirmed owner running archive 0.1.84.

## Scope

- catenary_art_030: geometric distance test precedes native rendering lookup; same tie/visibility rules for eligible candidates.
- traction_paid_065: read owner position/surface/force and verified anchor native subnet ID once inside nonmutating contact function. Same validation; no persistence.
- pantograph_visual_049: format sprite name only on creation or change; no changed visual geometry, animation or diagnostics cadence.
- power_bridge_058: share native live corridor set between idle-drain and candidate isolation checks within one synchronous invocation, after terminal repair. Idle/drain changes buffer values or destroys empty EEIs, not poles/wires. No result persists across ticks. Existing parent-network checks, all isolation predicates and 60/600 audits retained.
- info.json version bump. Five changed game files; 157 total, 99 unchanged PNG, no helper lifecycle, coupling, train physics, capacities, 20 MW per-station rules or prototype changes.

## Native QA

53 core (48 explicit engine PASS + 5 SNAP stands); 8 additional explicit (mast audit, watcher native/powered/disk load, localplan, native router/wire/switch); 4 explicit fault matrix tests = 65 (60 explicit + 5 stand assertions). All on exact 0.1.97 candidate. 100 moving trains all visited, distance 7600 tiles, paid 601666666.66668 J incl 135000000.00002 J motor; same cargo/fluid/helper identities; 800 motors, 401 powered, 100 teardown cycles, 48 stations, migration085, 8935 actual path comparisons passed.

| Fault variant | raw factory / fault subnet | Frozen output J | Restored delivery J | Result |
|---|---|---:|---:|---|
| direct | 9 / 9 | 333333.333 | 9833333.333 | PASS |
| cross | 17 / 17 | 333333.333 | 9833333.333 | PASS |
| switch | 7 / 9 | 333333.333 | 9833333.333 | PASS |
| cross-switch | 7 / 17 | 333333.333 | 9833333.333 | PASS |

Real fault injected tick241 after charged export at240, native parent equality asserted at242, zero output flow at243–246, frozen J stable to270, isolation repaired by305, restored delivery by365. Cross cases prove other corridor is independent before comparison; switch cases prove raw subnetwork IDs differ while canonical parent matches. Fixture direct variant derives from EM087J. No claim of all possible modes or all faults solved.

## Same-save whole-tick benchmarks

Uninstrumented code-only 0.1.96 metadata in both variants; two runs per variant. 480 ticks on 50/100 stationary, 1200 ticks long201, 200 ticks from dispatch snapshot for moving100. All sequential, no concurrent QA, host has variable timing and these small samples are not confidence intervals. Moving snapshot made on exact baseline via private localhost server at tick120 after dispatch. All 16 state checksums pairwise equal within each stand and measured logs equal. Actual candidate version-migration perf not separately tested.

| Stand | Base mean ms (two runs) | New mean ms (two runs) | Time change | Base/new max ms | checksum |
|---|---:|---:|---:|---:|---|
| 50x2 | 15.9330 (14.905, 16.961) | 16.8175 (16.563, 17.072) | +5.55% | 254.823/239.213 | 1552571529 |
| 100x2 | 38.9575 (41.816, 36.099) | 36.5130 (36.758, 36.268) | -6.27% | 426.592/506.162 | 211834507 |
| long201 | 3.3070 (3.233, 3.381) | 2.9350 (2.862, 3.008) | -11.25% | 47.941/38.196 | 1332054369 |
| moving100 | 52.0695 (48.939, 55.2) | 49.6560 (49.182, 50.13) | -4.64% | 168.111/171.070 | 917671444 |

All recorded paid ledger, contact, sink, buffer stop, station state, flow, helper state, rail debug and moving logs match after removing timestamps and source line numbers. Native train/cargo full arrival QA separate from 200-tick measurement.

## Profile ordinary tick

Instrumented 180 ticks on same 100x2 save, samples ticks 127,142,...292, 12 per variant; median used because outliers (e.g. 40 ms ports sample). Same checksum 2407261572; profiler is separate, not in patch.

| Function/phase | Base median ms | Candidate median ms |
|---|---:|---:|
| PROFILE/power019 | 0.005699 | 0.005934 |
| PROFILE/technical046 | 0.001918 | 0.001968 |
| PROFILE/mast059 | 0.001833 | 0.001652 |
| BRIDGE/allow_sample | 0.695828 | 0.675162 |
| BRIDGE/ports_observe | 3.502573 | 3.435284 |
| BRIDGE/traction_requests | 2.824310 | 2.882482 |
| BRIDGE/dispatch | 0.253772 | 0.262150 |
| BRIDGE/idle_isolation | 0.312391 | 0.306757 |
| BRIDGE/settlement | 0.003200 | 0.003245 |
| BRIDGE/diagnostic | 0.845284 | 0.806700 |
| PROFILE/bridge058 | 8.457297 | 8.490345 |
| PROFILE/art030 | 0.003044 | 0.003260 |
| PROFILE/helper067 | 1.578123 | 1.654038 |
| PROFILE/paidTraction065 | 3.386926 | 3.476497 |
| PROFILE/visual_diagnostics | 2.676738 | 2.763912 |

Bridge dominates ordinary mod work; native port/observe and traction requests are larger than dispatch. Median bridge unchanged (8.457/8.490 ms), no proven universal optimization.

## New observation: active/idle oscillation

On the same moving snapshot, both variants record exactly 12000 `[EM069 BUFFER STOP]` events across two 200-tick runs; 6000/run, 100 stations on each even tick 202..320, reason `reject:auto-idle-no-connected-peer`. Also 24000 station-status records across both runs. Preexisting, not introduced by K. Every even tick freezes stored buffer; intervening active ticks re-enable. Actual state and ledger equal. Do not infer free energy or suppress logs to hide this. Next isolate demand-feedback and auto-idle decision for single-station traction with actual native demand and paid buffer, prove no phantom power and no starvation, measure state transition count and whole tick. No new persistent cache.

## Limits and handoff

Mixed benchmark results: 50 stationary slower, 100 stationary and long201 faster on sample means, moving mean improved modestly, 100 stationary and moving peak grew. Gate NOT MET, not primary-installable. Full Windows invisibility of native consist GUI, signals/junctions, 100km, long-run, MP/mods, complete manual mode and all terminal fault cases untested. Initial shell streaming launch unsupported; retried ordinary command, no engine test failed in final 65. Startup and worker scripts contain absolute sandbox paths; evidence archives relevant fixtures and saves for adaptation, not standalone executable. Direct Patch build+verify five files, no deletions. No main merge/release.

Patch SHA256 `b3439467df1dd6982dc2a18c355c8fb8ee8d87f346c000d7b03d01d7f57e31af`. Full experimental archive in Library `/Factorio/Local-QA/EM087K_0.1.97_full_EXPERIMENT.zip`.