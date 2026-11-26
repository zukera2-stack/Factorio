# EM087H — Vanilla First: native bridge port checks, 2026-11-26

**PARTIAL / EXPERIMENT, NOT accepted.** Base 0.1.92 / EM087F, commit `51eceb442ed7d8fdd487795f9d46e861e427f431`, full archive SHA256 `0ef5c4890704808d5efdf21a2c654eb8ae58fcbd34f8320cc7bab87dea37624b`. Explicitly exclude rejected EM087G path-memo 0.1.93. New full experiment 0.1.94 SHA256 `229a75b0d14bf64c7a17542c16855e93b66a975616eaaddf23037f1da815702f`. Latest local maintenance candidate remains 0.1.86, last owner-confirmed running 0.1.84. No main merge or release.

## Changes and invariants

157 gameplay files, 99 PNG unchanged. Exactly three changes: info.json, scripts/power_bridge_058.lua, scripts/bridge_dispatch_059.lua. Replace enumeration of port.real_connections in sole_link with native real_connection_count==1 and is_connected_to(expected, script). Both endpoints are physical and live. Preserve check of origin and intended endpoint, call every original time; no stored permission or new cache. Read parent_network once per parent_key call rather than repeatedly, preserving validity check and minimum native subnetwork ID. Preserve native full parent lookup, factory isolation, path eligibility, rail watchers, local component replan, full 600-tick and 60-tick audits, 20 MW station cap, native paid J ledger, helper coupling and visibility contract. No claim that actual parent network ID is equivalent to raw electric_network_id. No permanent path memo from 0.1.93. No weakening of audit cadence or changes to prototypes/assets.

## Native engine verification

Factorio 2.1.24 build 87808 Linux headless. Exact 0.1.94: 53 inherited scenarios (48 explicit completion + 5 stand assertions) plus 7 additional explicit tests. 60 total (55 explicit + 5 stands). 100 moving trains, 800 motor wagons, mixed/vanilla/ownerless trains, opposing locomotives and changing consist length, 401 wagons with 11 substations, 100 demolition cycles, 48-substation electricity fixture, migration 0.1.85, no_path alert suppression, prototype checks, actual old disk checkpoint, silent rail cuts, local replan and native train pathfinder distinction. No Windows GUI claim. New native connectors test compares old/new predicates for 10 actual connector states: no wire, player-only, script-only, extra script, extra player, wrong target, two origins on same target, ghost wire, ghost removed, target destroyed. All equal. Ghost wire ignored by real connection count (1 actual, 3 total in fixture); removal had 2 real connections, both predicates rejected. First test incorrectly expected true after ghost removal; corrected to equivalence (unexpected native behavior not explained); initial failing log preserved. First localplan run used 300 ticks vs last assertion at 601; rerun 620 PASS t602. Preserve both logs. Independent switch fixture: raw IDs 1 and 2 throughout, canonical native parent key 0/1 open, 0/0 closed, 0/1 open; native subnetwork counts 1/1, 2/2, 1/1. PASS t31. Do not replace parent key with raw ID, or with the Lua planned topology. This test observes native parent grouping, not full power-through-switch gameplay bridge settlement. API reference https://lua-api.factorio.com/latest/classes/LuaWireConnector.html and https://lua-api.factorio.com/latest/classes/LuaElectricSubNetwork.html (online API version may differ; tests executed on 2.1.24).

## Code-only same-version A/B benchmarks

Two runs per variant on same input saves and version 0.1.92, isolating code changes from configuration/migration. Stationary saturated trains and one long consist, not whole-factory or movement performance benchmark. 480 ticks for 50/100, 1200 for long201. Full candidate 0.1.94 functional tests above; its separate version-changing benchmark not run. Regression jobs completed before benchmark starts. Small sample, host variability; peak and mean separate.

| Stand | Base mean ms | New code mean ms | Change | Worst base/new ms | Checksums base/new |
|---|---:|---:|---:|---:|---|
| 50x2 | 19.0215 | 17.5490 | -7.74% | 371.020/415.533 | 556739828/556739828 |
| 100x2 | 42.4385 | 39.7080 | -6.43% | 781.271/772.272 | 3722375787/3722375787 |
| long201 | 3.0480 | 3.5840 | +17.59% | 50.360/78.471 | 2633033209/2633033209 |

Paired recorded log lines (remove timestamp/path prefix):

- 50x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 300/300, equal, [EM069 BUFFER STOP]: 0/0, equal, [EM077 MOTOR STATE]: 2/2, equal
- 100x2: [EM072 PAID LEDGER]: 16/16, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 16/16, equal, [EM065 CONTACT]: 16/16, equal, [EM060]: 600/600, equal, [EM069 BUFFER STOP]: 0/0, equal, [EM077 MOTOR STATE]: 2/2, equal
- long201: [EM072 PAID LEDGER]: 40/40, equal, [EM068 ACTUAL NATIVE TRAIN LOAD]: 40/40, equal, [EM065 CONTACT]: 40/40, equal, [EM060]: 2400/2400, equal, [EM069 BUFFER STOP]: 1198/1198, equal, [EM077 MOTOR STATE]: 4/4, equal

