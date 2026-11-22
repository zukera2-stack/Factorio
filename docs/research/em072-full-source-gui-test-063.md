# EM072-C5-FULL — full Electrified Mainline experimental 0.1.63 player-test preflight

**Date:** 2026-11-22. **Owner requirement:** one complete playable mod ZIP containing **all actual existing 0.1.62 ElectrifiedMainline items and runtime**, not tiny Base-only C4 lab aliases. **Research branch:** `experiment/em072-fullmod-player-test-063`, based exactly on `main` `cf75656fda374824944311f26bbd454bc90ad45b`. **Target engine:** Factorio 2.1.24 build 87808. **Status:** proposal / no engine result yet. **No main merge, no release or updater.**

## 1. Exact test and original failure
Previous C4+C5 client artifact `45033425830` installed *two isolated Base-only research mods*, without the user's full `ElectrifiedMainline` source/assets. The initial 13-lane map was also unsuitable for a human. Neither proved authentic current contact masts/substation/HSR/electric locomotive/mod interactions. The owner wants a *single full mod ZIP* and a truthful explanation of component test methods.

## 2. Target behavior and safeguards
A single `ElectrifiedMainline_0.1.63.zip` with unchanged production 0.1.62 gameplay code/assets **plus clearly experimental** motor cargo/fluid entity prototypes, a script-only native 1MW hidden helper and read-only native train GUI observer. The existing 25kV contacts, substation reversible bridge, original `em-electric-locomotive`, HSR, artwork, tech/recipe graphs and native Upgrade Planner/Undo must be preserved. Add a manual **opt-in** command for one compact full-mod scene in a *disposable new world* instead of auto-constructing giant fields. Never overwrite player saves, auto-spawn into real saves, change `LuaTrain.speed`, or seed helpers with unpaid energy.

## 3. Falsifiable acceptance plan
1. Normal mod ZIP packaging must include full existing source and graphics, root Factorio entrypoints, and new runtime; no separate C4 or C5 helper mod dependencies.
2. Factorio engine 2.1.24 **data-stage** loads the actual full ZIP with Base enabled. If native headless startup fails, record exact error and fix branch before distribution.
3. New map: `/em-test-kit` grants placeable REAL existing HSR planner, catenary mast(s), traction substation and true `em-electric-locomotive`, and new genuine motor cargo/fluid wagon items; item names visible in normal inventory. **Do not claim any items are energy-certified by merely giving them.**
4. `/em-test-scene` (opt-in only) creates a small line near the player of **actual `em-high-speed-straight-rail`**, real `em-electric-locomotive`, two genuine `em-motor-*` wagons, nearby 25kV masts and traction substation, with one hidden helper coupled while stopped and 0 J. **Failure if the core mod throws or native helper is absent**, no 13-lane automated scene.
5. Open **normal vanilla train GUI** from actual EM locomotive and cargo/fluid, capture screenshots; compare `LuaTrain.carriages=4`, `locomotives=2`, `real motor wagons=2`, hidden helper count=1 with screenshots. **If helper slot visible, UX FAIL, do not claim it is invisible.**
6. Separate user tests: native HSR Upgrade Planner with robots and Ctrl+Z/Ctrl+Y, mast/ghost/blueprint/robot handling, and powered EM070 substation with *real* grid J; a GUI image doesn't prove them.
7. Record CI tests, official Factorio build, full package file count and SHA256. **Engine test** and **owner actual screenshot** independent gates. Re-run after changes.

