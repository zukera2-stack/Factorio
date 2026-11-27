-- EM091: conservative native debit certificate, no virtual kinetic reservoir.
-- Only this module can offer a calculated brake grant to the onboard store.
local M={}
local term094=require("scripts.line_terminal_094")
local estimate=require('scripts.brake_estimator_091')
local reserve117=require('scripts.native_reserve_117')
local EM='em-electric-locomotive'
local FUEL='em-c5-test-internal-joule-063'
local motor={['em-motor-cargo-wagon']=true,['em-motor-fluid-wagon']=true,['em-battery-wagon']=true}
local function enabled() return true end
M.enabled=enabled
local phase=nil -- synchronous Lua phase only, never persisted across ticks
local function state()
  storage.em=storage.em or {}
  local s=storage.em.brake_recovery_091
  if not s then s={burners={},trains={},consumed_J=0,estimated_J=0,recovered_J=0,rejected_J=0,intervals=0};storage.em.brake_recovery_091=s end
  return s
end
function M.damage(event)
  -- Deliberately conservative: obstacle damage need not be to rolling stock.
  if enabled() then state().damage_tick=event.tick end
end
function M.invalidate()
  local s=storage.em and storage.em.brake_recovery_091
  if s then s.burners={};s.trains={} end
  phase=nil
end
function M.train_changed(event)
  local s=storage.em and storage.em.brake_recovery_091
  if not s then return end
  local function invalidate(id)
    if not id then return end
    s.trains[id]=nil
    if phase and phase.pre[id] then phase.pre[id].source_verified=false end
  end
  invalidate(event.old_train_id_1);invalidate(event.old_train_id_2)
  if event.train and event.train.valid then invalidate(event.train.id) end
end
function M.credit(e,j)
  if phase and j>0 then local id=e.unit_number;phase.credits[id]=(phase.credits[id] or 0)+j end
