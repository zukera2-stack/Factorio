-- EM090B diagnostic only. This returns a hypothetical upper capped grant;
-- it cannot modify fuel, storage, network, or speed. No virtual energy pool.
local M={C=450,eta=.65}
local eps=1e-8
function M.observe(s,q)
  local p=s.prev;s.prev=q
  for _,k in ipairs({'speed','weight','B','motorB','friction','air','capW','consumed','tick'}) do
    local x=q[k];if type(x)~='number' or x~=x or x==math.huge or x==-math.huge then s.certified=false;s.prev=nil;return 0,0,'invalid-data' end
  end
  -- Cancellation of measured cumulative credits and burner reserve at rest.
  if q.consumed<0 and q.consumed>=-1e-6 then q.consumed=0 end
  if q.weight<=0 or q.B<=0 or q.motorB<0 or q.motorB>q.B or q.friction<0 or q.air<0 or q.air>=q.weight/1000 or q.capW<0 or q.consumed<0 or not q.id then s.certified=false;s.prev=nil;return 0,0,'invalid-data' end
  local v=math.abs(q.speed)
  local grant,work,why=0,0,'no-brake'
  if v==0 then
    -- Reserve the WHOLE uncertain stock once per stationary epoch, before
    -- departure. All later native debits are measured; unexplained credits
    -- invalidate the epoch. Do not repeatedly count the same unknown joules.
    local u=q.unknown_reserve or 0
    if type(u)~='number' or u~=u or u<0 or u==math.huge then s.certified=false;return 0,0,'invalid-unknown-reserve' end
    s.unpaid_K=u;s.certified=q.source_verified and not q.damage
    return 0,0,'stop'
  end
  if not p or math.abs(p.speed)==0 and not s.certified then
    s.certified=false;return 0,0,'unobserved-start'
  end
  if not s.certified or not q.source_verified or not p.source_verified or q.tick~=p.tick+1
    or q.id~=p.id or q.weight~=p.weight or q.B~=p.B or q.motorB~=p.motorB
    or q.friction~=p.friction or q.air~=p.air or q.capW~=p.capW
    or (p.speed~=0 and p.speed*q.speed<0) or q.damage or p.damage then
    s.certified=false;return 0,0,'uncertain-epoch'
  end
  local old=math.abs(p.speed)
  local K0=M.C*q.weight*old*old/2;local K1=M.C*q.weight*v*v/2
  local debit=q.consumed-p.consumed
  if debit < -0.05 then s.certified=false;return 0,0,'debit-reversal' end
  if K1>K0 then
    if K1-K0>debit+0.001 then
      s.certified=false;return 0,0,'unpaid-acceleration'
    end
    return 0,0,'acceleration'
  end
  if old-v<=eps or p.r~=2 or q.r~=2 then return 0,0,'no-brake' end
  local d=old-v;local nominal=math.min(old,q.B/q.weight)
  local coast=math.max(0,old-q.friction/q.weight)*(1-q.air/(q.weight/1000))
  local drag=old-coast
  if p.state==7 and q.state==7 then -- native manual_control_stop; not driver control
    if math.abs(d-nominal)>eps then s.certified=false;return 0,0,'unexpected-manual-brake' end
    work=K0-K1 -- native manual brake excludes separate coast term in the tested engine
  elseif p.state==5 and q.state==5 then -- tested native arrive_station only
    if d>nominal+drag+eps then s.certified=false;return 0,0,'excess-deceleration' end
    if d<nominal-eps then return 0,0,'terminal-adjustment' end
    -- Conservatively subtract all predicted passive decay; cap by nominal brake.
    work=math.max(0,math.min(M.C*q.weight*(coast*coast-v*v)/2,
      M.C*q.weight*(old*old-(old-nominal)^2)/2))
  else return 0,0,'state-transition' end
  if q.B<=0 or q.motorB<=0 or q.motorB>q.B or q.capW<0 then return 0,0,'invalid-motor' end
  -- Never recover the unbacked part of native kinetic energy. Retain the
  -- debt during coasting: this deliberately under-recovers rather than
  -- treating uncertain passive decay as proof of dissipated unbacked work.
  local excluded=math.min(work,s.unpaid_K or 0)
  s.unpaid_K=math.max(0,(s.unpaid_K or 0)-excluded)
  s.unpaid_excluded_J=(s.unpaid_excluded_J or 0)+excluded
  grant=math.min((work-excluded)*q.motorB/q.B*M.eta,q.capW/60)
  assert(grant>=0 and grant<=K0-K1+0.001 and grant<=q.capW/60+0.001)
  return grant,work,'estimate'
end
return M
