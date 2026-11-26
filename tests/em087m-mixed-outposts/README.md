# EM087M mixed outposts — native QA only

Exact runtime: Factorio 2.1.24 build 87808 Linux headless, ElectrifiedMainline 0.1.98 full experimental ZIP SHA256 `9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a`. The QA mod is not a new game feature, is not a release, and must not be put in the primary owner mod directory. All placements and initial finite energy are test-fixture operations. No production script or accepted art is modified. No owner save is used.

Run the ten cases in a fresh directory:

```sh
python run_suite.py --factorio /path/to/factorio/bin/x64/factorio --full-mod /path/to/EM087L_0.1.98_full_EXPERIMENT.zip --output /tmp/em087m-qa-new
```

Optional `--checkpoint /path/to/mixed-outposts-t901.zip` additionally loads the saved broken vanilla link; six subsequent logged energy snapshots must be compared to `mixed.log`. The checkpoint is a QA save, not a playable user map. The original source is finite EEI (200 MJ), except actual native solar/radar case; the battery and transit buffer are vanilla accumulators. `scale` uses 3 finite EEI sources (600 MJ total), 12 physical 25 kV corridors, 11 distinct ordinary link networks, 31 mod substations, 24 vanilla accumulators, and 3 moving motor consists. Each line is a physically separate native electrical parent network. The fixtures use genuine wire connections. The 20 MW cap test checks all native EEI input/output flow limits and measures 80 MJ over 240 ticks. No claim about all modded generators, all possible ring topologies, long-range performance, Windows GUI or multiplayer.
