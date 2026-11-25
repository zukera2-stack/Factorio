local CASE=script.test_arg or 'save'
local function ck(b,msg) if not b then error('[AUDIT FAIL] '..CASE..' '..msg) end end
local function say(msg) log('[AUDIT] '..CASE..' '..msg) end
local function create(s,name,x,y,dir)
 local e=s.create_entity{name=name,position={x=x,y=y},force='player',direction=dir or defines.direction.west,raise_built=true}
 ck(e and e.valid,'create '..name..' at '..x);return e
end
local function joules(e) return e.valid and e.burner and (e.burner.remaining_burning_fuel or 0) or 0 end
local function helpers(t)
 local a={}
 if t and t.valid then for _,e in ipairs(t.carriages) do if e.valid and e.name:find('^em%-c5%-technical%-booster%-') then a[#a+1]=e end end end
 return a
end
local function global_helpers()
 local n=0
 for _,s in pairs(game.surfaces) do for _,e in pairs(s.find_entities_filtered{type='locomotive'}) do if e.name:find('^em%-c5%-technical%-booster%-') then n=n+1 end end end
 return n
end
script.on_init(function()
 local n=(CASE=='block' or CASE=='save') and 201 or ((CASE=='fair' or CASE=='churn') and 0 or 2)
 local xmax=math.max(500,7*(n+1)+280)
 local s=game.create_surface('em085-audit-'..CASE,{width=math.ceil((xmax+650)/32)*32,height=256})
 s.generate_with_lab_tiles=true;s.always_day=true
 for x=-320,xmax,128 do s.request_to_generate_chunks({x=x,y=0},2) end
 s.force_generate_chunk_requests()
 for x=-340,xmax,2 do create(s,'em-high-speed-straight-rail',x,1,defines.direction.east) end
 if CASE~='offgrid' then for x=-301.5,xmax-4,20 do create(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east) end end
 local sub=create(s,'em-35kv-traction-substation',-20,9,defines.direction.east)
 local gen=create(s,'electric-energy-interface',-20,13,defines.direction.east)
 local supply=CASE=='fair' and 1000000 or 20000000
 gen.electric_interface_mode=defines.electric_interface_mode.primary_output
 gen.electric_buffer_size=10000000
 gen.power_production=supply/60;gen.power_usage=0;gen.output_flow_limit=supply/60;gen.input_flow_limit=0;gen.energy=0
 local loco=create(s,'em-electric-locomotive',0,1,defines.direction.west)
 local wagons={}
 for i=1,n do wagons[i]=create(s,i%2==0 and 'em-motor-fluid-wagon' or 'em-motor-cargo-wagon',i*7,1,defines.direction.west) end
 if n>0 then ck(wagons[1].get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo insert');ck(wagons[2].insert_fluid{name='water',amount=9000}==9000,'fluid insert') end
 local second=nil
 if CASE=='fair' then second=create(s,'em-electric-locomotive',40,1,defines.direction.west) end
 ck(#loco.train.carriages==n+1,'coupling before helper mount')
 storage.qa={loco=loco,second=second,wagons=wagons,n=n,sub=sub,gen=gen,peak=0,start_x=loco.position.x}
 if CASE=='move' then
  local stop
  for _,dy in ipairs({-2,2,0}) do
   for _,dir in ipairs({defines.direction.west,defines.direction.east}) do
    local a=s.create_entity{name='train-stop',position={x=-160,y=1+dy},direction=dir,force='player',raise_built=true}
    if a and a.valid and a.connected_rail then stop=a;break end
    if a and a.valid then a.destroy() end
   end
   if stop then break end
  end
  ck(stop,'native stop');stop.backer_name='AUDIT_STOP'
  loco.train.schedule={current=1,records={{station='AUDIT_STOP',wait_conditions={{type='time',compare_type='and',ticks=60}}}}}
  loco.train.manual_mode=false
 end
 say('SETUP n='..n..' source_w='..supply)
end)
script.on_event(defines.events.on_tick,function(ev)
 local st=storage.qa
 local t=ev.tick
 if CASE=='save' then
  if t==80 then
   local h=helpers(st.loco.train);ck(#h==2,'save helper count')
   local snap=remote.call('em072_native_qa_071','snapshot',h[1].unit_number)
   st.saved={loco=st.loco.unit_number,helpers={h[1].unit_number,h[2].unit_number},paid=snap.paid_J,j=joules(st.loco),cars=#st.loco.train.carriages}
   say('SAVE tick='..t..' paid_J='..st.saved.paid..' carriages='..st.saved.cars..' loco_J='..st.saved.j)
   game.auto_save('em085-audit-201')
  elseif t==90 then say('SAVE phase complete') end
  return
 elseif CASE=='load' then
  if t>=90 then
   ck(st.saved and st.loco.valid and st.loco.unit_number==st.saved.loco,'save loco identity')
   local h=helpers(st.loco.train);ck(#h==2,'loaded helper count')
   local ids={};for _,e in ipairs(h) do ids[e.unit_number]=true end
   for _,id in ipairs(st.saved.helpers) do ck(ids[id],'helper identity changed') end
   ck(#st.loco.train.carriages==st.saved.cars,'carriages changed')
   ck(st.wagons[1].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost')
   ck(st.wagons[2].get_fluid_count('water')==9000,'water lost')
   local snap=remote.call('em072_native_qa_071','snapshot',h[1].unit_number)
   ck(snap.paid_J>=st.saved.paid,'paid counter regressed')
   say('LOAD tick='..t..' paid_J='..snap.paid_J..' carriages='..#st.loco.train.carriages..' identities retained');say('PASS');script.finish_test(true)
  end
  return
 end
 if CASE=='gui' then
  local wagon=st.wagons[1]
  if t==41 then
   local player=game.players[1]
   ck(player and player.valid,'no test player')
   player.teleport({x=7,y=5},wagon.surface)
   say('GUI_BEFORE custom_status='..tostring(wagon.custom_status~=nil))
   player.opened=wagon
   say('GUI_OPEN immediate_status='..tostring(wagon.custom_status~=nil)..' connected='..tostring(player.connected))
  elseif t==42 or t==61 then
   local s=wagon.custom_status
   say('GUI_'..t..' custom_status='..tostring(s~=nil)..' label='..tostring(s and s.label and s.label[1]))
   if t==61 then say('GUI inspection complete');script.finish_test(true) end
  end
  return
 end
 if CASE=='churn' then
  local function count_sinks(label)
   local count,isolated,energy=0,0,0
   for _,surf in pairs(game.surfaces) do
    for _,e in pairs(surf.find_entities_filtered{name='em-25kv-native-traction-consumer-068'}) do
     count=count+1;energy=energy+e.energy
     if not e.electric_network_id then isolated=isolated+1 end
     say(string.format('%s sink=%d net=%s J=%.3f',label,e.unit_number,tostring(e.electric_network_id),e.energy))
    end
   end
   say(string.format('%s sinks=%d disconnected=%d stored_J=%.3f',label,count,isolated,energy))
   return count,isolated
  end
  if t==60 or t==180 or t==300 then
   local count=count_sinks('BEFORE_'..t);ck(count>=1,'no traction sink created')
   local surf=st.loco.surface
   st.loco.destroy{raise_destroy=true};st.sub.destroy{raise_destroy=true}
   for _,m in pairs(surf.find_entities_filtered{name='em-35kv-catenary-pole'}) do m.destroy{raise_destroy=true} end
  elseif t==80 or t==200 then
   count_sinks('AFTER_REMOVAL_'..t)
   local surf=game.surfaces['em085-audit-churn']
   for x=-301.5,496,20 do create(surf,'em-35kv-catenary-pole',x,2.5,defines.direction.east) end
   st.sub=create(surf,'em-35kv-traction-substation',-20,9,defines.direction.east)
   st.loco=create(surf,'em-electric-locomotive',0,1,defines.direction.west)
  elseif t==320 then
   local count,isolated=count_sinks('FINAL_AFTER_3_REMOVALS')
   if count>0 then say('DEFECT persistent native sinks after complete infrastructure removal') end
   ck(count>=3 and isolated==count,'expected reproduction not observed')
   say('REPRODUCED: orphan sink accumulation');script.finish_test(true)
  end
  return
 end
 if t%10==0 then
  for _,s in pairs(game.surfaces) do
   for _,e in ipairs(s.find_entities_filtered{name='em-25kv-native-traction-consumer-068'}) do
    if e.valid then local p=e.electric_network and e.electric_network.parent_network;local f=p and p.flow_last_tick
      if f then st.peak=math.max(st.peak,(f.primary_demand or 0)+(f.secondary_demand or 0)) end
    end
   end
  end
 end
 if t==40 and CASE~='fair' and CASE~='churn' then
  local h=helpers(st.loco.train);local expected=st.n==201 and 2 or 1
  ck(#h==expected,'helper count='..#h..' expected='..expected)
  say('HELPERS '..#h)
  ck(st.wagons[1].get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost')
  ck(math.abs(st.wagons[2].get_fluid_count('water')-9000)<0.01,'fluid lost')
  if CASE=='ownerloss' then
   st.loco.destroy{raise_destroy=true}
   for _,x in ipairs(h) do ck(not x.valid,'orphan helper immediately after owner removed') end
   say('OWNER_REMOVED helpers_destroyed='..#h)
  end
 end
 if t==120 and CASE=='fair' then
  local a,b=joules(st.loco),joules(st.second)
  say(string.format('FAIR_120 loco1_J=%.3f loco2_J=%.3f native_peak_J_tick=%.3f',a,b,st.peak))
  ck(a>0 and b>0,'starvation');ck(math.abs(a-b)<0.1,'equal locomotive imbalance');ck(st.peak>0,'no native demand');say('PASS');script.finish_test(true)
 elseif t==120 and CASE=='offgrid' then
  local a=joules(st.loco);local b=0;for _,e in ipairs(helpers(st.loco.train)) do b=b+joules(e) end
  say(string.format('OFFGRID loco_J=%.3f helper_J=%.3f native_peak_J_tick=%.3f',a,b,st.peak));ck(a==0 and b==0,'free energy');ck(st.peak==0,'offgrid demand');say('PASS');script.finish_test(true)
 elseif t==120 and CASE=='ownerloss' then
  local n=global_helpers();say('OWNERLOSS global_helpers='..n);ck(n==0,'orphan persists');say('PASS');script.finish_test(true)
 elseif t==120 and CASE=='block' then
  local h=helpers(st.loco.train);local kw={};for _,x in ipairs(h) do kw[#kw+1]=tonumber(x.name:match('(%d+)$')) end;table.sort(kw)
  say('BLOCK count='..#h..' kw='..table.concat(kw,','));ck(#h==2 and kw[1]==500 and kw[2]==100000,'wrong blocks');say('PASS');script.finish_test(true)
 elseif t==300 and CASE=='move' then
  local dx=math.abs(st.loco.position.x-st.start_x)
  say(string.format('MOVE distance=%.3f speed=%.5f loco_J=%.3f native_peak_J_tick=%.3f',dx,st.loco.train.speed,joules(st.loco),st.peak));ck(dx>0.01,'no movement');ck(st.peak>0,'no native demand');say('PASS');script.finish_test(true)
 end
end)