## 4. Precedents and source comparison
| Source/analogue | Exact file/contract | Provenance | Difference |
|---|---|---|---|
| Base native cargo/fluid/loco | `data.raw['cargo-wagon']['cargo-wagon']`, `data.raw['fluid-wagon']['fluid-wagon']`, `data.raw.locomotive.locomotive` | Factorio Base 2.1.24 as used by C4 | Existing full mod has custom real EM locomotive + visuals; C4 had an artificial clone |
| Verified native C4 | `tests/em-c4-loco-mounted-probe/{data,control}.lua` | `experiment/em072-c4-locomotive-mounted-booster` commit `6e71496bb7972efc989f8b7d9398591335a43f97`, native 2.1.24 / 87808 | C4 helper + real cargo/fluid worked on one straight vanilla rail; never source-paid EM070 J |
| Production as-is | `ElectrifiedMainline/{data.lua,prototypes/bootstrap.lua,prototypes/power_019.lua,prototypes/power_bridge_058.lua,scripts/control.lua}` | `main` `cf75656fda374824944311f26bbd454bc90ad45b`, v0.1.62 | Production locomotive still `energy_source={type='void'}`, motor wagons not yet defined |
| 2.1 runtime API | [LuaSurface.create_entity](https://lua-api.factorio.com/latest/classes/LuaSurface.html), [LuaTrain](https://lua-api.factorio.com/latest/classes/LuaTrain.html), [LuaBootstrap](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html), [on_gui_opened](https://lua-api.factorio.com/latest/events.html) | Public latest documentation may serve newer 2.1.25; **not strictly version matched** | Must validate scene & event scope in actual 2.1.24 engine |
| Native prototype | [LocomotivePrototype](https://lua-api.factorio.com/latest/prototypes/LocomotivePrototype.html), [CargoWagonPrototype](https://lua-api.factorio.com/latest/prototypes/CargoWagonPrototype.html) | public 2.1 docs, version may differ | Helper remains genuine counted locomotive; flags cannot guarantee GUI slot invisibility |

Same-type successful **full-mod** integration precedent has NOT been measured; C4 Base-only native setup is a testable analogous design, not certification. No third-party code copied.

## 5. Intended small change and explicit exclusions
**Data stage:** append a dedicated module after existing full data graph; clone only native cargo/fluid and items, provide native 0.5MW/1MW/2MW hidden finite-J helper prototypes for later controlled tests, no wagon battery. **Runtime:** add a small optional command module from existing control.lua, independent of existing on_tick/Undo handlers. GUI observer logs counts; one compact opt-in scene requires safe native stopped coupling, and failure must be visible. **Kit:** actual existing items from mod, not aliases.

**NEVER claim** that motor wagons draw power from EM070, have working 500kW electric traction, regen, are tested on curves/HSR, work in MP, or are production-ready. Existing 0.1.62 loco is still void. Hidden helper **has zero J**, so scene is GUI/placement-only. Do not change legacy recipes, original graphics, energy bridge, rail upgrade handlers or normal train behavior.

## 6. Hypothesis / falsification / rollback
Hypothesis: by packaging unchanged 0.1.62 source with actual two wagon clones and a read-only optional GUI trial, the user can validate authentic item UI and hidden helper visibility without misrepresenting the electric drivetrain. Falsification: Factorio data-stage fails, real rail geometry/coupler fails, any original item missing, native GUI unexpectedly polluted, existing full runtime interference, or native ZIP content mismatch. Rollback: remove experimental 0.1.63 ZIP, restore prior main-built 0.1.62 ZIP, discard disposable test save; no main branch or old player save edited.

## 7. Implementation / verification — initial source record
Implemented in research-only `ElectrifiedMainline_0.1.63`: original 0.1.62 files and art retained, append `prototypes.em072_c5_fullmod_trial_063` to `data.lua`, `scripts.em072_c5_fullmod_trial_063` to `scripts/control.lua`; two native wagon prototypes and items/recipes/tech unlock; one native invisible finite-burner helper tier for 1/2/4 wagon counts, but no energy-seeding code; optional `/em-test-kit`, `/em-test-scene` (compact actual custom HSR + actual EM + wagon + mast/substation), `/em-test-train` and GUI observer. Factorio APIs not yet client-tested; CI/real engine pending. **C4+Base helper test is not proof of 0.1.63 gameplay.**

## 7b. Human-scale test and original items
`/em-test-kit` grants actual named items from original mod: `em-high-speed-rail`, two authentic catenary masts, `em-35kv-traction-substation`, `em-electric-locomotive`, standard `em-electric-pole` and native railway replacement planner, plus newly added cargo/fluid motor wagon items. `/em-test-scene` is **opt-in** only and limited to 29 genuine HSR rail pieces with real vehicle and only two masts and one substation; no 13-lane 720-tile benchmark. Original production 0.1.62 runtime still processes native building and network/Undo events. This scene tests GUI/coupling and physical placement only: hidden adapter 0J; the EM loco's existing void source is unchanged. Exact game results await user/CI.

## 7c. Test infrastructure committed; outcomes pending
- Main test branch full game ZIP: existing **Build Factorio mod ZIP** workflow with 5 additional source-level checks, adding no second install package.
- Exact native engine experiment: `.github/workflows/em072-fullmod-063-native.yml` downloads official Factorio 2.1.24 Linux headless, loads **actual full game ZIP**, and runs a separate disposable `tests/em063-native-fullmod-probe` to assert real native item prototypes and entity creation, HSR, 2 masts/substation, same train native coupling (4 carriages/2 native locomotives/0J), and visible 14-tile span. Does NOT prove GUI hide, any paid EM070 J, Undo, or user-client results.
- **At writing** Actions status pending; native engine result must be confirmed via exact run/log ID before marking PASS.
Exact code, ZIP/CI, headless client and owner screenshots to be appended after evidence, not invented.

## 8. Actual game results — NOT TESTED
Full source running under official 2.1.24 headless and owner's graphical client are separate test gates.

## 9. Status / next step
**Research prepared only; implement disposable full-mod source 0.1.63, native startup/CI and record actual evidence.** Main remains 0.1.62. Owner is asked only for graphical screenshots if code and CI pass.

## 10. License
Only native public Factorio source prototype contracts and own prior C4 research inspected. No third-party source or graphics copied.

## 7d. Native result / initial CI fixes — 2026-11-22
- [Official Factorio native workflow 45034430942](https://github.com/zukera2-stack/Factorio/actions/runs/45034430942) **PASS**: engine **2.1.24 build 87808 Linux headless** (official installed DLC also loaded), actual full `ElectrifiedMainline_0.1.63.zip` (134 runtime files, 83 accepted sprites), 29 true `em-high-speed-straight-rail`, one real `em-electric-locomotive`, native `em-motor-cargo-wagon` cargo, native `em-motor-fluid-wagon` fluid, two 25kV catenary masts, one `em-35kv-traction-substation`, one invisible 1MW booster with 0J; visible 14-tile span, real native carriage count 4, locomotive count 2.
- Native log: `[EM063 NATIVE PASS] full_real_mod=0.1.63|HSR=29|real_EM=1|motor_cargo=1|motor_fluid=1|masts=2|substation=1|native_carriages=4|native_locos=2|hidden_helper_J=0|span=14`.
- Initial standard build CI of version 0.1.63 **FAIL** due outdated `tests/35kv_ghost_023.lua` which selected legacy art checks for unknown version; 039 art is unchanged. Initial docs CI **FAIL** because `project.mod_version` was incorrectly 0.1.62 while `info.json` is 0.1.63. Corrected test version guard and project scoped version; **do not** mark standard Build ZIP PASS before fresh CI.
- Native result **does not cover** `/em-test-scene` player-initiated function (independent probe duplicates real prototype/geometry checks), graphical vanilla GUI, Undo/Redo, source-paid EM070 J, regen, MP or large-network performance.

## 7e. Legacy tests version compatibility
The normal ZIP pipeline originally **FAIL** in old, version-specific Lua tests: `35kv_ghost_023.lua`, then `25kv_auto_wire_028.lua` assumed a maximal version of 0.1.62. Updated their version selection, plus `25kv_span_029.lua` and `35kv_topology.lua`, to use the same accepted graphics and inherited 062 validation when version is 0.1.63. These are **test-only changes**, not production mechanics or new graphical assets. Full main CI must be rechecked; no attempt to bypass these tests.

## 7f. Full inherited QA remains enabled
The 0.1.63 branch now uses the same native 056 visual-axis contract in `tests/25kv_visual_geometry_048.lua` as 0.1.62. `tests/run_headless_062.sh` was fixed to read `info.json` and use actual versioned `ElectrifiedMainline_0.1.62.zip` or `ElectrifiedMainline_0.1.63.zip`. The three real 2.1.24 electrical bridge/priority/fairness scenarios remain obligatory; no skipping older tests or editing game runtime. Re-check exact CI logs before verdict.
