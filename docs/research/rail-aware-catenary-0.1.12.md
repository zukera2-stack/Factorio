# Research record: rail-following 35 kV visual catenary (0.1.12)

**Date:** 2026-11-13. **Branch:** `feature/rail-aware-catenary-012`, parent `d82eadcde57df93d149a0bc8019bea9827891945`. **Target:** Factorio 2.1.20 build 87512. **Inspected official online docs:** latest 2.1.24; exact 2.1.20 documentation URL returned inaccessible, so compatibility requires a game test. **Mod base:** 0.1.11.

## Player-observed issue and acceptance

User-supplied `2026-11-13_13-50-43.zip` contains a Factorio screenshot with fixed-direction Г-shaped supports beside a straight-to-curved-to-vertical custom HSR line. Existing poles do not rotate through R, and the contact wires remain straight or absent at corners. Keep the electricity system visual-only, preserve vanilla rail signal block partition and Undo/Redo.

Test: load updated existing save; poles must automatically point their arms towards nearby HSR rails on horizontal, diagonal and vertical sections *without user rotation*. Contact and messenger lines must be visually curved and change direction along the rails, not cut across the inside of a corner or connect poles on opposite tracks. Removing/adding/robot-building poles, changing HSR rails and save/reload must recreate correct rendering. No signal/chain-signal entity is ever created or modified.

## Native and third-party analogy research

