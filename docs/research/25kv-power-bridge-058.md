# 058 — native 25 kV corridor and reversible limited-power substation

## 1. Metadata
Owner request 2026-11-20; branch feature/25kv-power-bridge-058; based on 057 ecc890fb1c65a1766d8752861b45cb59e284757c, main remains accepted 056. Target last known game 2.1.24 build 87808, installed modpack exact versions unknown. 057 CI 44710656476 failed only final PNG count; preceding 054 validator confirmed 105 pre-cleanup PNGs, workflow forgot to remove pads for 057. Correct gate to include 057/058.

## 2. Behavior
Ordinary station remains native factory electric pole. Separate technical anchors (046) are zero supply/reach and script-connected only along actual HSR. A station transfers real buffered joules with an aggregate 20 MW ceiling, no continuous self-use, no direct ordinary-to-corridor copper connection. Existing 056 visual graph and feeder art unchanged.

## 3. Acceptance
Disposable save: lay at least 2 masts linked by HSR, one substation near each end; no ordinary wire spanning zones. Source generator >20MW, two substations set import/export respectively, remote >25MW load, inspect actual power graph, then source <10MW, no load, source off, remove middle rail, remove/rebuild mast, save/load, reverse roles, same ordinary network and loop, ghosts, Undo/Redo. Expected max 20MW, no phantom power, no bypass, finite <=2 ticks buffered tail. Traction remains void placeholder; no claims that locomotives consume. No automatic direction yet.

## 4. Native and mod analogue
Current repo technical_network_046.lua, power_019.lua and prototypes/catenary_art_030.lua: existing script copper connector contract with zero reach, same force/surface, actual links, nearest eligible feeder. Native small pole clone is already accepted. PowerOverload 2.3.3 source (Factorio 2.1), tburrows13/PowerOverload commit 289f0c026495dd3a56510f31a936aa7908c0ff6a, prototypes/transformer.lua lines 126–166, scripts/transformer.lua lines 146–229 and 257–292, scripts/create-surface.lua. Inspected via GitHub: separate input/output EEIs with capped buffer flow, transfer debits actual input.energy then credits output.energy, isolated helper surface with script copper link to physical terminal across surfaces. No code or assets copied. Exact installed PowerOverload not required. Native EEI analogue supported by official modding FAQ.

## 5. API
Official https://lua-api.factorio.com/latest/classes/LuaEntity.html energy, electric_network_id, electric_buffer_size; https://lua-api.factorio.com/latest/types/ElectricEnergySource.html input/output limits, buffer, drain; https://lua-api.factorio.com/latest/prototypes/ElectricEnergyInterfacePrototype.html; https://lua-api.factorio.com/latest/classes/LuaWireConnector.html connect_to(real target, false, script), network_id. Exact 2.1.24 URLs unavailable; latest 2.1.25 docs and 2.1-compatible working analogue. No dependence on newly documented dynamic interface mode or read/write flow limits.

## 6. Design
Two hidden isolated ports per real station on dedicated lab surface, one connects only to factory-side station pole, one to selected 046 anchor. Both ports retain zero native reach and no automatic copper connection, small supply footprint only on lab surface. Whitelist exactly registered corridor port in technical audit. Two EEIs with fixed secondary-input and secondary-output priorities, one-tick buffer and 20MW directional rates, zero production/usage/drain; create only after confirmed direct links and distinct actual network IDs. Modes off (default), import (factory to 25kV), export (25kV to factory); changing role destroys both interfaces and discards residual energy, never credits new energy. Recompute directed acyclic graph of actual grid IDs deterministically by station ID each tick; reject reverse/long cycles and same network. No load => finite buffers fill then no ongoing consumption. On rail split, native engine splits line; no scripted power across disconnected native component. No speculative engine voltage physics. Limit is 20MW each station, unity efficiency initially, no rail/train speed mutation. Fail closed on refused cross-surface link/missing connector/network mismatch; use disposable save. Old wagon migration from 057 persists. 

## 7. Implementation
Added native hidden terminal poles and EEIs, one-tick buffer and 20 MW flow limits. Per-tick conservation and cycle policy tested by pure Lua; runtime lifecycle and exact link validation implemented. Manual game validation pending.

058 initial CI 44750760503 failed at legacy 048 continuity fixture because inner axis-test gate omitted 058; corrected the gate, old assertions retained, no gameplay changes. Rebuild pending.

## 8. CI evidence
058 CI PASS (run 44750917384, source e5de8a8bd425d716ff9d7d61dbfccf6cf843e10e): 058 energy/loop/lifecycle Lua mock tests and 056 regressions passed, 126 game files / 83 PNGs. Install artifact 14635601471: https://github.com/zukera2-stack/Factorio/actions/runs/44750917384/artifacts/14635601471 . Inner ZIP SHA256 5fe82a166920dfac99c0541f3e334f3e3195322f26c07fe0cb2f3ce16c400341 . Live 25 kV network IDs, cross-surface wire attachment and actual engine energy transfer remain unverified. User test pending; main unchanged.
