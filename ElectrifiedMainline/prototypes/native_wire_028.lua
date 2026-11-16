-- 0.1.28: hidden native copper connectors for mod-owned 35 kV contact wires.
-- Not placeable or blueprintable; only attached by runtime after HSR checks.
local function make(name)
  local p=table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
  p.name=name
  p.hidden=true
  p.flags={"placeable-off-grid","not-on-map","not-blueprintable",
    "not-deconstructable","get-by-unit-number"}
  p.minable=nil;p.placeable_by=nil;p.next_upgrade=nil
  p.collision_box={{0,0},{0,0}}
  p.selection_box={{0,0},{0,0}}
  p.collision_mask={layers={}}
  p.selectable_in_game=false
  p.destructible=nil
  p.maximum_wire_distance=20 -- visible span 16, plus end-point shifts.
  p.supply_area_distance=0
  p.auto_connect_up_to_n_wires=0
  p.rewire_neighbours_when_destroying=false
  p.draw_copper_wires=true
  p.draw_circuit_wires=false
  p.track_coverage_during_drag_building=false
  p.active_picture=nil;p.radius_visualisation_picture=nil
  p.pictures={filename="__core__/graphics/empty.png",
    width=1,height=1,direction_count=1}
  assert(p.connection_points and p.connection_points[1])
  p.connection_points={table.deepcopy(p.connection_points[1])}
  p.connection_points[1].wire.copper={0,-2.53125}
  p.connection_points[1].shadow.copper={0,0}
  return p
end
-- Keep the legacy non-placeable type for safe 0.1.27 save migration.
-- All legacy helpers are destroyed on configuration change.
data:extend({
  make("em-35kv-wire-anchor"),
  make("em-25kv-wire-probe-anchor")
})
