-- 0.1.26 isolated vanilla copper-wire rendering probe. NOT a 25 kV power model.
-- Invisible connector entities live at projected C-mast arm tips. The normal
-- 0.1.24 masts/rails/Undo/ghosts remain exactly as before.
local anchor = table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
anchor.name = "em-25kv-wire-probe-anchor"
anchor.hidden = true
anchor.flags = {"placeable-off-grid", "not-on-map", "not-blueprintable",
    "not-deconstructable", "get-by-unit-number"}
anchor.minable = nil
anchor.placeable_by = nil
anchor.next_upgrade = nil
anchor.collision_box = {{0,0},{0,0}}
anchor.selection_box = {{0,0},{0,0}}
anchor.collision_mask = {layers={}}
anchor.selectable_in_game = false
anchor.destructible = nil -- EntityPrototype has no destructible property; set at runtime.
anchor.maximum_wire_distance = 16
anchor.supply_area_distance = 0
anchor.auto_connect_up_to_n_wires = 0
anchor.rewire_neighbours_when_destroying = false
anchor.draw_copper_wires = true
anchor.draw_circuit_wires = false
anchor.track_coverage_during_drag_building = false
anchor.active_picture = nil
anchor.radius_visualisation_picture = nil
anchor.pictures = {filename="__core__/graphics/empty.png",
    width=1,height=1,direction_count=1}
-- Exactly one rotated image requires exactly one connection point (2.1.13 lesson).
assert(anchor.connection_points and anchor.connection_points[1],
    "EM 0.1.26 probe needs vanilla electric-pole wire connection point")
anchor.connection_points={table.deepcopy(anchor.connection_points[1])}
-- The hidden entity is located at an arm-tip floor projection.
-- WirePosition vector is relative to hidden helper, in tile coordinates.
-- -2.53125 tiles is approximately -81 pixels at standard game scale.
anchor.connection_points[1].wire.copper={0,-2.53125}
anchor.connection_points[1].shadow.copper={0,0}
data:extend({anchor})
