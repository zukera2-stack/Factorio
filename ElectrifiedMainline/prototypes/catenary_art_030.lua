-- The same invisible contact helper serves straight and curved spans.
-- Copper topology remains native; all visible contact lines use 043 sprites.
local h=table.deepcopy(assert(data.raw["electric-pole"]["em-25kv-contact-anchor"]))
h.name="em-25kv-art-anchor-030"
h.draw_copper_wires=false
h.draw_circuit_wires=false
h.maximum_wire_distance=require("scripts.catenary_limits_029").WIRE_REACH
h.auto_connect_up_to_n_wires=0
local graphics="__ElectrifiedMainline__/graphics/entity/25kv/"
data:extend({
 h,
 {type="sprite",name="em-25kv-contact-043",
   filename=graphics.."contact-043.png",width=128,height=10,scale=1,flags={"no-crop"}},
 {type="sprite",name="em-25kv-messenger-043",
   filename=graphics.."messenger-043.png",width=128,height=10,scale=1,flags={"no-crop"}},
 {type="sprite",name="em-25kv-dropper-043",
   filename=graphics.."dropper-043.png",width=10,height=32,scale=1,flags={"no-crop"}},
})
