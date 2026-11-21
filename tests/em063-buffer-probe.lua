-- Native 2-substation + accumulator + hidden-bridge buffer experiment.
-- Test only. Factorio 2.1.24. No changes to production mod prototypes.
local f={}
local CASE=(script.mod_name or ''):match('em063%-buffer%-(%w+)') or 'both'
local HAVE_A=CASE=='both' or CASE=='source'
local HAVE_B=CASE=='both' or CASE=='receiver'
assert(CASE=='both' or CASE=='source' or CASE=='receiver' or CASE=='bridge','invalid EM063 scenario')
local MW=1000000/60
local function make(s,name,x,y,extra)
 local v={name=name,position={x,y},force='player',raise_built=true}
 for k,val in pairs(extra or {}) do v[k]=val end
 local e=s.create_entity(v)
 assert(e and e.valid,'create failed '..name..' at '..x..','..y)
 return e
end
local function eei(s,x,y,mode,mw)
 local e=make(s,'electric-energy-interface',x,y)
 e.electric_interface_mode=defines.electric_interface_mode[mode]
 e.electric_buffer_size=1000000000
 e.power_production=mode=='primary_output' and mw*MW or 0
 e.power_usage=0
 e.input_flow_limit=mode=='secondary_input' and mw*MW or 0
 e.output_flow_limit=mode=='primary_output' and mw*MW or 0
 e.energy=0
 return e
end
local function batteries(s,positions)
 local list={}
 for _,x in ipairs(positions) do
  local b=make(s,'accumulator',x,13);b.energy=0
  list[#list+1]=b
 end
 return list
end
local function sum(list)
 local v=0
 for _,e in ipairs(list) do v=v+e.energy end
 return v
end
local function hidden()
 local lab=game.surfaces['em-25kv-isolated-bridge-058']
 if not lab then return 0,0,0,0,0 end
 local i,o,ci,co,n=0,0,0,0,0
 for _,e in pairs(lab.find_entities_filtered{type='electric-energy-interface'}) do
  n=n+1
  if e.name=='em-25kv-bridge-input-058' then i=i+e.energy;ci=ci+e.electric_buffer_size end
  if e.name=='em-25kv-bridge-output-058' then o=o+e.energy;co=co+e.electric_buffer_size end
 end
 return i,o,ci,co,n
end
local function setup()
 local s=game.create_surface('em063-source-sink-'..CASE,{width=256,height=128})
 s.generate_with_lab_tiles=true
 s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
 for x=-23,23,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
 f.m1=make(s,'em-35kv-catenary-pole',-21.5,2.5)
 make(s,'em-35kv-catenary-pole',-1.5,2.5)
 f.m2=make(s,'em-35kv-catenary-pole',18.5,2.5)
 f.sa=make(s,'em-35kv-traction-substation',-20,9)
 f.sb=make(s,'em-35kv-traction-substation',20,9)
 f.source=eei(s,-20,13,'primary_output',20)
 f.sink=eei(s,20,13,'secondary_input',10)
 f.a=HAVE_A and batteries(s,{-25,-22,-19,-16}) or {}
 f.b=HAVE_B and batteries(s,{16,19,22,25}) or {}
 assert(f.sa.electric_network_id~=f.sb.electric_network_id,'ordinary grids shorted')
 assert(f.sa.electric_network_id~=f.m1.electric_network_id and f.sb.electric_network_id~=f.m1.electric_network_id,'factory/corridor shorted')
 log('[EM063] case='..CASE..' source_grid='..f.sa.electric_network_id..' sink_grid='..f.sb.electric_network_id)
end
local function snapshot(t)
 local i,o,ci,co,n=hidden()
 log(string.format('[EM063 SAMPLE] case=%s dt=%d source_J=%.0f sink_J=%.0f battery_A_J=%.0f battery_B_J=%.0f hidden_in_J=%.0f hidden_out_J=%.0f hidden_input_cap_J=%.0f hidden_output_cap_J=%.0f hidden_port_count=%d',CASE,t,f.source.energy,f.sink.energy,sum(f.a),sum(f.b),i,o,ci,co,n))
end
script.on_event(defines.events.on_tick,function(ev)
 if not storage.start then storage.start=ev.tick;setup() end
 local t=ev.tick-storage.start
 if t==120 or t==300 or t==540 or t==600 or t==660 or t==840 or t==1020 or t==1200 or t==1480 then snapshot(t) end
 if t==540 then
  assert(f.m1.electric_network_id==f.m2.electric_network_id,'contact line not joined')
  assert(f.sink.energy>25000000,'consumer starved during primary generation')
  if HAVE_A then assert(sum(f.a)>1000000,'source factory batteries not charged') end
  if HAVE_B then assert(sum(f.b)>1000000,'receiver factory batteries not charged') end
  storage.off={sink=f.sink.energy,a=sum(f.a),b=sum(f.b)}
  f.source.power_production=0;f.source.output_flow_limit=0
  log('[EM063] case='..CASE..' generator_off_dt=540')
 end
 if t==1020 then
  local da=storage.off.a-sum(f.a)
  local db=storage.off.b-sum(f.b)
  local delivered=f.sink.energy-storage.off.sink
  log(string.format('[EM063 DELTA] case=%s source_battery_used_J=%.0f receiver_battery_used_J=%.0f sink_received_after_off_J=%.0f',CASE,da,db,delivered))
  if HAVE_A then assert(da>100000,'source batteries did not export energy') end
  if HAVE_B then assert(db>100000,'receiver batteries did not supply local network') end
  if HAVE_A or HAVE_B then assert(delivered>100000,'consumer not supplied by batteries') end
  assert(delivered<=da+db+1000000,'energy balance violation after generator loss')
  if not HAVE_A and not HAVE_B then assert(delivered<1000000,'transient port energy was treated as long-term battery') end
 end
 if t==1200 then storage.last=f.sink.energy end
 if t==1480 then
  local delta=f.sink.energy-storage.last
  assert(sum(f.a)<100000 and sum(f.b)<100000,'batteries still charged at terminal checkpoint')
  assert(delta<500000,'consumer received unexplained power after all storage depleted')
  log(string.format('[EM063 NATIVE PASS] case=%s post_depletion_gain_J=%.0f generator_off=1 expected_batteries=%d',CASE,delta,#f.a+#f.b))
 end
end)