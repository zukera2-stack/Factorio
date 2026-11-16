-- 0.1.28 native 35 kV overhead wire: pure Lua geometry + runtime mock QA.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local g=require("scripts.native_wire_geometry_028")
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." != "..tostring(b)) end
local points={
 east={369,143},southeast={344,185},south={368,141},
 southwest={155,192},west={140,149},northwest={150,126},
 north={130,145},northeast={374,123}
}
local size=0
for face,p in pairs(points) do
  size=size+1
  assert(g.sprite_pixels[face][1]==p[1] and g.sprite_pixels[face][2]==p[2])
  local tip=assert(g.tip({x=10,y=20},face))
  near(tip.x,10+(p[1]-256)/64);near(tip.y,20+(p[2]-192)/64)
end
assert(size==8 and not g.tip({x=0,y=0},"bad"))
local south=g.tip({x=0,y=0},"south")
near(south.x,1.75);near(south.y,-0.796875)
local function node(id,x,rail)
  return {id=id,x=x,y=0,name="em-35kv-catenary-pole",face="south",
    rail_id=rail,rail_adjacent=rail~=nil,surface_index=1,force_name="player"}
end
local n1,n2=node(1,0,200),node(2,10,201)
assert(g.key(2,1)=="1:2" and g.eligible(n1,n2))
assert(not g.eligible(n1,node(2,10,nil)))
local wrong=node(2,10,201);wrong.force_name="enemy"
assert(not g.eligible(n1,wrong))
local all={};local next_id=100
local surface={index=1};local force={name="player"}
local function entity(name,id,position)
  local e={name=name,unit_number=id,position=position,surface=surface,
    force=force,valid=true}
  local connector=nil
  function e.get_wire_connector(_,create)
    if not connector and create then
      local c={owner=e,connections={},network_id=1}
      function c.is_connected_to(b)
        for _,x in pairs(c.connections) do
          if x.target==b then return true end
        end
        return false
      end
      function c.can_wire_reach(b)
        local dx=e.position.x-b.owner.position.x
        local dy=e.position.y-b.owner.position.y
        return dx*dx+dy*dy<=400
      end
      function c.connect_to(b,check,origin)
        if check and not c.can_wire_reach(b) or c.is_connected_to(b) then
          return false
        end
        c.connections[#c.connections+1]={target=b,origin=origin}
        b.connections[#b.connections+1]={target=c,origin=origin}
        return true
      end
      function c.disconnect_from(b)
        local removed=false
        for i=#c.connections,1,-1 do
          if c.connections[i].target==b then
            table.remove(c.connections,i);removed=true
          end
        end
        for i=#b.connections,1,-1 do
          if b.connections[i].target==c then table.remove(b.connections,i) end
        end
        return removed
      end
      connector=c
    end
    return connector
  end
  function e.destroy()
    if connector then
      local links={}
      for _,x in pairs(connector.connections) do links[#links+1]=x.target end
      for _,b in ipairs(links) do connector.disconnect_from(b) end
    end
    e.valid=false;all[e.unit_number]=nil
  end
  all[id]=e;return e
end
entity("em-35kv-catenary-pole",1,{x=0,y=0})
entity("em-35kv-catenary-pole",2,{x=10,y=0})
surface.find_entities_filtered=function(filter)
  local names={}
  if type(filter.name)=="table" then
    for _,name in pairs(filter.name) do names[name]=true end
  else names[filter.name]=true end
  local out={}
  for _,e in pairs(all) do
    if names[e.name] and e.valid then out[#out+1]=e end
  end
  return out
end
surface.create_entity=function(spec)
  next_id=next_id+1
  return entity(spec.name,next_id,{x=spec.position.x,y=spec.position.y})
end
storage={}
log=function(_) end
game={surfaces={[1]=surface},get_entity_by_unit_number=function(id) return all[id] end}
defines={wire_connector_id={pole_copper=1},wire_origin={player=1,script=2}}
local wires=require("scripts.native_wire_028")
local graph={["1:2"]={a=1,b=2,kind="contact"}}
local nodes={[1]=n1,[2]=n2}
wires.reset();wires.sync(nodes,{})
assert(next(storage.em.native_wire_028.anchors)==nil)
wires.sync(nodes,graph)
local s=storage.em.native_wire_028
assert(s.anchors[1] and s.anchors[2])
assert(s.last_sync.connected==1 and s.last_sync.failed==0)
local anchor_id=s.anchors[1].anchor_id
wires.sync(nodes,graph)
assert(s.anchors[1].anchor_id==anchor_id)
nodes[2]=node(2,10,nil)
wires.sync(nodes,graph)
assert(next(s.anchors)==nil and next(s.edges)==nil)
nodes[2]=n2;wires.sync(nodes,graph)
local test_anchor=assert(game.get_entity_by_unit_number(s.anchors[1].anchor_id))
local foreign=entity("small-electric-pole",500,{x=2,y=1})
local ca=test_anchor.get_wire_connector(1,true)
local cb=foreign.get_wire_connector(1,true)
assert(ca.connect_to(cb,true,1))
wires.sync(nodes,graph)
assert(not ca.is_connected_to(cb))
wires.sync(nodes,{})
assert(next(s.anchors)==nil and next(s.edges)==nil)
local legacy=entity("em-25kv-wire-probe-anchor",600,{x=0,y=0})
wires.reset();assert(not legacy.valid)
local src=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(src:find("connected_rail_path(n,s.nodes[candidate.id])",1,true))
assert(src:find("and connected_rail_path(a,b)",1,true))
assert(src:find("native_wire028.sync(s.nodes,s.edges)",1,true))
assert(not src:find("rendering.draw_line",1,true))
local ctl=assert(io.open("ElectrifiedMainline/scripts/control.lua")):read("*a")
assert(ctl:find("em-35kv-wire-status",1,true))
assert(ctl:find("native_wire028.reset()",1,true))
assert(not ctl:find('commands.add_command("em-25kv-probe"',1,true))
local proto=assert(io.open("ElectrifiedMainline/prototypes/native_wire_028.lua")):read("*a")
assert(proto:find("auto_connect_up_to_n_wires=0",1,true))
print("0.1.28 all 8 PNG points / HSR graph gate / native wires mock PASS")
