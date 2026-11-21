# 0.1.61 — native shared-accumulator gateway (RESEARCH / NO MERGE)

## 1. Research metadata
- Opened: 2026-11-21.
- Repository: `zukera2-stack/Factorio`.
- Experimental branch: `experiment/native-accumulator-gateway-061`; exact base `ea9366a9798cd78efec4b675c81d086c09170c28` from `test/updater-approved`.
- Game target: Factorio **2.1.24 build 87808**, Windows owner setup, previous 060 headless test.
- Active accepted gameplay baseline: **0.1.60** (test-only); stable `main` is **0.1.56**.
- Status: **native analogue confirmed in documentation; exact-game experiment NOT YET RUN**.
- Critical owner rule: keep all 129 accepted 060 runtime files and 83 PNGs byte-for-byte unchanged, do not touch `main`, `test/updater-approved` or the working 060 Lua bridge. No distribution/merge of unproven behavior.

## 2. Exact behavior
We want Factorio itself to allocate power among ordinary factory subnets and a separate 25 kV native corridor, instead of a Lua loop measuring supply/demand and moving buffered joules across multiple EEIs.

The existing 060 implementation has two `em-25kv-bridge-port-058` per station on `em-25kv-isolated-bridge-058` laboratory surface, at offsets **3 tiles**; they belong to different native networks, one ordinary factory side and one 25 kV line side, with copper script connections to actual in-world anchors. The script `power_bridge_058.lua` currently creates per-direction EEIs and explicitly copies accounted joules between their buffers, with a **20 MW** per-station limit and dispatch `bridge_dispatch_059.lua`.

**Proposed alternative:** a native accumulator within both supply areas but no copper link between the two port-poles. A shared accumulator may charge from one subnet and discharge into another under Factorio's own electricity solver. Its power input and output can be limited to 20 MW by its prototype. **This is a hypothesis for our specific hidden-port topology, not an implemented replacement.**

Important: native accumulator priority is managed/tertiary, so another accumulator as the only source may *not* charge the bridge; a chain of shared accumulators may not relay across a third network. There is also no guarantee of fair allocation among >2 networks or of independent per-station throughput when many bridges overlap. Avoid premature claims of full native power distribution.

## 3. Acceptance experiments — build a disposable Factorio map
Independent, test-only mod: `tests/em061-native-probe/`, requires only Factorio Base 2.1.24, **not included** in `ElectrifiedMainline/` installation ZIP. See `tests/em061-native-probe/README.md`.

1. **A ↔ B vanilla**. Two separately unconnected substations cover one vanilla accumulator; source is an editor EEI in A, sink editor EEI in B. Check different native subnet IDs, gateway attached to both, power delivered at no more than **300 kW**; verify buffer accounting.
2. **A ↔ B 20 MW**. Replace only the shared accumulator with test-only cloned native accumulator (20 MW input/output, 20 MJ buffer). Observe actual native delivery with a 10 MW source, then reverse source and consumer without Lua joule transfer. Verify 20 MW physical cap and no power creation.
3. **Battery only**. Remove active EEI source/sink; pre-charge ordinary accumulator in A and check whether it charges ordinary accumulator in B through the shared native gateway. **Log observed outcome, not a preconceived PASS**.
4. **A ↔ B ↔ C**. Separate third network with two shared accumulator gateways, source A/sink C; measure whether the center net relays power. **Diagnostic, not asserted**.
5. Only if 1–4 support the required semantics: a new isolated experiment against the already-existing 060 hidden ports, then 4 real substations/40 MW, rail interruption/restoration, save/reload, Bob's devices and accumulator reversing. No working runtime change until proven.

Game observations must include exact build, native network/subnetwork IDs, source/sink/gateway J before/after, delivered J, circuit isolation, and no Lua transfer. A passing Lua syntax or ZIP CI is **not** gameplay evidence.

## 4. Same-type native analogue and source provenance

