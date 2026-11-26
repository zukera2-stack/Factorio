-- EM072 finite-J 500kW helper physical native demonstration on unchanged full 0.1.69.
-- Not a release or production motor wagon controller; no LuaTrain.speed writes.
local CASE='paid'
local HAS_HELPER=(CASE~='base' and CASE~='base4')
local PAID=(CASE=='paid4' or CASE=='paid' or CASE=='paid_fluid' or CASE=='paid_cut' or CASE=='paid_delete' or CASE=='paid_delete_fixed' or CASE=='paid_offgrid' or CASE=='paid_both')
local BOOST_W=(CASE=='paid4') and 2000000 or (CASE=='paid_both') and 1000000 or 500000
local LMAX=BOOST_W/60
local function logit(tag,msg) log('[EM072 PAIDPROOF] '..CASE..' '..tag..' '..msg) end
local function ck(b,msg) if not b then error('[EM072 PAIDPROOF FAIL] '..CASE..' '..msg) end end
local function spawn(s,name,x,y,direction)
 local e=s.create_entity{name=name,position={x=x,y=y},force=game.forces.player,
    direction=direction or defines.direction.west,raise_built=true}
 ck(e and e.valid, 'cannot create '..name..' '..x..','..y)
 return e
end
local function setup()
 local s=game.create_surface('em072-test-'..CASE,{width=640,height=160})
 s.generate_with_lab_tiles=true
 s.request_to_generate_chunks({0,0},8);s.force_generate_chunk_requests()
 for x=-245,245,2 do spawn(s,'em-high-speed-straight-rail',x,1,defines.direction.east) end
 if CASE~='paid_offgrid' then
  for x=-221.5,218.5,20 do spawn(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east) end
 end
 spawn(s,'em-35kv-traction-substation',-20,9,defines.direction.east)
 spawn(s,'em-35kv-traction-substation',20,9,defines.direction.east)
 local source=spawn(s,'electric-energy-interface',-20,13,defines.direction.east)
 source.electric_interface_mode=defines.electric_interface_mode.primary_output
 source.electric_buffer_size=10000000
 source.power_production=20000000/60;source.power_usage=0
 source.input_flow_limit=0;source.output_flow_limit=20000000/60;source.energy=0
 -- The existing fullmod C5 motor wagons are genuine cargo/fluid native prototypes.
 local loco=spawn(s,'em-electric-locomotive',0,1)
 local cargo=spawn(s,CASE=='paid_fluid' and 'cargo-wagon' or 'em-motor-cargo-wagon',7,1)
 local fluid=spawn(s,(CASE=='paid_fluid' or CASE=='paid_both' or CASE=='paid4' or CASE=='base4') and 'em-motor-fluid-wagon' or 'fluid-wagon',14,1)
 local extra={}
 if CASE=='paid4' or CASE=='base4' then
  extra[#extra+1]=spawn(s,'em-motor-cargo-wagon',21,1)
  extra[#extra+1]=spawn(s,'em-motor-fluid-wagon',28,1)
 end
 local inserted=cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}
 local water=fluid.insert_fluid{name='water',amount=9000}
 ck(inserted==37 and water==9000,'native cargo/fluid fill failed')
 local helper=nil
 if HAS_HELPER then
   local disconnected=loco.disconnect_rolling_stock(defines.rail_direction.back)
   ck(disconnected,'cannot disconnect real locomotive')
   helper=spawn(s,'em-c5-technical-booster-'..(BOOST_W/1000),3.5,1)
   helper.minable_flag=false;helper.destructible=false
   ck(helper.train and helper.train.id==loco.train.id,'technical loco not physically connected to owner')
   ck(helper.burner and (helper.burner.remaining_burning_fuel or 0)==0,'helper starts with unpaid fuel')
 end
 local t=loco.train
 ck(t and t.valid and #t.carriages==((HAS_HELPER and 4 or 3)+#extra),'wrong native rolling stock count')
 ck(t.speed==0,'train not stationary at initial stage')
 local visible_tail=#extra>0 and extra[#extra] or fluid
 local span=math.abs(visible_tail.position.x-loco.position.x)
 ck(math.abs(span-(14+7*#extra))<0.0001,'visual train grew unexpectedly span='..span)
 ck((cargo.type=='cargo-wagon') and (fluid.type=='fluid-wagon'),'wagon native cargo/fluid types corrupted')
 local st={s=s,source=source,loco=loco,cargo=cargo,fluid=fluid,extra=extra,visible_tail=visible_tail,helper=helper,
    xpos=loco.position.x,paid_J=0,consumed_J=0,init_J=0,sink=nil,first_t=0,
    demand_peak=0,helper_max_J=0,energy_left=0}
 storage.proof=st
 logit('SETUP', 'real_stock='..#t.carriages..' helper='..tostring(HAS_HELPER)..' paid='..tostring(PAID)..
   ' span='..span..' cargo=37 fluid=9000 source_W=20000000 booster_W='..BOOST_W)
end
local function find_line_out()
 local lab=game.surfaces['em-25kv-isolated-bridge-058']
 if not lab then return nil,nil end
 local outputs=lab.find_entities_filtered{name='em-25kv-bridge-output-058'}
 table.sort(outputs,function(a,b)return a.unit_number<b.unit_number end)
 for _,port in ipairs(outputs)do
  if port.valid and port.electric_network_id then return lab,port end
 end
 return lab,nil
end
local function ensure_sink(st)
 if st.sink and st.sink.valid then return st.sink end
 local lab,out=find_line_out()
 if not out then return nil end
 local sink=lab.create_entity{name='em-25kv-native-traction-consumer-068',position=out.position,
   force=out.force,raise_built=false,create_build_effect_smoke=false}
 ck(sink and sink.valid,'failed to create native test-owned network consumer')
 sink.electric_interface_mode=defines.electric_interface_mode.secondary_input
 sink.electric_buffer_size=LMAX*2
 sink.input_flow_limit=LMAX;sink.output_flow_limit=0
 sink.power_usage=0;sink.power_production=0;sink.energy=0
 ck(sink.electric_network_id==out.electric_network_id,
  'test native sink not on actual EM070 catenary network')
 st.sink=sink;st.first_t=game.tick
 logit('NATIVE_EEI', 'tick='..game.tick..' sink='..sink.unit_number..' native_net='..sink.electric_network_id..
     ' output='..out.unit_number..' input_J_per_tick='..LMAX)
 return sink
end
local function credit(st)
 if not (st.helper and st.helper.valid and st.loco.valid and st.sink and st.sink.valid) then return end
 ck(st.helper.train and st.loco.train and st.helper.train.id==st.loco.train.id,
    'helper became disconnected from genuine owner')
 local fuel=prototypes.item['em-c5-test-internal-joule-063']
 ck(fuel,'native test-only internal fuel prototype absent')
 local hb=st.helper.burner
 local reserve=math.max(0,hb.remaining_burning_fuel or 0)
 ck(reserve<=LMAX+1,'helper had excess unaccounted reserve='..reserve)
 local paid=math.max(0,math.min(LMAX-reserve,st.sink.energy))
 if paid<=0 then return end
 if not hb.currently_burning then
   hb.currently_burning=fuel
   hb.remaining_burning_fuel=0
   reserve=0
 end
 local before=st.sink.energy
 st.sink.energy=before-paid
 ck(math.abs((before-st.sink.energy)-paid)<0.05,'native sink debit failed')
 hb.remaining_burning_fuel=reserve+paid
 ck(math.abs(hb.remaining_burning_fuel-(reserve+paid))<0.05,'native helper credit failed')
 st.paid_J=st.paid_J+paid
 st.helper_max_J=math.max(st.helper_max_J,hb.remaining_burning_fuel)
end
script.on_event(defines.events.on_tick,function(ev)
 local tick=ev.tick
 if tick==2 then setup() end
 local st=storage.proof
 if not st then return end
 if PAID and not st.owner_dismantled then
   ensure_sink(st)
   if st.sink and st.sink.valid then
     -- Only native solver input from authentic catenary can pay the helper.
     st.sink.input_flow_limit=LMAX
     local parent=st.sink.electric_network and st.sink.electric_network.parent_network
     local f=parent and parent.flow_last_tick
     if f then st.demand_peak=math.max(st.demand_peak,(f.primary_demand or 0)+(f.secondary_demand or 0)) end
     credit(st)
   end
 end
 if tick>=132 and tick<=160 and not st.owner_dismantled and (st.helper.burner.remaining_burning_fuel or 0)>100 then
   st.owner_dismantled=true
   st.loss_tick=tick
   st.loss_expected=st.helper.burner.remaining_burning_fuel or 0
   st.sink_at_removal=st.sink.energy
   st.source.power_production=0;st.source.output_flow_limit=0;st.source.energy=0
   st.sink.input_flow_limit=0
   logit('OWNER_DELETE',string.format('tick=%d charged_native_helper_J=%.3f sink_J=%.3f',tick,st.loss_expected,st.sink_at_removal))
   st.loco.destroy{raise_destroy=true}
 end
 if tick==170 then
   ck(st.owner_dismantled,'test never dismantled an actually charged helper')
   ck(not st.helper.valid,'charged native helper survived owner removal')
   ck(st.cargo.valid and st.fluid.valid,'real cargo/fluid destroyed')
   ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'iron missing')
   ck(st.fluid.get_fluid(1) and st.fluid.get_fluid(1).amount==9000,'water missing')
   ck(st.sink.valid and st.sink.energy<=st.sink_at_removal+0.1,'destroyed paid J refunded without authorization')
   logit('LOSS_SAVELOAD_PASS',string.format('tick=170 lost_helper_J=%.3f sink_at_loss_J=%.3f sink_final_J=%.3f paid_cumulative_J=%.3f iron=37 water=9000',st.loss_expected,st.sink_at_removal,st.sink.energy,st.paid_J))
 end
 if tick==125 and not storage.em072_paid_saved then
   storage.em072_paid_saved=true
   local ok,why=pcall(function()game.server_save('em072-lossy-persistence-checkpoint')end)
   ck(ok,'real independent server SAVE failed '..tostring(why))
   logit('DISK_SAVE','tick=125 helper='..st.helper.unit_number..' loco='..st.loco.unit_number..' boosterJ='..st.helper.burner.remaining_burning_fuel..' sourceJ='..st.source.energy..' paidJ='..st.paid_J)
 end
 if tick==50 then
   local driver=st.s.create_entity{name='character',position=st.loco.position,force='player'}
   ck(driver,'cannot create native locomotive driver')
   st.loco.set_driver(driver)
   driver.riding_state={acceleration=defines.riding.acceleration.accelerating,
     direction=defines.riding.direction.straight}
   logit('DRIVE','tick=50 native driver accelerating; loco_J='..(st.loco.burner.remaining_burning_fuel or 0))
 end
 if (CASE=='paid_delete' or CASE=='paid_delete_fixed') and tick==95 then
   logit('OWNER_DELETE','owner='..st.loco.unit_number..' helper='..st.helper.unit_number..' remaining_paidJ='..(st.helper.burner.remaining_burning_fuel or 0))
   st.loco.destroy{raise_destroy=true}
 end
 if CASE=='paid_delete_fixed' and tick==96 then
   local j=st.helper.burner.remaining_burning_fuel or 0
   local before=st.sink.energy+j
   st.sink.input_flow_limit=0
   local room=math.max(0,st.sink.electric_buffer_size-st.sink.energy)
   local refund=math.min(room,j)
   st.sink.energy=st.sink.energy+refund
   -- If native EEI is full, keep the rest as paid J escrow in test-only
   -- storage instead of discarding or inventing energy. No other entity
   -- may consume this escrow. Production requires owner/feeder binding.
   st.orphan_paid_escrow_J=j-refund
   st.refunded_J=refund
   st.helper.burner.remaining_burning_fuel=0
   st.helper.destroy{raise_destroy=true}
   ck(not st.helper.valid,'paid helper did not destroy after native escrow refund')
   ck(math.abs(st.sink.energy+st.orphan_paid_escrow_J-before)<0.1,'paid Joule refund/escrow violates balance')
   logit('REFUND',string.format('tick=96 paid_J=%.3f returned_same_native_sink_J=%.3f paid_escrow_J=%.3f delta_J=%.6f',j,refund,st.orphan_paid_escrow_J,st.sink.energy+st.orphan_paid_escrow_J-before))
 end
 if (CASE=='paid_delete' or CASE=='paid_delete_fixed') and tick==120 then
   ck(not (st.helper and st.helper.valid),'ORPHAN: paid helper still exists 25 ticks after real owner was destroyed')
   ck(st.cargo.valid and st.fluid.valid and st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37, 'cargo lost on owner death')
   ck(st.fluid.get_fluid(1).amount==9000,'fluid lost on owner death')
   logit('RESULT','status=PASS paid helper cleaned, finite-J refund and escrow accounted')
   -- test-save-only server does not have script.finish_test
   return
 end
 if CASE=='paid_offgrid' and tick==90 then
   ck(not st.sink,'offgrid 25kV sink incorrectly created')
   ck(st.helper.burner.remaining_burning_fuel==0,'offgrid helper got free fuel')
   ck((st.loco.burner.remaining_burning_fuel or 0)==0,'offgrid genuine EM loco got free fuel')
   logit('RESULT','status=PASS no 25kV link, no genuine EEI demand, helperJ=0 and locoJ=0')
   -- test-save-only server does not have script.finish_test
 end
 if CASE=='paid_cut' and tick==95 then
   st.source.power_production=0;st.source.output_flow_limit=0;st.source.energy=0
   logit('FAULT','source primary native electric interface output set 0 at tick95')
 end
 if tick%30==0 and not st.owner_dismantled then
  local helper_J=st.helper and st.helper.valid and st.helper.burner.remaining_burning_fuel or 0
  logit('TRACE',string.format('tick=%d position_x=%.6f locoJ=%.3f helperJ=%.3f paidJ=%.3f test_sinkJ=%.3f demand_peak=%.3f',
   tick,(st.loco.valid and st.loco.position.x or st.xpos),(st.loco.valid and st.loco.burner.remaining_burning_fuel or 0),helper_J,
   st.paid_J,st.sink and st.sink.valid and st.sink.energy or -1,st.demand_peak))
 end
 if tick==220 then
   if not st.loco.valid then return end
  local span=math.abs(st.loco.position.x-st.visible_tail.position.x)
  ck(math.abs(span-(14+7*#st.extra))<0.01,'physical visible span changed: '..span)
  ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost')
  ck(math.abs((st.fluid.get_fluid(1) and st.fluid.get_fluid(1).amount or 0)-9000)<1,'fluid lost')
  ck((st.loco.burner.remaining_burning_fuel or 0)<=2000000+0.1,'locomotive native burner exceeded cap')
  if PAID then
   ck(st.sink and st.sink.valid and st.demand_peak>1,'no true native network load')
   ck(st.paid_J>50000,'helper never received real catenary-paid Joules')
   ck(st.helper_max_J<=LMAX+1,'native proxy exceeded 1-tick paid quantum')
  elseif st.helper then ck((st.helper.burner.remaining_burning_fuel or 0)==0,'zero-powered helper gained free Joules') end
  logit('RESULT',string.format('status=PASS displacement=%.6f helper_paid_J=%.3f helper_reserve_J=%.3f loco_reserve_J=%.3f native_demand_peak=%.3f max_helper_buffer_J=%.3f span=%.6f',
   st.loco.position.x-st.xpos,st.paid_J,st.helper and st.helper.burner.remaining_burning_fuel or 0,
   st.loco.burner.remaining_burning_fuel or 0,st.demand_peak,st.helper_max_J,span))
  -- test-save-only server does not have script.finish_test
 end
end)