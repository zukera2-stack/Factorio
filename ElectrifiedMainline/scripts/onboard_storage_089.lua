-- EM089A: finite per-physical-locomotive store. Never a source of new J.
local M={}
local EM='em-electric-locomotive'
local WAGON='em-battery-wagon'
local energy=require('scripts.train_energy_088')
local cooling=require('scripts.battery_cooling_108')
local function cfg(name,default)
  local x=settings and settings.startup and settings.startup[name]
  return x and x.value or default
end
M.CAP=cfg('em089-storage-capacity-mj',60)*1000000
M.CHARGE=cfg('em089-storage-charge-kw',2000)*1000/60
M.DISCHARGE=cfg('em089-storage-discharge-kw',4000)*1000/60
-- Standard battery wagon; saved rows remain keyed by physical unit number.
M.WAGON_CAP=cfg('em107-battery-wagon-capacity-mj',600)*1000000
M.WAGON_CHARGE=cfg('em107-battery-wagon-charge-kw',5000)*1000/60
M.WAGON_DISCHARGE=cfg('em107-battery-wagon-discharge-kw',10000)*1000/60
-- Physical batteries are standard equipment.
function M.wagons_enabled() return true end
function M.enabled() return true end
function M.stationary_enabled()
  local x=settings and settings.global and settings.global['em128-charge-at-standstill']
  return M.enabled() and x and x.value==true or false
end
local function can_charge(e)
  return e.train.speed~=0 or M.stationary_enabled()
end
local function state(create)
  local em=storage.em
  if not em then if not create then return nil end;storage.em={};em=storage.em end
  if not em.onboard_storage_089 and create then
    em.onboard_storage_089={owners={},charged_J=0,discharged_J=0,lost_J=0}
  end
  return em.onboard_storage_089
end
local function real(e)
  return e and e.valid and e.name==EM and e.unit_number and e.train and e.train.valid
end
local function wagon(e)
  return e and e.valid and e.name==WAGON and e.unit_number and e.train and e.train.valid
