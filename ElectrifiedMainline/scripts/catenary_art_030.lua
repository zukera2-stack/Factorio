-- Electrified Mainline 0.1.30: two-wire sprite pilot on straight HSR.
-- Invisible copper helper stores real connector topology; curved graph remains
-- handled by the previous visible native copper implementation.
local M={}
local geo=require("scripts.native_wire_geometry_028")
local lim=require("scripts.catenary_limits_029")
-- Factorio permits require ONLY during control.lua parsing. Resolve
-- dependencies now, never while on_configuration_changed/on_tick runs.
local native028=require("scripts.native_wire_028")
local PARENT,HELPER="em-35kv-catenary-pole","em-25kv-art-anchor-030"
local HEIGHT=2.53125
local function conn(e,create)
  return e.get_wire_connector(defines.wire_connector_id.pole_copper,create)
end
local function get(id,name)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  if e and e.valid and e.name==name then return e end
end
local function valid_edge(g,e)
  if e.kind~="contact" or e.corner then return false end
  local a,b=g.nodes[e.a],g.nodes[e.b]
  return a and b and a.name==PARENT and b.name==PARENT
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
  local pos=geo.tip(parent.position,node.face,calib)
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
local function draw(s,key,ea,eb)
  local a={x=ea.position.x,y=ea.position.y-HEIGHT}
  local b={x=eb.position.x,y=eb.position.y-HEIGHT}
  local g=M.geometry(a,b)
  if not g then erase(s,key);return false end
  local sig=string.format("%.4f/%.4f/%.4f/%.4f/%d/%d",
    a.x,a.y,b.x,b.y,g.pieces,g.droppers)
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
  segment(ids,ea.surface,"em-25kv-contact-030",a,b,false,128)
  for i=1,g.pieces do
    segment(ids,ea.surface,"em-25kv-messenger-030",
      g.messenger((i-1)/g.pieces),g.messenger(i/g.pieces),false,128)
  end
  for i=1,g.droppers do
    local t=i/(g.droppers+1)
    segment(ids,ea.surface,"em-25kv-dropper-030",
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
      if draw(s,key,ae,be) then keep[key]=true;drawn=drawn+1 end
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
  if not (e and e.valid and e.name==PARENT) then return end
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
    "[EM 25kV] ART030 straight=%d hidden_native=%d sprites=%d missed=%d helpers=%d failures=%d curves=native MW=0",
    v.eligible or 0,v.connected or 0,v.drawn or 0,v.missed or 0,n,v.failures or 0))
end
return M
