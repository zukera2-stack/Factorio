-- Native QA: ONLY full ElectrifiedMainline 0.1.71 creates/mounts/pays helpers.
-- This scenario builds REAL stock/HSR/masts/substations/grid. It NEVER creates
-- em-c5-technical-booster-* or EEI native traction sinks, NEVER credits burners,
-- NEVER sets LuaTrain.speed. This is intentionally stronger than the old probes.
local CASE=script.test_arg or 'single'
local BIG={standalone200=200,long200highopp=200,long200highopp_rev=200,long200highopp_revpassive=200,long200highsame=200,long200highsamepassive=200,long200highpassive=200,long64=64,long64dual=64,long64passive=64,long64pushpull=64,long128=128,long128dual=128,long128passive=128,long200=200,long200high=200,long200highdual=200,long200high20=200,long200highzero=200,long200highoffgrid=200,long200highpassive=200,long200dual=200,long200passive=200,long256=256}
local N=BIG[CASE] or 2
local OPPOSITE=(CASE=='double_opposite' or CASE=='long64pushpull' or CASE=='long200highopp' or CASE=='long200highopp_rev' or CASE=='long200highopp_revpassive' or CASE=='bidir_auto' or CASE=='bidir_reverse' or CASE=='bidir_reversepassive' or CASE=='bidir_zero' or CASE=='bidir_offgrid' or CASE=='bidir_ownerloss')
local DOUBLE=OPPOSITE or CASE=='double_same' or CASE=='long200highsame' or CASE=='long200highsamepassive' or CASE:find('dual$')~=nil
local LOCOLESS=(CASE=='standalone200')
local EXPECT=(LOCOLESS and 0 or ((OPPOSITE and 2) or 1))
local GRID=(CASE~='zero' and CASE~='offgrid' and CASE~='bidir_zero' and CASE~='bidir_offgrid' and not CASE:find('highzero$') and not CASE:find('highoffgrid$'))
-- 'high' is 120 MW FACTORY over-generation against a 20 MW substation, not a 120 MW station.
local SUPPLY_W=(CASE=='brownout' and 1000000 or CASE=='zero' and 0 or CASE=='bidir_zero' and 0 or CASE:find('highzero$') and 0 or CASE:find('high20$') and 20000000 or CASE:find('high') and 120000000 or 20000000)
local MOTOR=(CASE~='nonmotor' and CASE:find('passive$')==nil)
local REAL=(CASE~='vanilla' and not LOCOLESS)
local function say(k,t)log('[EM073 BIDIR QA] '..CASE..'|'..k..'|'..t)end
local function ck(b,m)if not b then error('[EM073 BIDIR QA FAIL] '..CASE..' '..m)end end
local function spawn(s,name,x,y,direction)
 local e=s.create_entity{name=name,position={x=x,y=y},force='player',
  direction=direction or defines.direction.east,raise_built=true}
 ck(e and e.valid,'cannot create '..name..' at '..x..','..y)
 return e
