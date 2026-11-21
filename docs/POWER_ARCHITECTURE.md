> **EM072-A2 NATIVE FINITE EM070→LuaBurner JOULE PROOF (2026-11-21):** separate experimental `experiment/native-em070-burner-debit-072a2`, based on EM072-A; original EM070 power_bridge_058 Git blob `4a4084e5cf71d57cc057aa15bc524ac68ff6268b` unmodified. Actual native **Factorio 2.1.24**: five real accumulators **25MJ** -> EM070 manual-import native EEI buffers -> same-J debit into native 2MW LuaBurner. At tick240 **5,116,668J credited, 5,091,668J native consumed, 25,000J burner remains**, unexplained energy residual **~0J**. Parallel vanilla-rail locomotive received **0J**; EM070 OFF tick270 means **0J additional** and still ~0J ledger residual by tick330. Genuine disk SAVE tick151 -> separate process LOAD+210 ticks **PASS all 3 cases**; native SHA256 `f15fb2d63f38646558f83c568d003711c63945ad76e9d7d90f630c44fbb6601a`, reload `2caf429ae02bd0e55b6e15f9279e588168d0c39c87ccdbca29470dd4e9d6e74f`. Full [research](research/traction-em070-native-debit-072a2.md) and [tested runner](../tests/run_native_bridge_debit_072a2.py). **CAVEATS:** station manually forced import, locomotive mapped to a specific station without proof of exact powered HSR component, native EM070 auto dispatch NOT receiving dynamic traction demand. Scratch copy has test-only remote hook; actual mod 0.1.62 still VoidEnergySource. No main game file edits, merge, release or updater. Next EM072-A3 auto demand / verified rail component before 500kW motor wagons, EM073 battery or EM074 regen.\n\n> **NEW CURRENT POWER/TRACTION ARCHITECTURE PLAN EM072–EM075 (2026-11-21):** owner explicitly specified **500 kW per motorized cargo wagon or motorized fluid wagon**, not 500 MW; wagon wheels ONLY receive/return energy via the locomotive's internal train bus, never direct 25 kV pickup. The original locomotive supplies 2 MW nominal; installed nameplate `P=2MW*N_loco+0.5MW*N_motor_wagon`, actual limited by EM070 and batteries/engine. Braking energy can go via locomotive to corridor first, then onboard battery; no fictitious energy from speed changes. Native Factorio does not expose wagon traction `max_power`; exact 500kW must be measured in engine, not assumed from fuel modifiers. [Implementation roadmap](plans/DISTRIBUTED_TRACTION_072.md) · [API proof prerequisites](research/distributed-traction-native-072.md). **PLANNED ONLY**, existing 0.1.62 locomotive remains `void` powered, EM070 and EM071 untouched. This current note supersedes historic 0.1.9–0.1.60 planning snapshots below. No release.

> **Current development source 0.1.62 (no release):** EM070 native dynamic EEI 20MW bidirectional bridge is verified by Factorio 2.1.24 native headless CI and closed-energy test. The locomotive is still `void`-powered, so none of this yet implements traction, battery backup or regenerative braking. Read [EM070 evidence](research/25kv-dynamic-eei-070.md). The 060/059/058 descriptions below are historical.

# 0.1.60 cold-start recovery

060 implementation: native 059 topology confirmed in game 44 vs factory 27/61, auto stayed idle. Independent bounded physical-device sampling for vanilla dynamic EEIs and accumulators, max aggregation without duplication, nonstorage maximum-flow fallback, own offer/request subtraction, native per-interface flow caps, raw and planned diagnostics. Exact engine cause not isolated. 060 CI/live pending; main unchanged.

---

# Current experimental power architecture 0.1.59

See [059 research](research/25kv-auto-bidirectional-059.md). Preserve 058 two separate native networks, wire each visible mast only to its own hidden technical anchor. Automatic direction based on native production and requested load; regular generation serves ordinary loads first, then batteries help unmet load, spare generation charges native accumulators. No battery-to-battery routing. Per station 20MW combined, actual source-buffer accounting and loop protection. 059 game verification pending.

---

# Current experimental power architecture 0.1.58

See [058 research](research/25kv-power-bridge-058.md). Native corridor poles and normal station pole never directly wired: each station has two isolated lab-surface terminals linked only to their respective networks. Fixed direction input and output EEIs move actual source buffer energy. 20 MW per station, no steady self-drain, no energy creation. Explicit import/export/off, default off. Reject loops, same network and connector/network-ID mismatch. No train energy use yet. Live validation pending.

---

# Power architecture 0.1.9 — source prototype, unpowered

Baseline main is ElectrifiedMainline 0.1.8. Work only on feature/35kv-catenary-019.

Two separate systems: ordinary Factorio electric network and custom logical 35 kV graph. Voltage is a UI nominal value, not physical kV simulation.

Contact supports are cloned zero-wire-reach poles. Vanilla copper wires never connect; pair of rendering.draw_line spans is entirely visual and does not transfer electricity.

Substation is currently a normal electric-pole substation on the factory side. Script graphic on its 35 kV side is NOT a working power bridge; a future verified energy interface must debit source energy before crediting destination.

Graph storage: storage.em.power_019.nodes indexed by unit_number, primitive positions/surface/force; edges with render IDs. Local 16-tile neighbourhood query on construction, remove edges on destruction. Current approximate near-rail detection is not exact rail coverage and does not react to subsequent rail edits.

No live rail signal clones. Signal-like placement needs a proven neutral mechanism; train block integrity is more important than UI polish.

Future energy contract: per simulation step delivered_J <= source_debited_J * efficiency, transfer_J <= max_MW * step_seconds * 1000000, no closed-loop charging. Test separately both directions, two substations and a stranded remote outpost.

Traction source remains void placeholder. Plan: overhead first, battery backup, regeneration to grid before battery. No locomotive power code in 0.1.9 phase B.
## 0.1.10 visual topology correction

Contact supports are now limited to nearest mutually selected neighbours in each direction of an approximate local rail axis, so each support has at most two contact spans. Candidate poles must lie within 16 tiles, agree on track side and axis, and have rail entities near three points between them. Straight-rail axis is inferred from direction; curved/half-diagonal axis is an approximation from rail-anchor-to-support offset. This does NOT prove continuous rail connectivity and can omit valid curved spans.

Substations connect to the single closest eligible support by ONE visually distinct blue feeder line, not a pair of contact wires to every nearby support. Substation-to-substation lines are not drawn. Neither line carries actual energy.

After updating an existing 0.1.9 save to 0.1.10, on_configuration_changed deletes old render objects and reconstructs the graph from existing placed entities. Construction/removal of EM rails queues a local graph refresh on the next tick, after engine removal has completed. Normal pole changes refresh locally immediately.

Pure geometry is tested by tests/35kv_topology.lua. In-game geometry, multiplayer, Undo/Redo, crossings, sharp curves and save migration still need player validation.
