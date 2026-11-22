local cases={}
local function say(s)log('EM_C3F|'..s)end
local function ns(t)return tostring(t and #t.carriages or -1)end
local function grant(l,energy)
 local b=l.burner
 if not b then say('error|burner_nil');return false end
 local ok,errmsg=pcall(function()
  b.currently_burning=prototypes.item['em-phantom-internal-energy-token']
  b.remaining_burning_fuel=energy
 end)
 say('grant|unit='..l.unit_number..'|ok='..tostring(ok)..'|res='..tostring(errmsg)..'|value='..tostring(b.remaining_burning_fuel))
 return ok
end
script.on_event(defines.events.on_tick,function(e)
 cases=storage.cases or cases
 if e.tick==2 then
  local s=game.surfaces[1];s.request_to_generate_chunks({70,0},14);s.force_generate_chunk_requests()
  for i,mode in ipairs({'control','void','paid','empty'}) do
   local x=(i-1)*40
   for y=-350,350,2 do s.create_entity{name='straight-rail',position={x=x,y=y},force='player',direction=defines.direction.north}end
   local l=s.create_entity{name='em-finite-main-loco',position={x=x,y=0},force='player',direction=defines.direction.north}
   local p1=nil;local p2=nil
   if mode~='control' then p1=s.create_entity{name='em-phantom-'..(mode=='void' and 'void' or 'paid'),position={x=x,y=3.5},direction=defines.direction.north,force='player'} end
   local w=s.create_entity{name='cargo-wagon',position={x=x,y=7},force='player',direction=defines.direction.north}
   if mode~='control' then p2=s.create_entity{name='em-phantom-'..(mode=='void' and 'void' or 'paid'),position={x=x,y=10.5},direction=defines.direction.north,force='player'} end
   local f=s.create_entity{name='fluid-wagon',position={x=x,y=14},force='player',direction=defines.direction.north}
   cases[mode]={l=l,p1=p1,p2=p2,w=w,f=f}
   say('created|mode='..mode..'|n='..ns(l.train)..'|span='..string.format('%.4f',f.position.y-l.position.y)..'|phantom1='..tostring(p1~=nil)..'|phantom2='..tostring(p2~=nil))
  end
  storage.cases=cases
 end
 if e.tick==12 then
  for mode,d in pairs(cases) do
   if d.p1 and d.p1.valid then
    d.p1.operable=false;d.p2.operable=false
    if mode=='paid' then grant(d.p1,200000);grant(d.p2,200000) end
    say('startup|mode='..mode..'|J1='..tostring(d.p1.burner and d.p1.burner.remaining_burning_fuel or 0)..'|J2='..tostring(d.p2.burner and d.p2.burner.remaining_burning_fuel or 0))
   end
   local c=d.l.surface.create_entity{name='character',position=d.l.position,force='player'}
   if c then d.l.set_driver(c);c.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}end
  end
 end
 if e.tick==25 then local ok,why=pcall(function()game.server_save('emc3f-checkpoint')end);say('disk_save_request|tick=25|ok='..tostring(ok)..'|err='..tostring(why))end
 if e.tick==20 or e.tick==30 or e.tick==40 or e.tick==50 or e.tick==60 or e.tick==100 or e.tick==180 or e.tick==240 then
  for mode,d in pairs(cases)do
   local J=0
   if d.p1 and d.p1.valid and d.p1.burner then J=J+d.p1.burner.remaining_burning_fuel end
   if d.p2 and d.p2.valid and d.p2.burner then J=J+d.p2.burner.remaining_burning_fuel end
   say('motion|tick='..e.tick..'|mode='..mode..'|y='..string.format('%.6f',d.l.position.y)..'|speed='..string.format('%.7f',d.l.train.speed)..'|n='..#d.l.train.carriages..'|paid_j_remaining='..string.format('%.3f',J))
  end
 end
end)