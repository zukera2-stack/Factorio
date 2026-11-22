-- Disposable Base-only native comparison: passive wagon vs renamed motor-marked wagon,
-- and a separate *locomotive fuel acceleration multiplier* counterfactual.
local loco=table.deepcopy(data.raw.locomotive.locomotive)
loco.name='em-c-loco';loco.minable=nil;loco.placeable_by=nil
loco.max_power='2MW';loco.energy_source={type='burner',fuel_categories={'em-c-fuel'},fuel_inventory_size=1,effectivity=1}
local cargo_passive=table.deepcopy(data.raw['cargo-wagon']['cargo-wagon']); cargo_passive.name='em-c-passive-cargo'
local fluid_passive=table.deepcopy(data.raw['fluid-wagon']['fluid-wagon']); fluid_passive.name='em-c-passive-fluid'
local cargo_motor=table.deepcopy(data.raw['cargo-wagon']['cargo-wagon']); cargo_motor.name='em-c-motor-cargo'
local fluid_motor=table.deepcopy(data.raw['fluid-wagon']['fluid-wagon']); fluid_motor.name='em-c-motor-fluid'
for _,stock in ipairs({cargo_passive,fluid_passive,cargo_motor,fluid_motor}) do stock.minable=nil;stock.placeable_by=nil end
local function item(name,mul)
 return {type='item',name=name,icon='__base__/graphics/icons/coal.png',icon_size=64,stack_size=1,fuel_categories={'em-c-fuel'},fuel_value='100MJ',fuel_acceleration_multiplier=mul,fuel_top_speed_multiplier=1}
end
data:extend({{type='fuel-category',name='em-c-fuel'},item('em-c-fuel-plain',1),item('em-c-fuel-boost',1.25),loco,cargo_passive,fluid_passive,cargo_motor,fluid_motor})