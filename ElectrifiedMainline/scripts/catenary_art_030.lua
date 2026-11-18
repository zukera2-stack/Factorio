-- Electrified Mainline 0.1.43: native helper topology with Factorio-style PNG
-- contact (copper), steel messenger and riveted dropper for straight and curves.
-- Curve art follows connected custom rail centre traces, not a bare chord.
local M={}
local geo=require("scripts.native_wire_geometry_028")
local lim=require("scripts.catenary_limits_029")
-- Factorio permits require ONLY during control.lua parsing. Resolve
-- dependencies now, never while on_configuration_changed/on_tick runs.
local native028=require("scripts.native_wire_028")
local mast035=require("scripts.mast_visual_034")
local PARENT,HELPER="em-35kv-catenary-pole","em-25kv-art-anchor-030"
local NORTH="em-35kv-catenary-pole-north"
local function is_parent(name) return name==PARENT or name==NORTH end
local HEIGHT=2.53125
-- The C mast SOUTH of the rails faces NORTH toward the line.
-- This adjustment affects ONLY custom sprite drawing, not native helpers.
local VISUAL_OFFSET={north={x=-0.22,y=0.90}}
function M.visual_point(helper_floor,face,prototype_name)
  local o=VISUAL_OFFSET[face]
  return {
    x=helper_floor.x+(o and o.x or 0),
    y=helper_floor.y-HEIGHT+(o and o.y or 0)
      +mast035.visual_delta(prototype_name,face)
  }
end
local function conn(e,create)
  return e.get_wire_connector(defines.wire_connector_id.pole_copper,create)
end
local function get(id,name)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  if e and e.valid and (e.name==name or (name==PARENT and is_parent(e.name))) then return e end
end
local function valid_edge(g,e)
  if e.kind~="contact" then return false end
  local a,b=g.nodes[e.a],g.nodes[e.b]
  return a and b and is_parent(a.name) and is_parent(b.name)
    and a.rail_adjacent and b.rail_adjacent and a.rail_id and b.rail_id
    and a.surface_index==b.surface_index and a.force_name==b.force_name
end
function M.ensure_storage()
  storage.em=storage.em or {}
  storage.em.art_030=storage.em.art_030 or {helpers={},draws={},stats={},dirty=true}
  local s=storage.em.art_030
  s.helpers=s.helpers or {};s.draws=s.draws or {};s.stats=s.stats or {}
  return s
end
local function erase(s,key)
  local row=s.draws[key]
  if row then
    for _,id in pairs(row.ids or {}) do
      local obj=rendering.get_object_by_id(id)
      if obj and obj.valid then obj.destroy() end
    end
    s.draws[key]=nil
  end
end
local function destroy(row)
  local e=get(row and row.id,HELPER)
  if e then e.destroy() end
end
local function anchor(s,id,node,calib)
  local parent=get(id,PARENT)
  if not parent then return nil end
  local pos=geo.tip_for_pole(parent.position,node.face,calib,parent.name)
  if not pos then return nil end
  local row=s.helpers[id]
  local e=get(row and row.id,HELPER)
  if e and (row.face~=node.face or not geo.same_pos(e.position,pos)
     or e.surface.index~=parent.surface.index or e.force.name~=parent.force.name) then
    e.destroy();e=nil
  end
  if not e then
    e=parent.surface.create_entity{
      name=HELPER,position=pos,force=parent.force,snap_to_grid=false,
      raise_built=false,create_build_effect_smoke=false}
    if not (e and e.valid and e.unit_number) then s.helpers[id]=nil;return nil end
    e.destructible=false
  end
  s.helpers[id]={id=e.unit_number,face=node.face}
  return e
