local W=1000000/60
local mode=script.test_arg or 'mixed'
local function ck(x,m) if not x then error('[MIX FAIL] '..m) end end
local function say(m) log('[MIX] '..mode..' '..m) end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {}) do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n..' '..x..','..y);return e
end
local function key(e)
 local n=e.electric_network;local p=n and n.parent_network
 ck(p and p.valid,'no parent '..e.name);local id=n.id;for _,a in pairs(p.sub_networks)do if a.valid and a.id<id then id=a.id end end;return id
end
local function wire(a,b)
 local c=defines.wire_connector_id.pole_copper
 ck(a.get_wire_connector(c,true).connect_to(b.get_wire_connector(c,true),false,defines.wire_origin.player),'wire '..a.name..' '..b.name)
end
local function unlink(a,b)
 local c=defines.wire_connector_id.pole_copper
 ck(a.get_wire_connector(c,true).disconnect_from(b.get_wire_connector(c,true),defines.wire_origin.player),'disconnect')
end
local function eei(s,x,y,kind,mw,energy)
 local e=make(s,'electric-energy-interface',x,y);e.electric_interface_mode=defines.electric_interface_mode[kind];e.electric_buffer_size=1000000000;e.energy=energy or 0;e.power_usage=0;e.power_production=0;e.input_flow_limit=kind=='secondary_input' and mw*W or 0;e.output_flow_limit=kind=='primary_output' and mw*W or 0;return e
