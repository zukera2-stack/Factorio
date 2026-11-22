-- B10R: locomotive-only finite batteries; motor cargo/fluid have NO storage or direct 25kV.
-- LuaTrain.carriages defines only a temporary power bus; no train.speed edits.
local M={}
local function power_member(e,states)
 if not (e and e.valid and e.unit_number) then return nil end
 if e.type~='locomotive' or e.name~='em-b10r-battery-loco' then
  assert(states[e.unit_number]==nil,'NONCOMPLIANT wagon energy storage is forbidden')
  return nil
 end
 local st=states[e.unit_number]
 if st then assert(st.kind=='locomotive','only locomotive energy owner permitted') end
 return st
end
function M.members(train,states)
 assert(train and train.valid,'native LuaTrain is required')
 local members={}
 for _,stock in ipairs(train.carriages) do
  local s=power_member(stock,states)
  if s then members[#members+1]={entity=stock,state=s,id=stock.unit_number} end
 end
 table.sort(members,function(a,b)return a.id<b.id end)
 return members
end
function M.snapshot(train,states)
 local members=M.members(train,states)
 local sum,reserve,shared,power=0,0,0,0
 local motor_cargo,motor_fluid=0,0
 for _,e in ipairs(train.carriages) do
  if e.name=="em-b10r-motor-cargo-wagon" then motor_cargo=motor_cargo+1
  elseif e.name=="em-b10r-motor-fluid-wagon" then motor_fluid=motor_fluid+1 end
 end
 for _,m in ipairs(members) do
  local s=m.state
  assert(s.j>=0 and s.j<=s.capacity_j+0.01,'battery outside physical capacity')
  sum=sum+s.j;reserve=reserve+math.min(s.j,s.solo_reserve_j)
  shared=shared+math.max(0,s.j-s.solo_reserve_j)
  power=power+s.max_discharge_w
 end
 return {members=members,n=#members,energy_j=sum,protected_j=reserve,
    shareable_j=shared,peak_w=power,motor_cargo_count=motor_cargo,
    motor_fluid_count=motor_fluid,nominal_nameplate_w=2000000*#members+500000*(motor_cargo+motor_fluid)}
end
function M.take(train,states,request_j,dt)
 -- Shared borrow is ONLY energy above each vehicle's solo maneuver reserve.
 -- A single un-coupled powered locomotive can use its OWN full battery, reserve included.
 assert(dt>0 and dt<=1 and request_j>=0,'bad power request')
 local snap=M.snapshot(train,states)
 local available={};local max_sum=0
 local solo=(#train.carriages==1 and snap.n==1)
 for _,m in ipairs(snap.members) do
  local st=m.state
  local spendable=solo and st.j or math.max(0,st.j-st.solo_reserve_j)
  local budget=math.min(spendable,st.max_discharge_w*dt)
  if budget>0 then
   local row={unit=m.id,budget=budget,weight=spendable,state=st}
   available[#available+1]=row;max_sum=max_sum+budget
  end
 end
 local target=math.min(request_j,max_sum)
 local allocation={};local left=target;local pending=available
 for _=1,#available+1 do
  if left<=1e-7 or #pending==0 then break end
  local weight_sum=0;for _,r in ipairs(pending) do weight_sum=weight_sum+r.weight end
  local next_rows={};local used=0
  for _,row in ipairs(pending) do
   local old=allocation[row.unit] or 0
   local proposal=weight_sum>0 and left*row.weight/weight_sum or left/#pending
   local give=math.min(proposal,row.budget-old)
   allocation[row.unit]=old+give;used=used+give
   if row.budget-allocation[row.unit]>1e-7 then next_rows[#next_rows+1]=row end
  end
  left=left-used;pending=next_rows
  if used<1e-9 then break end
 end
 local drawn=0
 for _,row in ipairs(available) do
  local q=allocation[row.unit] or 0
  assert(q>=-0.00001 and q<=row.budget+0.00001,'discharge cap exceeded')
  row.state.j=row.state.j-q;row.state.discharge_j=(row.state.discharge_j or 0)+q
  if row.state.j<1e-7 then row.state.j=0 end
  if not solo then assert(row.state.j+0.0001>=row.state.solo_reserve_j,'protected solo reserve accidentally shared') end
  drawn=drawn+q
 end
 assert(drawn<=request_j+0.001,'free energy from bus')
 return drawn,allocation,snap
end
return M