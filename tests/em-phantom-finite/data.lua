local main=table.deepcopy(data.raw.locomotive.locomotive)
main.name="em-finite-main-loco"
main.max_power="2MW"
main.energy_source={type="void"}
main.max_speed=1.2
data:extend({main})
data:extend({{type="fuel-category",name="em-phantom-internal-joule"},
  {type="item",name="em-phantom-internal-energy-token",hidden=true,icon="__base__/graphics/icons/battery.png",icon_size=64,stack_size=1, fuel_categories={"em-phantom-internal-joule"}, fuel_value="1MJ"}})
for _,mode in ipairs({"paid","void"}) do
 local p=table.deepcopy(data.raw.locomotive.locomotive)
 p.name="em-phantom-"..mode
 p.max_power="500kW"
 p.weight=1
 p.max_speed=1.2
 p.joint_distance=0.1
 p.connection_distance=-0.1
 p.collision_box={{-0.2,-0.26},{0.2,0.26}}
 p.selection_box={{-0.2,-0.26},{0.2,0.26}}
 p.pictures={rotated={filename="__core__/graphics/empty.png",width=1,height=1,direction_count=1}}
 p.wheels={rotated={filename="__core__/graphics/empty.png",width=1,height=1,direction_count=1}}
 p.front_light=nil;p.front_light_pictures=nil;p.back_light=nil;p.stand_by_light=nil
 p.minimap_representation=nil;p.selected_minimap_representation=nil
 p.stop_trigger=nil;p.minable=nil
 p.flags={"placeable-neutral","player-creation","placeable-off-grid","not-blueprintable","not-deconstructable","not-on-map"}
 if mode=="paid" then
  p.energy_source={type="burner",fuel_categories={"em-phantom-internal-joule"},effectivity=1,fuel_inventory_size=1}
 else p.energy_source={type="void"} end
 data:extend({p})
end