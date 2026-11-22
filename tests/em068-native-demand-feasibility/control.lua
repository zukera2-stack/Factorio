-- Actual Factorio 2.1.24 prototype-same-type isolated NATIVE demand lab.
-- Runs the complete, unchanged, original 0.1.67 ElectrifiedMainline and the
-- independent 1MW/2-real-EM-loco native observer in two disposable probe mods.
-- No game mod source changes, no artificial buffer/locomotive energy writes.
local NAME="em068-native-line-consumer-test"
local observed={peak=0,peakenergy=0,matched=false,samples=0,seed=0}
local function get(id)
  local e=id and game.get_entity_by_unit_number(id)
  return e and e.valid and e or nil
end
local function setup()
  local surface=game.surfaces["em065-audit-shared-1mw"]
  assert(surface and surface.valid,"Need actual other native fullmod audit train fixture")
  local line=surface.find_entities_filtered{name="em-35kv-catenary-pole"}
  assert(#line>2,"Native fullmod authentic masts not built")
  local actual=line[2].electric_network_id
  assert(actual,"Authentic catenary mast native network ID absent")
  local lab=game.surfaces["em-25kv-isolated-bridge-058"]
  assert(lab and lab.valid,"Real complete EM070 isolated bridge ports not created")
  local ports=lab.find_entities_filtered{name="em-25kv-bridge-port-058"}
  assert(#ports>=2,"Real source bridge ports not yet native")
  local matching={}
  for _,p in ipairs(ports) do
    if p.valid and p.electric_network_id==actual then matching[#matching+1]=p end
  end
  assert(#matching>0,"No native EM070 bridge output port belongs to authenticated catenary network "..actual)
  table.sort(matching,function(a,b)return a.unit_number<b.unit_number end)
  local port=matching[1]
  local sink=lab.create_entity{name=NAME,position=port.position,force=port.force,raise_built=false}
  assert(sink and sink.valid,"Could not place native test EEI on real source catenary bridge port")
  sink.electric_interface_mode=defines.electric_interface_mode.secondary_input
  sink.electric_buffer_size=100000
  sink.input_flow_limit=2000000/60
  sink.output_flow_limit=0
  sink.power_usage=0
  sink.power_production=0
  sink.energy=0
  -- Negative: same prototype, separate isolated surface no factory source.
  local no=game.surfaces["em065-audit-offgrid-AUTO"]
  assert(no and no.valid,"Second no-contact surface absent")
  local isolated=no.create_entity{name=NAME,position={x=20,y=19},force="player",raise_built=false}
  assert(isolated and isolated.valid,"Cannot create native offgrid EEI control")
  isolated.electric_interface_mode=defines.electric_interface_mode.secondary_input
  isolated.input_flow_limit=2000000/60
  isolated.output_flow_limit=0
  isolated.power_usage=0
  isolated.power_production=0
  isolated.energy=0
  storage.em068={sink=sink,negative=isolated,mast=line[2],port=port,
    started=game.tick,network=actual,peak_demand=0,peak_burner=0,
    peak_buffer=0,ticks_demand_positive=0,ticks_sampled=0}
  log(string.format("[EM068 NATIVE EEI FIXTURE] tick=%d mast_net=%s bridge_port_net=%s sink_net=%s line_native=%s buffer=100000J max_input_J_tick=33333.333 offgrid_net=%s",
    game.tick,tostring(actual),tostring(port.electric_network_id),
    tostring(sink.electric_network_id),
    tostring(sink.electric_network_id==actual),
    tostring(isolated.electric_network_id)))
end
script.on_event(defines.events.on_tick,function(event)
  local tick=event.tick
  if tick==40 then setup() end
  local s=storage.em068
  if not s then return end
  assert(s.sink.valid and s.negative.valid and s.port.valid and s.mast.valid,
    "Actual true EEI and mast must survive until test boundary")
  if tick>=41 then
    local net=s.mast.electric_network
    local p=net and net.parent_network
    local f=p and p.flow_last_tick
    local demand=f and ((f.primary_demand or 0)+(f.secondary_demand or 0)) or 0
    s.ticks_sampled=s.ticks_sampled+1
    if demand>1 then s.ticks_demand_positive=s.ticks_demand_positive+1 end
    s.peak_demand=math.max(s.peak_demand,demand)
    s.peak_buffer=math.max(s.peak_buffer,s.sink.energy)
    if tick==41 or tick==45 or tick==50 or tick==60 or tick==80 or tick==100 then
      log(string.format("[EM068 NATIVE ELECTRIC FLOW] tick=%d mast_net=%s port_net=%s sink_net=%s native_primary_demand=%.3f native_secondary_demand=%.3f genuine_sink_buffer_J=%.3f peak_demand=%.3f offgrid_J=%.3f",
        tick,tostring(s.mast.electric_network_id),
        tostring(s.port.electric_network_id),
        tostring(s.sink.electric_network_id),
        f and f.primary_demand or -1,f and f.secondary_demand or -1,
        s.sink.energy,s.peak_demand,s.negative.energy))
    end
  end
  if tick==100 then
    assert(s.sink.electric_network_id==s.network,"Test EEI left native 25kV network")
    assert(s.negative.energy==0,"Offgrid native negative got unpaid energy")
    assert(s.peak_buffer>1000,
      "NATIVE DEMAND FEASIBILITY FAIL: real 25kV network did not fill live native consumer buffer")
    assert(s.ticks_demand_positive>0,
      "NATIVE DEMAND FEASIBILITY FAIL: true 25kV network recorded ZERO native electric demand while consumer charged")
    log(string.format("[EM068 NATIVE CONSUMER FEASIBILITY PASS] native_mast_net=%s buffer_max_J=%.3f native_demand_max_J_tick=%.3f positive_ticks=%d offgrid_native_sink_J=0 integration_source_pay_not_yet_tested",
      tostring(s.network),s.peak_buffer,s.peak_demand,s.ticks_demand_positive))
  end
end)
