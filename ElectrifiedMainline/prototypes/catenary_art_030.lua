-- The same invisible contact helper serves straight and curved spans.
-- Copper topology remains native; all visible contact lines use 043 sprites.
local h=table.deepcopy(assert(data.raw["electric-pole"]["em-25kv-contact-anchor"]))
h.name="em-25kv-art-anchor-030"
h.draw_copper_wires=false
h.draw_circuit_wires=false
h.maximum_wire_distance=require("scripts.catenary_limits_029").WIRE_REACH
h.auto_connect_up_to_n_wires=0
-- Technical anchor has no native player/engine reach; script checks own 40 tiles.
local t=table.deepcopy(h)
t.name="em-25kv-technical-anchor-046"
t.maximum_wire_distance=0
t.auto_connect_up_to_n_wires=0
t.supply_area_distance=0
t.rewire_neighbours_when_destroying=false
t.connection_points[1].wire.copper={0,0}
local graphics="__ElectrifiedMainline__/graphics/entity/25kv/"
data:extend({
 h,t,
 {type="sprite",name="em-25kv-contact-043",
   filename=graphics.."contact-043.png",width=128,height=10,scale=1,flags={"no-crop"}},
 {type="sprite",name="em-25kv-messenger-043",
   filename=graphics.."messenger-043.png",width=128,height=10,scale=1,flags={"no-crop"}},
 {type="sprite",name="em-25kv-dropper-043",
   filename=graphics.."dropper-043.png",width=10,height=32,scale=1,flags={"no-crop"}},
})
