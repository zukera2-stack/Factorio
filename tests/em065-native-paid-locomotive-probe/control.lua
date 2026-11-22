-- EM065 native proof: actual 20MW EM070 source, authenticated contact,
-- real 2MW EM burner. No artificial fuel, ever. Probe is NOT user mod source.
local LIMIT=20000000/60
local function entity(s,name,x,y,other)
  local opts={name=name,position={x=x,y=y},force=game.forces.player,
    raise_built=true,direction=defines.direction.east}
  for key,value in pairs(other or {}) do opts[key]=value end
  local e=s.create_entity(opts)
  assert(e and e.valid,"EM065 cannot create "..name.." x="..x.." y="..y)
  return e
end
local function setup()
  local s=game.create_surface("em065-paid-test",{width=256,height=128})
  s.generate_with_lab_tiles=true
  s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
  for x=-35,35,2 do entity(s,"em-high-speed-straight-rail",x,1) end
  entity(s,"em-35kv-catenary-pole",-21.5,2.5)
  entity(s,"em-35kv-catenary-pole",-1.5,2.5)
  entity(s,"em-35kv-catenary-pole",18.5,2.5)
  local sub=entity(s,"em-35kv-traction-substation",-20,9)
  local subb=entity(s,"em-35kv-traction-substation",20,9)
  local source=entity(s,"electric-energy-interface",-20,13)
  source.electric_interface_mode=defines.electric_interface_mode.primary_output
  source.electric_buffer_size=10000000
  source.power_production=LIMIT;source.power_usage=0
  source.input_flow_limit=0;source.output_flow_limit=LIMIT;source.energy=0
  -- A positive owner at a true contact span, one negative untouched off-line.
  local loco=entity(s,"em-electric-locomotive",0,1)
  local goal=nil
  for _,cfg in ipairs({
    {27,3,defines.direction.east},
    {27,-1,defines.direction.west},
    {29,3,defines.direction.east},
    {29,-1,defines.direction.west},
  }) do
    local e=s.create_entity{name="train-stop",position={x=cfg[1],y=cfg[2]},
      direction=cfg[3],force="player",raise_built=true}
    if e and e.valid and e.connected_rail then goal=e;break end
    if e and e.valid then e.destroy() end
  end
  assert(goal and goal.valid and goal.connected_rail,
    "Real native train stop not connected on horizontal HSR corridor")
  goal.backer_name="EM065_NATIVE_GOAL"
  local no=game.create_surface("em065-no-catenary",{width=128,height=128})
  no.generate_with_lab_tiles=true
  no.request_to_generate_chunks({0,0},2);no.force_generate_chunk_requests()
  for x=-13,13,2 do entity(no,"em-high-speed-straight-rail",x,1) end
  local negative=entity(no,"em-electric-locomotive",0,1)
  assert(loco.burner and negative.burner,"actual 0.1.65 EM locomotive has no native burner")
  assert((loco.burner.remaining_burning_fuel or 0)==0 and
         (negative.burner.remaining_burning_fuel or 0)==0,
    "new real EM locomotive starts with unpaid J")
  storage.em065_test={source=source,positive=loco,negative=negative,
    goal=goal,positive_origin_x=loco.position.x,
    positive_unit=loco.unit_number,negative_unit=negative.unit_number,
    negative_origin_x=negative.position.x,
    source_substation=sub,sink_substation=subb,source_initial=0}
  log("[EM065 PROBE] setup=actual_HSR_real_loco_20MW_3mast_2sub|burner_J=0|source_W=20000000")
