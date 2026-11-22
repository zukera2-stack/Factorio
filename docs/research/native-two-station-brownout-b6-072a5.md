# EM072-A5-B6 — two genuine native EM070 substation sources and factory brownout

**Date:** 2026-11-22. **Verified:** NATIVE FACTORIO 2.1.24 build 87808, 500 ticks + true independent disk SAVE/LOAD **PASS**, **RESEARCH ONLY / NOT GAMEPLAY IMPLEMENTED**.

## Source baseline and integrity

Repository `zukera2-stack/Factorio`; parent B5 commit `219edd0d4247986f1beb336761604b02fdf3744c`; new branch `experiment/em072a5-native-brownout-b6`. Original playable-code baseline is still **ElectrifiedMainline 0.1.62, not a published release**. Exact EM071/EM070 CI source: [Actions run 44925677432](https://github.com/zukera2-stack/Factorio/actions/runs/44925677432), artifact 14714614745, original mod ZIP SHA256 **`91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`**. The runner checks SHA256 and 5 individual core source Git blob IDs, then extracts it to an isolated temporary mod folder. No file under production `ElectrifiedMainline/` is changed in this Git branch or `main`.

The native lab uses **16 actual independent Factorio trains**, with true `LuaBurner` and acceleration via native `character.riding_state`; `LuaTrain.speed` is never set. Exact source B5 research fixture is maintained as regression control. Test fixture uses static train requests (2MW per train); no production traction algorithm or `void`-powered game's locomotive has been integrated.

## Physical setup

| Component | Corridor A | Corridor B |
| --- | --- | --- |
| Real EM070 station | 1, x≈−20, AUTO→OFF t300 | 1, x≈500, AUTO throughout |
| Real HSR, force and surface | y=1, first physically connected rail component | y=160, second **disconnected** rail component |
| Real locomotive trains | 12 × 2MW fixed demand | 4 × 2MW fixed demand |
| Real vanilla factory accumulators | **84**, 420 MJ / 25.2 MW | **84**, 420 MJ / 25.2 MW |
| Real corridor accumulators | **24**, 120 MJ / 7.2 MW, 0 J initial and charged by native solar + EM070 | **24**, 120 MJ / 7.2 MW, **test-seeded full** initially |
| Real solar panels | 346 built, 270 native-connected to A factory, destroyed t225 | 340 built, **326 native-connected** to B factory, destroyed t225 |
| Native traction meter | Own finite native EEI 800kJ input-only | Own finite native EEI 800kJ input-only |
| Native factory overload meter | None | Own **500 kJ EEI native input-only**, requested 30MW starting t300; script drains solely native-accepted J and accounts them as industrial load |
| Native electrical network | Native factory A vs corridor A different IDs | Native factory B vs corridor B different IDs, different from A's two IDs |

B's new station is attached to real HSR through true technical masts; standard mast prototype supply radius is not changed. Only the disposable research fixture registers test-owned terminal/copper on the appropriate technical anchor. The four factory/corridor native network identities and the train HSR graph reject cross-component demand. Existing B4 physical rail cut/rejoin and both B5 controller lifecycle sequences continue as negative tests.

### Timeline, measured inside real Factorio

- **t1:** two real station entities, 2×84 vanilla source cells, 2×24 outpost cells, 16 native train IDs, native solar on both factory sides. For corridor B, solar create count 340, at t90 there are **326 native-connected** solar panels and all 84 source cells on the second factory network.
- **t90:** four real native electrical networks verified distinct and B line-side ID equals B terminal + battery meter network. Neither native rail network authorizes a foreign locomotive. `[EM072A5 B6 TWO REAL EM070 PASS]`.
- **t200:** native zero-start charge of A continues as in B3. All B native source and outpost cells remain finite.
- **t225:** both solar fields **physically removed** (not a fake generation Boolean).
- **t231:** B's closed finite-J baseline **541,212,000 J**, including 84 source cells, 24 outpost cells, two native bridge EEI buffers, traction meter, factory-load meter and current burner fuel. Source production is now zero.
- **t240:** native B fixed demand of 4×2MW was entered **once** on B line network; B AUTO station actually became active.
- **t250–295:** B EM070 AUTO *planned* power observed; **46 active plan ticks** and **peak plan 20.000 MW** (per-station cap). **Warning: this is planned requested power, not independently measured real 20MW native output.** B's measured four-locomotive demand is 8MW. Battery charge or demand overcount are potential explanations and need a separate per-tick source/target audit.
- **t300:** A's EM070 placed OFF (as in B3). B's EM070 stayed in AUTO. Native B factory solar remains absent and an isolated B factory EEI starts requesting **30MW**. The loop debits only the Joules Factorio's native solver has actually placed in this finite 500kJ EEI buffer. Vanilla 84-cell B factory battery can output no more than **25.2MW**; demand is therefore larger than battery's maximum even if no other loads exist.
- **t310–496:** **187 control ticks** report source native charge to the 30MW factory meter under 30MW by >1 kJ/tick, proving measured demand shortfall. On t330 the 4 B trains have received >0.5MJ beyond t300 while the first station remains OFF. Rebuilt B terminal ownership and A rail-cut/lifecycle tests continue to pass.
- **t496:** primary and secondary honest finite-J ledgers PASS; all 16 trains had moved. Native B industrial sink consumed **82,231,578.947 J** from native factory electricity during the measured span. B four locomotives received **30,880,000 J**, actually spent **27,217,939.353 J**, have **3,662,060.647 J** remaining in their native LuaBurners, with equal **7,720,000 J per B train**. Minimum B movement **354.086 tiles**. B unexplained ledger residual **−0.000002 J**, A residual **−0.000002 J**, A native burner received/spent **39,533,333.333 J**, each of its 12 trains **3,294,444.444 J**, minimum movement **194.172 tiles**.

### True native SAVE/LOAD

- Native headless **500-tick benchmark PASS**.
- Independent headless server did true **SAVE t385**, checkpoint **735,607 bytes**.
- Separate Factorio headless process loaded that on-disk file using `--test-save` and ran **115 ticks**. The B6 station peak, industrial native consumption, shortfall count, B and A train delivery, expenditure, stored burner fuel, path cache rebuild counts and both energy ledgers **matched exactly**.
- Native benchmark log SHA256 **`e5d16d56b5e72da366bbc812a9aedb5e05c733550a69530c3286771b42f1d021`**; independent LOAD log SHA256 **`fc9417cb9e087d31ea9a23b63091497a5c6f3da66e09836dc3b0aba563e07a84`**. The raw native logs and all source fixture files are saved in the personal Library under `/Factorio/Network-062/brownout-072a5b6/`.

## Limits and open physics/API questions

1. **This is not a playable outpost or complete electric train.** The B6 source is an isolated test probe, hook and script-owned connector, with no player/controller mining UI, Ctrl+Z/Redo, Blueprint or bot verification. The production version 0.1.62 locomotive remains `energy_source.type="void"`.
2. The B industrial load is a **test-only dynamically debited native EEI**, not a built production beacon/furnace network. It consumes only native-solver-supplied J and the finite ledger includes its J. The experiment proves native shortage and isolation in this scenario, not general brownout responses of all modded buildings.
3. **20MW station reading is a planner ceiling, not measured real native throughput.** With only 8MW fixed locomotives on B, the 20MW plan before brownout is a red flag for future demand dedup/EEI buffering analysis. Need independently sample both input EEI draw and line EEI delivery and capacitor charge at 60Hz before accepting automatic dispatch efficiency.
4. Both real EM070 stations are **on different physical HSR and native factory components**. Multi-EM070 competing on a **single shared HSR component**, interactions with moving trains passing substations, mixed 12-train/4-train demand through 2 stations, dynamic throttling, motorized +500kW wagons, regenerative braking, multiple player surfaces/forces, multiplayer, large UPS benchmark are **not verified**.
5. Genuine player, robot, Blueprint, Undo and gameplay `on_configuration_changed` for player-built terminal are still not implemented. B5 test-probe-only change 0.0.1→0.0.2 PASS does not imply they work in gameplay.

**Next gate (B7):** validate true per-tick second station EEI input/output flow, deduplicate fixed direct vs sampled meter demand, negative factory brownout priority and paid-battery movement, then separately add two native EM070 on one shared rail and player/robot/Undo tests. Do not advance into the production branch until explicit owner approval.

**NO MAIN MERGE, NO GAMEPLAY RELEASE/TAG, NO PATCHER/INSTALLER, NO DISTRIBUTABLE ZIP.**