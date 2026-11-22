# EM065 — Gate plan after independent audit, 22 November 2026

**Scope:** GitHub repo `zukera2-stack/Factorio`; this is **DOCUMENTATION ONLY** from actual `main` development source `0.1.62` (baseline game commit `cf75656fda374824944311f26bbd454bc90ad45b`). No release, tag, new installer, automatic Updater or merge of 0.1.65. Do not touch original accepted sprites/owner SAVES.

## Branches and exact results

| Role | Reference | What is true |
|---|---|---|
| Accepted source `main` | `cf75656fda374824944311f26bbd454bc90ad45b` at audit start | `ElectrifiedMainline/info.json` is **0.1.62**; current locomotive **void**, EM070 and EM071 source integrated. NOT a released game |
| Owner's full game test | `experiment/em072-fullmod-player-test-063` SHA `2650d44b3caccc63189d6516b14bcd11d4800b8d` | **0.1.63** has full 25kV/HSR/stock catalog but real train draw **does not exist**, and hidden helper may orphan |
| Pole retirement | `experiment/em063-source-traction-audit-legacy-pole-20261122` SHA `eeccfcc9b15cefb808423731e506d4a112c0bbc4` | **0.1.64** hides redundant normal-looking `em-electric-pole`, preserving historical prototype IDs; native compatibility PASS |
| Paid drive prototype | `experiment/em065-source-paid-locomotive-drive-native` SHA `053fdd9d528b39db8f57eba5698aebfe9d79c506` | **0.1.65 research**; one real finite 2MW loco physically goes 24 tiles on native real source-paid buffer, SAVE/LOAD PASS. CI ZIP SHA256 `a8ef5756d4f64abefb678b769f5640f548fea007013347e7544e647ee4fa781e`. NOT RELEASE |
| Independent game audit | `audit/em065-native-multitrain-20261122` SHA `718a8011edf38a064364f7ceb9c7e2529b5a6799` | Two native 2.1.24 runs [#45042971982](https://github.com/zukera2-stack/Factorio/actions/runs/45042971982), [#45043138579](https://github.com/zukera2-stack/Factorio/actions/runs/45043138579) on the **same game ZIP** reproduced P0 native load=0 and P1 second locomotive FIFO starvation. Tests/docs-only, no gameplay code |

**Never conflate experimental version 0.1.65 (Nov22 paid locomotive) with historical EM065 (Nov21 closed-reservoir energy accounting for mod 0.1.62). They refer to different numbered experiment tracks.**

## Release-blocking acceptance matrix

| Gate | Current condition | Repro and PASS requirement |
|---|---|---|
| P0: authentic 25kV load | **FAIL** | Native mast network demand measured **0 J/tick** while real EM locos charge. [Issue #77](https://github.com/zukera2-stack/Factorio/issues/77). A true 25kV electric consumer must take source-backed J during charging/motion, with no double-counting and visible native power statistics |
| P1: 2+ trains scarcity | **FAIL** | At 1MW source, A has 933,333J and B 0 at tick60; B still 0 at tick120 but eventually charges. [Issue #78](https://github.com/zukera2-stack/Factorio/issues/78). Specify share-policy; two eligible locomotives must both get their correct share from the first minute, never exceed measured total |
| P1: true native 2MW powered movement | **PASS narrowly** | Official [#45041147885](https://github.com/zukera2-stack/Factorio/actions/runs/45041147885) one real locomotive 24 tiles, 3.2MJ transfer and true private SAVE / independent LOAD; **not** full movement matrix |
| P1: no source, AUTO negative | **PASS narrowly** | [Audit #45043138579](https://github.com/zukera2-stack/Factorio/actions/runs/45043138579) real off-catenary 0J locomotive with native AUTO station remains at 0J/0 tiles (to tick240). Still test loss of source **during movement** |
| P1: owner lifecycle | **FAIL** | [Issue #73](https://github.com/zukera2-stack/Factorio/issues/73): hidden helper remains 80 ticks after only real owner is destroyed (original 0.1.63 full source). Confirm fix with native owner UID/cleanup and true SAVE/LOAD before energizing wagons |
| P1: closed energy balance | **NOT RETESTED for 0.1.65** | Historical 0.1.62 deficit of 1,500,000J without, 1,537,742J with eight real accumulators. Recreate exact outage/removal/short/reconnect/split tests on newly changed source; no unexplained lost or created J |
| P1: +500kW per motor wagon | **NOT IMPLEMENTED** | Both motor cargo/fluid native wagons currently exist as prototypes but 0J hidden C5 GUI fixture provides no actual drive. Each wagon must add +0.5MW under source-funded Joules from actual loco only, while saving cargo/fluid and schedule |
| P1: braking regenerative return | **NOT IMPLEMENTED** | Measured finite returned J: first back to authentic powered 25kV when connected, else to locomotive-only battery; never free energy |
| P1: player GUI, native Undo, old SAVE, MP | **NOT TESTED** | Windows graphical client checks native demand, pantograph up/down, full train GUI, direct ordinary/HRS rails, robots, Blueprint/Undo, actual migration, 60 UPS, multiplayer |

## Ordered next work (separate experimental code branches; never blind merge)

1. **P0 concept and engine probe:** research native same-type `electric-energy-interface` consumption from verified mast+pan contact. Draft minimally falsifiable small experiment. Check native `flow_last_tick` of line and power supply AND full ledger on new true runtime, plus control no source/catenary, movement and SAVE/LOAD. No source-backed native consumer? Record native limitation and equivalent native-proven alternative; do not fake network metrics.
2. **P1 fair power broker:** isolate one common source budget, allocate each eligible train by agreed equal-proportional (or owner-chosen) priority; check limited 1MW with A,B each >0 from tick60; 2/4/10 trains and different starting IDs, stations/surfaces/masts; sum debit never above supply+prior buffers.
3. **P1 remove C5 orphan:** owner-key map `real_unit_number -> technical_helper_unit_number`; cleanup for mining/die/script destroy, train split/merge, reconnect/auto/saves. Preserve cargo 37 iron + fluid 9000 water when fixture uses those and native train unit_number; check HSR and Undo.
4. **P1 all-source energy:** rerun strict EM066/older closed reservoir energy ledger with 0W source and eight real accumulators, actual removal/rebuild/cycle; label historical only until reproduced. No implicit dissipated 1.5MJ without measured permitted event.
5. **P1 source-funded motor wagon 500kW:** only after orphan/energy accounting, include 1/2/4 wagon tiers, cargo/fluid, charged source and 0J control, no direct LuaTrain.speed writes or battery/25kV pantograph per motor wagon.
6. **Client/final integration:** upgrade all main primitives only after each gate has game test, independent review, owner Windows acceptance; exact GitHub Actions install artifact only, no updater/patcher or automated main merge.

## Proof hygiene for future assistants
- At project start, load `AGENTS.md`, `docs/CURRENT_WORK.md`, **the branch's own** `docs/AI_CONTEXT.md` + `docs/PROJECT_STATE.yaml`, `docs/RESEARCH_METHOD.md`, `CONTRIBUTING.md`, native-research skill and the exact source; recheck live HEAD.
- Every material code/test change **atomically** updates AI_CONTEXT and PROJECT_STATE. Keep all historical lines, do not rewrite 100KB state YAML with a new short stub.
- A GREEN CI workflow means the **harness executed**; if it logs `FAIRNESS DEFECT REPRODUCED` the feature itself **failed**. Log assertion status and proof separately.
- All reports must identify exact executable gameplay source SHA, Factorio build, installed mod stack, source ZIP SHA256 and whether a different test-only helper/probe was present.
- Audit origin: [full independent source + native analysis](https://github.com/zukera2-stack/Factorio/blob/audit/em065-native-multitrain-20261122/docs/research/em065-independent-full-audit-20261122-FINAL.md), [original user no draw complaint](https://github.com/zukera2-stack/Factorio/issues/74), [audit-only draft PR #79](https://github.com/zukera2-stack/Factorio/pull/79).