end
local function segment(ids,surface,sprite,a,b,vertical,pixels)
  local dx,dy=b.x-a.x,b.y-a.y
  local d=math.sqrt(dx*dx+dy*dy)
  if d<0.001 then return end
  local theta=math.atan2(dy,dx)
  if vertical then theta=theta-math.pi/2 end
  local arg={
    sprite=sprite,surface=surface,
    target={x=(a.x+b.x)/2,y=(a.y+b.y)/2},
    orientation=(theta/(2*math.pi))%1,
    render_layer="object"}
  if vertical then arg.y_scale=d*32/pixels
  else arg.x_scale=d*32/pixels end
  local obj=rendering.draw_sprite(arg)
  ids[#ids+1]=obj.id
end
function M.geometry(a,b)
  local dx,dy=b.x-a.x,b.y-a.y
  local len=math.sqrt(dx*dx+dy*dy)
  if len<0.1 or len>lim.STRAIGHT+0.001 then return nil end
  local function contact(t)
    return {x=a.x+dx*t,y=a.y+dy*t}
  end
  local function messenger(t)
    local p=contact(t)
    p.y=p.y-0.68+0.27*4*t*(1-t)
    return p
  end
  return {len=len,contact=contact,messenger=messenger,
    pieces=math.max(3,math.min(12,math.ceil(len/3.2))),
    droppers=math.max(2,math.min(8,math.floor(len/3.5)))}
end
-- Sample an ordered set of connected rail entity centres, translated to
-- the actual wire attachment positions. Catmull-Rom smooths the rail trace.
-- We do not draw a guessed curve over disconnected/unrelated vanilla rails:
-- only a route produced by the bounded HSR rail walk is accepted.
local function distance(a,b)
  local dx,dy=a.x-b.x,a.y-b.y
  return math.sqrt(dx*dx+dy*dy)
end
local function lerp(a,b,t) return a+(b-a)*t end
local function catmull(a,b,c,d,t)
  local t2,t3=t*t,t*t*t
  return 0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t2+
      (-a+3*b-3*c+d)*t3)
