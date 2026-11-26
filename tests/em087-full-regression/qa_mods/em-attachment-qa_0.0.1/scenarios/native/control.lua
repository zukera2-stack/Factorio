local CASE=script.test_arg or 'dual'
local N=(CASE=='grow' and 200 or CASE=='shrink' and 201 or 4)
local DUAL=CASE=='dual' or CASE=='same' or CASE=='bidir'
local function ck(b,m) if not b then error('[ATTACH FAIL] '..CASE..' '..m) end end
local function say(m) log('[ATTACH] '..CASE..' '..m) end
local function create(s,name,x,y,dir)
 local e=s.create_entity{name=name,position={x=x,y=y},direction=dir or defines.direction.west,force='player',raise_built=true}
 ck(e and e.valid,'create '..name..' at '..x);return e
end
local function ishelper(e) return e.name:match('^em%-c5%-technical%-booster%-%d+$')~=nil end
local function j(e) return e.burner and e.burner.remaining_burning_fuel or 0 end
local function verify(st,n,ndirs)
 local tr=st.loco.train
 ck(tr and tr.valid,'invalid train')
 local owners,actual={},{}
 local needed={}
 for i=1,math.floor(n/200) do needed[#needed+1]=100000 end
 if n%200>0 then needed[#needed+1]=(n%200)*500 end
 local expected={};for i=1,ndirs do for _,kw in ipairs(needed) do expected[#expected+1]=kw end end;table.sort(expected)
 local visible=0;local real_j=0;local helper_j=0
 for _,e in ipairs(tr.carriages) do
  if ishelper(e) then
   actual[#actual+1]=tonumber(e.name:match('(%d+)$'))
   local owner=remote.call('em072_native_qa_071','snapshot',e.unit_number).owner
   ck(owner and (owner==st.loco.unit_number or (st.second and owner==st.second.unit_number)),'not real owner')
   owners[owner]=(owners[owner] or 0)+1
   ck(e.operable==false and e.minable_flag==false,'helper exposed')
   helper_j=helper_j+j(e)
  else visible=visible+1;if e.name=='em-electric-locomotive' then real_j=real_j+j(e) end end
 end
 table.sort(actual);ck(#actual==#expected,'wrong helper count '..#actual..' expected '..#expected)
 for i,v in ipairs(expected)do ck(actual[i]==v,'wrong power '..actual[i]..' expected '..v) end
 local nowners=0;for _,c in pairs(owners) do nowners=nowners+1;ck(c==#needed,'wrong blocks per owner') end
 ck(nowners==ndirs,'wrong owners '..nowners)
 ck(visible==n+1+(DUAL and 1 or 0),'visible count changed')
 for i,w in ipairs(st.wagons) do ck(w.valid and w.train.id==tr.id,'detached wagon '..i);ck(math.abs(w.position.x-i*7)<.001,'wagon moved '..i) end
 ck(st.wagons[1].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost')
 ck(st.wagons[2].get_fluid_count('water')==9000,'fluid lost')
 local groups=tr.locomotives;local ng=0
 for _,heading in ipairs({'front_movers','back_movers'}) do
  local real=0;local nh=0
  for _,e in ipairs(groups[heading]) do if e.name=='em-electric-locomotive' then real=real+1;ck(j(e)>0,'real loco no fuel') elseif ishelper(e) then nh=nh+1 end end
  if real>0 then ng=ng+1;ck(nh==#needed,'wrong native heading helper count') else ck(nh==0,'helper in unauthorized heading') end
 end
 ck(ng==ndirs,'wrong direction count')
 say('n='..n..' headings='..ng..' helpers='..table.concat(actual,',')..' real_J='..real_j..' helper_J='..helper_j..' visible='..visible)
end
script.on_init(function()
 local xmax=math.max(260,7*(N+3)+80)
 local s=game.create_surface('attachment-'..CASE,{width=math.ceil((xmax+400)/32)*32,height=256})
 s.generate_with_lab_tiles=true;s.always_day=true
 for x=-200,xmax,128 do s.request_to_generate_chunks({x=x,y=0},2) end;s.force_generate_chunk_requests()
 for x=-200,xmax,2 do create(s,'em-high-speed-straight-rail',x,1,defines.direction.east) end
 for x=-181.5,xmax-4,20 do create(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east) end
 create(s,'em-35kv-traction-substation',-20,9,defines.direction.east)
 local gen=create(s,'electric-energy-interface',-20,13,defines.direction.east)
 gen.electric_interface_mode=defines.electric_interface_mode.primary_output;gen.electric_buffer_size=10000000;gen.power_production=20000000/60;gen.power_usage=0;gen.output_flow_limit=20000000/60;gen.input_flow_limit=0;gen.energy=0
 local loco=create(s,'em-electric-locomotive',0,1,defines.direction.west)
 local wagons={};for i=1,N do wagons[i]=create(s,i%2==0 and 'em-motor-fluid-wagon' or 'em-motor-cargo-wagon',i*7,1,defines.direction.west) end
 ck(wagons[1].get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo insert');ck(wagons[2].insert_fluid{name='water',amount=9000}==9000,'water insert')
 local second=DUAL and create(s,'em-electric-locomotive',(N+1)*7,1,(CASE=='dual' or CASE=='bidir') and defines.direction.east or defines.direction.west) or nil
 ck(#loco.train.carriages==N+1+(DUAL and 1 or 0),'initial coupling')
 storage.qa={loco=loco,second=second,wagons=wagons,n=N}
 if CASE=='bidir' then
  local function stop_at(x,ys,dirs,name)
   for _,dy in ipairs(ys) do for _,d in ipairs(dirs) do
    local a=s.create_entity{name='train-stop',position={x=x,y=1+dy},direction=d,force='player',raise_built=true}
    if a and a.valid and a.connected_rail then a.backer_name=name;return a end
    if a and a.valid then a.destroy() end
   end end
  end
  ck(stop_at(-120,{-2,2,0},{defines.direction.west,defines.direction.east},'ATTACH_LEFT'),'left stop')
  ck(stop_at(100,{2,-2,0},{defines.direction.east,defines.direction.west},'ATTACH_RIGHT'),'right stop')
  storage.qa.visited={};storage.qa.burned={}
 end
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa
 if CASE=='bidir' then
  if e.tick==120 then
   verify(st,N,2)
   st.loco.train.schedule={current=1,records={{station='ATTACH_LEFT',wait_conditions={{type='time',compare_type='and',ticks=60}}},{station='ATTACH_RIGHT',wait_conditions={{type='time',compare_type='and',ticks=60}}}}}
   st.loco.train.manual_mode=false
  elseif e.tick>120 then
   local tr=st.loco.train
   ck(tr and tr.valid,'native train invalid')
   if tr.speed>0.02 then st.forward=true elseif tr.speed< -0.02 then st.reverse=true end
   if math.abs(tr.speed)>0.03 then for _,h in ipairs(tr.carriages) do if ishelper(h) and j(h)<N*500000/120 then st.burned[h.unit_number]=true end end end
   local station=tr.station and tr.station.valid and tr.station.backer_name
   if station and not st.visited[station] then st.visited[station]=true;say('ARRIVED '..station..' tick='..e.tick) end
   if e.tick==1700 then
    ck(st.visited.ATTACH_LEFT and st.visited.ATTACH_RIGHT and st.forward and st.reverse,'both station/direction check')
    local n=0;for _,h in ipairs(tr.carriages) do if ishelper(h) then n=n+1;ck(st.burned[h.unit_number],'helper did not consume native J') end end
    ck(n==2,'helpers lost')
    ck(st.wagons[1].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37 and st.wagons[2].get_fluid_count('water')==9000,'payload lost')
    say('PASS both stations, both native speed signs, both helpers consumed J');script.finish_test(true)
   end
  end
  return
 end
 if e.tick==120 then
  verify(st,N,CASE=='dual' and 2 or 1)
  if CASE=='grow' then st.wagons[N+1]=create(st.loco.surface,'em-motor-cargo-wagon',(N+1)*7,1,defines.direction.west);st.n=N+1
  elseif CASE=='shrink' then ck(st.wagons[N].destroy{raise_destroy=true},'remove last');st.wagons[N]=nil;st.n=N-1
  else say('PASS');script.finish_test(true) end
 elseif e.tick==180 then verify(st,st.n,1);say('PASS');script.finish_test(true) end
end)
