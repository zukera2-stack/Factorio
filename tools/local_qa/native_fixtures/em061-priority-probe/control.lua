-- Research-only. Native Factorio 2.1.24 EEI priority matrix; no script transfers energy.
-- All energy changes arise from Factorio solver, not Lua teleportation.
local W=2000000/60
local cases={}
local function make(s,name,x,y)
 local e=s.create_entity{name=name,position={x,y},force='player',raise_built=true}
 assert(e and e.valid,'cannot create '..name..' at '..x..','..y)
 return e
end
local function interface(s,x,y,mode,kind)
 local e=make(s,'electric-energy-interface',x,y)
 e.electric_interface_mode=defines.electric_interface_mode[mode]
 assert(e.electric_interface_mode==defines.electric_interface_mode[mode], 'priority mode not applied '..mode)
 e.electric_buffer_size=10000000
 e.power_production=(kind=='output') and W or 0
 e.power_usage=0
 e.input_flow_limit=(kind=='input') and W or 0
 e.output_flow_limit=(kind=='output') and W or 0
 e.energy=0
 return e
end
local function build()
 local s=game.create_surface('em061-priority-matrix',{width=512,height=128})
 s.generate_with_lab_tiles=true
 s.request_to_generate_chunks({0,0},6);s.force_generate_chunk_requests()
 local patterns={
   {'batt_to_secondary','battery','secondary_input'},
   {'batt_to_tertiary','battery','tertiary_input'},
   {'secondary_to_batt','secondary_output','battery'},
   {'tertiary_to_batt','tertiary_output','battery'},
   {'primary_vs_secondary','primary_output','primary_input'},
   {'secondary_supply','secondary_output','secondary_input'},
 }
 for i,def in ipairs(patterns) do
   local x=-180+(i-1)*65
   local pole=make(s,'medium-electric-pole',x,0)
   local a,b
   if def[2]=='battery' then
     a=make(s,'accumulator',x-2,0);a.energy=4000000
   else
     a=interface(s,x-2,0,def[2],'output')
   end
   if def[3]=='battery' then
     b=make(s,'accumulator',x+2,0);b.energy=0
   else
     b=interface(s,x+2,0,def[3],'input')
   end
   local extra=nil
   if i==5 then extra=interface(s,x,2,'secondary_input','input') end
   cases[i]={name=def[1],a=a,b=b,pole=pole,extra=extra}
 end
 log('[EM061 MATRIX] setup 6 independent scenarios; all test entities use native electrical solver')
end
local function snapshot(t)
 local results={}
 for _,c in ipairs(cases) do
   assert(c.a.electric_network_id==c.b.electric_network_id,'network disconnected '..c.name)
   local a=c.a.energy;local b=c.b.energy
   local e=c.extra and c.extra.energy or -1
   log(string.format('[EM061 MATRIX] t=%d case=%s source_J=%.0f target_J=%.0f other_J=%.0f net=%s',t,c.name,a,b,e,tostring(c.a.electric_network_id)))
   results[c.name]={a=a,b=b,extra=e}
 end
 if t==240 then
   assert(results.batt_to_secondary.b>100000,'secondary-input must draw from a charged native accumulator')
   assert(results.batt_to_secondary.a<3900000,'accumulator should discharge when serving secondary-input')
   assert(results.batt_to_tertiary.b==0,'tertiary-input unexpectedly drained accumulator; check native priority change')
   assert(results.secondary_to_batt.b>100000,'secondary-output must charge native accumulator')
   assert(results.tertiary_to_batt.b==0,'tertiary-output unexpectedly charged accumulator; check native priority change')
   assert(results.primary_vs_secondary.b>results.primary_vs_secondary.extra,'primary-input should have priority over secondary-input')
   assert(results.secondary_supply.b>100000,'secondary-output must power secondary-input')
   log('[EM061 MATRIX PASS] independently wired native battery input/output, primary/secondary priority ordering')
 end
end
script.on_event(defines.events.on_tick,function(ev)
 if not storage.init then storage.init=ev.tick;build() end
 local dt=ev.tick-storage.init
 if dt==60 or dt==240 then snapshot(dt) end
end)