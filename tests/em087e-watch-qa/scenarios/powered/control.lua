local C='watch-powered'
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

script.on_init(function()
 setup()
 local st=storage.qa
 -- Insert an actual signal within the selected route, so the watcher must
 -- also register dependencies returned by the bounded non-segment walk.
 local signal
 for _,y in ipairs({-0.5,2.5,3,-1}) do
  for _,dir in ipairs({defines.direction.east,defines.direction.west,defines.direction.north,defines.direction.south}) do
   local x=st.s.create_entity{name='rail-signal',position={-11,y},force='player',direction=dir,raise_built=false}
   if x and x.valid and #x.get_connected_rails()>0 then signal=x;break end
   if x and x.valid then x.destroy() end
  end
  if signal then break end
 end
 ck(signal,'cannot create signal fixture');st.signal=signal
end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.qa;local c=st.sinks[3]
 if t==180 and (script.test_arg=='save' or not script.test_arg) then
  ck(c.energy>5000000,'no initial delivery');st.saved=c.energy;if script.test_arg=='save' then game.auto_save('em087e-watcher') else game.server_save('em087e-watcher') end;say('disk save requested')
 elseif t==185 and script.test_arg=='save' then script.finish_test(true)
 elseif t==199 then
  ck(c.energy>5000000,'no initial delivery');ck(st.masts[1].electric_network_id==st.masts[5].electric_network_id,'initial disconnected')
  if script.test_arg=='load' then ck(st.saved and c.energy>=st.saved,'disk state lost') end
 elseif t==200 then
  st.before=c.energy;ck(st.rails[-13].destroy{raise_destroy=false},'silent cut refused')
 elseif t==203 then
  ck(st.masts[1].electric_network_id~=st.masts[5].electric_network_id,'silent cut did not split by t203');say('silent cut native network split by t203')
 elseif t==220 then st.after=c.energy
 elseif t==260 then
  ck(math.abs(c.energy-st.after)<1,'continued energy after disconnection '..(c.energy-st.after))
  ck(c.energy-st.before<2000000,'unexpected post-cut energy '..(c.energy-st.before))
  say('silent cut residual_J='..(c.energy-st.before)..' later_J='..(c.energy-st.after));st.before=c.energy
  st.rails[-13]=make(st.s,'em-high-speed-straight-rail',-13,1,{direction=defines.direction.east})
 elseif t==360 then
  ck(st.masts[1].electric_network_id==st.masts[5].electric_network_id,'restore disconnected')
  ck(c.energy-st.before>5000000,'no restored power');isolated(st);say('PASS restored energy_J='..(c.energy-st.before));script.finish_test(true)
 end
end)
