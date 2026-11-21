-- Isolated native test: driver acceleration on real rail, NEVER LuaTrain.speed writes.
local kinds={"burner","void","empty","physical-fuel"}
local function log_state(t)
 for _,v in ipairs(storage.vehicles or {}) do
  local l=v.loco
  if l.valid then
   local b=l.burner
   log(string.format("[EM072 SNAP] tick=%d kind=%s pos=%.4f,%.4f speed=%.8f train_state=%s manual=%s path=%s burner=%s burning=%s fuel_J=%s inventory=%s driver=%s",t,v.kind,l.position.x,l.position.y,l.train.speed,tostring(l.train.state),tostring(l.train.manual_mode),tostring(l.train.has_path),tostring(b~=nil),tostring(b and b.currently_burning and b.currently_burning.name),tostring(b and b.remaining_burning_fuel),tostring(b and b.inventory and b.inventory.get_item_count("em072-charge")),tostring(l.get_driver())))
  end
 end
end
script.on_init(function() storage.vehicles={} end)
script.on_event(defines.events.on_tick,function(event)
 local t=event.tick
 if t==1 then
  local surf=game.surfaces[1]
  for i,kind in ipairs(kinds) do
   local x=i*48
   local count=0
   for y=-130,130,2 do
    local r=surf.create_entity{name="straight-rail",position={x=x,y=y},direction=defines.direction.north,force="player",raise_built=false}
    if r then count=count+1 end
   end
   local l=surf.create_entity{name="em072-"..kind.."-loco",position={x=x,y=-94},direction=defines.direction.south,force="player",raise_built=false}
   log(string.format("[EM072 SETUP] kind=%s rails=%d locomotive=%s",kind,count,tostring(l~=nil)))
   assert(count==131 and l,"Native rail or locomotive setup failed for "..kind)
   local b=l.burner
   if kind=="burner" then b.currently_burning="em072-charge";b.remaining_burning_fuel=120000 end
   if kind=="physical-fuel" then b.inventory.insert{name="em072-charge",count=1} end
   if kind=="empty" then
    b.remaining_burning_fuel=120000
    assert(b.remaining_burning_fuel==0,"Empty LuaBurner must not accept fuel without currently_burning")
   end
   local tr=l.train;tr.manual_mode=true
   local driver=assert(surf.create_entity{name="character",position={x=x+8,y=-94},force="player"})
   l.set_driver(driver)
   assert(l.get_driver()==driver,"Native dummy driver setup failed")
   driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
   storage.vehicles[#storage.vehicles+1]={kind=kind,loco=l}
  end
 end
 if t==2 or t==3 or t==4 or t==5 or t==6 or t==10 or t==60 or t==120 or t==180 or t==240 or t==360 or t==480 or t==600 then log_state(t) end
 -- EM072_SERVER_SAVE_HOOK
 if t==240 then
  local list={}
  for _,v in ipairs(storage.vehicles) do list[v.kind]=v.loco end
  assert(list.burner and list["physical-fuel"] and list.void and list.empty,"Missing controls")
  assert(math.abs(list.empty.train.speed)<1e-8,"Empty-fuel train moved using free energy")
  assert(list.burner.position.y>-94 and list.burner.position.y< -85,"Finite-burner did not move/coast realistically")
  assert(list.burner.burner.remaining_burning_fuel==0,"Finite fuel not exhausted")
  assert(math.abs(list.burner.position.y-list["physical-fuel"].position.y)<0.001,"Physical fuel disagrees with LuaBurner finite Joule supply")
  assert(list.void.position.y>100,"Void train failed to accelerate")
  log(string.format("[EM072 NATIVE PASS] tick=%d zero_energy_speed=%.8f burner_distance=%.6f physical_distance=%.6f void_distance=%.6f",t,list.empty.train.speed,list.burner.position.y+94,list["physical-fuel"].position.y+94,list.void.position.y+94))
 end
end)
