local locos = {}
local function result(id,fn)
 local success,v=pcall(fn)
 log("POWER_API_PROBE|"..id.."|ok="..tostring(success).."|result="..tostring(v))
 return success,v
end
script.on_event(defines.events.on_tick,function(e)
 if e.tick==2 then
  log("POWER_API_PROBE|version=2.1.24")
  result("runtime_prototype_field_read",function()return tostring(prototypes.entity["em-power-2mw"].max_power)end)
  result("runtime_prototype_field_set",function()prototypes.entity["em-power-2mw"].max_power=3000000;return "wrote" end)
  result("runtime_prototype_field_get3",function()return tostring(prototypes.entity["em-power-3mw"].max_power)end)
  local surface=game.surfaces[1]
  surface.request_to_generate_chunks({20,0},11)
  surface.force_generate_chunk_requests()
  for _,x in ipairs({0,40}) do
   for y=-320,320,2 do
    surface.create_entity{name="straight-rail",position={x=x,y=y},force="player",direction=defines.direction.north}
   end
  end
  for i,name in ipairs({"em-power-2mw","em-power-3mw"}) do
   local x=(i-1)*40
   local loco=surface.create_entity{name=name,position={x=x,y=0},force="player",direction=defines.direction.north}
   log("POWER_API_PROBE|entity_"..name.."_exists="..tostring(loco~=nil))
   if loco then
    locos[i]=loco
    if i==1 then
     result("live_entity_max_power_read",function()return tostring(loco.max_power)end)
     result("live_entity_max_power_set",function()loco.max_power=3000000;return "wrote" end)
     result("live_entity_prototype_power_set",function()loco.prototype.max_power=3000000;return "wrote" end)
     result("live_entity_prototype_replace",function()loco.prototype=prototypes.entity["em-power-3mw"];return "wrote" end)
     log("POWER_API_PROBE|entity_name_after="..tostring(loco.name))
    end
    local driver=surface.create_entity{name="character",position={x=x,y=0},force="player"}
    if driver then
     result("set_driver_"..name,function()loco.set_driver(driver);return "ok" end)
     result("set_acceleration_"..name,function()driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight};return "ok" end)
    end
   end
  end
 end
 if e.tick==60 or e.tick==120 or e.tick==180 then
  for i,loco in pairs(locos) do
   if loco and loco.valid then log("POWER_API_PROBE|motion|tick="..e.tick.."|name="..loco.name.."|y="..string.format("%.6f",loco.position.y).."|speed="..string.format("%.8f",loco.train.speed)) end
  end
 end
end)