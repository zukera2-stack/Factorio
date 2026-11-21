
-- EM072-A5-B0 ephemeral research hook: never merge into gameplay code.
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
 -- Static B0 fixture. Do not reuse this cache when geometry changes in other tests.
 if s.a5_seed_id==seed_id and s.a5_reach then return s.a5_reach end
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
 s.a5_seed_id=seed_id;s.a5_reach=seen;s.a5_builds=(s.a5_builds or 0)+1
 return seen
end
local function qualifies(station_id,loco_id)
 local s=state_b0()
 local r=s.stations[station_id]
 local loco=game.get_entity_by_unit_number(loco_id)
 if not(r and r.mode=="auto" and r.line_port and r.line_port.valid and loco and loco.valid
  and loco.name==B0_TRAIN_NAME and loco.train and loco.train.valid
  and loco.surface.index==r.parent_surface and loco.force.name==r.line_port.force.name
  and r.line_port.electric_network_id) then return false end
 local reach=reach_cache(station_id)
 if not reach then return false end
 for _,rail in pairs(loco.train.get_rails()) do
  if rail.valid and rail.unit_number and reach[rail.unit_number] then return true end
 end
 return false
end
local function batch_take(station_id)
 local s=state_b0();local r=s.stations[station_id]
 if not (r and r.mode=="auto" and r.direction=="import" and r.status=="active"
  and r.output and r.output.valid and r.line_port and r.line_port.valid
  and r.output.electric_network_id and r.output.electric_network_id==r.line_port.electric_network_id) then return {} end
 local request={};local ids={}
 for _,id in ipairs(s.a5_ids or {}) do
  if qualifies(station_id,id) then
   local e=game.get_entity_by_unit_number(id)
   if e and e.valid and e.burner and e.train and e.train.valid then
    request[id]=math.min(2000000/60,math.max(0,100000000-e.burner.remaining_burning_fuel))
    ids[#ids+1]=id
   end
  end
 end
 table.sort(ids)
 local avail=math.max(0,math.min(20000000/60,r.output.energy))
 local budget=avail
 local grants={}
 -- Deterministic max-min fair distribution: at most one station/tick physical debit.
 local pending=ids
 while #pending>0 and budget>0.000001 do
  local slice=budget/#pending
  local next_pending={};local used=0
  for _,id in ipairs(pending) do
   local grant=math.min(slice,request[id]-(grants[id] or 0))
   if grant>0 then grants[id]=(grants[id] or 0)+grant;used=used+grant end
   if request[id]-(grants[id] or 0)>0.000001 then next_pending[#next_pending+1]=id end
  end
  budget=math.max(0,budget-used)
  if used<0.000001 then break end
  pending=next_pending
 end
 local actual={};local spent_total=0
 for _,id in ipairs(ids) do
  local j=grants[id] or 0
  local loco=game.get_entity_by_unit_number(id)
  if j>0 then
   local burner=loco.burner
   if not burner.currently_burning then burner.currently_burning="em072a5-test-token" end
   local old=burner.remaining_burning_fuel
   burner.remaining_burning_fuel=old+j
   local credited=burner.remaining_burning_fuel-old
   assert(credited>=0 and credited<=j+0.01,"Native burner credit mismatch")
   actual[id]=credited
   spent_total=spent_total+credited
  else actual[id]=0 end
 end
 assert(spent_total<=avail+0.01,"Bridge exceeded available real EEI joules")
 r.output.energy=r.output.energy-spent_total
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