-- 0.1.30 straight-specific helper (invisible copper, real topology).
-- The visible 0.1.29 prototype is retained for curved spans only.
local h=table.deepcopy(assert(data.raw["electric-pole"]["em-25kv-contact-anchor"]))
h.name="em-25kv-art-anchor-030"
h.draw_copper_wires=false
h.draw_circuit_wires=false
h.maximum_wire_distance=require("scripts.catenary_limits_029").WIRE_REACH
h.auto_connect_up_to_n_wires=0
local graphics="__ElectrifiedMainline__/graphics/entity/25kv/"
data:extend({
 h,
 {type="sprite",name="em-25kv-contact-030",
   filename=graphics.."contact-030.png",width=128,height=10,scale=1,flags={"no-crop"}},
 {type="sprite",name="em-25kv-messenger-030",
   filename=graphics.."messenger-030.png",width=128,height=10,scale=1,flags={"no-crop"}},
 {type="sprite",name="em-25kv-dropper-030",
   filename=graphics.."dropper-030.png",width=10,height=32,scale=1,flags={"no-crop"}},
})
