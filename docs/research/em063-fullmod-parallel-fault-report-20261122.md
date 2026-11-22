# EM063 complete parallel native fault report — 22 November 2026

**Original unchanged full mod:** `ElectrifiedMainline_0.1.63.zip`, SHA256 `2b150cdc506dafdde8fd10358e8f4e31d62c3215469db2027ba2a56b4d47c2b6`. **Official engine:** Factorio 2.1.24 build 87808 Linux headless. **Two simultaneous independent jobs**, each with an isolated server, exact full mod ZIP, real server SAVE and new-process LOAD. **Main and user's ZIP unchanged.**

**Final run:** [#45036921306](https://github.com/zukera2-stack/Factorio/actions/runs/45036921306) — workflow overall **FAIL by design** because the rail-stock lane detected a persistent defect. Electrical lane **PASS**. No false blanket success.

## Rail, full real mod inventory and rolling stock — FAIL (one confirmed issue)
[Download rail proof log](https://github.com/zukera2-stack/Factorio/actions/runs/45036921306/artifacts/14759877457). Real checkpoint **1,143,041 bytes**, SHA256 `e2d1775b52d1c692109856a851c5edba4ec7ba4cb44a7c5eddcead95bf4fdcdd`.

The actual native Factorio registry was enumerated from *all* `em-` prototypes (including hidden internal entities): **15 items, 21 entity prototypes, 29 recipes including recycler-generated variants, 4 technologies**. A tiny handcoded shortlist is not being presented as the entire registry.

| Gate | Verdict | Exactly observed |
| --- | --- | --- |
| R1 inventory/prototype coverage | PASS | All `em-` prototype names logged; 15/21/29/4, required real 14 items exist |
| R2 all HSR geometry creation | PASS | 29 real straight HSR + actual curved-A, curved-B and half-diagonal rail entities constructed; NOT a moving-train curve test |
| R3 real cargo/fluid | PASS | Native motor cargo **37 iron** and motor fluid **9000 water** persisted through stopped native disconnect, reattach, real SAVE/LOAD |
| R4 native helper | PASS | One physical hidden locomotive, 4 native carriages, 2 native locomotives, **0J helper energy** |
| R5 helper replace | PASS | Remove + recreate at full stop tick126; real motor wagon unit identities/contents unchanged |
| R7 independent SAVE/LOAD | PASS | Genuine headless-server save, separate-process official `--test-save` loaded checkpoint |
| R8 catenary destruction/rebuild | PASS | Eight real alternating north/south poles built tick25, four destroyed tick55, four rebuilt tick75, all eight valid tick90 **and tick140 after independent reload** |
| **R6 owner destroy cleanup** | **FAIL** | At **tick160** real EM owner was destroyed with native `raise_destroy`. Hidden helper was still `valid=true` at **tick170** and **tick240 (80 ticks later)**. This is persistent, beyond two 30-tick update intervals. |

The PASS on item/geometry/building must not conceal R6. Precise failure: `[EM063 FAULT R FAIL] PERSISTENT_ORPHAN_HIDDEN_LOCOMOTIVE`. Tracked in [Issue #73](https://github.com/zukera2-stack/Factorio/issues/73). It concerns the **experimental 0.1.63 test-only helper**, not a released feature of the 0.1.62 main.

## Electricity / loss / recovery — PASS for tested transitions
[Download electrical proof log](https://github.com/zukera2-stack/Factorio/actions/runs/45036921306/artifacts/14758984753). Real checkpoint **1,001,759 bytes**, SHA256 `1a7a0aa494d9da3cd8cd0b3daceafc35c3028f69a049a71164c37ebd48ca2e17`.

| Gate | Verdict | Measured on real 2.1.24 native engine |
| --- | --- | --- |
| E1–E2 native setup/allocation | PASS | 44 HSR, five 25kV poles, three traction substations; both isolated factory sinks received ~**39 MJ** each by tick240 (20MW budget) |
| E3 isolate one consumer | PASS | Stop B input tick240; C reaches **118.333 MJ** tick480, fair reassignment |
| E4 disk SAVE/LOAD | PASS | Real server SAVE tick500; independent Factorio process loaded exact checkpoint |
| E5 demolish source | PASS | Source substation destroyed tick600, sink C rises **158.333 → 159.167 MJ** at tick750 (finite buffer transient ~0.833 MJ) |
| E6 rebuild source | PASS | Source substation rebuilt tick750; sink C rises to **217.833 MJ** by tick930 (~58.667 MJ delivered) |
| E7 disconnect 25kV line | PASS | Two intermediate masts destroyed tick930; sink C rises only **~0.333 MJ** transient by tick1100 (to 218.167 MJ) |
| E8 generator off | PASS | Native source set to 0W tick1100; sink C stays **218.167 MJ** by tick1210, no further production |
| E9 long endurance | PARTIAL | One actual demolition/rebuild plus split, no 100x cycles, long-run UPS or MP test |

**Proof limitations:** this is real native EM070 bridge and isolated factory networks, **not** powered locomotive: `em-electric-locomotive` remains `void` sourced, and no integrated +500kW paid motor-wagon traction or braking regeneration exists.

## Additional flag from full catalog (NOT A PROVEN BUG)
With Space Age/Quality active, native prototype catalog includes `em-c5-test-internal-joule-063-recycling`, an engine-generated recipe associated with hidden test fuel. The probe only confirmed its **registration**; it did **not** demonstrate that a player can access or exploit it. Audit accessibility and deletion as part of production cleanup, do not claim an exploit yet.

## Tests that a headless script does NOT certify
Actual Windows train GUI list and phantom visibility; user `/em-test-scene` command; native green Upgrade Planner **with robots and real Undo/Redo**; blueprint superforced/revival, all moving train curvature/elevated rails, save migrations across versions, multiplayer, graphics, sustained UPS or broad modpack interference. These are future independent gates, not implied PASS from current engine results.

## Next decision / release gate
**Do not merge/release.** Any adoption of C4/C5 helper into production requires explicit owner-governed physical helper ownership/removal, J-accounting, and re-running this exact negative failure test from a new isolated branch. Preserve user's full `0.1.63` test ZIP unchanged. Reuse these tests on every new candidate and require **both** lanes to pass before progressing to human GUI and Undo.
