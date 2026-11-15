# 0.1.26 — native copper connector probe for independent 25 kV catenary

## 1. Research metadata
- Opened: 2026-11-15. Branch: experiment/native-25kv-wire-026.
- Starting commit: 04a290da887477d759b9ec53edb67371a6835a90 (accepted 0.1.24 main).
- Target Factorio: 2.1.20 build 87512; API online documentation observed at 2.1.24 (not exactly version matched).
- Game QA status: NOT TESTED. Intended network label 25 kV AC; no electrical voltage physics in probe.

## 2. Exact operation and acceptance
On a COPY of ВСМ, place two native C masts 8-12 tiles apart. Use
/em-25kv-probe start while near them. The mod creates two nonselectable,
collisionless, non-blueprintable electric-pole helpers at projected arm tips,
then uses a *player-origin* copper connector to request a visible Factorio
copper wire between them. Inspect screenshot, connection count and network IDs.
Use /em-25kv-probe status and /em-25kv-probe clear. Removing a parent mast
must delete its test anchors. Confirm no unintended vanilla pole auto-link.
Do not treat this experiment as a power network, regeneration or traction.

## 3. Analogue search / provenance
| Source | Location | Revision / version | Observation |
| --- | --- | --- | --- |
| Wube native prototypes | https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/entities.lua | public master; NOT pinned to installed 2.1.20 | small-electric-pole uses ElectricPolePrototype and connection_points for copper and shadow |
| Official prototype | https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html | docs 2.1.24 | maximum_wire_distance, connection_points, draw_copper_wires, auto_connect_up_to_n_wires=0 disables auto-connect |
| Official runtime | https://lua-api.factorio.com/latest/classes/LuaWireConnector.html | docs 2.1.24 | connect_to(target, reach_check, origin), can_wire_reach, is_connected_to, network_id |
| Official defines | https://lua-api.factorio.com/latest/defines.html | docs 2.1.24 | copper connector, player origin vs invisible script-origin; no new 25kv connector type |
| Our baseline | ElectrifiedMainline/prototypes/power_019.lua | main 04a290da | 0 wire distance, zero auto-connect, no vanilla copper drawing, one C shaft and eight Lua arm overlays |

No same-type published mod source is claimed inspected or validated at installed
2.1.20. Native small-electric-pole prototype is the direct same-type reference.
The actual copper-wire engine code is not public. The game is the arbiter.

## 4. Prototype and API comparison
- Existing C masts: stay untouched at 0.1.24 state with cosmetic rail wires;
  native shaft, blue ghosts and robot/Undo stay native.
- Helpers: new cloned electric-pole type, empty picture, no collision/selection,
  auto-connect=0, reach 16, one connection point matching one picture.
- Projection: approximate existing eight C face offsets 1.5 tiles; native copper
  connection point is rendered 2.53125 tiles upward from helper floor projection.
  P2 image alignment is a hypothesis, not established by source art coordinates.
- Script: command-only create/connect with explicit wire_origin.player,
  synchronous success/diagnostic output, manual cleanup. No periodic sweeping,
  no scripted ghost or signal grid. Do not use script-origin wire: invisible.
- Risks: connector reach/offset mismatch, invisible pole prototype validation,
  unwanted outside links, wire occlusion, save/load, unowned helper if an
  external mod destroys parent without events, and Factorio 2.1.20 drift.

## 5. Falsifiable hypothesis
If the game accepts two empty-sprite electric-poles with configured copper
connection points and player-origin LuaWireConnector.connect_to, it will render
a native copper line without using rendering.draw_line. Compare actual visuals
against 0.1.25. If no visible line, or a connected helper produces an unwanted
factory-grid link, reject this architecture or change the test design.

## 6. Stop conditions and rollback
No migration or automatic building on loading. Remove with probe clear,
restore the saved-map backup or remove the experimental mod ZIP.
Never merge to main without screenshot/log and performance/Undo regressions.
Source remains an original implementation informed by native API, not copied
engine source.

## 7. Implementation
Added isolated helper prototype, projection module, command-only runtime and
pure Lua geometry/prototype contract QA. Main masts and legacy contact graph are
untouched. CI can prove Lua and ZIP packaging, not native game behavior.

## 8. In-game evidence
PENDING — user Factorio 2.1.20 screenshot and factorio-current.log.

## 9. Decision
PENDING — native wire rendering, attachment accuracy, isolation and lifecycle
must be visually verified before using as a 25 kV network primitive.
