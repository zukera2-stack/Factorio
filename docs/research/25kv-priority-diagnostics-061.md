# 0.1.61 — read-only native EEI priorities, patcher candidate

## Provenance
- Source branch: `feature/updater-061-candidate` from frozen approved 060 `ea9366a9798cd78efec4b675c81d086c09170c28`.
- Target game: Factorio **2.1.24 build 87808**. Actual 061 native-game QA is **pending**.
- Context and separate non-distributable native accumulator experiment: [prior 061 research](https://github.com/zukera2-stack/Factorio/blob/experiment/native-accumulator-gateway-061/docs/research/25kv-native-accumulator-gateway-061.md).
- Official runtime API: [2.1.24 LuaEntity](https://lua-api.factorio.com/2.1.24/classes/LuaEntity.html), fields `electric_interface_mode`, `input_flow_limit`, `output_flow_limit`, `energy`, `electric_network_id`. Input/output limits and production/usage values are **J/tick**; convert to MW by multiplying by 60/1e6.
- Existing 060 prototypes have **fixed** `secondary-input` and `secondary-output`. The new diagnostic reports configured modes for selected accessible EEIs; **does not change** prototype configuration or transfer joules.

## User-visible change (minimal falsifiable scope)
1. Bump installable `ElectrifiedMainline/info.json` to `0.1.61` so Updater 1.1 can display it **after approval and promotion**.
2. Add read-only `/em-25kv-priority`: select an ordinary electric-energy-interface and inspect native network ID, actual `electric_interface_mode`, energy, buffer capacity, current configured input/output rates, production/consumption. Selecting vanilla accumulator prints tertiary storage context and native rate limits. Selecting the mod traction substation prints existing 060 bridge status and static source/target priorities.
3. No game-mechanic alterations: no custom voltage system, no dynamic EEI priority change, no new entity, no change to power bridge, measured 060 20MW cap, frozen visuals, rail tools, Undo ownership, or saves.

## 061 acceptance and negative scenarios
- **Static Lua:** syntax for all shipped and test-only Lua; 060 inherited regressions and new `tests/priority_diagnostics_061.lua`. Historical CI version gates only cover 060; isolated subprocess runner is in always-run `tests/35kv_topology.lua` for 061.
- **CI package:** exactly source SHA, 83 frozen runtime PNG manifest and generated `ElectrifiedMainline_0.1.61.zip` (not a local manually repacked user ZIP); verify game payload list, metadata and SHA when available.
- **Native Factorio 2.1.24:** create disposable test save; verify mod loads, selected editor EEI mode readout matches mode; verify accumulator readout and station status, verify auto transfer still 20MW under prior 060 scenario and reverse after battery use. **Not established by Lua CI.**
- **Owner testing:** on separate save after approval, run existing Windows `Update.bat` option 1, then verify option 2, test selected entity command. Do not touch user's saves.
- **Negative:** selected nil, non-electric entity, invalid entity should print helpful message and never error or mutate state.

## Distribution gate
`test/updater-approved` stays on 0.1.60 until build CI, native 2.1.24 evidence and owner approval. An experiment branch and an untested probe are **never** promoted simply to make Updater download files. After the exact approved commit promotion, the owner uses their existing Updater 1.1. No main merge required and no standalone updater download.