end
local function route_points(a,b,rail)
  if not rail or #rail==0 then return nil end
  local points={{x=a.x,y=a.y}}
  if #rail>2 then
    local span=0
    for i=2,#rail do span=span+distance(rail[i-1],rail[i]) end
    local walked=0
    for i=2,#rail-1 do
      walked=walked+distance(rail[i-1],rail[i])
      local t=span>0 and walked/span or (i-1)/(#rail-1)
      local ox=lerp(a.x-rail[1].x,b.x-rail[#rail].x,t)
      local oy=lerp(a.y-rail[1].y,b.y-rail[#rail].y,t)
      local x,y=rail[i].x+ox,rail[i].y+oy
      if distance(points[#points],{x=x,y=y})>0.20 then
        points[#points+1]={x=x,y=y}
      end
    end
  elseif #rail==1 then
    -- A and B can both be attached to the same curved rail entity.
    -- A gentle bend toward its centre preserves a visible turn; this is
    -- an approximation, NOT the precise engine rail spline.
    local cx,cy=(a.x+b.x)/2,(a.y+b.y)/2
    local dx,dy=b.x-a.x,b.y-a.y
    local d=math.sqrt(dx*dx+dy*dy)
    if d>0.1 then
      local side=(rail[1].x-cx)*(-dy/d)+(rail[1].y-cy)*(dx/d)
      local bend=math.max(-0.75,math.min(0.75,side*0.4))
      points[#points+1]={x=cx-dy/d*bend,y=cy+dx/d*bend}
    end
  elseif #rail==2 then
    -- Two rail centres alone cannot describe the actual curved track.
    -- Bias the midpoint mildly toward the rail-side offset to avoid
    -- pretending that the precise Bezier control points are known.
    local cx,cy=(a.x+b.x)/2,(a.y+b.y)/2
    local rx,ry=(rail[1].x+rail[2].x)/2,(rail[1].y+rail[2].y)/2
    local dx,dy=b.x-a.x,b.y-a.y
    local d=math.sqrt(dx*dx+dy*dy)
    if d>0.1 then
      local side=(rx-cx)*(-dy/d)+(ry-cy)*(dx/d)
      local bend=math.max(-0.45,math.min(0.45,side*0.10))
      points[#points+1]={x=cx-dy/d*bend,y=cy+dx/d*bend}
    end
  end
  points[#points+1]={x=b.x,y=b.y}
  return points
end
function M.curve_geometry(a,b,rail)
  local points=route_points(a,b,rail)
  if not points then return nil end
  if distance(a,b)>lim.CURVE+0.001 then return nil end
  local dense={points[1]}
  for i=1,#points-1 do
    local p0=points[math.max(1,i-1)]
    local p1=points[i]
    local p2=points[i+1]
    local p3=points[math.min(#points,i+2)]
    local n=math.max(2,math.min(12,math.ceil(distance(p1,p2)/0.75)))
    for j=1,n do
      local t=j/n
      dense[#dense+1]={
        x=catmull(p0.x,p1.x,p2.x,p3.x,t),
        y=catmull(p0.y,p1.y,p2.y,p3.y,t)}
    end
  end
  local lengths={0}
  for i=2,#dense do
    lengths[i]=lengths[i-1]+distance(dense[i-1],dense[i])
  end
  local total=lengths[#lengths]
  if total<0.1 or total>lim.CURVE*1.65+0.001 then return nil end
  local function contact(t)
    local target=total*math.max(0,math.min(1,t))
    for i=2,#dense do
      if target<=lengths[i] then
        local ds=lengths[i]-lengths[i-1]
        local f=ds>0 and (target-lengths[i-1])/ds or 0
        return {x=lerp(dense[i-1].x,dense[i].x,f),
                y=lerp(dense[i-1].y,dense[i].y,f)}
      end
    end
    return {x=b.x,y=b.y}
  end
  local function messenger(t)
    local v=contact(t)
    v.y=v.y-0.68+0.27*4*t*(1-t)
    return v
  end
  return {len=total,contact=contact,messenger=messenger,
    pieces=math.max(4,math.min(48,math.ceil(total/0.65))),
    droppers=math.max(2,math.min(8,math.floor(total/3.5)))}
end
local function draw(s,key,ea,eb,face_a,face_b,name_a,name_b,edge)
  local a=M.visual_point(ea.position,face_a,name_a)
  local b=M.visual_point(eb.position,face_b,name_b)
  local g
  if edge and edge.corner then
    g=M.curve_geometry(a,b,edge.route)
  else
    g=M.geometry(a,b)
  end
  if not g then erase(s,key);return false end
  local sig=string.format("%.4f/%.4f/%.4f/%.4f/%d/%d/%s",
    a.x,a.y,b.x,b.y,g.pieces,g.droppers,
    edge and edge.corner and "curve" or "straight")
  if edge and edge.corner then
    for _,p in ipairs(edge.route or {}) do
      sig=sig..string.format("/%.3f,%.3f",p.x,p.y)
    end
  end
  local previous=s.draws[key]
  if previous and previous.sig==sig then
    local good=true
    for _,id in pairs(previous.ids) do
      local obj=rendering.get_object_by_id(id)
      if not (obj and obj.valid) then good=false;break end
    end
    if good then return true end
  end
  erase(s,key)
  local ids={}
  for i=1,g.pieces do
    segment(ids,ea.surface,"em-25kv-contact-043",
      g.contact((i-1)/g.pieces),g.contact(i/g.pieces),false,128)
  end
  for i=1,g.pieces do
    segment(ids,ea.surface,"em-25kv-messenger-043",
      g.messenger((i-1)/g.pieces),g.messenger(i/g.pieces),false,128)
  end
  for i=1,g.droppers do
    local t=i/(g.droppers+1)
    segment(ids,ea.surface,"em-25kv-dropper-043",
      g.messenger(t),g.contact(t),true,32)
  end
  s.draws[key]={ids=ids,sig=sig}
  return true
end
local function audit(s,adj)
  local reverse={}
  for parent,row in pairs(s.helpers) do reverse[row.id]=parent end
  local stripped=0
  for parent,row in pairs(s.helpers) do
    local e=get(row.id,HELPER)
    if e then
      local c=conn(e,false)
      if c then
        for _,link in pairs(c.real_connections) do
          local target=link.target
          local owner=target and target.valid and target.owner
          local other=owner and owner.valid and reverse[owner.unit_number]
          if not (other and adj[parent] and adj[parent][other]
            and link.origin==defines.wire_origin.player) then
            if target and target.valid and
               c.disconnect_from(target,link.origin or defines.wire_origin.player) then
              stripped=stripped+1
            end
          end
        end
      end
    end
  end
  return stripped
end
function M.sync(graph)
  local s=M.ensure_storage()
  local adj,edges={},{}
  for key,e in pairs(graph.edges or {}) do
    if valid_edge(graph,e) then
      edges[key]=e
      adj[e.a]=adj[e.a] or {};adj[e.b]=adj[e.b] or {}
      adj[e.a][e.b]=true;adj[e.b][e.a]=true
    end
  end
  for id,row in pairs(s.helpers) do
    if not adj[id] or not get(id,PARENT) then
      destroy(row);s.helpers[id]=nil
    end
  end
  local calibration=native028.ensure_storage().calibration
  local failures=0
  for id in pairs(adj) do
    if not anchor(s,id,graph.nodes[id],calibration) then failures=failures+1 end
  end
  local stripped=audit(s,adj)
  local connected,missed,drawn,eligible=0,0,0,0
  local keep={}
  for key,e in pairs(edges) do
    eligible=eligible+1
    local ar,br=s.helpers[e.a],s.helpers[e.b]
    local ae=get(ar and ar.id,HELPER)
    local be=get(br and br.id,HELPER)
    local ca=ae and conn(ae,true)
    local cb=be and conn(be,true)
    if ca and cb and ca.can_wire_reach(cb)
       and (ca.is_connected_to(cb,defines.wire_origin.player)
          or ca.connect_to(cb,true,defines.wire_origin.player)) then
      connected=connected+1
      if draw(s,key,ae,be,graph.nodes[e.a].face,graph.nodes[e.b].face,
          graph.nodes[e.a].name,graph.nodes[e.b].name,e) then
        keep[key]=true;drawn=drawn+1
      end
    else missed=missed+1 end
  end
  for key in pairs(s.draws) do
    if not keep[key] then erase(s,key) end
  end
  s.stats={eligible=eligible,connected=connected,drawn=drawn,missed=missed,
    failures=failures,stripped=stripped}
  s.dirty=false
end
function M.rebuild_all(graph)
  local s=M.ensure_storage()
  for key in pairs(s.draws) do erase(s,key) end
  for _,surface in pairs(game.surfaces) do
    for _,e in pairs(surface.find_entities_filtered{name=HELPER}) do
      if e.valid then e.destroy() end
    end
  end
  s.helpers={};s.draws={};s.dirty=true
  M.sync(graph)
end
function M.mark_dirty() M.ensure_storage().dirty=true end
function M.on_parent_removed(e)
  if not (e and e.valid and is_parent(e.name)) then return end
  local s=M.ensure_storage()
  if s.helpers[e.unit_number] then
    destroy(s.helpers[e.unit_number]);s.helpers[e.unit_number]=nil
  end
  s.dirty=true
end
function M.on_tick(tick,graph)
  local s=M.ensure_storage()
  if s.dirty or (tick%600==0 and next(s.helpers)) then M.sync(graph) end
  if tick%60==0 and next(s.helpers) then
    local adj={}
    for _,e in pairs(graph.edges or {}) do
      if valid_edge(graph,e) then
        adj[e.a]=adj[e.a] or {};adj[e.b]=adj[e.b] or {}
        adj[e.a][e.b]=true;adj[e.b][e.a]=true
      end
    end
    local n=audit(s,adj)
    if n>0 then log("[EM 25kV] art 030 stripped "..n.." unauthorized links") end
  end
end
function M.status(player)
  local s=M.ensure_storage()
  local n=0;for _ in pairs(s.helpers) do n=n+1 end
  local v=s.stats
  player.print(string.format(
    "[EM 25kV] ART043 spans=%d hidden_native=%d sprites=%d missed=%d helpers=%d failures=%d curves=sprites MW=0",
    v.eligible or 0,v.connected or 0,v.drawn or 0,v.missed or 0,n,v.failures or 0))
end
return M
