local function ck(x,m)if not x then error('[BATMIG FAIL] '..m) end end
local function make(s,n,x,y,o)local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end;local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e end
script.on_init(function()
 local s=game.create_surface('batmig',{width=512,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-100,100,64 do s.request_to_generate_chunks({x=x,y=0},2)end;s.force_generate_chunk_requests()
 for x=-100,100,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 for x=-81.5,79,20 do make(s,'em-35kv-catenary-pole',x,2.5)end
 make(s,'em-35kv-traction-substation',-20,9)
 local g=make(s,'electric-energy-interface',-20,13);g.electric_interface_mode=defines.electric_interface_mode.primary_output;g.electric_buffer_size=2000000;g.energy=2000000;g.power_usage=0;g.power_production=0;g.output_flow_limit=20000000/60;g.input_flow_limit=0
 local a=make(s,'em-electric-locomotive',0,1,{direction=defines.direction.west});storage.st={a=a,g=g}
end)
script.on_event(defines.events.on_tick,function(ev)
 local st=storage.st;local t=ev.tick
 if t==241 then
  local p=remote.call('em088_train_energy','snapshot',st.a.unit_number);ck(math.abs(p.paid_J-2000000)<.05 and st.g.energy<.05,'base payment');st.old_J=p.paid_J;log('[BATMIG] old paid='..p.paid_J);game.server_save('onboard-migration')
 elseif t==361 then
  if not remote.interfaces['em089_onboard_storage'] then return end
  local p=remote.call('em088_train_energy','snapshot',st.a.unit_number);local z=remote.call('em089_onboard_storage','snapshot',st.a.unit_number)
  ck(math.abs(p.paid_J-st.old_J)<.05,'old history changed');ck(z.stored_J==0 and z.charged_J==0 and z.discharged_J==0 and z.lost_J==0 and z.owners[1].J==0,'migration created charge');ck(math.abs(st.a.burner.remaining_burning_fuel-2000000)<.05,'old burner reserve changed');log('[BATMIG] PASS history='..p.paid_J..' stored='..z.stored_J..' enabled='..tostring(z.enabled));script.finish_test(true)
 end
end)
