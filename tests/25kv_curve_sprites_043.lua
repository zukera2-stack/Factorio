-- 0.1.43 pure-Lua smoke test + mocked renderer integration for 25 kV
-- curve sprites. Does not claim a Factorio screenshot/game acceptance.
package.path="ElectrifiedMainline/?.lua;ElectrifiedMainline/?/init.lua;"..package.path
local art=require('scripts.catenary_art_030')
local function near(a,b) return math.abs(a-b)<1e-6 end
local a,b={x=1,y=0},{x=13,y=-3}
local rails={{x=0,y=2},{x=4,y=1},{x=8,y=-1},{x=14,y=-2}}
local g=assert(art.curve_geometry(a,b,rails),"curve requires sampled path")
assert(g.pieces>=4 and g.pieces<=48)
assert(g.droppers>=2 and g.droppers<=8)
assert(near(g.contact(0).x,a.x) and near(g.contact(0).y,a.y))
assert(near(g.contact(1).x,b.x) and near(g.contact(1).y,b.y))
assert(g.messenger(0.5).y<g.contact(0.5).y)
local m=g.contact(0.5)
local chord={x=(a.x+b.x)/2,y=(a.y+b.y)/2}
assert(math.abs(m.y-chord.y)>0.03,"curved rail art must not be a straight chord")
assert(art.curve_geometry(a,b,nil)==nil,"missing route must not render fake curve")
assert(art.curve_geometry(a,{x=20,y=0},rails)==nil,"curved span limit=16")
assert(art.geometry(a,b),"previous straight geometry still works")
assert(art.curve_geometry({x=0,y=0},{x=5,y=1},{{x=2,y=2}}),"one rail fallback")
assert(art.curve_geometry({x=0,y=0},{x=5,y=1},{{x=0,y=1},{x=5,y=2}}),"two-rail fallback")

-- Supply just the native minimal rendering API to exercise the actual
-- art030.sync() path, including copper, steel and riveted dropper sprites.
local rendered={}; local entities={}; local eid=100
local surface={index=1}; local force={name='player'}
local function connector()
  local c={real_connections={},connected={}}
  function c.can_wire_reach(other) return true end
  function c.is_connected_to(other,origin) return c.connected[other]==true end
  function c.connect_to(other,preserve,origin) c.connected[other]=true;return true end
  function c.disconnect_from(other,origin) c.connected[other]=nil;return true end
  return c
end
function surface.create_entity(args)
  eid=eid+1
  local e={unit_number=eid,name=args.name,position=args.position,
    surface=surface,force=force,valid=true,connect=connector()}
  function e.get_wire_connector(id,create) return e.connect end
  function e.destroy() e.valid=false end
  entities[eid]=e
  return e
end
local function parent(id,name,pos)
  local e={unit_number=id,name=name,position=pos,surface=surface,force=force,valid=true}
  entities[id]=e
end
parent(1,'em-35kv-catenary-pole',{x=0,y=0})
parent(2,'em-35kv-catenary-pole-north',{x=12,y=-3})
_G.storage={}
_G.defines={wire_connector_id={pole_copper=5},wire_origin={player=1}}
_G.game={get_entity_by_unit_number=function(id) return entities[id] end}
_G.rendering={}
function rendering.draw_sprite(arg)
  local id=#rendered+1
  rendered[id]={id=id,valid=true,arg=arg}
  return rendered[id]
end
function rendering.get_object_by_id(id) return rendered[id] end
-- Call no native-curved manager; only the art manager's calibrated helpers.
local graph={nodes={
 [1]={id=1,name='em-35kv-catenary-pole',face='east',rail_adjacent=true,
       rail_id=10,surface_index=1,force_name='player'},
 [2]={id=2,name='em-35kv-catenary-pole-north',face='west',rail_adjacent=true,
       rail_id=11,surface_index=1,force_name='player'},
},edges={['1:2']={a=1,b=2,kind='contact',corner=true,
    route={{x=1,y=2},{x=4,y=1},{x=8,y=-1},{x=11,y=-2}}}}}
art.sync(graph)
local stats=art.ensure_storage().stats
assert(stats.eligible==1 and stats.connected==1 and stats.drawn==1,
  'curve art must be actually drawn by sync()')
local hit={contact=0,messenger=0,dropper=0}
for _,r in ipairs(rendered) do
  if r.valid then
    local name=r.arg.sprite
    if name=='em-25kv-contact-043' then hit.contact=hit.contact+1 end
    if name=='em-25kv-messenger-043' then hit.messenger=hit.messenger+1 end
    if name=='em-25kv-dropper-043' then hit.dropper=hit.dropper+1 end
  end
end
assert(hit.contact>4 and hit.messenger>4 and hit.dropper>=2,
  'curve needs all three 043 sprite families')
-- Redrawing the same graph must reuse valid LuaRendering objects.
local n=#rendered
art.sync(graph)
assert(#rendered==n,'unchanged geometry must not redraw every tick')
print('PASS 0.1.43 curve contact/messenger/dropper sprites + geometry + reuse ('..
    hit.contact..'/'..hit.messenger..'/'..hit.dropper..')')
