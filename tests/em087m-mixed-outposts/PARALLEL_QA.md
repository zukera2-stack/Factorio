# EM087N — memory-budgeted native parallel QA

Test-only extension of EM087M; exact ElectrifiedMainline 0.1.98 (SHA256 `9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a`), Factorio 2.1.24 build 87808 linux64. Do not install the QA mod in the owner game. No production changes.

## Run

On Linux cgroup v2 with finite `memory.max` and `/usr/bin/time`, from this directory (engine and mod ZIP must be accessible; ZIP and output are on the same filesystem for read-only hardlinks):

```sh
python run_parallel.py --factorio /path/to/factorio/bin/x64/factorio --full-mod /path/to/EM087L_0.1.98_full_EXPERIMENT.zip --output /tmp/qa-parallel --workers 3 --worker-mib 700
```

The default suite includes `disk-load` and requires the exact EM087M `mixed-outposts-t901.zip` from the Library QA archive alongside this runner. `--case mixed --case scale` selects cases explicitly. Each case receives separate config, write-data, mod-list, QA mod copy, log and result directory; engine/data shared read-only, exact game ZIP hardlinked read-only by convention (the runner does not write it). `--threads 1` is the native map-generation thread option, not a global CPU limit. Worker count = min(requested, integer CPU quota, floor((memory.max - initial memory.current - reserve)/worker budget)). Defaults: 2 workers, 1024 MiB budget/worker, 768 MiB reserved, 240 s timeout/case. Small-suite calibration measured ~471 MiB max RSS per process; 700 MiB is an empirical planning allowance, not a hard per-process limit. Cgroup memory is sampled every 150 ms; above the protected threshold the runner kills active process groups and refuses remaining work. Sampling cannot guarantee against a sudden OOM; no swap assumptions; do not run a timing benchmark alongside QA workers. Report `parallel.json` includes measured peaks, cgroup memory events, per-case wall/RSS and samples. Results of the single-versus-parallel comparison describe QA throughput only, not game UPS or CPU scaling inside one map.

## Shared-world stress

```sh
python run_parallel.py --factorio /path/to/factorio/bin/x64/factorio --full-mod /path/to/EM087L_0.1.98_full_EXPERIMENT.zip --output /tmp/stress-new --workers 1 --worker-mib 1700 --timeout 360 --case stress100
```

`stress12`, `stress24`, `stress100` (multiples of four up to 100). A native vanilla common generation backbone connects four-corridor ring branches. Each corridor has one actual electric locomotive, one motor cargo wagon, one motor fluid wagon and the mod's actual helper; each branch has one finite generator (20 MW/500 MJ), one load (2 MW, half raised to 4 MW), one separate battery bank and one transit-buffer bank (four vanilla accumulators per bank). No native train speed writes, no arbitrary energy credit after init. 11 stations and 4 independent vanilla ring-link networks per branch; the shared backbone is another native vanilla parent. The fixture asserts all corridor/vanilla parents distinct, common source parent, every arrival and payload, sampled conservation, backup supply during outage, ring bypass during cut, and link rejoin. All source outputs off at tick 900, restored tick 1100, one transit link cut then rejoined tick 1300. Destination at x=-120, origin x=41; each train must move more than 100 tiles. Exact native movement, not an abstract graph. Current scenario is finite trip then station wait, not continuous long-range movement or 60 UPS proof. Real solar/radar covered separately in prior mixed tests.
