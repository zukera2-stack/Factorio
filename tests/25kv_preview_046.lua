package.path='./ElectrifiedMainline/?.lua;'..package.path
local power=require('scripts.power_019')
local art=require('scripts.catenary_art_030')
local ghost=require('scripts.ghost_mast_023')
storage={};log=function() end
defines={rail_direction={front=1,back=2},rail_connection_direction={straight=1,left=2,right=3},rail_layer={ground=0}}
local name='em-35kv-catenary-pole'
local force={name='p'};local surface={index=1};local entities={};local renders={};local serial=0
local function entity(id,n,x,y)
 local e={valid=true,unit_number=id,name=n,position={x=x,y=y},force=force,surface=surface,direction=4}
 entities[id]=e;return e
end
local rail=entity(100,'em-high-speed-straight-rail',0,0)
function rail.get_connected_rail() return nil end
function rail.get_rail_end() return nil end
local p=entity(1,name,0,1.5)
local q=entity(2,'entity-ghost',2,1.5);q.ghost_name=name
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
 serial=serial+1
 local o={id=serial,valid=true,arg=arg};function o.destroy() o.valid=false end
 renders[serial]=o;return o
end
function rendering.get_object_by_id(id) return renders[id] end
power.rebuild_all()
local live=power.graph();assert(live.nodes[1] and not live.nodes[2])
local _,spans=power.preview_at(q)
assert(#spans==1,'placed ghost should predict same straight span')
assert(next(live.edges)==nil and not live.nodes[2])
assert(ghost.on_built(q))
local tinted=0
for _,o in pairs(renders) do if o.valid and o.arg.tint then tinted=tinted+1 end end
assert(tinted>1)
local serial1=serial;assert(ghost.on_built(q) and serial==serial1)
assert(ghost.on_removed(q))
for _,o in pairs(renders) do assert(not(o.valid and o.arg.tint)) end
q.name=name;q.ghost_name=nil
power.on_built({entity=q});assert(next(power.graph().edges))
art.sync(power.graph());assert(art.ensure_storage().stats.drawn==1)
print('046 PASS: actual ghost dry-run uses same visual candidates, no graph mutation, tinted spans, cancellation, revival match')
