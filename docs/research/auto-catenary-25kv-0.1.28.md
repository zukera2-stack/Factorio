# 0.1.28 — automatic C-mast native wire, linked ONLY by ВСМ track

Date: 2026-11-16. Branch: experiment/auto-25kv-028.
Base: user-accepted SOUTH native wire 0.1.27, commit faae5d354e760e740dda486e8b2b3d7bad75160e.
Target game: 2.1.20 build 87512. No changes to main 0.1.24.

## Decision / scope
- Display name "Контактная опора 25 кВ" and corresponding substation.
- Legacy prototype IDs em-35kv-* and legacy locale keys deliberately remain so
  installed 0.1.24-0.1.27 masts, blueprint and recipes survive game upgrade.
- No actual electrical 25 kV AC physics, MW transfer or charging yet.
- Each native visible copper wire is between two hidden helper electric poles,
  never directly between existing C-mast entities.
- Auto topology follows *rail-connected* custom HSR only. Pure spatial corridor
  checks are insufficient; every edge must pass connected_rail_path, which
  traverses Rail.get_connected_rail (up to 96 rails) and rejects vanilla rails.
- No wire when no adjacent custom HSR, unrelated adjacent tracks, or too far.
  Helpers only created when a valid approved contact edge exists.
- Native auto-connect disabled and unauthorized player/vanilla connections
  removed at least every 60 ticks. This is not a watertight guarantee during
  the interval or against a hostile mod creating an invisible script-origin link.
- Rail queue scans for affected masts to full SPAN*1.45+RADIUS+2 radius,
  ensuring a deleted midpoint rail 8+ tiles away from both masts still
  recalculates its contact edge and removes native wires.
- Changes are coalesced to one sync after built/removal and rail modifications
  rather than one full scan per robot build event.
- All eight actual 0.1.24 C-arm sprite hanger locations are estimated from
  relative PNG coordinates. SOUTH keeps exact user-approved 0.1.27 offset.
  Seven others need screenshot adjustment. Use /em-25kv-tune FACE DX DY.
- Existing visual rendering.draw_line contact/feeder lines remain disabled.
- On version update the 0.1.27 manual two-helper probe is cleaned and 0.1.28
  auto helper graph is rebuilt, no custom Undo injection.

## API / verification
- Native connector API: https://lua-api.factorio.com/2.1.20/classes/LuaWireConnector.html
- Prototype: https://lua-api.factorio.com/2.1.20/prototypes/ElectricPolePrototype.html
- WireConnections: https://lua-api.factorio.com/2.1.20/concepts/WireConnection.html
- Actual user gameplay validated only 0.1.27 SOUTH anchor, not the auto graph.
- Use main ZIP backup and a copy of ВСМ. See TEST_AUTO_WIRE_028.txt.
