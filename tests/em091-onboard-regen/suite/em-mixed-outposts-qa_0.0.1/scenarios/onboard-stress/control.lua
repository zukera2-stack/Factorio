-- EM087N configurable shared-grid stress. Test fixture only.
local N=tonumber(script.test_arg) or 12
assert(N>=4 and N<=100 and N%4==0)
local BUDGET=N/4*500000000
local W=1000000/60
local function ck(x,m)if not x then error('[SCALE FAIL] '..m) end end
local function say(m)log('[SCALE] '..m) end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n..' '..x..','..y);return e
end
local function key(e)local n=e.electric_network;local p=n and n.parent_network;ck(p and p.valid,'no parent');local id=n.id;for _,a in pairs(p.sub_networks)do if a.valid and a.id<id then id=a.id end end;return id end
local function wire(a,b,remove)
 local c=defines.wire_connector_id.pole_copper;local x,y=a.get_wire_connector(c,true),b.get_wire_connector(c,true)
 if remove then ck(x.disconnect_from(y,defines.wire_origin.player),'disconnect')else ck(x.connect_to(y,false,defines.wire_origin.player),'connect')end
end
local function eei(s,x,y,kind,mw,energy)
 local e=make(s,'electric-energy-interface',x,y);e.electric_interface_mode=defines.electric_interface_mode[kind];e.electric_buffer_size=1000000000;e.energy=energy;e.power_usage=0;e.power_production=0;e.input_flow_limit=kind=='secondary_input' and mw*W or 0;e.output_flow_limit=kind=='primary_output' and mw*W or 0;return e
