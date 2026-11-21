-- Test-only mod; never distributed as part of ElectrifiedMainline.
local L=20000000/60
local function make(surface,name,pos,extra)
 local arg={name=name,position=pos,force="player",raise_built=true}
 for k,v in pairs(extra or {}) do arg[k]=v end
 local e=surface.create_entity(arg)
 assert(e and e.valid,"probe create failed: "..name.." at "..pos[1]..","..pos[2])
 return e
end
local function setup()
 local surface=game.create_surface("em061-native-test",{width=256,height=128})
 surface.generate_with_lab_tiles=true
 surface.request_to_generate_chunks({0,0},2);surface.force_generate_chunk_requests()
 for x=-23,23,2 do make(surface,"em-high-speed-straight-rail",{x,1},{direction=defines.direction.east}) end
 local a=make(surface,"em-35kv-catenary-pole",{-21.5,2.5})
 make(surface,"em-35kv-catenary-pole",{-1.5,2.5})
 local b=make(surface,"em-35kv-catenary-pole",{18.5,2.5})
 local suba=make(surface,"em-35kv-traction-substation",{-20,9})
 local subb=make(surface,"em-35kv-traction-substation",{20,9})
 local source=make(surface,"electric-energy-interface",{-20,13})
 local sink=make(surface,"electric-energy-interface",{20,13})
 source.electric_interface_mode=defines.electric_interface_mode.primary_output
 source.electric_buffer_size=10000000;source.power_usage=0;source.power_production=L
 source.input_flow_limit=0;source.output_flow_limit=L;source.energy=0
 sink.electric_interface_mode=defines.electric_interface_mode.secondary_input
 sink.electric_buffer_size=200000000;sink.power_production=0;sink.power_usage=0
 sink.input_flow_limit=L;sink.output_flow_limit=0;sink.energy=0
 storage.fixture={surface=surface,a=a,b=b,suba=suba,subb=subb,source=source,sink=sink,batteries={}}
end
local function total(f)
 local e=0;for _,b in ipairs(f.batteries) do e=e+b.energy end;return e
end
local function network(e)
 local s=e.electric_network
 if not s then return "nil" end
 local f=s.parent_network.flow_last_tick
 return "id="..tostring(s.id).." flow="..serpent.line(f)
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick
 if not storage.start then storage.start=t;setup() end
 local dt=t-storage.start
 local f=storage.fixture
 if dt==60 then
   assert(f.source.electric_interface_mode==defines.electric_interface_mode.primary_output,"061 priority: source mode mismatch")
   assert(f.sink.electric_interface_mode==defines.electric_interface_mode.secondary_input,"061 priority: sink mode mismatch")
   assert(f.source.output_flow_limit>0 and f.sink.input_flow_limit>0,"061 priority: native limits unavailable")
   log("[EM061 NATIVE] priority-mode API primary-output / secondary-input and input-output limits observed")
   log("[EM061 NATIVE] startup source "..network(f.source))
   log("[EM060 NATIVE] startup sink "..network(f.sink))
   log("[EM060 NATIVE] startup line "..network(f.a))
 end
 if dt==240 then
   log("[EM060 NATIVE] delivery sink_J="..f.sink.energy)
   assert(f.a.electric_network_id and f.a.electric_network_id==f.b.electric_network_id,"native corridor not joined")
   assert(f.suba.electric_network_id~=f.subb.electric_network_id and f.suba.electric_network_id~=f.a.electric_network_id and f.subb.electric_network_id~=f.a.electric_network_id,"ordinary/line network short")
   assert(f.sink.energy>1000000,"native cold-start no transfer")
   f.sink.destroy{raise_destroy=true}
   for _,x in ipairs({16,19,22,25}) do
     local b=make(f.surface,"accumulator",{x,13});b.energy=0;f.batteries[#f.batteries+1]=b
   end
 end
 if dt==600 then
   f.before=total(f);log("[EM060 NATIVE] battery charge J="..f.before)
   assert(f.before>1000000,"native storage failed to charge")
   local e=f.source
   e.electric_interface_mode=defines.electric_interface_mode.secondary_input
   e.power_production=0;e.power_usage=0;e.electric_buffer_size=200000000;e.input_flow_limit=L;e.output_flow_limit=0;e.energy=0
 end
 if (dt>=598 and dt<=615) or (dt>=658 and dt<=670) then
   local rows={}
   local lab=game.surfaces["em-25kv-isolated-bridge-058"]
   if lab then for _,e in pairs(lab.find_entities_filtered{type="electric-energy-interface"}) do
     rows[#rows+1]=e.name.."@"..tostring(e.electric_network_id).." en="..e.energy.." cap="..e.electric_buffer_size.." in="..e.input_flow_limit.." out="..e.output_flow_limit
   end end
   log("[EM060 TRACE] dt="..dt.." source "..network(f.source).." battery "..network(f.batteries[1]).." line "..network(f.a).." device="..f.source.electric_interface_mode.."/"..f.source.power_production.."/"..f.source.power_usage.." buffers={"..table.concat(rows,";").."}")
 end
 if dt==900 then
   local after=total(f)
   log("[EM060 NATIVE] reverse sink_J="..f.source.energy.." battery_after_J="..after)
   assert(f.source.energy>500000,"native storage reverse transfer failed")
   assert(after<f.before-500000,"native storage did not discharge")
   assert(f.source.energy<=f.before-after+1400000,"reverse energy exceeds storage plus bounded transient bridge buffers")
   log("[EM061 NATIVE PASS] exact engine cold start, native isolated rail corridor, editor EEI delivery, real accumulator charge and reverse discharge")
 end
end)