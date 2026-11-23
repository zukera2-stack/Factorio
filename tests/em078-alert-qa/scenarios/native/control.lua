local CASE=script.test_arg or '201'
local N=tonumber(CASE:match('%d+')) or 201
local DUAL=CASE:find('dual')~=nil
local ZERO=CASE:find('zero')~=nil
local RESIZE=CASE:find('resize')~=nil
local OWNERLOSS=CASE:find('loss')~=nil
local HIGH=CASE:find('power')~=nil
local AUTO=CASE:find('auto')~=nil or HIGH
local SAVE=CASE:find('save')~=nil
local DECREASE=CASE:find('decrease')~=nil
local function say(msg) log('[EM077 QA] '..CASE..'|'..msg) end
local function ck(b,msg)if not b then error('[EM077 QA FAIL] '..CASE..' '..msg)end end
local function create(s,name,x,y,dir)
 local e=s.create_entity{name=name,position={x=x,y=y},force='player',direction=dir or defines.direction.west,raise_built=true}
 ck(e and e.valid,'create '..name..' at '..x);return e
end
local function snapshot(st,label)
 local tr=st.loco.valid and st.loco.train
 local ss={}
 local j=0
 if tr and tr.valid then
  for _,e in ipairs(tr.carriages) do
   if e.valid and e.name:find('^em%-c5%-technical%-booster%-') then
    local kw=tonumber(e.name:match('(%d+)$'))
    ss[#ss+1]=kw;j=j+(e.burner and (e.burner.remaining_burning_fuel or 0) or 0)
   end
  end
 end
 table.sort(ss)
 say(string.format('%s|helpers=%s|burner_j=%.3f|train_count=%s|list=%s',label,#ss,j,tr and #tr.carriages or 'nil',table.concat(ss,',')))
 return ss,j
end
local function expect(n,dual)
 local powers={}
 for i=1,math.floor(n/200) do powers[#powers+1]=100000 end
 if n%200>0 then powers[#powers+1]=(n%200)*500 end
 local twice={}
 for i=1,(dual and 2 or 1) do for _,v in ipairs(powers)do twice[#twice+1]=v end end
 table.sort(twice)
 return twice
end
script.on_init(function()
 ck(N>=1 and N<=800,'QA test only 1..800')
 local xmax=math.max(500,7*(N+(DUAL and 2 or 1))+280)
 local s=game.create_surface('em077-'..CASE,{width=math.ceil((xmax+650)/32)*32,height=256})
 s.generate_with_lab_tiles=true;s.always_day=true
 for x=-320,xmax,128 do s.request_to_generate_chunks({x=x,y=0},2) end
 s.force_generate_chunk_requests()
 for x=-340,xmax,2 do create(s,'em-high-speed-straight-rail',x,1,defines.direction.east)end
 if not ZERO then for x=-301.5,xmax-4,20 do create(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east)end end
 local genx=-20
 local supply=ZERO and 0 or 20000000
 if HIGH then
   supply=220000000
   genx=-260
   for i=0,10 do
     create(s,'em-35kv-traction-substation',-260+20*i,9,defines.direction.east)
   end
   for i=0,9 do create(s,'big-electric-pole',-250+20*i,9,defines.direction.east)end
 else
   create(s,'em-35kv-traction-substation',-20,9,defines.direction.east)
   create(s,'em-35kv-traction-substation',20,9,defines.direction.east)
 end
 local gen=create(s,'electric-energy-interface',genx,13,defines.direction.east)
 gen.electric_interface_mode=defines.electric_interface_mode.primary_output
 gen.electric_buffer_size=10000000
 gen.power_production=supply/60
 gen.power_usage=0;gen.output_flow_limit=supply/60;gen.input_flow_limit=0;gen.energy=0
 local loco=create(s,'em-electric-locomotive',0,1,defines.direction.west)
 local wagon={}
 for i=1,N do wagon[i]=create(s,i%2==0 and 'em-motor-fluid-wagon' or 'em-motor-cargo-wagon',i*7,1,defines.direction.west)end
 local second=nil
 if DUAL then second=create(s,'em-electric-locomotive',(N+1)*7,1,defines.direction.east)end
 local cargo=wagon[1].get_inventory(defines.inventory.cargo_wagon)
 ck(cargo.insert{name='iron-plate',count=37}==37,'cargo failed')
 if wagon[2] then ck(wagon[2].insert_fluid{name='water',amount=9000}==9000,'fluid failed') end
 ck(#loco.train.carriages==N+1+(DUAL and 1 or 0),'train not coupled before helper mount')
 storage.qa={loco=loco,second=second,wagon=wagon,gen=gen,expected=expect(N,DUAL),start_x=loco.position.x}
 if AUTO then
   local stop=nil
   for _,dy in ipairs({-2,2,0}) do
     for _,dir in ipairs({defines.direction.west,defines.direction.east}) do
       local maybe=s.create_entity{name='train-stop',position={x=-160,y=1+dy},direction=dir,force='player',raise_built=true}
       if maybe and maybe.valid and maybe.connected_rail then stop=maybe;break end
       if maybe and maybe.valid then maybe.destroy() end
     end
     if stop then break end
   end
   ck(stop,'auto train stop not connected to native HSR')
   stop.backer_name='EM077_AUTOMATIC_STOP'
   loco.train.schedule={current=1,records={{station='EM077_AUTOMATIC_STOP',wait_conditions={{type='time',compare_type='and',ticks=60}}}}}
   loco.train.manual_mode=false
 end
 say(string.format('SETUP|visible=%d|dual=%s|zero=%s|source_w=%d',N,tostring(DUAL),tostring(ZERO),supply))
end)
local function verify(st,label)
 ck(st.loco.valid,'loco invalid')
 local tr=st.loco.train;ck(tr and tr.valid,'train invalid')
 local got,j=snapshot(st,label)
 ck(#got==#st.expected,'helper count '..#got..' expected '..#st.expected)
 for i,v in ipairs(st.expected)do ck(got[i]==v,'helper kw['..i..']='..got[i]..' expected='..v) end
 local seen={}
 for _,e in ipairs(tr.carriages)do seen[e.unit_number]=true end
 for _,e in ipairs(st.wagon)do ck(e.valid and seen[e.unit_number],'visible motor lost or detached '..e.unit_number)end
 ck(st.wagon[1].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost')
 if st.wagon[2] then ck(math.abs(st.wagon[2].get_fluid_count('water')-9000)<0.01,'fluid lost') end
 if ZERO then ck(j<0.01,'hidden fuel credited without grid') else ck(j>=0,'negative fuel')end
 if not AUTO then ck(tr.speed==0,'test train moved unexpectedly')end
 return got,j
end
script.on_event(defines.events.on_tick,function(ev)
 local st=storage.qa
 if HIGH then
  local lab=game.surfaces['em-25kv-isolated-bridge-058']
  if lab then
   for _,e in ipairs(lab.find_entities_filtered{name='em-25kv-native-traction-consumer-068'}) do
    if e.valid then
     local w=(e.input_flow_limit or 0)*60
     st.peak_input_w=math.max(st.peak_input_w or 0,w)
    end
   end
  end
 end
 if ev.tick==15 then
  verify(st,'READY_15')
  local tr=st.loco.train
  tr.schedule={current=1,records={{station='EM078-NO-STATION-EXISTS',wait_conditions={{type='time',compare_type='and',ticks=60}}}}}
  tr.manual_mode=false
  say('REQUIRE_NO_PATH|installed impossible schedule')
  if RESIZE then
   ck(st.wagon[#st.wagon].valid,'last missing')
   -- Add one wagon onto native end and force refresh; no invisible wagon edits.
   local x=(#st.wagon+1)*7
   local w=create(st.loco.surface,'em-motor-cargo-wagon',x,1,defines.direction.west)
   st.wagon[#st.wagon+1]=w
   st.expected=expect(#st.wagon,DUAL)
   ck(st.loco.train and w.train.id==st.loco.train.id,'resize wagon disconnected')
   say('RESIZE|added_one_motor_wagon')
  end
  if DECREASE then
   local last=st.wagon[#st.wagon]
   st.wagon[#st.wagon]=nil
   ck(last.destroy{raise_destroy=true},'cannot remove last motor wagon')
   st.expected=expect(#st.wagon,DUAL)
   say('DECREASE|removed_one_motor_wagon')
  end
 end
 if ev.tick==30 and SAVE then
   game.auto_save('em077-block-save-'..N)
   say('SAVE|requested_native_save')
 end
 if ev.tick==40 then
  verify(st,'READY_40')
  local tr=st.loco.train
  ck(tr.state==defines.train_state.no_path, 'expected a genuine impossible native train route, got '..tostring(tr.state))
  local count=0
  for _,entity in ipairs(tr.carriages) do
    if entity.name:match('^em%-c5%-technical%-booster%-%d+
  if OWNERLOSS then
    local tr=st.loco.train;local helpers={}
    for _,e in ipairs(tr.carriages)do if e.name:find('^em%-c5%-technical%-booster%-') then helpers[#helpers+1]=e end end
    st.loco.destroy{raise_destroy=true}
    for _,h in ipairs(helpers)do ck(not h.valid,'orphan helper after owner removal')end
    say('OWNERLOSS|all_helpers_removed='..#helpers)
  end
  if not AUTO then
   say('PASS|no_path_hidden_helper_prototype_native')
   script.finish_test(true)
  end
 end
 if ev.tick==300 and AUTO then
   local got,j=snapshot(st,'AUTO_300')
   ck(#got==#st.expected,'helpers lost during native movement')
   local dx=math.abs(st.loco.position.x-st.start_x)
   ck(dx>0.01,'source-paid native train did not accelerate')
   if HIGH then ck((st.peak_input_w or 0)>120000000,'native motor sink did not request >120MW with 11 independent 20MW substations; peak='..tostring(st.peak_input_w)) end
   local paid=st.loco.burner and st.loco.burner.remaining_burning_fuel or 0
   say(string.format('PASS|native_auto_movement|distance=%.3f|speed=%.5f|loco_j=%.1f|helper_j=%.1f|peak_sink_mw=%.3f',dx,st.loco.train.speed,paid,j,(st.peak_input_w or 0)/1e6))
   script.finish_test(true)
 end
end)
) then
      count=count+1
      ck(entity.prototype.alert_icon_scale==0,'helper alert scale not zero in runtime')
      ck(entity.prototype.burner_prototype.render_no_power_icon==false,'helper fuel warning not disabled')
    elseif entity.name=='em-electric-locomotive' then
      ck(entity.prototype.alert_icon_scale>0,'real locomotive no-path icon suppressed')
    end
  end
  ck(count==math.ceil(N/200)*(DUAL and 2 or 1),'missing actual mounted hidden helpers')
  say('NATIVE_NO_PATH|state=no_path|hidden='..count..'|hidden_scale_zero=YES|real_warning_visible=YES')
  if OWNERLOSS then
    local tr=st.loco.train;local helpers={}
    for _,e in ipairs(tr.carriages)do if e.name:find('^em%-c5%-technical%-booster%-') then helpers[#helpers+1]=e end end
    st.loco.destroy{raise_destroy=true}
    for _,h in ipairs(helpers)do ck(not h.valid,'orphan helper after owner removal')end
    say('OWNERLOSS|all_helpers_removed='..#helpers)
  end
  if not AUTO then
   say('PASS|block_traction_native')
   script.finish_test(true)
  end
 end
 if ev.tick==300 and AUTO then
   local got,j=snapshot(st,'AUTO_300')
   ck(#got==#st.expected,'helpers lost during native movement')
   local dx=math.abs(st.loco.position.x-st.start_x)
   ck(dx>0.01,'source-paid native train did not accelerate')
   if HIGH then ck((st.peak_input_w or 0)>120000000,'native motor sink did not request >120MW with 11 independent 20MW substations; peak='..tostring(st.peak_input_w)) end
   local paid=st.loco.burner and st.loco.burner.remaining_burning_fuel or 0
   say(string.format('PASS|native_auto_movement|distance=%.3f|speed=%.5f|loco_j=%.1f|helper_j=%.1f|peak_sink_mw=%.3f',dx,st.loco.train.speed,paid,j,(st.peak_input_w or 0)/1e6))
   script.finish_test(true)
 end
end)
