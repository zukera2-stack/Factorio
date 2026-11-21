-- Standalone 2.1.24 native-solver experiment. Does NOT require ElectrifiedMainline.
-- No script ever copies, credits, or debits energy between networks: only test setup and measurements.
local POWER_J_TICK = 10000000 / 60
local function make(surface, name, x, y, opts)
  local arg = {name=name, position={x,y}, force="player", raise_built=false}
  for k,v in pairs(opts or {}) do arg[k]=v end
  local e = surface.create_entity(arg)
  assert(e and e.valid, "[EM061] cannot create "..name.." @"..x..","..y)
  return e
end
local function surface_named(name)
  local s=game.create_surface(name,{width=256,height=128})
  s.generate_with_lab_tiles=true
  s.always_day=true
  s.request_to_generate_chunks({0,0},3)
  s.force_generate_chunk_requests()
  return s
end
local function source(e)
  e.electric_interface_mode=defines.electric_interface_mode.primary_output
  e.electric_buffer_size=200000000
  e.power_production=POWER_J_TICK
  e.power_usage=0
  e.input_flow_limit=0
  e.output_flow_limit=POWER_J_TICK
  e.energy=0
end
local function sink(e)
  e.electric_interface_mode=defines.electric_interface_mode.secondary_input
  e.electric_buffer_size=200000000
  e.power_production=0
  e.power_usage=0
  e.input_flow_limit=POWER_J_TICK
  e.output_flow_limit=0
  e.energy=0
end
local function setup_two()
  local s=surface_named("em061-2-grid")
  local a=make(s,"substation",-8,0,{auto_connect=false})
  local b=make(s,"substation",8,0,{auto_connect=false})
  local left=make(s,"electric-energy-interface",-15,0)
  local right=make(s,"electric-energy-interface",15,0)
  local bridge=make(s,"accumulator",0,0)
  source(left);sink(right);bridge.energy=0
  storage.two={s=s,a=a,b=b,left=left,right=right,bridge=bridge}
end
local function setup_three()
  local s=surface_named("em061-3-grid")
  local a=make(s,"substation",-16,0,{auto_connect=false})
  local b=make(s,"substation",0,0,{auto_connect=false})
  local c=make(s,"substation",16,0,{auto_connect=false})
  local left=make(s,"electric-energy-interface",-24,0)
  local right=make(s,"electric-energy-interface",24,0)
  local g1=make(s,"em061-native-gateway-20mw",-8,0)
  local g2=make(s,"em061-native-gateway-20mw",8,0)
  source(left);sink(right)
  g1.energy=0;g2.energy=0
  storage.three={a=a,b=b,c=c,left=left,right=right,g1=g1,g2=g2}
end
local function networks(e)
  local ids={}
  for _,net in pairs(e.electric_networks or {}) do ids[#ids+1]=tostring(net.id) end
  table.sort(ids)
  return table.concat(ids,",")
end
script.on_event(defines.events.on_tick,function(event)
  if not storage.em061_start then storage.em061_start=event.tick;setup_two() end
  local t=event.tick-storage.em061_start
  local f=storage.two
  if t==60 then
    log("[EM061] 2-net pole IDs A="..tostring(f.a.electric_network_id).." B="..tostring(f.b.electric_network_id).." shared="..networks(f.bridge))
    assert(f.a.electric_network_id and f.b.electric_network_id and f.a.electric_network_id~=f.b.electric_network_id,
      "[EM061] unconnected pole grids were shorted or are missing")
    assert(f.left.electric_network_id==f.a.electric_network_id and f.right.electric_network_id==f.b.electric_network_id,
      "[EM061] source/sink not connected to their respective native pole grids")
  elseif t==300 then
    log("[EM061] vanilla 300kW sink_J="..f.right.energy.." gateway_J="..f.bridge.energy)
    assert(f.right.energy>100000,"[EM061] vanilla accumulator did not transmit power")
    assert(f.right.energy<2200000,"[EM061] vanilla 300kW limit apparently exceeded; inspect native topology")
  elseif t==320 then
    f.bridge.destroy()
    f.bridge=make(f.s,"em061-native-gateway-20mw",0,0)
    f.bridge.energy=0;f.right.energy=0
  elseif t==620 then
    log("[EM061] 20MW prototype A->B delivered_J="..f.right.energy.." gateway_J="..f.bridge.energy)
    assert(f.right.energy>5000000,"[EM061] custom native gateway did not deliver")
    assert(f.a.electric_network_id~=f.b.electric_network_id,"[EM061] custom bridge shorted grids")
  elseif t==640 then
    sink(f.left);source(f.right)
  elseif t==940 then
    log("[EM061] 20MW prototype B->A delivered_J="..f.left.energy.." gateway_J="..f.bridge.energy)
    assert(f.left.energy>5000000,"[EM061] reverse flow failed")
    log("[EM061 TWO-NET PASS] isolated grids, vanilla 300kW cap, custom 20MW prototype, bidirectional native solver")
  elseif t==970 then
    f.left.destroy();f.right.destroy()
    f.bridge.energy=0
    f.battery_a=make(f.s,"accumulator",-15,0)
    f.battery_b=make(f.s,"accumulator",15,0)
    f.battery_a.energy=5000000;f.battery_b.energy=0
  elseif t==1200 then
    log("[EM061 DIAGNOSTIC] battery-only A_J="..f.battery_a.energy.." B_J="..f.battery_b.energy..
      " gateway_J="..f.bridge.energy.." (NO PASS CLAIM)")
  elseif t==1250 then
    setup_three()
  elseif t==1550 then
    local g=storage.three
    log("[EM061 DIAGNOSTIC] 3-net A="..tostring(g.a.electric_network_id)..
      " B="..tostring(g.b.electric_network_id).." C="..tostring(g.c.electric_network_id)..
      " sink_J="..g.right.energy.." gw1_J="..g.g1.energy.." gw2_J="..g.g2.energy..
      " (NO PASS CLAIM)")
    assert(g.a.electric_network_id~=g.b.electric_network_id and g.b.electric_network_id~=g.c.electric_network_id,
      "[EM061] 3-net diagnostic accidentally shorted copper grids")
  end
end)
