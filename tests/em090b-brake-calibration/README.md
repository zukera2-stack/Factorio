# EM090B — native brake calibration and diagnostic estimator

Exact runtime is unchanged EM089 0.1.101, SHA256 `6e2b48acea118b4542ff0be0b8101c1b844bb74e1359897af1b2653818fd8376`. Factorio 2.1.24 build87808 linux64. Test-only. `estimator.lua` is copied into both QA mods, not ElectrifiedMainline. No speed writes or recovered-J credit. Experimental C=450, eta=.65, locomotive regenerative power assumption 2MW; no final balance approval.

## Reproduction

Use a new writable directory and exact engine (`FACTORIO_BIN`), verify limits, see project PARALLEL_QA_STANDARD. No owner save or game directory. Source ZIP includes original matrix fixture, final fixtures, settings file, runner and analyzer. GitHub text-only tree omits the binary settings file: recover it from source ZIP or generate with `tests/em089-onboard-storage/prepare_onboard_settings.py` from exact engine-produced default 0.1.101 file. Expected settings SHA256 `c2e23ccbdfb873c1ae7541c2ede63e489e05c003ec2005d64fc7dff78b46b7da`.

1. Copy `run.py` and `qa-matrix-original/` to a separate directory, renaming the latter `qa/`. Run `FACTORIO_BIN=/absolute/path/factorio python run.py coast locoonly wagononly both bothbonus autolocoonly autowagononly autoboth`. Preserve resulting `runs/` under `matrix-runs/` in analysis directory.
2. In source root with final `qa/`, run `FACTORIO_BIN=/absolute/path/factorio python run.py coast locoonly wagononly both bothbonus autolocoonly autowagononly autoboth cycle autocollision starve passive`.
3. Run `python fullsuite/run_parallel.py --factorio /absolute/path/factorio --full-mod /absolute/path/EM089_0.1.101_full_EXPERIMENT.zip --output fullruns --workers 2 --worker-mib 1024 --case onboard-move --case onboard-outage --case onboard-empty`.
4. Copy `holdout/` from evidence ZIP (original EM090 logs) to analysis directory, then `python analyze.py`. Analyzer asserts equal native trajectories after exchanging brake forces, coast and manual law residual, calibration sample bounds and hypothetical cap/negative controls. A different engine or configuration requires a fresh calibration. `source_verified` is a fixture-specific assumption, not a production permission.

## Scope

Manual *native manual_control_stop* and automatic *arrive_station* only; not active player control or arbitrary signals. The estimator starts from a verified zero-speed sample, rejects unknown composition, direction, time gaps, changing parameters, source debits, anomalous deceleration and observed damage. On auto brake, subtract predicted coast loss conservatively and cap nominal brake work; reject station terminal adjustment. Zero-speed sample earns no credit. Hidden helper brake contributes to denominator only. Actual reception, damage coverage, exact burner-debit attribution, live split/load and repeated energy reuse remain EM091 gates. Do not copy this diagnostic module directly into gameplay or change the current installed version.
