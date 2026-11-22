-- B10R disposable, Base-only rolling stock: only locomotives can have finite battery state.
local loco=table.deepcopy(data.raw.locomotive.locomotive)
loco.name='em-b10r-battery-loco';loco.energy_source={type='burner',fuel_categories={'em-b10r-test'},fuel_inventory_size=1,effectivity=1}
loco.max_power='2MW';loco.minable=nil;loco.placeable_by=nil
local wagon=table.deepcopy(data.raw['cargo-wagon']['cargo-wagon'])
wagon.name='em-b10r-motor-cargo-wagon';wagon.minable=nil;wagon.placeable_by=nil
local tanker=table.deepcopy(data.raw['fluid-wagon']['fluid-wagon'])
tanker.name='em-b10r-motor-fluid-wagon';tanker.minable=nil;tanker.placeable_by=nil
data:extend({
 {type='fuel-category',name='em-b10r-test'},
 {type='item',name='em-b10r-token',icon='__base__/graphics/icons/coal.png',icon_size=64,stack_size=1,fuel_categories={'em-b10r-test'},fuel_value='100MJ'},
 loco,wagon,tanker
})