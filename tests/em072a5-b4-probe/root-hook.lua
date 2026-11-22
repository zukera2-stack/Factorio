
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