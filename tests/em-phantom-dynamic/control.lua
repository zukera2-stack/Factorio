local function say(s) log('EM_C3D|'..s) end
local function snap(t)
 if not t or not t.valid then return 'invalid' end
 local v={};for _,c in ipairs(t.carriages)do v[#v+1]=c.name..'@'..string.format('%.4f',c.position.y)end
 local len=math.abs(t.carriages[1].position.y-t.carriages[#t.carriages].position.y)
 return 'train='..t.id..'|n='..#t.carriages..'|span='..string.format('%.4f',len)..'|stock='..table.concat(v,',')
end
local cases={}
local function err(lbl,fn)local ok,v=pcall(fn);say('api|'..lbl..'|ok='..tostring(ok)..'|out='..tostring(v));return ok,v end
local function insert(d,x,kind)
 local s=game.surfaces[1]
 local p1=s.create_entity{name='em-invisible-motor-500kw',position={x=x,y=3.5},force='player',direction=defines.direction.north}
 local p2=s.create_entity{name='em-invisible-motor-500kw',position={x=x,y=10.5},force='player',direction=defines.direction.north}
 d.p1=p1;d.p2=p2
 say('insert|'..kind..'|p1='..tostring(p1~=nil)..'|p2='..tostring(p2~=nil)..'|'..snap(d.l.train))
 if p1 then say('p1|'..kind..'|'..snap(p1.train)) end
 if p2 then say('p2|'..kind..'|'..snap(p2.train)) end
 if p1 then
  err(kind..'_p1_front',function()return p1.connect_rolling_stock(defines.rail_direction.front)end)
  err(kind..'_p1_back',function()return p1.connect_rolling_stock(defines.rail_direction.back)end)
 end
 if p2 then
  err(kind..'_p2_front',function()return p2.connect_rolling_stock(defines.rail_direction.front)end)
  err(kind..'_p2_back',function()return p2.connect_rolling_stock(defines.rail_direction.back)end)
 end
 say('afterconnect|'..kind..'|'..snap(d.l.train))
end
script.on_event(defines.events.on_train_created,function(ev)
 say('event_train_created|tick='..game.tick..'|id='..ev.train.id..'|old1='..tostring(ev.old_train_id_1)..'|old2='..tostring(ev.old_train_id_2)..'|'..snap(ev.train))
end)
script.on_event(defines.events.on_tick,function(e)
 cases=storage.cases or cases
 if e.tick==2 then
  local s=game.surfaces[1];s.request_to_generate_chunks({80,0},14);s.force_generate_chunk_requests()
  for i,k in ipairs({'baseline','hot','detached','detached_both','restore','prebuilt'}) do
   local x=(i-1)*40
   for y=-350,350,2 do s.create_entity{name='straight-rail',position={x=x,y=y},force='player',direction=defines.direction.north}end
   local l=s.create_entity{name='em-traction-real-main',position={x=x,y=0},force='player',direction=defines.direction.north}
   local p1=nil;local p2=nil
   if k=='prebuilt' then p1=s.create_entity{name='em-invisible-motor-500kw',position={x=x,y=3.5},force='player',direction=defines.direction.north}end
   local w1=s.create_entity{name='cargo-wagon',position={x=x,y=7},force='player',direction=defines.direction.north}
   if k=='prebuilt' then p2=s.create_entity{name='em-invisible-motor-500kw',position={x=x,y=10.5},force='player',direction=defines.direction.north}end
   local w2=s.create_entity{name='fluid-wagon',position={x=x,y=14},force='player',direction=defines.direction.north}
   cases[k]={l=l,w1=w1,w2=w2,p1=p1,p2=p2,x=x}
   say('start|'..k..'|'..snap(l.train))
  end
  storage.cases=cases
 end
 if e.tick==8 then
  local d=cases.hot;insert(d,d.x,'hot')
  local x=cases.detached
  err('disconnect_back',function()return x.l.disconnect_rolling_stock(defines.rail_direction.back)end)
  say('afterdisconnect|detached|'..snap(x.l.train)..'|wagontrain='..snap(x.w1.train))
  insert(x,x.x,'detached')
  local d=cases.detached_both
  err('both_disconnect_main',function()return d.l.disconnect_rolling_stock(defines.rail_direction.back)end)
  local q=d.l.surface.create_entity{name='em-invisible-motor-500kw',position={x=d.x,y=3.5},force='player',direction=defines.direction.north}
  d.p1=q
  say('both_first|added='..tostring(q~=nil)..'|'..snap(d.l.train))
  err('both_disconnect_cargo',function()return d.w1.disconnect_rolling_stock(defines.rail_direction.back)end)
  say('both_split_second|'..snap(d.l.train)..'|fluid='..snap(d.w2.train))
  local q2=d.l.surface.create_entity{name='em-invisible-motor-500kw',position={x=d.x,y=10.5},force='player',direction=defines.direction.north}
  d.p2=q2
  say('both_second|added='..tostring(q2~=nil)..'|'..snap(d.l.train))
  local r=cases.restore
  err('restore_disconnect_main',function()return r.l.disconnect_rolling_stock(defines.rail_direction.back)end)
  r.p1=r.l.surface.create_entity{name='em-invisible-motor-500kw',position={x=r.x,y=3.5},force='player',direction=defines.direction.north}
  err('restore_disconnect_cargo',function()return r.w1.disconnect_rolling_stock(defines.rail_direction.back)end)
  r.p2=r.l.surface.create_entity{name='em-invisible-motor-500kw',position={x=r.x,y=10.5},force='player',direction=defines.direction.north}
  say('restore_both_inserted|p1='..tostring(r.p1~=nil)..'|p2='..tostring(r.p2~=nil)..'|'..snap(r.l.train))
 end
 if e.tick==13 then
  local r=cases.restore
  if r.p2 and r.p2.valid then err('restore_delete_p2',function()return r.p2.destroy()end)end
  if r.p1 and r.p1.valid then err('restore_delete_p1',function()return r.p1.destroy()end)end
  say('restore_after_destroy|'..snap(r.l.train)..'|cargo='..snap(r.w1.train)..'|fluid='..snap(r.w2.train))
  err('restore_join_main',function()return r.l.connect_rolling_stock(defines.rail_direction.back)end)
  err('restore_join_cargo',function()return r.w1.connect_rolling_stock(defines.rail_direction.back)end)
  say('restored_final|'..snap(r.l.train)..'|orig_units='..r.l.unit_number..','..r.w1.unit_number..','..r.w2.unit_number)
 end
 if e.tick==15 then
  for k,d in pairs(cases) do
   say('assembled|'..k..'|'..snap(d.l.train))
   if d.p1 and d.p1.valid then say('p1state|'..k..'|same_train='..tostring(d.p1.train.id==d.l.train.id))end
   local ch=d.l.surface.create_entity{name='character',position=d.l.position,force='player'}
   if ch then d.l.set_driver(ch);ch.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}end
  end
 end
 if e.tick==120 then local ok,why=pcall(function()game.server_save('emc3d-checkpoint')end);say('disk_save_request|tick=120|ok='..tostring(ok)..'|info='..tostring(why))end
 if e.tick==60 or e.tick==100 or e.tick==160 or e.tick==240 then
  for k,d in pairs(cases) do say('motion|tick='..e.tick..'|mode='..k..'|y='..string.format('%.6f',d.l.position.y)..'|'..snap(d.l.train))end
 end
end)