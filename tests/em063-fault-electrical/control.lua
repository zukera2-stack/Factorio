-- EM063 native FULL mod 20MW electrical fault-injection probe, test-only.
-- No fake joule script transfers: official native solver owns actual EEI Joules.
local RATE=20000000/60
local function check(cond,msg)
  if not cond then error("[EM063 FAULT E FAIL] "..msg,2) end
end
local function say(phase,msg)
  log("[EM063 FAULT E] event="..phase.."|tick="..game.tick.."|"..msg)
end
local function make(s,name,x,y,extra)
  local p={name=name,position={x=x,y=y},force=game.forces.player,
    direction=defines.direction.north,raise_built=true}
  for k,v in pairs(extra or {}) do p[k]=v end
  local e=s.create_entity(p)
  check(e and e.valid,"failed real entity "..name.." at "..x..","..y)
  return e
end
local function eei(s,x,mode)
  local e=make(s,"electric-energy-interface",x,13)
  e.electric_interface_mode=defines.electric_interface_mode[mode]
  e.electric_buffer_size=1000000000
  e.power_usage=0
  e.power_production=mode=="primary_output" and RATE or 0
  e.input_flow_limit=mode=="secondary_input" and RATE or 0
  e.output_flow_limit=mode=="primary_output" and RATE or 0
  e.energy=0
  return e
end
local function get(s)
  check(s.source.valid and s.b.valid and s.c.valid,"native factory source or sink destroyed")
  return s.source.energy,s.b.energy,s.c.energy
end
local function snapshot(s,name)
  local a,b,c=get(s)
  say(name,"generator_J="..a.."|sink_B_J="..b.."|sink_C_J="..c..
    "|source_net="..tostring(s.suba.valid and s.suba.electric_network_id)..
    "|sinkB_net="..tostring(s.subb.electric_network_id)..
    "|sinkC_net="..tostring(s.subc.electric_network_id))
end
local function setup()
  local surface=game.create_surface("em063-fault-power",{width=256,height=128})
  surface.generate_with_lab_tiles=true
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for x=-43,43,2 do make(surface,"em-high-speed-straight-rail",x,1,
    {direction=defines.direction.east}) end
  local poles={}
  for i,x in ipairs({-41.5,-21.5,-1.5,18.5,38.5}) do
    poles[i]=make(surface,"em-35kv-catenary-pole",x,2.5) end
  local s={surface=surface,poles=poles}
  s.suba=make(surface,"em-35kv-traction-substation",-40,9)
  s.subb=make(surface,"em-35kv-traction-substation",0,9)
  s.subc=make(surface,"em-35kv-traction-substation",40,9)
  s.source=eei(surface,-40,"primary_output")
  s.b=eei(surface,0,"secondary_input")
  s.c=eei(surface,40,"secondary_input")
  storage.power_fault=s
  say("setup","HSR=44|catenary_masts=5|traction_substations=3|source_limit_J_tick="..RATE)
end
script.on_event(defines.events.on_tick,function(ev)
  local t=ev.tick
  if t==2 then setup() end
  local s=storage.power_fault
  if not s then return end
  if t==240 then
    snapshot(s,"baseline")
    local a,b,c=get(s)
    check(s.suba.electric_network_id~=s.subb.electric_network_id and
          s.suba.electric_network_id~=s.subc.electric_network_id and
          s.subb.electric_network_id~=s.subc.electric_network_id,
      "factory networks merged; 25kV isolation violated")
    check(b>5000000 and c>5000000,"20MW source didn't feed both real consumers")
    check(math.abs(b-c)<4000000,"20MW fairness broke")
    check(b+c<95000000,"unpaid energy beyond capped source")
    s.before_c=c
    s.b.input_flow_limit=0
    say("consumer_outage","B_input=0|sink_C_previous="..c)
  end
  if t==480 then
    local a,b,c=get(s)
    check(c-s.before_c>40000000,"remaining C did not receive redirected source power")
    check(c-s.before_c<85000000,"C gained more than 20MW window budget")
    snapshot(s,"after_consumer_outage")
  end
  if t==500 then
    local ok,res=pcall(function() game.server_save("em063-fault-electrical-checkpoint") end)
    check(ok,"real disk checkpoint failed: "..tostring(res))
    say("disk_checkpoint","name=em063-fault-electrical-checkpoint|ok=true")
  end
  if t==600 then
    snapshot(s,"before_source_loss")
    s.before_stop_c=s.c.energy
    s.suba.destroy{raise_destroy=true}
    check(not s.suba.valid,"source substation demolition did not occur")
    say("demolish_source_substation","source_net_before_destroyed=true|sinkC_J="..s.before_stop_c)
  end
  if t==750 then
    snapshot(s,"source_isolated")
    check(s.c.energy<s.before_stop_c+6000000,
      "continued phantom delivery after ONLY source substation destroyed")
    s.suba=make(s.surface,"em-35kv-traction-substation",-40,9)
    s.before_rebuild_c=s.c.energy
    say("rebuild_source_substation","sinkC_J_before="..s.before_rebuild_c)
  end
  if t==930 then
    snapshot(s,"source_restored")
    check(s.c.energy>s.before_rebuild_c+5000000,
      "real 25kV power didn't resume after owner rebuilt")
    s.before_cut_c=s.c.energy
    s.poles[2].destroy{raise_destroy=true}
    s.poles[3].destroy{raise_destroy=true}
    say("double_mast_break","removed=2|gap=60|sinkC_before="..s.before_cut_c)
  end
  if t==1100 then
    snapshot(s,"line_split")
    check(s.c.energy<s.before_cut_c+6000000,
      "25kV consumer kept receiving power through broken two-mast corridor")
    s.source.power_production=0
    s.source.output_flow_limit=0
    s.before_off_c=s.c.energy
    say("stop_factory_generator","sinkC_before="..s.before_off_c)
  end
  if t==1210 then
    snapshot(s,"zero_source_final")
    check(s.c.energy<s.before_off_c+5000000,
      "unbounded consumer energy generation with generator fully OFF")
    log("[EM063 POWER FAULT PASS] fullmod 20MW delivery/reallocation, source loss/recovery, catenary break, 0W and disk reload checks")
  end
end)
