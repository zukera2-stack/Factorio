-- 0.1.28 autonomous 25 kV contact-wire attachment. Not a power supply.
-- Clone the user-proven 0.1.27 invisible pole; retain its exact connector
-- image height (-2.53125) so SOUTH visual attachment is not regressed.
local a=table.deepcopy(data.raw["electric-pole"]["em-25kv-wire-probe-anchor"])
assert(a,"0.1.28 requires 0.1.27 experimental native wire helper")
a.name="em-25kv-contact-anchor"
a.maximum_wire_distance=16
a.auto_connect_up_to_n_wires=0
a.supply_area_distance=0
a.draw_copper_wires=true
a.rewire_neighbours_when_destroying=false
data:extend({a})
