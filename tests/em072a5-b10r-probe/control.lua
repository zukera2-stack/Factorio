-- B10R research-only. Battery exists ONLY on locomotive unit_number, NEVER on wagons.
local bus=require('bus')
local function make(s,name,x,y,opts)
 local v={name=name,position={x,y},force='player',raise_built=true}
 for k,q in pairs(opts or {}) do v[k]=q end
 local e=s.create_entity(v)
 assert(e and e.valid,'cannot create '..name..' '..x..','..y)
 return e
end
local function near(a,b,eps) return math.abs(a-b)<(eps or .01) end
local function total_energy(p)
 local n=p.native_spent
 for id,st in pairs(p.units) do
  assert(st.kind=='locomotive','INVALID storage owner '..id)
  assert(st.j>=-.01 and st.j<=st.capacity_j+.01,'invalid locomotive energy balance')
  n=n+st.j
 end
 for _,e in ipairs(p.locomotives) do assert(e.valid);n=n+(e.burner.remaining_burning_fuel or 0) end
 return n
end
local function credited(e,j)
 if j<=0 then return 0 end
 local b=e.burner
 if not b.currently_burning then b.currently_burning='em-b10r-token' end
 local before=b.remaining_burning_fuel or 0
 b.remaining_burning_fuel=before+j
 local paid=b.remaining_burning_fuel-before
 assert(near(paid,j),'native LuaBurner rejected finite J')
 return paid
end
local function drive(p,e)
 local d=make(p.s,'character',e.position.x,-8)
 e.set_driver(d)
 assert(e.get_driver()==d)
 e.train.manual_mode=true
 d.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 return d
