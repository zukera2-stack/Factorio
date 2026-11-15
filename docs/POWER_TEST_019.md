# 0.1.9 visual infrastructure test worksheet

Factorio 2.1.20, user test after successful CI. No scenarios have passed in game yet.

| ID | Test | Expected | Status |
|---|---|---|---|
| T01 | Load 0.1.9 base-only + existing save | No prototype/runtime error | not_tested |
| T02 | Two 35 kV supports beside EM rails, <16 tiles apart | Pair of rendered nonconducting lines | not_tested |
| T03 | Copper cable from normal pole to contact support | No vanilla copper connection | not_tested |
| T04 | Substation beside contact support and regular poles | Ordinary side connects; 35 kV line only visual | not_tested |
| T05 | Mine middle support, Ctrl+Z/Ctrl+Y | Render spans removed/recreated correctly | not_tested |
| T06 | Support >3 tiles away from all custom rails | Warning and no catenary span from this pole | not_tested |
| T07 | /em-35kv-status | Nodes/spans, energized=NO, transfer_MW=0 | not_tested |
| T08 | 0.1.8 native rail planner straight/curved-A/B Undo/Redo | No regression | not_tested |
| T09 | Ctrl+Shift superforced mixed rails blueprint Undo/Redo | No regression | not_tested |

Out of scope: real MW transfer, exact signal placement, physically wired rail coverage and train electricity.