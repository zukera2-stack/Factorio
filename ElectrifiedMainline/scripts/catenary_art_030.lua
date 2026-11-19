-- 0.1.48: same cosmetic candidates and geometry; render only confirmed technical continuity.
local M={}
local lim=require("scripts.catenary_limits_029")
-- Factorio permits require ONLY during control.lua parsing. Resolve
-- dependencies now, never while on_configuration_changed/on_tick runs.
local visible=require("scripts.catenary_visual_geometry_045")
local PARENT,HELPER="em-35kv-catenary-pole","em-25kv-art-anchor-030"
local NORTH="em-35kv-catenary-pole-north"
local function is_parent(name) return name==PARENT or name==NORTH end
-- Visible geometry is deliberately independent of legacy hidden helpers.
local function get(id,name)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  if e and e.valid and (e.name==name or (name==PARENT and is_parent(e.name))) then return e end
end
local function valid_edge(g,e)
  if e.kind~="contact" then return false end
  local a,b=g.nodes[e.a],g.nodes[e.b]
  return a and b and is_parent(a.name) and is_parent(b.name)
    and e.axis==true
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
-- The 045 pixel geometry and chord renderer are retained.
local function segment(ids,surface,sprite,a,b,vertical,pixels,outer_a,outer_b,preview)
  local dx,dy=b.x-a.x,b.y-a.y
  local d=math.sqrt(dx*dx+dy*dy)
  if d<0.001 then return end
  local theta=math.atan2(dy,dx)
  if vertical then theta=theta-math.pi/2 end
  local arg={
    sprite=sprite,surface=surface,
    target={x=(a.x+b.x)/2,y=(a.y+b.y)/2},
    orientation=(theta/(2*math.pi))%1,
    -- Overhead conductors must render above ground rolling stock and pantograph.
    render_layer="wires"}
  if vertical then
    arg.y_scale=d*32/pixels
    arg.x_scale=1.14 -- make rivet heads on the droppers more legible
  else
    -- 0.1.43 source steel pixel thickness was 8px, close to a metal PIPE.
    -- Keep the approved sprite artwork but render a wire-sized cross-section.
    -- End-cap overlap (<1px per joint) prevents tiled rotated-sprite pinholes.
    local u,v=outer_a and 0 or 0.4,outer_b and 0 or 0.4
    arg.x_scale=(d*32+u+v)/pixels
    arg.target.x=arg.target.x+(v-u)/64*dx/d
    arg.target.y=arg.target.y+(v-u)/64*dy/d
    if sprite=="em-25kv-messenger-043" then
      arg.y_scale=0.40
    else
      arg.y_scale=0.48
    end
  end
  if preview then arg.tint=preview.tint;arg.forces=preview.forces end
  local obj=rendering.draw_sprite(arg)
  ids[#ids+1]=obj.id
end
local function span_geometry(a,b,ma,mb,curve)
  local dx,dy=b.x-a.x,b.y-a.y
  local len=math.sqrt(dx*dx+dy*dy)
  local limit=lim.STRAIGHT+4 -- same cosmetic reach on curves and straights
  if len<0.1 or len>limit+0.001 then return nil end
  local pieces=math.max(2,math.min(12,math.ceil(len/2.4)))
  local function lerp(p,q,t)
    return {x=p.x+(q.x-p.x)*t,y=p.y+(q.y-p.y)*t}
  end
  local function contact(t) return lerp(a,b,t) end
  -- Limited readability bow only on near-vertical spans, zero at ends.
  local lateral=0.24*math.max(0,1-math.abs(dx)/len/0.25)
  local points={}
  for i=0,pieces do
    local t=i/pieces
    local p=lerp(ma,mb,t)
    local sag=4*t*(1-t)
    p.x=p.x+lateral*sag
    p.y=p.y+0.23*sag
    points[i]=p
  end
  -- Droppers terminate exactly on the drawn steel segment.
  local function messenger(t)
    if t<=0 then return points[0] end
    if t>=1 then return points[pieces] end
    local z=t*pieces
    local i=math.floor(z)
    return lerp(points[i],points[i+1],z-i)
  end
  return {len=len,contact=contact,messenger=messenger,pieces=pieces,
    droppers=math.max(2,math.min(12,math.floor(len/2.4)))}
end
function M.geometry(a,b,ma,mb)
  return span_geometry(a,b,ma,mb,false)
end
function M.curve_geometry(a,b,ma,mb)
  return span_geometry(a,b,ma,mb,true)
end
local function draw_geometry(surface,g,preview)
  local ids={}
  for i=1,g.pieces do
    segment(ids,surface,"em-25kv-contact-043",
      g.contact((i-1)/g.pieces),g.contact(i/g.pieces),false,128,i==1,i==g.pieces,preview)
  end
  for i=1,g.pieces do
    segment(ids,surface,"em-25kv-messenger-043",
      g.messenger((i-1)/g.pieces),g.messenger(i/g.pieces),false,128,i==1,i==g.pieces,preview)
  end
  for i=1,g.droppers do
    local t=i/(g.droppers+1)
    segment(ids,surface,"em-25kv-dropper-043",
      g.messenger(t),g.contact(t),true,32,nil,nil,preview)
  end
  return ids
end
function M.preview_span(surface,force,na,nb,curve)
  local va,vb=visible.points(na,na.name,na.face),visible.points(nb,nb.name,nb.face)
  if not (va and vb) then return {} end
  local g=span_geometry(va.contact,vb.contact,va.messenger,vb.messenger,curve)
  if not g then return {} end
  return draw_geometry(surface,g,{tint={r=.53,g=.84,b=1,a=.48},forces={force}})
end
function M.clear_preview(ids)
  for _,id in ipairs(ids or {}) do
    local obj=rendering.get_object_by_id(id)
    if obj and obj.valid then obj.destroy() end
  end
end
local function draw(s,key,na,nb,edge)
  local pa,pb=get(edge.a,PARENT),get(edge.b,PARENT)
  if not (pa and pb) then erase(s,key);return false end
  local va,vb=visible.points(pa.position,na.name,na.face),
              visible.points(pb.position,nb.name,nb.face)
  if not (va and vb) then erase(s,key);return false end
  local a,b,ma,mb=va.contact,vb.contact,va.messenger,vb.messenger
  local g
  if edge.corner then g=M.curve_geometry(a,b,ma,mb)
  else g=M.geometry(a,b,ma,mb) end
  if not g then erase(s,key);return false end
  local sig=string.format("052-wires/%.6f/%.6f/%.6f/%.6f/%.6f/%.6f/%.6f/%.6f/%d/%d/%s",
    a.x,a.y,b.x,b.y,ma.x,ma.y,mb.x,mb.y,g.pieces,g.droppers,
    edge and edge.corner and "curve" or "straight")
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
  local ids=draw_geometry(pa.surface,g)
  s.draws[key]={ids=ids,sig=sig,contact_a=a,contact_b=b,contact_pieces=g.pieces,
    surface_index=na.surface_index,force_name=na.force_name}
  return true
end
local CELL=16
local function cell_key(surface,force,x,y)
  return tostring(surface)..":"..force..":"..x..":"..y
end
local function index_contacts(s)
  local index={}
  for k,row in pairs(s.draws) do
    local a,b=row.contact_a,row.contact_b
    if a and b then
      for x=math.floor((math.min(a.x,b.x)-.45)/CELL),math.floor((math.max(a.x,b.x)+.45)/CELL) do
        for y=math.floor((math.min(a.y,b.y)-.45)/CELL),math.floor((math.max(a.y,b.y)+.45)/CELL) do
          local id=cell_key(row.surface_index,row.force_name,x,y)
          index[id]=index[id] or {};index[id][#index[id]+1]=k
        end
      end
    end
  end
  s.contact_index=index
end
-- Already projected sprite coordinates. Only actual drawn contact IDs;
-- preview, messenger, ghost and predicted links never enter this index.
function M.contact_at(surface,force,p)
  local s=M.ensure_storage()
  if s.dirty then return nil end
  local keys=s.contact_index and s.contact_index[cell_key(surface,force,math.floor(p.x/CELL),math.floor(p.y/CELL))] or {}
  local best,best2=nil,.45*.45
  for _,key in ipairs(keys) do
    local row=s.draws[key]
    if row and row.surface_index==surface and row.force_name==force then
      local a,b=row.contact_a,row.contact_b
      local dx,dy=b.x-a.x,b.y-a.y
      local d2=dx*dx+dy*dy
      if d2>0 then
        local t=math.max(0,math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/d2))
        local q={x=a.x+t*dx,y=a.y+t*dy}
        local ds=(p.x-q.x)^2+(p.y-q.y)^2
        local i=math.min(row.contact_pieces,math.floor(t*row.contact_pieces)+1)
        local obj=rendering.get_object_by_id(row.ids[i])
        if ds<=best2 and obj and obj.valid and obj.visible~=false then
          best2=ds;best={x=q.x,y=q.y,distance=math.sqrt(ds),key=key}
        end
      end
    end
  end
  return best
end
function M.sync(graph)
  local s=M.ensure_storage()
  local keep={}
  local drawn,eligible,blocked=0,0,0
  for key,e in pairs(graph.edges or {}) do
    if valid_edge(graph,e) then
      eligible=eligible+1
      local na,nb=graph.nodes[e.a],graph.nodes[e.b]
      if draw(s,key,na,nb,e) then keep[key]=true;drawn=drawn+1 end
    end
  end
  for key in pairs(s.draws) do if not keep[key] then erase(s,key) end end
  s.stats={eligible=eligible,drawn=drawn,blocked=blocked,missed=eligible-drawn-blocked}
  index_contacts(s)
  s.dirty=false
end
function M.rebuild_all(graph)
  local s=M.ensure_storage()
  for key in pairs(s.draws) do erase(s,key) end
  -- Retire legacy art electrical anchors from 030–045 saves.
  for _,surface in pairs(game.surfaces) do
    for _,e in pairs(surface.find_entities_filtered{name=HELPER}) do if e.valid then e.destroy() end end
  end
  s.helpers={};s.draws={};s.dirty=true
  M.sync(graph)
end
function M.mark_dirty() M.ensure_storage().dirty=true end
function M.on_parent_removed(e)
  if not (e and e.valid and is_parent(e.name)) then return end
  local s=M.ensure_storage()
  for k,row in pairs(s.draws) do
    local a,b=k:match("^(%d+):(%d+)$")
    if tonumber(a)==e.unit_number or tonumber(b)==e.unit_number then erase(s,k) end
  end
  s.dirty=true
end
function M.on_tick(tick,graph)
  local s=M.ensure_storage()
  if s.dirty or tick%600==0 then M.sync(graph) end
end
function M.status(player)
  local v=M.ensure_storage().stats
  player.print(string.format("[EM056 visual] eligible=%d drawn=%d blocked=%d render_missed=%d (HSR centreline; decorative only)",
    v.eligible or 0,v.drawn or 0,v.blocked or 0,v.missed or 0))
end
function M.inspect_pair(graph,a,b)
  local key=tostring(math.min(a,b))..":"..tostring(math.max(a,b))
  local e=graph.edges[key]
  if not e or e.kind~="contact" then return "no-contact-edge" end
  if not e.axis then return "no-axis-route" end
  local s=M.ensure_storage()
  local row=s.draws[key]
  if not row then return "no-render-record" end
  for _,id in pairs(row.ids or {}) do
    local obj=rendering.get_object_by_id(id)
    if not (obj and obj.valid) then return "missing-render-object" end
  end
  return "drawn"
end
return M
