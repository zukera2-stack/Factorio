# ElectrifiedMainline 0.1.10 — in-game topology tests

Target: Factorio 2.1.20. Install ONLY ElectrifiedMainline_0.1.10.zip; preserve a backup of the 0.1.9 save. Source checks do not prove gameplay.

| ID | Test | Expected | Status |
|---|---|---|---|
| C01 | Open old 0.1.9 save with five supports and one substation | Old diagonal spiderweb disappears; one blue feeder | not_tested |
| C02 | Run /em-35kv-status on a five-support straight rail line | 4 contact spans, 1 feeder (if all supports <16 tiles apart), transfer_MW=0 | not_tested |
| C03 | Add supports on same straight track | Only nearest forward/back spans, not all-to-all | not_tested |
| C04 | Add two substations near the track | One feeder per substation; no direct substation-to-substation line | not_tested |
| C05 | Remove middle support, Ctrl+Z/Ctrl+Y | No stale lines; gap remains if >16 tiles | not_tested |
| C06 | Remove all EM rail within 3 tiles of a support | Next tick support becomes ineligible | not_tested |
| C07 | Rebuild rail near support | Graph reconnects after next tick | not_tested |
| C08 | Parallel tracks and crossings | No unintended cross-track spans; report failures | not_tested |
| C09 | Curved-A/B and half-diagonal rail | Check visual placement; some valid spans may be omitted | not_tested |
| C10 | Attempt vanilla copper wire connection to 35 kV support | Must not connect | not_tested |
| C11 | Blueprint/robots/Undo/Redo supports | No duplicated render objects | not_tested |
| C12 | Native rail Upgrade Planner and Ctrl+Shift superforce blueprint Undo/Redo | No regression from verified 0.1.8 | not_tested |
| C13 | Save and reload, inspect status | Same spans, no Lua error | not_tested |

Do not claim actual electricity transfer, native signal-like snapping, exact curved track geometry or UPS scalability from these tests.
