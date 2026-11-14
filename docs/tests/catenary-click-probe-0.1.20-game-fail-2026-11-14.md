# 0.1.20 Factorio user test: capsule normal-LMB concept falsified, rail-only wire rule accepted as simpler architecture

**Date:** 2026-11-14. **User evidence:** uploaded `factorio-current(20261114-185758).log` from Factorio **2.1.20 build 87512**, Windows 10 / Space Age, user reports the experimental pole is buildable on empty land. This is the hotfixed ZIP `ElectrifiedMainline_0.1.20.zip` from [build #43628474166](https://github.com/zukera2-stack/Factorio/actions/runs/43628474166), artifact #14127098330.

## What was observed in the game

- 0.1.20 successfully completed the data stage and locale stage, initialized and loaded the user's ВСМ save; user quit normally. Hotfix from 2026-11-14 fixed the prior fatal duplicate locale.
- Four real `em-35kv-catenary-pole` electric-pole entity placements were logged via ordinary `on_pre_build` + `on_built_entity`:
  - tick 47935, (-9.5,54.5)
  - tick 49949, (3.5,2.5)
  - tick 50503, (7.5,8.5)
  - tick 50892, (6.5,2.5)
- **No** `[ElectrifiedMainline][0.1.20][probe]` events or `on_player_used_capsule`-derived build attempts appear. The log alone doesn't label which cursor item generated each event; the **user explicitly reports** off-HSR build with the probe item.
- This **falsifies the proposed safety invariant**: an item prototype having both capsule action and `place_result` is not a reliable vanilla-LMB pre-build HSR gate on Factorio 2.1.20. Likely `place_result` takes precedence on LMB (game test supports behavioral outcome, not isolated engine cause). No reason to keep developing this dual-use capsule pathway. Keep as archived experiment; NO release to main.

## Current catenary behavior verified in source (not all visually game-asserted)

Source `scripts/power_019.lua`:
- `RAILS` contains only the four custom ВСМ rail names; nearby railway detection uses `RADIUS=3` tiles at `rail_tangent`.
- `register` sets `rail_adjacent=false` for an off-track catenary pole. `on_built` prints `message.em-35kv-no-rail` when the new pole is away from custom HSR.
- `build_edges` only selects wire candidates if `a.rail_adjacent`; `scripts/power_topology.lua` `M.compatible` additionally requires `b.rail_adjacent` and relative geometry. Corner spans additionally require `connected_rail_path` and curved corridor checks. Both endpoints must be rail-adjacent to form contact edges.
- A 35kV pole built away from HSR therefore remains a **physical electric-pole entity** and decorative mast sprite, but it cannot participate in the **visual** 35kV contact-wire graph. The engine handles ordinary LMB and native Undo/Redo without script injection.
- `power_019.lua` line 1 clearly says `cosmetic sprites only; no MW transfer`; `M.status` reports `energized=NO transfer_MW=0 (visual only)`. **Do not claim functional 35 kV electricity supply exists yet.** The `electric-pole` prototype has its base-vanilla supply/wire links disabled in 0.1.9+; drawn contact lines are LuaRendering, not real copper wires.

## Recommended simpler product rule (user discussion)

- **Allow physical mast installation anywhere via standard LMB** (normal game behavior).
- **Only form catenary lines along custom ВСМ geometry**, requiring both real masts within 3 tiles of custom tracks and compatible geometry; preserve rail connectivity for curves. Off-rail masts are visually standalone and nonfunctional to the virtual catenary graph; no resource consumption/refund hacks.
- Preserve original real `electric-pole` and engine Undo, blueprints, robots and upgrades; do not create capsule click-probes, signal proxies, special ground, hidden helper entities or global LMB override in production.
- Keep green rail-end markers optionally as placement guidance; do not misrepresent them as engine placement permission. Consider decluttering (e.g. only show near mouse/when toggled) and clear on-screen feedback for off-rail masts.
- **Future** real traction energy feature should explicitly gate power supply/consumption by the same HSR contact graph, with tests for disconnected rails and no spurious electricity at off-track poles.
- This is an architectural recommendation based on user explicitly suggesting the relaxed constraint. Not a coding change or release approval.

**Outcome:** no source changes, no ZIP generated, no branch merging. Stable `main` stays 0.1.8. Source 0.1.20 game result is a **FAIL** of click-probe HSR-only placement concept, not a general mod load failure. Return to 0.1.18 experimental game-tested version for catenary visuals pending a clean next release.
