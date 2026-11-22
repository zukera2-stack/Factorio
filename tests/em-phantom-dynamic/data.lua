local main=table.deepcopy(data.raw.locomotive.locomotive)
main.name="em-traction-real-main"
main.max_power="2MW"
main.energy_source={type="void"} -- native kinematics ONLY, not approved energy source
main.max_speed=1.2
data:extend({main})
local p=table.deepcopy(data.raw.locomotive.locomotive)
p.name="em-invisible-motor-500kw"
p.max_power="500kW"
p.energy_source={type="void"} -- strictly research kinematics, must investigate paid J
p.max_speed=1.2
p.weight=1
p.joint_distance=0.1
p.connection_distance=-0.1
p.collision_box={{-0.2,-0.26},{0.2,0.26}}
p.selection_box={{-0.2,-0.26},{0.2,0.26}}
p.pictures={rotated={filename="__core__/graphics/empty.png",width=1,height=1,direction_count=1}}
p.wheels={rotated={filename="__core__/graphics/empty.png",width=1,height=1,direction_count=1}}
p.front_light=nil
p.front_light_pictures=nil
p.back_light=nil
p.stand_by_light=nil
p.minimap_representation=nil
p.selected_minimap_representation=nil
p.stop_trigger=nil
p.flags={"placeable-neutral","player-creation","placeable-off-grid","not-blueprintable","not-deconstructable","not-on-map"}
p.minable=nil
data:extend({p})