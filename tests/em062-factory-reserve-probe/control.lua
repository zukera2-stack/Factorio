-- Actual Factorio solver: preserve ordinary and critical factory power with a simultaneous long-distance transfer.
local MW=1000000/60
local f={}
local start_tick
local function make(s,name,x,y,extra)
 local args={name=name,position={x,y},force='player',raise_built=true}
 for k,v in pairs(extra or {}) do args[k]=v end
 local e=s.create_entity(args)
 assert(e and e.valid,'create failed '..name..' at '..x..','..y)
 return e
end
local function interface(s,x,y,mode,flow)
 local e=make(s,'electric-energy-interface',x,y)
 e.electric_interface_mode=defines.electric_interface_mode[mode]
 e.electric_buffer_size=1000000000;e.power_usage=0
 e.power_production=(mode=='primary_output') and flow or 0
 e.input_flow_limit=(mode=='primary_input' or mode=='secondary_input') and flow or 0
 e.output_flow_limit=(mode=='primary_output') and flow or 0
 e.energy=0
 return e
end
local function setup()
 local s=game.create_surface('em062-factory-deficit',{width=256,height=128})
 s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},3);s.force_generate_chunk_requests()
 for x=-3,43,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
 for _,x in ipairs({-1.5,18.5,38.5}) do make(s,'em-35kv-catenary-pole',x,2.5) end
 f.suba=make(s,'em-35kv-traction-substation',0,9)
 f.subb=make(s,'em-35kv-traction-substation',40,9)
 f.source=interface(s,0,13,'primary_output',20*MW)
 f.local_load=interface(s,3,13,'secondary_input',12*MW)
 f.remote=interface(s,40,13,'secondary_input',20*MW)
 assert(f.source.electric_network_id==f.local_load.electric_network_id,'local factory consumer disconnected')
 assert(f.source.electric_network_id~=f.remote.electric_network_id,'factory networks shorted')
 log('[EM062 DEFICIT] test: source 20MW, local factory ordinary consumer 12MW, remote demand 20MW')
end
local function snapshot(t)
 log(string.format('[EM062 DEFICIT] dt=%d local_J=%.0f remote_J=%.0f source_J=%.0f src_capacity_MW=%.1f net_local=%s net_remote=%s',t,f.local_load.energy,f.remote.energy,f.source.energy,(f.source.output_flow_limit or 0)/MW,tostring(f.local_load.electric_network_id),tostring(f.remote.electric_network_id)))
end
script.on_event(defines.events.on_tick,function(ev)
 if not start_tick then start_tick=ev.tick;setup() end
 local dt=ev.tick-start_tick
 if dt==120 or dt==240 or dt==420 or dt==600 or dt==840 then snapshot(dt) end
 if dt==240 then
   assert(f.local_load.energy>40000000,'factory local 12MW consumer deprived under 20MW source')
   assert(f.remote.energy>15000000,'remote consumer failed to receive surplus after local factory load')
   assert(f.local_load.energy+f.remote.energy<85000000,'energy exceeds 20MW input capacity')
   storage.local_before=f.local_load.energy;storage.remote_before=f.remote.energy
   f.source.power_production=8*MW;f.source.output_flow_limit=8*MW
   log('[EM062 DEFICIT] reduced factory source from 20MW to 8MW while local 12MW demand remains')
 end
 if dt==600 then
   local local_gain=f.local_load.energy-storage.local_before
   local remote_gain=f.remote.energy-storage.remote_before
   log(string.format('[EM062 DEFICIT] 8MW generation phase factory_gain_J=%.0f remote_gain_J=%.0f',local_gain,remote_gain))
   assert(local_gain>35000000,'local factory consumer starved by bridge during low generation')
   assert(remote_gain<18000000,'corridor draining too much energy during local factory shortfall')
   assert(local_gain+remote_gain<58000000,'generation energy budget exceeded')
   -- Primary factory consumer receives higher engine priority under continued deficit.
   f.local_load.electric_interface_mode=defines.electric_interface_mode.primary_input
   storage.local_prior=f.local_load.energy;storage.remote_prior=f.remote.energy
   log('[EM062 DEFICIT] priority escalated local factory load to primary-input at 8MW generation')
 end
 if dt==840 then
   local local_gain=f.local_load.energy-storage.local_prior
   local remote_gain=f.remote.energy-storage.remote_prior
   log(string.format('[EM062 DEFICIT] primary-input phase factory_gain_J=%.0f remote_gain_J=%.0f',local_gain,remote_gain))
   assert(local_gain>24000000,'factory primary load underpowered by railway competition')
   assert(remote_gain<8000000,'railway consumed energy over factory primary input at deficit')
   assert(local_gain+remote_gain<36000000,'primary phase energy budget exceeded')
   log('[EM062 DEFICIT PASS] factory ordinary 12MW protected at surplus, factory protected under 8MW deficit, primary priority respected')
 end
end)