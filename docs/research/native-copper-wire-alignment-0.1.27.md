# 0.1.27 native copper wire attachment correction
Date: 2026-11-16. Branch: experiment/native-25kv-wire-027.
Base: 0.1.26 commit ffabf34d19c6e956f14fccf081a3bda2cdcf667f.
Target: Factorio 2.1.20 build 87512. Main stays accepted 0.1.24.

## Actual user evidence
On 0.1.26 user sent factorio-current.log and a ZIP of three 1921x1080
screenshots. The game log reports copper network 24/24, count 1/1,
visible-connection=true. Gameplay therefore proves engine native wire
connections; screenshot proves the endpoints miss the C insulators.
Two test helpers were at (-33.50,1.00) and (-48.50,1.00), while mast
positions were (-33.50,-0.50) and (-48.50,-0.50).

## Cause
Old SOUTH tip placement used world rail direction (0,+1.5), but the
SOUTH sprite actually depicts a RIGHTWARD cantilever. Wire was anchored
around the shaft and lower than the triangular insulator. Screenshot
spatial estimates: 15 tile separation is about 480px, so 32px/tile;
visual desired delta from old copper endpoint approximately +56px X
and -74px Y. New SOUTH helper offset (+1.75,-0.80), 1.75 tiles right
and 2.30 tiles up from old helper. Same native wire point height
-2.53125 tiles retained. Other seven orientations are not yet calibrated.

## Minimal change and safeguards
- Remove old scripted rendering.draw_line overhead, messenger and feeder
  segments, preserve rail-following topology graph, native C mast sprite
  and eight arm overlays. Previous render IDs are destroyed by
  power019.rebuild_all during on_configuration_changed.
- Shift invisible copper helper entity location, not native shaft sprite.
- Add optional command DX DY arguments for runtime screenshot calibration.
- Remove tracked and orphan 0.1.26 helper poles on configuration update.
- Keep command-only creation; no automatic power grid/Undo changes.
- No real 25 kV AC, traction transfer, or independent wire connector type.

## Research/API
Our source: scripts/power_019.lua, scripts/native_wire_probe_026.lua,
scripts/native_wire_geometry_026.lua, prototypes/native_wire_probe_026.lua.
Official ElectricPolePrototype and WireConnectionPoint:
https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html
https://lua-api.factorio.com/latest/types/WireConnectionPoint.html
Official LuaWireConnector: https://lua-api.factorio.com/latest/classes/LuaWireConnector.html
Online docs are 2.1.24 versus game 2.1.20, so native gameplay is the
final arbiter. Vanilla game internals are not publicly available.

## Acceptance
On a save COPY, two SOUTH C masts with /em-25kv-probe start show copper
wire on BOTH triangular hangers, no secondary gray/blue Lua lines,
status 1/1, clear removes wire, old saved 0.1.26 helpers removed
during update. Needs new game screenshots/log. No merge before user QA.
