# EM090 — native brake observation (no gameplay modifications)

Exact Factorio 2.1.24 build 87808 linux64. Run Base-only `run.py` with the exact engine (edit engine path for local environment, or supply FACTORIO_BIN). Isolated worker directories; new output directories required. Cases station600, station2000, station4000, heavy2000, bonus2000, coast2000, manual2000, collision2000. `fullsuite` is the prior EM089 runner plus read-only trace added to its onboard fixture. Copy the exact 0.1.101 full archive SHA256 6e2b48acea118b4542ff0be0b8101c1b844bb74e1359897af1b2653818fd8376 and preserved settings file into working area, then run:

```
python fullsuite/run_parallel.py --factorio /path/to/factorio/bin/x64/factorio --full-mod /path/to/EM089_0.1.101_full_EXPERIMENT.zip --output fullruns --workers 2 --worker-mib 1024 --case onboard-move --case onboard-outage
python analyze.py
```

Base-only test runner logs and full runner logs must exist under `runs` and `fullruns` respectively for analyze.py. Do not install QA mod into owner game. `Test passed` means observation fixture completed, NOT that regenerative work was proved. The production mod is unchanged. No writes to train.speed, no recouped J. Initial fuel is deliberately finite test setup; coast removes and accounts remaining fuel at t120. Manual switch is scripted test action, not human GUI acceptance. Collision uses real tank damage. Signal braking and mixed diesel/multiplayer/split during braking not tested.
