package.path='./ElectrifiedMainline/?.lua;'..package.path
local M=require('scripts.technical_network_046')
local POLE,NORTH='em-35kv-catenary-pole','em-35kv-catenary-pole-north'
local function n(id,x,y,force,surface,name)
 return {id=id,name=name or POLE,x=x,y=y,force_name=force or 'p',surface_index=surface or 1,rail_adjacent=false}
end
local nodes={[1]=n(1,0,0),[2]=n(2,4,0,nil,nil,NORTH),[3]=n(3,44,0),[4]=n(4,44.1,40),[5]=n(5,1,0,'other'),[6]=n(6,1,0,nil,2),[7]=n(7,1,0,nil,nil,'small-electric-pole'),[8]=n(8,1,0,nil,nil,'entity-ghost')}
local edges=M.plan(nodes)
assert(edges['1:2'] and edges['2:3'] and not edges['1:3'])
for _,e in pairs(edges) do assert(e.a<5 and e.b<5 and e.d<=1600) end
local dense={}
for i=1,30 do dense[i]=n(i,i%5,math.floor(i/5)) end
local degree={}
for _,e in pairs(M.plan(dense)) do degree[e.a]=(degree[e.a] or 0)+1;degree[e.b]=(degree[e.b] or 0)+1 end
for _,d in pairs(degree) do assert(d<=5) end

storage={};log=function() end
defines={wire_origin={player=1,script=2},wire_connector_id={pole_copper=5}}
local entities={};local nextid=100;local created=0;local surface={index=1};local force={name='p'}
local function make(id,name,x,y)
 local e={valid=true,unit_number=id,name=name,position={x=x,y=y},surface=surface,force=force}
 local c={valid=true,owner=e,real_connections={},network_id=22}
 function c.is_connected_to(other,origin)
   for _,l in ipairs(c.real_connections) do if l.target==other and l.origin==origin then return true end end
   return false
 end
 function c.connect_to(other,reach,origin)
   assert(reach==false and origin==defines.wire_origin.script)
   assert(e.name=='em-25kv-technical-anchor-046' and other.owner.name==e.name)
   c.real_connections[#c.real_connections+1]={target=other,origin=origin}
   other.real_connections[#other.real_connections+1]={target=c,origin=origin}
   return true
 end
 local function remove(a,b,origin)
   for i=#a.real_connections,1,-1 do local l=a.real_connections[i];if l.target==b and l.origin==origin then table.remove(a.real_connections,i) end end
 end
 function c.disconnect_from(other,origin) remove(c,other,origin);remove(other,c,origin);return true end
 function e.get_wire_connector() return c end
 function e.destroy()
   while #c.real_connections>0 do local l=c.real_connections[1];c.disconnect_from(l.target,l.origin) end
   e.valid=false;c.valid=false;entities[id]=nil
 end
 e.c=c;entities[id]=e;return e
end
function surface.create_entity(arg)
 assert(arg.auto_connect==false and arg.raise_built==false)
 nextid=nextid+1;created=created+1
 return make(nextid,arg.name,arg.position.x,arg.position.y)
end
function surface.find_entities_filtered(f)
 local t={};for _,e in pairs(entities) do if e.name==f.name then t[#t+1]=e end end;return t
end
game={surfaces={[1]=surface},get_entity_by_unit_number=function(id) return entities[id] end}
local p1,p2,p3=make(1,POLE,0,0),make(2,NORTH,4,0),make(3,POLE,44,0)
local vanilla=make(7,'small-electric-pole',2,0)
local ghost=make(8,'entity-ghost',3,0)
local g={nodes={[1]=nodes[1],[2]=nodes[2],[3]=nodes[3],[7]=nodes[7],[8]=nodes[8]},edges={}}
M.sync(g)
local s=M.ensure_storage()
assert(s.stats.connected==2 and created==3)
assert(M.inspect_pair(1,2)=='script-connected' and M.inspect_pair(2,3)=='script-connected')
assert(s.helpers[7]==nil and s.helpers[8]==nil)
local h=entities[s.helpers[1]]
-- Deliberately simulate both unauthorized origins; both must be stripped.
for _,origin in ipairs({1,2}) do h.c.real_connections[#h.c.real_connections+1]={target=vanilla.c,origin=origin};vanilla.c.real_connections[#vanilla.c.real_connections+1]={target=h.c,origin=origin} end
M.on_tick(60,g);assert(#vanilla.c.real_connections==0)
assert(M.inspect_pair(1,2)=='script-connected')
g.nodes[1].rail_adjacent=true;g.nodes[1].face='south';g.edges={fake={a=1,b=3}}
M.sync(g);assert(created==3 and s.stats.connected==2)
M.on_parent_removed(p2);p2.destroy();g.nodes[2]=nil;M.sync(g)
assert(s.stats.connected==0 and not s.helpers[2])
assert(M.inspect_pair(1,3)=='not-selected')
M.rebuild_all(g);assert(s.stats.connected==0)
print('046 PASS: bounded nearest-first technical links, separate forces/surfaces/types, zero ghost anchors, unauthorized origins removed, no rail dependency, cleanup')