end
local function helper(train)
 local hs={}
 for _,e in ipairs(train.carriages)do
  if e.valid and e.name:find('^em%-c5%-technical%-booster%-') then hs[#hs+1]=e end
 end
 return hs
end
local function setup()
 local s=game.create_surface('em072-native-'..CASE,{width=6000,height=256})
 s.generate_with_lab_tiles=true
 s.always_day=true
 local xmax=math.max(400,7*(N+(DOUBLE and 2 or 1))+220)
 local xmin=BIG[CASE] and -2400 or -350
 for x=xmin,xmax,128 do s.request_to_generate_chunks({x=x,y=0},2) end
 s.force_generate_chunk_requests()
 for x=xmin,xmax,2 do spawn(s,'em-high-speed-straight-rail',x,1,defines.direction.east)end
 if CASE~='offgrid' and CASE~='bidir_offgrid' and not CASE:find('highoffgrid$') then
  for x=xmin+18.5,xmax-2,20 do
   spawn(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east)
  end
 end
 spawn(s,'em-35kv-traction-substation',-20,9,defines.direction.east)
 spawn(s,'em-35kv-traction-substation',20,9,defines.direction.east)
 local source=spawn(s,'electric-energy-interface',-20,13,defines.direction.east)
 source.electric_interface_mode=defines.electric_interface_mode.primary_output
 source.electric_buffer_size=10000000
 source.power_production=SUPPLY_W/60
 source.power_usage=0
 source.output_flow_limit=SUPPLY_W/60
 source.input_flow_limit=0
 source.energy=0
 local stop=nil
 local stop2=nil
 if CASE=='auto' or CASE=='bidir_auto' then
  for _,dy in ipairs({-2,2,0}) do
   for _,direction in ipairs({defines.direction.west,defines.direction.east}) do
    local candidate=s.create_entity{name='train-stop',position={x=-160,y=1+dy},
      force='player',direction=direction,raise_built=true}
    if candidate and candidate.valid and candidate.connected_rail then
      stop=candidate
      break
    end
    if candidate and candidate.valid then candidate.destroy() end
   end
   if stop then break end
  end
  ck(stop,'real train stop could not connect to actual HSR rail')
  stop.backer_name='EM072_NATIVE_AUTO_TARGET'
  if CASE=='bidir_auto' then
    for _,dy in ipairs({2,-2,0}) do
      for _,direction in ipairs({defines.direction.east,defines.direction.west}) do
        local candidate=s.create_entity{name='train-stop',position={x=180,y=1+dy},
          force='player',direction=direction,raise_built=true}
        if candidate and candidate.valid and candidate.connected_rail then
          stop2=candidate
          break
        end
        if candidate and candidate.valid then candidate.destroy() end
      end
      if stop2 then break end
    end
    ck(stop2,'second opposite-direction real HSR stop could not attach')
    stop2.backer_name='EM073_NATIVE_RETURN_TARGET'
    say('STOPS',string.format('left=%.3f,%0.3f dir=%d right=%.3f,%0.3f dir=%d',
      stop.position.x,stop.position.y,stop.direction,stop2.position.x,stop2.position.y,stop2.direction))
  end
 end
 local loco=spawn(s,(REAL or LOCOLESS) and 'em-electric-locomotive' or 'locomotive',0,1,defines.direction.west)
 local second
 local offset=(DOUBLE and not OPPOSITE) and 7 or 0
 if DOUBLE and not OPPOSITE then
  second=spawn(s,'em-electric-locomotive',7,1,defines.direction.west)
 end
 local stock={}
 for i=1,N do
  local kind=not MOTOR and (i%2==1 and 'cargo-wagon' or 'fluid-wagon')
   or (i%2==1 and 'em-motor-cargo-wagon' or 'em-motor-fluid-wagon')
  stock[i]=spawn(s,kind,offset+i*7,1,defines.direction.west)
  if LOCOLESS and i>1 then
    local prev=stock[i-1]
    if not prev.train or not stock[i].train or prev.train.id~=stock[i].train.id then
      local joined=prev.connect_rolling_stock(defines.rail_direction.front)
      if not joined then joined=stock[i].connect_rolling_stock(defines.rail_direction.back) end
      if not joined then
        say('CONNECT',string.format('wagon=%d previous_id=%s current_id=%s',i,tostring(prev.train and prev.train.id),tostring(stock[i].train and stock[i].train.id)))
      end
    end
  end
 end
 if OPPOSITE then
  second=spawn(s,'em-electric-locomotive',(N+1)*7,1,defines.direction.east)
 end
 local cargo=stock[1]
 local fluid=stock[2]
 ck(cargo.type=='cargo-wagon' and fluid.type=='fluid-wagon','native wagon mechanics not preserved')
 local metal=cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}
 local water=fluid.insert_fluid{name='water',amount=9000}
 ck(metal==37 and water==9000,'cargo/fluid payload initialization failed')
 if LOCOLESS then
   local seed=loco
   loco=stock[1]
   seed.destroy{raise_destroy=true}
 end
 local all=loco.train
 ck(all and all.valid,'native train missing')
 local expect=N+(LOCOLESS and 0 or 1)+(DOUBLE and 1 or 0)
 ck(#all.carriages==expect,'native initial cars '..#all.carriages..' expected='..expect)
 storage.qa={s=s,source=source,loco=loco,second=second,stock=stock,
  start_x=loco.position.x,expected=expect,original_cargo_unit=cargo.unit_number,
  stop2=stop2,visited={}, saw_forward=false,saw_reverse=false,
  used_west_native=false,used_east_native=false,
  original_fluid_unit=fluid.unit_number,helper_unit=0,first_paid=0,stop=stop}
 say('START',string.format('stock=%d motors=%d real_EM=%d source_W=%d cargo=37 fluid=9000',
  expect,N,REAL and 1+(DOUBLE and 1 or 0) or 0,SUPPLY_W))
end
local function info(tick)
 local st=storage.qa;local loco=st.loco
 local train=loco.valid and loco.train
 local hs=train and train.valid and helper(train) or {}
 local engines=0
 if train and train.valid then
  for _,e in ipairs(train.carriages)do if e.name=='em-electric-locomotive' then engines=engines+1 end end
 end
 local diag=remote.call('em072_native_qa_071','snapshot',#hs==1 and hs[1].unit_number or nil)
 local state={created=diag.created,orphan_helpers_removed=diag.removed,removed_loss_J=diag.lost_J}
 local paid={debited_J=diag.paid_J,motor_paid_J=diag.motor_paid_J}
 local h=#hs==1 and hs[1] or nil
 local function j(e)return e and e.valid and e.burner and (e.burner.remaining_burning_fuel or 0) or 0 end
 local weight=train and train.weight or 0
 local payload=st.stock[1].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')
 local water=st.stock[2].get_fluid(1)
 local water_n=water and water.amount or 0
 say('SNAP',string.format('tick=%d cars=%d helpers=%d helper_w=%d helper_J=%.3f loco_J=%.3f paid_J=%.3f motor_paid_J=%.3f distance=%.3f speed=%.5f created=%d retired=%d lost_J=%.3f cargo=%d water=%.0f EM=%d weight=%.1f',
 tick,train and #train.carriages or -1,#hs,h and tonumber(h.name:match('(%d+)$'))*1000 or 0,j(h),j(loco),paid.debited_J or 0,paid.motor_paid_J or 0,
 loco.position.x-st.start_x,train and train.speed or 0,state.created or 0,
 state.orphan_helpers_removed or 0,state.removed_loss_J or 0,payload,water_n,engines,weight))
 say('ORIENT',string.format('tick=%d real_orientation=%.4f real_direction=%d helper_orientation=%.4f helper_direction=%d',tick,loco.valid and loco.orientation or -1,loco.valid and loco.direction or -1,h and h.orientation or -1,h and h.direction or -1))
 if OPPOSITE and #hs==2 then
   say('BURNERS',string.format('tick=%d helper1_o=%.3f J=%.3f helper2_o=%.3f J=%.3f',tick,hs[1].orientation,j(hs[1]),hs[2].orientation,j(hs[2])))
 end
 return hs,state,paid,payload,water_n
end
script.on_event(defines.events.on_tick,function(e)
 local tick=e.tick
 if tick==2 then setup() end
 local st=storage.qa
 if not st then return end
 if tick==70 then
  local hs,s,paid,payload,water=info(tick)
  if REAL and MOTOR then
   ck(#hs==EXPECT,'real controller failed expected directed booster count '..EXPECT..' actual '..#hs)
   for _,h in ipairs(hs) do ck(tonumber(h.name:match('(%d+)$'))==N*500,'wrong exact +500kW*motors booster') end
   local who=remote.call('em072_native_qa_071','snapshot',hs[1].unit_number).owner
   ck(who==st.loco.unit_number or (st.second and who==st.second.unit_number),
     'booster has no real EM owner mapping')
   ck(#st.loco.train.carriages==st.expected+EXPECT,'real extra helper count wrong')
   st.helper_unit=hs[1].unit_number
   if OPPOSITE then
      ck(#hs==2,'missing native backward-facing aggregate')
      local owners={}
      for _,h in ipairs(hs) do
        local owner=remote.call('em072_native_qa_071','snapshot',h.unit_number).owner
        ck(owner==st.loco.unit_number or owner==st.second.unit_number,'missing real opposite owner')
        ck(not owners[owner],'duplicate owner in opposing aggregates')
        owners[owner]=true
        say('BOOSTER',string.format('owner=%d helper=%d orientation=%.3f burner=%.3f',owner,h.unit_number,h.orientation,h.burner.remaining_burning_fuel or 0))
      end
      ck(owners[st.loco.unit_number] and owners[st.second.unit_number], 'opposing head missing motor')
      ck(math.abs((st.loco.orientation-st.second.orientation+1)%1-0.5)<0.01,'real EM heads not opposite')
   end
  else ck(#hs==0,'should not auto-spawn motor without owner/motor wagons') end
  ck(payload==37 and math.abs(water-9000)<0.01,'payload lost at auto-mount')
 end
 if (CASE=='auto' or CASE=='bidir_auto') and tick==80 then
  local train=st.loco.train
  local records={{station='EM072_NATIVE_AUTO_TARGET',wait_conditions={{type='time',compare_type='and',ticks=CASE=='bidir_auto' and 60 or 700}}}}
  if CASE=='bidir_auto' then
    records[#records+1]={station='EM073_NATIVE_RETURN_TARGET',wait_conditions={{type='time',compare_type='and',ticks=60}}}
  end
  train.schedule={current=1,records=records}
  train.manual_mode=false
  say('AUTO_ROUTE','schedule enabled with native HSR stop; departure and wait are Factorio engine controlled')
 end
 if tick==100 then
  local hs,s,paid=info(tick)
  if REAL and MOTOR and GRID then
   ck(#hs==EXPECT,'no correct directional helpers under grid')
   ck((paid.motor_paid_J or 0)>0,'no paid real helper Joules from authentic 25kV source')
   ck((paid.debited_J or 0)>=(paid.motor_paid_J or 0),'helper minted energy outside sink ledger')
  elseif REAL and MOTOR then
   ck((paid.motor_paid_J or 0)<0.01,'free motor energy without power/contact')
  end
  if CASE=='auto' or CASE=='bidir_auto' then local tr=st.loco.train; say('PATH', 'tick=100 state='..tostring(tr.state)..' manual='..tostring(tr.manual_mode)..' stop='..tostring(tr.station and tr.station.backer_name)..' target='..tostring(tr.path_end_stop and tr.path_end_stop.backer_name)) end
  if CASE=='brownout' then
   ck((paid.motor_paid_J or 0)>0 and (paid.debited_J or 0)>(paid.motor_paid_J or 0),
     '1MW scarcity starved loco or motor')
   ck((paid.debited_J or 0) <= SUPPLY_W*100/60+150000,
     'source paid bridge exceeds limited factory input')
  end
 end
 if (CASE=='loss' or CASE=='split') and tick==110 then
  local hs=helper(st.loco.train)
  ck(#hs==1,'expected paid motor helper before deletion')
  ck((hs[1].burner.remaining_burning_fuel or 0)>0,'missing positive-J native booster before demolition')
  local pre=hs[1].burner.remaining_burning_fuel
  if CASE=='loss' then st.loco.destroy{raise_destroy=true}
  else
   ck(hs[1].disconnect_rolling_stock(defines.rail_direction.back),'native split operation rejected')
  end
  st.expected_loss=pre
  say('DEMOLISH',string.format('tick=%d anticipated_native_J_loss=%.3f',tick,pre))
 end
 if (CASE=='loss' or CASE=='split') and tick==115 then
  local diag=remote.call('em072_native_qa_071','snapshot')
  local s={orphan_helpers_removed=diag.removed,removed_loss_J=diag.lost_J}
  ck(s.orphan_helpers_removed>=1,'charged helper remained after real removal')
  ck(math.abs(s.removed_loss_J-st.expected_loss)<0.1,
    'nonconservative loss log expected='..st.expected_loss..' actual='..s.removed_loss_J)
  ck(not game.get_entity_by_unit_number(st.helper_unit),'hidden motor orphan survived')
  ck(st.stock[1].valid and st.stock[2].valid,'native cargo/fluid destroyed with helper')
  say('LOSS_PASS',string.format('dissipated_paid_J=%.3f native_orphan=0',s.removed_loss_J))
 end
 if CASE=='split' and tick==140 then
  ck(st.loco.valid,'real owner unexpectedly dead')
  local ok=st.loco.connect_rolling_stock(defines.rail_direction.back)
  ck(ok,'native re-couple did not succeed')
  say('RECOUPLED','visible stock reconnected')
 end
 if CASE=='split' and tick==155 then
  local hs=helper(st.loco.train)
  ck(#hs==1 and hs[1].unit_number~=st.helper_unit,'new paid helper not remounted after re-couple')
  ck(remote.call('em072_native_qa_071','snapshot',hs[1].unit_number).owner==st.loco.unit_number,'remounted helper not owned')
  say('REMOUNT_PASS','one fresh helper source-paid, old hidden J never returned')
 end
 if CASE=='bidir_ownerloss' and tick==110 then
    local old=st.loco
    ck(st.second and st.second.valid,'missing second real locomotive before owner removal')
    local hs=helper(old.train)
    ck(#hs==2,'owner-loss precondition missing two helpers')
    old.destroy{raise_destroy=true}
    st.loco=st.second
    st.start_x=st.loco.position.x
    say('HEAD_REMOVED','real first EM destroyed, native helper must retire as a loss')
 end
 if CASE=='bidir_ownerloss' and tick==115 then
    local hs=helper(st.loco.train)
    ck(#hs==1,'remaining genuine EM must keep exactly its helper')
    ck(remote.call('em072_native_qa_071','snapshot',hs[1].unit_number).owner==st.loco.unit_number,
       'wrong surviving genuine owner')
    ck(hs[1].orientation==st.loco.orientation,'remaining helper heading lost')
    local diag=remote.call('em072_native_qa_071','snapshot')
    ck((diag.lost_J or 0)>0,'destroyed engine paid J was not dissipated')
    ck(st.stock[1].valid and st.stock[2].valid,'cargo/fluid damaged by owner removal')
    say('OWNER_RETIRED',string.format('remaining_helper=%d paid_J_lost=%.3f',hs[1].unit_number,diag.lost_J))
 end
 if tick==130 and not LOCOLESS and CASE~='bidir_ownerloss' and CASE~='loss' and CASE~='split' and CASE~='nonmotor' and CASE~='vanilla' and CASE~='auto' and CASE~='bidir_auto' then
  local driver=spawn(st.s,'character',st.loco.position.x,st.loco.position.y)
  st.loco.set_driver(driver)
  driver.riding_state={acceleration=(CASE:find('_rev') and defines.riding.acceleration.reversing or defines.riding.acceleration.accelerating),
    direction=defines.riding.direction.straight}
  say('DEPART','actual native driver and train, no LuaTrain.speed writes')
 end
 if CASE=='bidir_auto' and tick>=85 then
    local tr=st.loco.train
    if tr and tr.valid then
      if tr.speed>0.02 then st.saw_forward=true end
      if tr.speed< -0.02 then st.saw_reverse=true end
      if math.abs(tr.speed)>0.03 then
        for _,h in ipairs(helper(tr)) do
          local hj=h.burner and (h.burner.remaining_burning_fuel or 0) or 0
          local cap=N*500000/60
          if hj<cap*0.5 then
            if math.abs(h.orientation-st.loco.orientation)<0.01 then
              st.used_west_native=true
            end
            if math.abs(h.orientation-st.second.orientation)<0.01 then
              st.used_east_native=true
            end
          end
        end
      end
      local station=tr.station and tr.station.valid and tr.station.backer_name
      if station and not st.visited[station] then
        st.visited[station]=true
        say('ARRIVED',string.format('tick=%d station=%s x=%.3f train_speed=%.3f manual=%s',tick,station,st.loco.position.x,tr.speed,tostring(tr.manual_mode)))
      end
    end
 end
 if CASE=='bidir_auto' and tick==1700 then
    local tr=st.loco.train
    local hs=helper(tr)
    local diag=remote.call('em072_native_qa_071','snapshot')
    ck(tr.valid and not tr.manual_mode,'native AUTO lost after both direction mounts')
    ck(st.visited.EM072_NATIVE_AUTO_TARGET and st.visited.EM073_NATIVE_RETURN_TARGET,
      'did not physically visit both real train stops in AUTO')
    ck(st.saw_forward and st.saw_reverse,'AUTO never traveled in BOTH native speed signs')
    ck(st.used_west_native and st.used_east_native,
      'both real AUTO directions did not burn native correctly oriented helper fuel')
    ck(#hs==2 and (diag.motor_paid_J or 0)>0,'native double-headed motor power not retained')
    say('PASS',string.format('real two-stop AUTO bidirectional engine route; two native directions; paid_J=%.3f',diag.motor_paid_J or 0))
 end
 if CASE=='auto' and tick==500 then
  local tr=st.loco.train
  ck(tr and tr.valid and not tr.manual_mode,'AUTO switched to MANUAL after native helper insertion')
  ck(tr.schedule and tr.schedule.records[1].station=='EM072_NATIVE_AUTO_TARGET','AUTO schedule lost')
  ck(tr.station and tr.station.valid and tr.station.backer_name=='EM072_NATIVE_AUTO_TARGET','did not reach physical HSR train stop')
  say('PASS','native AUTO schedule and physical HSR train stop accepted with source-paid motor traction')
 end
 if BIG[CASE] and tick==1200 then
  local hs,s,paid,payload,water=info(tick)
  ck(payload==37 and math.abs(water-9000)<0.01,'1200-tick extreme consist cargo damage')
  if REAL and MOTOR then
    ck(#hs==1 and tonumber(hs[1].name:match('(%d+)$'))==N*500,'extreme train lost aggregate power prototype')
    ck((paid.motor_paid_J or 0)>0,'extreme train no genuine J')
    ck(math.abs(st.loco.position.x-st.start_x)>0.01,'extreme train failed to move over 1200 ticks')
  else ck(#hs==0,'passive 1200-tick train had hidden booster') end
  say('PASS','long native 1200-tick motorized stress complete; compare measured distance to passive control')
 end
 if tick==300 then
  if CASE=='loss' then
    ck(st.stock[1].valid and st.stock[2].valid,'cargo/fluid missing after owner demolition')
    ck(not game.get_entity_by_unit_number(st.helper_unit),'orphan after owner removal')
    say('PASS','owner demolition yields native loss and leaves native cargo')
    return
  end
  local hs,s,paid,payload,water=info(tick)
  ck(payload==37 and math.abs(water-9000)<0.01,'cargo/fluid lost during native 300-tick test')
  if CASE=='bidir_ownerloss' then
    ck(#hs==1 and (s.removed_loss_J or 0)>0,'owner-loss left wrong helper count/paid loss')
    say('PASS','owner destroyed, its charged booster retired and other head retained')
    return
  end
  if CASE=='loss' then ck(not st.loco.valid,'owner not deleted')
  elseif CASE=='split' then ck(#hs==1,'new helper missing after split+rejoin')
  elseif REAL and MOTOR then
   ck(#hs==EXPECT,'wrong helper count on 300-tick consistency audit')
   ck(tonumber(hs[1].name:match('(%d+)$'))==N*500,'wrong long train traction nameplate')
   if GRID then
    ck((paid.motor_paid_J or 0)>0,'no paid wagon motor J')
    ck(math.abs(st.loco.position.x-st.start_x)>(BIG[CASE] and 0.001 or 0.5),'full native powered train did not move')
   else
    ck(math.abs(st.loco.position.x-st.start_x)<0.5,'train moved for free with no authentic grid')
   end
  else
    ck(#hs==0,'non-em or nonmotor train generated helper')
    if LOCOLESS then ck(math.abs(st.loco.position.x-st.start_x)<0.001,'200 wagons without EM started moving') end
  end
  if CASE=='long200high' then
     ck(SUPPLY_W==120000000,'overload fixture must generate 120 MW on factory side')
     ck((paid.motor_paid_J or 0)<105000000,'one 20MW feeder illegally paid motor energy at 120MW rating')
     ck(math.abs(st.loco.position.x-st.start_x)>0.001,'200 motor wagons should move within a 20MW supply budget')
   elseif CASE=='long200high20' then
     ck(SUPPLY_W==20000000 and (paid.motor_paid_J or 0)<70000000,
       '20MW original source must still limit paid motor Joules')
   end
   if (not BIG[CASE] or N>=200) and CASE~='auto' and CASE~='bidir_auto' then say('PASS','real integrated full-mod native scenario; long200/256 limited to first 300 ticks') end
 end
end)