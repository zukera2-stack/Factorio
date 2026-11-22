
-- EM072-A5-B4 ephemeral rail-change and owner-lifecycle research only; never merge into gameplay code.
local B0_TRAIN_NAME="em072a5-b0-burner-loco"
local HSR={ ["em-high-speed-straight-rail"]=true,
 ["em-half-diagonal-high-speed-rail"]=true,
 ["em-curved-high-speed-rail"]=true,
 ["em-curved-high-speed-rail-b"]=true }
local function state_b0()
 local s=storage.em and storage.em.bridge058
 assert(s and s.stations,"EM070 storage not initialized")
 return s
end
local function reach_cache(station_id)
 local s=state_b0()
 local mast_id=s.feeders and s.feeders[station_id]
 local mast=mast_id and game.get_entity_by_unit_number(mast_id)
 local power=storage.em and storage.em.power_019
 local tech=storage.em and storage.em.technical_046
 if not(mast and mast.valid and power and power.nodes and power.nodes[mast_id]
   and tech and tech.components and tech.components[mast_id] and tech.mast_connected and tech.mast_connected[mast_id]) then return nil end
 local seed_id=power.nodes[mast_id].rail_id
 if not seed_id then return nil end
 local p=mast.position
 local nearby=mast.surface.find_entities_filtered{position=p,radius=7,type={"straight-rail","half-diagonal-rail","curved-rail-a","curved-rail-b"}}
 local seed=nil
 for _,e in pairs(nearby) do if e.valid and e.unit_number==seed_id and HSR[e.name] then seed=e;break end end
 if not seed then return nil end
 -- B4 cache is bounded, invalidated on native rail edit and technical generation.
 if s.a5_seed_id==seed_id and s.a5_reach and s.a5_reach_generation==tech.sync_generation then return s.a5_reach end
 local queue={seed};local seen={[seed.unit_number]=true};local idx=1
 local directions={defines.rail_direction.front,defines.rail_direction.back}
 local branches={defines.rail_connection_direction.straight,defines.rail_connection_direction.left,defines.rail_connection_direction.right}
 while idx<=#queue and idx<=4096 do
  local rail=queue[idx];idx=idx+1
  for _,d in ipairs(directions) do for _,a in ipairs(branches) do
   local next_rail=rail.get_connected_rail{rail_direction=d,rail_connection_direction=a}
   if next_rail and next_rail.valid and HSR[next_rail.name]
     and next_rail.surface.index==seed.surface.index and next_rail.force.name==seed.force.name
     and next_rail.unit_number and not seen[next_rail.unit_number] then
    seen[next_rail.unit_number]=true
    queue[#queue+1]=next_rail
   end
  end end
 end
 if idx<=#queue then return nil end -- FAIL CLOSED when traversal exceeds bound
 s.a5_seed_id=seed_id;s.a5_reach=seen;s.a5_reach_generation=tech.sync_generation;s.a5_builds=(s.a5_builds or 0)+1
 return seen
end
-- Require an owned, physically connected terminal for every burner credit. A dangling
-- meter with native stored Joules is NOT a valid train feed once controller is mined.
local function terminal_owned()
 local s=storage.em and storage.em.bridge058
 local t=storage.em and storage.em.technical_046
 if not (s and t and s.a5_b3_controller_id and s.a5_b3_terminal_id and s.a5_b3_mast_id) then return false end
 local c=game.get_entity_by_unit_number(s.a5_b3_controller_id)
 local p=game.get_entity_by_unit_number(s.a5_b3_terminal_id)
 local mast=game.get_entity_by_unit_number(s.a5_b3_mast_id)
 local a_id=t.helpers and t.helpers[s.a5_b3_mast_id]
 local anchor=a_id and game.get_entity_by_unit_number(a_id)
 if not (c and c.valid and p and p.valid and mast and mast.valid and anchor and anchor.valid
  and c.force==p.force and c.surface==p.surface and p.force==mast.force and p.surface==mast.surface
  and t.bridge_ports and t.bridge_ports[p.unit_number]==anchor.unit_number) then return false end
 local pc=p.get_wire_connector(defines.wire_connector_id.pole_copper,false)
 local ac=anchor.get_wire_connector(defines.wire_connector_id.pole_copper,false)
 return pc and ac and pc.is_connected_to(ac,defines.wire_origin.script) or false
end
local function qualifies(station_id,loco_id)
 local s=state_b0()
 if not terminal_owned() then return false end
 local mast_id=s.feeders and s.feeders[station_id]
 local mast=mast_id and game.get_entity_by_unit_number(mast_id)
 local tech=storage.em and storage.em.technical_046
 local loco=game.get_entity_by_unit_number(loco_id)
 local meter=s.a5_meter and game.get_entity_by_unit_number(s.a5_meter)
 if not(mast and mast.valid and tech and tech.components and tech.components[mast_id]
  and tech.mast_connected and tech.mast_connected[mast_id]
  and loco and loco.valid and loco.name==B0_TRAIN_NAME and loco.train and loco.train.valid
  and loco.surface.index==mast.surface.index and loco.force.name==mast.force.name
  and meter and meter.valid and meter.electric_network_id and meter.electric_network_id==mast.electric_network_id) then return false end
 local reach=reach_cache(station_id)
 if not reach then return false end
 for _,rail in pairs(loco.train.get_rails()) do
  if rail.valid and rail.unit_number and reach[rail.unit_number] then return true end
 end
 return false
end
local function batch_take(station_id)
 local s=state_b0()
 local meter=s.a5_meter and game.get_entity_by_unit_number(s.a5_meter)
 if not(meter and meter.valid and meter.name=='em072a5-b1-native-traction-meter') then return {} end
 local request={};local ids={}
 for _,id in ipairs(s.a5_ids or {}) do
  if qualifies(station_id,id) then
   local e=game.get_entity_by_unit_number(id)
   if e and e.valid and e.burner and e.train and e.train.valid then
    request[id]=math.min(2000000/60, math.max(0,100000000-e.burner.remaining_burning_fuel))
    ids[#ids+1]=id
   end
  end
 end
 table.sort(ids)
 local initial=math.max(0,meter.energy)
 local budget=math.min(24000000/60,initial)
 local grants={};local pending=ids
 while #pending>0 and budget>0.000001 do
  local slice=budget/#pending;local next_pending={};local used=0
  for _,id in ipairs(pending) do
   local delta=math.min(slice,request[id]-(grants[id] or 0))
   if delta>0 then grants[id]=(grants[id] or 0)+delta;used=used+delta end
   if request[id]-(grants[id] or 0)>0.000001 then next_pending[#next_pending+1]=id end
  end
  budget=math.max(0,budget-used)
  if used<0.000001 then break end
  pending=next_pending
 end
 local actual={};local given=0
 for _,id in ipairs(ids) do
  local j=grants[id] or 0
  local loco=game.get_entity_by_unit_number(id)
  if j>0 then
   local burner=loco.burner
   if not burner.currently_burning then burner.currently_burning='em072a5-test-token' end
   local start=burner.remaining_burning_fuel
   burner.remaining_burning_fuel=start+j
   local credited=burner.remaining_burning_fuel-start
   assert(credited>=0 and credited<=j+0.01,'native burner credit mismatch')
   actual[id]=credited;given=given+credited
  else actual[id]=0 end
 end
 assert(given<=initial+0.01,'meter overspent native available joules')
 meter.energy=meter.energy-given
 return actual
end

remote.add_interface("em072a5_b0_native",{
 register=function(ids)
  local s=state_b0()
  assert(type(ids)=="table" and #ids==12,"exactly 12 locomotive IDs required")
  local seen={}
  for _,id in ipairs(ids) do assert(type(id)=="number" and not seen[id],"duplicate native locomotive");seen[id]=true end
  s.a5_ids=ids;s.dirty=true;return true
 end,
 meter_register=function(id)
   local s=state_b0();local e=game.get_entity_by_unit_number(id)
   assert(e and e.valid and e.name=='em072a5-b1-native-traction-meter')
   s.a5_meter=id;return true
 end,
 set_off=function(id)
   local s=state_b0();local r=s.stations[id];assert(r)
   r.mode='off';s.dirty=true;return true
 end,
 qualifies=function(station_id,loco_id) return qualifies(station_id,loco_id) end,
 take_all=function(station_id) return batch_take(station_id) end,
 balances=function(station_id)
  local s=state_b0();local r=s.stations[station_id]
  if not r then return {} end
  return {status=r.status,mode=r.mode,direction=r.direction,
   input=r.input and r.input.valid and r.input.energy or 0,
   output=r.output and r.output.valid and r.output.energy or 0,
   factory=r.factory_port and r.factory_port.valid and r.factory_port.electric_network_id,
   line=r.line_port and r.line_port.valid and r.line_port.electric_network_id,
   planned=r.planned_mw or 0,cache_builds=s.a5_builds or 0}
 end
})

-- EM072-A5-B3 laboratory script-owned terminal; no stock mast supply-area changes.
remote.add_interface('em072a5_b3_terminal',{
 detach=function(controller_id)
  local s=state_b0()
  local t=storage.em and storage.em.technical_046
  if not (t and s.a5_b3_controller_id==controller_id) then return false end
  local port=s.a5_b3_terminal_id and game.get_entity_by_unit_number(s.a5_b3_terminal_id)
  if port and port.valid then
   if t.bridge_ports then t.bridge_ports[port.unit_number]=nil end
   port.destroy{raise_destroy=false}
  end
  s.a5_b3_terminal_id=nil;s.a5_b3_controller_id=nil;s.a5_b3_mast_id=nil
  s.a5_reach=nil;s.a5_seed_id=nil
  log('[EM072A5 B4 DETACH EVENT] t='..game.tick..' removed owned port; no train access')
  return true
 end,
 enable_demand=function()local s=state_b0();s.a5_b3_enable_demand=true;s.dirty=true;return true end,
 attach=function(controller_id,mast_id)
  local s=storage.em and storage.em.bridge058
  local t=storage.em and storage.em.technical_046
  local controller=game.get_entity_by_unit_number(controller_id)
  local mast=game.get_entity_by_unit_number(mast_id)
  if not(s and t and controller and controller.valid and controller.name=='em072a5-b3-outpost-controller'
    and mast and mast.valid and (mast.name=='em-35kv-catenary-pole-north' or mast.name=='em-35kv-catenary-pole')
    and controller.surface.index==mast.surface.index and controller.force.name==mast.force.name
    and t.components and t.components[mast_id] and t.mast_connected and t.mast_connected[mast_id]) then
    log('[EM072A5 B3 ATTACH REJECT] t='..game.tick..' mast='..tostring(mast and mast.name)..' ctrl='..tostring(controller and controller.name)..' components='..tostring(t and t.components and t.components[mast_id])..' mast_connected='..tostring(t and t.mast_connected and t.mast_connected[mast_id])..' helper='..tostring(t and t.helpers and t.helpers[mast_id]))
    return false end
  local dx,dy=controller.position.x-mast.position.x,controller.position.y-mast.position.y
  if dx*dx+dy*dy>20*20 then log('[EM072A5 B3 ATTACH REJECT] distance='..(dx*dx+dy*dy));return false end
  if s.a5_b3_terminal_id then log('[EM072A5 B3 ATTACH REJECT] duplicate');return false end -- one terminal per pilot, fail closed
  local helper_id=t.helpers and t.helpers[mast_id]
  local anchor=helper_id and game.get_entity_by_unit_number(helper_id)
  if not(anchor and anchor.valid and anchor.name=='em-25kv-technical-anchor-046') then log('[EM072A5 B3 ATTACH REJECT] no anchor');return false end
  local port=controller.surface.create_entity{name='em072a5-b3-outpost-terminal',position=controller.position,
    force=controller.force,auto_connect=false,raise_built=false,create_build_effect_smoke=false}
  if not(port and port.valid and port.unit_number) then return false end
  port.destructible=false
  local ac=anchor.get_wire_connector(defines.wire_connector_id.pole_copper,true)
  local pc=port.get_wire_connector(defines.wire_connector_id.pole_copper,true)
  local origin=defines.wire_origin.script
  -- Whitelist first: technical_046 audit removes any unregistered or player-origin copper.
  t.bridge_ports=t.bridge_ports or {};t.bridge_ports[port.unit_number]=anchor.unit_number
  local ok,res=pcall(function()return ac and pc and ac.connect_to(pc,false,origin) end)
  if not(ok and res) then log('[EM072A5 B3 ATTACH REJECT] copper connect failure '..tostring(res));t.bridge_ports[port.unit_number]=nil;port.destroy();return false end
  s.a5_b3_terminal_id=port.unit_number;s.a5_b3_controller_id=controller_id;s.a5_b3_mast_id=mast_id
  return true
 end,
 status=function()
  local s=storage.em and storage.em.bridge058
  local t=storage.em and storage.em.technical_046
  local port=s and s.a5_b3_terminal_id and game.get_entity_by_unit_number(s.a5_b3_terminal_id)
  local anchor=t and s and s.a5_b3_mast_id and t.helpers[s.a5_b3_mast_id]
    and game.get_entity_by_unit_number(t.helpers[s.a5_b3_mast_id])
  local cc=port and port.valid and port.get_wire_connector(defines.wire_connector_id.pole_copper,false)
  local ac=anchor and anchor.valid and anchor.get_wire_connector(defines.wire_connector_id.pole_copper,false)
  return {valid=port and port.valid or false,network=port and port.valid and port.electric_network_id or nil,
    authorized=port and anchor and t and t.bridge_ports[port.unit_number]==anchor.unit_number or false,
    attached=cc and ac and cc.is_connected_to(ac,defines.wire_origin.script) or false,
    controller=s and s.a5_b3_controller_id or nil}
 end
})

-- EM072-A5 B5 additional physically separate battery corridor.
-- No station 2: this *only* proves independence of two real HSR/copper/battery
-- components when one station is OFF. A full dual-EM070 dispatcher is NOT tested.
local function b5_s()return state_b0()end
local function b5_auth()
 local s=b5_s();local t=storage.em and storage.em.technical_046
 local c=s.b5_controller and game.get_entity_by_unit_number(s.b5_controller)
 local port=s.b5_port and game.get_entity_by_unit_number(s.b5_port)
 local mast=s.b5_mast and game.get_entity_by_unit_number(s.b5_mast)
 local meter=s.b5_meter and game.get_entity_by_unit_number(s.b5_meter)
 local anchorid=t and t.helpers and s.b5_mast and t.helpers[s.b5_mast]
 local anchor=anchorid and game.get_entity_by_unit_number(anchorid)
 if not(c and c.valid and c.name=='em072a5-b3-outpost-controller' and port and port.valid
   and mast and mast.valid and meter and meter.valid and anchor and anchor.valid
   and c.surface==port.surface and port.surface==mast.surface and mast.surface==meter.surface
   and c.force==port.force and port.force==mast.force and mast.force==meter.force
   and t.bridge_ports and t.bridge_ports[port.unit_number]==anchor.unit_number
   and t.components and t.components[mast.unit_number] and t.mast_connected[mast.unit_number]
   and mast.electric_network_id and meter.electric_network_id==mast.electric_network_id
   and port.electric_network_id==mast.electric_network_id) then return false end
 local pc=port.get_wire_connector(defines.wire_connector_id.pole_copper,false)
 local ac=anchor.get_wire_connector(defines.wire_connector_id.pole_copper,false)
 return pc and ac and pc.is_connected_to(ac,defines.wire_origin.script) or false
end
local function b5_reach()
 local s=b5_s();local t=storage.em.technical_046;local power=storage.em.power_019
 local mast=s.b5_mast and game.get_entity_by_unit_number(s.b5_mast)
 local seedid=mast and power.nodes and power.nodes[mast.unit_number] and power.nodes[mast.unit_number].rail_id
 if not seedid then return nil end
 if s.b5_reach and s.b5_seed==seedid and s.b5_generation==t.sync_generation then return s.b5_reach end
 local nearby=mast.surface.find_entities_filtered{position=mast.position,radius=7,type={'straight-rail','half-diagonal-rail','curved-rail-a','curved-rail-b'}}
 local seed=nil;for _,e in pairs(nearby) do if e.valid and e.unit_number==seedid and HSR[e.name] then seed=e;break end end
 if not seed then return nil end
 local queue={seed};local seen={[seed.unit_number]=true};local i=1
 local ds={defines.rail_direction.front,defines.rail_direction.back}
 local turns={defines.rail_connection_direction.straight,defines.rail_connection_direction.left,defines.rail_connection_direction.right}
 while i<=#queue and i<=4096 do
  local rail=queue[i];i=i+1
  for _,d in ipairs(ds) do for _,turn in ipairs(turns) do
   local n=rail.get_connected_rail{rail_direction=d,rail_connection_direction=turn}
   if n and n.valid and n.unit_number and HSR[n.name] and n.surface==seed.surface and n.force==seed.force
      and not seen[n.unit_number] then seen[n.unit_number]=true;queue[#queue+1]=n end
  end end
 end
 if i<=#queue then return nil end -- fail closed on large networks
 s.b5_reach=seen;s.b5_seed=seedid;s.b5_generation=t.sync_generation;s.b5_builds=(s.b5_builds or 0)+1
 return seen
end
local function b5_qualifies(id)
 if not b5_auth() then return false end
 local s=b5_s();local e=game.get_entity_by_unit_number(id)
 local mast=game.get_entity_by_unit_number(s.b5_mast)
 if not(e and e.valid and e.name==B0_TRAIN_NAME and e.train and e.train.valid
  and e.surface==mast.surface and e.force==mast.force) then return false end
 local reach=b5_reach();if not reach then return false end
 for _,r in pairs(e.train.get_rails()) do if r.valid and r.unit_number and reach[r.unit_number] then return true end end
 return false
end
local function b5_take()
 local s=b5_s();local meter=s.b5_meter and game.get_entity_by_unit_number(s.b5_meter)
 if not(meter and meter.valid) then return {} end
 local ids={};for _,id in ipairs(s.b5_ids or {}) do if b5_qualifies(id) then ids[#ids+1]=id end end
 table.sort(ids)
 local left=math.min(math.max(0,meter.energy),#ids*2000000/60)
 local actual={};local total=0
 if #ids>0 and left>0 then
  local per=left/#ids
  for _,id in ipairs(ids) do
   local loco=game.get_entity_by_unit_number(id);local burner=loco.burner
   local j=math.min(per,math.max(0,100000000-burner.remaining_burning_fuel))
   if j>0 then
    if not burner.currently_burning then burner.currently_burning='em072a5-test-token' end
    local before=burner.remaining_burning_fuel
    burner.remaining_burning_fuel=before+j
    local credited=burner.remaining_burning_fuel-before
    assert(credited>=-0.01 and credited<=j+0.01)
    actual[id]=credited;total=total+credited
   end
  end
 end
 assert(total<=meter.energy+0.01,'b5 secondary network free J')
 meter.energy=meter.energy-total
 return actual
end
remote.add_interface('em072a5_b5_secondary',{
 register=function(ids,meterid)
  local s=b5_s();assert(type(ids)=='table' and #ids==4)
  local e=game.get_entity_by_unit_number(meterid);assert(e and e.valid and e.name=='em072a5-b1-native-traction-meter')
  s.b5_ids=ids;s.b5_meter=meterid;return true
 end,
 attach=function(controllerid,mastid)
  local s=b5_s();local t=storage.em.technical_046
  local c=game.get_entity_by_unit_number(controllerid);local m=game.get_entity_by_unit_number(mastid)
  if not(c and c.valid and c.name=='em072a5-b3-outpost-controller' and m and m.valid
    and (m.name=='em-35kv-catenary-pole-north' or m.name=='em-35kv-catenary-pole')
    and c.force==m.force and c.surface==m.surface and t.components and t.components[mastid]
    and t.mast_connected[mastid]) then return false end
  local id=t.helpers and t.helpers[mastid];local anchor=id and game.get_entity_by_unit_number(id)
  if not(anchor and anchor.valid and anchor.name=='em-25kv-technical-anchor-046') then return false end
  local dx=c.position.x-m.position.x;local dy=c.position.y-m.position.y
  if dx*dx+dy*dy>24*24 then return false end
  if s.b5_controller or s.b5_port then return false end
  local port=c.surface.create_entity{name='em072a5-b3-outpost-terminal',position=c.position,force=c.force,auto_connect=false,raise_built=false}
  if not(port and port.valid) then return false end
  port.destructible=false
  local pc=port.get_wire_connector(defines.wire_connector_id.pole_copper,true)
  local ac=anchor.get_wire_connector(defines.wire_connector_id.pole_copper,true)
  t.bridge_ports=t.bridge_ports or {};t.bridge_ports[port.unit_number]=anchor.unit_number
  local ok,res=pcall(function()return pc and ac and ac.connect_to(pc,false,defines.wire_origin.script) end)
  if not(ok and res) then t.bridge_ports[port.unit_number]=nil;port.destroy();return false end
  s.b5_controller=controllerid;s.b5_port=port.unit_number;s.b5_mast=mastid
  s.b5_reach=nil;return b5_auth()
 end,
 detach=function(id)
  local s=b5_s();if not(s.b5_controller and s.b5_controller==id) then return false end
  local t=storage.em.technical_046
  local e=s.b5_port and game.get_entity_by_unit_number(s.b5_port)
  if e and e.valid then t.bridge_ports[e.unit_number]=nil;e.destroy{raise_destroy=false} end
  s.b5_controller=nil;s.b5_port=nil;s.b5_mast=nil;s.b5_reach=nil
  return true
 end,
 qualifies=b5_qualifies,
 take=b5_take,
 status=function()
  local s=b5_s();local e=s.b5_meter and game.get_entity_by_unit_number(s.b5_meter)
  return {authorized=b5_auth(),network=e and e.valid and e.electric_network_id or nil,
   meter_j=e and e.valid and e.energy or 0,cache_builds=s.b5_builds or 0}
 end
})

-- B6: strictly TEST-ONLY second native EM070 registration/status.
remote.add_interface('em072a5_b6_station',{
 register=function(id)
  local s=state_b0();local e=game.get_entity_by_unit_number(id)
  assert(e and e.valid and e.name=='em-35kv-traction-substation')
  s.b6_secondary_station_id=id;s.dirty=true;return true
 end,
 enable_secondary=function()
  local s=state_b0();assert(s.b6_secondary_station_id and s.stations[s.b6_secondary_station_id])
  s.b6_enable_secondary_demand=true;s.dirty=true;return true
 end,
 status=function()
  local s=state_b0();local r=s.stations[s.b6_secondary_station_id]
  return {mode=r and r.mode or 'unknown',status=r and r.status or 'missing',
    planned=r and r.planned_mw or 0,direction=r and r.direction or 'none',
    factory=r and r.factory_port and r.factory_port.valid and r.factory_port.electric_network_id or nil,
    corridor=r and r.line_port and r.line_port.valid and r.line_port.electric_network_id or nil,
    b7_actual_import_j=r and r.b7_actual_transfer_j or 0,
    b7_pre_brownout_import_j=r and r.b7_pre_brownout_transfer_j or 0,
    b7_peak_actual_mw=r and r.b7_peak_actual_mw or 0}
 end
})