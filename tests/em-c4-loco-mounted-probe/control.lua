-- EM072-C4: owner-only locomotive booster prototype/scope, no actual electrical payment.
local function out(kind, s) log('EMC4|'..kind..'|'..s) end
local CASES={
 {id='solo',x=0,kind='solo'},
 {id='vanilla',x=40,kind='vanilla'},
 {id='em0',x=80,kind='em0'},
 {id='em1',x=120,kind='em1'},
 {id='em2',x=160,kind='em2'},
 {id='em4',x=200,kind='em4'},
 {id='remove',x=240,kind='em2'},
 {id='change',x=280,kind='em2'},
 {id='multi',x=320,kind='multi'},
 {id='zero',x=360,kind='em2'},
 {id='em2drive',x=400,kind='em2'},
 {id='multi_owner_removed',x=440,kind='multi'},
 {id='late',x=480,kind='em2'}
}
local function count_real(t)
 local l,m=0,0
 for _,e in ipairs(t.carriages) do
  if e.name=='em-c4-real-electric' then l=l+1 end
  if e.name=='em-c4-motor-cargo' or e.name=='em-c4-motor-fluid' then m=m+1 end
 end
 return l,m
end
local function count_helper(t)
 local n,watts=0,0
 for _,e in ipairs(t.carriages) do if e.name:find('^em%-c4%-technical%-booster%-') then n=n+1; watts=watts+tonumber(e.name:match('(%d+)$'))*1000 end end
 return n,watts
