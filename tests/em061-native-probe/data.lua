-- Test-only prototype: clone the real Base accumulator, change only electrical limits.
-- Never place this file in ElectrifiedMainline or an install archive.
local p = table.deepcopy(assert(data.raw.accumulator.accumulator))
p.name = "em061-native-gateway-20mw"
p.minable = nil
p.placeable_by = nil
p.energy_source.buffer_capacity = "20MJ"
p.energy_source.input_flow_limit = "20MW"
p.energy_source.output_flow_limit = "20MW"
data:extend({p})
