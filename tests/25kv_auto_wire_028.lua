-- 0.1.28 pure Lua: 8 sprite anchor points and strict ВСМ-only graph.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local geo=require("scripts.native_wire_geometry_028")
local function close(a,b) assert(math.abs(a-b)<0.00001,tostring(a).." != "..tostring(b)) end
local count=0
for face,off in pairs(geo.OFFSETS) do
  count=count+1
  local p=assert(geo.tip({x=5,y=7},face))
  close(p.x,5+off[1]);close(p.y,7+off[2])
end
assert(count==8)
local south=geo.tip({x=-33.5,y=-0.5},"south")
close(south.x,-31.75);close(south.y,-1.30)
assert(geo.tip({x=0,y=0},"bogus")==nil)
local corrected=geo.tip({x=5,y=7},"west",{west={x=0.25,y=-0.25}})
close(corrected.x,5-1.73+0.25)
close(corrected.y,7-0.64-0.25)
-- Direct mock of helper creation and connection gating.
storage={}
defines={wire_origin={player=1},wire_connector_id={pole_copper=3}}
local entities,idnext={},100
local function make_entity(name,pos)
 idnext=idnext+1
 local e={name=name,position=pos,unit_number=idnext,valid=true,
  surface=nil,force={name="player"}}
 entities[e.unit_number]=e
 function e.destroy() e.valid=false; entities[e.unit_number]=nil end
 local c={real_connections={}}
 function c.can_wire_reach(other) return true end
 function c.is_connected_to(other) 
   for _,x in pairs(c.real_connections) do if x.target==other then return true end end
   return false
 end
 function c.connect_to(other,check,origin)
   if c.is_connected_to(other) then return false end
   c.real_connections[#c.real_connections+1]={target=other,origin=origin}
   other.real_connections[#other.real_connections+1]={target=c,origin=origin}
   return true
 end
 function c.disconnect_from(other,origin)
   local changed=false
   for _,x in ipairs(c.real_connections) do
     if x.target==other and x.origin==origin then x.target=nil;changed=true end
   end
   for _,x in ipairs(other.real_connections) do
     if x.target==c and x.origin==origin then x.target=nil end
   end
   local function compact(list)
     local new={}
     for _,x in pairs(list) do if x.target then new[#new+1]=x end end
     return new
   end
   c.real_connections=compact(c.real_connections)
   other.real_connections=compact(other.real_connections)
   return changed
 end
 c.owner=e;c.valid=true
 function e.get_wire_connector() return c end
 return e
end
local surface={index=1}
function surface.create_entity(opts)
 local e=make_entity(opts.name,opts.position)
 e.surface=surface
 return e
end
function surface.find_entities_filtered(filter)
 local out={}
 for _,e in pairs(entities) do if e.valid and e.name==filter.name then out[#out+1]=e end end
 return out
end
local poleA=make_entity("em-35kv-catenary-pole",{x=0,y=0})
local poleB=make_entity("em-35kv-catenary-pole",{x=10,y=0})
poleA.surface=surface;poleB.surface=surface
game={surfaces={[1]=surface},get_entity_by_unit_number=function(id) return entities[id] end}
log=function(_) end
local M=require("scripts.native_wire_028")
local nodes={
 [poleA.unit_number]={id=poleA.unit_number,name=poleA.name,face="south",rail_adjacent=true,rail_id=1,surface_index=1,force_name="player"},
 [poleB.unit_number]={id=poleB.unit_number,name=poleB.name,face="south",rail_adjacent=true,rail_id=2,surface_index=1,force_name="player"}}
local key="a:b"
local graph={nodes=nodes,edges={[key]={a=poleA.unit_number,b=poleB.unit_number,kind="contact"}}}
M.rebuild_all(graph)
assert(M.ensure_storage().stats.connected==1)
-- With no eligible ВСМ rail, no native wires or helper poles.
nodes[poleB.unit_number].rail_adjacent=false
M.sync(graph)
assert(M.ensure_storage().stats.connected==0)
assert(next(M.ensure_storage().helpers)==nil)
-- Two independent paths may be close: absence of a contact edge denies wire.
nodes[poleB.unit_number].rail_adjacent=true
graph.edges={}
M.sync(graph)
assert(M.ensure_storage().stats.connected==0)
-- Recreate after connected track appears.
graph.edges[key]={a=poleA.unit_number,b=poleB.unit_number,kind="contact"}
M.sync(graph)
assert(M.ensure_storage().stats.connected==1)
M.on_parent_removed(poleA)
assert(M.ensure_storage().helpers[poleA.unit_number]==nil)
local src=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
local info=assert(io.open("ElectrifiedMainline/info.json")):read("*a")
if not info:find('"version": "0.1.47"',1,true) and not info:find('"version": "0.1.48"',1,true) and not info:find('"version": "0.1.49"',1,true) and not info:find('"version": "0.1.50"',1,true) and not info:find('"version": "0.1.51"',1,true) and not info:find('"version": "0.1.52"',1,true) and not info:find('"version": "0.1.53"',1,true) and not info:find('"version": "0.1.54"',1,true) and not info:find('"version": "0.1.55"',1,true) and not info:find('"version": "0.1.56"',1,true) and not info:find('"version": "0.1.57"',1,true) and not info:find('"version": "0.1.58"',1,true) and not info:find('"version": "0.1.59"',1,true) and not (info:find('"version": "0.1.60"',1,true) or (info:find('"version": "0.1.61"',1,true) or (info:find('"version": "0.1.62"',1,true) or (info:find('"version": "0.1.63"',1,true) or (info:find('"version": "0.1.64"',1,true) or (info:find('"version": "0.1.65"',1,true) or (info:find('"version": "0.1.66"',1,true) or (info:find('"version": "0.1.67"',1,true) or info:find('"version": "0.1.68"',1,true))))))))) then
assert(src:find("corridor(e.surface,e.force,x,y)",1,true))
assert(src:find("path_info(x,y)",1,true))
assert(src:find("radius=SPAN+RADIUS+4",1,true),
  "Broken middle track must re-check mast ends beyond 5 tiles")
else
 if info:find('"version": "0.1.56"',1,true) or info:find('"version": "0.1.57"',1,true) or info:find('"version": "0.1.58"',1,true) or info:find('"version": "0.1.59"',1,true) or (info:find('"version": "0.1.60"',1,true) or (info:find('"version": "0.1.61"',1,true) or (info:find('"version": "0.1.62"',1,true) or (info:find('"version": "0.1.63"',1,true) or (info:find('"version": "0.1.64"',1,true) or (info:find('"version": "0.1.65"',1,true) or (info:find('"version": "0.1.66"',1,true) or (info:find('"version": "0.1.67"',1,true) or info:find('"version": "0.1.68"',1,true))))))))) then
  assert(src:find("axis056.plan(s.nodes)",1,true))
 else
  assert(src:find("visual047.plan(s.nodes)",1,true))
 end
 assert(src:find("radius=limits.WIRE_REACH*1.5+4+RADIUS",1,true))
 assert(src:find("function M.technical_path(a,b)",1,true))
end
assert(not src:find("rendering.draw_line",1,true))
-- Dynamic unit mock of rail continuity: close, disconnected ВСМ MUST be rejected.
local power=require("scripts.power_019")
defines.rail_direction={front=1,back=2}
defines.rail_connection_direction={straight=1,left=2,right=3}
local f={name="player"}
game.forces={player=f}
local ra={name="em-high-speed-straight-rail",unit_number=701,valid=true,
 position={x=0,y=0},surface=surface,force=f}
local rb={name="em-high-speed-straight-rail",unit_number=702,valid=true,
 position={x=8,y=0},surface=surface,force=f}
local joined=false
function ra.get_connected_rail(_) if joined then return rb end end
function rb.get_connected_rail(_) if joined then return ra end end
local original_find=surface.find_entities_filtered
function surface.find_entities_filtered(filter)
 if filter.position and filter.name and filter.radius then
   local x=filter.position.x
   if math.abs(x)<=3 then return {ra}
   elseif math.abs(x-8)<=3 then return {rb} end
   return {}
 end
 return original_find(filter)
end
local na={rail_id=701,x=0,y=0,surface_index=1,force_name="player"}
local nb={rail_id=702,x=8,y=0,surface_index=1,force_name="player"}
assert(not power.connected_rail_path(na,nb),
  "Disconnected custom high-speed rails must not connect")
joined=true
assert(power.connected_rail_path(na,nb),
  "Physically connected custom HSR rails must permit the edge")
local same={rail_id=701,x=2,y=0,surface_index=1,force_name="player"}
assert(power.connected_rail_path(na,same))

local pr=assert(io.open("ElectrifiedMainline/prototypes/native_wire_auto_028.lua")):read("*a")
assert(pr:find("em-25kv-contact-anchor",1,true))
print("0.1.28 eight C-sprite anchors and native ВСМ-only graph mock PASS")