end
script.on_init(function()
 local s=game.create_surface('mixed-outposts',{width=512,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-100,100,64 do for y=-64,64,64 do s.request_to_generate_chunks({x,y},2) end end;s.force_generate_chunk_requests()
 local st={s=s,lines={},subs={},batteries={},buffers={}}
 for i,y in ipairs({-39,1,41}) do
  local line={masts={},subs={}};st.lines[i]=line
  for x=-83,83,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east}) end
  for x=-81.5,79,20 do line.masts[#line.masts+1]=make(s,'em-35kv-catenary-pole',x,y+1.5) end
  local xs=i==1 and {-60,0} or i==2 and {-60,0,40} or {40,60};if mode=='ring' and i~=2 then xs[#xs+1]=-20 end
  for _,x in ipairs(xs) do local sub=make(s,'em-35kv-traction-substation',x,y+8,{auto_connect=false});line.subs[x]=sub;st.subs[#st.subs+1]=sub end
 end
 local a,b,c=st.lines[1].subs,st.lines[2].subs,st.lines[3].subs
 st.ab=make(s,'big-electric-pole',0,-11,{auto_connect=false});wire(a[0],st.ab);wire(st.ab,b[0])
 st.bc=make(s,'big-electric-pole',40,29,{auto_connect=false});wire(b[40],st.bc);wire(st.bc,c[40])
 if mode=='ring' then
  local prev=a[-20]
  for _,y in ipairs({-11,9,29}) do local p=make(s,'big-electric-pole',-20,y,{auto_connect=false});wire(prev,p);prev=p end
  wire(prev,c[-20])
 end
 if mode=='reverse' then
  st.source=eei(s,60,53,'primary_output',12,200000000);st.load=eei(s,-60,-27,'secondary_input',2,0)
 elseif mode=='solar' then
  st.panels={};for _,x in ipairs({-66,-62,-58,-54})do for _,y in ipairs({-27,-23})do st.panels[#st.panels+1]=make(s,'solar-panel',x,y)end end
  st.load=eei(s,60,53,'secondary_input',0.1,0);st.radar=make(s,'radar',64,53)
  s.always_day=false;s.freeze_daytime=true;s.daytime=0
 else st.source=eei(s,-60,-27,'primary_output',mode=='limit' and 60 or 12,mode=='limit' and 1000000000 or ((mode=='empty' or mode=='battery' or mode=='buffer') and 0 or 200000000));st.load=eei(s,60,53,'secondary_input',mode=='limit' and 40 or 2,0) end
 if mode=='train' then
  local y=41
  st.loco=make(s,'em-electric-locomotive',1,y,{direction=defines.direction.west})
  st.cargo=make(s,'em-motor-cargo-wagon',8,y,{direction=defines.direction.west})
  st.fluid=make(s,'em-motor-fluid-wagon',15,y,{direction=defines.direction.west})
  ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo');ck(st.fluid.insert_fluid{name='water',amount=9000}==9000,'fluid')
  for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do if not st.stop then local q=s.create_entity{name='train-stop',position={x=-60,y=y+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='OUTPOST';st.stop=q elseif q and q.valid then q.destroy()end end end end
  ck(st.stop,'train stop not connected');st.start=st.loco.position.x
 end
 for _,x in ipairs({-66,-62,-58,-54})do local e=make(s,'accumulator',x,13);e.energy=mode=='battery' and e.electric_buffer_size or 0;st.batteries[#st.batteries+1]=e end
 for _,x in ipairs({-6,-2,2,6})do local e=make(s,'accumulator',x,13);e.energy=mode=='buffer' and e.electric_buffer_size or 0;st.buffers[#st.buffers+1]=e end
 storage.st=st
end)
local function total(es)local t=0;for _,e in ipairs(es)do t=t+e.energy end;return t end
local function snapshot(st,t)
 local b,f=total(st.batteries),total(st.buffers);local s=st.source and st.source.energy or 0;local l=st.load.energy
 local lab=game.surfaces['em-25kv-isolated-bridge-058'];local h=0
 if lab then for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end end
 local paid=0;if st.loco then paid=remote.call('em072_native_qa_071','snapshot').paid_J;local bus=remote.call('em088_train_energy','snapshot',st.loco.unit_number);ck(math.abs(bus.paid_J-paid)<0.05,'bus global paid');ck(#bus.owners==1,'bus owner count');if t>=120 then ck(bus.owners[1].loco_J+bus.owners[1].motor_J>0,'bus credited') end;ck(not bus.battery_enabled and not bus.regen_enabled,'new energy source enabled');if t>=600 then ck(bus.owners[1].motor_J>0 and bus.owners[1].loco_J>0,'bus both consumers');say('bus paid='..bus.paid_J..' loco='..bus.owners[1].loco_J..' motor='..bus.owners[1].motor_J) end end
 say(string.format('t=%d source_J=%.3f load_J=%.3f battery_J=%.3f buffer_J=%.3f hidden_J=%.3f paid_train_J=%.3f total_J=%.3f',t,s,l,b,f,h,paid,s+l+b+f+h+paid));return {s=s,l=l,b=b,f=f,h=h,total=s+l+b+f+h+paid,paid=paid}
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st;local a,b,c=st.lines[1],st.lines[2],st.lines[3]
 if t==901 and not script.test_arg then game.server_save('mixed-outposts-t901') end
 if t==120 then
  local k={key(a.masts[4]),key(b.masts[4]),key(c.masts[4])};ck(k[1]~=k[2] and k[1]~=k[3] and k[2]~=k[3],'corridors not separate')
  ck(key(a.subs[0])==key(b.subs[0]),'A-B vanilla grid not connected');ck(key(b.subs[40])==key(c.subs[40]),'B-C vanilla grid not connected');ck(key(a.subs[0])~=key(b.subs[40]),'transit grids merged')
  for _,sub in ipairs(st.subs)do for _,id in ipairs(k)do ck(key(sub)~=id,'factory shorted to corridor')end end
  for _,e in ipairs(st.batteries)do ck(key(e)==key(b.subs[-60]),'battery not on outpost')end
  for _,e in ipairs(st.buffers)do ck(key(e)==key(b.subs[0]),'buffer not on transit grid')end
  if mode=='reverse' then ck(key(st.source)==key(c.subs[60]) and key(st.load)==key(a.subs[-60]),'reverse wiring')
  elseif mode=='solar' then for _,p in ipairs(st.panels) do ck(key(p)==key(a.subs[-60]),'solar not connected')end;ck(key(st.radar)==key(c.subs[60]),'radar not connected')
  else ck(key(st.source)==key(a.subs[-60]) and key(st.load)==key(c.subs[60]),'source/load wiring') end
  if mode=='ring' then ck(key(a.subs[-20])==key(c.subs[-20]) and key(a.subs[-20])~=key(a.subs[0]) and key(a.subs[-20])~=key(b.subs[40]),'ring wiring')end
  if st.loco then local tr=st.loco.train;ck(#tr.carriages==4,'train not coupled with helper');tr.schedule={current=1,records={{station=st.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false end
  say('topology PASS corridors='..table.concat(k,',')..' transit='..key(a.subs[0])..','..key(b.subs[40]));snapshot(st,t)
 elseif mode=='empty' or mode=='battery' or mode=='buffer' then
  if t==600 then local q=snapshot(st,t);local budget=mode=='empty' and 0 or 20000000;ck(math.abs(q.total-budget)<100,'isolated reserve energy balance');if mode=='empty' then ck(q.l<1,'free energy on empty network') else ck(q.l>1000000,'reserve cannot feed remote load');if mode=='battery' then ck(q.b<20000000 and q.f<100,'battery charge cycles into buffer')else ck(q.f<20000000 and q.b<100,'buffer charge cycles into battery')end end;say('PASS independent '..mode..' source');script.finish_test(true) end
 elseif mode=='limit' then
  if t==240 then st.pre=snapshot(st,t)
  elseif t==480 then local q=snapshot(st,t);local moved=q.l-st.pre.l;ck(moved>50000000 and moved<=80000000+333334,'20MW path cap/underdelivery '..moved);ck(math.abs(q.total-1000000000)<100,'limit energy balance');say('path delivered_J='..moved..' average_W='..moved/4);script.finish_test(true) end
  if t>=120 then local lab=game.surfaces['em-25kv-isolated-bridge-058'];if lab then for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do ck(e.input_flow_limit<=20000000/60+1 and e.output_flow_limit<=20000000/60+1,'bridge limit exceeded') end end end
 elseif t==600 and mode=='solar' then
  st.pre=snapshot(st,t);local f=a.subs[-60].electric_network.parent_network.flow_last_tick;local g=st.radar.electric_network.parent_network.flow_last_tick
  say('solar_output_J_tick='..f.solar_output..' radar_net_secondary_demand_J_tick='..g.secondary_demand..' radar_energy_J='..st.radar.energy)
  ck(f.solar_output>0 and st.pre.l>100000 and st.radar.energy>0,'native solar/radar failed');ck(st.pre.b+st.pre.f>10000,'no solar surplus stored');st.s.daytime=0.5
 elseif t==900 and mode=='solar' then
  st.off=snapshot(st,t);local f=a.subs[-60].electric_network.parent_network.flow_last_tick;say('dark solar_output_J_tick='..f.solar_output);ck(f.solar_output<1,'solar not dark');ck(st.off.b+st.off.f<st.pre.b+st.pre.f,'no storage release at night');st.s.daytime=0
 elseif t==1500 and mode=='solar' then
  local q=snapshot(st,t);local f=a.subs[-60].electric_network.parent_network.flow_last_tick;ck(f.solar_output>0 and q.l>st.off.l,'solar restart failed');say('PASS native solar panels, radar, metered load and storage day/night/day');script.finish_test(true)
 elseif mode=='solar' then if t%120==0 then snapshot(st,t)end
 elseif t==600 then
  st.pre=snapshot(st,t);ck(st.pre.l>1000000,'remote load starvation');ck(st.pre.b>100000 and st.pre.f>100000,'battery or buffer not charging');ck(st.pre.total<=200000000+100,'created energy before outage');if st.loco then ck(st.loco.train.station==st.stop and math.abs(st.loco.position.x-st.start)>10,'train not arrived');ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and st.fluid.get_fluid_count('water')==9000,'train payload');ck(st.pre.paid>1000000,'train not paid');say('train arrived distance='..math.abs(st.loco.position.x-st.start)..' paid_J='..st.pre.paid) end;st.source.output_flow_limit=0
 elseif t==900 then
  st.off=snapshot(st,t);ck(st.off.s>=st.pre.s-100,'source still discharging');ck(st.off.l>st.pre.l+100000,'storage did not supply load');ck(st.off.b+st.off.f<st.pre.b+st.pre.f,'storage did not discharge');ck(st.off.total<=200000000+100,'created energy after outage');if mode=='reverse' then say('PASS reverse source/load and battery backup');script.finish_test(true);return end;st.source.output_flow_limit=12*W;unlink(st.bc,c.subs[40]);st.cut=st.load.energy
 elseif t==1200 then
  st.split=snapshot(st,t);ck(key(b.subs[40])~=key(c.subs[40]),'B-C cut failed');if mode=='ring' then ck(st.split.l-st.cut>1000000,'alternate path did not supply load') else ck(st.split.l-st.cut<3000000,'unbounded power across cut')end;wire(st.bc,c.subs[40])
 elseif t==1500 then
  local q=snapshot(st,t);ck(key(b.subs[40])==key(c.subs[40]),'rejoin failed');ck(q.l>st.split.l+100000,'load no recovery');ck(q.total<=200000000+100,'energy creation');say('PASS mixed generation/load/battery/buffer, outage and split/rejoin');script.finish_test(true)
 elseif t%120==0 then snapshot(st,t) end
end)
