# EM087N — memory-budgeted native parallel QA and connected 100-train stress

**Native test-only PASS: parallel runner and 12/24/100-train connected stress. Runtime stays exact 0.1.98; no production modification.** Parent `464737717489a88c8c5782dc10613617a9921153` (EM087M). Exact game ZIP SHA256 `9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a`; Factorio 2.1.24 build 87808 linux64 headless. No owner installation, merge, or release. Last owner-running 0.1.84; maintenance candidate 0.1.86. Rejected EM087M 0.1.99 not used.

## Resource-aware scheduling

Actual cgroup v2 memory.max 4294967296 bytes (4 GiB), cpu.max 400000/100000 (4 CPU quota), no swap. Initial container usage at discovery 746360832 bytes; after engine extraction and setup roughly 1.0–1.1 GiB. Separate read-only engine data, independent write-data/config/mod-list/QA source/log per worker. Exact game ZIP hardlinked (same filesystem; not written). `--threads 1` is map generation only, not a CPU affinity guarantee. Admission uses actual cgroup memory and CPU quota, reserve 768 MiB, configurable per-worker estimate. Monitor samples cgroup every 150 ms, kills active groups and refuses remaining jobs if threshold crossed. This is a conservative sampled guard, not an absolute OOM guarantee or OS-enforced per-worker limit; the guard did not trigger in the real runs. Initial tool streaming exec unsupported; ordinary shell child launch used and monitored to completion in this turn.

| Batch | Workers | Wall s | Sampled peak cgroup bytes | Max per-process RSS KiB | PASS |
|---|---:|---:|---:|---:|---:|
| Calibration mixed + scale | 2 | 7.552 | 2073378816 | 479768 | 2/2 |
| Same 11-case suite sequential | 1 | 44.302 | 1633517568 | 481092 | 11/11 |
| Same 11-case suite parallel | 3 | 20.339 | 2393780224 | 482252 | 11/11 |
| Stress12 + stress24 | 2 | 26.094 | 2012106752 | 460648 | 2/2 |
| Stress100 dedicated | 1 | 107.230 | 1688064000 | 596860 | 1/1 |

11 cases: mixed, reverse, ring, train, solar, empty, battery, buffer, limit, scale, disk-load. All 124 fixture log lines matched exactly after stripping timestamps/source locations between serial and parallel; all cases native `Test passed at tick`. The comparison is one serial and one 3-worker batch, not a confidence interval. Throughput speedup 2.17818x; wall reduction 54.0901%. Peak cgroup ~2.23 GiB with three workers, measured per-process max ~471 MiB. No cgroup OOM/oom_kill/max events in any completed batch. Three workers with 700 MiB estimate reasonable for this suite and environment; do not assume same for arbitrary saves. No concurrent whole-game performance benchmarks. The original serial run_suite.py was not independently executed; its cases were executed via the new runner.

## Shared-world stress topology

Native common vanilla generator backbone links N/4 four-corridor ring branches (N=12,24,100). N physically distinct 25 kV parent networks, N independent vanilla ring-link networks and one common vanilla generation parent, 11 substations per ring (33/66/275), 2N vanilla accumulators, N trains (one electric locomotive, one motor cargo and one motor fluid wagon plus actual helper per train). N/4 of each outpost role. Each finite metered EEI source initialized 500 MJ, max 20 MW, no refill. Loads initially 2 MW; alternating loads raised to 4 MW at tick480. All trains dispatched at tick120, target station x=-120 from x=41; by tick900 every train must be at its station and moved >100 tiles, cargo 37 iron plates and 9000 water intact. All sources disabled t900, restore t1100 and cut one native transit wire, bypass must deliver energy to affected ring load, rejoin at t1300, final t1500. No production code, train speed, or post-init arbitrary energy credit. Finite EEI generator is test metering, not solar; real solar/radar covered separately in prior suite. 20 MW substation gameplay cap unchanged.

| N | Energy budget J | Native result | Paid traction J | Wall s |
|---|---:|---|---:|---:|
| 12 | 1500000000 | PASS t1501 | 94230641.993 | 13.769 (concurrent) |
| 24 | 3000000000 | PASS t1501 | 188461283.987 | 26.091 (concurrent) |
| 100 | 12500000000 | PASS t1501 | 785255349.945 | 107.227 (dedicated) |

All 17 sampled energy totals per stress case exactly equal budget at printed 0.001 J precision (assert tolerance 5000 J; not an every-tick conservation proof). 100 actual trains arrived, each payload preserved. At t900 -> t1100 sources unchanged at 9871603730.502 J; load 925328160.672 -> 1056915783.567 J (+131587622.895 J); battery 445519407.836 -> 379656644.575; buffer 443943351.045 -> 396172267.776; internal 28350000 -> 10396223.636. Ring cut t1100, affected load increased >100000 J before t1300 assertion; actual link parent IDs split and rejoined. Final t1500: source 9142682791.217 J, load 1539717075.270 J, battery 499980000.000 J, transit buffer 500000000.000 J, hidden 32364783.568 J, paid trains 785255349.945 J, total 12500000000.000 J (sum subject to printed rounding). Native generator reservoir remains finite. Paid train ledger is cumulative energy credited to native burners, not all mechanically consumed.

## Limits and next step

No claim 60 UPS met. Dedicated stress100 t120..240 log wall interval 9.354 s (~78 ms/tick including diagnostic overhead); t480 all stopped, so this is not continuous long-range movement or formal same-save performance benchmark. This stage improves QA throughput, not the mod's in-game speed. No runtime patch, version bump or additional 65-core regression rerun needed for unchanged runtime; previous results remain historical. Native Windows GUI, multiplayer, 100 km, junctions and actual modded generators still pending. Next EM087O: longer continuous motion checkpoint and isolated single-worker profiler/benchmark; separate individual native-read optimizations; run prior 65 + 11 mixed + 3 stress scenarios in RAM-budgeted parallel batches before promotion. Preserve all isolation, power caps, paid traction and deterministic state checks.

Sources: `tests/em087m-mixed-outposts/run_parallel.py`, `tests/em087m-mixed-outposts/em-mixed-outposts-qa_0.0.1/scenarios/stress/control.lua`, `tests/em087m-mixed-outposts/PARALLEL_QA.md`. Logs, resource time series, exact fixtures and comparison in evidence ZIP. No main/owner writes.

Evidence ZIP SHA256: `1484b771b96af12c2a5c8e890d95d76d3629cfa7ee4c0fe892cc36641aec124a`.