end
local function valid_store(e) return real(e) or wagon(e) end
local function cap(e) return wagon(e) and M.WAGON_CAP or M.CAP end
local function charge_limit(e) return wagon(e) and M.WAGON_CHARGE or M.CHARGE end
local function discharge_limit(e) return wagon(e) and M.WAGON_DISCHARGE or M.DISCHARGE end
-- Each wagon is requested by exactly one physical locomotive in its current consist.
-- No energy belongs to train.id; this choice is only a deterministic grid-request anchor.
-- If that anchor lacks contact while another loco has it, wagon charging waits (QA limitation).
local function stores_for_owner(e)
  local stores={e}
  if not M.wagons_enabled() then return stores end
  local lowest=e.unit_number
  for _,heading in ipairs({'front_movers','back_movers'}) do
    for _,l in ipairs(e.train.locomotives[heading] or {}) do
      if real(l) and l.unit_number<lowest then lowest=l.unit_number end
    end
  end
  if lowest~=e.unit_number then return stores end
  local ws={}
  for _,w in ipairs(e.train.cargo_wagons or {}) do
    if wagon(w) and w.force==e.force and w.surface==e.surface then ws[#ws+1]=w end
  end
  table.sort(ws,function(a,b)return a.unit_number<b.unit_number end)
  for _,w in ipairs(ws) do stores[#stores+1]=w end
  return stores
end
local function row(e,create)
  local s=state(create)
  if not s then return nil end
  local r=s.owners[e.unit_number]
  if not r and create then r={J=0,charged_J=0,discharged_J=0};s.owners[e.unit_number]=r end
  return r
end
local function want_one(e)
  local r=row(e,false)
  return math.max(0,math.min(charge_limit(e),cap(e)-(r and r.J or 0)))
end
-- EM112: one physical charge target per consist, independent of direction
-- or which live pantograph contacts the network. All locomotives before wagons.
local function ordered_stores(e)
  local ls,ws={},{}
  for _,heading in ipairs({'front_movers','back_movers'}) do
    for _,l in ipairs(e.train.locomotives[heading] or {}) do
      if real(l) and l.force==e.force and l.surface==e.surface then ls[#ls+1]=l end
    end
  end
  if M.wagons_enabled() then
    for _,w in ipairs(e.train.cargo_wagons or {}) do
      if wagon(w) and w.force==e.force and w.surface==e.surface then ws[#ws+1]=w end
    end
  end
  local cmp=function(a,b)return a.unit_number<b.unit_number end
  table.sort(ls,cmp);table.sort(ws,cmp)
  for _,w in ipairs(ws) do ls[#ls+1]=w end
  return ls
end
local function next_charge(e)
  for _,d in ipairs(ordered_stores(e)) do
    local w=want_one(d)
    if w>0.0001 then return d,w end
  end
end
function M.want(e)
  if not (M.enabled() and real(e) and can_charge(e)) then return 0 end
  local _,w=next_charge(e);return w or 0
end
-- All charge comes from the actual dedicated, import-only native 25kV sink.
function M.charge(e,source,sink,amount,tick)
  if not (M.enabled() and real(e) and can_charge(e) and source.mode=='auto' and source.direction=='import' and source.status=='active'
      and sink and sink.valid and source.output and source.output.valid and source.line_port and source.line_port.valid
      and sink.electric_network_id and sink.electric_network_id==source.line_port.electric_network_id
      and sink.electric_network_id==source.output.electric_network_id and sink.force==e.force
      and sink.output_flow_limit==0) then return 0 end
  local d,w=next_charge(e);if not d then return 0 end
  local r=row(d,true)
  if r.discharged_tick==tick or r.charged_tick==tick then return 0 end
  amount=math.max(0,math.min(amount,w,sink.energy))
  if amount<=0 then return 0 end
  local before=sink.energy;sink.energy=before-amount
  if math.abs(before-sink.energy-amount)>0.05 then error('[EM112] native debit mismatch') end
  r.J=r.J+amount;r.charged_J=r.charged_J+amount;r.charged_tick=tick;r.charge_tick_J=amount
  if wagon(d) then r.last_mode='charging';r.last_flow_tick=tick end
  cooling.mark(d,amount,'charging',tick)
  local st=state(true);st.charged_J=st.charged_J+amount
  return amount
end
-- Allocate only the *remaining* per-engine deficit after real grid credit.
-- Donor budgets are shared by all recipients of the same live consist.
function M.discharge(owners,requests,tick)
  if not M.enabled() then return {} end
  local s=state(false);if not s then return {} end
  local groups,ids={},{}
  for _,e in ipairs(owners) do
    if real(e) then
      for _,d in ipairs(stores_for_owner(e)) do
        local r=row(d,false)
        if r and r.J>0 and r.charged_tick~=tick then
          local id=e.train.id;local g=groups[id]
          if not g then g={donors={},requests={},available=0};groups[id]=g;ids[#ids+1]=id end
          local budget=math.min(r.J,discharge_limit(d))
          g.donors[#g.donors+1]={e=d,row=r,left=budget};g.available=g.available+budget
        end
      end
    end
  end
  for _,req in ipairs(requests) do
    if real(req.owner) and req.e.valid and req.e.train and req.e.train.valid and req.owner.train.id==req.e.train.id then
      local g=groups[req.owner.train.id]
      local deficit=math.max(0,req.want-(req.grid_paid or 0))
      if g and deficit>0 then g.requests[#g.requests+1]={req=req,left=deficit,grant=0} end
    end
  end
  local used={};table.sort(ids)
  for _,id in ipairs(ids) do
    local g=groups[id];local pending=g.requests;local available=g.available
    while available>0.0001 and #pending>0 do
      local share=available/#pending;local sent=0;local more={}
      for _,r in ipairs(pending) do
        local j=math.min(r.left,share);r.grant=r.grant+j;r.left=r.left-j;sent=sent+j
        if r.left>0.0001 then more[#more+1]=r end
      end
      if sent<=0.0001 then break end
      available=math.max(0,available-sent);pending=more
    end
    for _,r in ipairs(g.requests) do
      local left=r.grant
      for _,d in ipairs(g.donors) do
        if left<=0.0001 then break end
        local amount=math.min(left,d.left,d.row.J)
        if amount>0 then
          local j=energy.transfer_store_to_burner(r.req,d.e,d.row,amount)
          d.left=d.left-j;left=left-j
          if j>0 then
            d.row.discharged_J=d.row.discharged_J+j;d.row.discharged_tick=tick
            s.discharged_J=s.discharged_J+j;used[id]=true
            if wagon(d.e) then d.row.last_mode='discharging';d.row.last_flow_tick=tick end
            cooling.mark(d.e,j,'discharging',tick)
            if r.req.kind=='motor' then s.motor_J=(s.motor_J or 0)+j end
          end
        end
      end
    end
  end
  return used
end
-- Internal EM091 receiver only. No public remote mutation. The offered energy
-- has already passed the native debit and brake certificate.
function M.recover(owners,amount,tick)
  if not M.enabled() or amount<=0 then return 0 end
  local accepted=0;local seen={}
  for _,e in ipairs(owners) do
    if real(e) and not seen[e.train.id] then
      seen[e.train.id]=true
      -- Locomotives have priority up to their individual power/headroom limits.
      -- Battery wagons keep the same physical sequential queue even during regen.
      for _,d in ipairs(ordered_stores(e)) do
        local r=row(d,true)
        if r.discharged_tick~=tick then
          -- Multiple certified grants can settle in the same tick (old native
          -- terminal residual, then current brake grant). Share one rate budget.
          local used=r.charged_tick==tick and (r.charge_tick_J or charge_limit(d)) or 0
          local j=math.max(0,math.min(amount-accepted,charge_limit(d)-used,cap(d)-r.J))
          if j>0 then
            r.J=r.J+j;r.regen_J=(r.regen_J or 0)+j;r.charged_tick=tick;r.charge_tick_J=used+j
            local st=state(true);st.regen_J=(st.regen_J or 0)+j;accepted=accepted+j
            if wagon(d) then r.last_mode='recovering';r.last_flow_tick=tick end
            cooling.mark(d,j,'recovering',tick)
          end
        end
        if accepted>=amount or (wagon(d) and r.J<cap(d)-0.0001) then break end
      end
    end
  end
  return accepted
end
function M.audit()
  local s=state(false);if not s then return end
  local ids={};for id in pairs(s.owners) do ids[#ids+1]=id end;table.sort(ids)
  local total=0
  for _,id in ipairs(ids) do
    local r=s.owners[id];local e=game.get_entity_by_unit_number(id)
    if not valid_store(e) then s.lost_J=s.lost_J+r.J;s.owners[id]=nil
    else
      if r.J>cap(e) then s.lost_J=s.lost_J+r.J-cap(e);r.J=cap(e) end
      if r.J<0 then error('[EM089] negative charge') end
      total=total+r.J
    end
  end
  if math.abs(s.charged_J+(s.regen_J or 0)-s.discharged_J-s.lost_J-total)>math.max(0.05,s.charged_J*1e-10) then error('[EM089] closed battery ledger mismatch') end
end
function M.charge_of(e)
  local r=row(e,false)
  return r and r.J or 0
end
function M.has_charge(e,epsilon)
  return M.charge_of(e)>(epsilon or 1)
end
function M.charged_wagons()
  local s=state(false)
  if not s then return {} end
  local out={}
  for id,r in pairs(s.owners) do
    if r.J and r.J>1 then
      local e=game.get_entity_by_unit_number(id)
      if wagon(e) then out[#out+1]=e end
    end
  end
  table.sort(out,function(a,b)return a.unit_number<b.unit_number end)
  return out
end

function M.wagon_status(e,tick)
  local r=row(e,false)
  local enabled=M.enabled() and M.wagons_enabled()
  local mode=not enabled and 'disabled' or 'idle'
  if enabled and r and r.last_flow_tick and tick-r.last_flow_tick<12 then mode=r.last_mode end
  return {J=r and r.J or 0,capacity_J=M.WAGON_CAP,enabled=enabled,mode=mode}
end
function M.snapshot(unit)
  local s=state(false) or {owners={},charged_J=0,discharged_J=0,lost_J=0}
  local result={enabled=M.enabled(),capacity_J=M.CAP,charge_J_tick=M.CHARGE,discharge_J_tick=M.DISCHARGE,
    charged_J=s.charged_J,regen_J=s.regen_J or 0,discharged_J=s.discharged_J,motor_J=s.motor_J or 0,lost_J=s.lost_J,stored_J=0,owners={},wagons={},wagon_enabled=M.wagons_enabled(),wagon_capacity_J=M.WAGON_CAP,wagon_charge_J_tick=M.WAGON_CHARGE,wagon_discharge_J_tick=M.WAGON_DISCHARGE,wagon_stored_J=0}
  local ids={};for id in pairs(s.owners) do ids[#ids+1]=id end;table.sort(ids)
  for _,id in ipairs(ids) do
    result.stored_J=result.stored_J+s.owners[id].J
    if wagon(game.get_entity_by_unit_number(id)) then result.wagon_stored_J=result.wagon_stored_J+s.owners[id].J end
  end
  local e=unit and game.get_entity_by_unit_number(unit)
  if valid_store(e) then
    result.train_id=e.train.id
    for _,heading in ipairs({'front_movers','back_movers'}) do
      for _,o in ipairs(e.train.locomotives[heading] or {}) do
        if real(o) then local r=s.owners[o.unit_number];result.owners[#result.owners+1]={unit=o.unit_number,J=r and r.J or 0,charged_J=r and r.charged_J or 0,regen_J=r and r.regen_J or 0,discharged_J=r and r.discharged_J or 0} end
      end
    end
    table.sort(result.owners,function(a,b)return a.unit<b.unit end)
    for _,w in ipairs(e.train.cargo_wagons or {}) do
      if wagon(w) then local r=s.owners[w.unit_number];result.wagons[#result.wagons+1]={unit=w.unit_number,J=r and r.J or 0,charged_J=r and r.charged_J or 0,regen_J=r and r.regen_J or 0,discharged_J=r and r.discharged_J or 0} end
    end
    table.sort(result.wagons,function(a,b)return a.unit<b.unit end)
  end
  return result
end
return M
