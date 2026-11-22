local cases={}
local function say(s) log("EM_PHANTOM_C3|"..s) end
local function safe(label,fn)local ok,res=pcall(fn);say("api|"..label.."|ok="..tostring(ok).."|result="..tostring(res));return ok,res end
local function describe(t)
 local list={}local n=t and #t.carriages or 0
 if t then for _,e in ipairs(t.carriages) do list[#list+1]=e.name.."@"..string.format("%.5f",e.position.y) end end
 return "n="..n.."|cars="..table.concat(list,",")
end
local function lane(x,mode)
 local s=game.surfaces[1]
 for y=-350,350,2 do s.create_entity{name="straight-rail",position={x=x,y=y},force="player",direction=defines.direction.north} end
 local l=s.create_entity{name="em-traction-real-main",position={x=x,y=0},force="player",direction=defines.direction.north}
 local p1=nil;local p2=nil
 if mode=="two_hidden" or mode=="disabled" then
  p1=s.create_entity{name="em-invisible-motor-500kw",position={x=x,y=3.5},force="player",direction=defines.direction.north}
 end
 local w1=s.create_entity{name="cargo-wagon",position={x=x,y=7},force="player",direction=defines.direction.north}
 if mode=="two_hidden" or mode=="disabled" then
  p2=s.create_entity{name="em-invisible-motor-500kw",position={x=x,y=10.5},force="player",direction=defines.direction.north}
 end
 local w2=s.create_entity{name="fluid-wagon",position={x=x,y=14},force="player",direction=defines.direction.north}
 if mode=="offtrain" then p1=s.create_entity{name="em-invisible-motor-500kw",position={x=x,y=25},force="player",direction=defines.direction.north} end
 if mode=="overlay" then
  p1=s.create_entity{name="em-invisible-motor-500kw",position={x=x,y=7},force="player",direction=defines.direction.north}
 end
 cases[mode]={loco=l,p1=p1,p2=p2,w1=w1,w2=w2}
 say("created|mode="..mode.."|l="..tostring(l~=nil).."|w1="..tostring(w1~=nil).."|w2="..tostring(w2~=nil).."|p1="..tostring(p1~=nil).."|p2="..tostring(p2~=nil))
 if l then
  say("train|mode="..mode.."|"..describe(l.train))
  local cars=l.train.carriages
  say("span|mode="..mode.."|delta="..string.format("%.6f",math.abs(cars[1].position.y-cars[#cars].position.y)))
 end
 if p1 then
  safe(mode.."_get_disabled",function()return p1.disabled_by_script end)
  if mode=="disabled" then
   safe(mode.."_set_disabled",function()p1.disabled_by_script=true;p2.disabled_by_script=true;return tostring(p1.disabled_by_script).."/"..tostring(p2.disabled_by_script)end)
   safe(mode.."_read_active",function()return p1.active end)
   safe(mode.."_set_active",function()p1.active=false;return p1.active end)
  end
  safe(mode.."_minable_flag",function()return p1.minable_flag end)
  safe(mode.."_blueprint_flag",function()return p1.has_flag("not-blueprintable") end)
 end
end
script.on_event(defines.events.on_tick,function(e)
 cases=storage.c3_cases or cases
 if e.tick==2 then
  local s=game.surfaces[1]
  s.request_to_generate_chunks({80,0},14);s.force_generate_chunk_requests()
  for i,name in ipairs({"control","two_hidden","disabled","offtrain","overlay"}) do lane((i-1)*40,name) end
  storage.c3_cases=cases
 end
 if e.tick==12 then
  for name,d in pairs(cases) do
   if d.loco and d.loco.valid then
    say("ready|mode="..name.."|"..describe(d.loco.train))
    if d.p1 and d.p1.valid then say("coupled|mode="..name.."|same="..tostring(d.loco.train.id==d.p1.train.id)) end
    local c=d.loco.surface.create_entity{name="character",force="player",position=d.loco.position}
    if c then d.loco.set_driver(c);c.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight} end
   end
  end
 end
 if e.tick==120 then
  local ok,why=pcall(function()game.server_save("emc3-checkpoint")end)
  say("disk_save_request|tick=120|ok="..tostring(ok).."|info="..tostring(why))
 end
 if e.tick==60 or e.tick==100 or e.tick==160 or e.tick==240 then
  for name,d in pairs(cases) do if d.loco and d.loco.valid then
   say("motion|tick="..e.tick.."|mode="..name.."|y="..string.format("%.6f",d.loco.position.y).."|speed="..string.format("%.6f",d.loco.train.speed).."|"..describe(d.loco.train))
   if d.p1 and d.p1.valid and name=="disabled" then say("disabled_status|tick="..e.tick.."|state="..tostring(d.p1.disabled_by_script).."|active="..tostring(d.p1.active)) end
  end end
 end
end)