end
local function setup()
 local s=game.create_surface('b10r-native-loco-bus',{width=1024,height=256})
 s.generate_with_lab_tiles=true;s.request_to_generate_chunks({120,0},20);s.force_generate_chunk_requests()
 for x=-300,700,2 do make(s,'straight-rail',x,1,{direction=defines.direction.east}) end
 local a=make(s,'em-b10r-battery-loco',0,1,{direction=defines.direction.east})
 local b=make(s,'em-b10r-battery-loco',7,1,{direction=defines.direction.east})
 local c=make(s,'em-b10r-motor-cargo-wagon',14,1,{direction=defines.direction.east})
 local f=make(s,'em-b10r-motor-fluid-wagon',21,1,{direction=defines.direction.east})
 local d=make(s,'em-b10r-battery-loco',-180,1,{direction=defines.direction.east})
 assert(a.train.id==b.train.id and b.train.id==c.train.id and c.train.id==f.train.id,'need 4 native cars as genuine coupled train')
 assert(d.train.id~=a.train.id,'solo mistakenly coupled')
 local units={
  [a.unit_number]={j=600000,capacity_j=600000,solo_reserve_j=200000,max_discharge_w=1000000,kind='locomotive'},
  [b.unit_number]={j=600000,capacity_j=600000,solo_reserve_j=200000,max_discharge_w=1000000,kind='locomotive'},
  [d.unit_number]={j=300000,capacity_j=300000,solo_reserve_j=150000,max_discharge_w=300000,kind='locomotive'}
 }
 assert(units[c.unit_number]==nil and units[f.unit_number]==nil,'WAGON BATTERY FORBIDDEN')
 local p={s=s,a=a,b=b,c=c,f=f,d=d,units=units,locomotives={a,b,d},native_spent=0,prev={},native_grants=0,
  group_native_grants=0,independent_solo_grants=0,former_member_solo_grants=0,
  solo_start_x=d.position.x,consist_start_x=a.position.x,former_start_x=0,
  coupling_event_count=0,starting_j=1500000,disconnected_wagon_grants=0}
 for _,e in ipairs(p.locomotives) do p.prev[e.unit_number]=e.burner.remaining_burning_fuel end
 storage.b10r=p
 local snap=bus.snapshot(a.train,units)
 assert(snap.n==2 and #a.train.carriages==4 and near(snap.energy_j,1200000))
 assert(near(snap.protected_j,400000) and near(snap.shareable_j,800000))
 assert(snap.motor_cargo_count==1 and snap.motor_fluid_count==1 and snap.nominal_nameplate_w==5000000)
 assert(near(total_energy(p),p.starting_j))
 log('[B10R TOPOLOGY PASS] native_consist=4 loco_sources=2 motor_cargo=1 motor_fluid=1 wagon_battery_count=0 nameplate_only_MW=5 battery_initial_J=1500000 shareable_J=800000')
end
script.on_event(defines.events.on_train_created,function(ev)
 local p=storage.b10r
 if not p or not(ev.train and ev.train.valid) then return end
 p.coupling_event_count=p.coupling_event_count+1
 log('[B10R NATIVE on_train_created] tick='..ev.tick..' new='..ev.train.id..' old1='..tostring(ev.old_train_id_1)..' old2='..tostring(ev.old_train_id_2)..' carriages='..#ev.train.carriages)
end)
local function count_spent(p)
 for _,e in ipairs(p.locomotives) do
  local current=e.burner.remaining_burning_fuel or 0
  local prev=p.prev[e.unit_number]
  if prev>current then p.native_spent=p.native_spent+(prev-current) end
  p.prev[e.unit_number]=current
 end
end
local function grant(p,e,j,label)
 local q=credited(e,j)
 assert(near(q,j),'script failed to credit native paid battery')
 p.native_grants=p.native_grants+q
 if label=='group' then p.group_native_grants=p.group_native_grants+q
 elseif label=='independent' then p.independent_solo_grants=p.independent_solo_grants+q
 elseif label=='former' then p.former_member_solo_grants=p.former_member_solo_grants+q end
 p.prev[e.unit_number]=e.burner.remaining_burning_fuel
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick
 if t==1 then setup() end
 local p=storage.b10r;if not p then return end
 count_spent(p)
 if t==30 then
  assert(p.b.disconnect_rolling_stock(defines.rail_direction.front),'genuine first split failed')
  assert(p.b.disconnect_rolling_stock(defines.rail_direction.back),'genuine second split failed')
  assert(#p.a.train.carriages==1 and #p.b.train.carriages==1 and #p.c.train.carriages==2,'native split geometry changed')
  assert(p.c.train.id==p.f.train.id,'motor wagons should remain coupled')
  local wagon_only=bus.snapshot(p.c.train,p.units)
  assert(wagon_only.n==0 and wagon_only.energy_j==0 and wagon_only.shareable_j==0 and wagon_only.peak_w==0)
  local q=bus.take(p.c.train,p.units,100000,1/60)
  assert(q==0,'motor wagons got free J without locomotive')
  assert(near(total_energy(p),p.starting_j))
  log('[B10R SPLIT PASS] wagon_only_native_train=2 wagon_saved_J=0 wagon_traction_grants_J=0 physical_loco_battery_unit_id_preserved=true')
 end
 if t==35 then
  assert(p.b.connect_rolling_stock(defines.rail_direction.front),'rejoin front failed')
  assert(p.b.connect_rolling_stock(defines.rail_direction.back),'rejoin back failed')
  local snap=bus.snapshot(p.a.train,p.units)
  assert(#p.a.train.carriages==4 and snap.n==2 and snap.motor_cargo_count==1 and snap.motor_fluid_count==1)
  assert(near(snap.energy_j,1200000) and near(snap.protected_j,400000) and near(total_energy(p),p.starting_j))
  log('[B10R REJOIN PASS] two locomotive battery owners, two motor wagons NO battery, 0 new J by coupling')
 end
 if t==36 then
  for _,wagon in ipairs({p.c,p.f}) do
   -- Negative acceptance: even an improperly injected saved battery record on a wagon must fail closed.
   local before=total_energy(p)
   p.units[wagon.unit_number]={j=100,capacity_j=100,solo_reserve_j=0,max_discharge_w=500000,kind='locomotive'}
   local ok=pcall(function()return bus.snapshot(p.a.train,p.units)end)
   p.units[wagon.unit_number]=nil
   assert(not ok,'forbidden motor wagon battery record was accepted')
   assert(near(total_energy(p),before),'illegal test changed locomotive energy')
  end
  log('[B10R WAGON FORGED BATTERY REJECTED PASS] both motor cargo and motor fluid records rejected; no Joules created')
 end
 if t>=41 and t<=84 then
  local j=bus.take(p.a.train,p.units,1200000/60,1/60)
  grant(p,p.a,j,'group')
 end
 if t==85 then
  local a=p.units[p.a.unit_number];local b=p.units[p.b.unit_number]
  assert(near(a.j,200000) and near(b.j,200000))
  assert(near(p.group_native_grants,800000))
  assert(p.units[p.c.unit_number]==nil and p.units[p.f.unit_number]==nil)
  assert(near(total_energy(p),p.starting_j))
  p.driver_a=drive(p,p.a)
  p.driver_d=drive(p,p.d)
  log('[B10R GROUP RESERVE PASS] loco_A_reserve_J=200000 loco_B_reserve_J=200000 donated_only_over_reserve_J=800000 motor_wagon_storage_J=0')
 end
 if t>=86 and t<=155 then
  local j=bus.take(p.d.train,p.units,300000/60,1/60)
  grant(p,p.d,j,'independent')
 end
 if t==156 then
  assert(near(p.units[p.d.unit_number].j,0))
  assert(near(p.independent_solo_grants,300000))
  assert(p.a.position.x-p.consist_start_x>.5,'native coupled train did not move using finite locomotive batteries')
  assert(p.d.position.x-p.solo_start_x>.5,'native independent solo locomotive did not move')
  assert(near(total_energy(p),p.starting_j))
  log(string.format('[B10R BEFORE FORMER MEMBER SPLIT PASS] group_moved_tiles=%.4f independent_solo_moved_tiles=%.4f group_J=%.0f solo_J=%.0f',p.a.position.x-p.consist_start_x,p.d.position.x-p.solo_start_x,p.group_native_grants,p.independent_solo_grants))
 end
 if t==160 then
  assert(p.b.disconnect_rolling_stock(defines.rail_direction.front),'second split front failed')
  assert(p.b.disconnect_rolling_stock(defines.rail_direction.back),'second split back failed')
  assert(#p.b.train.carriages==1 and #p.c.train.carriages==2 and #p.a.train.carriages==1,'second split must isolate former loco')
  assert(near(p.units[p.b.unit_number].j,200000),'former member lost own protected reserve during split')
  p.former_start_x=p.b.position.x
  local q=bus.take(p.c.train,p.units,100000,1/60)
  assert(q==0,'wagon-only detached train cannot supply J')
  assert(near(total_energy(p),p.starting_j))
  log('[B10R FORMER MEMBER SPLIT PASS] loco_B_solo_reserved_J=200000 preserved=true motor_wagons_J=0')
 end
 if t==162 then p.driver_b=drive(p,p.b) end
 if t>=163 and t<=202 then
  local j=bus.take(p.b.train,p.units,600000/60,1/60)
  grant(p,p.b,j,'former')
 end
 if t==205 then
  local moved=p.b.position.x-p.former_start_x
  assert(moved>.5,'formerly coupled locomotive did not move on its own protected battery reserve')
  assert(near(p.former_member_solo_grants,200000))
  assert(near(p.units[p.b.unit_number].j,0))
  assert(near(p.units[p.a.unit_number].j,200000))
  assert(p.units[p.c.unit_number]==nil and p.units[p.f.unit_number]==nil)
  assert(near(total_energy(p),p.starting_j))
  log(string.format('[B10R VERIFIED PASS] split_events=%d group_moved_tiles=%.4f independent_solo_moved_tiles=%.4f former_member_solo_moved_tiles=%.4f pooled_battery_to_burner_J=%.0f original_solo_to_burner_J=%.0f former_solo_to_burner_J=%.0f remaining_A_protected_J=%.0f wagon_saved_J=0 gross_native_spent_J=%.3f finite_ledger_residual_J=%.6f',p.coupling_event_count,p.a.position.x-p.consist_start_x,p.d.position.x-p.solo_start_x,moved,p.group_native_grants,p.independent_solo_grants,p.former_member_solo_grants,p.units[p.a.unit_number].j,p.native_spent,total_energy(p)-p.starting_j))
 end
 if t==100 then
  local ok,err=pcall(function()game.server_save('em072a5-b10r-checkpoint')end)
  log('[B10R DISK SAVE] tick=100 requested='..tostring(ok)..' err='..tostring(err))
 end
 if t==240 then
  assert(near(total_energy(p),p.starting_j))
  assert(p.c.valid and p.f.valid)
  log('[B10R FINAL PASS] 240 native ticks, two compliant motor wagons NO batteries, split/merge, former-loco solo after split, zero created J')
 end
end)