## Decision and blockers

Performance gate NOT MET, no primary-game install. The native predicate is smaller and tested, but improvement cannot be generalized to all maps; 100-train budget 16.667 ms/tick not met. Preserve exact energy accounting and audits. Complete Windows consist/station GUI invisibility, complex junctions, 100km corridor, long-run memory, multiplayer and compatibility remain open. Future: profile per-tick bridge isolation/read-network loops and native mast connector audit; avoid new cache layers. Native count/connection fast path for a mast or technical anchor only when all expected connections are verified, fallback to existing full list audit for discrepancies. Do not remove independent verified-edge components merely because native parent IDs coincide: a foreign connection may join them. Existing native copper topology remains authority for electricity; retain permitted HSR eligibility and wire isolation. Compare 0.1.94 against 0.1.92 on exact moving saves before acceptance.

## Delivery

Approved Direct Patch tool explicitly rejects non-adjacent 0.1.92 -> 0.1.94. Do not bypass or renumber a tested archive. No Direct Patch created; preserve failed build/verify log. Deliver verified complete experimental ZIP only, never overwrite owner install or main. 0.1.93 was an unaccepted separate experiment; 0.1.94 not an update on that archive. Exact full candidate stored separately in Library /Factorio/Local-QA/EM087H_0.1.94_full_EXPERIMENT.zip. Full source and all logs in evidence. Reproduction scripts refer to the original local fixture directories; reconstruct these from supplied previous experiment archive and this evidence if necessary. No official CI, no release.

## Regression cases

| Case | Status | seconds |
|---|---|---:|
| `alerts-nopath1` | PASS | 3.677 |
| `alerts-nopath201` | PASS | 3.797 |
| `alerts-nopath800` | PASS | 8.031 |
| `alerts-nopathdual201` | PASS | 4.404 |
| `alerts-nopathzero201` | PASS | 4.046 |
| `attach-bidir` | PASS | 5.046 |
| `attach-dual` | PASS | 3.797 |
| `attach-grow-retry` | PASS | 4.207 |
| `attach-same` | PASS | 4.293 |
| `attach-shrink-retry` | PASS | 4.000 |
| `audit-block` | PASS | 4.156 |
| `audit-churn` | PASS | 7.639 |
| `audit-churn100` | PASS | 16.422 |
| `audit-fair` | PASS | 4.511 |
| `audit-gui` | PASS | 3.726 |
| `audit-move` | PASS | 3.745 |
| `audit-offgrid` | PASS | 4.323 |
| `audit-ownerloss` | PASS | 3.797 |
| `audit-retain` | PASS | 3.204 |
| `audit-visibility` | PASS | 3.914 |
| `bench-100x2` | PASS | 13.883 |
| `bench-10x2` | PASS | 3.965 |
| `bench-1x2` | PASS | 3.732 |
| `bench-1x800` | PASS | 7.368 |
| `bench-50x2` | PASS | 6.467 |
| `extended-0` | PASS | 3.534 |
| `extended-1` | PASS | 3.765 |
| `extended-199` | PASS | 3.634 |
| `extended-200` | PASS | 3.761 |
| `extended-201` | PASS | 4.104 |
| `extended-400` | PASS | 4.189 |
| `extended-401` | PASS | 5.051 |
| `extended-600` | PASS | 6.739 |
| `extended-800` | PASS | 7.071 |
| `extended-dual201` | PASS | 4.159 |
| `extended-mixed` | PASS | 3.729 |
| `extended-ownerlossdual` | PASS | 4.756 |
| `extended-passive` | PASS | 3.239 |
| `extended-power401` | PASS | 7.881 |
| `extended-prototypes-retry` | PASS | 3.078 |
| `extended-split` | PASS | 3.664 |
| `extended-standalone` | PASS | 4.103 |
| `extended-vanilla` | PASS | 3.134 |
| `extended-zero201` | PASS | 3.647 |
| `migration085` | PASS | 2.107 |
| `moving-1` | PASS | 4.284 |
| `moving-10` | PASS | 6.181 |
| `moving-100` | PASS | 38.592 |
| `moving-50` | PASS | 22.367 |
| `native-corridor` | PASS | 3.589 |
| `native-segments` | PASS | 3.968 |
| `network-multi48` | PASS | 6.865 |
| `network-topology` | PASS | 4.203 |
| `watch-native` | PASS | — |
| `watch-powered` | PASS | — |
| `watch-disk-load` | PASS | — |
| `localplan` | PASS | — |
| `native-router` | PASS | — |
| `native-wire` | PASS | — |
| `native-switch` | PASS | — |