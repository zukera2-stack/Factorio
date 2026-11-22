-- EM072-A5 B3 TEST-ONLY entities. NO edits to production catenary prototypes.
local loco=table.deepcopy(data.raw.locomotive['em-electric-locomotive'])
loco.name='em072a5-b0-burner-loco'
loco.energy_source={type='burner',fuel_categories={'em072a5-test'},fuel_inventory_size=1,effectivity=1}
loco.minable=nil;loco.placeable_by=nil
local controller=table.deepcopy(data.raw['electric-pole']['small-electric-pole'])
controller.name='em072a5-b3-outpost-controller'
controller.maximum_wire_distance=0
controller.supply_area_distance=0
controller.auto_connect_up_to_n_wires=0
controller.minable={mining_time=0.2,result=controller.name}
controller.placeable_by={item=controller.name,count=1}
controller.next_upgrade=nil
controller.flags=controller.flags or {}
local has_lookup=false
for _,flag in ipairs(controller.flags) do if flag=='get-by-unit-number' then has_lookup=true end end
if not has_lookup then table.insert(controller.flags,'get-by-unit-number') end
-- Test-only hidden port; no factory-side copper is ever attached to this helper.
local terminal=table.deepcopy(data.raw['electric-pole']['em-25kv-bridge-port-058'])
terminal.name='em072a5-b3-outpost-terminal'
terminal.maximum_wire_distance=0
terminal.supply_area_distance=24
terminal.auto_connect_up_to_n_wires=0
-- Native finite input consumption, engine decides how batteries/EEI share the network.
local meter=table.deepcopy(data.raw['electric-energy-interface']['em-25kv-bridge-input-058'])
meter.name='em072a5-b1-native-traction-meter'
meter.energy_source.buffer_capacity='800000J'
meter.energy_source.input_flow_limit='24MW'
meter.energy_source.output_flow_limit='0W'
meter.energy_source.usage_priority='dynamic'
meter.energy_usage='0W';meter.energy_production='0W'
local factory_meter=table.deepcopy(meter)
factory_meter.name='em072a5-b6-native-factory-load'
factory_meter.energy_source.buffer_capacity='500000J'
factory_meter.energy_source.input_flow_limit='30MW'
factory_meter.energy_source.output_flow_limit='0W'
factory_meter.energy_usage='0W'
factory_meter.energy_production='0W'
data:extend({
 {type='fuel-category',name='em072a5-test'},
 {type='item',name='em072a5-test-token',icon='__base__/graphics/icons/coal.png',icon_size=64,stack_size=1,fuel_categories={'em072a5-test'},fuel_value='100MJ'},
 loco,
 {type='item',name=controller.name,icon='__base__/graphics/icons/small-electric-pole.png',icon_size=64,stack_size=50,place_result=controller.name},
 {type='recipe',name=controller.name,enabled=true,ingredients={{type='item',name='iron-plate',amount=2}},results={{type='item',name=controller.name,amount=1}}},
 controller,terminal,meter,factory_meter
})