end
local function stats(c)
 local r=c.real
 local t=(r and r.valid and r.train) or (c.wagon and c.wagon.valid and c.wagon.train)
 if not t or not t.valid then return 'no_train' end
 local nl,nm=count_real(t);local nh,p=count_helper(t)
 local parts={};for _,e in ipairs(t.carriages)do parts[#parts+1]=e.name end
 local numl=#t.locomotives.front_movers+#t.locomotives.back_movers
 local baseY=(r and r.valid and r.position.y) or (c.wagon and c.wagon.valid and c.wagon.position.y) or -1
 local tail=(c.extra and c.extra[#c.extra]) or c.second_real or c.other
 local span=(r and r.valid and tail and tail.valid) and math.abs(tail.position.y-r.position.y) or -1
 return 'tid='..t.id..'|carriages='..#t.carriages..'|real='..nl..'|motor='..nm..'|helpers='..nh..'|helperW='..p..'|engineLocos='..numl..'|baseY='..string.format('%.6f',baseY)..'|visibleSpan='..string.format('%.6f',span)..'|stock='..table.concat(parts,',')
end
local function setup()
 local s=game.surfaces[1]
 s.request_to_generate_chunks({140,0},20);s.force_generate_chunk_requests()
 for _,def in ipairs(CASES)do
  local x=def.x
  for y=-360,360,2 do s.create_entity{name='straight-rail',position={x=x,y=y},force='player',direction=defines.direction.north}end
  local c={x=x,kind=def.kind,id=def.id}
  if def.kind=='solo' then
   c.wagon=s.create_entity{name='em-c4-motor-cargo',position={x=x,y=0},force='player',direction=defines.direction.north}
   c.other=s.create_entity{name='em-c4-motor-fluid',position={x=x,y=7},force='player',direction=defines.direction.north}
  else
   c.real=s.create_entity{name=def.kind=='vanilla' and 'locomotive' or 'em-c4-real-electric',position={x=x,y=0},force='player',direction=defines.direction.north}
   local nm=def.kind=='em4' and 4 or def.kind=='em2' and 2 or def.kind=='em1' and 1 or def.kind=='vanilla' and 2 or def.kind=='multi' and 2 or 0
   c.motor_count=nm
   c.wagon=s.create_entity{name=nm>0 and 'em-c4-motor-cargo' or 'cargo-wagon',position={x=x,y=7},force='player',direction=defines.direction.north}
   if nm>1 then c.other=s.create_entity{name='em-c4-motor-fluid',position={x=x,y=14},force='player',direction=defines.direction.north}
   else c.other=s.create_entity{name='fluid-wagon',position={x=x,y=14},force='player',direction=defines.direction.north}end
   if nm>2 then
    c.extra={}
    for idx=3,nm do c.extra[#c.extra+1]=s.create_entity{name='em-c4-motor-cargo',position={x=x,y=7*idx},force='player',direction=defines.direction.north}end
   end
  end
  if def.id=='change' then
   c.initial_cargo_unit=c.wagon.unit_number;c.initial_fluid_unit=c.other.unit_number
   local inv=c.wagon.get_inventory(defines.inventory.cargo_wagon)
   local inserted=inv.insert{name='iron-plate',count=37}
   c.other.set_fluid(1,{name='water',amount=9000})
   out('cargo_fill','units='..c.initial_cargo_unit..','..c.initial_fluid_unit..'|inserted='..inserted..'|fluid='..(c.other.get_fluid(1) and c.other.get_fluid(1).amount or -1))
  end
  if def.id=='multi' or def.id=='multi_owner_removed' then
   c.second_real=s.create_entity{name='em-c4-real-electric',position={x=x,y=21},force='player',direction=defines.direction.south}
  end
  assert(c.wagon and c.wagon.valid)
  if def.kind~='solo' then assert(c.real and c.real.valid)end
  storage[def.id]=c
  out('before','case='..def.id..'|'..stats(c))
 end
 local stop=s.create_entity{name='train-stop',position={x=162,y=-100},force='player',direction=defines.direction.north}
 out('route_stop','placed='..tostring(stop~=nil)..'|rail='..tostring(stop and stop.connected_rail~=nil))
 assert(stop and stop.connected_rail,'real native station connection needed for routing')
 stop.backer_name='EM_C4_STATION'
 local lateStop=s.create_entity{name='train-stop',position={x=482,y=-100},force='player',direction=defines.direction.north}
 assert(lateStop and lateStop.connected_rail,'late stop native connection')
 lateStop.backer_name='EM_C4_LATE_STATION'
 -- Need real players cannot place helper; it has no matching item/recipe and it is script-only.
 for _,pow in ipairs({500,1000,2000})do
  local n='em-c4-technical-booster-'..pow
  local p=prototypes.entity[n]
  out('prototype','name='..n..'|exists='..tostring(p~=nil)..'|selectable='..tostring(p.selectable_in_game)..'|mining_time='..tostring(p.mineable_properties and p.mineable_properties.mining_time)..'|item='..tostring(prototypes.item[n]~=nil)..'|type='..p.type..'|kind='..tostring(p.type)..'|blueprint_block='..tostring(p.has_flag('not-blueprintable'))..'|deconstruct_block='..tostring(p.has_flag('not-deconstructable'))..'|not_on_map='..tostring(p.has_flag('not-on-map')))
 end
 out('real_wagon_items','cargo_item='..tostring(prototypes.item['em-c4-motor-cargo']~=nil)..'|fluid_item='..tostring(prototypes.item['em-c4-motor-fluid']~=nil)..'|phantom_item='..tostring(prototypes.item['em-c4-technical-booster-500']~=nil))
end
local function build(c)
 local t=c.real and c.real.valid and c.real.train
 if not t or not t.valid then return false end
 local real,motor=count_real(t)
 if real<1 or motor<1 then return false end
 if c.helper and c.helper.valid then return false end
 local need=500*motor
 if need>2000 then return false end
 local typeName='em-c4-technical-booster-'..need
 -- Only a real EM electric locomotive can authorize creation. A vanilla loco cannot.
 if c.real.name~='em-c4-real-electric' then return false end
 if t.speed~=0 then return false end
 local originalAuto=not t.manual_mode
 local originalSchedule=t.schedule
 storage.c4_doing_own_insertion=true
 local disconnected=c.real.disconnect_rolling_stock(defines.rail_direction.back)
 local midx=(c.real.position.x+c.wagon.position.x)/2
 local midy=(c.real.position.y+c.wagon.position.y)/2
 local phantom=c.real.surface.create_entity{name=typeName,position={x=midx,y=midy},force='player',direction=defines.direction.north}
 c.helper=phantom
 c.helper_owner_unit=c.real.unit_number
 storage.c4_doing_own_insertion=nil
 if c.real.valid and c.real.train and c.real.train.valid then
  local joined=c.real.train
  if originalSchedule then joined.schedule=originalSchedule end
  if originalAuto then joined.manual_mode=false end
  out('mode_restored','case='..c.id..'|auto_before='..tostring(originalAuto)..'|manual_after='..tostring(joined.manual_mode)..'|schedule='..tostring(joined.schedule and joined.schedule.records and joined.schedule.records[1].station))
 end
 if phantom then
  phantom.minable_flag=false
  phantom.destructible=false
  if c.id~='change' and c.id~='zero' then
   phantom.burner.currently_burning=prototypes.item['em-c4-internal-joule']
   phantom.burner.remaining_burning_fuel=10000000 -- C4 LAB ONLY, NOT source-backed
  end
  out('helper_policy','case='..c.id..'|selectable='..tostring(phantom.prototype.selectable_in_game)..'|minable_flag='..tostring(phantom.minable_flag)..'|burner_j='..tostring(phantom.burner.remaining_burning_fuel)..'|item='..tostring(prototypes.item[typeName]~=nil))
 end
 out('spawn' ,'case='..c.id..'|disconnected='..tostring(disconnected)..'|created='..tostring(phantom and phantom.valid)..'|'..stats(c))
 assert(phantom and phantom.valid,'creation of owner-only helper failed')
 assert(phantom.train.id==c.real.train.id,'not physically in main locomotive train')
 return true
end
script.on_event(defines.events.on_train_created,function(ev)
 local t=ev.train
 local nr,nh=0,0
 if t and t.valid then nr=count_real(t);nh=count_helper(t) end
 if not storage.c4_doing_own_insertion and t and t.valid and nr==0 and nh>0 then
  t.manual_mode=true
  out('orphan_quarantine','tick='..game.tick..'|train='..t.id..'|helper='..nh..'|manual='..tostring(t.manual_mode))
 end
 out('train_created','tick='..game.tick..'|id='..(t and t.valid and t.id or -1)..'|old1='..tostring(ev.old_train_id_1)..'|old2='..tostring(ev.old_train_id_2)..'|real='..tostring(nr))
end)
script.on_event(defines.events.on_tick,function(ev)
 local tick=ev.tick
 if tick==2 then setup() end
 if tick==6 then
  local c=storage.em2
  assert(build(c),'auto route must attach booster while physically stopped BEFORE departure')
  out('pre_departure_boost','case=em2|'..stats(c))
 end
 if tick==7 then
  local c=storage.em2
  local t=c.real.train
  local ok,why=pcall(function()
   t.schedule={current=1,records={{station='EM_C4_STATION',wait_conditions={{type='time',compare_type='and',ticks=300}}}}}
   t.manual_mode=false
  end)
  local c2=storage.late
  local t2=c2.real.train
  t2.schedule={current=1,records={{station='EM_C4_LATE_STATION',wait_conditions={{type='time',compare_type='and',ticks=400}}}}}
  t2.manual_mode=false
  out('late_schedule_initial','mode='..tostring(t2.manual_mode)..'|station='..tostring(t2.schedule.records[1].station))
  out('schedule_initial','ok='..tostring(ok)..'|error='..tostring(why)..'|mode='..tostring(t.manual_mode)..'|record='..tostring(t.schedule and t.schedule.records and t.schedule.records[1].station))
 end
 if tick==10 then
  for _,id in ipairs({'solo','vanilla','em0','em1','em2','em4','remove','change','multi','zero','em2drive','multi_owner_removed','late'})do
   local c=storage[id]
   if c.real and c.real.valid and c.real.name=='em-c4-real-electric' and not (c.helper and c.helper.valid) then build(c)end
   out('after','case='..id..'|'..stats(c))
   if c.wagon and c.wagon.valid then out('wagon_native_type','case='..id..'|cargo='..c.wagon.type..'|fluid='..(c.other and c.other.valid and c.other.type or 'none')) end
   if id=='em2' then
    local t=c.real.train
    out('schedule_after','mode='..tostring(t.manual_mode)..'|record='..tostring(t.schedule and t.schedule.records and t.schedule.records[1].station))
   end
  end
 end
 if tick==15 then
  for _,id in ipairs({'vanilla','em0','em1','em2','em4','zero','em2drive'})do
   local c=storage[id];local p=c.real
   if p and p.valid then
    local driver=p.surface.create_entity{name='character',position=p.position,force='player'}
    if driver then p.set_driver(driver);driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}end
   end
  end
 end
 if tick==70 then
  local c=storage.multi_owner_removed
  out('multi_owner_before','case=multi_owner_removed|owner='..tostring(c.helper_owner_unit)..'|'..stats(c))
  c.real.destroy()
  out('multi_owner_destroyed','case=multi_owner_removed|second_valid='..tostring(c.second_real.valid)..'|'..stats(c))
 end
 if tick==71 then
  local c=storage.multi_owner_removed
  local t=c.wagon.train
  local nl,nm=count_real(t);local nh=count_helper(t)
  assert(nl==1 and nh==1,'expected one remaining real loco and one helper')
  -- Key safety contract: booster's owner died, even though another real loco still exists.
  if not c.real.valid and c.helper and c.helper.valid then c.helper.destroy();c.helper=nil end
  out('multi_owner_cleanup','case=multi_owner_removed|'..stats(c))
 end
 if tick==70 then
  local c=storage.remove
  out('pre_remove','case=remove|'..stats(c))
  local e=c.real; c.real_id=e.unit_number
  e.destroy()
  out('after_original_destroy','case=remove|'..stats(c))
 end
 if tick==71 then
  local c=storage.remove
  local t=c.wagon.train
  local nl,nm=count_real(t);local nh=count_helper(t)
  out('orphan_before_gc','real='..nl..'|motor='..nm..'|helpers='..nh)
  if nl==0 then
   local toDestroy={}
   for _,u in ipairs(t.carriages)do if u.name:find('^em%-c4%-technical%-booster%-') then toDestroy[#toDestroy+1]=u end end
   for _,u in ipairs(toDestroy)do u.destroy() end
  end
  out('after_gc','case=remove|'..stats(c))
  out('removed_orphan_mode','manual='..tostring(c.wagon.train.manual_mode))
 end
 if tick==80 then
  local c=storage.change
  storage.c4_doing_own_insertion=true
  local detached=c.wagon.disconnect_rolling_stock(defines.rail_direction.back)
  assert(detached,'change: failed to detach motor fluid')
  assert(c.helper and c.helper.valid)
  c.helper.destroy();c.helper=nil
  c.real.connect_rolling_stock(defines.rail_direction.back)
  storage.c4_doing_own_insertion=nil
  out('change_detached','case=change|fluid='..tostring(c.other.valid)..'|'..stats(c))
  assert(build(c),'change: failed rebuild lower power')
  out('change_low','case=change|'..stats(c))
 end
 if tick==90 then
  local c=storage.change
  out('change_t90','case=change|'..stats(c))
 end
 if tick==111 then
  local c=storage.change
  storage.c4_doing_own_insertion=true
  if c.helper and c.helper.valid then c.helper.destroy() end;c.helper=nil
  c.real.connect_rolling_stock(defines.rail_direction.back)
  local j=c.wagon.connect_rolling_stock(defines.rail_direction.back)
  storage.c4_doing_own_insertion=nil
  out('change_rejoin','case=change|joined='..tostring(j)..'|'..stats(c))
  assert(build(c),'change: failed rebuild higher power')
  out('change_high','case=change|'..stats(c))
  local ci=c.wagon.get_inventory(defines.inventory.cargo_wagon)
  out('cargo_persist','cargo_unit_same='..tostring(c.wagon.unit_number==c.initial_cargo_unit)..'|fluid_unit_same='..tostring(c.other.unit_number==c.initial_fluid_unit)..'|iron='..ci.get_item_count('iron-plate')..'|water='..(c.other.get_fluid(1) and c.other.get_fluid(1).amount or -1))
 end
 if tick==80 then
  local s=storage.solo
  local t=s.wagon.train
  local l,m=count_real(t);local h=count_helper(t)
  out('solo_check','real='..l..'|motor='..m..'|helpers='..h..'|native_locomotives='..(#t.locomotives.front_movers+#t.locomotives.back_movers))
 end
 if tick==300 then
  local c=storage.late
  local t=c.real.train
  out('late_before_mount','mode='..tostring(t.manual_mode)..'|speed='..tostring(t.speed)..'|station='..tostring(t.station~=nil)..'|'..stats(c))
  if t.station and t.speed==0 then
   local ok=build(c)
   out('late_after_mount','ok='..tostring(ok)..'|'..stats(c)..'|mode='..tostring(c.real.train.manual_mode)..'|schedule='..tostring(c.real.train.schedule and c.real.train.schedule.records[1].station))
  end
 end
 if tick==190 or tick==280 or tick==350 then
  local c=storage.em2
  local t=c.real.train
  local tl=storage.late.real.train
  out('late_arrival','tick='..tick..'|mode='..tostring(tl.manual_mode)..'|station='..tostring(tl.station~=nil)..'|speed='..tostring(tl.speed)..'|helpers='..count_helper(tl)..'|pos='..tostring(storage.late.real.position.y))
  out('auto_arrival','tick='..tick..'|mode='..tostring(t.manual_mode)..'|schedule='..tostring(t.schedule and t.schedule.records[1].station)..'|at_station='..tostring(t.station~=nil)..'|state='..tostring(t.state)..'|distance='..tostring(c.real.position.y))
  local c=storage.change
  local iron=c.wagon.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')
  local water=c.other.get_fluid(1) and c.other.get_fluid(1).amount or 0
  out('cargo_final','cargo_unit_same='..tostring(c.wagon.unit_number==c.initial_cargo_unit)..'|fluid_unit_same='..tostring(c.other.unit_number==c.initial_fluid_unit)..'|iron='..iron..'|water='..water)
 end
 if tick==60 or tick==110 or tick==190 then
  if tick==190 then
   for _,id in ipairs({'em1','em2','em4','zero','em2drive'})do
    local c=storage[id]
    out('energy_remaining','case='..id..'|J='..tostring(c.helper.burner.remaining_burning_fuel))
   end
  end
  for _,id in ipairs({'vanilla','em0','em1','em2','em4','zero','em2drive'})do
   local c=storage[id]
   out('motion','tick='..tick..'|case='..id..'|'..stats(c))
  end
 end
 if tick==125 then
  local ok,res=pcall(function()game.server_save('em-c4-probe-checkpoint')end)
  out('save','tick=125|ok='..tostring(ok)..'|result='..tostring(res))
 end
end)