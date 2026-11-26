# Resource-budgeted parallel Factorio QA

**Status: proven workflow, documented 2026-11-26 at owner request.** Evidence: [EM087N](EM087N_PARALLEL_QA.md), commit `cc558e2c4c7a5f02fe51ab8f9c4bc827783ecac2`. Applies to independent native headless functional QA, not a single game's internal simulation. No runtime, version, owner installation or main changes.

## Required preparation

1. Recover exact tested engine and full mod archive, verify SHA256. Read [runner runbook](../../tests/em087m-mixed-outposts/PARALLEL_QA.md).
2. Inspect effective cgroup memory.max, memory.current, cpu.max, available disk and swap. On other platforms determine equivalent limits; if uncertain, start with one process. Do not infer allocation from host totals. Calibrate one worker on representative fixture, then two if safe.
3. Use admission formula: min(requested workers, integer CPU quota, floor((memory limit - current use - reserve)/estimated worker memory)). If no worker fits, do not start a new process. Recheck budget for each batch and after larger fixtures. The tested 768 MiB reserve and 700 MiB small-worker estimate are planning values, not universal limits.
4. Each worker gets separate write-data, config, mod-list, QA mod, save and log directories. Share engine and exact game archive only as immutable inputs. Never use owner installation or share writable saves. Preserve exact native assertions and logs.

## Calibrated defaults

| Workload | Workers in tested environment | Qualification |
|---|---:|---|
| Small functional regression | 3 | 700 MiB planning allowance; 4 GiB RAM, 4 CPU quota |
| Medium stress12/stress24 | 2 | measured pair completed |
| Large stress100 | 1 | dedicated process, 1700 MiB admission allowance in runbook |
| UPS, profiler, A/B timing | 1 | no concurrent QA, same save/conditions |

Actual worker count is bounded by current resource availability. Do not treat `--threads 1` as global CPU affinity; it controls map generation. Runner uses Linux cgroup v2 and /usr/bin/time, not a verified Windows scheduler. Source and output need same filesystem for hardlinked mod archive.

## Execution and evidence

Use `tests/em087m-mixed-outposts/run_parallel.py`; command and required disk-load save are in the runbook. Extend other fixtures explicitly before using them with this runner; 65 older scenarios have not yet been rerun through this scheduler. Preserve per-case engine PASS/failure, timeout, logs, resource samples, peak RSS/cgroup use, OOM counters and wall time. The 150 ms guard kills active process groups and refuses remaining work when the protected threshold is crossed; it did not trigger in EM087N and cannot guarantee prevention of sudden OOM. Do not count refused/interrupted cases as PASS. If pressure occurs, reduce workers and rerun only affected cases with recorded provenance.

## Verified results

Exact Factorio 2.1.24 build 87808 Linux headless and full experimental mod 0.1.98. The same 11 scenarios passed both ways: serial 44.302 s, three workers 20.339 s, 124 normalized fixture log lines equal, peak cgroup 1633517568 / 2393780224 bytes, no OOM. One comparison, 2.18x batch throughput, not a general performance guarantee. Dedicated 100-train connected stress also passed, but not a 60 UPS or continuous-motion result.

Keep benchmarks isolated, do not weaken safety/energy assertions to gain throughput, and update AI_CONTEXT and PROJECT_STATE after material results. Future development should use resource-budgeted parallel functional QA when safe, while retaining sequential fallback.
