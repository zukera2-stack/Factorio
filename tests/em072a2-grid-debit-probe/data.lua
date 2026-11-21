local loco=table.deepcopy(data.raw.locomotive["em-electric-locomotive"])
loco.name="em072-grid-burner-loco"
loco.energy_source={type="burner",fuel_categories={"em072-grid-test"},fuel_inventory_size=1,effectivity=1}
loco.minable=nil;loco.placeable_by=nil
data:extend({{type="fuel-category",name="em072-grid-test"},{type="item",name="em072-grid-token",icon="__base__/graphics/icons/coal.png",icon_size=64,stack_size=1,fuel_categories={"em072-grid-test"},fuel_value="10MJ"},loco})
