# EM087O — longer mixed-grid motion and isolated profiler

Runtime: exact ElectrifiedMainline 0.1.98 (SHA256 `9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a`), Factorio 2.1.24 build 87808 Linux headless. Use the existing RAM-budgeted runner. Test-only; do not install diagnostic mod in owner game.

From the suite directory, run the following with absolute paths to engine, mod and fresh output directory:

```sh
python run_parallel.py --factorio /path/to/factorio/bin/x64/factorio --full-mod /path/to/EM087L_0.1.98_full_EXPERIMENT.zip --output /tmp/continuous-qa --workers 2 --worker-mib 1000 --timeout 240 --case continuous12 --case continuous24
```

`continuous` extends the EM087N shared-grid stress to nominal 761 tiles (start x=41, stop x=-720; actual arrival requires displacement >700). 12/24 trains pass full t2401 including outage, cut, rejoin and cargo. All are moving at sampled ticks 240,360,480,600; only t480 explicitly asserts every train moving. No every-tick motion proof. Long100 full functional scenario available via `--case continuous100` but not run end-to-end in EM087O. Use a dedicated process and appropriate timeout/budget.

## Diagnostic profiler only

Ensure no other Factorio process or QA is active. Prepare an isolated diagnostic copy:

```sh
python prepare_motion_profile.py --engine-root /path/to/factorio --full-mod /path/to/EM087L_0.1.98_full_EXPERIMENT.zip --suite "$PWD" --output /tmp/motion-profile
/path/to/factorio/bin/x64/factorio --config /tmp/motion-profile/config.ini --mod-directory /tmp/motion-profile/mods --threads 1 --test-scenario em-mixed-outposts-qa/continuous --test-arg 100 --test-ticks 620 > /tmp/motion-profile/stdout.log 2>&1
```

The preparer instruments only control.lua and power_bridge_058.lua inside a new ZIP; it does not alter base or runtime source. Profile samples t247,277,...577 and t600. The diagnostic fixture intentionally finishes at t601, checking all 100 trains moving at t600. It does not assert their arrival or run outage/rejoin. The profile includes measurement/log overhead; not a same-save A/B benchmark. `--threads 1` is map generation, not CPU affinity. No concurrent QA. Preserve failed logs and the original full-mod hash. The diagnostic ZIP reproduction yields identical member bytes (ZIP timestamps may differ). See report for measured results and limits.
