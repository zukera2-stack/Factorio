package.path='./ElectrifiedMainline/?.lua;'..package.path
local power=require('scripts.power_019')
local art=require('scripts.catenary_art_030')
local ghost=require('scripts.ghost_mast_023')
local tech=require('scripts.technical_network_046')
storage={};log=function() end
defines={rail_direction={front=1,back=2},rail_connection_direction={straight=1,left=2,right=3},rail_layer={ground=0},
 wire_origin={player=1,script=2},wire_connector_id={pole_copper=5}}
local name='em-35kv-catenary-pole'
local force={name='p'};local surface={index=1};local entities={};local renders={};local serial=0;local nextid=500;local created=0;local refuse=false
local function entity(id,n,x,y)
 local e={valid=true,unit_number=id,name=n,position={x=x,y=y},force=force,surface=surface,direction=4}
 entities[id]=e;return e
end
local function anchor(arg)
 nextid=nextid+1;created=created+1
 local e=entity(nextid,arg.name,arg.position.x,arg.position.y)
 local c={valid=true,owner=e,real_connections={},network_id=22}
 function c.is_connected_to(other,o)
  for _,l in ipairs(c.real_connections) do if l.target==other and l.origin==o then return true end end
  return false
 end
 function c.connect_to(other,reach,o)
  assert(reach==false and o==2 and other.owner.name==e.name)
  if refuse then return false end
  c.real_connections[#c.real_connections+1]={target=other,origin=o}
  other.real_connections[#other.real_connections+1]={target=c,origin=o}
  return true
 end
 local function remove(a,b,o)
  for i=#a.real_connections,1,-1 do local l=a.real_connections[i];if l.target==b and l.origin==o then table.remove(a.real_connections,i) end end
 end
 function c.disconnect_from(other,o) remove(c,other,o);remove(other,c,o);return true end
 function e.get_wire_connector() return c end
 function e.destroy()
  while #c.real_connections>0 do local l=c.real_connections[1];c.disconnect_from(l.target,l.origin) end
  e.valid=false;c.valid=false;entities[e.unit_number]=nil
 end
 return e
end
surface.create_entity=anchor
local function rail(id,x)
 local r=entity(id,'em-high-speed-straight-rail',x,0);r.links={}
 function r.get_connected_rail(q) if q.rail_connection_direction==1 then return r.links[q.rail_direction] end end
 function r.get_rail_end() return nil end
 return r
end
local rails={}
for i=1,7 do rails[i]=rail(100+i,(i-1)*2) end
local function connect()
 for i,r in ipairs(rails) do r.links[1]=rails[i+1];r.links[2]=rails[i-1] end
end
connect()
local p=entity(1,name,0,1.5)
local q=entity(2,'entity-ghost',12,1.5);q.ghost_name=name
local function has(list,x)
 if not list then return true end
 if type(list)=='string' then return list==x end
 for _,v in pairs(list) do if v==x then return true end end;return false
end
function surface.find_entities_filtered(f)
 local out={}
 for _,e in pairs(entities) do if e.valid and has(f.name,e.name) and (not f.ghost_name or f.ghost_name==e.ghost_name) then
  if not f.position or (e.position.x-f.position.x)^2+(e.position.y-f.position.y)^2<=f.radius^2 then out[#out+1]=e end
 end end
 return out
end
function surface.count_entities_filtered(_) return 1 end
game={tick=0,surfaces={[1]=surface},forces={p=force},get_entity_by_unit_number=function(id) return entities[id] end}
rendering={}
function rendering.draw_sprite(arg)
 if arg.sprite and arg.sprite:find("em-25kv-",1,true) then assert(arg.render_layer=="wires","050 wire must draw above train") end
 serial=serial+1
 local o={id=serial,valid=true,arg=arg};function o.destroy() o.valid=false end
 renders[serial]=o;return o
end
function rendering.get_object_by_id(id) return renders[id] end
local function count_tinted_spans()
 local n=0
 for _,o in pairs(renders) do if o.valid and o.arg.tint and o.arg.sprite:find('em-25kv-',1,true) then n=n+1 end end
 return n
end
local function split()
 rails[4].valid=false;rails[3].links[1]=nil;rails[5].links[2]=nil
end
local function restore() rails[4].valid=true;connect() end
local function sync()
 local g=power.graph();tech.sync(g);art.sync(g);return g
end
power.rebuild_all();sync()
local live=power.graph();assert(live.nodes[1] and not live.nodes[2])
local _,spans=power.preview_at(q);assert(#spans==1)
local before=created
assert(ghost.on_built(q));assert(count_tinted_spans()>0 and created==before)
for _,o in pairs(renders) do if o.valid and o.arg.tint and o.arg.sprite=='em-25kv-contact-043' then assert(not art.contact_at(1,force.name,o.arg.target),'ghost preview cannot trigger sparks') end end
assert(not live.nodes[2] and next(live.edges)==nil)
assert(ghost.on_removed(q) and count_tinted_spans()==0)
split()
assert(ghost.on_built(q));assert(count_tinted_spans()==0 and created==before)
assert(ghost.on_removed(q))
restore()
assert(ghost.on_built(q) and count_tinted_spans()>0)
assert(ghost.on_removed(q))
q.name=name;q.ghost_name=nil
power.on_built({entity=q});live=sync()
assert(live.edges['1:2'] and art.inspect_pair(live,1,2)=='drawn')
local s=tech.ensure_storage();local a,b=entities[s.helpers[1]],entities[s.helpers[2]]
assert(a and b and tech.same_component(1,2))
-- Independent cosmetic candidate survives, actual wire and rendering must not.
split();live=sync()
assert(live.edges['1:2'] and not tech.same_component(1,2))
assert(art.inspect_pair(live,1,2)=='no-HSR-path' and art.ensure_storage().stats.drawn==0)
assert(a.valid and b.valid and a.get_wire_connector().network_id==b.get_wire_connector().network_id)
restore();refuse=true;live=sync()
assert(live.edges['1:2'] and not tech.same_component(1,2))
assert(art.inspect_pair(live,1,2)=='technical-split' and art.ensure_storage().stats.blocked==1)
refuse=false;live=sync()
assert(art.inspect_pair(live,1,2)=='drawn')
-- A hypothetical cosmetic A-C span whose only technical connection is A-B-C.
local mid=entity(3,name,6,1.5);power.on_built({entity=mid});live=sync()
assert(tech.inspect_pair(1,2)=='not-selected' and tech.same_component(1,2))
local candidate={nodes=live.nodes,edges={['1:2']={a=1,b=2,kind='contact'}}}
art.sync(candidate);assert(art.inspect_pair(candidate,1,2)=='drawn')
local hmid=entities[s.helpers[3]]
hmid.get_wire_connector().disconnect_from(b.get_wire_connector(),2)
assert(tech.on_tick(60,live) and not tech.same_component(1,2))
art.sync(candidate);assert(art.inspect_pair(candidate,1,2)=='technical-split')
assert(not next(art.ensure_storage().draws))
print('048 PASS: no false visible span on broken HSR/failed native connection, restored span, verified indirect component, audit split, equal network IDs insufficient, ghost dry-run and cleanup')
