local mode=script.test_arg or 'station2000'
local power=2000
local highL=not mode:find('wagononly')
local highW=not mode:find('locoonly')
local B=(highL and 20 or .001)+(highW and 20 or .001)
local function ck(x,m)if not x then error('[BRAKE FAIL] '..mode..' '..m)end end
local function make(s,n,x,y,o)local p={name=n,position={x=x,y=y},force='player'};for k,v in pairs(o or {})do p[k]=v end;local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e end
local function stop(s,x)
 for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do local q=s.create_entity{name='train-stop',position={x=x,y=1+dy},direction=d,force='player'};if q and q.valid and q.connected_rail then q.backer_name='DEST';return q elseif q and q.valid then q.destroy()end end end
 error('stop')
end
script.on_init(function()
 local s=game.create_surface('brake-lab',{width=2048,height=128});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-800,80,64 do s.request_to_generate_chunks({x=x,y=0},2)end;s.force_generate_chunk_requests()
 for x=-800,80,2 do make(s,'straight-rail',x,1,{direction=defines.direction.east})end
 local a=make(s,'em090-cal-loco-'..(highL and 'high' or 'low'),0,1,{direction=defines.direction.west})
 local wagon=make(s,'em090-cal-wagon-'..(highW and 'high' or 'low'),7,1,{direction=defines.direction.west});wagon.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=2000};ck(a.train.id==wagon.train.id and a.train.weight==3000,'same mass/consist');log(string.format('[CAL] mass=%.6f locoB=%.6f wagonB=%.6f friction=%.6f air=%.6f',a.train.weight,a.prototype.braking_force,wagon.prototype.braking_force,a.prototype.friction_force+wagon.prototype.friction_force,a.prototype.air_resistance))
 local dest=stop(s,not mode:find('auto') and -700 or -350)
 local b=a.burner;b.currently_burning=prototypes.item['em090-finite-fuel'];b.remaining_burning_fuel=20000000
 local st={a=a,dest=dest,prev=0,prev_J=20000000,initial=20000000,cut=0,brake=0,coast=0,negative=0,maxv=0,max_ratio=0,brake_err=0,moving=0}
 storage.st=st
 if mode:find('bonus') then game.forces.player.train_braking_force_bonus=1 end
 log('[BRAKE ENUM] '..serpent.line(defines.riding.acceleration)..' '..serpent.line(defines.train_state))
 a.train.schedule={current=1,records={{station='DEST',wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};a.train.manual_mode=false
end)
script.on_event(defines.events.on_entity_damaged,function(ev) local st=storage.st;if st then st.damage=(st.damage or 0)+ev.final_damage_amount;log('[DAMAGE] '..ev.entity.name..' '..ev.final_damage_amount..' tick='..game.tick)end end)
script.on_event(defines.events.on_tick,function(ev)
 local st=storage.st;local a=st.a;local t=ev.tick;local tr=a.train;local v=math.abs(tr.speed);local j=a.burner.remaining_burning_fuel;local r=tr.riding_state.acceleration;local d=st.prev-v;local loss=0.5*tr.weight*3600*(st.prev^2-v^2);local consumed=st.initial-j-st.cut
 if v>0 then st.moving=st.moving+1 end
 if v>st.maxv then st.maxv=v end
 if consumed>0 then st.max_ratio=math.max(st.max_ratio,0.5*tr.weight*3600*v*v/consumed) end
 if d>1e-8 then
  st.negative=st.negative+1
  if r==defines.riding.acceleration.braking then st.brake=st.brake+1;local f=B*(1+game.forces.player.train_braking_force_bonus);st.brake_err=math.max(st.brake_err,math.abs(d-math.min(st.prev,f/tr.weight))) else st.coast=st.coast+1 end
 end
 log(string.format('[TRACE] %d %.12f %.6f %d %d %.6f %.6f %.6f %.6f %d',t,v,j,r,tr.state,tr.weight,a.position.x,a.health,loss,tr.id))
 if not mode:find('auto') and not mode:find('coast') and t==120 then tr.manual_mode=true;log('[MANUAL SWITCH]') end
 if mode:find('collision') and t==180 then local o=make(a.surface,'tank',math.floor(a.position.x)-8,1,{direction=defines.direction.north});st.obstacle=o;log('[OBSTACLE] '..o.unit_number) end
 if mode:find('coast') and t==120 then st.cut=j;a.burner.remaining_burning_fuel=0;log('[CUT] '..j) end
 st.prev=v;st.prev_J=j
 if t==900 or (tr.station==st.dest and t>100) then
  ck(st.moving>20,'no movement');ck(st.negative>0,'no deceleration');if mode:find('auto') then ck(tr.station==st.dest,'no arrival') elseif not mode:find('coast') then ck(v==0,'manual stop did not finish') end; if mode:find('collision') then ck(st.damage and st.damage>0,'no collision damage')end
  log(string.format('[RESULT] %s t=%d maxv=%.9f ratio=%.9f neg=%d brake=%d other=%d max_brake_err=%.12f consumed=%.6f cut=%.6f arrived=%s',mode,t,st.maxv,st.max_ratio,st.negative,st.brake,st.coast,st.brake_err,consumed,st.cut,tostring(tr.station==st.dest)));script.finish_test(true)
 end
end)
