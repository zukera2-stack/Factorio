local N=50
local W=2
local function ck(b,m) if not b then error('[EM087 FAIL] '..m) end end
local function create(s,name,x,y,dir)
 local e=s.create_entity{name=name,position={x=x,y=y},force='player',direction=dir or defines.direction.west,raise_built=true}
 ck(e and e.valid,'create '..name..' '..x..','..y);return e
end
script.on_init(function()
 local xmax=math.max(100,7*(W+1)+40)
 local s=game.create_surface('em087-bench-'..N..'-'..W,{width=math.ceil((2*xmax+256)/32)*32,height=math.ceil((N*80+128)/32)*32})
 s.generate_with_lab_tiles=true;s.always_day=true
 for i=1,N do local y=(i-1)*40-math.floor(N/2)*40+1
  for x=-100,xmax,128 do s.request_to_generate_chunks({x=x,y=y},2) end
 end
 s.force_generate_chunk_requests()
 storage.locos={};storage.wagons={};storage.subs={};storage.gen={}
 for i=1,N do
  local y=(i-1)*40-math.floor(N/2)*40+1
  for x=-100,xmax,2 do create(s,'em-high-speed-straight-rail',x,y,defines.direction.east) end
  for x=-81.5,xmax-4,20 do create(s,'em-35kv-catenary-pole',x,y+1.5,defines.direction.east) end
  storage.subs[i]=create(s,'em-35kv-traction-substation',-20,y+8,defines.direction.east)
  local g=create(s,'electric-energy-interface',-20,y+12,defines.direction.east)
  g.electric_interface_mode=defines.electric_interface_mode.primary_output
  g.electric_buffer_size=10000000;g.power_production=20000000/60;g.power_usage=0;g.output_flow_limit=20000000/60;g.input_flow_limit=0;g.energy=0
  storage.gen[i]=g
  local loco=create(s,'em-electric-locomotive',0,y,defines.direction.west)
  storage.locos[i]=loco
  local first=nil
  for j=1,W do local w=create(s,j%2==0 and 'em-motor-fluid-wagon' or 'em-motor-cargo-wagon',j*7,y,defines.direction.west); if j==1 then first=w end end
  if first then storage.wagons[i]=first;ck(first.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo') end
  ck(#loco.train.carriages==W+1,'initial coupling')
 end
 game.speed=10
 log('[EM087 SETUP] trains='..N..' motors='..W..' stations='..N)
end)
script.on_event(defines.events.on_tick,function(e)
 if e.tick<120 or (e.tick~=120 and e.tick%600~=0) then return end
 local cars,helpers,j=0,0,0
 for i,l in ipairs(storage.locos) do
  ck(l.valid and l.train.valid,'invalid train '..i)
  local expected=math.ceil(W/200)
  local count=0
  for _,c in ipairs(l.train.carriages) do
   if c.name:find('^em%-c5%-technical%-booster%-') then count=count+1;ck(not c.operable and not c.minable_flag and not c.destructible,'helper exposure') end
  end
  ck(count==expected,'helper count '..i..' got '..count..' expected '..expected)
  ck(#l.train.carriages==W+1+expected,'carriage count')
  if W>0 then ck(storage.wagons[i].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost') end
  cars=cars+#l.train.carriages;helpers=helpers+count;j=j+(l.burner.remaining_burning_fuel or 0)
 end
 local snap=remote.call('em072_native_qa_071','snapshot')
 log(string.format('[EM087 SNAP] tick=%d trains=%d cars=%d helpers=%d loco_J=%.3f paid_J=%.3f motor_paid_J=%.3f',e.tick,N,cars,helpers,j,snap.paid_J,snap.motor_paid_J))
 if e.tick==120 then game.auto_save('em087-'..N..'-'..W) end
end)
