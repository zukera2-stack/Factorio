local H='em-high-speed-straight-rail'
local D=defines.rail_direction
local function ck(v,m) if not v then error('[EM087G ROUTER FAIL] '..m) end end
local function mk(s,name,x,y,dir)
 local r=s.create_entity{name=name,position={x=x,y=y},force='player',direction=dir or defines.direction.east,raise_built=true}
 ck(r and r.valid,'create '..name..' at '..x..','..y);return r
end
local function route(a,b,label)
 local r=game.train_manager.request_train_path{starts={{rail=a,direction=D.front},{rail=a,direction=D.back}},goals={{rail=b,direction=D.front},{rail=b,direction=D.back}},shortest_path=true,return_path=true,steps_limit=192}
 local vanilla=0;for _,e in ipairs(r.path or {}) do if e.name~=H then vanilla=vanilla+1 end end
 log('[EM087G ROUTER] '..label..' found='..tostring(r.found_path)..' vanilla='..vanilla..' length='..tostring(r.total_length))
 return r.found_path,vanilla
end
script.on_init(function()
 local s=game.create_surface('em087g-router',{width=256,height=128});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
 local st={s=s,rails={}};for x=-43,43,2 do st.rails[x]=mk(s,H,x,1) end
 st.a=mk(s,'em-35kv-catenary-pole',-21.5,2.5);st.b=mk(s,'em-35kv-catenary-pole',18.5,2.5)
 storage.qa=st
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa;local t=e.tick;local a,b=st.rails[-21],st.rails[19]
 if t==120 then
  ck(route(a,b,'straight-east') and route(b,a,'straight-west'),'no baseline path');ck(st.a.electric_network_id==st.b.electric_network_id,'initial copper disconnected')
  local signal
  for _,y in ipairs({-0.5,2.5,3,-1}) do
   for _,dir in ipairs({defines.direction.east,defines.direction.west,defines.direction.north,defines.direction.south}) do
    local x=st.s.create_entity{name='rail-signal',position={-11,y},force='player',direction=dir,raise_built=false}
    if x and x.valid and #x.get_connected_rails()>0 then signal=x;break end
    if x and x.valid then x.destroy() end
   end
   if signal then break end
  end
  ck(signal,'signal fixture');st.signal=signal
 elseif t==140 then
  local f=route(a,b,'signal-east');local r=route(b,a,'signal-west')
  ck(f~=r,'expected one-way route');ck(st.a.electric_network_id==st.b.electric_network_id,'signal must not break current');st.signal.destroy()
 elseif t==160 then
  st.rails[-1].destroy{raise_destroy=true};st.rails[-1]=mk(st.s,'straight-rail',-1,1)
 elseif t==180 then
  local f,v=route(a,b,'mixed');ck(f and v>0,'expected native train route via vanilla');ck(st.a.electric_network_id~=st.b.electric_network_id,'vanilla rail must break HSR power');log('[EM087G ROUTER PASS] train pathfinder is not an electrical continuity oracle');script.finish_test(true)
 end
end)