| Evidence | Exact source | Version/provenance | What it establishes |
|---|---|---|---|
| Vanilla accumulator isolation | https://wiki.factorio.com/Accumulator (section "Isolation of Power Networks") | Wiki page, inspected 2026-11-21, not a version-frozen 2.1.24 test | One accumulator may be shared by two unconnected networks, charging on one and discharging on the other; vanilla rate 300 kW per accumulator |
| Native accumulator prototype | https://lua-api.factorio.com/latest/prototypes/AccumulatorPrototype.html | Indexed latest 2.1.x; runtime target **2.1.24** to verify | Accumulator capacity comes from `energy_source`; its usage priority is engine-managed |
| Native electrical source | https://lua-api.factorio.com/latest/types/ElectricEnergySource.html | Latest documentation may show 2.1.25, not exact target | `buffer_capacity`, `input_flow_limit`, `output_flow_limit` are prototype properties |
| Native priorities | https://lua-api.factorio.com/latest/types/ElectricUsagePriority.html | 2.1.x; exact installed-version check pending | `tertiary` serves residual storage only |
| Native multisubnet runtime info | https://lua-api.factorio.com/latest/classes/LuaEntity.html | 2.1.x; exact installed-version check pending | `electric_networks` enumerates subnetworks for one energy entity |
| Developer discussion, corroboration only | https://forums.factorio.com/viewtopic.php?t=125485 | 2025; not source code | A shared accumulator behaves as a capped bidirectional flow control |
| Our actual 060 code | `ElectrifiedMainline/scripts/power_bridge_058.lua`, `prototypes/power_bridge_058.lua`, `scripts/bridge_devices_060.lua`, `scripts/technical_network_046.lua` | `ea9366a9798cd78efec4b675c81d086c09170c28`; version 0.1.60 | Two independent terminal poles on separate lab surface; EEI-Lua transfer; network safety checks |
| Target earlier native test | `docs/research/25kv-dispatch-recovery-060.md`, run 44762226742 | Official Factorio 2.1.24 headless on CI | 060 Lua transfer, 20 MW source/sink, charge & reverse discharge **passed**, but not native shared-accumulator candidate |

No same-type *mod implementation* was copied. This experiment builds a tiny native-prototype reference using the game's built-in accumulator and an independent clone.

## 5. Comparison with the existing bridge

| Property | 060 accepted Lua bridge | 061 hypothesis |
|---|---|---|
| Factory-to-line separation | Isolated native port networks; strict wiring checks | Same topological separation; shared energy entity with zero copper link |
| Throughput | Lua per station capped at 20 MW | Prototype `input_flow_limit` / `output_flow_limit`; **measure** total actual rate |
| Supply scheduling | Lua samples production, loads, batteries and plans direction | Native engine priority, no Lua sampling |
| Source support | Tested with primary-output EEIs, some owner modes need manual configuration | Native EEI/steam/accumulator priorities determine availability; not all sources guaranteed |
| Stored-energy reversal | 060 headless test passed with ordinary accumulators | Battery-to-battery-through-accumulator unknown, likely limitation |
| Three-network relay | 060 auto planner handles graph with limits | Native tertiary-to-tertiary relay unverified |
| Backward compatibility | Exact 0.1.60 distributed files unchanged | Test-only mod; no replacement until user approval and game evidence |

## 6. Falsifiable hypothesis and rollback
**H1:** If two truly unconnected pole subnetworks both cover the same vanilla accumulator, energy from an active primary source on A will reach an active consumer on B, bounded by 300 kW, with no Lua transfer. **Reject H1** on no delivery, shared poles, or an unexplained excess.

**H2:** Raising only the accumulator's native input/output limits to 20 MW and capacity to 20 MJ yields a source-limited (~10 MW) bidirectional transfer while poles remain unconnected. **Reject H2** on loss of isolation, incorrect power cap, energy creation, or reverse failure.

**H3:** A bank of ordinary accumulators on A can export their stored joules across a tertiary shared accumulator to B; **not assumed true**. No transition away from 060 if this fails and is needed by gameplay.

**H4:** Two consecutive accumulator bridges can relay power across three networks; **not assumed true**.

Rollback: remove test-only mod and temporary save; nothing in the accepted 060 installation changes. An experimental gameplay implementation, if tests pass, must use a *new* branch and can only be promoted with explicit owner permission.

## 7. Implementation record
Only test-only independent source under `tests/em061-native-probe/` and research/handoff documentation. **No modification to the shipped mod.** No third-party code/assets copied. Static Lua/CI and actual native test results must be appended when available.

## 8. Game results
**Not run as of initial record; no proof of 061 behavior.** Earlier verified 060 headless test is *not* reused as a PASS for these hypotheses.

## 9. Decision gate
For now retain Lua bridge. Only consider native integration if Factorio 2.1.24 evidence proves all required cases including isolated 20 MW, 40 MW aggregate, native accumulators, mixed ordinary loads, live rail removal, and no bypass/cycle. Otherwise a hybrid bridge may be necessary. Update `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` atomically with every material change.

