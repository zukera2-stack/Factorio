-- Disposable native topology/teardown lifecycle probe, Factorio 2.1.24.
-- Exercises real script_raised_destroy and script_raised_built events.
local W = 1000000/60
local f={}
local function e(s,n,x,y,ex)
  local p={name=n,position={x,y},force='player',raise_built=true}
  for k,v in pairs(ex or {}) do p[k]=v end
  local r=s.create_entity(p)
  assert(r and r.valid, 'create failed: '..n..' '..x..','..y)
  return r
end
local function eei(s,x,mode,power)
  local a=e(s,'electric-energy-interface',x,13)
  a.electric_interface_mode=defines.electric_interface_mode[mode]
  a.electric_buffer_size=1000000000
  a.power_production=mode=='primary_output' and power*W or 0
  a.power_usage=0
  a.input_flow_limit=mode=='secondary_input' and power*W or 0
  a.output_flow_limit=mode=='primary_output' and power*W or 0
  a.energy=0
  return a
end
local function hidden()
  local s=game.surfaces['em-25kv-isolated-bridge-058']
  if not s then return 0,0 end
  local n,j=0,0
  for _,v in pairs(s.find_entities_filtered{type='electric-energy-interface'}) do
    n=n+1;j=j+v.energy
  end
  return n,j
end
local function state(t,label)
  local n,j=hidden()
  log(string.format('[EM064 STAGE] %s dt=%d srcJ=%.0f sinkJ=%.0f lineA=%s lineB=%s facA=%s facB=%s hidden_count=%d hidden_j=%.0f',label,t,f.source.energy,f.sink.energy,tostring(f.m1.valid and f.m1.electric_network_id or '-'),tostring(f.m2.valid and f.m2.electric_network_id or '-'),tostring(f.a.valid and f.a.electric_network_id or '-'),tostring(f.b.valid and f.b.electric_network_id or '-'),n,j))
end
local function find(s,name,x,y)
  local list=s.find_entities_filtered{name=name,position={x,y},radius=0.3}
  for _,entity in pairs(list) do
    if entity.name==name and math.abs(entity.position.x-x)<0.1 and math.abs(entity.position.y-y)<0.1 then return entity end
  end
  error('Cannot rehydrate '..name..' at '..x..','..y)
end
local function hydrate()
  local s=game.surfaces['em064-topology'];assert(s,'saved test surface missing')
  f.s=s;f.m1=find(s,'em-35kv-catenary-pole',-31.5,2.5)
  f.mid=find(s,'em-35kv-catenary-pole',-1.5,2.5)
  f.m2=find(s,'em-35kv-catenary-pole',28.5,2.5)
  f.a=find(s,'em-35kv-traction-substation',-30,9)
  f.b=find(s,'em-35kv-traction-substation',30,9)
  f.source=find(s,'electric-energy-interface',-30,13)
  f.sink=find(s,'electric-energy-interface',30,13)
  f.rails={};f.rails[-1]=find(s,'em-high-speed-straight-rail',-1,1)
  log('[EM064] test fixture rehydrated after Lua reload')