| Source | Precise inspected evidence | Relevance | Limits |
| --- | --- | --- | --- |
| [RailSignalBasePrototype](https://lua-api.factorio.com/latest/prototypes/RailSignalBasePrototype.html) | Dedicated `rail-signal` properties and hardcoded collision rules; rail signals attach to rail locations | Native rail-side snapping analogue | Real rail signal *changes train block/path semantics*; not safe as a disguised support |
| [Rail signal guide](https://wiki.factorio.com/Rail_signal) | Signals partition rail blocks; sided orientation controls allowed direction of travel | Reason to keep supports out of signals | No supported property for signal-like snapping on an arbitrary electric pole was found |
| [ElectricPolePrototype](https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html) | `pictures` is a `RotatedSprite`, copper wire reach and automatic connections are independent | Preserve 0-copper-reach ElectricPolePrototype for inventory/blueprint compatibility | Its graphics direction is not automatically rail-aligned |
| [EntityPrototypeFlags](https://lua-api.factorio.com/latest/types/EntityPrototypeFlags.html) | `filter-directions` is used by train stops, signals and pumps | Investigated native filtering | No documentation promises rail direction filtering on `electric-pole`, so NOT used |
| [LuaRendering](https://lua-api.factorio.com/latest/classes/LuaRendering.html) | `draw_sprite` accepts `sprite`, `target`, `surface`, `orientation`, `x_scale`, `y_scale`, `render_layer` and returns a render object | Mechanism to rotate only the cantilever and texture short wire segments | Runtime behavior on exact 2.1.20 build not confirmed |
| [LuaGameScript.get_entity_by_unit_number](https://lua-api.factorio.com/latest/classes/LuaGameScript.html) | Resolves `get-by-unit-number` flagged entities | Existing graph resolution | Existing support already has flag, no new magic |
| [Realistic Electric Trains Continued 0.6.1](https://mods.factorio.com/mod/Realistic_Electric_Trains_Continued_2SE) | Mod description says ordinary catenary poles snap beside straight/diagonal/curved tracks and do not function as railway signals | Same-task working *reported* behavior | Source N/A, Factorio 2.0 not exact 2.1.20; descriptive claim only, no inspected source or code copied |
| [Electrified Railways](https://mods.factorio.com/mod/ElectrifiedRailways) | Mod description says its catenary poles snap beside rails | Additional precedent | Source and exact implementation not inspected; licensed artwork/code NOT copied |

Current source: `prototypes/power_019.lua`, `scripts/power_019.lua`, `scripts/power_topology.lua`. In 0.1.11, cloned `electric-pole` has four `RotatedSprite` frames but does not turn in the user's screenshot. The 0.1.10 contact graph requires tangent alignment ≥0.90 and lateral deviation ≤2 tiles, rejecting a corner. The existing runtime has no geometry-curved wire rendering.

## Hypothesis and minimal independent design

**Hypothesis:** Keep the entity an isolated `electric-pole` with a static mast/shadow; generate an independent upper cantilever `SpritePrototype` and attach a `rendering.draw_sprite` object to each physical pole. On pole placement and rail changes, calculate its normal toward the closest custom HSR rail and set render orientation from that vector. This changes neither rail signals nor electrical connections, and avoids assuming `LuaEntity.direction` works for poles. The arm has a separate rotation origin; the mast remains upright. When no HSR rail is within 3 tiles, show the mast without arm.

For contact lines, allow ~45-degree local tangent changes (with mutual-nearest and rail-corridor guards) and sample a cubic Hermite path constrained by the endpoint rail tangents. Draw short *textured* contact/messenger sprite segments following the path, not one horizontal cord. Keep one visual feeder per substation, and never create electric copper connections.

**Implementation boundaries:** no `rail-signal` or `rail-chain-signal` prototypes, no signal events, no new rail entities, no entity teleport/re-creation, no Undo manipulation, no power transfer. Pole placement will NOT have the vanilla blue/green signal snap preview or physical relocation; it auto-orients visually immediately after placement. This tradeoff avoids changing Undo ownership.

**Risks / falsifiers:** rendered arm might rotate in the plane rather than true isometric perspective; curves and switchbacks may still be rejected by approximate tangent/corridor; unsupported sprite args could fail to load the 2.1.20 data stage; scripts drawing graphics can create UPS costs. If tested curves remain disconnected, inspect exact 2.1.20 rail geometry and traversal before broadening acceptance (do not connect across gaps). No third-party code or assets copied.

## Test plan and evidence labels

- **Offline/unit:** alpha-mask mast/arm separation, reproducible PNG hashes, Lua syntax, vector orientation quadrants, straight-line rejection of opposite-side supports, corner acceptance, Hermite endpoints, original graph behavior, single-version ZIP.
- **CI:** valid PNG dimensions and `SpritePrototype` paths; ensure no rail-signal source mutation; build 0.1.12 zip. Successful CI is NOT an in-game test.
- **Game:** screenshot curved track and four corner directions with supports, verify anchored arms and nonstraight wire spans, `/em-35kv-status`, robot placement/removal, save reload, rail Upgrade Planner+Undo/Redo, no altered train signals. Exact player-provided Factorio log required to mark game-tested.

Implementation record and CI link to be appended after source changes.

## Implementation and check results (2026-11-13)

Changed: scripts/power_topology.lua (pure geometry), scripts/catenary_visuals_012.lua (script rendering), scripts/power_019.lua (lifecycle hooks and graph schema 3), prototypes/power_019.lua (static mast, separately registered arm), info.json 0.1.12, scripts/sprites/split_012.py and its negative tests, tests/35kv_curve_topology.lua. CI scripts generate PNGs reproducibly from synthetic test sprites; real art is a local byte-checked replacement of 3 PNGs only. No rail-signal or rail-chain-signal entities or prototypes introduced; physical poles keep no copper reach. Poles are not teleported/snapped and original rail Undo event handling remains untouched.

Source commit df9f5069ec64ccbec1fdadc46a02cc94dd3119f8. [CI #43418015719](https://github.com/zukera2-stack/Factorio/actions/runs/43418015719) PASS with 33 Python unit tests, Lua syntax, pure Lua original and curve assertions including right-angle elbow, and single 0.1.12 mod ZIP. [Artifact 14033350683](https://github.com/zukera2-stack/Factorio/actions/runs/43418015719/artifacts/14033350683). Offline evidence only: runtime Factorio 2.1.20 and game visual/UPS/Undo are **unverified**. Some complicated switches/curved piece anchors may still need real-game geometry refinement.