## 10. Existing Windows patcher — required distribution route (2026-11-21 clarification)
Do **not** tell the owner to download and manually replace a gameplay mod ZIP every time: **Electrified Mainline Updater 1.1** already exists and was confirmed working by the owner on Windows on 2026-11-20. The updater itself is stored in `feature/git-updater-060/tools/updater/`:
- `README.txt` — owner instructions.
- `Update.bat` → `Updater.ps1` — Russian UI: **1 install/update**, **2 verify**, **3 rollback**, **4 select mods folder**.
- Windows QA run [44783774432](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432), updater artifact [14650879317](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432/artifacts/14650879317). QA included Windows clean install, ZIP conversion, incremental one-file repair, rollback, duplicate refusal; owner independently reported successful install.
- Git for Windows, PowerShell 5.1 are prerequisites; Python and administrator rights are not.
- Only approved source `refs/heads/test/updater-approved` is fetched, currently **0.1.60 / ea9366a9798cd78efec4b675c81d086c09170c28** (verified 2026-11-21). The updater does not track `experiment/native-accumulator-gateway-061`, cannot install the separate test-only mod, and must not be redirected to arbitrary feature branches.
- A future **gameplay 0.1.61** (not this research-only probe) must first pass static/CI, actual Factorio 2.1.24 headless and owner-defined game QA, then receive explicit owner approval for promotion of an **exact reviewed commit** to `test/updater-approved`. Only after that, tell owner: close Factorio → `Update.bat` → **1** → confirm; optionally **2** for verification. Backups under `%TEMP%\ElectrifiedMainline-Updater` may be cleaned by Windows; keep an independent save backup.
- Do not move approved ref just to run the Base-only research probe. Run it on a disposable isolated map/CI instead; preserve current 060 and user's saves.

## 11. Architecture correction: priority levels are more important than an accumulator alone

