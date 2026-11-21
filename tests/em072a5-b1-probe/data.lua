-- Only the throwaway QA mod gets a native burner locomotive clone.
local loco=table.deepcopy(data.raw.locomotive["em-electric-locomotive"])
loco.name="em072a5-b0-burner-loco"
loco.energy_source={type="burner",fuel_categories={"em072a5-test"},fuel_inventory_size=1,effectivity=1}
loco.minable=nil
loco.placeable_by=nil
data:extend({
 {type="fuel-category",name="em072a5-test"},
 {type="item",name="em072a5-test-token",icon="__base__/graphics/icons/coal.png",icon_size=64,stack_size=1,fuel_categories={"em072a5-test"},fuel_value="100MJ"},
 loco
})

-- A5-B1 test-only prototype: load-bearing native EEI, not a generator.
local mast=data.raw['electric-pole']['em-35kv-catenary-pole-north']
assert(mast and mast.maximum_wire_distance==0 and mast.supply_area_distance==0)
mast.supply_area_distance=30 -- TEST ONLY: proves native local corridor participation, NOT approved gameplay terminal
local meter=table.deepcopy(data.raw['electric-energy-interface']['em-25kv-bridge-input-058'])
meter.name='em072a5-b1-native-traction-meter'
meter.energy_source.buffer_capacity='800000J'
meter.energy_source.input_flow_limit='24MW'
meter.energy_source.output_flow_limit='0W'
meter.energy_source.usage_priority='dynamic'
meter.energy_usage='0W';meter.energy_production='0W'
data:extend({meter})