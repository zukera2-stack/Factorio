# EM094A diagnostic native terminal and no-substation train exchange
Exact base archive `/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip`, SHA256 eebed6e004a13b002a2a33101d771a3b7b0ee12d3dbba2bd12e19f6cb902e1a7; Factorio headless Linux 2.1.24 build87808. Neither probe is a playable/released mod: QA-only remote mutation interface, precreated ports and finite test seed. Do not install on real saves. No production files or version changed in Git.

Use the exact diagnostic ZIPs from Library `/Factorio/Local-QA/EM094A-Terminal-Integration/` (hashes in report). Source package contains both module revisions, preparers, runner(s), exact focused QA scenario sources, generated mod-settings.dat. Preparers rebuild equivalent member contents against the exact base; ZIP timestamps can differ, so use archived exact ZIPs for the hash-pinned runners. Run from extracted source root; adjust `/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip` in preparers if necessary. Example commands (fresh output directories):

```
python suite/run_parallel.py --factorio /path/to/factorio --full-mod terminal-probe-QA-ONLY.zip --output small --workers 3 --worker-mib 700 --case terminal-multi --case terminal-isolation --case terminal-cut --case terminal-no-load
python suite/run_parallel.py --factorio /path/to/factorio --full-mod terminal-probe-QA-ONLY.zip --output large --workers 1 --worker-mib 1600 --case terminal-large100
python suite/run_integrated.py --factorio /path/to/factorio --full-mod integrated-probe-QA-ONLY.zip --output actual --workers 2 --worker-mib 700 --case train-exchange-pair --case train-exchange-multi --case train-same-terminal
python suite/run_integrated.py --factorio /path/to/factorio --full-mod integrated-probe-QA-ONLY.zip --output large_actual --workers 1 --worker-mib 1600 --case train-exchange-large100
python suite/run_parallel.py --factorio /path/to/factorio --full-mod terminal-probe-QA-ONLY.zip --output race --workers 1 --worker-mib 700 --case terminal-race
```

The `terminal-race` scenario asserts that the fault is reproduced (not that safety passes). The two probes use same native bridge port/EEI prototypes from 0.1.102; runner retains inherited case choices, only listed focused cases are delivered in this package. Native large100 train fixture uses 50 paired lines plus one isolated empty line. Actual seed 2 MJ/line, depleted before start. No factory substations. No claim final arrival, mixed wagon integration, or UPS. Original 0.1.102 unchanged. See report for blocker and next gate.
