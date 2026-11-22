-- Dedicated test-only prototype; NEVER ships in ElectrifiedMainline ZIP.
-- True Factorio engine ElectricEnergyInterfacePrototype cloned same-type
-- from the real full source bridge input (not a fictional Lua network).
local original=assert(data.raw["electric-energy-interface"]["em-25kv-bridge-input-058"])
local sink=table.deepcopy(original)
sink.name="em068-native-line-consumer-test"
sink.energy_source.buffer_capacity="100kJ"
sink.energy_source.input_flow_limit="2MW"
sink.energy_source.output_flow_limit="0W"
sink.energy_production="0W"
sink.energy_usage="0W"
data:extend{sink}
