local loco=table.deepcopy(data.raw.locomotive.locomotive)
loco.name='em-b10-battery-loco'
loco.energy_source={type='burner',fuel_categories={'em-b10-test'},fuel_inventory_size=1,effectivity=1}
loco.max_power='2MW';loco.minable=nil;loco.placeable_by=nil
local wagon=table.deepcopy(data.raw['cargo-wagon']['cargo-wagon'])
wagon.name='em-b10-powered-wagon';wagon.minable=nil;wagon.placeable_by=nil
-- Wagon prototype is NON-PROPELLING in Factorio. It supplies only scripted finite J on this lab bus.
data:extend({
 {type='fuel-category',name='em-b10-test'},
 {type='item',name='em-b10-token',icon='__base__/graphics/icons/coal.png',icon_size=64,stack_size=1,fuel_categories={'em-b10-test'},fuel_value='100MJ'},
 loco,wagon
})