# EM072-C5 — read-only client GUI observer / research preflight

**Date:** 2026-11-22. **Repository:** `zukera2-stack/Factorio`. **Base:** `experiment/em072-c4-locomotive-mounted-booster` at `6e71496bb7972efc989f8b7d9398591335a43f97`. **Target:** Factorio 2.1.24 build 87808, native graphical client, Base-only. **Main mod source:** 0.1.62; still void-powered. **Status: observer SOURCE PREPARED; actual client GUI NOT TESTED.** This branch is research-only, stacked on C4, not for merge into main.

## 1–2. One observable question
Does an invisible C4 native locomotive helper appear in **vanilla train GUI** when a player opens a visible EM loco or motor wagon? The C4 headless engine already counts the helper as a genuine `LuaTrain.locomotives` entry. `selectable_in_game=false` and `not-blueprintable` do **not** establish native GUI invisibility. The scope is one exact player action and screenshots, not a guess about the GUI implementation.

## 3. Falsifiable acceptance / rejection
- Reuse the existing C4 Base-only fixture, a fresh disposable game, and an independent `em-c5-client-gui-observer` add-on; **never** modify `ElectrifiedMainline/`.
- Observe 1 EM + 2 motor wagons (C4 lane `em2`) with one helper; open the native GUI from the visible EM and each motor wagon, capture screenshot(s). Record built-in train lineup, counts, stations and schedule; compare actual screenshot to the Lua log with `native_locomotives=2` / `real_locomotives=1`.
- Negative controls: `em0`, `vanilla`, `solo`, and fully stopped `change`. Open native GUI or inspect the corresponding visible wagon; record whether helper is listed as a separate locomotive/portrait/slot. Do not mistake a log count for a screenshot.
- **UX FAIL**: an extra helper is visible in vanilla train GUI, is selectable via list, exposed as a player-facing item, or breaks displayed schedule/cargo. **UX PASS only after explicit client screenshot and open/close evidence** for the exact tested composition. Until then: `UNVERIFIED`.
- Record failures separately for hover, blueprint, deconstruction, Ctrl+Z, robot mining, rolling-stock item placement, MP, curved/diagonal/elevated rails. This GUI probe does not automatically test any of these workflows.

## 4. Analogues inspected
| Kind | Source / ref | Meaning |
|---|---|---|
| Native same-type | Base `data.raw.locomotive.locomotive` cloned in `tests/em-c4-loco-mounted-probe/data.lua`, C4 SHA above; Factorio 2.1.24 native C4 log | Helper is an actual locomotive, not a GUI overlay |
| Native events | [Factorio `on_gui_opened` API](https://lua-api.factorio.com/latest/events.html) | Supplies `player_index`, optional `entity`, `gui_type`; page may serve newer 2.1.25, **not guaranteed 2.1.24** |
| Native train | [Factorio `LuaTrain` API](https://lua-api.factorio.com/latest/classes/LuaTrain.html) | `carriages` and `locomotives.front_movers/back_movers` available; repeated in existing C4 native 2.1.24 test |
| Our code | `tests/em-c4-loco-mounted-probe/{data,control}.lua` and `tests/verify_c4.py` | `selectable_in_game=false`, no helper item, zero visible span but native helper exists |

No same-type public mod claiming **native GUI suppression of a real hidden locomotive** has been verified. Do not claim an API or runtime control to hide individual train GUI locomotive slots. No external source code copied.

## 5. Prototype/API comparison
| Property | Existing real C4 helper | GUI implication / boundary |
|---|---|---|
| Type | `locomotive` | Engine includes it in train composition |
| `selectable_in_game` | `false` | World interaction restricted; GUI representation unproven |
| `not-blueprintable`, `not-deconstructable`, `not-on-map` | Set | Not a proof of native GUI exclusion |
| Item | None | No normal player placement of helper |
| `LuaTrain.locomotives` | Counts helper in C4 real native run | Observer records native number but cannot read native GUI pixels |
| `on_gui_opened` | C5 add-on logs event/entity | Event does not describe rendered native GUI list |
| Inventory/fluid | Real `cargo-wagon`/`fluid-wagon` | Must remain unchanged in any later implementation |

## 6. Minimal experiment and rollback
**Hypothesis:** a built-in train GUI may expose the C4 helper despite world selection flags. **Falsification:** readable screenshots show no extra helper element in all named panels and an exact helper count in same-tick event logs. A GUI screenshot alone without composition log is insufficient. Experiment adds one **independent client add-on** that only listens to GUI open/close, reports train metadata, and optionally teleports the **player** on an explicit `/em-c5-case` command; it never mutates a train, cargo, schedule, energy or prototype. Rollback: disable/delete the add-on and discard disposable save. No production save migration.

## 7. Implementation record
- New `tests/em-c5-client-gui-observer/{info.json,control.lua}`, `tests/verify_c5_gui.py` and `tests/test_c5_gui_parser.py`.
- Logging schema: `EMC5|gui_open|tick=...|player=...|gui_type=...|case=...|train_id=...|native_carriages=...|real_locomotives=...|native_locomotives=...|technical_helpers=...|motor_wagons=...|native_stock=...`.
- Python parser deliberately returns **COUNTS_OBSERVED_ONLY**, never `GUI PASS` without screenshot.
- Local offline validation on 2026-11-22: `python -m unittest discover -s tests -p 'test_c5_gui_parser.py' -v` equivalent executed on exact byte-matching copies of both Python files: **2/2 PASS**; `python -m py_compile` **PASS**. Git blob SHA verify_c5_gui.py `e8bff90b538fb5b5e9f5cf36586594d2fca048d8`, test_c5_gui_parser.py `8e3db5ac46174bb417fa2807ce86eb1d3ab096d7`, both independently confirmed against GitHub.
- This is a Python parser-only check. **Lua syntax, Factorio data-stage, Factorio native client GUI, CI and gameplay NOT RUN**.

## 8–9. Experiment result and next gate
| Case | Status | Needed evidence |
|---|---|---|
| Native graphical client em2 train GUI | NOT TESTED | Screenshot showing locomotive list, logged `EMC5|gui_open` |
| Solo / vanilla / no-helper controls | NOT TESTED | Screenshots and logs |
| Blueprint/Undo/Robot mining | NOT TESTED | Distinct actual player action & final entities |
| EM070 paid energy / locomotive battery | NOT TESTED | Separate C7 native finite-J accounting |
| Other track geometry and GUI mods | NOT TESTED | Separate C6/C8 |

**Decision gate:** If the helper is visible in the native UI, escalate the UX architecture to the owner; no silent visual fake or mutation of original real wagons. Once measured, record screenshots, exact save, log, Factorio version and verdict; only then consider production integration.

## 10. Licensing
Only own C4 source and public Factorio API descriptions consulted; no third-party code/assets copied.
