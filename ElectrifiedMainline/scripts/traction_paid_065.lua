-- EM065 research P0: finite, source-paid native locomotive traction.
-- ALL charge comes from live native EM070 output buffer on same real 25kV network.
-- No speed writes, no fabricated energy, and NO wagon helper charge.
local M={MAX_PER_TICK=2000000/60,BUFFER_CAP=2000000}
local FUEL="em-c5-test-internal-joule-063"
local function entity(id)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  return e and e.valid and e or nil
end
local function ensure()
  storage.em=storage.em or {}
  storage.em.traction_paid_065=storage.em.traction_paid_065 or
    {debited_J=0,credited_J=0,charged_ticks=0,miss_contact=0,miss_grid=0,miss_supply=0}
  return storage.em.traction_paid_065
end
local function network_for_contact(e,art,pantograph)
  local h=pantograph.head_offset(pantograph.frame(e.orientation))
  local contact=art.contact_at(e.surface.index,e.force.name,
    {x=e.position.x+h.x,y=e.position.y+h.y})
  if not contact or not contact.key then return nil,"no-contact" end
  local a,b=contact.key:match("^(%d+):(%d+)$")
  a=tonumber(a);b=tonumber(b)
  if not (a and b and a~=b) then return nil,"invalid-contact-key" end
  local t=storage.em and storage.em.technical_046
  if not (t and t.helpers and t.mast_connected and t.mast_connected[a]
    and t.mast_connected[b]) then return nil,"mast-not-native-connected" end
  local aa,ab=entity(t.helpers[a]),entity(t.helpers[b])
  if not (aa and ab and aa.surface.index==e.surface.index
    and ab.surface.index==e.surface.index and aa.force==e.force
    and ab.force==e.force and aa.electric_network_id
    and aa.electric_network_id==ab.electric_network_id) then
    return nil,"native-25kv-network-unverified"
  end
  return aa.electric_network_id,nil
end
local function donor(network,force)
  local bridge=storage.em and storage.em.bridge058
  if not (bridge and bridge.stations) then return nil end
  local list={}
  for id,r in pairs(bridge.stations) do
    local output=r.output
    if r.direction=="import" and r.status=="active"
      and output and output.valid and r.input and r.input.valid
      and r.factory_port and r.factory_port.valid
      and r.line_port and r.line_port.valid
      and output.electric_network_id==network
      and r.line_port.electric_network_id==network
      and output.force==force and output.energy>0
      and entity(id) then
      list[#list+1]={id=id,r=r}
    end
  end
  table.sort(list,function(a,b)return a.id<b.id end)
  return list[1] and list[1].r or nil
end
local function charge(e,art,pantograph,stats)
  if not (e and e.valid and e.name=="em-electric-locomotive"
    and e.unit_number and e.burner) then return end
  local burner=e.burner
  local old=math.max(0,burner.remaining_burning_fuel or 0)
  if old>M.BUFFER_CAP+1 then
    error("[EM065 PAID FAIL] native locomotive battery exceeded finite 2MJ cap; unit="..
      e.unit_number.." J="..old)
  end
  if old>=M.BUFFER_CAP-M.MAX_PER_TICK/2 then return end
  local network,why=network_for_contact(e,art,pantograph)
  if not network then
    stats.miss_contact=stats.miss_contact+1
    return
  end
  local source=donor(network,e.force)
  if not source then
    stats.miss_supply=stats.miss_supply+1
    return
  end
  local available=source.output.energy
  local amount=math.max(0,math.min(M.MAX_PER_TICK,M.BUFFER_CAP-old,available))
  if amount<=0 then return end
  -- Existing paid native EEI energy must be physically removed FIRST.
  source.output.energy=available-amount
  local next_J=source.output.energy
  if next_J< -0.0001 or math.abs(available-next_J-amount)>0.05 then
    error("[EM065 PAID FAIL] native source debit didn't match grant")
  end
  if not burner.currently_burning then
    -- The API may auto-fill a newly assigned fuel item; forcibly set ZERO
    -- before crediting exactly the already-paid amount, no free 10MJ.
    burner.currently_burning=prototypes.item[FUEL]
    burner.remaining_burning_fuel=0
    old=0
  end
  burner.remaining_burning_fuel=old+amount
  stats.debited_J=stats.debited_J+amount
  stats.credited_J=stats.credited_J+amount
  stats.charged_ticks=stats.charged_ticks+1
  if burner.remaining_burning_fuel>old+amount+0.05 then
    error("[EM065 PAID FAIL] burner gained free energy")
  end
end
function M.on_tick(tick,art,pantograph)
  local stats=ensure()
  local trains=game.train_manager.get_trains{stock="em-electric-locomotive"}
  local owners={}
  for _,t in pairs(trains) do
    if t.valid then
      for _,e in ipairs(t.carriages) do
        if e.valid and e.name=="em-electric-locomotive" then
          owners[#owners+1]=e
        end
      end
    end
  end
  table.sort(owners,function(a,b)return a.unit_number<b.unit_number end)
  for _,e in ipairs(owners) do charge(e,art,pantograph,stats) end
  if tick%60==0 then
    log(string.format("[EM065 PAID LEDGER] tick=%d locos=%d debited_J=%.1f credited_J=%.1f charged_ticks=%d no_contact=%d no_supply=%d",
      tick,#owners,stats.debited_J,stats.credited_J,stats.charged_ticks,
      stats.miss_contact,stats.miss_supply))
  end
end
return M
