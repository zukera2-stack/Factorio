# 0.1.9 35 kV — research and first hypothesis

Status: 2026-11-12; source prototype, game test pending.

## Verified research / external precedents
- Vanilla electric pole: https://lua-api.factorio.com/2.1.20/prototypes/ElectricPolePrototype.html . Supports supply_area_distance, maximum_wire_distance, auto_connect_up_to_n_wires. A zero-reach pole should not connect to ordinary power; still needs in-game verification.
- Rail signals: https://lua-api.factorio.com/2.1.20/prototypes/RailSignalBasePrototype.html . Actual rail signals would change train signalling. Do NOT clone a live signal as a passive contact support.
- Electrified Railways 0.3.25: https://mods.factorio.com/mod/ElectrifiedRailways . Public description confirms signal-snap catenary gates and visible centreline wire, but they use ordinary electrical copper wiring. Source code and exact commit not yet audited; this is not proof for our architecture.
- Electric Grid: https://mods.factorio.com/mod/electric-grid . Public description of converter-like power bridges; architecture precedent only, source not audited.
- Electric energy interfaces: https://lua-api.factorio.com/2.1.20/prototypes/ElectricEnergyInterfacePrototype.html . Candidate for bounded bidirectional transfer. No writes to energy or power_production until a source-debit conservation test is designed.
- Rendering lines: https://lua-api.factorio.com/2.1.20/classes/LuaRendering.html . Visual wires can be drawn without electrically joining networks; 2.1.20 gameplay test pending.

## Approaches
| Design | Issue | Decision |
|---|---|---|
| Native copper-wire network with contact poles | Player connections may bypass any bridge to ordinary grid | Reject strict-isolation requirement |
| Cloned rail signal | Becomes a real block signal, risking routes | Reject until neutral rail snap is proven |
| Copperless electric-pole support + logical graph + rendered lines | Separate by construction; no current flow until modeled | Selected for safe Phase B test |

## Implemented prototype
- em-35kv-catenary-pole: copper reach=0, supply radius=0, auto connection disabled.
- em-35kv-traction-substation: ordinary electric substation clone; may connect to factories, no transfer to logical 35 kV graph.
- scripts/power_019.lua stores primitive node IDs, force and surface, creates visual paired spans up to 16 tiles at construction, removes drawings on mining/destruction.
- Poles need existing EM rail within 3 tiles to connect to the graph. This is only a proximity heuristic, NOT true native rail-signal snapping, NOT proof of electrified coverage or centerline catenary geometry.
- No per-tick graph scans. No energy source/sink, no MW flows. Old em-electric-pole left untouched.

## Tests and blockers
1. CI Lua/ZIP and YAML; test game load separately.
2. Build two poles beside EM rails <16 tiles apart, see two lines; ordinary poles cannot connect to the contact supports.
3. Mine middle support; check lines disappear. Ctrl+Z/Ctrl+Y and blueprints with robots.
4. Build a substation and connect it only to ordinary vanilla grid; 35 kV graphics alone must not power remote base.
5. Test vanilla rail upgrade, curved-A/B Undo/Redo and superforced blueprint unchanged.
6. Research/implement correct non-signalling snap placement and rail geometry graph.
7. Research/implement a metered electric-energy-interface power bridge and energy conservation. This is a hard gate; don't create energy via power_production without debit.