-- EM072-A disposable, Base-only; never put this fuel into released game without debiting EM070.
local base=assert(data.raw.locomotive.locomotive)
local entries={}
for _,kind in ipairs({"burner","void","empty","physical-fuel"}) do
 local l=table.deepcopy(base)
 l.name="em072-"..kind.."-loco"
 l.max_power="2MW";l.max_speed=2.0;l.weight=2000
 l.minable=nil;l.placeable_by=nil
 if kind=="void" then l.energy_source={type="void"}
 else l.energy_source={type="burner",fuel_categories={"em072-test-charge"},fuel_inventory_size=1,effectivity=1} end
 entries[#entries+1]=l
end
entries[#entries+1]={type="fuel-category",name="em072-test-charge"}
entries[#entries+1]={type="item",name="em072-charge",icon="__base__/graphics/icons/coal.png",icon_size=64,stack_size=1,fuel_categories={"em072-test-charge"},fuel_value="120kJ",fuel_acceleration_multiplier=1.0,fuel_top_speed_multiplier=1.0}
data:extend(entries)
