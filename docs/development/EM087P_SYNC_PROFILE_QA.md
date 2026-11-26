# EM087P — full-sync subphase profile and native certificate read experiment

**PARTIAL / functional PASS, performance inconclusive; retain 0.1.98.** Parent `f000495098980ae15c6338fbbe2e5db948f94c49` (EM087O). Exact base full ZIP SHA256 `9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a`, Factorio 2.1.24 build87808 Linux headless. Candidate changes only `scripts/power_019.lua` (157 members, 156 byte-identical, all PNG unchanged), code-only metadata 0.1.98, SHA256 `b636c265f4794022f1a39ddc8975a2540e2c4f0f0a4245c05004ecd1a52d60e4`. Not an installable patch/version. No production files changed in Git, no main/owner writes. Last owner running 0.1.84, maintenance 0.1.86; rejected EM087M 0.1.99 not used. Research recorded before edit (see research record). No new API or permission/cache; native straight certificate checks valid HSR name, unit ID, force, surface, position/spacing, boundary and original fallback as before; reads ID once instead of repeatedly and uses already checked straight type rather than reading start.name on every rail.

## Isolated full-sync and corridor profile

EM087O exact diagnostic fixture (100 trains, nominal 761 tiles, 275 substations, 100 corridors, finite 12.5 GJ); additional instrumentation of technical_network_046.lua and corridor_keys inside existing bridge profiler. Diagnostic base and candidate differ only power_019.lua. Each generated separately (not same save); unit IDs differed, no state equality claim from separate generation. Both native test PASS tick601; all 100 trains moving at t600. All 12 normalized fixture lines match including six energy snapshots; paid at t600 1488444257.816 J, total 12500000000.000 J. Same measured ledger, not full state proof. No concurrent QA. Single diagnostic run each, measurement overhead and host variance. Initial streaming exec unsupported; ordinary child launch used, monitored to completion.

| Sync subphase at tick 600 | Base ms | Candidate ms |
|---|---:|---:|
| Resolve parents | 262.017336 | 28.729901 |
| Resolve/repair anchors | 259.834687 | 33.282078 |
| Geometric candidates and partitions | 295.142852 | 251.403689 |
| Attachment rail reads | 73.081399 | 56.192724 |
| Path selection and capture | 532.214759 | 455.575160 |
| Collect dependencies | 42.154572 | 28.250910 |
| Watch update | 187.540052 | 150.454876 |
| Native wire audit | 127.878066 | 783.674615 |
| Verify/repair | 43.071002 | 137.386353 |
| Components | 8.301590 | 20.770863 |
| Outer technical046 | 1831.987425 | 1946.686185 |

The path phase fell by 14.40% in this sample, but total full sync rose by 6.26%. The large changes in unchanged phases demonstrate timing variance; cannot attribute these to a cause (GC/native scheduling not isolated). Ordinary live corridor scan 12 samples: median 8.303117/8.238690 ms, max 36.164203/13.222591; tick600 39.817189 ms base. No scan optimization in candidate. The scan cannot be replaced by planned component labels alone: live shorts must be detected. Wall time 78.65/81.21s, max RSS 932652/911640 KiB. Full long100 arrival/outage not run.

## Native focused and mixed regression, candidate code-only

Actual exact engine tests, separate processes. Focused 5/5 (3 workers, 6.851s, cgroup peak 2221846528 bytes): prior native path oracle 8935 comparisons / 3603 fast hits; four charged short variants direct/cross/switch/cross-switch hold 333333.333333 J and restore 9833333.333333 J. Mixed 11/11 (3 workers, 21.664s, cgroup peak 2323107840 bytes): mixed/reverse/ring/train/solar/empty/battery/buffer/limit/scale/disk-load. All 124 normalized MIX/SCALE fixture lines equal EM087N reference. No guard, OOM or timeout. Total 16 targeted native cases; not a full 65-case core rerun. Current limit 4 GiB and CPU quota 4, reserve 768 MiB, planning 700 MiB per small worker. Retain both periodic audits.

## Uninstrumented same-save paired benchmark

Exact earlier EM087K `saves/100x2.zip` SHA256 `3205d56bd99ae1b360bf5862e0b99d54842ac70533fe593ff6c63931993a98d5`. 100 stationary trains, 2 motor wagons each. Earlier-version save loaded with both 0.1.98 metadata (same update path in both, not an exact freshly created 0.1.98 long-motion save). One 480-tick run per variant, includes t600, no profiling instrumentation or concurrent QA. Base 36.863 ms mean, min 13.501, max 433.656, candidate 34.898 ms mean, min 13.710, max 395.596. Mean -5.33%, max -8.78% in this pair; checksum 2975750948 equal, all 526 compared paid/contact/station/flow/helper/SNAP lines equal (no BUFFER STOP events). Not a confidence interval, not proof of 60 UPS or continuous mixed-world speedup. Both runs exit normally. Preserve uninstrumented and diagnostic logs separately.

## Decision and next

Retain exact 0.1.98. Do not advance version, install candidate, merge, or claim global performance gain. Store experiment diff as test-only research, not under production runtime. Next: create an exact 0.1.98 long100 moving save near tick 540 (verify save and t600 motion), run repeated isolated A/B/B/A around t600 with uninstrumented and diagnostic copies separately. Subdivide audit work further and consider exact per-sync geometry bucket optimization (same candidate ordering) or single-read parent/anchor metadata; no persistent permission, no reduction of 60/600 cadence. Full 65 old + 11 mixed + 3 stress + long12/24/100 regression before promoting any runtime candidate. Windows/MP, 100km, continuous long100 arrival and 60 UPS remain open. Preserve failures and exact hashes.
