-- EM072-A5 B0: actual Factorio native rail and train motion, finite native grid reservoir.
-- Isolated lab only; no writing to production mod tree or user save.
local function make(surface,name,x,y,other)
 local opts={name=name,position={x,y},force="player",raise_built=true}
 for k,v in pairs(other or {}) do opts[k]=v end
 local e=surface.create_entity(opts)
 assert(e and e.valid,"cannot place "..name.." at "..x..","..y)
 return e
end
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
local function setup()
 local s=game.create_surface("em072a5-native-overload",{width=2048,height=320})
 s.generate_with_lab_tiles=true
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
 for _,a in ipairs(outpost) do a.energy=5000000 end
 local meter=make(s,'em072a5-b1-native-traction-meter',-140,7,{raise_built=false})
 meter.energy=0
 meter.electric_interface_mode=defines.electric_interface_mode.secondary_input
 assert(meter.electric_interface_mode==defines.electric_interface_mode.secondary_input)
 log('[EM072A5 B1 METER] mode='..tostring(meter.electric_interface_mode)..' input='..tostring(meter.input_flow_limit)..' output='..tostring(meter.output_flow_limit))
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
 storage.b0={surface=s,sub=sub,masts=masts,cells=cells,outpost=outpost,meter=meter,locos=locos,drivers=drivers,starts=starts,
  got={},spent={},previous={},peak=0,granted=0,total_tick=0,first_supply_tick=0,init_j=0, off_tick=235, off_granted=0,pre_off_outpost=0}
 local p=storage.b0
 for i=1,12 do p.got[i]=0;p.spent[i]=0;p.previous[i]=0 end
 log("[EM072A5 B1 SETUP] 12 native trains, 84 factory cells and 24 TRUE native corridor cells, native traction meter, modified mast supply radius TEST ONLY")
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
 if t==35 then
  local count=0;for _ in pairs(distinct) do count=count+1 end
  assert(count==12,"not 12 different real native LuaTrain.ids: "..count)
  log("[EM072A5 B1 TRAINS PASS] count=12 distinct native LuaTrain.id")
 end
 if t==90 then
  local _,topology= sum_state(p)
  assert(topology.factory and topology.line and topology.factory~=topology.line,"EM070 physical isolation broken")
  local connected=0
  for _,a in ipairs(p.cells) do if a.electric_network_id==topology.factory then connected=connected+1 end end
  assert(connected==84,"not all finite factory accumulator sources are in same native network: "..connected)
  local match=0
  for _,a in ipairs(p.outpost) do if a.electric_network_id==topology.line then match=match+1 end end
  assert(match==24,'native corridor battery component missing: '..match)
  assert(p.meter.electric_network_id==topology.line,'traction meter not native corridor network')
  assert(topology.line==p.masts[1].electric_network_id,'rail mast does not match meter network')
  log('[EM072A5 B1 NATIVE CORRIDOR PASS] 84 factory cells and 24 corridor accumulators; native traction meter; electric network IDs isolated')
  p.init_j=sum_state(p)
  assert(p.init_j>530000000 and p.init_j<545000000,"unexpected source energy in reservoir")
  -- A single far north mast has expanded test supply, never any mast near factory.
  local out_mast=p.masts[1]
  for _,a in ipairs(p.cells) do
   local dx=a.position.x-out_mast.position.x;local dy=a.position.y-out_mast.position.y
   assert(dx*dx+dy*dy>40*40,'factory accumulator overlaps test outpost mast supply')
  end
  assert(p.sub.position.x-out_mast.position.x>40,'outpost supply touches factory traction substation')
  log("[EM072A5 B1 START LEDGER] t=90 native_total_j="..p.init_j)
 end
 if t==p.off_tick then
  p.pre_off_outpost=sum_outpost(p)
  p.pre_off_factory=sum_factory(p)
  p.off_positions={}
  for i,loco in ipairs(p.locos) do p.off_positions[i]=loco.position.x end
  assert(remote.call('em072a5_b0_native','set_off',p.sub.unit_number))
  log('[EM072A5 B1 STATION OFF] mode=off t='..t..' outpost_J='..p.pre_off_outpost)
 end
 if t>=91 and t<=340 then
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
   assert(total<=7200000/60+0.05,'station OFF supplied >7.2MW native battery capacity')
  end
  if total>0 then
   assert(funded==12,"allocated some but not all reachable equal trains: "..funded)
   assert(max_v-min_v<0.2,"max-min fairness broken within a native tick: "..(max_v-min_v))
   p.first_supply_tick=p.first_supply_tick==0 and t or p.first_supply_tick
   p.peak=math.max(p.peak,total);p.granted=p.granted+total;p.total_tick=p.total_tick+1
  end
 end
 if t%60==0 then
  local total,b=sum_state(p)
  local spent=0;for _,v in ipairs(p.spent) do spent=spent+v end
  local delta=t>=90 and p.init_j-total-spent or 0
  if t>=91 and t<p.off_tick then assert((b.planned or 0)<=20.000001,'station planner exceeded 20MW') end
  log(string.format("[EM072A5 B1 TRACE] t=%d planned=%.3fMW dir=%s status=%s line=%s factory=%s transfer=%.0f J spent=%.0f J residual=%.3f J funded_ticks=%d outpost_J=%.1f meter_J=%.1f qual=%s meter_mode=%s",t,b.planned or 0,tostring(b.direction),tostring(b.status),tostring(b.line),tostring(b.factory),p.granted,spent,delta,p.total_tick,sum_outpost(p),p.meter.energy,tostring(remote.call('em072a5_b0_native','qualifies',p.sub.unit_number,p.locos[1].unit_number)),tostring(p.meter.electric_interface_mode)))
  if t>=120 then assert(math.abs(delta)<1,"native energy balance violated: "..delta) end
 end
 if t==151 then
  local ok,err=pcall(function() game.server_save("em072a5-b1-checkpoint") end)
  log("[EM072A5 B1 DISK SAVE] t=151 requested="..tostring(ok).." err="..tostring(err))
 end
 if t==241 then p.post_off_factory=sum_factory(p) end
 if t==310 then
   local off_storage=sum_outpost(p)
   assert(p.off_granted>2000000,'native battery supplied no Joules after station OFF')
   assert(off_storage<p.pre_off_outpost-1000000,'native battery energy was not debited during OFF')
   local factory_after=sum_factory(p)
   assert(math.abs(factory_after-p.post_off_factory)<1,'factory sources were drained after settled OFF! '..(factory_after-p.post_off_factory))
   local _,b=sum_state(p)
   assert(b.mode=='off','EM070 station remained on')
   assert((b.planned or 0)<0.0001,'EM070 still issued planned MW after OFF')
   assert(p.meter.electric_network_id==p.masts[1].electric_network_id,'meter lost native line side after OFF')
   local min_off_movement=math.huge
   for i,loco in ipairs(p.locos) do min_off_movement=math.min(min_off_movement,math.abs(loco.position.x-p.off_positions[i])) end
   assert(min_off_movement>0.05,'one native locomotive failed to move after station OFF: '..min_off_movement)
   log(string.format('[EM072A5 B1 OFF PASS] off_delivered_J=%.3f outpost_before_J=%.3f outpost_after_J=%.3f min_off_movement_tiles=%.3f meter_J=%.1f line_network=%s factory_change_J=%.3f',p.off_granted,p.pre_off_outpost,off_storage,min_off_movement,p.meter.energy,tostring(p.meter.electric_network_id),factory_after-p.post_off_factory))
 end
 if t==360 then
  local sum_got=0;local min_got=math.huge;local max_got=0;local min_move=math.huge;local sum_spent=0
  for i,loco in ipairs(p.locos) do
   sum_got=sum_got+p.got[i];min_got=math.min(min_got,p.got[i]);max_got=math.max(max_got,p.got[i])
   min_move=math.min(min_move,math.abs(loco.position.x-p.starts[i]));sum_spent=sum_spent+p.spent[i]
  end
  local total,b=sum_state(p)
  local deficit=p.init_j-total-sum_spent
  assert(p.total_tick>120,"not enough real power delivery ticks: "..p.total_tick)
  assert(sum_got>15000000,"native supply too low: "..sum_got)
  assert(min_got>0 and max_got-min_got<3,"unfair native joule split: "..(max_got-min_got))
  assert(min_move>0.05,"at least one locomotive did not move under paid power: "..min_move)
  assert(b.mode=="off","station OFF did not persist")
  assert(b.cache_builds>=1 and b.cache_builds<=2,"native physical HSR path cache was not used")
  assert(math.abs(deficit)<3000,"joule accounting exceeds error budget: "..deficit)
  log(string.format("[EM072A5 B1 NATIVE PASS] 12 moving trains actual_J=%.0f spent_J=%.0f min_train_J=%.3f max_train_J=%.3f peak_MW=%.6f station_20MW_cap=true min_move_tiles=%.4f ledger_residual_J=%.6f funded_ticks=%d cache_builds=%d",sum_got,sum_spent,min_got,max_got,p.peak*60/1e6,min_move,deficit,p.total_tick,b.cache_builds))
 end
end)