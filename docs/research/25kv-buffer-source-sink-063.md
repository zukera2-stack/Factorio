# 0.1.62: native two-substation energy buffers and accumulator reserve (EM063)

**Date:** 2026-11-21  
**Status:** 4/4 native scenarios PASS; test-only change, no gameplay code changes and no 0.1.63 promotion.  
**Engine:** official Factorio Headless 2.1.24 build 87808, linux64 x86-64.  
**Source mod:** `experiment/network-fair-share-opt-062`, actual byte-matched CI ZIP `ElectrifiedMainline_0.1.62.zip`, SHA256 `18bfdd184f901aefa5c7cbf8e266359aa9ebd7a9e4036361b8ea1abda1629040`; no changes to frozen 83 PNG files or game ZIP.  
**Raw evidence:** `tests/run_native_buffer_063.py`, `tests/em063-buffer-probe.lua`, and `docs/research/25kv-buffer-source-sink-063.json`.

## Exact native setup

Two traction substations A and B at (-20, 9), (20, 9) with 3 contact poles and 24 native straight rail sections. Separate ordinary networks at A and B share one 25 kV contact corridor; network IDs are verified distinct. A native editor `electric-energy-interface` in A operates as `primary_output` with 20 MW max. A separate EEI in B is `secondary_input` with 10 MW max, and acts as an energy meter. The source `power_production` and `output_flow_limit` are both set to zero at **dt=540**; the second change is essential to prevent its own energy-storage property from masquerading as ongoing generation. We explicitly measure engine energy of each accumulator and all bridge EEI input/output buffers on the hidden lab surface.

Four independent disposable maps use only ordinary vanilla accumulators, four at source, four at receiver, both, or none. All accumulators start at zero. Each simulation is **1540 game ticks**, 6160 total. Checkpoints dt=540 and dt=1020 compare physical energy changes; dt=1200 and dt=1480 assert flat sink storage after depletion. Production code is never edited or monkey-patched.

## Measured native results

| Configuration | Batteries A | Batteries B | Battery energy released by A after cutoff | Battery energy released by B after cutoff | Additional energy stored by consumer B (dt540→1020) | Native result |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Both sides | 4 | 4 | 9.600 MJ | 9.560 MJ | **19.493 MJ** | PASS |
| Source A only | 4 | 0 | 9.600 MJ | 0 | **9.893 MJ** | PASS |
| Receiver B only | 0 | 4 | 0 | 9.560 MJ | **9.747 MJ** | PASS |
| Hidden bridge buffers only | 0 | 0 | 0 | 0 | **0.167 MJ** | PASS |

- In the **both sides** case at dt=540, battery group A held 10.800 MJ, group B 10.720 MJ and the 10 MW consumer had already received 89.333 MJ. At dt=1020, battery groups held 1.200 MJ and 1.160 MJ; consumer held 108.827 MJ. Battery discharge 19.160 MJ versus consumer gain 19.493 MJ, with the difference accounted for in the conservative 1 MJ tolerance allowing transitional native bridge buffers. This tolerance bounds **rather than independently proves** exact per-tick energy accounting.
- The source-only case demonstrates that stored energy at the *generating substation* can cross the isolated 25 kV line after its generator is turned off. The receiver-only case demonstrates local backup with the bridge inactive after generator loss. Together the groups deliver both supplies as expected.
- Hidden EEI relay at dt=540 contained ~0.333 MJ (bridge-only) or ~0.373 MJ (both sides) on its output side, and the ordinary substation itself is an `electric-pole` with **no native electrical storage**. A bridge-only outage delivered just 0.167 MJ after cutoff; by dt=600 the hidden interfaces were gone. Therefore the relay buffer is a **roughly one-tick transient**, not a persistent 20 MJ station battery.
- All four maps reached 0 J in both battery groups at dt=1200 and received exactly **0 additional J** between dt=1200 and dt=1480. No phantom sustained power was observed in this scope.

## Findings and engineering decision

**Use native factory-grid accumulator energy storage for genuine backup**, leaving the 333334 J bridge EEI buffer to smooth one-tick energy handover. This already works with the unchanged optimized 0.1.62 in both source and receiving station arrangements. It is unsafe to advertise the electric-pole substation itself as containing a battery; it has no battery prototype or capacity.

If a **dedicated persistent per-station buffer** is desired, implement and test it as a new native accumulator prototype, independent of the bridge's transient EEIs. Such a change requires fixed input/output power and capacity, preservation on migration/rebuild/rotation/undo, no duplication on recreation, power-priority testing and native Bob's compatibility. This research **does not** introduce or approve that mechanic. The user-facing Updater remains on approved 0.1.61; stable `main` remains 0.1.56.

## Reproduce without GitHub Actions

```bash
python3 tests/run_native_buffer_063.py \
  --engine /path/to/factorio/bin/x64/factorio \
  --game-zip /path/to/ElectrifiedMainline_0.1.62.zip \
  --output build/native-buffer-063
```

Requires the user's privately provided engine binary, which must not be committed to GitHub. The launcher validates exact Factorio engine build, ZIP SHA256, game version, runs four temporary mod scenarios and creates `buffer-report.json` plus full per-case logs. It never modifies user savegames or installs mods into the user's directory.