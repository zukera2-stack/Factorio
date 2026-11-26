-- Native 12-corridor mixed-grid acceptance, finite reservoirs; no runtime mod writes.
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
 for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do local q=s.create_entity{name='train-stop',position={x=-60,y=y+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='SCALE_'..i;return q elseif q and q.valid then q.destroy()end end end
 error('[SCALE FAIL] stop '..i)
end
script.on_init(function()
 local s=game.create_surface('mixed-scale',{width=512,height=640});s.generate_with_lab_tiles=true;s.always_day=true
 for i=1,12 do local y=(i-7)*40+1;for x=-100,100,64 do s.request_to_generate_chunks({x,y},2)end end;s.force_generate_chunk_requests()
 local st={s=s,lines={},links={},sources={},loads={},batteries={},buffers={},trains={}}
 for i=1,12 do
  local y=(i-7)*40+1;local l={y=y,subs={},masts={}};st.lines[i]=l
  for x=-83,83,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})end
  for x=-81.5,79,20 do l.masts[#l.masts+1]=make(s,'em-35kv-catenary-pole',x,y+1.5)end
  if i%4==1 then sub(s,l,-60);st.sources[#st.sources+1]=eei(s,-60,y+12,'primary_output',12,200000000)
  elseif i%4==3 then sub(s,l,-60);st.batteries[#st.batteries+1]=bank(s,-60,y)
  elseif i%4==0 then
   sub(s,l,60);st.loads[#st.loads+1]=eei(s,60,y+12,'secondary_input',2,0)
   local loco=make(s,'em-electric-locomotive',1,y,{direction=defines.direction.west});local cargo=make(s,'em-motor-cargo-wagon',8,y,{direction=defines.direction.west});local fluid=make(s,'em-motor-fluid-wagon',15,y,{direction=defines.direction.west})
   ck(cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo');ck(fluid.insert_fluid{name='water',amount=9000}==9000,'fluid');st.trains[#st.trains+1]={loco=loco,cargo=cargo,fluid=fluid,stop=stop(s,y,i),start=loco.position.x}
  end
 end
 for i=1,11 do local a,b=st.lines[i],st.lines[i+1];local x=i%2==1 and 0 or 40;local p=sub(s,a,x);local q=sub(s,b,x);local c=make(s,'big-electric-pole',x,a.y+28,{auto_connect=false});wire(p,c);wire(c,q);st.links[i]={p=p,q=q,c=c}
  if i%4==2 then st.buffers[#st.buffers+1]=bank(s,x,a.y) end
 end
 storage.st=st
end)
local function snapshot(st,t)
 local src,load,bat,buf=total(st.sources),total(st.loads),banks(st.batteries),banks(st.buffers);local lab=game.surfaces['em-25kv-isolated-bridge-058'];local h=0
 if lab then for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end end
 local paid=remote.call('em072_native_qa_071','snapshot').paid_J or 0;local sum=src+load+bat+buf+h+paid
 say(string.format('t=%d source_J=%.3f load_J=%.3f battery_J=%.3f buffer_J=%.3f hidden_J=%.3f paid_train_J=%.3f total_J=%.3f',t,src,load,bat,buf,h,paid,sum));ck(math.abs(sum-600000000)<200,'energy balance '..sum);return {src=src,load=load,bat=bat,buf=buf,paid=paid}
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  local corridor,links={},{};for i,l in ipairs(st.lines)do local k=key(l.masts[4]);ck(not corridor[k],'corridors merged '..i);corridor[k]=true end
  for i,l in ipairs(st.links)do local k=key(l.p);ck(k==key(l.q) and not links[k] and not corridor[k],'transit link '..i);links[k]=true end
  for _,l in ipairs(st.lines)do for _,s in pairs(l.subs)do ck(not corridor[key(s)],'factory short')end end
  for _,r in ipairs(st.trains)do local tr=r.loco.train;ck(#tr.carriages==4,'helper count');tr.schedule={current=1,records={{station=r.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false end
  say('topology PASS 12 native corridors, 11 independent vanilla links, 31 substations, 24 accumulators');snapshot(st,t)
 elseif t==600 then
  st.pre=snapshot(st,t);for _,e in ipairs(st.loads)do ck(e.energy>1000000,'starved load')end;for _,b in ipairs(st.batteries)do ck(total(b)>100000,'starved battery')end;for _,b in ipairs(st.buffers)do ck(total(b)>100000,'starved buffer')end
  for _,r in ipairs(st.trains)do ck(r.loco.train.station==r.stop and math.abs(r.loco.position.x-r.start)>10,'train not arrived');ck(r.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and r.fluid.get_fluid_count('water')==9000,'payload')end
  say('3 trains arrived with cargo; paid_J='..st.pre.paid);for _,e in ipairs(st.sources)do e.output_flow_limit=0 end
 elseif t==900 then
  st.off=snapshot(st,t);ck(math.abs(st.off.src-st.pre.src)<100 and st.off.load>st.pre.load+100000 and st.off.bat+st.off.buf<st.pre.bat+st.pre.buf,'outage backup');for _,e in ipairs(st.sources)do e.output_flow_limit=12*W end;local l=st.links[6];wire(l.c,l.q,true)
 elseif t==1200 then
  st.split=snapshot(st,t);local l=st.links[6];ck(key(l.p)~=key(l.q),'split failed');wire(l.c,l.q)
 elseif t==1500 then
  local q=snapshot(st,t);local l=st.links[6];ck(key(l.p)==key(l.q) and q.load>st.split.load+100000,'rejoin/load');say('PASS 12 corridors; 3 generation, 3 load, 3 battery, 3 buffer outposts, 3 trains; finite 600MJ balance');script.finish_test(true)
 elseif t%120==0 then snapshot(st,t) end
end)
