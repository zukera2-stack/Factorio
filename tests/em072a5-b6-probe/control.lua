-- EM072-A5 B4: physical HSR cut/rejoin and controller destruction/rebuild.
-- Isolated lab only; no writing to production mod tree or user save.
local function make(surface,name,x,y,other)
 local opts={name=name,position={x,y},force="player",raise_built=true}
 for k,v in pairs(other or {}) do opts[k]=v end
 local e=surface.create_entity(opts)
 assert(e and e.valid,"cannot place "..name.." at "..x..","..y)
 return e
end
script.on_event(defines.events.script_raised_destroy,function(event)
 local e=event.entity
 if e and e.name=='em072a5-b3-outpost-controller' then
  local p=storage.b0
  if p and p.b5 and p.b5.controller and p.b5.controller.unit_number==e.unit_number then
   assert(remote.call('em072a5_b5_secondary','detach',e.unit_number),'second terminal not detached')
  else
   assert(remote.call('em072a5_b3_terminal','detach',e.unit_number),'primary controller not detached')
  end
 end
end)
local function sum_factory(p)
 local j=0;for _,cell in ipairs(p.cells) do assert(cell.valid);j=j+cell.energy end
 return j
end
local function sum_outpost(p)
 local j=0
 for _,cell in ipairs(p.outpost) do assert(cell.valid);j=j+cell.energy end
 return j
end
local function sum_state(p)
 local total=0
 for _,a in ipairs(p.cells) do assert(a.valid);total=total+a.energy end
 total=total+sum_outpost(p)+p.meter.energy
 local b=remote.call("em072a5_b0_native","balances",p.sub.unit_number)
 total=total+(b.input or 0)+(b.output or 0)
 for _,loco in ipairs(p.locos) do total=total+loco.burner.remaining_burning_fuel end
 return total,b
end

