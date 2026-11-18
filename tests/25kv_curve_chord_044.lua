-- 0.1.44 regression: curved HSR has a physically tensioned contact CHORD,
-- not a Catmull-Rom rail-centre spline. Uses the actual module, mocked API.
package.path='./ElectrifiedMainline/?.lua;'..package.path
local art=require('scripts.catenary_art_030')
local function near(x,y) return math.abs(x-y)<0.00001 end
local a={x=1,y=0};local b={x=13,y=-3}
local r1={{x=0,y=2},{x=4,y=1},{x=8,y=-1},{x=14,y=-2}}
local r2={{x=200,y=-100},{x=900,y=800},{x=-500,y=600}}
local c=assert(art.curve_geometry(a,b,r1))
local z=assert(art.curve_geometry(a,b,r2))
local short=assert(art.geometry(a,b))
assert(c.pieces>=2 and c.pieces<=16)
assert(c.droppers>=2 and c.droppers<=12)
for _,t in ipairs({0,0.1,0.25,0.50,0.75,0.90,1}) do
  local p=c.contact(t)
  assert(near(p.x,a.x+(b.x-a.x)*t) and near(p.y,a.y+(b.y-a.y)*t),
    'curved contact must be linear between C-bracket tips, including endpoints')
  assert(near(p.x,z.contact(t).x) and near(p.y,z.contact(t).y),
    'wrong 0.1.43 rail-centre Catmull-Rom dependence still present')
  assert(near(p.x,short.contact(t).x) and near(p.y,short.contact(t).y))
  local m=c.messenger(t)
  assert(m.y<p.y,'messenger must stay elevated above contact (screen projection)')
end
assert(near(c.messenger(0).x,a.x) and near(c.messenger(1).x,b.x),
  'steel wire must not leave hanging registration points at the masts')
assert(art.curve_geometry(a,{x=17.1,y=0})==nil,'16-tile curved limit')
assert(art.geometry(a,{x=33.1,y=0})==nil,'32-tile straight limit')
assert(art.curve_geometry({x=0,y=0},{x=0,y=9}),
  'vertical chord should render regardless of curve rail centre approximation')
local gv=art.curve_geometry({x=0,y=0},{x=0,y=9})
assert(gv.messenger(0.5).x>0.20,
  'vertical wire messenger must be visible alongside copper in midspan')

storage={};defines={wire_connector_id={pole_copper=5},wire_origin={player=1}}
local eid=100;local entities={};local objects={};local order={};local surface={index=1}
local force={name='player'}
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
    surface=surface,force=force,valid=true,con=connector()}
  function e.get_wire_connector(id,create) return e.con end
  function e.destroy() e.valid=false;entities[e.unit_number]=nil end
  entities[e.unit_number]=e
  return e
end
local function parent(id,name,pos)
  entities[id]={unit_number=id,name=name,position=pos,surface=surface,
    force=force,valid=true}
end
parent(1,'em-35kv-catenary-pole',{x=0,y=0})
parent(2,'em-35kv-catenary-pole-north',{x=12,y=-3})
local drawn=0
rendering={}
function rendering.draw_sprite(args)
  drawn=drawn+1
  local ob={id=drawn,valid=true,args=args}
  function ob.destroy() ob.valid=false end
  objects[ob.id]=ob;order[#order+1]=ob
  return ob
end
function rendering.get_object_by_id(id) return objects[id] end
game={get_entity_by_unit_number=function(id) return entities[id] end}
local graph={nodes={
 [1]={id=1,name='em-35kv-catenary-pole',face='east',rail_adjacent=true,
    rail_id=10,surface_index=1,force_name='player'},
 [2]={id=2,name='em-35kv-catenary-pole-north',face='west',rail_adjacent=true,
    rail_id=11,surface_index=1,force_name='player'}},
 edges={ab={a=1,b=2,kind='contact',corner=true,route=r1}}}
-- Runtime cannot call require() after parsing: require is resolved above.
local orig_require=require
require=function() error('late require in runtime callback') end
art.sync(graph)
local stats=art.ensure_storage().stats
assert(stats.eligible==1 and stats.connected==1 and stats.drawn==1)
local kinds={contact=0,messenger=0,dropper=0}
for _,ob in ipairs(order) do if ob.valid then
  local s=ob.args.sprite
  if s=='em-25kv-contact-043' then
    kinds.contact=kinds.contact+1
    assert(ob.args.y_scale<=0.50,'copper must not be over-thick')
  elseif s=='em-25kv-messenger-043' then
    kinds.messenger=kinds.messenger+1
    assert(ob.args.y_scale<=0.42,'steel must not render as a pipe')
  elseif s=='em-25kv-dropper-043' then
    kinds.dropper=kinds.dropper+1
    assert(ob.args.x_scale>=1.1,'rivet dropper should be legible')
  else error('wrong sprite '..tostring(s)) end
end end
assert(kinds.contact>=4 and kinds.messenger==kinds.contact and kinds.dropper>=2)
local initial=drawn
art.sync(graph)
assert(drawn==initial,'unchanged spans must reuse sprites, not duplicate')
graph.edges.ab.route=r2
art.sync(graph)
assert(drawn==initial,'render geometry should not depend on unreliable rail-centre route')
graph.edges={}
art.sync(graph)
assert(art.ensure_storage().stats.eligible==0)
for _,ob in ipairs(order) do assert(not ob.valid,'removed rail must erase sprites') end
require=orig_require
local p=assert(io.open('ElectrifiedMainline/scripts/power_019.lua')):read('*a')
assert(not p:find('trace={x=start.position.x',1,true),
  'experimental path trace must not remain in the stable power topology')
local ctext=assert(io.open('ElectrifiedMainline/scripts/control.lua')):read('*a')
assert(ctext:find('native_curve_graph',1,true),
  'native hidden curve topology must remain available')
print('0.1.44 PASS curved-contact chord, connector alignment, slim copper/steel, rivets, no duplicate sprites, Undo rail clean-up')
