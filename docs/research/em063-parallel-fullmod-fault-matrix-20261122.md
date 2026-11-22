# EM063-FM — parallel full-mod fault and recovery test plan (22 Nov 2026)

**Status before code:** RESEARCH PREFLIGHT ONLY. **Source full mod:** `experiment/em072-fullmod-player-test-063` @ `2650d44b3caccc63189d6516b14bcd11d4800b8d`, **ElectrifiedMainline 0.1.63**, original inner CI ZIP SHA256 `2b150cdc506dafdde8fd10358e8f4e31d62c3215469db2027ba2a56b4d47c2b6`, full 134 files/83 PNG. **Target engine:** official Factorio **2.1.24 build 87808** Linux headless. **Owner goal:** run two simultaneous independent real-engine destructive/negative test lanes while owner tests the graphical client. **Scope:** TEST CODE AND DOCUMENTS ONLY; no `ElectrifiedMainline/` changes, no user save, no main merge/release, no new install ZIP.

## 1–2. Test method / exact failure model
Use the **same complete original full mod ZIP byte-for-byte**, plus one of two **separate** disposable test-only probes (not part of game ZIP). Run two different GitHub Actions jobs in **parallel**; each gets its own fresh engine, mods directory and disposable save, then performs a real disk checkpoint with `game.server_save` and a subsequent independent-process resume. A native Factorio data/load/test failure marks its lane **FAIL**, not a mock PASS. Distinguish engine-native operations from player-only clicks, Undo and GUI.

## 3. Failure matrix with falsifiable gates
| ID | Lane | Real-game operation | Expected / rejection | Coverage boundary |
|---|---|---|---|---|
| R1 | Rail & stock | Look up every actual EM HSR, mast, substation, EM loco, cargo/fluid item/recipe, helper | All entities/items present; no hidden helper item; missing item FAIL | Not actual GUI inventory |
| R2 | Rail & stock | Build 29 custom straight HSR, native locomotive, motor cargo and fluid | 3 authentic visible entities, 14-tile span | Not curve geometry |
| R3 | Rail & stock | Fill real cargo with 37 iron plates, fluidbox with 9000 water | Exact quantities survive stopped native attach/detach; unit_numbers unchanged | Not industrial loading machines |
| R4 | Rail & stock | Insert 1MW hidden loco while stopped | Exactly 4 native carriages, two native locos, hidden 0J | Does not prove UI hiding or +500kW paid traction |
| R5 | Rail & stock | Remove helper and reattach/replace at full stop | Correct remaining native stock and inventories; no loss | No on-the-fly moving train surgery |
| R6 | Rail & stock | Destroy real owner locomotive after mount | Check no orphan hidden helper/stray native rolling-stock remains; if orphan then **FAIL** and record actual flaw | The 0.1.63 test-only helper lifecycle may not have cleanup — likely candidate |
| R7 | Rail & stock | True SAVE checkpoint & separate-process LOAD | World, entities, storage, cargo/fluid amounts persist, no duplicated helpers | Not graphical Windows saves |
| E1 | Energy & failures | Build real custom HSR/5 poles/3 substations | Native separate factory networks, one technical corridor | Different from normal copper-grid |
| E2 | Energy & failures | Supply one real 20MW factory source, two consumers | Both receive, fair allocation, bounded sum | Existing EM062 already covers baseline |
| E3 | Energy & failures | Disconnect consumer B while C stays | Remaining C receives redirected power; no phantom J | Same exact 2.1.24 engine |
| E4 | Energy & failures | SAVE and separately LOAD source/sink/native state | Buffer and network roles persist without multiple station duplicates | Must use real checkpoint |
| E5 | Energy & failures | Destroy source substation with `raise_destroy=true` | No new consumer energy after finite transient reservoirs, no free generation | Existing orphan buffers can be a known energy defect; record instead of dismiss |
| E6 | Energy & failures | Rebuild source substation and restore supply | Consumers resume, still isolated native factory networks | Needs post-rebuild settling |
| E7 | Energy & failures | Break contact corridor / remove masts | Source remains isolated; disconnected sink must stop receiving sustained energy | Graph reconnection may be conditional and must be measured |
| E8 | Energy & failures | Stop generator completely | No independent energy creation after local buffering; bounded final ledger | Loco's real energy consumption is NOT implemented |
| E9 | Energy & failures | Repeated deletion / rebuild and final cleanup | No infinite loops, Lua errors, leaked native bridge ports or unbounded Joule gifts | Native game simulation, not GUI |

**Known unimplemented features, not mislabeled as passing:** real EM locomotive still `energy_source={type="void"}`; motor cargo/fluid traction via EM070 Joules and regen not implemented; Phantom native locomotive potentially appears in vanilla train GUI. These MUST remain explicit **BLOCKED/NOT TESTED**, not reinterpreted as native test success.

