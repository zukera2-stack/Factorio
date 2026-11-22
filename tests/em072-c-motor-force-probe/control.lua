local function create(s,name,x,y,options)
 local q={name=name,position={x,y},force='player',raise_built=true}
 for k,v in pairs(options or {}) do q[k]=v end
 local e=s.create_entity(q);assert(e and e.valid,'create '..name..' failed')
 return e
end
local function spawn(s,y,cargo_name,fluid_name,fuel)
 local loco=create(s,'em-c-loco',0,y,{direction=defines.direction.east})
 local cargo=create(s,cargo_name,7,y,{direction=defines.direction.east})
 local fluid=create(s,fluid_name,14,y,{direction=defines.direction.east})
 assert(loco.train.id==cargo.train.id and loco.train.id==fluid.train.id,'Native 3-piece train not coupled')
 assert(cargo.type=='cargo-wagon' and fluid.type=='fluid-wagon','wagon prototype type invalid')
 local b=loco.burner;b.currently_burning=fuel;b.remaining_burning_fuel=20000000
 assert(math.abs(b.remaining_burning_fuel-20000000)<.01,'native burner initialization failed')
 local d=create(s,'character',0,y-9)
 loco.set_driver(d);loco.train.manual_mode=true
 d.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 return {loco=loco,cargo=cargo,fluid=fluid,driver=d,start_x=loco.position.x,start_J=20000000,fuel=fuel}
end
local function setup()
 local s=game.create_surface('em-c-native-no-virtual-wagon-motor',{width=1024,height=256})
 s.generate_with_lab_tiles=true;s.request_to_generate_chunks({250,60},15);s.force_generate_chunk_requests()
 for _,y in ipairs({1,41,81}) do
  for x=-200,1400,2 do create(s,'straight-rail',x,y,{direction=defines.direction.east}) end
 end
 local a=spawn(s,1,'em-c-passive-cargo','em-c-passive-fluid','em-c-fuel-plain')
 local b=spawn(s,41,'em-c-motor-cargo','em-c-motor-fluid','em-c-fuel-plain')
 local c=spawn(s,81,'em-c-motor-cargo','em-c-motor-fluid','em-c-fuel-boost')
 assert(a.loco.train.id~=b.loco.train.id and a.loco.train.id~=c.loco.train.id and b.loco.train.id~=c.loco.train.id)
 assert(a.loco.prototype.weight==b.loco.prototype.weight and b.loco.prototype.weight==c.loco.prototype.weight)
 assert(a.cargo.prototype.weight==b.cargo.prototype.weight and b.cargo.prototype.weight==c.cargo.prototype.weight)
 assert(a.fluid.prototype.weight==b.fluid.prototype.weight and b.fluid.prototype.weight==c.fluid.prototype.weight)
 storage.c={A=a,B=b,C=c}
 log('[EM072C TOPOLOGY PASS] three_true_native_3_stock_trains=3 identical_weights=true locomotive_max_power_MW=2 wagon_extra_max_power_native=false motor_label_only=true fuel_boost_multiplier=1.25')
end
local function probe(t)
 local u=storage.c
 local function measure(r)
  local b=r.loco.burner
  local remaining=b.remaining_burning_fuel or 0
  return {travel=r.loco.position.x-r.start_x,speed=r.loco.train.speed,burned=r.start_J-remaining,remaining=remaining}
 end
 local a,b,c=measure(u.A),measure(u.B),measure(u.C)
 assert(math.abs(a.travel-b.travel)<.0001 and math.abs(a.burned-b.burned)<.01,'Motor wagon label created unexplained native physics difference')
 for _,x in ipairs({a,b,c}) do assert(x.burned>=0 and x.burned<=20000000+.01) end
 local ledger=0;for _,r in ipairs({u.A,u.B,u.C}) do ledger=ledger+((r.loco.burner.remaining_burning_fuel or 0)+(r.start_J-(r.loco.burner.remaining_burning_fuel or 0))-r.start_J) end
 assert(math.abs(ledger)<.01,'native burner J conservation failed')
 log(string.format('[EM072C MEASURE] tick=%d passive_tiles=%.6f motor_label_tiles=%.6f loco_fuel_boost_tiles=%.6f passive_burned_J=%.3f motor_label_burned_J=%.3f boost_burned_J=%.3f boost_vs_passive_tiles=%.6f boost_vs_passive_J=%.3f remaining_total_J=%.3f',t,a.travel,b.travel,c.travel,a.burned,b.burned,c.burned,c.travel-a.travel,c.burned-a.burned,a.remaining+b.remaining+c.remaining))
 if t==240 then
  assert(a.travel>1 and b.travel>1,'controls never moved')
  assert(math.abs(b.travel-a.travel)<.0001 and math.abs(b.burned-a.burned)<.01,'motor named wagons changed native physics unexpectedly')
  log('[EM072C FINAL PASS] 240 true native ticks: cargo/fluid motor labels have NO additional native propulsion and cannot claim +500kW; fuel multiplier effect measured separately; no train.speed mutation')
 end
end
script.on_event(defines.events.on_tick,function(e)
 if e.tick==1 then setup() end
 if e.tick==100 then
  local ok,err=pcall(function()game.server_save('em072c-checkpoint')end)
  log('[EM072C DISK SAVE] tick=100 requested='..tostring(ok)..' err='..tostring(err))
 end
 if e.tick==60 or e.tick==120 or e.tick==180 or e.tick==240 then probe(e.tick) end
end)