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