end
local function bank(s,x,y)local r={};for _,dx in ipairs({-6,-2,2,6})do local e=make(s,'accumulator',x+dx,y+12);e.energy=0;r[#r+1]=e end;return r end
local function sub(s,line,x)local e=make(s,'em-35kv-traction-substation',x,line.y+8,{auto_connect=false});line.subs[x]=e;return e end
local function total(es)local a=0;for _,e in ipairs(es)do a=a+e.energy end;return a end
local function banks(es)local a=0;for _,b in ipairs(es)do a=a+total(b) end;return a end
local function stop(s,y,i)
 for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do local q=s.create_entity{name='train-stop',position={x=-120,y=y+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='SCALE_'..i;return q elseif q and q.valid then q.destroy()end end end
 error('[SCALE FAIL] stop '..i)
end
script.on_init(function()
 local s=game.create_surface('mixed-stress',{width=512,height=math.max(640,N*40+128)});s.generate_with_lab_tiles=true;s.always_day=true
 for i=1,N do local y=(i-N/2-1)*40+1;for x=-196,196,64 do s.request_to_generate_chunks({x,y},2)end end;s.force_generate_chunk_requests()
 local st={s=s,lines={},links={},sources={},loads={},batteries={},buffers={},trains={}}
 for i=1,N do
  local y=(i-N/2-1)*40+1;local l={y=y,subs={},masts={}};st.lines[i]=l
  for x=-143,143,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})end
  for x=-141.5,139,20 do l.masts[#l.masts+1]=make(s,'em-35kv-catenary-pole',x,y+1.5)end
  if i%4==1 then sub(s,l,-60);st.sources[#st.sources+1]=eei(s,-60,y+12,'primary_output',20,500000000)
  elseif i%4==3 then sub(s,l,-60);st.batteries[#st.batteries+1]=bank(s,-60,y)
  elseif i%4==0 then
   sub(s,l,60);st.loads[#st.loads+1]=eei(s,60,y+12,'secondary_input',2,0)
  end
  do
   local loco=make(s,'em-electric-locomotive',41,y,{direction=defines.direction.west});local cargo=make(s,'em-motor-cargo-wagon',48,y,{direction=defines.direction.west});local fluid=make(s,'em-motor-fluid-wagon',55,y,{direction=defines.direction.west})
   ck(cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo');ck(fluid.insert_fluid{name='water',amount=9000}==9000,'fluid');st.trains[#st.trains+1]={loco=loco,cargo=cargo,fluid=fluid,stop=stop(s,y,i),start=loco.position.x}
  end
 end
 -- Four-corridor ring branches, joined by one native vanilla generation backbone.
 local function pole(x,y)return make(s,'big-electric-pole',x,y,{auto_connect=false})end
 local trunk=nil;local trunk_first=nil
 for i=1,N,4 do
  local a=st.lines[i];local y=a.y+8
  local top=pole(-180,y);if not trunk_first then trunk_first=top end
  if trunk then for yy=y-140,y-20,20 do local p=pole(-180,yy);wire(trunk,p);trunk=p end;wire(trunk,top)end
  trunk=top;local prev=top
  for x=-160,-80,20 do local p=pole(x,y);wire(prev,p);prev=p end;wire(prev,a.subs[-60])
  for j=i,i+2 do local l,b=st.lines[j],st.lines[j+1];local x=j%2==1 and 0 or 40;local p=sub(s,l,x);local q=sub(s,b,x);local c=pole(x,l.y+28);wire(p,c);wire(c,q);st.links[#st.links+1]={p=p,q=q,c=c}
   if j%4==2 then st.buffers[#st.buffers+1]=bank(s,x,l.y) end
  end
  local b=st.lines[i+3];local p=sub(s,a,-20);local q=sub(s,b,-20);local prev=p
  for yy=a.y+28,b.y-12,20 do local c=pole(-20,yy);wire(prev,c);prev=c end
  wire(prev,q);st.links[#st.links+1]={p=p,q=q,c=prev,ring=true}
 end
 st.trunk=trunk_first
 storage.st=st
end)
local function snapshot(st,t)
 local src,load,bat,buf=total(st.sources),total(st.loads),banks(st.batteries),banks(st.buffers);local lab=game.surfaces['em-25kv-isolated-bridge-058'];local h=0
 if lab then for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end end
 local paid=remote.call('em072_native_qa_071','snapshot').paid_J or 0;local onboard=remote.call('em089_onboard_storage','snapshot');ck(onboard.enabled,'onboard not enabled');ck(math.abs(onboard.charged_J-onboard.stored_J-onboard.discharged_J-onboard.lost_J)<.05,'onboard balance');local sum=src+load+bat+buf+h+paid+onboard.stored_J+onboard.discharged_J+onboard.lost_J;log(string.format('[ONBOARD STRESS] t=%d charged_J=%.3f stored_J=%.3f discharged_J=%.3f lost_J=%.3f',t,onboard.charged_J,onboard.stored_J,onboard.discharged_J,onboard.lost_J))
 say(string.format('t=%d source_J=%.3f load_J=%.3f battery_J=%.3f buffer_J=%.3f hidden_J=%.3f paid_train_J=%.3f total_J=%.3f',t,src,load,bat,buf,h,paid,sum));ck(math.abs(sum-BUDGET)<5000,'energy balance '..sum);return {src=src,load=load,bat=bat,buf=buf,paid=paid,onboard=onboard}
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  local corridor,links={},{};for i,l in ipairs(st.lines)do local k=key(l.masts[4]);ck(not corridor[k],'corridors merged '..i);corridor[k]=true end
  for i,l in ipairs(st.links)do local k=key(l.p);ck(k==key(l.q) and not links[k] and not corridor[k],'transit link '..i);links[k]=true end
  local bus=key(st.trunk);ck(not corridor[bus] and not links[bus],'trunk short');for _,g in ipairs(st.sources)do ck(key(g)==bus,'source not on common trunk')end;for _,l in ipairs(st.lines)do for _,s in pairs(l.subs)do ck(not corridor[key(s)],'factory short')end end
  for _,r in ipairs(st.trains)do local tr=r.loco.train;ck(#tr.carriages==4,'helper count');tr.schedule={current=1,records={{station=r.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false end
  say('topology PASS '..N..' native corridors, '..#st.links..' independent ring links, common native generation backbone, '..#st.trains..' trains');snapshot(st,t)
 elseif t==480 then
  local moving=0;for _,r in ipairs(st.trains)do if math.abs(r.loco.train.speed)>0.001 then moving=moving+1 end end; say('t480 moving='..moving);snapshot(st,t);for i,e in ipairs(st.loads)do if i%2==1 then e.input_flow_limit=4*W end end
 elseif t==900 then
  st.pre=snapshot(st,t);for _,e in ipairs(st.loads)do ck(e.energy>1000000,'starved load')end;for _,b in ipairs(st.batteries)do ck(total(b)>100000,'starved battery')end;for _,b in ipairs(st.buffers)do ck(total(b)>100000,'starved buffer')end
  for i,r in ipairs(st.trains)do ck(r.loco.train.station==r.stop and math.abs(r.loco.position.x-r.start)>100,'train not arrived '..i..' x='..r.loco.position.x..' speed='..r.loco.train.speed); ck(r.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and r.fluid.get_fluid_count('water')==9000,'payload')end
  say(#st.trains..' trains arrived with cargo; paid_J='..st.pre.paid);for _,e in ipairs(st.sources)do e.output_flow_limit=0 end
 elseif t==1100 then
  st.off=snapshot(st,t);ck(math.abs(st.off.src-st.pre.src)<100 and st.off.load>st.pre.load+100000 and st.off.bat+st.off.buf<st.pre.bat+st.pre.buf,'outage backup');for _,e in ipairs(st.sources)do e.output_flow_limit=20*W end;local l=st.links[2];st.cut_load=st.loads[1].energy;wire(l.c,l.q,true)
 elseif t==1300 then
  st.split=snapshot(st,t);local l=st.links[2];ck(key(l.p)~=key(l.q),'split failed');ck(st.loads[1].energy>st.cut_load+100000,'ring alternate path starved');wire(l.c,l.q)
 elseif t==1500 then
  local q=snapshot(st,t);local l=st.links[2];ck(key(l.p)==key(l.q) and q.load>st.split.load+100000,'rejoin/load');ck(q.onboard.charged_J>1000000,'no onboard charge');say('PASS '..N..' corridors and trains; '..N/4 ..' of each outpost role; finite energy balance');script.finish_test(true)
 elseif t%120==0 then snapshot(st,t) end
end)
