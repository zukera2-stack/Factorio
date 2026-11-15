# ElectrifiedMainline 0.1.24 — user acceptance / scoped game test

Date: **2026-11-15**. Target game: **Factorio 2.1.20**, build **87512** (Windows, Space Age). Version loaded: **ElectrifiedMainline 0.1.24**; test save: `ВСМ.zip`. Result: **USER ACCEPTED visual mast/cursor/ghost milestone**, authorizes merging to `main` and updating documentation. The words "все отлично, наверно можно сливать в майн" are explicit user approval for this promotion. A complete electrical system is NOT approved or implemented.

## Exact supplied evidence

- Gameplay screenshot archive `2026-11-15_21-27-44.zip` (one 1920×1080 RGBA PNG, `2026-11-15_21-27-44.png`). SHA-256 **`fd73991e6fc408e2a6cc931cbc5d1c47189e622f283844e1bb792111badefd12`**. The full-resolution screenshot is a conversation attachment; **not stored as a 5 MB source image in GitHub** by design.
- `factorio-current(20261115-183047).log` supplied 2026-11-15, SHA-256 **`506bee98a83260408ff8e3fa50307800b7132a6a7fcd9050acf7a139e7608af9`** (702 lines).
- Build workflow [#43738070195](https://github.com/zukera2-stack/Factorio/actions/runs/43738070195) **SUCCESS**, artifact [#14171451634](https://github.com/zukera2-stack/Factorio/actions/runs/43738070195/artifacts/14171451634) includes `ElectrifiedMainline_0.1.24.zip`; static Lua/PNG/ZIP checks. Earlier image QA [#43737875150](https://github.com/zukera2-stack/Factorio/actions/runs/43737875150) SUCCESS.
- Source snapshot under test: `feature/catenary-native-mast-body-024` commit `c83f2bc45180b814c344dfa28df18a77f7507d04`; latest code changes `ddf6a1e5817aab84e4ee30511c9174831bbe5cd5`. **MERGED [PR #8](https://github.com/zukera2-stack/Factorio/pull/8) into `main`: `43dd05a544a02de75f3b4a3c3689cd795f853d21`**. Post-merge [mod CI #43748406702](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702) SUCCESS; [docs CI #43748406753](https://github.com/zukera2-stack/Factorio/actions/runs/43748406753) SUCCESS.

## Observed in screenshot and log

- Screenshot shows a **visible green placement-preview native mast shaft** rather than old shadow-only cursor; already built masts have **one lattice mast body with a directed G cantilever**; blue ghost silhouettes and the subdued circular rail-slot markers appear on/near curves and a half-diagonal segment.
- Game loads without a visible Lua/Factorio exception; both data stages and `control.lua` load properly, and the save opens.
- Direct manual build: `on_built_entity` at tick 47318 and tick 48459. Ghosts: multiple `on_built_entity entity=entity-ghost ghost_name=em-35kv-catenary-pole`, including curve region.
- Robot construction: `on_robot_built_entity` events tick 56512–56543, plus 57385, 57423, 57446, 57558; successful native robot actions, including curved A/B and half-diagonal adjacency.
- Undo/Redo: `on_undo_applied` after marked deconstruction tick 56871+ and `on_redo_applied` with regenerated ghosts at ticks 57308+, followed by robot construction; subsequent exits normally (`Goodbye`).
- Visual-facing log examples: curved-A `face=west`; curved-B `face=southwest`; half-diagonal `face=northeast`. Several masts outside the custom railway have `face=east via=no_rail_default` — expected fallback; **not** proof of incorrect geometry.
- User's own assessment: **"все отлично"**, accepts as visually satisfactory and requests merging to `main`.

## Scope and important open issues

**Game-tested, visually accepted:** native mast-body preview under cursor, built mast with eight-way arm geometry in photographed scenes, blue ghost body/arm representation, native placement and ghost/robot/Undo sequence, muted circular indicators. No evidence of error in supplied log.

**Not established by this test:** every of eight angles under every curve/rail combination, multiplayer, every save migration, interrupted robot-job edge cases, production-scale sprite performance, exact native ghost blur equivalence, half-diagonal *Upgrade Planner* undo, separate selection tool and train-signal regressions. Additional 0.1.8 rail-upgrade tests remain valid historically.

**Explicitly NOT implemented:** energized catenary/traction, physical 35kV simulation, MW transfer, battery model, power regeneration; `transfer_MW=0`. Current wires are **cosmetic** and need deliberate separate geometry/visual QA.

## Release decision

This is a **0.1.24 accepted visual milestone**, not an all-features-complete final release. Promoted to `main` via PR #8 after passing source, graphics and docs CI checks without rewriting 0.1.8 historical game-tested evidence. Old `dist/ElectrifiedMainline_0.1.8.zip` remains as rollback baseline; `main` should become 0.1.24 and future branches should originate there.
