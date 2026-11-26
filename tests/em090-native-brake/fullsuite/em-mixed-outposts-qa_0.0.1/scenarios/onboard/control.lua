local mode=script.test_arg or 'reload'
local W=1000000/60
local function ck(x,m)if not x then error('[ONBOARD FAIL] '..mode..' '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function b(e)return remote.call('em089_onboard_storage','snapshot',e and e.unit_number)end
local function snap(st,t)
 local h=0;local lab=game.surfaces['em-25kv-isolated-bridge-058'];if lab then for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end end
 local z=b(st.a);local paid=remote.call('em072_native_qa_071','snapshot').paid_J;local src=st.g.energy;local load=st.load and st.load.energy or 0;local vb=st.vb and st.vb.energy or 0
 local sum=src+load+vb+h+paid+z.stored_J+z.discharged_J+z.lost_J
 ck(math.abs(sum-st.budget)<100,'balance '..sum..' vs '..st.budget)
 ck(math.abs(z.charged_J-z.discharged_J-z.lost_J-z.stored_J)<.05,'store conservation')
 ck(z.stored_J>=0 and z.stored_J<=z.capacity_J*((mode=='couple' or mode=='shared') and 2 or 1)+.05,'capacity')
 log(string.format('[ONBOARD] %s t=%d src=%.3f load=%.3f vb=%.3f hidden=%.3f grid_paid=%.3f charged=%.3f stored=%.3f discharged=%.3f motor=%.3f lost=%.3f total=%.3f x=%.3f speed=%.6f',mode,t,src,load,vb,h,paid,z.charged_J,z.stored_J,z.discharged_J,z.motor_J,z.lost_J,sum,st.a.position.x,st.a.train.speed))
 return z,paid
end
local function stop(s,y,x)
 for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do local q=s.create_entity{name='train-stop',position={x=x,y=y+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='BATTERY';return q elseif q and q.valid then q.destroy()end end end
 error('stop')
end
script.on_init(function()
 local s=game.create_surface('onboard',{width=2048,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-740,100,64 do s.request_to_generate_chunks({x=x,y=0},2)end;s.force_generate_chunk_requests()
 for x=-740,100,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 for x=-81.5,79,20 do make(s,'em-35kv-catenary-pole',x,2.5)end
 make(s,'em-35kv-traction-substation',-20,9)
 local g=make(s,'electric-energy-interface',-20,13);g.electric_interface_mode=defines.electric_interface_mode.primary_output;g.electric_buffer_size=200000000
 local budget=mode=='empty' and 0 or (mode=='cap' or mode=='outage') and 100000000 or mode=='couple' and 20000000 or mode=='priority' and 100000000 or mode=='vanilla-battery' and 5000000 or 12000000
 g.energy=mode=='vanilla-battery' and 0 or budget;g.power_usage=0;g.power_production=0;g.output_flow_limit=mode=='priority' and 2*W or 20*W;g.input_flow_limit=0
 local a=make(s,'em-electric-locomotive',0,1,{direction=defines.direction.west});local st={a=a,g=g,budget=budget}
 if mode=='couple' then st.b=make(s,'em-electric-locomotive',7,1,{direction=defines.direction.west});ck(st.b.train.id==a.train.id,'initial join') end
 if mode=='move' or mode=='outage' then st.cargo=make(s,'em-motor-cargo-wagon',7,1,{direction=defines.direction.west});st.fluid=make(s,'em-motor-fluid-wagon',14,1,{direction=defines.direction.west});st.cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37};st.fluid.insert_fluid{name='water',amount=9000};st.stop=stop(s,1,-700) end
 if mode=='priority' then local e=make(s,'electric-energy-interface',-16,13);e.electric_interface_mode=defines.electric_interface_mode.secondary_input;e.electric_buffer_size=200000000;e.energy=0;e.power_usage=0;e.power_production=0;e.output_flow_limit=0;e.input_flow_limit=2*W;st.load=e end
 if mode=='vanilla-battery' then st.vb=make(s,'accumulator',-16,13);st.vb.energy=5000000 end
 storage.st=st
 ck(b(a).enabled and b(a).stored_J==0,'empty init')
end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st;local a=st.a
 local tr=a.train; local fuel=0;local helpers=0;for _,c in ipairs(tr.carriages)do if c.burner then fuel=fuel+c.burner.remaining_burning_fuel end;if c.name:match('^em%-c5%-technical%-booster') then helpers=helpers+1 end end
 local z=b(a);local paid=remote.call('em072_native_qa_071','snapshot').paid_J
 log(string.format('[FULLTRACE] %d %.12f %d %d %.6f %.6f %.6f %.6f %d %d %.6f',t,math.abs(tr.speed),tr.riding_state.acceleration,tr.state,tr.weight,paid,z.discharged_J,fuel,helpers,tr.id,a.position.x))
 local now=b(a);local dc=now.charged_J-(st.last_charge or 0);local dd=now.discharged_J-(st.last_discharge or 0)
 local count=(mode=='couple' or mode=='shared') and 2 or 1
 ck(dc>=-.05 and dd>=-.05 and dc<=now.charge_J_tick*count+.05 and dd<=now.discharge_J_tick*count+.05,'per-tick rate')
 ck(dc<.05 or dd<.05,'same-tick charge/discharge')
 st.last_charge=now.charged_J;st.last_discharge=now.discharged_J
 if t%120==0 then snap(st,t) end
 if mode=='empty' and t==360 then ck(b(a).stored_J==0 and b(a).discharged_J==0 and a.burner.remaining_burning_fuel==0,'empty created energy');script.finish_test(true)
 elseif mode=='priority' and t==600 then local z=snap(st,t);ck(z.stored_J<100,'charge under full competing load');ck(st.load.energy>19000000,'ordinary load starved');script.finish_test(true)
 elseif mode=='vanilla-battery' and t==600 then local z=snap(st,t);ck(z.stored_J<100,'factory battery charged onboard store');script.finish_test(true)
 elseif mode=='cap' and t==2400 then local z=snap(st,t);ck(math.abs(z.stored_J-60000000)<.1,'capacity not reached');ck(z.discharged_J==0,'stationary discharge');script.finish_test(true)
 elseif mode=='charge' and t==720 then local z=snap(st,t);ck(z.stored_J>9000000,'charge not completed');ck(z.discharged_J==0,'stationary discharge');script.finish_test(true)
 elseif mode=='reload' then
  if t==241 then local z=snap(st,t);ck(z.stored_J>1000000,'nonzero checkpoint');st.check_J=z.stored_J;game.server_save('onboard-checkpoint')
  elseif t==242 then local z=snap(st,t);ck(z.stored_J>=st.check_J and z.stored_J<=st.check_J+z.charge_J_tick+.05,'reloaded charge not preserved')
  elseif t==720 then local z=snap(st,t);ck(z.stored_J>9000000 and z.discharged_J==0,'reload final');script.finish_test(true) end
 elseif mode=='outage' then
  if t==720 then local z,p=snap(st,t);ck(z.stored_J>10000000 and st.g.energy>10000000,'pre outage charge/source');st.paid=p;st.src=st.g.energy;st.start=a.position.x;st.g.output_flow_limit=0;local tr=a.train;tr.schedule={current=1,records={{station=st.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false
  elseif t==780 then local z,p=snap(st,t);ck(z.discharged_J>100000 and math.abs(st.g.energy-st.src)<.05,'no actual backup');st.p2=p;st.g.output_flow_limit=20*W
  elseif t==840 then local z,p=snap(st,t);ck(p>st.p2+100000 and st.g.energy<st.src,'no grid recovery');ck(z.discharged_J>0,'no deficit coverage')
  elseif t==1440 then local z=snap(st,t);ck(a.train.station==st.stop and math.abs(a.position.x-st.start)>600,'not arrived');ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and st.fluid.get_fluid_count('water')==9000,'payload changed');script.finish_test(true) end
 elseif mode=='shared' then
  if t==720 then local z=snap(st,t);ck(z.stored_J>9000000 and #z.owners==1,'charge one');st.initial=z.stored_J;st.g.output_flow_limit=0;st.b=make(a.surface,'em-electric-locomotive',7,1,{direction=defines.direction.west});ck(st.b.train.id==a.train.id,'new loco not coupled');local q=b(st.b);ck(q.owners[2].J==0 and st.b.burner.remaining_burning_fuel==0,'new loco created energy')
  elseif t==900 then local z=snap(st,t);ck(#z.owners==2 and z.owners[2].J==0,'physical owner changed');ck(st.b.burner.remaining_burning_fuel>1900000 and math.abs(z.discharged_J-2000000)<100,'no shared discharge');ck(math.abs(z.stored_J-(st.initial-2000000))<100,'donor reserve');script.finish_test(true) end
 elseif mode=='move' then
  if t==720 then local z,p=snap(st,t);ck(z.stored_J>5000000,'battery not charged');st.initial=z.stored_J;st.paid=p;st.src=st.g.energy;st.g.output_flow_limit=0;st.start=a.position.x;local tr=a.train;tr.schedule={current=1,records={{station=st.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false
  elseif t==1440 then local z=snap(st,t);ck(z.discharged_J>5000000 and z.motor_J>100000,'no autonomous motor traction');ck(math.abs(st.g.energy-st.src)<.05,'source changed after disabled');ck(math.abs(a.position.x-st.start)>10,'no autonomous movement');ck(z.stored_J<.05,'battery not empty');ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and st.fluid.get_fluid_count('water')==9000,'payload changed');script.finish_test(true) end
 elseif mode=='couple' then
  if t==720 then local z=snap(st,t);ck(#z.owners==2 and z.owners[1].J>1000000 and z.owners[2].J>1000000,'joint charge');st.j1=z.owners[1].J;st.j2=z.owners[2].J;st.g.output_flow_limit=0
    for _,side in ipairs({defines.rail_direction.front,defines.rail_direction.back})do local n=a.get_connected_rolling_stock(side);if n and n.unit_number==st.b.unit_number then st.side=side end end;ck(st.side and a.disconnect_rolling_stock(st.side),'split')
  elseif t==780 then local x,y=b(a),b(st.b);ck(#x.owners==1 and #y.owners==1 and x.train_id~=y.train_id,'split membership');ck(math.abs(x.owners[1].J-st.j1)<100 and math.abs(y.owners[1].J-st.j2)<100,'split charge changed');ck(a.connect_rolling_stock(st.side),'rejoin')
  elseif t==840 then local z=b(a);ck(#z.owners==2,'rejoin membership');st.loss=z.owners[2].J;ck(st.b.destroy{raise_destroy=true},'destroy')
  elseif t==961 then local z=snap(st,t);ck(#z.owners==1 and math.abs(z.lost_J-st.loss)<100,'retired battery loss');script.finish_test(true) end
 end
end)
