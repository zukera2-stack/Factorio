local OWNER=(script.test_arg or ""):find("^owner_")~=nil
local ownerMod=OWNER and require("owner_lifecycle") or nil
-- EM072 finite-J 500kW helper physical native demonstration on unchanged full 0.1.69.
-- Not a release or production motor wagon controller; no LuaTrain.speed writes.
local CASE=script.test_arg or 'base'
local HAS_HELPER=(CASE~='base' and CASE~='base4')
local PAID=(OWNER or CASE=='paid_scarce' or CASE=='paid4' or CASE=='paid' or CASE=='paid_fluid' or CASE=='paid_cut' or CASE=='paid_delete' or CASE=='paid_delete_fixed' or CASE=='paid_offgrid' or CASE=='paid_both')
local BOOST_W=(CASE=='paid4' or CASE=='owner_four') and 2000000 or (CASE=='paid_both' or CASE=='owner_two' or CASE=='owner_second') and 1000000 or 500000
local LMAX=BOOST_W/60
local SOURCE_W=(CASE=='paid_scarce' or CASE=='owner_scarce') and 1000000 or 20000000
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
 source.power_production=SOURCE_W/60;source.power_usage=0
 source.input_flow_limit=0;source.output_flow_limit=SOURCE_W/60;source.energy=0
 -- The existing fullmod C5 motor wagons are genuine cargo/fluid native prototypes.
 local loco=spawn(s,'em-electric-locomotive',0,1)
 local cargo=spawn(s,CASE=='paid_fluid' and 'cargo-wagon' or 'em-motor-cargo-wagon',7,1)
 local fluid=spawn(s,(CASE=='paid_fluid' or CASE=='paid_both' or CASE=='paid4' or CASE=='base4' or CASE=='owner_two' or CASE=='owner_four' or CASE=='owner_second') and 'em-motor-fluid-wagon' or 'fluid-wagon',14,1)
 local extra={}
 if CASE=='paid4' or CASE=='base4' or CASE=='owner_four' then
  extra[#extra+1]=spawn(s,'em-motor-cargo-wagon',21,1)
  extra[#extra+1]=spawn(s,'em-motor-fluid-wagon',28,1)
 end
 local second=nil
 if CASE=='owner_second' then
   second=spawn(s,'em-electric-locomotive',21,1,defines.direction.east)
   ck(second.valid,'cannot create second real EM')
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
 ck(t and t.valid and #t.carriages==((HAS_HELPER and 4 or 3)+#extra+(second and 1 or 0)),'wrong native rolling stock count')
 ck(t.speed==0,'train not stationary at initial stage')
 local visible_tail=#extra>0 and extra[#extra] or fluid
 local span=math.abs(visible_tail.position.x-loco.position.x)
 ck(math.abs(span-(14+7*#extra))<0.0001,'visual train grew unexpectedly span='..span)
 ck((cargo.type=='cargo-wagon') and (fluid.type=='fluid-wagon'),'wagon native cargo/fluid types corrupted')
 local st={s=s,source=source,loco=loco,cargo=cargo,fluid=fluid,extra=extra,visible_tail=visible_tail,helper=helper,helper_unit=helper and helper.unit_number,second=second,
    xpos=loco.position.x,paid_J=0,consumed_J=0,init_J=0,sink=nil,first_t=0,
    demand_peak=0,helper_max_J=0,energy_left=0}
 storage.proof=st
 if OWNER then st.owner_expected=(CASE=="owner_four" and 4 or (CASE=="owner_two" or CASE=="owner_second") and 2 or 1) end
 logit('SETUP', 'real_stock='..#t.carriages..' helper='..tostring(HAS_HELPER)..' paid='..tostring(PAID)..
   ' span='..span..' cargo=37 fluid=9000 source_W='..SOURCE_W..' booster_W='..BOOST_W)
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
 if st.owner_expected then ownerMod.register(st.loco,st.helper,sink,st.owner_expected) end
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
 if PAID then
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
 if CASE=='paid_scarce' and tick==60 then
   local native_loco=st.loco.burner.remaining_burning_fuel or 0
   local native_helper=st.helper.burner.remaining_burning_fuel or 0
   ck(native_loco>1000 and st.paid_J>1000 and native_helper>0,
      '1MW scarcity denied paid J to real loco or 500kW motor helper')
   ck(native_loco+st.paid_J<=SOURCE_W+50000,
      '1MW source exceeded 60-tick available J (check other source EEI buffers)')
   logit('SCARCITY',string.format('tick60 native_loco_J=%.3f paid_helper_cumulative_J=%.3f helper_buffer_J=%.3f sum=%.3f',
      native_loco,st.paid_J,native_helper,native_loco+st.paid_J))
 end
 if OWNER and tick<=90 then ownerMod.reconcile(tick,'active-check') end
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
 if (CASE=='owner_delete' or CASE=='owner_second' or CASE=='owner_isolated_sink') and tick==95 then
   if CASE=='owner_isolated_sink' then
     -- Force ownership change is a native topology/authorization negative.
     -- Factorio forbids cross-surface EEI teleport; never bypass the engine.
     local before=st.sink.energy
     st.sink.force=game.forces.enemy
     ck(math.abs(st.sink.energy-before)<.1,'sink lost paid J on force change')
     ck(st.sink.force~=st.loco.force,'EEI force isolation did not take effect')
     logit('ISOLATE','paid native EEI changed force before owner deletion, retained_J='..before)
   end
   st.loco.destroy{raise_destroy=true}
   logit('OWNER_REMOVED','tick=95 immediate owner destruction')
 end
 if CASE=='owner_external_destroy' and tick==95 then
   -- Intentional adversarial loss: the native engine cannot refund a charged
   -- hidden locomotive after an unannounced third-party destroy.
   st.helper.destroy{raise_destroy=false}
   logit('EXTERNAL_DESTRUCTION','paid helper destroyed by unrelated actor before lifecycle accounting')
 end
 if CASE=='owner_split' and tick==95 then
   -- Native decouple leaves owner+helper without its cargo/fluid wagons.
   local success=st.helper.disconnect_rolling_stock(defines.rail_direction.back)
   ck(success,'native split of helper from motor wagons failed')
   logit('SPLIT','tick=95 native split succeeded')
 end
 if (CASE=='owner_delete' or CASE=='owner_split' or CASE=='owner_second' or CASE=='owner_isolated_sink') and tick==96 then
   local stats=ownerMod.stats()
   ck(stats.removed==1,'expected exactly one paid helper to be retired')
   ck(not st.helper.valid,'paid helper remained after automatic owner reconciliation')
   ck(stats.escrow_J>=0 and stats.total_paid_refund_J>=0,'negative paid energy account')
   if CASE=='owner_isolated_sink' then
     local locked=stats.escrow_by_helper[st.helper_unit]
     ck(locked and locked.source_sink==st.sink.unit_number and locked.force=='player'
        and math.abs(locked.J-8333.3333333)<0.1 and not locked.spent,
        'isolated paid Joules lost original helper/source authorization')
   end
   ck(st.cargo.valid and st.fluid.valid,'real wagon destruction by cleanup')
   if st.second then ck(st.second.valid and st.second.train and st.second.train.valid,'second EM destroyed by first owner cleanup') end
   ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'iron lost')
   ck(st.fluid.get_fluid(1) and math.abs(st.fluid.get_fluid(1).amount-9000)<.1,'water lost')
   logit('OWNER_RESULT',string.format('tick96 removed=%d refunded_J=%.3f escrow_J=%.3f cargo=37 fluid=9000',stats.removed,stats.total_paid_refund_J,stats.escrow_J))
   script.finish_test(true)
   return
 end
 if OWNER and tick>=91 then ownerMod.reconcile(tick,'automatic-owned-helper-safety') end
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
   script.finish_test(true)
   return
 end
 if CASE=='paid_offgrid' and tick==90 then
   ck(not st.sink,'offgrid 25kV sink incorrectly created')
   ck(st.helper.burner.remaining_burning_fuel==0,'offgrid helper got free fuel')
   ck((st.loco.burner.remaining_burning_fuel or 0)==0,'offgrid genuine EM loco got free fuel')
   logit('RESULT','status=PASS no 25kV link, no genuine EEI demand, helperJ=0 and locoJ=0')
   script.finish_test(true)
 end
 if CASE=='paid_cut' and tick==95 then
   st.source.power_production=0;st.source.output_flow_limit=0;st.source.energy=0
   logit('FAULT','source primary native electric interface output set 0 at tick95')
 end
 if tick%30==0 then
  local helper_J=st.helper and st.helper.valid and st.helper.burner.remaining_burning_fuel or 0
  logit('TRACE',string.format('tick=%d position_x=%.6f locoJ=%.3f helperJ=%.3f paidJ=%.3f test_sinkJ=%.3f demand_peak=%.3f',
   tick,st.loco.position.x,st.loco.burner.remaining_burning_fuel or 0,helper_J,
   st.paid_J,st.sink and st.sink.valid and st.sink.energy or -1,st.demand_peak))
 end
 if tick==220 then
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
  if OWNER then ck(ownerMod.stats().removed==0,'valid owner got unexpected GC') end
  logit('RESULT',string.format('status=PASS displacement=%.6f helper_paid_J=%.3f helper_reserve_J=%.3f loco_reserve_J=%.3f native_demand_peak=%.3f max_helper_buffer_J=%.3f span=%.6f',
   st.loco.position.x-st.xpos,st.paid_J,st.helper and st.helper.burner.remaining_burning_fuel or 0,
   st.loco.burner.remaining_burning_fuel or 0,st.demand_peak,st.helper_max_J,span))
  script.finish_test(true)
 end
end)