end
local function details(t)
  local lab=game.surfaces['em-25kv-isolated-bridge-058']
  if not lab then return end
  local items={}
  for _,v in pairs(lab.find_entities_filtered{type='electric-energy-interface'}) do
    items[#items+1]=string.format('%s@%s energy=%.0f in=%.0f out=%.0f',v.name,tostring(v.electric_network_id),v.energy,v.input_flow_limit or 0,v.output_flow_limit or 0)
  end
  table.sort(items)
  log('[EM064 PORTS] dt='..t..' '..table.concat(items,' | '))
end
local function setup()
  local s=game.create_surface('em064-topology',{width=256,height=128});s.generate_with_lab_tiles=true
  s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
  f.s=s
  for x=-33,33,2 do f.rails=f.rails or {};f.rails[x]=e(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
  f.m1=e(s,'em-35kv-catenary-pole',-31.5,2.5)
  f.mid=e(s,'em-35kv-catenary-pole',-1.5,2.5)
  f.m2=e(s,'em-35kv-catenary-pole',28.5,2.5)
  f.a=e(s,'em-35kv-traction-substation',-30,9)
  f.b=e(s,'em-35kv-traction-substation',30,9)
  f.source=eei(s,-30,'primary_output',20)
  f.sink=eei(s,30,'secondary_input',10)
  assert(f.a.electric_network_id~=f.b.electric_network_id,'initial grids short')
  state(0,'start')
end
local function check_on(t,where)
  assert(f.m1.electric_network_id==f.m2.electric_network_id,where..': corridor disconnected')
  assert(f.a.electric_network_id~=f.b.electric_network_id,where..': factory grids shorted')
  local n=hidden();assert(n>=4,where..': hidden interfaces absent '..n)
  log('[EM064 PASS] '..where..' active source/sink on separate factory networks')
end
local function check_off(t,where,cap)
  assert(f.m1.electric_network_id~=f.m2.electric_network_id,where..': corridor did not split')
  local n=hidden()
  assert(n<4,where..': bridge still retains full active interface pair '..n)
  log('[EM064 PASS] '..where..' corridor split hidden_count='..n)
end
script.on_event(defines.events.on_tick,function(ev)
  if not f.s then
    if not storage.em064_started then storage.em064_started=ev.tick;setup()
    else hydrate() end
  end
  local t=ev.tick-storage.em064_started
  if t==180 then check_on(t,'initial');state(t,'initial') end
  if t==200 then
    storage.em064_before=f.sink.energy
    f.mid.destroy{raise_destroy=true};state(t,'remove_middle_mast')
  end
  if t==290 then
    state(t,'mast_before_split_check');check_off(t,'mast_destroy')
    local gain=f.sink.energy-storage.em064_before
    assert(gain<1500000,'mast_destroy: sustained power after disconnected corridor '..gain)
    state(t,'mast_split_stable')
  end
  if t==310 then f.mid=e(f.s,'em-35kv-catenary-pole',-1.5,2.5);state(t,'restore_middle_mast') end
  if t==420 then check_on(t,'mast_rebuilt');state(t,'mast_rebuilt') end
  if t==440 then
    storage.em064_before=f.sink.energy
    f.rails[-1].destroy{raise_destroy=true};state(t,'rail_remove')
  end
  if t==520 then
    check_off(t,'rail_cut')
    local gain=f.sink.energy-storage.em064_before
    assert(gain<1500000,'rail_cut: power persisted '..gain)
    state(t,'rail_split_stable')
  end
  if t==540 then f.rails[-1]=e(f.s,'em-high-speed-straight-rail',-1,1,{direction=defines.direction.east});state(t,'rail_restore') end
  if t==650 then check_on(t,'rail_rebuilt');state(t,'rail_rebuilt') end
  if t==670 then
    storage.em064_b_id=f.b.unit_number
    storage.em064_before=f.sink.energy
    f.b.destroy{raise_destroy=true};state(t,'substation_destroy')
  end
  if t==735 then
    local n=hidden()
    assert(n<=2,'deleted substation retained hidden EEI '..n)
    local gain=f.sink.energy-storage.em064_before
    assert(gain<1500000,'deleted substation still powers consumer '..gain)
    log('[EM064 PASS] substation removed and hidden interfaces cleaned')
  end
  if t==750 then f.b=e(f.s,'em-35kv-traction-substation',30,9);state(t,'substation_restore') end
  if t==865 then check_on(t,'substation_rebuilt');state(t,'substation_rebuilt') end
  if t==895 then
    f.cross1=e(f.s,'big-electric-pole',-22,18)
    f.cross2=e(f.s,'big-electric-pole',0,18)
    f.cross3=e(f.s,'big-electric-pole',22,18)
    state(t,'factory_copper_merge')
  end
  if t==975 then
    assert(f.a.electric_network_id==f.b.electric_network_id,'factory merge did not merge factory grids')
    local n=hidden()
    assert(n<4,'factory merge retained two full active bridge interface pairs: '..n)
    state(t,'factory_merge_stable');
    local _,stranded=hidden()
    assert(stranded<=666668,'unbounded transient bridge energy after factory merge: '..stranded)
    storage.em064_merged_remainder=stranded
    log('[EM064 OBSERVATION] factory merge retained transient bridge energy J='..stranded..' (may be discarded on reconfiguration)')
    log('[EM064 PASS] intentional factory merge suppresses same-network relay')
  end
  if t==975 or t==999 or t==1000 or t==1001 or t==1002 or t==1003 or t==1020 then details(t) end
  if t==1002 then local _,j=hidden();log('[EM064 OBSERVATION] split-at-t1002 hidden_energy_J='..j..' previous_merged_J='..tostring(storage.em064_merged_remainder)) end
  if t==1000 then f.cross1.destroy{raise_destroy=true};f.cross2.destroy{raise_destroy=true};f.cross3.destroy{raise_destroy=true};state(t,'factory_split') end
  if t==1150 then check_on(t,'factory_resplit');state(t,'factory_resplit') end
  if t==1170 then
    -- EM064_SERVER_SAVE_HOOK (the test runner replaces this in server mode).
    game.reload_script()
    log('[EM064] invoked game.reload_script at dt1170')
  end
  if t==1250 then
    check_on(t,'after_script_reload');state(t,'after_script_reload')
    if storage.em064_checkpoint_sink then
      local delta=f.sink.energy-storage.em064_checkpoint_sink
      assert(delta>5000000, 'disk-load continuation did not deliver power: '..delta)
      log(string.format('[EM064 DISK PASS] restored_factory_ids=%s,%s sink_delta_J=%.0f',tostring(f.a.electric_network_id),tostring(f.b.electric_network_id),delta))
    end
    log('[EM064 NATIVE PASS] mast cut/restore, rail cut/restore, substation remove/restore, factory merge/split, reload_script')
  end
end)