## 4. Same-type precedents inspected
- Actual game-proven **same full mod** `tests/em063-native-fullmod-probe/control.lua`, `experiment/em072-fullmod-player-test-063` @ `2650d44b3caccc63189d6516b14bcd11d4800b8d`; CI native [45034430942](https://github.com/zukera2-stack/Factorio/actions/runs/45034430942) PASS (29 real HSR, real loco/wagons, real catenary/substation, zero-J helper).
- Actual engine proven 20MW full-mod **`tests/em062-power-probe/control.lua`** (native source/battery/reverse) and `tests/em062-fairness-probe/control.lua` (3 factory nets, allocation reflow), source at `2650d44b3caccc63189d6516b14bcd11d4800b8d`; [run 45034991114](https://github.com/zukera2-stack/Factorio/actions/runs/45034991114) PASS, all **3/3** tests / 2030 ticks. New lane E is fault-injection beyond baseline.
- Actual C4 laboratory (not production) used `game.server_save("em-c4-probe-checkpoint")` at tick125 and separate process LOAD; `tests/em-c4-loco-mounted-probe/control.lua`, ref `experiment/em072-c4-locomotive-mounted-booster` @ `6e71496bb7972efc989f8b7d9398591335a43f97`. Outcome does not prove full-mod coupled train GUI or energy debit.
- Factorio 2.1 game API being tested natively: `LuaSurface.create_entity`, `LuaTrain.carriages/locomotives`, `LuaEntity.disconnect_rolling_stock`, `LuaEntity.get_inventory`, `LuaEntity.fluidbox`, `LuaGameScript.server_save`, `LuaEntity.electric_network_id`, `LuaEntity.energy`, `LuaEntity.destroy{raise_destroy=true}`. [API](https://lua-api.factorio.com/latest/) may be 2.1.25, exact 2.1.24 verified only by runs.

No new runtime patch or third-party code copied; in-repo test modifications are all isolated to `tests/`, `.github/workflows/` and `docs/`.

## 5. Safety / design
The two jobs **never share the same save directory** or engine state. Build one deterministic `ElectrifiedMainline_0.1.63.zip` from unchanged original source for each runner and assert its SHA256 is exactly the existing delivered `2b150cd...` before launching tests. The two disposable probe mods add no user-facing items. Each lane may **fail independently**; log remains downloadable because artifact step is `if: always()`. Do not weaken assertions to hide defects. Test scripts must never edit existing player saves; new map only.

## 6. Experiment steps / rollback
(1) independent ephemeral fresh map, exact full ZIP; (2) native setup and baseline verified; (3) mutate one dimension (remove helper, cut demand, demolish substation); (4) log before/after counts, Joules, owners, entity/unit identity; (5) save to engine-owned disk using `game.server_save` and resume from that exact checkpoint in a **different Factorio process**; (6) final pass only if all enforced checks pass. On fault, assert so CI marks FAIL; retain logs/artifact and refine test only if measurement is invalid. Rollback: delete this branch/test-only probes; owner's `ElectrifiedMainline_0.1.63.zip` remains SHA-identical.

## 7. Implementation — parallel native CI ready
- Two independent probe mods under `tests/em063-fault-rail-stock/` and `tests/em063-fault-electrical/` (no `ElectrifiedMainline/` changes).
- Dedicated [parallel workflow](../../.github/workflows/em063-parallel-fault-matrix.yml) matrix jobs, `fail-fast: false`. Both **run the exact 0.1.63 ZIP** from original source SHA256 pin; they do not borrow or alter each other's saves. The rail job uses 115 engine ticks then loads its real disk checkpoint in separate process for 130 ticks; electrical job uses 525 then 740 ticks. Each script terminates with its own PASS marker only if all native phase checks pass.
- Deliberate strict orphan guard (rail lane, only actual EM owner destroyed), genuine source demolition and split/restore guard (energy lane). All logs retained on failing CI. New test suite uses genuine engine entities and native interfaces, not Lua-synthesized success.
- Source code committed, **native CI status PENDING** before actual run.

The test workflow and probe code will be added next. Exact CI run/job/artifact refs and failures must be recorded, with per-lane PASS/FAIL, not a single invented blanket PASS.

## 8. Actual native results — NOT RUN
Real engine will be launched in two simultaneous jobs. Future user GUI, Undo/Redo, robots, curved geometry, elevated rails, multiplayer and FPS are separate gates.

## 9. Release decisions
Research-only branch; no merge to `main`, and no changes to owner-installed test mod or existing 0.1.63 downloadable artifact.
