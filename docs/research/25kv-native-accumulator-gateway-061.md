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
