-- EM089A: finite per-physical-locomotive store. Never a source of new J.
local M={}
local EM='em-electric-locomotive'
local energy=require('scripts.train_energy_088')
local function cfg(name,default)
  local x=settings and settings.startup and settings.startup[name]
  return x and x.value or default
end
M.CAP=cfg('em089-storage-capacity-mj',60)*1000000
M.CHARGE=cfg('em089-storage-charge-kw',2000)*1000/60
M.DISCHARGE=cfg('em089-storage-discharge-kw',4000)*1000/60
function M.enabled()
  local x=settings and settings.global and settings.global['em089-experimental-onboard-storage']
  return x and x.value==true or false
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
local function row(e,create)
  local s=state(create)
  if not s then return nil end
  local r=s.owners[e.unit_number]
  if not r and create then r={J=0,charged_J=0,discharged_J=0};s.owners[e.unit_number]=r end
  return r
end
function M.want(e)
  if not (M.enabled() and real(e) and e.train.speed==0) then return 0 end
  local r=row(e,false)
  return math.max(0,math.min(M.CHARGE,M.CAP-(r and r.J or 0)))
end
-- All charge comes from the real, live 25kV sink, never from a virtual plan.
function M.charge(e,source,sink,amount,tick)
  if not (M.enabled() and real(e) and source.mode=='auto' and source.direction=='import' and source.status=='active'
      and sink and sink.valid and source.output and source.output.valid and source.line_port and source.line_port.valid
      and sink.electric_network_id and sink.electric_network_id==source.line_port.electric_network_id
      and sink.electric_network_id==source.output.electric_network_id and sink.force==e.force) then return 0 end
  local r=row(e,true)
  if r.discharged_tick==tick or r.charged_tick==tick then return 0 end
  amount=math.max(0,math.min(amount,M.want(e),sink.energy))
  if amount<=0 then return 0 end
  local before=sink.energy;sink.energy=before-amount
  if math.abs(before-sink.energy-amount)>0.05 then error('[EM089] native debit mismatch') end
  r.J=r.J+amount;r.charged_J=r.charged_J+amount;r.charged_tick=tick
  local s=state(true);s.charged_J=s.charged_J+amount
  return amount
end
-- Allocate only the *remaining* per-engine deficit after real grid credit.
-- Donor budgets are shared by all recipients of the same live consist.
function M.discharge(owners,requests,tick)
  if not M.enabled() then return {} end
  local s=state(false);if not s then return {} end
  local groups,ids={},{}
  for _,e in ipairs(owners) do
    local r=real(e) and row(e,false)
    if r and r.J>0 and r.charged_tick~=tick then
      local id=e.train.id;local g=groups[id]
      if not g then g={donors={},requests={},available=0};groups[id]=g;ids[#ids+1]=id end
      local budget=math.min(r.J,M.DISCHARGE)
      g.donors[#g.donors+1]={e=e,row=r,left=budget};g.available=g.available+budget
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
  local accepted=0
  for _,e in ipairs(owners) do
    if real(e) and e.train.speed~=0 then
      local r=row(e,true)
      if r.discharged_tick~=tick and r.charged_tick~=tick then
        local j=math.max(0,math.min(amount-accepted,M.CHARGE,M.CAP-r.J))
        if j>0 then
          r.J=r.J+j;r.regen_J=(r.regen_J or 0)+j;r.charged_tick=tick
          local s=state(true);s.regen_J=(s.regen_J or 0)+j;accepted=accepted+j
        end
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
    if not real(e) then s.lost_J=s.lost_J+r.J;s.owners[id]=nil
    else
      if r.J>M.CAP then s.lost_J=s.lost_J+r.J-M.CAP;r.J=M.CAP end
      if r.J<0 then error('[EM089] negative charge') end
      total=total+r.J
    end
  end
  if math.abs(s.charged_J+(s.regen_J or 0)-s.discharged_J-s.lost_J-total)>math.max(0.05,s.charged_J*1e-10) then error('[EM089] closed battery ledger mismatch') end
  if game.tick%600==0 then
    log(string.format('[EM089 STORAGE] tick=%d enabled=%s stored_J=%.3f charged_J=%.3f discharged_J=%.3f motor_J=%.3f lost_J=%.3f',game.tick,tostring(M.enabled()),total,s.charged_J,s.discharged_J,s.motor_J or 0,s.lost_J))
  end
end
function M.snapshot(unit)
  local s=state(false) or {owners={},charged_J=0,discharged_J=0,lost_J=0}
  local result={enabled=M.enabled(),capacity_J=M.CAP,charge_J_tick=M.CHARGE,discharge_J_tick=M.DISCHARGE,
    charged_J=s.charged_J,regen_J=s.regen_J or 0,discharged_J=s.discharged_J,motor_J=s.motor_J or 0,lost_J=s.lost_J,stored_J=0,owners={}}
  local ids={};for id in pairs(s.owners) do ids[#ids+1]=id end;table.sort(ids)
  for _,id in ipairs(ids) do result.stored_J=result.stored_J+s.owners[id].J end
  local e=unit and game.get_entity_by_unit_number(unit)
  if real(e) then
    result.train_id=e.train.id
    for _,heading in ipairs({'front_movers','back_movers'}) do
      for _,o in ipairs(e.train.locomotives[heading] or {}) do
        if real(o) then local r=s.owners[o.unit_number];result.owners[#result.owners+1]={unit=o.unit_number,J=r and r.J or 0,charged_J=r and r.charged_J or 0,regen_J=r and r.regen_J or 0,discharged_J=r and r.discharged_J or 0} end
      end
    end
    table.sort(result.owners,function(a,b)return a.unit<b.unit end)
  end
  return result
end
return M
