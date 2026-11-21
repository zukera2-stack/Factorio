# EM063: exact GitHub-package native verification

**Date:** 2026-11-21. **Repo:** `zukera2-stack/Factorio`, experimental `experiment/buffer-flush-063` commit `04ab5f719b3a7ac09a8066e58614471565b70729`. **Game:** official Factorio Headless 2.1.24 build 87808, Linux x86-64.

**GitHub Actions build:** SUCCESS [run 44892720155](https://github.com/zukera2-stack/Factorio/actions/runs/44892720155), artifact `14702513298`. Downloaded the artifact, extracted and tested **the exact CI game mod** `ElectrifiedMainline_0.1.62.zip` SHA256 `a869c7fb5b76aa49ae38f50af8f1c74b9e8dcd9254e4e354b127e3698d966a07`.

The previously native-tested local ZIP has SHA256 `a0bd3030e6ccda2f2227e76ce4311afc2f3d9792fbb10d9e65ba796c1f1b0f2b`. ZIP bitstreams do **not** match due to compressed sizes/metadata, but every **one of 130 unpacked game file contents is byte-identical**, including the 83 PNGs and the actual Lua bridge code. Rather than assume equivalent ZIP files, we repeated **all 11 native scenarios** on the exact official CI ZIP.

## Native game tests directly on the CI artifact

| Scenario | Game ticks | Result |
|---|---:|---|
| 2 substations, 4 vanilla accumulators each (A source + B receiver) | 1540 | PASS: 19,493,333 J delivered after generator cutoff |
| 2 substations, 4 accumulators only at source | 1540 | PASS: 9,893,333 J |
| 2 substations, 4 accumulators only at receiver | 1540 | PASS: 9,885,591 J |
| 2 substations, no batteries; only hidden relay buffer | 1540 | PASS: 333,333 J (before fix 166,667 J) |
| Inherited 20 MW rail power bridge and accumulator reverse | 1050 | PASS |
| Native EEI priority matrix | 300 | PASS |
| Three-grid equal-share fairness | 680 | PASS |
| 32-station line with 1 source, 31 consumers | 1050 | PASS |
| 32-station line with 4 sources, 28 consumers | 1050 | PASS on separate retry |
| Factory brownout priority, 20 MW to 8 MW | 950 | PASS |
| 48-station line with 6 sources, 42 consumers, reroute and outage | 960 | PASS |
| **Total** | **12,200** | **11/11 PASS** |

The 32-station, four-source test exceeded the long aggregate batch timeout on its first attempt (cause not established); direct isolated native rerun exited successfully (1050 updates in 6784.138 ms; min tick 1.273 ms), and emitted `[EM062 MULTI PASS]`. This should not be concealed or misinterpreted as an engine failure. 48-station test min tick 1.954 ms on this run; this is NOT a guarantee of 60 UPS on arbitrary saves.

## Interpretation and boundaries

The visible substation is an **electric pole, not a built-in accumulator**. Energy buffering comes from actual connected accumulator entities and the hidden *transient* electric-energy-interface (EEI) relay. Before the buffer-flush fix, the relay port was destroyed with energy remaining; now it stays until the real Factorio electric solver discharges the remaining stored joules, then is removed. The code explicitly protects local factory power priorities in the tested low-generation condition.

This exact run **does not** prove native Bob's Power accumulator integration, multiplayer, saves migrating from other versions, Undo teardown edge cases, or complete global power-flow fairness. Version remains 0.1.62 for comparison. **PR #38 is draft; no merge into stable `main` 0.1.56 and no update to `test/updater-approved` 0.1.61.** A uniquely bumped mod version and explicit user permission would be needed before promotion.

## Reproduce

Exact game ZIP artifact checksum above. Source test harnesses are `tests/run_native_buffer_063.py` and `tests/em063-buffer-probe.lua`, plus the seven native probes from the optimized 062 test suite and stress tests. Engine is user-provided official Factorio 2.1.24 headless; binaries are never placed in public GitHub. Full machine-readable report: `CI_EXACT_BUFFER_063_REPORT.json`.