end
local function trains()
  local a={};for _,t in pairs(game.train_manager.get_trains{stock=EM}) do if t.valid then a[#a+1]=t end end
  table.sort(a,function(x,y)return x.id<y.id end);return a
end
local function inspect(t)
  local q={id=t.id,units={},engines={},limits={},owners={},B=0,motorB=0,friction=0,capW=0,valid=true,speed=t.speed,weight=t.weight,r=t.riding_state.acceleration,state=t.state}
  local f,surface=nil,nil
  local hs=storage.em.helper067
  local stock=t.carriages
  local front=q.speed<0 and stock[#stock] or stock[1]
  q.air=front and front.prototype.air_resistance or 0
  for _,e in ipairs(stock) do
    local id=e.unit_number;local p=e.prototype;local n=e.name
    q.units[#q.units+1]=id
    if not f then f=e.force;surface=e.surface end
    if e.force~=f or e.surface~=surface then q.valid=false end
    q.B=q.B+p.braking_force;q.friction=q.friction+p.friction_force
    if n==EM then q.owners[#q.owners+1]=e;q.motorB=q.motorB+p.braking_force;q.capW=q.capW+2000000
    elseif motor[n] then q.motorB=q.motorB+p.braking_force;q.capW=q.capW+500000 end
    if e.type=='locomotive' then
      local h=n:match('^em%-c5%-technical%-booster%-%d+$')
      local owner=h and hs and hs.owners and hs.owners[id] and game.get_entity_by_unit_number(hs.owners[id])
      if n~=EM and not (owner and owner.valid and owner.name==EM and owner.train and owner.train.id==t.id and owner.force==e.force and owner.surface==e.surface) then q.valid=false end
      local b=e.burner;local J,heat,reserve_valid=reserve117.parts(b)
      local fuel=b and b.currently_burning
      -- 2.1.24 returns ItemWithQualityID: .name is LuaItemPrototype.
      local internal=fuel and (fuel.name==FUEL or fuel.name==prototypes.item[FUEL])
      if not b or not b.inventory or not b.inventory.is_empty() or J<0 or (J>0 and not internal) then q.valid=false end
      if not reserve_valid then q.valid=false end
      q.engines[id]=J+heat
      q.limits[id]=p.get_max_energy_usage(e.quality)
    end
  end
  table.sort(q.owners,function(x,y)return x.unit_number<y.unit_number end)
  local bonus=f and 1+f.train_braking_force_bonus or 1
  q.B=q.B*bonus;q.motorB=q.motorB*bonus
  q.identity=t.id..':'..table.concat(q.units,',')..':'..tostring(f and f.index)..':'..tostring(surface and surface.index)
  return q
end
function M.begin(tick)
  if not enabled() then
    if storage.em and storage.em.brake_recovery_091 and next(storage.em.brake_recovery_091.burners) then M.invalidate() end
    return
  end
  local s=state();phase={tick=tick,credits={},pre={}}
  for _,t in ipairs(trains()) do
    local q=inspect(t);local ok=q.valid;local debit,unknown_debit=0,0;local trusted,unknown={},{}
    for id,J in pairs(q.engines) do
      local d,u,ud,continuous,reason=reserve117.debit(s.burners[id],J,tick,q.limits[id])
      if reason=='debit-limit' then
        s.debit_limit_count=(s.debit_limit_count or 0)+1
        s.last_debit_limit={unit=id,tick=tick,previous_J=s.burners[id].J,current_J=J,limit_J=q.limits[id]}
      end
      trusted[id]=continuous;unknown[id]=u
      debit=debit+d;unknown_debit=unknown_debit+ud
      if not continuous then ok=false end
    end
    q.trusted=trusted;q.unknown=unknown;q.debit=debit;q.unknown_debit=unknown_debit;q.source_verified=ok
    phase.pre[t.id]=q
  end
end
-- Native solver has already processed the previous tick's offered energy.
-- Settle its actual residual BEFORE ordinary traction/charging can use stores.
function M.settle(tick,battery)
  if storage.em and storage.em.em094_terminal then term094.settle_actual(state(),battery,tick,enabled()) end
end
function M.finish(tick,battery,contact)
  if not phase or phase.tick~=tick then return end
  local s=state();local nextburn,nexttrain={},{}
  for _,t in ipairs(trains()) do
    local post=inspect(t);local pre=phase.pre[t.id];local stable=pre and pre.identity==post.identity and pre.valid and post.valid and pre.speed==post.speed and pre.weight==post.weight and pre.B==post.B and pre.motorB==post.motorB and pre.friction==post.friction and pre.air==post.air and pre.capW==post.capW and pre.r==post.r and pre.state==post.state
    local valid=stable and pre.source_verified
    local unknown_total=0;local all_matched=true
    for id,J in pairs(post.engines) do
      local before=pre and pre.engines[id];local receipt=phase.credits[id] or 0
      local matched=before~=nil and math.abs(J-before-receipt)<=1e-5 and post.valid
      local trusted=matched and pre.trusted[id]
      if not trusted then valid=false end
      if not matched then all_matched=false end
      -- Unknown legacy or externally changed reserves are not paid receipts.
      local unknown=J
      if matched then unknown=math.min(J,pre.unknown[id] or before)
      elseif before==nil and post.valid and math.abs(J-receipt)<=1e-5 then unknown=0 end
      nextburn[id]={J=J,tick=tick,trusted=post.valid==true,unknown=unknown}
      unknown_total=unknown_total+unknown

    end
    if pre then
      local es=s.trains[t.id] or {consumed=0}
      if valid then es.consumed=es.consumed+pre.debit;s.consumed_J=s.consumed_J+pre.debit;s.unknown_debit_J=(s.unknown_debit_J or 0)+pre.unknown_debit end
      local damage=s.damage_tick and s.damage_tick>=tick-1
      local empty=true
      for _,j in pairs(pre.engines) do if j>0 then empty=false end end
      -- At a verified stationary boundary no kinetic energy can be refunded.
      -- Rebase the whole remaining unknown stock, without counting the rejected
      -- interval as paid consumption. While moving, the epoch remains invalid.
      local rest_rebase=stable and all_matched and pre.speed==0 and not damage
      local verified=valid or rest_rebase
      local q={empty=empty,exhausted=empty and pre.debit>0,id=pre.identity,tick=tick,speed=pre.speed,weight=pre.weight,B=pre.B,motorB=pre.motorB,friction=pre.friction,air=pre.air,capW=pre.capW,r=pre.r,state=pre.state,consumed=es.consumed,unknown_reserve=unknown_total,source_verified=verified==true,damage=damage==true}
      local was=es.certified
      local grant,work,why=estimate.observe(es,q)
      if was and not es.certified then log('[EM117 CERTIFICATE LOST] '..serpent.line({q=q,why=why},{comment=false})) end
      if not verified then es.certified=false end
      if grant>0 then
        s.estimated_J=s.estimated_J+grant;s.intervals=s.intervals+1
        local offered=term094.offer_actual(post,grant,contact)
        local remainder=grant-offered
        local accepted=battery.recover(post.owners,remainder,tick)
        if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
        s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+remainder-accepted
      end
      s.last_reason=why;es.last_reason=why;nexttrain[t.id]=es
    end
  end
  s.burners=nextburn;s.trains=nexttrain;phase=nil
end
function M.snapshot(unit)
  local s=storage.em and storage.em.brake_recovery_091 or {}
  local r={enabled=enabled(),consumed_J=s.consumed_J or 0,unknown_debit_J=s.unknown_debit_J or 0,estimated_J=s.estimated_J or 0,recovered_J=s.recovered_J or 0,rejected_J=s.rejected_J or 0,intervals=s.intervals or 0,last_credit_tick=s.last_credit_tick,last_credit_J=s.last_credit_J}
  r.debit_limit_count=s.debit_limit_count or 0;r.last_debit_limit=s.last_debit_limit
  r.qa_grid_J=s.qa_grid_J or 0;r.qa_fallback_J=s.qa_fallback_J or 0;r.qa_uncertain_J=s.qa_uncertain_J or 0;r.qa_missing_J=s.qa_missing_J or 0;r.qa_pending_J=storage.em and storage.em.em094_terminal and term094.pending_actual() or 0
  local e=unit and game.get_entity_by_unit_number(unit);local q=e and e.valid and e.train and s.trains and s.trains[e.train.id]
  if q then r.certified=q.certified==true;r.reason=q.last_reason;r.train_consumed_J=q.consumed;r.unpaid_kinetic_J=q.unpaid_K or 0;r.unpaid_added_J=q.unpaid_added_J or 0;r.unpaid_excluded_J=q.unpaid_excluded_J or 0 end
  return r
end
return M
