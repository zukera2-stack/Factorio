local power=require('__ElectrifiedMainline__/scripts/power_019')
local H='em-high-speed-straight-rail'
local function ck(v,m) if not v then error('[EM087C QA FAIL] '..m) end end
local function make(s,name,x,y,d,raised)
 local e=s.create_entity{name=name,position={x,y},direction=d,force='player',auto_connect=false,raise_built=raised}
 ck(e and e.valid,'create '..name..' '..x..','..y);return e
end
local function c(e) return e.get_wire_connector(defines.wire_connector_id.pole_copper,true) end
local origin=defines.wire_origin.script
local function connect(a,b) ck(c(a).connect_to(c(b),false,origin),'native wire connect') end
local function disconnect(a,b) ck(c(a).disconnect_from(c(b),origin),'native wire disconnect') end
local function node(e,i)
 local p=e.position
 return {id=i,rail_id=e.unit_number,rail_adjacent=true,x=p.x,y=p.y,surface_index=e.surface.index,force_name=e.force.name}
end
local function compare(st,label)
 local nodes={};for _,r in ipairs(st.rails) do if r.valid and r.name==H then nodes[#nodes+1]=node(r,#nodes+1) end end
 local a={starts={},neighbours={}};local b={starts={},neighbours={},disable_native_segments=true};local comparisons=0
 for i=1,#nodes,3 do for j=1,#nodes,4 do
  local n,m=nodes[i],nodes[j]
  if math.abs(n.x-m.x)+math.abs(n.y-m.y)<=80 then
   local left=power.technical_path(n,m,a);local right=power.technical_path(n,m,b)
   ck((left~=nil)==(right~=nil),label..' reachability '..i..','..j)
   if left then ck(left.length==right.length and left.curved==right.curved,label..' exact path '..i..','..j) end
   comparisons=comparisons+1
  end
 end end
 log('[EM087C QA] '..label..' pairs='..comparisons..' native_hits='..(a.native_segment_hits or 0))
 st.comparisons=(st.comparisons or 0)+comparisons;st.hits=(st.hits or 0)+(a.native_segment_hits or 0)
 return a.native_segment_hits or 0
end
script.on_init(function()
 local s=game.create_surface('em087c-native-segment',{width=512,height=256});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},4);s.force_generate_chunk_requests()
 local st={s=s,rails={}}
 for x=-121,121,2 do st.rails[#st.rails+1]=make(s,H,x,1,defines.direction.east,false) end
 for y=-61,61,2 do st.rails[#st.rails+1]=make(s,H,151,y,defines.direction.north,false) end
 -- A separate route containing ordinary rail: must not be certified as all HSR.
 for x=-61,61,2 do st.rails[#st.rails+1]=make(s,(x==-1) and 'straight-rail' or H,x,41,defines.direction.east,false) end
 st.a=make(s,'small-electric-pole',-20,90,defines.direction.north,false)
 st.b=make(s,'small-electric-pole',0,90,defines.direction.north,false)
 st.c=make(s,'small-electric-pole',20,90,defines.direction.north,false)
 connect(st.a,st.b);connect(st.b,st.c);connect(st.a,st.c)
 storage.qa=st
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa
 if e.tick==5 then
  ck(compare(st,'initial')>0,'no native fast-path coverage')
  ck(st.a.electric_network_id==st.c.electric_network_id,'initial native loop not connected')
  disconnect(st.a,st.b)
 elseif e.tick==6 then
  ck(st.a.electric_network_id==st.b.electric_network_id,'native split with alternate path')
  disconnect(st.a,st.c)
 elseif e.tick==7 then
  ck(st.a.electric_network_id~=st.b.electric_network_id,'native C++ did not split network')
  connect(st.a,st.c)
 elseif e.tick==8 then
  ck(st.a.electric_network_id==st.b.electric_network_id,'native C++ did not rejoin')
  st.rails[61].destroy{raise_destroy=false}
  compare(st,'silent-rail-cut')
 elseif e.tick==9 then
  st.rails[61]=make(st.s,H,-1,1,defines.direction.east,false)
  compare(st,'silent-rail-restore')
 elseif e.tick==10 then
  local signal
  for _,y in ipairs({-0.5,2.5,3,-1}) do
   for _,dir in ipairs({defines.direction.east,defines.direction.west,defines.direction.north,defines.direction.south}) do
    local x=st.s.create_entity{name='rail-signal',position={-1,y},force='player',direction=dir,raise_built=false}
    if x and x.valid and #x.get_connected_rails()>0 then signal=x;break end
    if x and x.valid then x.destroy() end
   end
   if signal then break end
  end
  ck(signal,'could not place signal fixture');st.signal=signal
  compare(st,'signal-boundary')
 elseif e.tick==11 then
  st.signal.destroy{raise_destroy=false};compare(st,'signal-removed')
  log('[EM087C QA PASS] comparisons='..st.comparisons..' fast_hits='..st.hits..' native copper split/rejoin and alternate loop passed')
  script.finish_test(true)
 end
end)
