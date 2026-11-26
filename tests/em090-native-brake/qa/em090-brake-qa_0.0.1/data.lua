local prototypes={}
for _,power in ipairs({600,2000,4000}) do
 local p=table.deepcopy(data.raw.locomotive.locomotive)
 p.name='em090-loco-'..power;p.max_power=power..'kW';p.max_speed=2;p.braking_force=20;p.weight=2000;p.friction_force=.5;p.minable=nil;p.placeable_by=nil;p.next_upgrade=nil
 prototypes[#prototypes+1]=p
end
local fuel=table.deepcopy(data.raw.item.coal);fuel.name='em090-finite-fuel';fuel.fuel_value='100MJ';fuel.fuel_acceleration_multiplier=1;fuel.fuel_top_speed_multiplier=1
prototypes[#prototypes+1]=fuel;data:extend(prototypes)
