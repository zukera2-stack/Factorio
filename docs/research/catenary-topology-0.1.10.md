# 0.1.10 research record: rail-oriented catenary visuals

## User evidence and source cause

User's 0.1.9 screenshot shows five contact supports along a straight high-speed rail and a substation below them. Contact lines draw, but several long diagonals connect the substation to different supports. User reports that the entities place and lines render in Factorio 2.1.20. The 0.1.9 source linked EVERY pair of support/substation entities within 16 tiles. This is a confirmed source-level explanation for the visible diagonals.

## API and analogues

- Native 2.1.20 pole prototype: https://lua-api.factorio.com/2.1.20/prototypes/ElectricPolePrototype.html . The 35 kV support remains a zero-wire-reach electric pole; ordinary copper network is separate.
- Native rail runtime: https://lua-api.factorio.com/2.1.20/classes/LuaEntity.html and https://lua-api.factorio.com/2.1.20/classes/LuaSurface.html . Position, direction, local rail entity queries are used; exact curved spline API is not claimed.
- Native rendering: https://lua-api.factorio.com/2.1.20/classes/LuaRendering.html . Rendering lines remain decorative, not electrically conductive.
- Electrified Railways: https://mods.factorio.com/mod/ElectrifiedRailways . Visual analogue only; source and exact commit not reviewed; no code/assets copied.

## Hypothesis

Replacing all-pairs linking with a rail-oriented mutually nearest-neighbour chain will remove the observed spiderweb without altering train signals. Each substation should have only one feeder edge. Contact supports should have at most two contact spans, with a 16-tile maximum, 2-tile lateral tolerance, same track side and 3 sampled positions near high-speed rails. In-game tests must determine whether the geometry heuristic works on curves and nearby parallel tracks.

## Implementation / falsifiable checks

- Pure selection: ElectrifiedMainline/scripts/power_topology.lua. Lua unit tests: tests/35kv_topology.lua.
- Runtime: ElectrifiedMainline/scripts/power_019.lua. Feeder is one blue line, contact is paired gold/silver lines.
- Version 0.1.10 ensures on_configuration_changed reconstructs the old 0.1.9 all-pairs render graph; old render IDs are destroyed.
- Building/removing rails schedules a next-tick local re-evaluation; building/removing poles refreshes immediately.
- Straight line of five evenly spaced supports (10 tiles apart): expected four contact spans. A substation nearby: one feeder.
- Removing the middle pole should leave a gap when adjacent remaining poles exceed 16 tiles; Ctrl+Z should restore topology.
- Adjacent parallel tracks, crossings, curved-A/B and half-diagonal segments remain NOT verified. Geometric proximity is not true connected rail topology.
- Real power transfer, batteries and regeneration remain OFF; no claims of an energized rail.
