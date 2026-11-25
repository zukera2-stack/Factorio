local C=script.test_arg or 'topology'
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
script.on_init(setup)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.qa
 if C=='multi48' then
  if t==240 then isolated(st);local total,lo,hi,n=report(st,'initial');ck(n==42 and lo>500000 and hi/lo<2.2,'initial starvation/fairness');ck(total>340000000 and total<490000000,'initial budget '..total);st.before={};for i,e in pairs(st.sinks)do if i%2==0 then e.input_flow_limit=0 end;st.before[i]=e.energy end
  elseif t==600 then isolated(st);report(st,'rerouted');local added,lo,hi,n=0,math.huge,0,0;for i,e in pairs(st.sinks) do local d=e.energy-st.before[i];if i%2==1 then added=added+d;lo=math.min(lo,d);hi=math.max(hi,d);n=n+1 else ck(d<600000,'disabled load still receives '..i..' '..d) end end;ck(n==18 and lo>200000 and hi/lo<2.3 and added>590000000 and added<750000000,'reroute budget/fairness '..added..' min='..lo..' max='..hi);st.outage=0;for _,e in pairs(st.sinks) do st.outage=st.outage+e.energy end;for _,e in pairs(st.sources) do e.electric_interface_mode=defines.electric_interface_mode.secondary_input;e.power_production=0;e.input_flow_limit=20*W;e.output_flow_limit=0 end
  elseif t==900 then isolated(st);local now=0;for _,e in pairs(st.sinks)do now=now+e.energy end;ck(now-st.outage<=27000000,'unbounded outage energy '..(now-st.outage));say('PASS 48 independent grids, 6 sources, 42 then 18 sinks; final outage residual_J='..(now-st.outage));script.finish_test(true) end;return
 end
 local b,c=st.sinks[2],st.sinks[3]
 if t==240 then
  isolated(st);report(st,'baseline');ck(b.energy>5000000 and c.energy>5000000 and math.abs(b.energy-c.energy)<4000000 and b.energy+c.energy<95000000,'fairness/budget');b.input_flow_limit=0;st.before=c.energy
 elseif t==480 then local d=c.energy-st.before;ck(d>40000000 and d<85000000,'redirected supply '..d);say('PASS receiver loss redirected_J='..d)
 elseif t==500 then st.before=c.energy;st.masts[2].destroy{raise_destroy=true};st.masts[3].destroy{raise_destroy=true}
 elseif t==670 then local d=c.energy-st.before;ck(d<6000000,'mast cut continued energy '..d);say('PASS mast break residual_J='..d);st.before=c.energy;st.masts[2]=make(st.s,'em-35kv-catenary-pole',-21.5,2.5);st.masts[3]=make(st.s,'em-35kv-catenary-pole',-1.5,2.5)
 elseif t==850 then local d=c.energy-st.before;ck(d>5000000,'mast rejoin no power '..d);say('PASS mast restoration_J='..d);st.before=c.energy;st.rails[-11].destroy{raise_destroy=true}
 elseif t==1020 then local d=c.energy-st.before;ck(d<6000000,'rail cut continued power '..d);say('PASS rail split residual_J='..d);st.before=c.energy;st.rails[-11]=make(st.s,'em-high-speed-straight-rail',-11,1,{direction=defines.direction.east})
 elseif t==1200 then local d=c.energy-st.before;ck(d>5000000,'rail restoration no power '..d);say('PASS rail rejoin_J='..d);st.before=c.energy;st.subs[1].destroy{raise_destroy=true}
 elseif t==1370 then local d=c.energy-st.before;ck(d<6000000,'demolished source still powers consumer '..d);say('PASS substation demolition residual_J='..d);st.before=c.energy;st.subs[1]=make(st.s,'em-35kv-traction-substation',-40,9)
 elseif t==1550 then local d=c.energy-st.before;ck(d>5000000,'source rebuild failed '..d);say('PASS substation rebuild_J='..d);st.before=c.energy;st.sources[1].power_production=0;st.sources[1].output_flow_limit=0
 elseif t==1720 then local d=c.energy-st.before;ck(d<6000000,'source off continued power '..d);say('PASS source outage residual_J='..d);isolated(st);script.finish_test(true)
 end
end)
