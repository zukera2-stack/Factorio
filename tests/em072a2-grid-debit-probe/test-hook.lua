-- EM072-A2 DISPOSABLE TEST HOOK; not present in GitHub ElectrifiedMainline main.
remote.add_interface("em072a2_native_probe",{
 mode=function(id)
  local s=storage.em and storage.em.bridge058
  assert(s and s.stations,"EM070 storage missing")
  local r=s.stations[id]
  if not r then r={};s.stations[id]=r end
  r.mode="import";r.status="waiting";s.dirty=true
  return true
 end,
 take=function(id,loco_id,max_j)
  local s=storage.em and storage.em.bridge058
  local r=s and s.stations[id]
  local loco=game.get_entity_by_unit_number(loco_id)
  if not(r and r.mode=="import" and r.direction=="import" and r.status=="active" and r.output and r.output.valid and r.line_port and r.line_port.valid) then return 0 end
  if not (r.output.electric_network_id==r.line_port.electric_network_id) then return 0 end
  if not(loco and loco.valid and loco.name=="em072-grid-burner-loco") then return 0 end
  if not (loco.force.name==r.line_port.force.name and loco.surface.index==r.parent_surface) then return 0 end
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