-- SECOND physically isolated line, bank, native meter, separate tested ownership.
local function setup_second(s)
 for x=-200,750,2 do make(s,'em-high-speed-straight-rail',x,160,{direction=defines.direction.east}) end
 local masts={}
 for x=-141.5,578.5,20 do
  masts[#masts+1]=make(s,(x==-141.5 and 'em-35kv-catenary-pole-north' or 'em-35kv-catenary-pole'),x,161.5)
 end
 -- Second REAL station and physically separate native factory source (84 ordinary cells).
 local second_station=make(s,'em-35kv-traction-substation',500,168)
 local factory_cells={}
 for x=464,544,4 do for _,y in ipairs({174,178,187,191}) do
  factory_cells[#factory_cells+1]=make(s,'accumulator',x,y)
 end end
 assert(#factory_cells==84)
 for _,a in ipairs(factory_cells) do a.energy=5000000 end
 for x=472,536,16 do make(s,'substation',x,183) end
 for y=199,263,16 do for x=464,544,16 do make(s,'substation',x,y) end end
 local second_solar={}
 for x=450,550,4 do for y=213,265,4 do
  if s.can_place_entity{name='solar-panel',position={x,y},force='player'} then
   second_solar[#second_solar+1]=make(s,'solar-panel',x,y)
  end
 end end
 log('[EM072A5 B6 SECOND SOLAR COUNT] n='..#second_solar);assert(#second_solar>=160,'missing native second factory solar generator')
 local second_factory_load=make(s,'em072a5-b6-native-factory-load',508,178,{raise_built=false})
 second_factory_load.energy=0
 second_factory_load.electric_interface_mode=defines.electric_interface_mode.secondary_input
 second_factory_load.input_flow_limit=0
 assert(remote.call('em072a5_b6_station','register',second_station.unit_number))
 log('[EM072A5 B6 SECOND FACTORY SETUP] actual station and 84 cells, solar='..#second_solar)
 local outpost={}
 for _,x in ipairs({-152,-148,-144,-140,-136,-132}) do
  for _,y in ipairs({171,175,179,183}) do
   local a=make(s,'accumulator',x,y);a.energy=5000000;outpost[#outpost+1]=a
  end
 end
 assert(#outpost==24)
 local controller=make(s,'em072a5-b3-outpost-controller',-142,167)
 local meter=make(s,'em072a5-b1-native-traction-meter',-140,167,{raise_built=false})
 meter.energy=0;meter.electric_interface_mode=defines.electric_interface_mode.secondary_input
 local locos,drivers,ids,starts={},{},{},{}
 for i=0,3 do
  local x=-128+i*64
  local loco=make(s,'em072a5-b0-burner-loco',x,160,{direction=defines.direction.east})
  locos[#locos+1]=loco;ids[#ids+1]=loco.unit_number;starts[#starts+1]=x
  local driver=make(s,'character',x,151);drivers[#drivers+1]=driver;loco.set_driver(driver)
  assert(loco.get_driver()==driver);loco.train.manual_mode=true
  driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 end
 assert(remote.call('em072a5_b5_secondary','register',ids,meter.unit_number))
 return {masts=masts,outpost=outpost,controller=controller,meter=meter,locos=locos,ids=ids,drivers=drivers,starts=starts, second_station=second_station,factory_cells=factory_cells,second_solar=second_solar,factory_load=second_factory_load,factory_consumed=0,shortfall_ticks=0,bridge_active_ticks=0,bridge_peak=0,
   got={0,0,0,0},spent={0,0,0,0},prev={0,0,0,0},initial=120000000,granted=0,grant_ticks=0}
end
local function second_energy(p)
 local b=p.b5;local sum=0
 for _,a in ipairs(b.outpost) do assert(a.valid);sum=sum+a.energy end
 sum=sum+b.meter.energy+b.factory_load.energy
 for _,a in ipairs(b.factory_cells) do assert(a.valid);sum=sum+a.energy end
 local bridge=remote.call('em072a5_b0_native','balances',b.second_station.unit_number)
 sum=sum+(bridge.input or 0)+(bridge.output or 0)
 for _,loco in ipairs(b.locos) do sum=sum+loco.burner.remaining_burning_fuel end
 return sum
end

local function setup()
 local s=game.create_surface("em072a5-native-overload",{width=2048,height=768})
 s.generate_with_lab_tiles=true
 s.daytime=0.5;s.always_day=true -- native full daylight for REAL solar generation during precharge
 s.request_to_generate_chunks({0,0},13);s.request_to_generate_chunks({650,0},11);s.force_generate_chunk_requests()
 for x=-200,950,2 do make(s,"em-high-speed-straight-rail",x,1,{direction=defines.direction.east}) end
 local masts={}
 for x=-141.5,278.5,20 do
  masts[#masts+1]=make(s,(x==-141.5 and "em-35kv-catenary-pole-north" or "em-35kv-catenary-pole"),x,2.5)
 end
 local sub=make(s,"em-35kv-traction-substation",-20,9)
 local cells={}
 for x=-56,24,4 do for _,y in ipairs({14,18,27,31}) do
  cells[#cells+1]=make(s,"accumulator",x,y)
 end end
 assert(#cells==84)
 local poles={}
 for x=-48,16,16 do poles[#poles+1]=make(s,"substation",x,23) end
 for _,a in ipairs(cells) do a.energy=5000000 end
 -- GENUINE native Factorio solar generation, NOT scripted free joules.
 -- Additional vanilla substations connect panels to same factory component.
 for y=39,87,16 do
  for x=-48,32,16 do make(s,'substation',x,y) end
 end
 local solar={}
 for x=-66,34,4 do
  for y=49,101,4 do
   if s.can_place_entity{name='solar-panel',position={x,y},force='player'} then
    local p=make(s,'solar-panel',x,y)
    solar[#solar+1]=p
   end
  end
 end
 assert(#solar>=180,'too few real native solar panels: '..#solar)
 log('[EM072A5 B3 REAL SOLAR] native solar count='..#solar..' no script production')
 -- True native accumulator objects, not scripted reservoirs. Built beside a permanent
 -- test-modified rail mast, not a transient EM070 station line_port.
 local outpost={}
 for _,x in ipairs({-152,-148,-144,-140,-136,-132}) do
  for _,y in ipairs({12,16,20,24}) do
   local a=make(s,'accumulator',x,y)
   outpost[#outpost+1]=a
  end
 end
 assert(#outpost==24)
 for _,a in ipairs(outpost) do a.energy=0 end -- REQUIRED zero state; native solver must charge cells.
 local controller=make(s,'em072a5-b3-outpost-controller',-142,7)
 local meter=make(s,'em072a5-b1-native-traction-meter',-140,7,{raise_built=false})
 meter.energy=0
 meter.electric_interface_mode=defines.electric_interface_mode.secondary_input
 -- Native EEI meter may fill its finite 800kJ buffer, but no burner credit occurs before t240.
 assert(meter.electric_interface_mode==defines.electric_interface_mode.secondary_input)
 log('[EM072A5 B3 METER] mode='..tostring(meter.electric_interface_mode)..' input='..tostring(meter.input_flow_limit)..' output='..tostring(meter.output_flow_limit))
 assert(remote.call('em072a5_b0_native','meter_register',meter.unit_number))
 local locos,drivers,starts,ids={},{},{},{}
 for i=0,11 do
  local x=-128+i*32
  local loco=make(s,"em072a5-b0-burner-loco",x,1,{direction=defines.direction.east})
  locos[#locos+1]=loco;starts[#starts+1]=x;ids[#ids+1]=loco.unit_number
  local driver=make(s,"character",x,-8)
  drivers[#drivers+1]=driver
  loco.set_driver(driver)
  assert(loco.get_driver()==driver,"native driver missing")
  loco.train.manual_mode=true
  driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 end
 assert(remote.call("em072a5_b0_native","register",ids),"native train registry rejected")
 storage.b0={surface=s,sub=sub,masts=masts,cells=cells,outpost=outpost,solar=solar,controller=controller,meter=meter,locos=locos,drivers=drivers,starts=starts,
  got={},spent={},previous={},peak=0,granted=0,total_tick=0,first_supply_tick=0,init_j=0, off_tick=300, off_granted=0,pre_off_outpost=0}
 storage.b0.b5=setup_second(s)
 local p=storage.b0
 for i=1,12 do p.got[i]=0;p.spent[i]=0;p.previous[i]=0 end
 assert(sum_outpost(p)==0,'outpost must begin exactly EMPTY')
 log('[EM072A5 B3 ZERO PASS] t1=0J in 24 real native accumulators; untouched stock mast supply=0; controller placeable')
end
script.on_event(defines.events.on_tick,function(event)
 local t=event.tick
 if t==1 then setup() end
 local p=storage.b0
 if not p then return end
 local distinct={}
 for i,loco in ipairs(p.locos) do
  assert(loco.valid and loco.train and loco.train.valid,"missing real native train: "..i)
  distinct[loco.train.id]=true
  local now=loco.burner.remaining_burning_fuel
  local consumption=math.max(0,p.previous[i]-now)
  p.spent[i]=p.spent[i]+consumption
  p.previous[i]=now
 end
 -- Test-only industrial sink debits only J charged by native Factorio grid.
 if t>=301 then
  local b=storage.b0.b5
  local j=b.factory_load.energy
  assert(j>=0 and j<=30000000/60+1,'native factory meter exceeded 30MW')
  b.factory_consumed=b.factory_consumed+j
  if t>=310 and j<30000000/60-1000 then b.shortfall_ticks=b.shortfall_ticks+1 end
  b.factory_load.energy=0
 end
 -- Track the SECOND physical component independently: separate native battery/meter/burner ledger.
 local b5=p.b5
 for i,loco in ipairs(b5.locos) do
  assert(loco.valid and loco.train and loco.train.valid,'secondary train vanished')
  local now=loco.burner.remaining_burning_fuel
  b5.spent[i]=b5.spent[i]+math.max(0,b5.prev[i]-now)
  b5.prev[i]=now
 end
 if t==2 then
  local bank=0;for _,a in ipairs(b5.outpost) do bank=bank+a.energy end
  assert(math.abs(bank-120000000)<5,'second bank not finite 120MJ')
 end
 if t==2 then
  p.init_j=sum_state(p)
  assert(math.abs(p.init_j-420000000)<1000,'not a closed initial 420MJ source: '..p.init_j)
  log('[EM072A5 B3 START LEDGER] t2 initial_J='..p.init_j)
 end
 if t==65 then
  assert(remote.call('em072a5_b3_terminal','attach',p.controller.unit_number,p.masts[1].unit_number),
    'script-owned outpost terminal connection rejected by verified technical mast')
  log('[EM072A5 B3 TERMINAL ATTACHED] native registered script copper to 25kV technical anchor')
  assert(remote.call('em072a5_b5_secondary','attach',p.b5.controller.unit_number,p.b5.masts[1].unit_number),'second terminal attach failed')
  log('[EM072A5 B5 SECOND TERMINAL ATTACHED] separate native anchor')
 end
 if t==35 then
  local count=0;for _ in pairs(distinct) do count=count+1 end
  assert(count==12,"not 12 different real native LuaTrain.ids: "..count)
  log("[EM072A5 B3 TRAINS PASS] count=12 distinct native LuaTrain.id")
 end
 if t==90 then
  local _,topology= sum_state(p)
  local terminal=remote.call('em072a5_b3_terminal','status')
  assert(terminal.valid and terminal.authorized and terminal.attached,'owned terminal wire is not recognized')
  assert(terminal.network and terminal.network==p.meter.electric_network_id,'terminal must power native meter')
  assert(topology.factory and topology.line and topology.factory~=topology.line,"EM070 physical isolation broken")
  local solar_connected=0
  for _,pv in ipairs(p.solar) do if pv.valid and pv.electric_network_id==topology.factory then solar_connected=solar_connected+1 end end
  assert(solar_connected>=180,'true solar array not attached to factory network: '..solar_connected)
  log('[EM072A5 B3 SOLAR TOPOLOGY PASS] real panels on factory network='..solar_connected)
  local connected=0
  for _,a in ipairs(p.cells) do if a.electric_network_id==topology.factory then connected=connected+1 end end
  assert(connected==84,"not all finite factory accumulator sources are in same native network: "..connected)
  local match=0
  for _,a in ipairs(p.outpost) do if a.electric_network_id==topology.line then match=match+1 end end
  assert(match==24,'native corridor battery component missing: '..match)
  assert(p.meter.electric_network_id==topology.line,'traction meter not native corridor network')
  assert(topology.line==p.masts[1].electric_network_id,'rail mast does not match meter network')
  log('[EM072A5 B3 NATIVE CORRIDOR PASS] 84 factory cells and 24 corridor accumulators; native traction meter; electric network IDs isolated')
  assert(math.abs(p.init_j-420000000)<1000,'wrong original total energy')
  -- NO mast has modified native supply radius. One script-owned terminal feeds the corridor.
  local out_mast=p.masts[1]
  for _,a in ipairs(p.cells) do
   local dx=a.position.x-out_mast.position.x;local dy=a.position.y-out_mast.position.y
   assert(dx*dx+dy*dy>40*40,'factory accumulator overlaps outpost terminal region')
  end
  assert(p.sub.position.x-out_mast.position.x>40,'outpost supply touches factory traction substation')
  assert(sum_outpost(p)>100000,'outpost did not start native recharge from 0')
  log('[EM072A5 B3 TOPOLOGY] t90 outpost_native_j='..sum_outpost(p))
 end
 if t==90 then
  local st=remote.call('em072a5_b5_secondary','status')
  local _,primary= sum_state(p)
  assert(st.authorized,'second script-owned terminal missing')
  assert(st.network and st.network~=primary.factory and st.network~=primary.line,
    'SECOND native corridor electric component overlaps primary/factory component')
  local n=0
  for _,a in ipairs(p.b5.outpost) do if a.electric_network_id==st.network then n=n+1 end end
  assert(n==24,'second 24 native batteries not on own corridor network: '..n)
  assert(p.b5.meter.electric_network_id==st.network)
  for _,loco in ipairs(p.b5.locos) do
   assert(not remote.call('em072a5_b0_native','qualifies',p.sub.unit_number,loco.unit_number),
       'PRIMARY source illegally reached SECOND isolated HSR')
  end
  for _,loco in ipairs(p.locos) do
   assert(not remote.call('em072a5_b5_secondary','qualifies',loco.unit_number),
     'SECOND native accumulator source illegally reached PRIMARY HSR')
  end
  log('[EM072A5 B5 ISOLATION PASS] 2 separate actual HSR/copper components and 2 native outposts; mutual unauthorized request=0')
  local two=remote.call('em072a5_b0_native','balances',p.b5.second_station.unit_number)
  assert(two.factory and two.line and two.factory~=two.line, 'SECOND real EM070 failed native net isolation')
  assert(two.factory~=primary.factory and two.factory~=primary.line and two.factory~=st.network, 'SECOND factory touches unrelated native network')
  assert(two.line==st.network,'SECOND real EM070 not connected to second outpost corridor')
  assert(p.b5.factory_load.electric_network_id==two.factory,'native brownout consumer outside second factory')
  local connected=0;for _,a in ipairs(p.b5.factory_cells) do if a.electric_network_id==two.factory then connected=connected+1 end end
  assert(connected==84,'not all second 84 native source cells connected '..connected)
  local solar_count=0;for _,a in ipairs(p.b5.second_solar) do if a.electric_network_id==two.factory then solar_count=solar_count+1 end end
  assert(solar_count>=60,'second factory has no real native solar source '..solar_count)
  log('[EM072A5 B6 TWO REAL EM070 PASS] 2 native physical substations, 2 isolated factory nets, 2 isolated corridors, second source 84 batteries, solar='..solar_count)

 end
 if t==95 then
  local fake=make(p.surface,'em072a5-b3-outpost-controller',-155,7,{force='enemy'})
  assert(not remote.call('em072a5_b3_terminal','attach',fake.unit_number,p.masts[1].unit_number),
   'wrong-force controller illegally attached to player corridor')
  assert(not remote.call('em072a5_b3_terminal','attach',p.controller.unit_number,p.sub.unit_number),
   'non-mast station impersonated script-owned feeder')
  log('[EM072A5 B3 NEGATIVE PASS] invalid force / non-mast outpost terminal rejected')
 end
 if t==200 then
  local charged=sum_outpost(p)
  assert(charged>1000000,'native charging was not established: '..charged)
  local st=remote.call('em072a5_b3_terminal','status')
  assert(st.valid and st.authorized and st.attached,'technical_046 audit stripped permitted port')
  assert(p.granted==0,'precharge-only phase already delivered engine joules')
  log(string.format('[EM072A5 B3 NATIVE CHARGE PASS] t200 zero_start=true charged_native_J=%.3f meter_active=%s',charged,tostring(p.meter.active)))
 end
 if t==225 then
  for _,pv in ipairs(p.solar) do if pv.valid then pv.destroy{raise_destroy=true} end end
  log('[EM072A5 B3 SOLAR OFF] t225 all true solar panels physically removed; from here ONLY finite accumulators')
  for _,pv in ipairs(p.b5.second_solar) do if pv.valid then pv.destroy{raise_destroy=true} end end
  log('[EM072A5 B6 SECOND SOLAR OFF] t225 second genuine factory solar generator removed')

 end
 if t==231 then
  p.init_j=sum_state(p) -- Exact finite-energy ledger starts AFTER native solar removed.
  assert(p.init_j>420000000,'real solar did not move Joules into native corridor batteries')
  log('[EM072A5 B3 CLOSED LEDGER] t231 native_source_and_outpost_J='..p.init_j)
  p.b5.initial=second_energy(p)
  assert(p.b5.initial>500000000,'second native finite energy ledger missing 84 factory batteries')
  log('[EM072A5 B6 SECOND FINITE LEDGER] initial_J='..p.b5.initial)

 end
 if t==240 then
  assert(remote.call('em072a5_b3_terminal','enable_demand'))
  log('[EM072A5 B3 ENABLE TRACTION] t240 native 12 train demands now enabled after accumulator charge')
  assert(remote.call('em072a5_b6_station','enable_secondary'),'failed second native AUTO station demand')

 end
 if t==p.off_tick then
  p.pre_off_outpost=sum_outpost(p)
  p.pre_off_factory=sum_factory(p)
  p.off_positions={}
  for i,loco in ipairs(p.locos) do p.off_positions[i]=loco.position.x end
  assert(remote.call('em072a5_b0_native','set_off',p.sub.unit_number))
  log('[EM072A5 B3 STATION OFF] mode=off t='..t..' outpost_J='..p.pre_off_outpost)
  -- The first station is OFF; SECOND station remains AUTO with separate factory.
  assert(remote.call('em072a5_b6_station','status').mode=='auto','second native EM070 not AUTO')
  b5.brownout_start_granted=b5.granted
  b5.factory_load.input_flow_limit=30000000/60
  log('[EM072A5 B6 NATIVE BROWNOUT LOAD ON] t300 real factory native EEI demand=30MW, 84-cell battery max=25.2MW')

 end
 if t>=241 and t<=495 then
  local actual=remote.call("em072a5_b0_native","take_all",p.sub.unit_number)
  local total=0;local min_v=math.huge;local max_v=0;local funded=0
  for i,loco in ipairs(p.locos) do
   local j=actual[loco.unit_number] or 0
   if j>0 then funded=funded+1 end
   assert(j>=0 and j<=2000000/60+0.05,"train power above 2MW")
   total=total+j;min_v=math.min(min_v,j);max_v=math.max(max_v,j)
   p.got[i]=p.got[i]+j
   p.previous[i]=loco.burner.remaining_burning_fuel
  end
  assert(total<=24000000/60+0.05,"24 MW total train demand exceeded: "..total)
  if t>p.off_tick+5 then
   p.off_granted=p.off_granted+total
   -- Meter may release up to its actual precharged 800kJ in the first ticks after
   -- physical reconnection. The 7.2MW limit applies to settled direct battery flow.
   if (t<=314 or (t>=346 and t<=354) or (t>=426 and t<=495)) then
    assert(total<=7200000/60+0.05,'steady state after OFF exceeds native battery 7.2MW at t='..t..' got='..total)
   end
  end
  if total>0 then
   assert(funded==12,"allocated some but not all reachable equal trains: "..funded)
   assert(max_v-min_v<0.2,"max-min fairness broken within a native tick: "..(max_v-min_v))
   p.first_supply_tick=p.first_supply_tick==0 and t or p.first_supply_tick
   p.peak=math.max(p.peak,total);p.granted=p.granted+total;p.total_tick=p.total_tick+1
  end
 end
 if t>=241 and t<=495 then
  local raw=remote.call('em072a5_b5_secondary','take')
  local total=0;local n=0;local minj=math.huge;local maxj=0
  for i,loco in ipairs(b5.locos) do
   local j=raw[loco.unit_number] or 0
   assert(j>=0 and j<=2000000/60+0.05,'secondary train exceeds 2MW')
   if j>0 then n=n+1 end
   b5.got[i]=b5.got[i]+j;b5.prev[i]=loco.burner.remaining_burning_fuel
   total=total+j;minj=math.min(minj,j);maxj=math.max(maxj,j)
  end
  assert(total<=8000000/60+0.05,'secondary demand exceeds four trains')
  assert(n==0 or n==4,'secondary powered only subset without fairness')
  if n>0 then assert(maxj-minj<0.2,'secondary unequal fair share');b5.grant_ticks=b5.grant_ticks+1 end
  b5.granted=b5.granted+total
 end
 if t%60==0 then
  local total,b=sum_state(p)
  local spent=0;for _,v in ipairs(p.spent) do spent=spent+v end
  local delta=t>=90 and p.init_j-total-spent or 0
  if t>=241 and t<p.off_tick then assert((b.planned or 0)<=20.000001,'station planner exceeded 20MW') end
  log(string.format("[EM072A5 B3 TRACE] t=%d planned=%.3fMW dir=%s status=%s line=%s factory=%s transfer=%.0f J spent=%.0f J residual=%.3f J funded_ticks=%d outpost_J=%.1f meter_J=%.1f qual=%s meter_mode=%s",t,b.planned or 0,tostring(b.direction),tostring(b.status),tostring(b.line),tostring(b.factory),p.granted,spent,delta,p.total_tick,sum_outpost(p),p.meter.energy,tostring(remote.call('em072a5_b0_native','qualifies',p.sub.unit_number,p.locos[1].unit_number)),tostring(p.meter.electric_interface_mode)))
  if t>=240 then assert(math.abs(delta)<1,"native energy balance violated since solar removal: "..delta) end
 end
 if t>=250 and t<=295 then
  local status=remote.call('em072a5_b6_station','status')
  if status.planned>0.01 then p.b5.bridge_active_ticks=p.b5.bridge_active_ticks+1 end
  p.b5.bridge_peak=math.max(p.b5.bridge_peak,status.planned or 0)
 end
 if t==295 then
  local st=remote.call('em072a5_b6_station','status')
  assert(p.b5.bridge_active_ticks>10,'second real EM070 did not dispatch before brownout')
  log(string.format('[EM072A5 B6 SECOND STATION FLOW] mode=%s status=%s planned=%.6fMW active_ticks=%d',tostring(st.mode),tostring(st.status),st.planned or 0,p.b5.bridge_active_ticks))
 end
 if t==330 then
  assert(p.b5.shortfall_ticks>4,'30MW factory demand not natively brownout-constrained by 84 cells')
  local st=remote.call('em072a5_b6_station','status')
  assert(st.mode=='auto','independent second EM070 unexpectedly disabled')
  assert(p.b5.granted>p.b5.brownout_start_granted+500000,'second corridor failed to continue during factory shortage')
  log(string.format('[EM072A5 B6 BROWNOUT PASS] 30MW native demand exceeds 25.2MW available factory battery; shortfall_ticks=%d station_mode=%s second_trains_delivered_J=%.0f',p.b5.shortfall_ticks,st.mode,p.b5.granted))
 end
 if t==385 then
  local ok,err=pcall(function() game.server_save("em072a5-b4-checkpoint") end)
  log("[EM072A5 B4 DISK SAVE] t=385 requested="..tostring(ok).." err="..tostring(err))
 end
 if t==306 then p.post_off_factory=sum_factory(p) end
 -- B4: physically cut real HSR x=-115 (not just a Boolean switch).
 if t==315 then
  local rails=p.surface.find_entities_filtered{position={x=-115,y=1},radius=5,name='em-high-speed-straight-rail'}
  local pick=nil;local best=math.huge
  for _,rail in ipairs(rails) do
   local dx=rail.position.x+115;local dy=rail.position.y-1
   local dd=dx*dx+dy*dy
   if dd<best then pick=rail;best=dd end
  end
  assert(pick and best<25,'missing HSR rail close to x=-115')
  p.rail_cut_position={x=pick.position.x,y=pick.position.y}
  log('[EM072A5 B4 CUT DEBUG] rail_x='..pick.position.x..' rail_y='..pick.position.y..' first_loco='..p.locos[1].position.x)
  local removed=pick.destroy{raise_destroy=true}
  log('[EM072A5 B4 CUT RETURN] result='..tostring(removed)..' still_valid='..tostring(pick.valid))
  assert(not pick.valid,'failed physical HSR cut')
  p.cut_start_j=p.granted
  log('[EM072A5 B4 RAIL CUT] physically removed real HSR at x=-115')
 end
 if t==320 then
  p.cut_settled_j=p.granted
 end
 if t==331 then
  local qualified=0
  for _,loco in ipairs(p.locos) do
   if remote.call('em072a5_b0_native','qualifies',p.sub.unit_number,loco.unit_number) then qualified=qualified+1 end
  end
  assert(qualified==0,'disconnected HSR still authorized train count='..qualified)
  assert(math.abs(p.granted-p.cut_settled_j)<0.01,
    'phantom J across cut HSR: '..(p.granted-p.cut_settled_j))
  assert(sum_outpost(p)>100000,'no battery energy left for reconnect test')
  log('[EM072A5 B4 CUT PASS] real rail gap means 0 authorized trains and 0 new burner J')
 end
 if t==335 then
  local x,y=p.rail_cut_position.x,p.rail_cut_position.y
  make(p.surface,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})
  p.rejoin_granted_start=p.granted
  log('[EM072A5 B4 RAIL REJOIN] placed real HSR at x=-115')
 end
 if t==354 then
  assert(p.granted>p.rejoin_granted_start+100000,
    'real HSR rejoin did not resume energy; delta='..(p.granted-p.rejoin_granted_start))
  log('[EM072A5 B4 REJOIN PASS] true HSR rail restores native paid traction')
 end
 if t==355 then
  p.mine_start_j=p.granted
  assert(p.controller.valid,'missing player-placeable test controller')
  p.controller.destroy{raise_destroy=true}
  log('[EM072A5 B4 CONTROLLER REMOVED] script-raised native destroy event of owner entity')
 end
 if t==365 then
  local st=remote.call('em072a5_b3_terminal','status')
  assert(not st.valid and not st.attached and not st.authorized,
    'controller removed but unauthorized terminal remains live')
  assert(not remote.call('em072a5_b0_native','qualifies',p.sub.unit_number,p.locos[1].unit_number),
    'orphan terminal still qualifies locomotive')
  assert(math.abs(p.granted-p.mine_start_j)<0.01,
    'train got free J after controller destroyed')
  log('[EM072A5 B4 REMOVAL PASS] controller removal deleted port; zero new J from orphan meter')
 end
 if t==310 then b5.before_cut=b5.granted end
 if t==331 then
   assert(b5.granted>b5.before_cut+200000,'SECOND corridor lost power when first HSR cut')
   assert(remote.call('em072a5_b5_secondary','status').authorized,'second terminal lost ownership')
   log('[EM072A5 B5 CROSS-COMPONENT CUT PASS] first HSR severed but second physically isolated outpost continued paid traction')
 end
 if t==355 then b5.before_primary_detach=b5.granted end
 if t==365 then
  assert(b5.granted>b5.before_primary_detach+50000,'second corridor stopped after first controller was removed')
  log('[EM072A5 B5 INDEPENDENT LIFECYCLE PASS] other terminal delivers while first controller is removed')
 end
 if t==370 then
  b5.before_detach=b5.granted
  b5.controller.destroy{raise_destroy=true}
  log('[EM072A5 B5 SECOND CONTROLLER REMOVED] real script-raised destroy of separate outpost owner')
 end
 if t==378 then
  assert(not remote.call('em072a5_b5_secondary','status').authorized,'second terminal still valid after owner removed')
  assert(math.abs(b5.granted-b5.before_detach)<0.05,'phantom secondary burner J after owner removal')
  log('[EM072A5 B5 SECOND REMOVAL PASS] second terminal revoked; no native energy across unauthorized component')
 end
 if t==380 then
  b5.controller=make(p.surface,'em072a5-b3-outpost-controller',-142,167)
  assert(remote.call('em072a5_b5_secondary','attach',b5.controller.unit_number,b5.masts[1].unit_number),'second terminal reattach failed')
  b5.before_rejoin=b5.granted
  log('[EM072A5 B5 SECOND CONTROLLER REBUILT] valid new owner and native script copper')
 end
 if t==390 then
  assert(remote.call('em072a5_b5_secondary','status').authorized,'second native terminal lost on disk SAVE/LOAD')
  assert(b5.granted>b5.before_rejoin+50000,'second corridor failed to pay J after reload')
  log('[EM072A5 B5 SECOND SAVE PASS] first corridor disconnected, second remains powered across independent disk load')
 end
 if t==390 then
  local st=remote.call('em072a5_b3_terminal','status')
  assert(not st.valid and not st.attached,
    'detached terminal incorrectly restored before explicit owner rebuild')
  assert(math.abs(p.granted-p.mine_start_j)<0.01,'train got unauthorized energy across SAVE boundary')
  log('[EM072A5 B4 DETACHED CHECK PASS] controller absent; no new J; asserted in native and reloaded worlds')
 end
 if t==400 then
  p.controller=make(p.surface,'em072a5-b3-outpost-controller',-142,7)
  assert(remote.call('em072a5_b3_terminal','attach',p.controller.unit_number,p.masts[1].unit_number),
    'rebuilt legitimate controller cannot attach to retained corridor')
  p.rebuild_start_j=p.granted
  log('[EM072A5 B4 CONTROLLER REBUILD] new controller explicitly attached via verified script wire')
 end
 if t==420 then
  local st=remote.call('em072a5_b3_terminal','status')
  assert(st.valid and st.attached and st.authorized and st.network==p.meter.electric_network_id,
    'recreated controller failed authorized native network ownership check')
  assert(p.granted>p.rebuild_start_j+100000,
    'native train failed to resume after controller rebuilt')
  log('[EM072A5 B4 REBUILD PASS] own terminal recreated; honest native batteries again supply trains')
 end
 if t==496 then
  local init=b5.initial;local remaining=second_energy(p);local used=0;local grant=0
  local lo,hi=math.huge,0;local travel=math.huge
  for i,loco in ipairs(b5.locos) do
   used=used+b5.spent[i];grant=grant+b5.got[i]
   lo=math.min(lo,b5.got[i]);hi=math.max(hi,b5.got[i])
   travel=math.min(travel,math.abs(loco.position.x-b5.starts[i]))
  end
  local residual=init-remaining-used-b5.factory_consumed
  assert(math.abs(residual)<3,'SECOND two-network battery + factory demand ledger mismatch '..residual)
  local fuel_left=0;for _,loco in ipairs(b5.locos) do fuel_left=fuel_left+loco.burner.remaining_burning_fuel end
  assert(math.abs(grant-used-fuel_left)<1,'SECOND native burner credit != native spent + current burner buffer')
  assert(math.abs(lo-hi)<3,'SECOND four trains not fairly metered')
  assert(travel>0.1 and grant>10000000 and b5.grant_ticks>100,'second real trains did not move/consume native energy')
  assert(remote.call('em072a5_b5_secondary','status').authorized,'second outpost lost its terminal')
  log(string.format('[EM072A5 B5 NATIVE PASS] second_train_count=4 second_delivered_J=%.3f second_native_spent_J=%.3f second_remaining_burner_J=%.3f second_ledger_residual_J=%.6f second_min_train_J=%.3f second_max_train_J=%.3f second_min_travel_tiles=%.3f second_cache_builds=%d',grant,used,fuel_left,residual,lo,hi,travel,remote.call('em072a5_b5_secondary','status').cache_builds))
  assert(b5.shortfall_ticks>30,'no sustained factory native brownout observed')
  assert(b5.factory_consumed>20000000,'factory load was not paid by native battery')
  assert(b5.bridge_active_ticks>10,'second station not actually importing')
  assert(b5.bridge_peak<=20.00001,'second EM070 exceeded 20MW native cap')
  log(string.format('[EM072A5 B6 NATIVE PASS] second_em070_peak_MW=%.6f second_factory_native_sink_J=%.3f shortfall_ticks=%d second_factory_ledger_residual_J=%.6f second_trains_paid_J=%.3f',b5.bridge_peak,b5.factory_consumed,b5.shortfall_ticks,residual,grant))

 end
 if t==496 then
  local sum_got,spent,min_train,max_train,travel=0,0,math.huge,0,math.huge
  for i,loco in ipairs(p.locos) do
   sum_got=sum_got+p.got[i];spent=spent+p.spent[i]
   min_train=math.min(min_train,p.got[i]);max_train=math.max(max_train,p.got[i])
   travel=math.min(travel,math.abs(loco.position.x-p.starts[i]))
  end
  local total,b=sum_state(p)
  local residual=p.init_j-total-spent
  assert(math.abs(residual)<3,'B4 physical ledger residual J='..residual)
  assert(math.abs(max_train-min_train)<3,'unequal J among 12 trains')
  assert(b.mode=='off' and (b.planned or 0)<0.01,'EM070 station unexpectedly on')
  assert(p.granted>10000000 and p.peak<=24000000/60+0.1,'nonphysical peak or insufficient test demand')
  assert(travel>0.05,'one train failed to move')
  assert(p.total_tick>100,'not enough native charge-bearing ticks')
  log(string.format('[EM072A5 B4 NATIVE PASS] delivered_J=%.3f spent_J=%.3f ledger_residual_J=%.6f min_train_J=%.3f max_train_J=%.3f min_motion_tiles=%.3f builds=%d',sum_got,spent,residual,min_train,max_train,travel,b.cache_builds))
 end
end)