User challenge on 2026-11-21: you cannot attach an ordinary accumulator via two independent copper terminals. This is **correct** about explicit electrical connectors: accumulators have no two independent wire ports. The official [Accumulator isolation section](https://wiki.factorio.com/Accumulator#Isolation_of_Power_Networks) shows a distinct special case: two **unconnected electric-pole grids with overlapping supply areas** may both serve the same accumulator. [Factorio LuaEntity.electric_networks](https://lua-api.factorio.com/latest/classes/LuaEntity.html) is explicitly documented to enumerate multiple networks for an energy entity. A native overlap is real, but it is **tertiary-priority**, not a voltage transformer.

### The Factorio electrical scheduler, not physical voltage
[ElectricUsagePriority](https://lua-api.factorio.com/latest/types/ElectricUsagePriority.html) and [ElectricEnergySource](https://lua-api.factorio.com/latest/types/ElectricEnergySource.html) provide priorities:
- **solar output**: highest production priority.
- **primary-output**: primary source (editor/dynamic EEI when so configured).
- **secondary-output**: ordinary steam generators and existing 060 output EEI.
- **tertiary-output / tertiary**: stored-energy-style lower priority source (verify exact dynamic EEI behavior).
- **primary-input**: urgent consumers such as laser turrets.
- **secondary-input**: ordinary consumers and existing 060 bridge collector.
- **tertiary-input**: low-priority surplus collector (verify accumulator source interaction).
- **tertiary_input_output** and **accumulator** dynamic EEI modes exist in Factorio 2.1.x; subtle differences and mixed-network behavior must be **tested**, not guessed.

These are supply/demand *dispatch priorities*, **not** primary/secondary/tertiary physical voltage rails and **not** the ability of one EEI to have two independently wired electrical ports. The 25 kV in our mod is nominal/cosmetic; engine networks do not model voltage drop or 25 kV conversion.

The 2.1.7 [official scripting changelog](https://forums.factorio.com/134095) introduced dynamic priority, `LuaEntity.electric_interface_mode` and per-entity `input_flow_limit`/`output_flow_limit`. To exercise dynamic modes safely, the EEI prototype itself must support `usage_priority = "dynamic"`. Our shipped 060 prototype `prototypes/power_bridge_058.lua` instead has **fixed** `secondary-input` and `secondary-output` prototypes. Do not assume a runtime property can turn those into fully dynamic devices without a data-stage migration and exact engine proof.

### Why a single native accumulator probably cannot replace 060
1. A shared ordinary accumulator is *tertiary* on **both** sides. It accepts only surplus and discharges only to unmet demand at lower/higher production priorities; cannot guarantee stored-energy-to-stored-energy relay.
2. A bank of charged vanilla accumulators on A and an empty vanilla accumulator on B are also tertiary. **Do not assert** that they exchange energy through an extra tertiary shared accumulator: in particular, native batteries generally do not charge each other directly. A route A→B→C may stall. Verify exact 2.1.24 semantics before a conclusion.
3. We need supply from native ordinary generators, Bob's devices and native accumulator banks, with regular consumer priority; we also need charge on the far side at up to 20MW. An output-side **secondary-output** interface can offer energy to ordinary storage with the engine regulating within that local network, unlike an all-tertiary chain.
4. Two isolated factory/corridor grids cannot be interconnected just by assigning EEI priorities. The 060 Lua bridge transfers actual accounted J between physically isolated EEIs with 20MW caps and cycle guards. A **native power switch**, in contrast, merges networks when closed and provides no native 20MW throughput cap. Neither is a drop-in replacement for the other.

### Revised falsifiable first experiment: a 2.1.24 priority matrix
**Do not alter the working 060 bridge.** Build a separate Base-only test fixture with `electric-energy-interface` set to each mode (or a test-only dynamic prototype), a vanilla accumulator, a **real secondary-input load** (radar or other native device), an explicit primary-input priority device where feasible, and source/sink profiles. For each case log native net id(s), EEI mode/limits, J before-after, `parent_network.flow_last_tick`, and transferred J/tick. No scripted energy teleportation.

| Case | Source in network A | Bridge input priority | Bridge output priority in network B | B loads | What must be learned |
|---|---|---|---|---|---|
| P1 | 10MW primary-output EEI | secondary-input (060 control) | secondary-output | native sink + accumulator | Baseline buffer accounting, real A→B transfer only if using controlled 060 Lua bridge |
| P2 | 10MW primary-output EEI | tertiary-input | secondary-output | native sink + accumulator | Does surplus-only extraction work? |
| P3 | charged vanilla accumulators only | secondary-input | secondary-output | native sink + empty accumulators | Can bridge draw from source batteries? Identify no-generator behavior |
| P4 | charged vanilla accumulators only | tertiary-input | secondary-output | native sink + empty accumulators | Does tertiary-to-tertiary charge fail? |
| P5 | 10MW primary-output EEI | secondary-input | tertiary-output | empty vanilla accumulators only | Does tertiary output actually charge tertiary storage? |
| P6 | primary-output source + native loads | primary-input vs secondary-input | secondary-output | ordinary loads | Does bridge starve critical/ordinary consumers? |
| P7 | arbitrary source | dynamic accumulator vs tertiary_input_output | dynamic as supported | multiple nets | Distinguish modes; do NOT claim bidirectionality or cross-net transfer without native evidence |

**Attention:** P1–P6 require a *paired* isolated A/B interface plus a controlled (existing) accounted Joule transfer to evaluate bridged delivery. Their primary objective is to isolate **input and output priority semantics** on each side. The shared-accumulator no-Lua experiment remains a separate P8 sanity test for overlap/isolation, then P9 battery-only and P10 A→B→C. Do not mix experiments or infer native across-grid behavior from the existing Lua bridge.

### Direction policy hypothesis (not adopted)
- **Default surplus-only source**: tertiary-input EEI may collect only generated excess, preserving ordinary consumers, but likely will not discharge native battery banks; this is an operational policy choice, not automatic superiority.
- **Reserve-supported source**: secondary-input EEI may request energy even from stored batteries as a real consumer. Its 20MW limit alone does **not** guarantee protection of critical ordinary loads; add measured reserve guard.
- **Destination**: secondary-output EEI offers real buffered J to the local network and should be preferred over tertiary-output **if the goal includes charging native accumulators**; engine test required.
- **Primary-input/output**: never use merely to solve an idle bug, since it can override priorities of user factory devices.

Design decision: **keep the verified 060 bridge and test priorities as a focused optimization path**. Only consider replacing it if shared-native alternatives prove 20MW, battery bank charge/discharge, bidirectional 2-grid and 3-grid, no energy creation and full topology audit.

### Source provenance and uncertainty
Direct source: official Factorio Wiki Accumulator "Isolation of Power Networks"; official 2.1.x prototype/runtime docs and 2.1.7 changelog; 060 repository fixed EEI prototypes and headless test logs. Historical Factorio staff statement that tertiary EEI behaves as a battery: https://forums.factorio.com/viewtopic.php?t=73078 (older version: source **context**, not 2.1.24 acceptance). The 061 source is only **research code**; current CI PASS did not run a native engine. All mode-specific behavioral predictions above are marked for exact game tests.
