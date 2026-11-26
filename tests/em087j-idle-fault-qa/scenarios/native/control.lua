local C='idle-fault'
local W=1000000/60
local function ck(x,m)if not x then error('[NET FAIL] '..C..' '..m)end end
local function say(m)log('[NET] '..C..' '..m)end
local function make(s,name,x,y,extra)
 local p={name=name,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(extra or {}) do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..name..' '..x..','..y);return e
end
local function eei(s,x,mode,mw)
 local e=make(s,'electric-energy-interface',x,13);e.electric_interface_mode=defines.electric_interface_mode[mode];e.electric_buffer_size=1000000000;e.energy=0;e.power_usage=0;e.power_production=mode=='primary_output' and mw*W or 0;e.input_flow_limit=mode=='secondary_input' and mw*W or 0;e.output_flow_limit=mode=='primary_output' and mw*W or 0;return e
end
local function hidden_count()
 local lab=game.surfaces['em-25kv-isolated-bridge-058'];return lab and #lab.find_entities_filtered{type='electric-energy-interface'} or 0
end
local function setup()
 local multi=C=='multi48';local n=multi and 48 or 3;local start=multi and -940 or -40;local finish=start+40*(n-1)
 local s=game.create_surface('network-'..C,{width=multi and 2048 or 256,height=128});s.generate_with_lab_tiles=true
 for x=start-3,finish+3,96 do s.request_to_generate_chunks({x,0},2) end;s.force_generate_chunk_requests()
 local st={s=s,rails={},masts={},subs={},sources={},sinks={},start=start,n=n}
 for x=start-3,finish+3,2 do st.rails[x]=make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
 for x=start-1.5,finish-1.5,20 do st.masts[#st.masts+1]=make(s,'em-35kv-catenary-pole',x,2.5)end
 for i=1,n do local x=start+(i-1)*40;st.subs[i]=make(s,'em-35kv-traction-substation',x,9)
  if (multi and (i-1)%8==0) or (not multi and i==1) then st.sources[i]=eei(s,x,'primary_output',20) else st.sinks[i]=eei(s,x,'secondary_input',20) end
 end
 storage.qa=st;say('SETUP '..n..' stations '..#st.masts..' masts')
end
local function isolated(st)
 local ids={};for i,e in ipairs(st.subs) do if e.valid then local id=e.electric_network_id;ck(id and not ids[id],'factory nets not isolated '..i);ids[id]=true end end
end
local function sum(st)
 local total,lo,hi,n=0,math.huge,0,0
 for _,e in pairs(st.sinks) do if e.input_flow_limit>0 then total=total+e.energy;lo=math.min(lo,e.energy);hi=math.max(hi,e.energy);n=n+1 end end
 return total,lo,hi,n
end
local function report(st,label)
 local total,lo,hi,n=sum(st);say(label..' total_J='..total..' min_J='..lo..' max_J='..hi..' consumers='..n..' hidden_EEI='..hidden_count());return total,lo,hi,n
end


local function connector(e) return e.get_wire_connector(defines.wire_connector_id.pole_copper,true) end
script.on_init(setup)
script.on_event(defines.events.on_tick,function(e)
 local t=e.tick;local st=storage.qa
 if t==239 then
  st.sinks[2].input_flow_limit=0
 elseif t==240 then
  isolated(st);ck(st.sinks[2].energy>5000000,'no real energy before fault')
  local lab=game.surfaces['em-25kv-isolated-bridge-058'];local n=st.subs[2].electric_network_id
  for _,x in pairs(lab.find_entities_filtered{type='electric-energy-interface'}) do
   say('hidden '..x.name..' net='..tostring(x.electric_network_id)..' mode='..tostring(x.electric_interface_mode)..' J='..x.energy);if x.electric_network_id==n and x.electric_interface_mode==defines.electric_interface_mode.secondary_output then st.out=x end
  end
  ck(st.out and st.out.valid and st.out.energy>1,'no charged output fixture')
  say('pre-fault output_J='..st.out.energy..' flow='..st.out.output_flow_limit)
 elseif t==241 then
  st.sinks[2].input_flow_limit=0
  ck(connector(st.subs[2]).connect_to(connector(st.masts[3]),false,defines.wire_origin.player),'fault wire creation failed')
 elseif t==242 then
  ck(st.subs[2].electric_network_id==st.masts[3].electric_network_id,'fault not physically shorted')
 elseif t>=242 and t<=246 then
  say('fault tick='..t..' short='..tostring(st.subs[2].electric_network_id==st.masts[3].electric_network_id)..' buffer_J='..tostring(st.out.valid and st.out.energy)..' flow='..tostring(st.out.valid and st.out.output_flow_limit))
 end
 if t==243 or t==244 or t==245 or t==246 then
  if st.out.valid and st.out.output_flow_limit>0.5 then st.leaked=true end
 end
 if t==247 then
  ck(not st.leaked,'idle output remains enabled during confirmed factory-corridor short')
  st.frozen=st.out.energy;say('idle output frozen_J='..st.frozen)
 elseif t==270 then
  ck(st.out.valid and math.abs(st.out.energy-st.frozen)<1 and st.out.output_flow_limit==0,'frozen joules changed before audit')
 elseif t==305 then
  ck(st.subs[2].electric_network_id~=st.masts[3].electric_network_id,'isolation not repaired by mast audit');st.before=st.sinks[2].energy;st.sinks[2].input_flow_limit=20*W
 elseif t==365 then
  ck(st.sinks[2].energy-st.before>1000000,'no restored delivery');say('PASS idle freeze and restored delivery_J='..(st.sinks[2].energy-st.before));script.finish_test(true)
 end
end)
