# EM087O — longer mixed-grid motion and isolated profiling (2026-11-26)

**PARTIAL / test-only PASS.** Parent `4b50b0e9d8a485d142d857b0ae1be4e3374c444e` (EM087N documentation). Runtime remains exact 0.1.98 full archive SHA256 `9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a`. Factorio 2.1.24 build 87808 Linux headless. No production Lua or assets changed; no version bump, release, owner installation or main merge. Last owner-running 0.1.84, maintenance 0.1.86, rejected 0.1.99 not used.

## Longer functional fixture

Derived from EM087N stress: start x=41, destination x=-720, actual displacement assertion >700; track x=-743..143, 45 mast positions per line, same common vanilla generator backbone, four-corridor rings, four types of outposts, same train cargo/fluid. All generators off t1800..2000, cut t2000, rejoin t2200, final t2400. Load changes t480. Both exact uninstrumented 12/24 cases passed t2401 in two memory-budgeted workers, each 23 energy snapshots equal its finite budget at printed precision (assert tolerance 5000 J). Both logged all trains moving at t240,360,480,600 (t480 explicit assertion), stopped by t720; this is sampled motion, not every-tick/100km proof. Arrival and cargo asserted t1800. 12/24 paid train energy 178610514.430/357227384.560 J; budgets 1.5/3 GJ. Two-worker wall 53.627 s, case wall 27.765/53.623 s, peak cgroup 1632268288 bytes, max RSS 492896 KiB, memory events all zero, no guard. RAM limit 4294967296, CPU quota 4, initial 637378560 bytes, 768 MiB reserve, 1000 MiB allowance per worker. First streaming exec unsupported; ordinary process launch monitored to completion. No concurrent profile and QA.

## Dedicated 100-train motion window

Diagnostic copy of exact 0.1.98, only scripts/control.lua and scripts/power_bridge_058.lua instrumented; all 157 ZIP member bytes reproduced by portable preparer and 155 unchanged vs base. Actual diagnostic fixture ends t601 on purpose, all 100 moving at sampled t240/360/480/600 (t480/600 explicit); topology PASS t120, six energy snapshots t0..600 = 12.5 GJ. At t600 paid native traction 1488444257.816 J, remaining source 9901730811.177 J, load 529778628.966 J, battery 285260206.361 J, buffer 275386664.404 J, hidden 19399431.277 J. All snapshots conserve finite energy (not every-tick proof). Native `Test passed at tick 601`; 81.19s wall, max RSS 908576 KiB. No OOM. No claim of arrival, cargo after arrival, outage/rejoin or uninstrumented long100 full run. Not a benchmark or proof of 60 UPS.

## Ordinary tick samples

12 native profiler samples t247,277,...577. Medians are individual phase statistics; do not add medians as whole-tick mean. Bridge subphases nested inside bridge058. Timing includes diagnostic overhead. Single run, no confidence interval or same-save A/B.

| Phase | Median ms | Maximum ms |
|---|---:|---:|
| PROFILE/power019 | 0.006280 | 0.020160 |
| PROFILE/technical046 | 0.002108 | 0.003966 |
| PROFILE/mast059 | 0.001793 | 0.002143 |
| BRIDGE/allow_sample | 1.938607 | 97.267540 |
| BRIDGE/ports_observe | 7.270932 | 48.485992 |
| BRIDGE/traction_requests | 6.238356 | 8.399553 |
| BRIDGE/dispatch | 3.716579 | 8.327284 |
| BRIDGE/idle_isolation | 9.235318 | 10.696481 |
| BRIDGE/settlement | 2.598666 | 2.976340 |
| BRIDGE/diagnostic | 2.501720 | 2.861327 |
| PROFILE/bridge058 | 34.933759 | 178.144999 |
| PROFILE/art030 | 0.004292 | 0.006389 |
| PROFILE/helper067 | 1.942223 | 2.510378 |
| PROFILE/paidTraction065 | 7.593790 | 10.875119 |
| PROFILE/visual_diagnostics | 5.620632 | 6.726777 |

Tick427 bridge058 peak 178.145 ms: allow_sample 97.268, ports_observe 48.486. This is a non-600 sample; cannot attribute to periodic device scan, GC or native API without narrower instrumentation. Dispatch planner not dominant in this sample set.

## Tick600 full topology phase

| Phase | ms |
|---|---:|
| PROFILE/power019 | 0.004938 |
| PROFILE/technical046 | 1524.244400 |
| PROFILE/mast059 | 384.463386 |
| BRIDGE/allow_sample | 64.836401 |
| BRIDGE/ports_observe | 102.014366 |
| BRIDGE/traction_requests | 3.909133 |
| BRIDGE/dispatch | 1.051232 |
| BRIDGE/idle_isolation | 15.237222 |
| BRIDGE/settlement | 2.882959 |
| BRIDGE/diagnostic | 5.704867 |
| PROFILE/bridge058 | 195.914851 |
| PROFILE/art030 | 302.757755 |
| PROFILE/helper067 | 6.843380 |
| PROFILE/paidTraction065 | 7.453388 |
| PROFILE/visual_diagnostics | 6.032930 |

Sum of non-overlapping outer PROFILE phases 2427.715028 ms (not whole tick; excludes unprofiled work and engine overhead). `technical046.on_tick` runs full `M.sync(graph)` on tick%600==0 even on unchanged graph; `M.sync` resolves graph nodes/anchors, candidates/partitions, rebuilds full plan when changes absent, selects paths, updates watches, audits actual copper, reconciles links and refreshes components. `mast059` performs 60-tick independent mast checks, and art030 also updates on this tick. Need subdivide technical full-sync timer before assigning blame to path search vs native audit vs other work. The separate 60/600 native safety checks must stay. No reduction in audit frequency or new persistent permission. **Next EM087P:** profile individual sync stages and canonical live corridor scan; isolate one exact equivalent optimization at a time, preserve unauthorized-wire removal, path validity, energy and topology; compare same-save uninstrumented A/B and full regression (65 previous + 11 mixed + 3 stress + long12/24 and full long100). Existing 65 not rerun; unchanged production code. Windows/MP, full long100 arrival/outage, actual long continuous-motion timing, 60 UPS remain open.

Artifacts: test sources and preparer in `tests/em087m-mixed-outposts/`; runbook `CONTINUOUS_QA.md`. Evidence includes complete logs, profiler summary, memory samples, source, exact instrumented changed Lua files, manifest. Do not distribute diagnostic copy as a patch.

Evidence ZIP SHA256: `effc4d4688e9eb5ebe6a1c55d5747bb54e9a0beea649eeb24dee500acce74dd5`.
