-- EM062 actual Factorio native electric-network fairness/incremental-demand test.
-- No custom script moves joules. Factorio owns all energy changes.
local RATE=20000000/60
local f={}
local function make(s,name,x,y,extra)
  local options={name=name,position={x,y},force='player',raise_built=true}
  for k,v in pairs(extra or {}) do options[k]=v end
  local e=s.create_entity(options)
  assert(e and e.valid,'unable to create '..name..' at '..x..','..y)
  return e
end
local function eei(s,x,mode)
  local e=make(s,'electric-energy-interface',x,13)
  e.electric_interface_mode=defines.electric_interface_mode[mode]
  e.electric_buffer_size=1000000000
  e.power_usage=0
  e.power_production=mode=='primary_output' and RATE or 0
  e.input_flow_limit=mode=='secondary_input' and RATE or 0
  e.output_flow_limit=mode=='primary_output' and RATE or 0
  e.energy=0
  return e
end
local function start()
  local s=game.create_surface('em062-fairness',{width=256,height=128})
  s.generate_with_lab_tiles=true
  s.request_to_generate_chunks({0,0},3);s.force_generate_chunk_requests()
  for x=-43,43,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
  for _,x in ipairs({-41.5,-21.5,-1.5,18.5,38.5}) do make(s,'em-35kv-catenary-pole',x,2.5) end
  f.a=make(s,'em-35kv-traction-substation',-40,9)
  f.b=make(s,'em-35kv-traction-substation',0,9)
  f.c=make(s,'em-35kv-traction-substation',40,9)
  f.source=eei(s,-40,'primary_output')
  f.sinkB=eei(s,0,'secondary_input')
  f.sinkC=eei(s,40,'secondary_input')
  log('[EM062] setup: single 20MW source + two independent 20MW sinks via shared 25kV corridor')
end
local function line(t)
  log(string.format('[EM062] dt=%d sinkB=%.0fJ sinkC=%.0fJ source=%.0fJ factoryNets=%s,%s,%s',t,
      f.sinkB.energy,f.sinkC.energy,f.source.energy,
      tostring(f.a.electric_network_id),tostring(f.b.electric_network_id),tostring(f.c.electric_network_id)))
end
script.on_event(defines.events.on_tick,function(event)
  if not storage.started then storage.started=event.tick;start() end
  local dt=event.tick-storage.started
  if dt==100 or dt==240 or dt==420 or dt==600 then line(dt) end
  if dt==240 then
    assert(f.a.electric_network_id~=f.b.electric_network_id and f.a.electric_network_id~=f.c.electric_network_id and f.b.electric_network_id~=f.c.electric_network_id,'factory networks not isolated')
    local b,c=f.sinkB.energy,f.sinkC.energy
    assert(b>5000000 and c>5000000, 'both sinks must receive power; starvation detected')
    assert(math.abs(b-c)<4000000,'equal-demand fairness violated: allocation skew >4MJ')
    assert(b+c<95000000,'power created above 20MW source budget')
    storage.beforeC=c
    -- Stop B demand to verify all available power shifts to still-hungry C.
    f.sinkB.input_flow_limit=0
    log('[EM062] B closed; remaining demand C should receive 20MW')
  end
  if dt==600 then
    local c_gain=f.sinkC.energy-storage.beforeC
    assert(c_gain>65000000,'remaining C did not receive redirected 20MW')
    assert(c_gain<125000000,'C received more than possible 20MW over this window')
    log('[EM062 NATIVE PASS] 3 isolated factory nets share 20MW fairly; sink loss reroutes full budget; no extra generation')
  end
end)