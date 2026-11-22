local B8_FORCE_MANUAL_IMPORT=false -- explicitly changed ONLY in manual-import counterfactual
-- Research-only B8: 2 genuine EM070 in AUTO, SAME native HSR and SAME corridor electric network.
-- Real Factory A/B energy sources are physically disjoint, battery inventories native and finite.
local function make(s,name,x,y,opts)
 local args={name=name,position={x,y},force='player',raise_built=true}
 for k,v in pairs(opts or {}) do args[k]=v end
 local e=s.create_entity(args)
 assert(e and e.valid,'cannot create '..name..' x='..x..' y='..y)
 return e
end
local function sum(list)
 local n=0;for _,e in ipairs(list) do assert(e.valid);n=n+e.energy end;return n
end
local function setup()
 local surface=game.create_surface('em072a5-b8-ONE-real-HSR',{width=2048,height=512})
 surface.generate_with_lab_tiles=true;surface.daytime=0.5;surface.always_day=true
 surface.request_to_generate_chunks({300,0},19);surface.force_generate_chunk_requests()
 local rails={};for x=-200,950,2 do rails[#rails+1]=make(surface,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
 local masts={};for x=-141.5,618.5,20 do masts[#masts+1]=make(surface,x==-141.5 and 'em-35kv-catenary-pole-north' or 'em-35kv-catenary-pole',x,2.5) end
 local a=make(surface,'em-35kv-traction-substation',-20,9)
 local b=make(surface,'em-35kv-traction-substation',500,9)
 local fa,fb={},{}
 for x=-56,24,4 do for _,y in ipairs({14,18,27,31}) do fa[#fa+1]=make(surface,'accumulator',x,y) end end
 for x=464,544,4 do for _,y in ipairs({14,18,27,31}) do fb[#fb+1]=make(surface,'accumulator',x,y) end end
 assert(#fa==84 and #fb==84)
 for _,e in ipairs(fa) do e.energy=5000000 end
 for _,e in ipairs(fb) do e.energy=5000000 end
 for x=-48,16,16 do make(surface,'substation',x,23) end
 for x=472,536,16 do make(surface,'substation',x,23) end
 local load=make(surface,'em072a5-b6-native-factory-load',500,23,{raise_built=false})
 load.energy=0;load.electric_interface_mode=defines.electric_interface_mode.secondary_input
 load.input_flow_limit=0
 local controller=make(surface,'em072a5-b3-outpost-controller',-142,7)
 local meter=make(surface,'em072a5-b1-native-traction-meter',-140,7,{raise_built=false})
 meter.energy=0;meter.electric_interface_mode=defines.electric_interface_mode.secondary_input
 assert(meter.input_flow_limit>0)
 assert(remote.call('em072a5_b0_native','meter_register',meter.unit_number))
 local locos,drivers,ids,starts,prev,got,spent={},{},{},{},{},{},{}
 for i=0,15 do
  local x=-128+i*32
  local loco=make(surface,'em072a5-b0-burner-loco',x,1,{direction=defines.direction.east})
  locos[#locos+1]=loco;starts[#starts+1]=x;ids[#ids+1]=loco.unit_number;prev[#prev+1]=0;got[#got+1]=0;spent[#spent+1]=0
  local d=make(surface,'character',x,-8);drivers[#drivers+1]=d
  loco.set_driver(d);assert(loco.get_driver()==d);loco.train.manual_mode=true
  d.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 end
 assert(remote.call('em072a5_b0_native','register',ids))
 storage.b8={surface=surface,rails=rails,masts=masts,station_a=a,station_b=b,fa=fa,fb=fb,load=load,controller=controller,meter=meter,
  locos=locos,drivers=drivers,ids=ids,starts=starts,prev=prev,got=got,spent=spent,factory_spent=0,shortfall_ticks=0,
  snapshots={},initial_j=0,train_total_j=0,peak=0,pre_plan_a=0,pre_plan_b=0,pre_import_a=0,pre_import_b=0,pre_physical_train_j=0}
 log('[EM072A5 B8 SETUP] 2 real EM070 on 1 continuous native HSR, 168 genuine finite factory accumulators, 16 native trains')
end
local function total_energy(p)
 local n=sum(p.fa)+sum(p.fb)+p.load.energy+p.meter.energy
 local status=remote.call('em072a5_b8_status','snapshot')
 for _,r in pairs(status) do n=n+r.source_input_j+r.line_output_j end
 for _,loco in ipairs(p.locos) do n=n+loco.burner.remaining_burning_fuel end
 return n
end
local function audit(p,t)
 local st=remote.call('em072a5_b8_status','snapshot')
 local f1=p.fa[1].electric_network_id;local f2=p.fb[1].electric_network_id;local line=p.meter.electric_network_id
 assert(f1 and f2 and line and f1~=f2 and f1~=line and f2~=line,'factory copper networks were accidentally shorted')
 assert(p.load.electric_network_id==f2,'30MW native industrial test consumer MUST be on factory B, not factory A')
 assert(st.a.factory_id==f1 and st.b.factory_id==f2 and st.a.line_id==line and st.b.line_id==line,
   'two genuine EM070 must feed SAME corridor electric ID; factory ports must stay isolated')
 assert(p.masts[1].electric_network_id==line and p.masts[#p.masts].electric_network_id==line,'technical mast native corridor failed continuity')
 if t==90 then log('[EM072A5 B8 TOPOLOGY PASS] two independent native factory IDs, shared native line network ID, true connected 1 HSR geometry') end
 return st
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick
 if t==1 then setup() end
 local p=storage.b8;if not p then return end
 local seen={}
 for i,loco in ipairs(p.locos) do
  assert(loco.valid and loco.train and loco.train.valid)
  seen[loco.train.id]=true
  local now=loco.burner.remaining_burning_fuel
  p.spent[i]=p.spent[i]+math.max(0,p.prev[i]-now)
  p.prev[i]=now
 end
 if t==35 then local count=0;for _ in pairs(seen) do count=count+1 end;assert(count==16,'missing independent LuaTrain.ids') end
 if t==65 then
  assert(remote.call('em072a5_b3_terminal','attach',p.controller.unit_number,p.masts[1].unit_number))
  assert(remote.call('em072a5_b8_status','register',p.station_a.unit_number,p.station_b.unit_number))
 end
 if t==90 then audit(p,t) end
 if t==91 then
  p.initial_j=total_energy(p)
  assert(math.abs(p.initial_j-840000000)<100000,'expected 840MJ finite source batteries initial total')
  log('[EM072A5 B8 FINITE BASELINE] t91 total native J='..p.initial_j)
 end
 if t==100 then
  assert(remote.call('em072a5_b3_terminal','enable_demand'))
  log('[EM072A5 B8 16 TRACTION REQUESTS] t100 16 real trains demand 32MW; no line-side accumulator')
 end
 if t>=101 and t<=495 then
  local grants=remote.call('em072a5_b0_native','take_all',p.station_a.unit_number)
  local total=0;local count=0;local low=math.huge;local high=0
  for i,loco in ipairs(p.locos) do
   local j=grants[loco.unit_number] or 0
   assert(j>=0 and j<=2000000/60+0.05,'one train >2MW')
   if j>0 then count=count+1 end
   low=math.min(low,j);high=math.max(high,j);total=total+j
   p.got[i]=p.got[i]+j;p.prev[i]=loco.burner.remaining_burning_fuel
  end
  assert(total<=32000000/60+0.05,'16 train total exceeds 32MW')
  assert(count==0 or count==16,'locomotive transfer must be fair to all qualified trains')
  if count>0 then assert(high-low<0.2,'not fair per tick');p.train_total_j=p.train_total_j+total;p.peak=math.max(p.peak,total) end
 end
 if t==120 then
  local st=audit(p,t)
  assert(st.a.mode=='auto' and st.b.mode=='auto','both stations must remain AUTO')
 end
 if t>=120 and t<=250 then
  local st=remote.call('em072a5_b8_status','snapshot')
  p.pre_plan_a=math.max(p.pre_plan_a,st.a.planned_mw)
  p.pre_plan_b=math.max(p.pre_plan_b,st.b.planned_mw)
  p.pre_import_a=st.a.transferred_j
  p.pre_import_b=st.b.transferred_j
 end
 if t==250 then
  local st=audit(p,t)
  log(string.format('[EM072A5 B8 DISTRIBUTION] stage=healthy plan_A=%.6fMW plan_B=%.6fMW actual_source_backed_A=%.3fJ B=%.3fJ demand=32MW',
   p.pre_plan_a,p.pre_plan_b,p.pre_import_a,p.pre_import_b))
  if p.pre_import_a>100000 and p.pre_import_b>100000 then
   log('[EM072A5 B8 DUAL IMPORT PASS] both native EEI station bridges had verified actual source-back transfer on same native corridor')
  else log('[EM072A5 B8 DUAL IMPORT NOT PROVEN] one station may be idle with shared network') end
 end
 if t==260 then
  if B8_FORCE_MANUAL_IMPORT then assert(remote.call('em072a5_b8_status','set_b_mode','import')) end
  p.load.input_flow_limit=30000000/60
  p.brownout_initial_train_j=p.train_total_j
  log('[EM072A5 B8 FACTORY B BROWNOUT] 30MW native consumer attached to FACTORY B (25.2MW battery ceiling)')
 end
 if t>=261 then
  local j=p.load.energy
  assert(j>=0 and j<=30000000/60+1,'industrial sink >30MW')
  p.factory_spent=p.factory_spent+j
  if t>=280 and j<30000000/60-1000 then p.shortfall_ticks=p.shortfall_ticks+1 end
  p.load.energy=0
 end
 if t%20==0 and t>=100 then
  local st=remote.call('em072a5_b8_status','snapshot')
  log(string.format('[EM072A5 B8 STATIONS] t=%d A=%s/%s plan=%.3fMW actual_J=%.3f B=%s/%s plan=%.3fMW actual_J=%.3f native_train_received_J=%.3f industrial_paid_J=%.3f',
   t,st.a.mode,tostring(st.a.direction),st.a.planned_mw,st.a.transferred_j,st.b.mode,tostring(st.b.direction),st.b.planned_mw,st.b.transferred_j,p.train_total_j,p.factory_spent))
 end
 if t==300 then
  local ok,err=pcall(function()game.server_save('em072a5-b8-checkpoint')end)
  log('[EM072A5 B8 DISK SAVE] tick=300 requested='..tostring(ok)..' err='..tostring(err))
 end
 if t==350 then
  assert(p.shortfall_ticks>20,'no real factory B brownout proved')
  local st=audit(p,t)
  assert(p.train_total_j>p.brownout_initial_train_j+3000000,'trains did not receive energy during brownout')
  log('[EM072A5 B8 BROWNOUT PASS] factory B 30MW under-supplied with battery 25.2MW; native-paid locomotive motion persists')
  log(string.format('[EM072A5 B8 DIRECTION] variant=%s t350 B_direction=%s B_plan_MW=%.3f B_source_to_line_J=%.3f B_line_to_factory_J=%.3f B_signed_net_import_J=%.3f',B8_FORCE_MANUAL_IMPORT and 'manual_import' or 'auto',tostring(st.b.direction),st.b.planned_mw,st.b.factory_to_corridor_j,st.b.corridor_to_factory_j,st.b.signed_net_import_j))
 end
 if t==496 then
  local st=audit(p,t)
  local sumgot,spent,minj,maxj,mintravel=0,0,math.huge,0,math.huge
  for i,loco in ipairs(p.locos) do
   sumgot=sumgot+p.got[i];spent=spent+p.spent[i]
   minj=math.min(minj,p.got[i]);maxj=math.max(maxj,p.got[i]);mintravel=math.min(mintravel,math.abs(loco.position.x-p.starts[i]))
  end
  local remaining=total_energy(p)
  local residual=p.initial_j-remaining-spent-p.factory_spent
  assert(math.abs(residual)<3,'GLOBAL shared-line energy ledger cannot close '..residual)
  local burner_left=0;for _,loco in ipairs(p.locos) do burner_left=burner_left+loco.burner.remaining_burning_fuel end
  assert(math.abs(sumgot-spent-burner_left)<3,'native burners account mismatch')
  assert(mintravel>0.1 and sumgot>10000000 and math.abs(maxj-minj)<2,'locomotive movement and fair metering failed')
  assert(p.shortfall_ticks>20,'no native brownout')

  log(string.format('[EM072A5 B8 SIGNED ENERGY PASS] variant=%s A_import_J=%.3f A_export_J=%.3f A_net_J=%.3f B_import_J=%.3f B_export_J=%.3f B_net_J=%.3f end_B_direction=%s',
    B8_FORCE_MANUAL_IMPORT and 'manual_import' or 'auto',st.a.factory_to_corridor_j,st.a.corridor_to_factory_j,st.a.signed_net_import_j,st.b.factory_to_corridor_j,st.b.corridor_to_factory_j,st.b.signed_net_import_j,tostring(st.b.direction)))
  log(string.format('[EM072A5 B8 NATIVE PASS] real_emu=2 native_trains=16 shared_HSR=true station_A_sourcebacked_J=%.3f station_B_sourcebacked_J=%.3f factory_B_shortfall_ticks=%d factory_B_consumed_J=%.3f locomotive_credit_J=%.3f loco_spent_J=%.3f unspent_native_burner_J=%.3f global_ledger_residual_J=%.6f min_movement_tiles=%.3f plan_A_peak_MW=%.6f plan_B_peak_MW=%.6f',
    st.a.transferred_j,st.b.transferred_j,p.shortfall_ticks,p.factory_spent,sumgot,spent,burner_left,residual,mintravel,p.pre_plan_a,p.pre_plan_b))
 end
end)