local empty = "__core__/graphics/empty.png"
local main=table.deepcopy(data.raw.locomotive.locomotive)
main.name="em-c4-real-electric";main.max_power="2MW";main.max_speed=1.2
main.energy_source={type="void"} -- PHYSICS TEST ONLY, production forbidden
local cargo=table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])
cargo.name="em-c4-motor-cargo"
local fluid=table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])
fluid.name="em-c4-motor-fluid"
local ci=table.deepcopy(data.raw['item-with-entity-data']['cargo-wagon']);ci.name='em-c4-motor-cargo';ci.place_result='em-c4-motor-cargo'
local fi=table.deepcopy(data.raw['item-with-entity-data']['fluid-wagon']);fi.name='em-c4-motor-fluid';fi.place_result='em-c4-motor-fluid'
data:extend({main,cargo,fluid,ci,fi,{
 type="fuel-category",name="em-c4-internal-energy"
},{type="item",name="em-c4-internal-joule",hidden=true,icon="__base__/graphics/icons/battery.png",icon_size=64,
 stack_size=1,fuel_categories={"em-c4-internal-energy"},fuel_value="10MJ"
}})
for _,mw in ipairs({500,1000,2000}) do
 local p=table.deepcopy(data.raw.locomotive.locomotive)
 p.name="em-c4-technical-booster-"..mw
 p.max_power=(mw).."kW"
 p.max_speed=1.2;p.weight=1
 p.energy_source={type="burner",fuel_categories={"em-c4-internal-energy"},effectivity=1,fuel_inventory_size=1} -- C4 finite LAB J only
 p.joint_distance=0.1;p.connection_distance=-0.1
 p.collision_box={{-0.2,-0.26},{0.2,0.26}}
 p.selection_box={{-0.2,-0.26},{0.2,0.26}}
 p.selectable_in_game=false
 p.hidden_in_factoriopedia=true
 p.pictures={rotated={filename=empty,width=1,height=1,direction_count=1}}
 p.wheels={rotated={filename=empty,width=1,height=1,direction_count=1}}
 p.front_light=nil;p.front_light_pictures=nil;p.back_light=nil;p.stand_by_light=nil
 p.minimap_representation=nil;p.selected_minimap_representation=nil;p.stop_trigger=nil
 p.minable=nil;p.placeable_by=nil;p.next_upgrade=nil
 p.flags={"placeable-off-grid","not-blueprintable","not-deconstructable","not-on-map"}
 data:extend({p})
end