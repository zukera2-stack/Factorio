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