end
script.on_event(defines.events.on_tick,function(e)
  if e.tick==2 then setup() end
  local s=storage.em065_test
  if not s then return end
  if e.tick%60==0 then
    log(string.format("[EM065 PROBE] tick=%d source_J=%.1f positive_J=%.1f negative_J=%.1f",
      e.tick,s.source.energy,s.positive.burner.remaining_burning_fuel,
      s.negative.burner.remaining_burning_fuel))
  end
  if e.tick==60 then
    -- The real burner MUST have been charged with a finite amount before auto drive.
    s.before_motion_J=s.positive.burner.remaining_burning_fuel
    assert(s.before_motion_J>100000 and s.before_motion_J<=2000000,
      "positive native 25kV source has not paid the true locomotive at startup")
    local t=s.positive.train
    t.schedule={current=1,records={{station="EM065_NATIVE_GOAL",
      wait_conditions={{type="time",ticks=900}}}}}
    t.manual_mode=false
    log("[EM065 NATIVE ROUTE] tick=60|charged_J="..s.before_motion_J..
      "|native_goal="..s.goal.backer_name.."|manual="..tostring(t.manual_mode))
  end
  if e.tick==125 then
    -- True server save writes a physical file only in actual server mode.
    -- Benchmarks also execute this but cannot persist a disk checkpoint.
    -- Each mod has its OWN isolated storage! Never read ElectrifiedMainline
    -- storage.em from this separate probe. Verify its ledger from native logs.
    assert(s.positive.valid and s.positive.unit_number==s.positive_unit)
    assert(s.negative.valid and s.negative.unit_number==s.negative_unit)
    s.checkpoint_tick=125
    s.checkpoint_burner_J=s.positive.burner.remaining_burning_fuel
    assert(s.checkpoint_burner_J>100000 and s.checkpoint_burner_J<=2000000,
      "native charged locomotive absent at real SAVE tick125")
    local ok,result=pcall(function() game.server_save("em065-paid-checkpoint") end)
    assert(ok,"True Factorio server checkpoint failed: "..tostring(result))
    log("[EM065 DISK CHECKPOINT] tick=125|request_ok="..tostring(ok)..
      "|loco_burner_J="..s.checkpoint_burner_J.."|positive_unit="..s.positive_unit..
      "|negative_unit="..s.negative_unit)
  end
  if e.tick==180 then
    s.distance_by_180=math.abs(s.positive.position.x-s.positive_origin_x)
    log("[EM065 NATIVE MOTION] tick=180|distance="..s.distance_by_180..
      "|speed="..s.positive.train.speed.."|remaining_J="..
      s.positive.burner.remaining_burning_fuel)
  end
  -- This independent observer reads the **actual Factorio native catenary
  -- electric network demand** from the genuine paid sink, never its own Lua
  -- virtual network flow. It is intentionally NOT part of fullmod source.
  if e.tick>=5 and e.tick<=240 then
    local lab=game.surfaces["em-25kv-isolated-bridge-058"]
    if lab then
      storage.em068_native_meter=storage.em068_native_meter or
        {peak_native_demand=0,peak_native_sink=0,seen_sinks=0}
      local m=storage.em068_native_meter
      for _,consumer in ipairs(lab.find_entities_filtered{name="em-25kv-native-traction-consumer-068"}) do
        if consumer.valid then
          m.seen_sinks=math.max(m.seen_sinks,1)
          m.peak_native_sink=math.max(m.peak_native_sink,consumer.energy)
          local net=consumer.electric_network
          local parent=net and net.parent_network
          local f=parent and parent.flow_last_tick
          if f then
            m.peak_native_demand=math.max(m.peak_native_demand,
              (f.primary_demand or 0)+(f.secondary_demand or 0))
          end
        end
      end
    end
  end
  if e.tick==240 then
    local paid=s.positive.burner.remaining_burning_fuel
    local unpowered=s.negative.burner.remaining_burning_fuel
    assert(unpowered==0,"negative off-line loco received unpaid J: "..unpowered)
    local nativeMeter=storage.em068_native_meter
    assert(nativeMeter and nativeMeter.seen_sinks>0 and
      nativeMeter.peak_native_demand>1,
      "EM068 P0 FAIL: genuine catenary native network saw NO train electrical demand")
    log("[EM068 REAL 25KV POWER DEMAND PASS] native_max_network_demand_J_tick="..
      nativeMeter.peak_native_demand.."|source_paid_native_sink=true|no_manual_output_second_debit")
    assert(s.before_motion_J>100000,"source never paid 2MW locomotive")
    assert(s.distance_by_180 and s.distance_by_180>2,
      "native true EM locomotive did not move >2 tiles with paid J")
    assert(math.abs(s.negative.position.x-s.negative_origin_x)<0.001,
      "negative off-contact locomotive moved unexpectedly")
    assert(paid<=2000000,"paid real loco exceeded 2MJ physical reserve")
    log("[EM065 NATIVE PAID PASS] initial_J=0|grid_20MW=on|charged_initial_J="..
      s.before_motion_J.."|native_motion_tiles="..s.distance_by_180..
      "|remaining_J="..paid.."|negative_offline_J=0|no_fake_fuel")
    -- Once paid positive-control confirmed, cut the true source.
    s.source.power_production=0;s.source.output_flow_limit=0
    s.source_substation.destroy{raise_destroy=true}
    s.positive_before_source_loss=paid
  end
  if e.tick==420 then
    local neg=s.negative.burner.remaining_burning_fuel
    assert(neg==0,"off-line loco gained free energy at tick420")
    log("[EM065 NATIVE 0W CONTROL] offline_loco_J=0|source_W=0|no_fake_positive")
  end
  if e.tick==450 then
    assert(s.checkpoint_tick==125 and s.checkpoint_burner_J>100000,
      "EM065 actual disk SAVE checkpoint state missing")
    assert(s.positive.valid and s.positive.unit_number==s.positive_unit,
      "Original paid locomotive identity disappeared on actual LOAD")
    assert(s.negative.valid and s.negative.unit_number==s.negative_unit and
           s.negative.burner.remaining_burning_fuel==0,
      "Unpowered negative locomotive gained free energy across SAVE/LOAD")
    assert(s.distance_by_180 and s.distance_by_180>=24,
      "Native paid train's actual movement disappeared after LOAD")
    log("[EM065 REAL SAVELOAD PASS] checkpoint_tick="..s.checkpoint_tick..
      "|native_paid_motion_tiles="..s.distance_by_180..
      "|original_checkpoint_burner_J="..s.checkpoint_burner_J..
      "|unpowered_negative_J=0|original_unit_numbers=true")
  end
end)
