# 0.1.60 cold-start recovery

060 implementation: native 059 topology confirmed in game 44 vs factory 27/61, auto stayed idle. Independent bounded physical-device sampling for vanilla dynamic EEIs and accumulators, max aggregation without duplication, nonstorage maximum-flow fallback, own offer/request subtraction, native per-interface flow caps, raw and planned diagnostics. Exact-engine headless QA passed; owner configured EEI transfer confirmed. See the scoped evidence below. Main unchanged.

---

# Current experimental power architecture 0.1.59

See [059 research](research/25kv-auto-bidirectional-059.md). Preserve 058 two separate native networks, wire each visible mast only to its own hidden technical anchor. Automatic direction based on native production and requested load; regular generation serves ordinary loads first, then batteries help unmet load, spare generation charges native accumulators. No battery-to-battery routing. Per station 20MW combined, actual source-buffer accounting and loop protection. 059 live topology passed; automatic dispatch stayed idle (fixed for configured EEIs in 060).

---

# Current experimental power architecture 0.1.58

See [058 research](research/25kv-power-bridge-058.md). Native corridor poles and normal station pole never directly wired: each station has two isolated lab-surface terminals linked only to their respective networks. Fixed direction input and output EEIs move actual source buffer energy. 20 MW per station, no steady self-drain, no energy creation. Explicit import/export/off, default off. Reject loops, same network and connector/network-ID mismatch. No train energy use yet. 058 manual transfer supported by owner 20 MW screenshots; automatic dispatch introduced later.

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

## Latest scoped 0.1.60 acceptance (20 Nov 2026)
2026-11-20 owner confirmation: Updater 1.1 installed 0.1.60 successfully on the owner's Windows PC after the previous 1.0 clean-install connection failure. Owner reported energy transfer restored after configuring editor EEIs as primary_output/secondary_input using the previously verified console commands. This is owner chat confirmation, not a new measured log; prior 060 log factorio-current(20261120-155649).log lines 685–718 independently established sustained 20 MW. Scoped acceptance: updater installation and configured automatic transfer PASS. Not full release acceptance: arbitrary/tertiary EEI modes, ordinary generators, Bob's battery integration, owner accumulator reversal, live rail-break recovery, larger grids, actual retry after connection interruption and owner rollback remain open. 0.1.61 next: research all EEI modes and native ordinary loads, fix dispatch, localized substation GUI (actual signed MW, planned MW, mode, connectivity, idle reason), expanded native headless tests. Preserve frozen 83 PNGs and native isolation. Distribute subsequent test builds via explicitly promoted test/updater-approved only after CI and relevant engine QA; keep CI ZIP fallback. Main 0.1.56 unchanged; no merge approval.
