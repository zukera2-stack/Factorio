local N=tonumber(script.test_arg) or 1
local function ck(x,m)if not x then error('[MOVING FAIL] '..N..' '..m)end end
local function say(m)log('[MOVING] '..N..' '..m)end
local function create(s,name,x,y,dir)
 local e=s.create_entity{name=name,position={x=x,y=y},force='player',direction=dir or defines.direction.west,raise_built=true};ck(e and e.valid,'create '..name..' '..x..','..y);return e
end
local function stop_at(s,x,y,i)
 for _,dy in ipairs({-2,2,0}) do for _,d in ipairs({defines.direction.west,defines.direction.east}) do local a=s.create_entity{name='train-stop',position={x=x,y=y+dy},direction=d,force='player',raise_built=true};if a and a.valid and a.connected_rail then a.backer_name='MOVING_'..i;return a end;if a and a.valid then a.destroy()end end end
 error('[MOVING FAIL] no station '..i)
end
script.on_init(function()
 local s=game.create_surface('moving-'..N,{width=512,height=math.ceil((N*40+128)/32)*32});s.generate_with_lab_tiles=true;s.always_day=true
 for i=1,N do local y=(i-1-math.floor(N/2))*40+1;for x=-120,100,96 do s.request_to_generate_chunks({x,y},2)end end;s.force_generate_chunk_requests()
 storage.st={}
 for i=1,N do
  local y=(i-1-math.floor(N/2))*40+1
  for x=-120,100,2 do create(s,'em-high-speed-straight-rail',x,y,defines.direction.east)end
  for x=-101.5,96,20 do create(s,'em-35kv-catenary-pole',x,y+1.5,defines.direction.east)end
  local sub=create(s,'em-35kv-traction-substation',-20,y+8,defines.direction.east)
  local g=create(s,'electric-energy-interface',-20,y+12,defines.direction.east);g.electric_interface_mode=defines.electric_interface_mode.primary_output;g.electric_buffer_size=10000000;g.power_production=20000000/60;g.power_usage=0;g.output_flow_limit=20000000/60;g.input_flow_limit=0;g.energy=0
  local l=create(s,'em-electric-locomotive',0,y,defines.direction.west)
  local c=create(s,'em-motor-cargo-wagon',7,y,defines.direction.west);local f=create(s,'em-motor-fluid-wagon',14,y,defines.direction.west)
  ck(c.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo '..i);ck(f.insert_fluid{name='water',amount=9000}==9000,'fluid '..i)
  ck(#l.train.carriages==3,'initial coupled '..i);local stop=stop_at(s,-80,y,i)
  storage.st[i]={loco=l,cargo=c,fluid=f,stop=stop,start=l.position.x}
 end
end)
local function check(r,i,ids)
 local tr=r.loco.train;ck(tr and tr.valid and #tr.carriages==4,'train/stock '..i);ck(r.cargo.valid and r.fluid.valid and r.cargo.train.id==tr.id and r.fluid.train.id==tr.id,'detached '..i)
 ck(r.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and r.fluid.get_fluid_count('water')==9000,'payload '..i)
 local h
 for _,e in ipairs(tr.carriages)do if e.name=='em-c5-technical-booster-1000' then ck(not h,'duplicate helper '..i);h=e end end
 ck(h and not h.operable and not h.minable_flag and not h.destructible,'helper '..i)
 ck(remote.call('em072_native_qa_071','snapshot',h.unit_number).owner==r.loco.unit_number,'owner '..i)
 if ids then ck(h.unit_number==r.helper,'helper changed '..i) else r.helper=h.unit_number end
 return tr
end
script.on_event(defines.events.on_tick,function(e)
 local t=e.tick
 if t==120 then
  for i,r in ipairs(storage.st) do local tr=check(r,i,false);tr.schedule={current=1,records={{station=r.stop.backer_name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false end
  say('dispatch '..N)
 elseif t>=121 then
  local moving,visited,dist=0,0,0
  for i,r in ipairs(storage.st)do
   local tr=r.loco.train;ck(tr and tr.valid,'moving lost train '..i)
   if math.abs(tr.speed)>0.01 then r.moved=true;moving=moving+1 end
   if tr.station and tr.station.valid and tr.station==r.stop then r.visited=true end
   if r.visited then visited=visited+1 end
   dist=dist+math.abs(r.loco.position.x-r.start)
  end
  storage.peak=math.max(storage.peak or 0,moving)
  if t==240 or t==360 or t==500 then say('tick='..t..' moving='..moving..' visited='..visited..' distance_sum='..dist) end
  if t==500 then
   for i,r in ipairs(storage.st)do local tr=check(r,i,true);ck(r.moved and r.visited,'not reached stop '..i..' state='..tostring(tr.state))end
   ck(storage.peak==N,'not simultaneous '..storage.peak);local q=remote.call('em072_native_qa_071','snapshot');ck(q.motor_paid_J>0 and q.paid_J>=q.motor_paid_J,'paid ledger');say('PASS simultaneous='..storage.peak..' visited='..visited..' sum_distance='..dist..' paid_J='..q.paid_J..' motor_paid_J='..q.motor_paid_J);script.finish_test(true)
  end
 end
end)
