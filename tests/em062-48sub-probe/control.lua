-- Native 2.1.24 stress: thirty-two separate factory substations on one 25 kV corridor.
-- Real engine owns electricity; the fixture *only* configures test loads, sources and asserts energy.
local RATE=20000000/60
local RATE_END=20000000/60
local sites,substations,sinks,sources,lines={},{},{},{},{}
local start_tick
local function make(surface,name,x,y,extra)
  local args={name=name,position={x,y},force='player',raise_built=true}
  for k,v in pairs(extra or {}) do args[k]=v end
  local e=surface.create_entity(args)
  assert(e and e.valid,'cannot create '..name..' at '..x..','..y)
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
local function setup()
  local s=game.create_surface('em062-long-mainline-stress',{width=2048,height=128})
  s.generate_with_lab_tiles=true
  for x=-992,992,96 do s.request_to_generate_chunks({x,0},2) end
  s.force_generate_chunk_requests()
  for x=-943,943,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
  for x=-941.5,938.5,20 do lines[#lines+1]=make(s,'em-35kv-catenary-pole',x,2.5) end
  for i=1,48 do
    local x=-940+(i-1)*40
    sites[i]=x
    substations[i]=make(s,'em-35kv-traction-substation',x,9)
    if (i-1)%8==0 then sources[i]=eei(s,x,'primary_output')
    else sinks[i]=eei(s,x,'secondary_input') end
  end
  log('[EM062 MULTI] set up 48 substations with six 20MW sources and 42 sinks')
end
local function sum()
  local t,lo,hi,count=0,math.huge,0,0
  for i=1,48 do
    local e=sinks[i]
    if e then
    if e.input_flow_limit>0 then
      count=count+1
      t=t+e.energy
      lo=math.min(lo,e.energy)
      hi=math.max(hi,e.energy)
    end
    end
  end
  return t,lo,hi,count
end
local function connectivity()
  local factory={}
  for i,s in ipairs(substations) do
    local id=s.electric_network_id
    assert(id,'factory electrical net missing '..i)
    assert(not factory[id],'separate factory networks shorted: '..i)
    factory[id]=true
  end
  local lid=lines[1].electric_network_id
  for i=2,#lines do assert(lines[i].electric_network_id==lid,'catenary disconnected '..i) end
  assert(not factory[lid],'factory/catenary short')
  return lid
end
local function show(t)
  local total,lo,hi,n=sum()
  log(string.format('[EM062 MULTI] dt=%d receiving=%d energy_J=%.0f min_J=%.0f max_J=%.0f source_J=%.0f',t,n,total,lo,hi,0))
  return total,lo,hi,n
end
script.on_event(defines.events.on_tick,function(ev)
  if not start_tick then start_tick=ev.tick;setup() end
  local dt=ev.tick-start_tick
  if dt==90 then connectivity();show(dt) end
  if dt==240 then
    connectivity()
    local total,lo,hi,n=show(dt)
    assert(n==42,'wrong receiver count')
    assert(lo>500000,'a remote factory was starved, lowest='..lo)
    assert(hi/lo<2.2,'long-mainline allocation unfair max/min='..hi/lo)
    assert(total>340000000 and total<490000000,'energy budget abnormal: '..total)
    log('[EM062 48 STAGE1 PASS] 48 isolated factory grids, six 20MW generators, 42 equal consumers, source budget and fairness checked at tick 240')
    -- Keep every other load alive. All existing production should automatically redistribute.
    for i=1,48 do if sinks[i] and i%2==0 then sinks[i].input_flow_limit=0 end end
    storage.before={}
    for i=1,48 do if sinks[i] then storage.before[i]=sinks[i].energy end end
    log('[EM062 MULTI] 24 selected receivers disabled, others remain active')
  end
  if dt==600 then
    connectivity()
    local total,lo,hi,n=show(dt)
    local added,delta_min,delta_max,n_live=0,math.huge,0,0
    for i=1,48 do
      if sinks[i] then
      local d=sinks[i].energy-storage.before[i]
      if i%2==1 then
        n_live=n_live+1;added=added+d;delta_min=math.min(delta_min,d);delta_max=math.max(delta_max,d)
      else assert(d<600000,'disabled load still filled too much '..i..' delta='..d) end
      end
    end
    log(string.format('[EM062 MULTI] 18 active sinks newly received_J=%.0f min_delta=%.0f max_delta=%.0f',added,delta_min,delta_max))
    assert(n_live==18,'live count unexpected')
    assert(delta_min>200000,'a remaining sink received no power')
    assert(delta_max/delta_min<2.3,'restored distribution uneven')
    assert(added>590000000 and added<750000000,'post-shutdown allocation budget invalid '..added)
    -- Source switch to simulate outage. No network should generate energy thereafter.
    for _,e in pairs(sources) do e.electric_interface_mode=defines.electric_interface_mode.secondary_input
    e.power_production=0;e.power_usage=0;e.input_flow_limit=RATE;e.output_flow_limit=0 end
    storage.outage_total=0
    for _,e in pairs(sinks) do storage.outage_total=storage.outage_total+e.energy end
    log('[EM062 MULTI] source outage; should stop factory deliveries')
  end
  if dt==900 then
    connectivity()
    show(dt)
    local post=0
    for _,e in pairs(sinks) do post=post+e.energy end
    assert(post<=storage.outage_total+27000000,'energy appeared after source outage '..(post-storage.outage_total))
    log('[EM062 STRESS PASS] 48 factory grids isolated, 6x20MW sources, 42-way fair share, 18-way reroute, bounded outage')
  end
end)