local mode='direct'
local W=1000000/60
local function ck(x,m)if not x then error('[LINE FAIL] '..mode..' '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function key(e)
 local n=e.electric_network;local p=n and n.parent_network;ck(p and p.valid,'no parent '..e.name);local id=n.id;for _,a in pairs(p.sub_networks)do if a.valid and a.id<id then id=a.id end end;return id
end
local function eei(s,n,pos,kind,rate,J)
 local e=s.create_entity{name=n,position=pos,force='player',raise_built=false};ck(e and e.valid,'EEI create');e.electric_interface_mode=defines.electric_interface_mode[kind];e.electric_buffer_size=4000000;e.power_usage=0;e.power_production=0;e.input_flow_limit=kind=='secondary_input' and rate or 0;e.output_flow_limit=kind=='secondary_output' and rate or 0;e.energy=J;return e
end
script.on_init(function()
 local s=game.create_surface('line-probe',{width=512,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-160,160,64 do for y=-64,64,64 do s.request_to_generate_chunks({x,y},2) end end;s.force_generate_chunk_requests()
 local st={s=s,lines={}}
 for i,y in ipairs({1,41}) do
  local l={};st.lines[i]=l
  for x=-143,143,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})end
  for x=-141.5,139,20 do local a=make(s,'em-35kv-catenary-pole',x,y+1.5);if x==-21.5 then l.mast=a end end
  l.sub=make(s,'em-35kv-traction-substation',-20,y+8,{auto_connect=false})
 end
 st.factory=eei(s,'electric-energy-interface',{x=-20,y=13},'secondary_input',0,0)
 if (mode=='noimport' or mode=='direct') then
  st.loco=make(s,'em-electric-locomotive',41,1,{direction=defines.direction.west})
  for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do if not st.stop then local q=s.create_entity{name='train-stop',position={x=-120,y=1+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='LINE';st.stop=q elseif q and q.valid then q.destroy()end end end end
  ck(st.stop,'station');st.start=st.loco.position.x
 end
 storage.st=st
end)
local function snap(st,t)
 local h=0;local lab=game.surfaces['em-25kv-isolated-bridge-058'];for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end
 local p=remote.call('em072_native_qa_071','snapshot').paid_J
 local z=remote.call('em089_onboard_storage','snapshot');local q=remote.call('em091_brake_recovery','snapshot');local bus=st.receiver and remote.call('em088_train_energy','snapshot',st.receiver.unit_number);local rx=bus and bus.owners[1] and bus.owners[1].loco_J or 0
 local sum=h+st.factory.energy+p+z.stored_J+z.discharged_J+z.lost_J-q.recovered_J-q.qa_pending_J
 ck(math.abs(sum-2000000)<1,'closed J '..sum);ck(math.abs(q.estimated_J-q.recovered_J-q.rejected_J-q.qa_pending_J)<.05,'offer accounting');ck(st.other.energy==0,'other corridor leak');ck(q.qa_grid_J+z.regen_J<=q.recovered_J+.05,'double claim')
 if t%30==0 or t==540 then log(string.format('[EXCHANGE] t=%d paid=%.6f receiver_paid=%.6f source=%.6f hidden=%.6f recovered=%.6f grid=%.6f fallback=%.6f pending=%.6f battery=%.6f total=%.6f sender_v=%.9f receiver_v=%.9f',t,p,rx,st.source.energy,h,q.recovered_J,q.qa_grid_J,q.qa_fallback_J,q.qa_pending_J,z.stored_J,sum,st.loco.train.speed,st.receiver and st.receiver.train.speed or 0))end
 return p,q,rx
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  local lab=game.surfaces['em-25kv-isolated-bridge-058'];ck(lab,'lab');local k1,k2=key(st.lines[1].mast),key(st.lines[2].mast);ck(k1~=k2 and k1~=key(st.lines[1].sub),'isolated')
  local p1,p2;for _,p in ipairs(lab.find_entities_filtered{name='em-25kv-bridge-port-058'})do if key(p)==k1 then p1=p elseif key(p)==k2 then p2=p end end
  ck(p1 and p2,'ports');st.source=eei(lab,'em092-qa-finite-source',p1.position,'secondary_output',2*W,2000000);st.other=eei(lab,'em-25kv-native-traction-consumer-068',p2.position,'secondary_input',2*W,0)
 elseif t==200 then
  ck(st.source.energy<.05,'seed not exhausted');local tr=st.loco.train;tr.schedule={current=1,records={{station='LINE',wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false
 elseif t==230 then
  st.receiver=make(st.s,'em-electric-locomotive',121,1,{direction=defines.direction.west});st.receiver_start=st.receiver.position.x
  local tr=st.receiver.train;tr.schedule={current=1,records={{station='LINE',wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false
 elseif t==235 then
  ck(math.abs(st.loco.train.speed)>.1,'sender not moving');st.loco.train.manual_mode=true
 end
 if t>=120 then local p,q,rx=snap(st,t)
  if t==540 then
   ck(q.qa_grid_J>1000,'no native accepted recovered J');ck(rx>1000,'no recipient debit');ck(st.receiver.position.x<st.receiver_start-.01,'recipient did not move');ck(st.factory.energy==0,'factory contribution');ck(q.qa_pending_J<.05,'pending at end');log('[EXCHANGE PASS] recovered to native grid='..q.qa_grid_J..' recipient='..rx..' displacement='..(st.receiver_start-st.receiver.position.x));script.finish_test(true)
  end
 end
end)
