
-- EM072-A2 DISPOSABLE TEST HOOK; not present in GitHub ElectrifiedMainline main.
-- EM072-A3 disposable strict rail-path and native power-component qualification.
local function em072a3_qualifies(station_id,loco_id)
  local bridge=storage.em and storage.em.bridge058
  local power=storage.em and storage.em.power_019
  local tech=storage.em and storage.em.technical_046
  local r=bridge and bridge.stations and bridge.stations[station_id]
  local mast_id=bridge and bridge.feeders and bridge.feeders[station_id]
  local mast= mast_id and game.get_entity_by_unit_number(mast_id)
  local loco=game.get_entity_by_unit_number(loco_id)
  if not(bridge and bridge.em072a3_loco_id==loco_id and r and r.mode=="auto" and r.line_port and r.line_port.valid and loco and loco.valid
      and loco.name=="em072-grid-burner-loco" and loco.train and loco.train.valid
      and mast and mast.valid and power and tech and tech.components
      and tech.components[mast_id] and tech.mast_connected and tech.mast_connected[mast_id]) then return false end
  if not(loco.surface.index==mast.surface.index and loco.force.name==mast.force.name
    and r.parent_surface==loco.surface.index and r.line_port.electric_network_id
    and r.line_port.electric_network_id==mast.electric_network_id) then return false end
  -- The feeder itself must be a verified existing HSR-connected mast, not just a pole.
  local root=power.nodes and power.nodes[mast_id]
  local target_id=root and root.rail_adjacent and root.rail_id
  if not target_id then return false end
  local rail_names={"em-high-speed-straight-rail","em-half-diagonal-high-speed-rail","em-curved-high-speed-rail","em-curved-high-speed-rail-b"}
  local tracks=loco.surface.find_entities_filtered{position=loco.position,radius=6,name=rail_names,force=loco.force}
  local closest=nil;local best=math.huge
  for _,rail in pairs(tracks) do
    local dx=rail.position.x-loco.position.x;local dy=rail.position.y-loco.position.y
    local d=dx*dx+dy*dy
    if rail.valid and d<best then closest=rail;best=d end
  end
  if not closest or best>36 then return false end
  -- Bounded real rail-connection BFS; never crosses rail intersections merely by proximity.
  local queue={closest};local seen={[closest.unit_number]=true};local i=1
  local valid_name={};for _,n in ipairs(rail_names) do valid_name[n]=true end
  local directions={defines.rail_direction.front,defines.rail_direction.back}
  local turns={defines.rail_connection_direction.straight,defines.rail_connection_direction.left,defines.rail_connection_direction.right}
  while i<=#queue and i<=512 do
    local item=queue[i];i=i+1
    if item.unit_number==target_id then return true end
    for _,d in ipairs(directions) do
      for _,turn in ipairs(turns) do
        local rail=item.get_connected_rail{rail_direction=d,rail_connection_direction=turn}
        if rail and rail.valid and rail.unit_number and not seen[rail.unit_number] and valid_name[rail.name]
          and rail.force.name==loco.force.name and rail.surface.index==loco.surface.index then
          seen[rail.unit_number]=true;queue[#queue+1]=rail
        end
      end
    end
  end
  return false
end
remote.add_interface("em072a2_native_probe",{
 mode=function(id)
  local s=storage.em and storage.em.bridge058
  assert(s and s.stations,"EM070 storage missing")
  local r=s.stations[id]
  if not r then r={};s.stations[id]=r end
  r.mode="auto";r.status="waiting";s.dirty=true
  return true
 end,
 qualifies=function(id,loco_id) return em072a3_qualifies(id,loco_id) end,
 unregister=function() storage.em.bridge058.em072a3_loco_id=nil;return true end,
 register=function(loco_id)
  local s=storage.em.bridge058;s.em072a3_loco_id=loco_id
  return true
 end,
 take=function(id,loco_id,max_j)
  local s=storage.em and storage.em.bridge058
  local r=s and s.stations[id]
  local loco=game.get_entity_by_unit_number(loco_id)
  if not(r and r.mode=="auto" and r.direction=="import" and r.status=="active" and r.output and r.output.valid and r.line_port and r.line_port.valid) then return 0 end
  if not (r.output.electric_network_id==r.line_port.electric_network_id) then return 0 end
  if not(loco and loco.valid and loco.name=="em072-grid-burner-loco") then return 0 end
  if not (loco.force.name==r.line_port.force.name and loco.surface.index==r.parent_surface) then return 0 end
  if not em072a3_qualifies(id,loco_id) then return 0 end
  -- Negative control: even on the same surface/force, vanilla rails are not catenary.
  local seen_hsr=false
  for _,rail in pairs(loco.train.get_rails()) do
   if rail and rail.valid and (rail.name=="em-high-speed-straight-rail" or rail.name=="em-curved-high-speed-rail" or rail.name=="em-curved-high-speed-rail-b" or rail.name=="em-half-diagonal-high-speed-rail") then seen_hsr=true end
  end
  if not seen_hsr then return 0 end
  -- Test-only fixed station association. Production needs native rail/component mapping.
  local b=loco.burner
  local j=math.min(math.max(0,max_j),math.max(0,r.output.energy))
  if j<=0 then return 0 end
  if not b.currently_burning then b.currently_burning="em072-grid-token" end
  local start=b.remaining_burning_fuel
  b.remaining_burning_fuel=start+j
  local delivered=b.remaining_burning_fuel-start
  assert(delivered>=-0.001 and delivered<=j+0.001,"EM072 injected fuel mismatch")
  r.output.energy=r.output.energy-delivered
  return delivered
 end,
 off=function(id)
  local s=storage.em and storage.em.bridge058;local r=s and s.stations[id]
  assert(r,"Cannot turn off missing EM070 station");r.mode="off";s.dirty=true;return true
 end,
 balances=function(id)
  local s=storage.em and storage.em.bridge058
  local r=s and s.stations[id]
  if not r then return {state="none"} end
  return {mode=r.mode,direction=r.direction,status=r.status,input=(r.input and r.input.valid) and r.input.energy or 0,
    output=(r.output and r.output.valid) and r.output.energy or 0,
    input_network=(r.input and r.input.valid) and r.input.electric_network_id or nil,
    output_network=(r.output and r.output.valid) and r.output.electric_network_id or nil,
    line_network=(r.line_port and r.line_port.valid) and r.line_port.electric_network_id or nil}
 end
})
