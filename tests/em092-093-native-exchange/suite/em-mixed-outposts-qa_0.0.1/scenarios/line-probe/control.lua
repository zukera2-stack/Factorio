local mode=script.test_arg or 'local'
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
local function snapshot(st,t)
 local lab=game.surfaces['em-25kv-isolated-bridge-058'];local h=0
 for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end
 local paid=remote.call('em072_native_qa_071','snapshot').paid_J or 0
 local sum=h+st.factory.energy+paid
 ck(math.abs(sum-2000000)<1,'energy balance '..sum)
 log(string.format('[LINE] %s t=%d source=%.6f local=%.6f other=%.6f factory=%.6f hidden=%.6f paid=%.6f total=%.6f',mode,t,st.source.energy,st.sink.energy,st.other.energy,st.factory.energy,h,paid,sum))
 return paid
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  local lab=game.surfaces['em-25kv-isolated-bridge-058'];ck(lab,'lab');local k1,k2=key(st.lines[1].mast),key(st.lines[2].mast);ck(k1~=k2 and k1~=key(st.lines[1].sub) and k2~=key(st.lines[2].sub),'isolation');ck(key(st.factory)==key(st.lines[1].sub),'factory connection')
  local p1,p2
  for _,p in ipairs(lab.find_entities_filtered{name='em-25kv-bridge-port-058'})do local k=key(p);if k==k1 then p1=p elseif k==k2 then p2=p end end
  ck(p1 and p2,'verified line ports');st.source=eei(lab,mode=='direct' and 'em092-qa-finite-source' or 'em-25kv-bridge-output-058',p1.position,'secondary_output',2*W,2000000);st.sink=eei(lab,'em-25kv-native-traction-consumer-068',p1.position,'secondary_input',0,0);st.other=eei(lab,'em-25kv-native-traction-consumer-068',p2.position,'secondary_input',2*W,0)
  ck(key(st.source)==k1 and key(st.sink)==k1 and key(st.other)==k2,'actual EEI parent');snapshot(st,t)
 elseif t==180 then
  snapshot(st,t);if mode~='direct' then ck(math.abs(st.source.energy-2000000)<.05 and st.other.energy==0,'unaccepted offer lost or leaked') end;
  if mode=='local' then st.sink.input_flow_limit=W
  elseif mode=='export' then st.factory.input_flow_limit=W
  elseif mode=='both' then st.sink.input_flow_limit=W;st.factory.input_flow_limit=W
  elseif (mode=='noimport' or mode=='direct') then local tr=st.loco.train;tr.schedule={current=1,records={{station='LINE',wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false end
 elseif t==240 or t==360 or t==540 then
  local paid=snapshot(st,t);ck(st.other.energy==0,'cross-corridor leakage')
  if t==540 then
   if mode=='local' then ck(st.sink.energy>1999999 and st.source.energy<.05 and st.factory.energy==0,'local receipt')
   elseif mode=='export' then ck(st.factory.energy>1000000,'factory export not proven')
   elseif mode=='both' then ck(st.sink.energy>0 and st.factory.energy>0,'both receivers not proven')
   elseif mode=='direct' then ck(paid>1000000 and st.loco.position.x<st.start-5 and st.factory.energy==0,'direct traction no motion/paid');log('[LINE DIRECT] displacement='..(st.start-st.loco.position.x)..' paid='..paid)
   elseif mode=='noimport' then ck(paid==0 and st.loco.position.x==st.start and math.abs(st.source.energy-2000000)<.05,'unexpected train draw');log('[LINE BLOCKER] active import prerequisite prevents actual traction despite local source') end
   log('[LINE PASS] '..mode);script.finish_test(true)
  end
 end
end)
