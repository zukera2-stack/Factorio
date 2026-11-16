-- 0.1.30 isolated pure Lua test: helper native links remain real,
-- while straight wire body is drawn only with textured sprites.
package.path="./ElectrifiedMainline/?.lua;"..package.path
storage={}
defines={wire_origin={player=1},wire_connector_id={pole_copper=3}}
local next_id=100
local all={}
local surface={index=1}
local force={name="player"}
local objects={}
local function new_entity(name,pos)
  next_id=next_id+1
  local e={name=name,position={x=pos.x,y=pos.y},
    unit_number=next_id,valid=true,surface=surface,force=force}
  all[e.unit_number]=e
  function e.destroy()
    e.valid=false
    all[e.unit_number]=nil
  end
  local c={real_connections={},owner=e,valid=true}
  function c.can_wire_reach(_) return true end
  function c.is_connected_to(other)
    for _,v in ipairs(c.real_connections) do
      if v.target==other then return true end
    end
    return false
  end
  function c.connect_to(other,check,origin)
    if c.is_connected_to(other) then return false end
    c.real_connections[#c.real_connections+1]={target=other,origin=origin}
    other.real_connections[#other.real_connections+1]={target=c,origin=origin}
    return true
  end
  function c.disconnect_from(other,origin)
    local function remove(l,t)
      for i=#l,1,-1 do
        if l[i].target==t and l[i].origin==origin then table.remove(l,i) end
      end
    end
    remove(c.real_connections,other);remove(other.real_connections,c)
    return true
  end
  function e.get_wire_connector(_) return c end
  return e
end
function surface.create_entity(args) return new_entity(args.name,args.position) end
function surface.find_entities_filtered(args)
  local out={}
  for _,e in pairs(all) do if e.valid and e.name==args.name then
    out[#out+1]=e
  end end
  return out
end
game={surfaces={[1]=surface},
  get_entity_by_unit_number=function(id)return all[id] end}
log=function(_)end
rendering={
  draw_sprite=function(args)
    assert(args.sprite:find("em-25kv-",1,true))
    assert(args.render_layer=="object")
    assert(args.surface==surface)
    next_id=next_id+1
    local o={id=next_id,valid=true,args=args}
    function o.destroy()o.valid=false end
    objects[o.id]=o
    return o
  end,
  get_object_by_id=function(id)return objects[id] end,
}
local a=new_entity("em-35kv-catenary-pole",{x=0,y=0})
local b=new_entity("em-35kv-catenary-pole",{x=30,y=0})
local nodes={
 [a.unit_number]={id=a.unit_number,name=a.name,face="south",
   rail_adjacent=true,rail_id=1,surface_index=1,force_name="player"},
 [b.unit_number]={id=b.unit_number,name=b.name,face="south",
   rail_adjacent=true,rail_id=2,surface_index=1,force_name="player"},
}
local graph={nodes=nodes,edges={ab={a=a.unit_number,b=b.unit_number,kind="contact"}}}
local art=require("scripts.catenary_art_030")
-- Regression for user crash on 2026-11-16: Factorio does NOT allow
-- require after control.lua parsing. Simulate this engine restriction
-- throughout the entire configuration-change and tick lifecycle.
local original_require=require
require=function(name)
  error("Require can't be used outside of control.lua parsing: "..tostring(name))
end
art.rebuild_all(graph)
-- SOUTH side poles face NORTH. Actual copper helper is unmodified.
local north=art.visual_point({x=8,y=10},"north")
local south=art.visual_point({x=8,y=10},"south")
local east=art.visual_point({x=8,y=10},"east")
assert(math.abs(north.x-7.78)<1e-6)
assert(math.abs(north.y-(10-2.53125+0.90))<1e-6)
assert(math.abs(south.x-8)<1e-6)
assert(math.abs(south.y-(10-2.53125))<1e-6)
assert(math.abs(east.x-south.x)<1e-6 and math.abs(east.y-south.y)<1e-6)
local state=art.ensure_storage()
assert(state.stats.eligible==1 and state.stats.connected==1)
assert(state.stats.drawn==1 and state.stats.missed==0)
assert(state.helpers[a.unit_number] and state.helpers[b.unit_number])
local function count()
  local n=0
  for _,o in pairs(objects) do if o.valid then n=n+1 end end
  return n
end
local original=count()
assert(original>=8 and original<=25,original)
art.sync(graph)
assert(count()==original,"unchanged sprite geometry must reuse IDs")
assert(art.geometry({x=0,y=0},{x=32,y=0}).droppers>=5)
assert(not art.geometry({x=0,y=0},{x=33,y=0}))
nodes[a.unit_number].face="north"
nodes[b.unit_number].face="north"
art.sync(graph)
assert(state.stats.connected==1 and state.stats.drawn==1)
local found=false
for _,obj in pairs(objects) do
  if obj.valid and obj.args.sprite=="em-25kv-contact-030" then
    found=true
    local helper=all[state.helpers[a.unit_number].id]
    assert(helper and helper.valid)
    assert(math.abs(obj.args.target.y-(helper.position.y-2.53125+0.90))<1e-6)
  end
end
assert(found,"north-facing sprite should render at corrected coordinate")
graph.edges.ab.corner=true
art.sync(graph)
assert(state.stats.eligible==0 and not next(state.helpers))
assert(count()==0,"curve must use visible native copper fallback")
graph.edges.ab.corner=false
art.sync(graph)
assert(state.stats.connected==1 and count()>0)
graph.edges={}
art.sync(graph)
assert(state.stats.connected==0 and not next(state.draws))
assert(count()==0)
art.on_tick(60,graph)
art.on_tick(600,graph)
require=original_require
local p=assert(io.open("ElectrifiedMainline/prototypes/catenary_art_030.lua")):read("*a")
assert(p:find("h.draw_copper_wires=false",1,true))
local c=assert(io.open("ElectrifiedMainline/scripts/control.lua")):read("*a")
assert(c:find("native_curve_graph(graph)",1,true))
print("0.1.32 north-face south-side sprite calibration and runtime require guard PASS")
