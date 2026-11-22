local bus=require('bus')
local function make(s,name,x,y,opts)
 local v={name=name,position={x,y},force='player',raise_built=true}
 for k,q in pairs(opts or {}) do v[k]=q end
 local e=s.create_entity(v)
 assert(e and e.valid,'cannot create '..name..' '..x..','..y)
 return e
end
local function total_energy(p)
 local n=0
 for _,s in pairs(p.units) do n=n+s.j end
 for _,e in ipairs(p.locomotives) do
  assert(e.valid)
  n=n+(e.burner.remaining_burning_fuel or 0)
 end
 return n+p.native_spent
end
local function add_to_native_burner(e,j)
 if j<=0 then return 0 end
 local b=e.burner
 if not b.currently_burning then b.currently_burning='em-b10-token' end
 local before=b.remaining_burning_fuel
 b.remaining_burning_fuel=before+j
 local credited=b.remaining_burning_fuel-before
 assert(math.abs(credited-j)<0.01,'native burner rejected J')
 return credited
end
local function count_in(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function setup()
 local s=game.create_surface('b10-native-consist-bus',{width=1024,height=256})
 s.generate_with_lab_tiles=true;s.request_to_generate_chunks({120,0},20);s.force_generate_chunk_requests()
 for x=-300,700,2 do make(s,'straight-rail',x,1,{direction=defines.direction.east}) end
 local a=make(s,'em-b10-battery-loco',0,1,{direction=defines.direction.east})
 local b=make(s,'em-b10-battery-loco',7,1,{direction=defines.direction.east})
 local c=make(s,'em-b10-powered-wagon',14,1,{direction=defines.direction.east})
 local d=make(s,'em-b10-battery-loco',-180,1,{direction=defines.direction.east})
 assert(a.train.id==b.train.id and b.train.id==c.train.id,'need genuine 3-unit native consist')
 assert(d.train.id~=a.train.id,'solo locomotive accidentally coupled')
 local units={
  [a.unit_number]={j=600000,capacity_j=600000,solo_reserve_j=200000,max_discharge_w=1000000,kind='locomotive'},
  [b.unit_number]={j=600000,capacity_j=600000,solo_reserve_j=200000,max_discharge_w=1000000,kind='locomotive'},
  [c.unit_number]={j=400000,capacity_j=400000,solo_reserve_j=100000,max_discharge_w=500000,kind='future-motor-wagon'},
  [d.unit_number]={j=300000,capacity_j=300000,solo_reserve_j=150000,max_discharge_w=300000,kind='locomotive'}
 }
 local p={s=s,a=a,b=b,c=c,d=d,units=units,locomotives={a,b,d},native_spent=0,prev={},native_grants=0,
      driver_a=nil,driver_d=nil,solo_start_x=d.position.x,consist_start_x=a.position.x,coupling_event_count=0,
      coupled_units=0,solo_initial_j=units[d.unit_number].j,starting_j=1900000,previous_train_ids={},loaded_once=false}
 for _,e in ipairs(p.locomotives) do p.prev[e.unit_number]=e.burner.remaining_burning_fuel end
 storage.b10=p
 local snap=bus.snapshot(a.train,units)
 assert(snap.n==3 and #a.train.carriages==3 and math.abs(snap.energy_j-1600000)<0.01)
 assert(math.abs(snap.protected_j-500000)<0.01 and math.abs(snap.shareable_j-1100000)<0.01)
 log('[EM072 B10 TOPOLOGY PASS] native_train3=true native_solo1=true powered_members=3 shared_J=1100000 solo_protected_J=500000 total_unit_J=1900000')
end
script.on_event(defines.events.on_train_created,function(ev)
 local p=storage.b10
 if not p or not(ev.train and ev.train.valid) then return end
 p.coupling_event_count=p.coupling_event_count+1
 log('[EM072 B10 NATIVE on_train_created] tick='..ev.tick..' new='..ev.train.id..' old1='..tostring(ev.old_train_id_1)..' old2='..tostring(ev.old_train_id_2)..' carriages='..#ev.train.carriages)
end)
local function update_spent(p)
 for _,e in ipairs(p.locomotives) do
  local v=e.burner.remaining_burning_fuel or 0
  local prev=p.prev[e.unit_number]
  if prev>v then p.native_spent=p.native_spent+(prev-v) end
  p.prev[e.unit_number]=v
 end
end
local function drive(s,e,x)
 local d=make(s,'character',x,-8);e.set_driver(d)
 assert(e.get_driver()==d)
 e.train.manual_mode=true
 d.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 return d
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick
 if t==1 then setup() end
 local p=storage.b10;if not p then return end
 update_spent(p)
 if t==20 then
  assert(p.a.train.id==p.b.train.id and p.b.train.id==p.c.train.id)
  assert(#p.a.train.carriages==3 and #p.d.train.carriages==1)
 end
 if t==30 then
  local original={p.a.train.id,p.d.train.id}
  assert(p.b.disconnect_rolling_stock(defines.rail_direction.front),'genuine native split1 failed')
  assert(p.b.disconnect_rolling_stock(defines.rail_direction.back),'genuine native split2 failed')
  assert(p.a.train.id~=p.b.train.id and p.b.train.id~=p.c.train.id and p.a.train.id~=p.c.train.id,'native split did not isolate the units')
  assert(#p.a.train.carriages==1 and #p.b.train.carriages==1 and #p.c.train.carriages==1,'native split unit composition')
  assert(math.abs(total_energy(p)-p.starting_j)<0.01,'split changed energy without work')
  log('[EM072 B10 REAL SPLIT PASS] four distinct train IDs; all J preserved by unit_number')
 end
 if t==35 then
  assert(p.b.connect_rolling_stock(defines.rail_direction.front),'native front reconnect failed')
  assert(p.b.connect_rolling_stock(defines.rail_direction.back),'native back reconnect failed')
  local snap=bus.snapshot(p.a.train,p.units)
  assert(snap.n==3 and #p.a.train.carriages==3,'native rejoin must expose 3 stocks')
  assert(math.abs(snap.energy_j-1600000)<0.01,'rejoin changed J')
  assert(math.abs(total_energy(p)-p.starting_j)<0.01,'rejoin energy not conserved')
  log('[EM072 B10 REAL REJOIN PASS] 3 member train; 0 J created, solo untouched')
 end
 if t>=41 and t<=84 then
  -- LAB demonstration of strictly finite logic: 1.5MW demand, 3 connected sources
  -- (one of which is a non-propelling wagon prototype), Native LuaBurner receives paid J.
  local j=bus.take(p.a.train,p.units,1500000/60,1/60)
  local credited=add_to_native_burner(p.a,j)
  assert(math.abs(j-credited)<0.01)
  p.native_grants=p.native_grants+credited
  p.prev[p.a.unit_number]=p.a.burner.remaining_burning_fuel
 end
 if t==75 then
  local ok,err=pcall(function()game.server_save('em072a5-b10-checkpoint')end)
  log('[EM072 B10 DISK SAVE] tick=75 requested='..tostring(ok)..' err='..tostring(err))
 end
 if t==85 then
  for _,e in ipairs({p.a,p.b,p.c}) do
   local u=p.units[e.unit_number]
   assert(math.abs(u.j-u.solo_reserve_j)<0.01,'must preserve own maneuver battery below sharing floor')
  end
  assert(math.abs(p.native_grants-1100000)<0.01,'wrong shared paid bus energy')
  assert(math.abs(total_energy(p)-p.starting_j)<0.01,'energy after combined load not conserved')
  log('[EM072 B10 BUS RESERVE PASS] 1100000 J shared and native-burner credited; protected 500000 J retained across 3 units')
  p.driver_a=drive(p.s,p.a,p.a.position.x)
  p.driver_d=drive(p.s,p.d,p.d.position.x)
 end
 if t>=86 and t<=155 then
  -- Standalone locomotive is the only source for itself. No line and no other member.
  -- It may spend its own protected solo reserve, up to 300 kW and finite 300 kJ.
  local request=300000/60
  local j=bus.take(p.d.train,p.units,request,1/60)
  local credited=add_to_native_burner(p.d,j)
  assert(math.abs(j-credited)<0.01)
  p.native_grants=p.native_grants+credited
  p.prev[p.d.unit_number]=p.d.burner.remaining_burning_fuel
 end
 if t==156 then
  local solo=p.units[p.d.unit_number]
  assert(solo.j<0.1,'solo locomotive failed to use its own last protected reserve')
  for _,e in ipairs({p.a,p.b,p.c}) do
   local st=p.units[e.unit_number];assert(math.abs(st.j-st.solo_reserve_j)<0.01) end
  local delta=p.d.position.x-p.solo_start_x
  assert(delta>0.5,'genuine standalone locomotive did not move on its own finite reserve')
  local coupled_delta=p.a.position.x-p.consist_start_x
  assert(coupled_delta>0.5,'real native consist did not move on finite energy pooled from coupled members')
  local energy=total_energy(p)
  assert(math.abs(energy-p.starting_j)<0.01,'native burner + batteries + spent ledger not closed '..energy)
  assert(math.abs(p.native_grants-1400000)<0.02,'incorrect total bus + solo contributions')
  log(string.format('[EM072 B10 BATTERY BUS NATIVE PASS] real_split_rejoin_events=%d coupled_moving_delta=%.4f solo_moving_delta=%.4f train_bus_grants_J=1100000 solo_grants_J=300000 protected_coupled_J=500000 solo_remaining_J=%.4f native_spent_J=%.4f total_ledger_residual_J=%.6f',p.coupling_event_count,coupled_delta,delta,solo.j,p.native_spent,energy-p.starting_j))
 end
 if t==180 then
  assert(math.abs(total_energy(p)-p.starting_j)<0.01,'last native ledger no energy creation')
  log('[EM072 B10 FINAL PASS] 180 native Factorio ticks + real solo reserve movement + shared-bus energy and native split/rejoin')
 end
end)