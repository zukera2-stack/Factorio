# Power architecture 0.1.9 — source prototype, unpowered

Baseline main is ElectrifiedMainline 0.1.8. Work only on feature/35kv-catenary-019.

Two separate systems: ordinary Factorio electric network and custom logical 35 kV graph. Voltage is a UI nominal value, not physical kV simulation.

Contact supports are cloned zero-wire-reach poles. Vanilla copper wires never connect; pair of rendering.draw_line spans is entirely visual and does not transfer electricity.

Substation is currently a normal electric-pole substation on the factory side. Script graphic on its 35 kV side is NOT a working power bridge; a future verified energy interface must debit source energy before crediting destination.

Graph storage: storage.em.power_019.nodes indexed by unit_number, primitive positions/surface/force; edges with render IDs. Local 16-tile neighbourhood query on construction, remove edges on destruction. Current approximate near-rail detection is not exact rail coverage and does not react to subsequent rail edits.

No live rail signal clones. Signal-like placement needs a proven neutral mechanism; train block integrity is more important than UI polish.

Future energy contract: per simulation step delivered_J <= source_debited_J * efficiency, transfer_J <= max_MW * step_seconds * 1000000, no closed-loop charging. Test separately both directions, two substations and a stranded remote outpost.

Traction source remains void placeholder. Plan: overhead first, battery backup, regeneration to grid before battery. No locomotive power code in 0.1.9 phase B.