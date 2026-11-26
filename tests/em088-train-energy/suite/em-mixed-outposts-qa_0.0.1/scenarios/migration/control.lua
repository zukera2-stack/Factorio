local function ck(x,m)if not x then error('[BUS FAIL] '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function snap(e)
 local b=remote.call('em088_train_energy','snapshot',e and e.unit_number)
 ck(math.abs(b.paid_J-b.original_paid_J)<.05,'ledger total');ck(not b.battery_enabled and not b.regen_enabled,'battery/regen disabled');return b
end
local function owner(b,id)for _,r in ipairs(b.owners)do if r.unit==id then return r end end;error('missing owner '..id)end
script.on_init(function()
 local s=game.create_surface('bus',{width=512,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-100,100,64 do s.request_to_generate_chunks({x=x,y=0},2)end;s.force_generate_chunk_requests()
 for x=-100,100,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 for x=-81.5,79,20 do make(s,'em-35kv-catenary-pole',x,2.5)end
 make(s,'em-35kv-traction-substation',-20,9)
 local g=make(s,'electric-energy-interface',-20,13);g.electric_interface_mode=defines.electric_interface_mode.primary_output;g.electric_buffer_size=20000000;g.energy=20000000;g.power_usage=0;g.power_production=0;g.output_flow_limit=20000000/60;g.input_flow_limit=0
 local a=make(s,'em-electric-locomotive',0,1,{direction=defines.direction.west});local b=make(s,'em-electric-locomotive',7,1,{direction=defines.direction.west})
 ck(a.train.id==b.train.id,'initial join');storage.qa={a=a,b=b,g=g,aid=a.unit_number,bid=b.unit_number}
end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.qa;local a,b=st.a,st.b
 if t==120 then
  local p=remote.call('em072_native_qa_071','snapshot');ck(math.abs(p.paid_J-4000000)<.05,'legacy source paid 4MJ '..p.paid_J);st.legacy=p.paid_J;log('[MIG] legacy source '..p.paid_J)
 elseif t==241 then game.server_save('migration-checkpoint')
 elseif t==300 then
  local z=snap(a);ck(#z.owners==2 and z.legacy_paid_J==st.legacy and z.paid_J==st.legacy,'legacy offset preserved');ck(z.live_loco_J==0 and z.live_motor_J==0,'invented historic owner attribution');st.c=make(a.surface,'em-electric-locomotive',33,1,{direction=defines.direction.west});log('[MIG] offset '..z.legacy_paid_J)
 elseif t==420 then
  local z=snap(st.c);ck(z.legacy_paid_J==st.legacy and z.live_loco_J>0 and z.paid_J>st.legacy,'new credits after migration');local lab=game.surfaces['em-25kv-isolated-bridge-058'];local h=0;for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end
  ck(math.abs(st.g.energy+h+z.paid_J-20000000)<100,'migrated closed source conservation');log(string.format('[MIG] PASS legacy=%.3f new=%.3f paid=%.3f source=%.3f hidden=%.3f',z.legacy_paid_J,z.live_loco_J,z.paid_J,st.g.energy,h));script.finish_test(true)
 end
end)
