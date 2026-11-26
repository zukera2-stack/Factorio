-- EM068 ONLY: actual native electrical consumption from the real 25kV
-- contact network, source-paid into genuine Factorio engine native EEl buffers.
-- Inherits exact invisible/collisionless 058 prototype, no player item/recipe.
local original=assert(data.raw["electric-energy-interface"]["em-25kv-bridge-input-058"])
local sink=table.deepcopy(original)
sink.name="em-25kv-native-traction-consumer-068"
sink.energy_source.buffer_capacity="2MJ"
sink.energy_source.input_flow_limit="120MW"
sink.energy_source.output_flow_limit="0W"
sink.energy_production="0W"
sink.energy_usage="0W"
assert(sink.energy_source.usage_priority=="dynamic")
data:extend{sink}
log("[EM068 PROTOTYPE] genuine native 25kV secondary-input EEI sink installed; NO free energy")