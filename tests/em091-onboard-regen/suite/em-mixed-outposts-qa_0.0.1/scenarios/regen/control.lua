local mode=script.test_arg or 'reload'
local W=1000000/60
local function ck(x,m)if not x then error('[REGEN FAIL] '..mode..' '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function b(e)return remote.call('em089_onboard_storage','snapshot',e and e.unit_number)end
local function r(e)return remote.call('em091_brake_recovery','snapshot',e and e.unit_number)end
local function stop(s,y,x)
 for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do local q=s.create_entity{name='train-stop',position={x=x,y=y+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='BATTERY';return q elseif q and q.valid then q.destroy()end end end
 error('stop')
end
local function snap(st,t)
 local h=0;local lab=game.surfaces['em-25kv-isolated-bridge-058'];if lab then for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end end
 local z=b(st.a);local q=r(st.a);local paid=remote.call('em072_native_qa_071','snapshot').paid_J;local src=st.g.energy
 local sum=src+h+paid+z.stored_J+z.discharged_J+z.lost_J-z.regen_J
 ck(math.abs(sum-st.budget)<100,'balance '..sum..' vs '..st.budget)
 ck(math.abs(z.charged_J+z.regen_J-z.discharged_J-z.lost_J-z.stored_J)<.05,'store conservation')
 ck(z.stored_J>=0 and z.stored_J<=z.capacity_J*((mode=='couple') and 2 or 1)+.05,'capacity')
 ck(math.abs(q.recovered_J-z.regen_J)<.05,'recovery mismatch');ck(math.abs(q.estimated_J-q.recovered_J-q.rejected_J)<.05,'offer mismatch')
 ck(q.recovered_J<=q.consumed_J+.05,'unpaid recovered energy')
 local fuel=0;for _,e in ipairs(st.a.train.carriages)do if e.burner then fuel=fuel+e.burner.remaining_burning_fuel end end
 local independent=paid+z.discharged_J-fuel
 if mode~='foreign' and mode~='couple' and mode~='inject' then ck(q.consumed_J<=independent+.1,'native debit exceeds independent estimate '..q.consumed_J..' vs '..independent) end
 log(string.format('[REGEN QA] %s t=%d src=%.3f hidden=%.3f paid=%.3f gridcharge=%.3f stored=%.3f discharge=%.3f recovery=%.3f estimate=%.3f rejected=%.3f debit=%.3f independent=%.3f total=%.3f v=%.9f x=%.3f cert=%s reason=%s',mode,t,src,h,paid,z.charged_J,z.stored_J,z.discharged_J,q.recovered_J,q.estimated_J,q.rejected_J,q.consumed_J,independent,sum,st.a.train.speed,st.a.position.x,tostring(q.certified),tostring(q.reason)))
 return z,q
end
script.on_init(function()
 local s=game.create_surface('regen',{width=4096,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-1800,100,64 do s.request_to_generate_chunks({x=x,y=0},2)end;s.force_generate_chunk_requests()
 for x=-1800,100,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 for x=(mode=='full' and -801.5 or -81.5),79,20 do make(s,'em-35kv-catenary-pole',x,2.5)end
 make(s,'em-35kv-traction-substation',-20,9)
 local g=make(s,'electric-energy-interface',-20,13);g.electric_interface_mode=defines.electric_interface_mode.primary_output;g.electric_buffer_size=200000000
 local budget=mode=='empty' and 0 or mode=='full' and 100000000 or (mode=='auto' or mode=='reload' or mode=='disabled') and 12000000 or (mode=='cycle' or mode=='reuse') and 19200000 or mode=='coast' and 4500000 or 30000000
 g.energy=budget;g.power_usage=0;g.power_production=0;g.output_flow_limit=20*W;g.input_flow_limit=0
 local a=make(s,'em-electric-locomotive',0,1,{direction=defines.direction.west});local st={a=a,g=g,budget=budget}
 if mode~='full' and mode~='foreign' and mode~='couple' and mode~='empty' then st.cargo=make(s,'em-motor-cargo-wagon',7,1,{direction=defines.direction.west});st.fluid=make(s,'em-motor-fluid-wagon',14,1,{direction=defines.direction.west});st.cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37};st.fluid.insert_fluid{name='water',amount=9000} end
 if mode=='foreign' then st.diesel=make(s,'locomotive',7,1,{direction=defines.direction.west});st.diesel.burner.inventory.insert{name='coal',count=5} end
 if mode=='couple' then st.b=make(s,'em-electric-locomotive',7,1,{direction=defines.direction.west}) end
 st.stop=stop(s,1,(mode=='auto' or mode=='reload' or mode=='disabled') and -700 or -1700)
 if mode=='inject' then a.burner.currently_burning=prototypes.item['em-c5-test-internal-joule-063'];a.burner.remaining_burning_fuel=100000;st.injected=true end
 storage.st=st
 ck(b(a).enabled and r(a).enabled==(mode~='disabled') and b(a).stored_J==0,'empty init/enable')
end)
script.on_event(defines.events.on_entity_damaged,function(ev)local st=storage.st;if st then st.damage_tick=ev.tick;st.damage=true;log('[REGEN DAMAGE] '..ev.tick..' '..ev.entity.name) end end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st;local a=st.a;local tr=a.train;local v=math.abs(tr.speed)
 local z,q=b(a),r(a)
 local dc=z.charged_J-(st.last_charge or 0);local dr=z.regen_J-(st.last_regen or 0);local dd=z.discharged_J-(st.last_discharge or 0)
 local count=mode=='couple' and 2 or 1
 ck(dc>=-.05 and dr>=-.05 and dd>=-.05 and dc+dr<=z.charge_J_tick*count+.05 and dd<=z.discharge_J_tick*count+.05,'rate')
 ck(dc+dr<.05 or dd<.05,'same tick charge/discharge')
 -- The level handler runs BEFORE the mod's on_tick. A new counter value
 -- here belongs to the preceding tick, not to the current native state.
 if dr>0 then ck(q.last_credit_tick==t-1 and st.last_r==defines.riding.acceleration.braking and st.last_v>0,'non-brake credit at '..t);st.credit_ticks=(st.credit_ticks or 0)+1 end
 if mode=='collision' and st.cycle_start and t>=st.cycle_start+130 and t<=st.cycle_start+138 then
   log(string.format('[COLLISION OBS] t=%d prev_v=%.9f v=%.9f credit_previous_tick=%.9f last_credit_tick=%s damage_tick=%s',t,st.last_v or 0,v,dr,tostring(q.last_credit_tick),tostring(st.damage_tick)))
 end
 -- Damage is emitted after the tick callback for the tested collision. A
 -- prior ordinary braking interval may have already been credited. The
 -- sampled interval containing the actual crash is the NEXT interval.
 if st.damage_tick and t-1>st.damage_tick and t-1<=st.damage_tick+2 then ck(dr<.05,'collision interval credit') end
 st.last_r=tr.riding_state.acceleration;st.last_v=v
 st.last_charge=z.charged_J;st.last_regen=z.regen_J;st.last_discharge=z.discharged_J
 if t%120==0 then snap(st,t) end
 local launch=mode=='full' and 2400 or ((mode=='auto' or mode=='reload' or mode=='disabled') and 720 or 1200)
 if t==launch then
   snap(st,t);ck(mode=='empty' or z.stored_J>1000000,'no prior storage');st.initial=z.stored_J;st.src=st.g.energy
   if mode~='full' then st.g.output_flow_limit=0 end
   tr.schedule={current=1,records={{station=st.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false;st.cycle_start=t
 end
 if mode=='empty' and t==1800 then ck(q.recovered_J==0 and z.stored_J==0 and v==0,'empty created energy');script.finish_test(true) end
 if (mode=='cycle' or mode=='reuse' or mode=='collision' or mode=='foreign' or mode=='couple' or mode=='full' or mode=='inject') and st.cycle_start then
   local run_ticks=mode=='reuse' and (st.cycles or 0)==3 and 60 or 120
   if not tr.manual_mode and t==st.cycle_start+run_ticks then tr.manual_mode=true end
   if mode=='collision' and t==st.cycle_start+130 then st.obstacle=make(a.surface,'tank',math.floor(a.position.x)-8,1,{direction=defines.direction.north}) end
   if mode=='couple' and t==st.cycle_start+125 then
     for _,side in ipairs({defines.rail_direction.front,defines.rail_direction.back})do local n=a.get_connected_rolling_stock(side);if n and n.unit_number==st.b.unit_number then st.side=side end end
     st.split_regen=z.regen_J;ck(st.side and a.disconnect_rolling_stock(st.side),'split while moving');st.split_tick=t;tr=a.train;v=math.abs(tr.speed)
   end
   if tr.manual_mode and v==0 and t>st.cycle_start+run_ticks and (mode~='collision' or (st.damage_tick and t>=st.damage_tick+2)) then
     st.cycles=(st.cycles or 0)+1;local x,y=snap(st,t);log('[REGEN CYCLE] '..st.cycles..' recovered='..y.recovered_J..' discharge='..x.discharged_J)
     if (mode=='cycle' or mode=='reuse') and st.cycles<(mode=='reuse' and 4 or 3) then if st.cycles==1 then st.first_regen=y.recovered_J;st.first_discharge=x.discharged_J end;st.cycle_start=t;tr.manual_mode=false
     else
       if mode=='cycle' or mode=='reuse' then ck(st.first_regen>1000 and y.recovered_J>st.first_regen and x.discharged_J>st.first_discharge,'no repeated recovery/use');ck(st.g.energy==st.src,'disabled source changed');ck(x.discharged_J>st.initial+1000,'no proven reuse beyond initial store');if mode=='reuse' then ck(y.consumed_J>st.budget+1000,'native debit does not exceed initial finite source') end
       elseif mode=='foreign' then ck(y.recovered_J==0,'diesel credit')
       elseif mode=='inject' then ck(st.injected and y.recovered_J==0,'unverified initial burner credit')
       elseif mode=='collision' then ck(st.damage,'no damage');ck(y.last_credit_tick and y.last_credit_tick<=st.damage_tick,'collision tick credited');ck(y.recovered_J>0,'no positive pre-collision brake control')
       elseif mode=='couple' then ck(math.abs(y.recovered_J-st.split_regen)<.05,'uncertified post-split recovery')
       elseif mode=='full' then ck(x.stored_J<=x.capacity_J+.05 and y.estimated_J>0 and y.rejected_J>0,'full store did not reject') end
       script.finish_test(true)
     end
   end
 end
 if mode=='coast' and st.cycle_start then
   if st.prev_v and v<st.prev_v-1e-8 and tr.riding_state.acceleration~=defines.riding.acceleration.braking then st.coast=(st.coast or 0)+1 end;st.prev_v=v
   if t==3000 then local x,y=snap(st,t);ck((st.coast or 0)>100 and y.recovered_J==0,'coast recovered');ck(st.g.energy==st.src,'source changed');script.finish_test(true) end
 end
 if mode=='auto' or mode=='reload' or mode=='disabled' then
   if mode=='reload' and not st.saved and q.recovered_J>10000 and v>0 then st.saved=true;st.saved_regen=q.recovered_J;snap(st,t);game.server_save('regen-checkpoint') end
   if tr.station==st.stop and t>launch+100 then
     local x,y=snap(st,t);ck(mode=='disabled' and y.recovered_J==0 or mode~='disabled' and y.recovered_J>10000,'wrong recovery');if mode~='disabled' then ck(x.discharged_J>st.initial+1000,'no reuse beyond initial storage') end;ck(st.g.energy==st.src,'disabled source changed');ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and st.fluid.get_fluid_count('water')==9000,'payload changed');script.finish_test(true)
   end
 end
end)
