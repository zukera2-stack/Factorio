-- 0.1.29 auto native-wire catenary (32 straight / 16 curved / 40 connector); VISUAL ONLY.
-- Never connects standard electric poles or changes train/Undo mechanics.
-- The eligible graph is produced by power_019, which must verify real
-- connectivity of custom ВСМ rails for EVERY contact span.
local M={}
local geo=require("scripts.native_wire_geometry_028")
local PARENT="em-35kv-catenary-pole" -- stable legacy prototype ID for saves
local NORTH="em-35kv-catenary-pole-north"
local function is_parent(name) return name==PARENT or name==NORTH end
local ANCHOR="em-25kv-contact-anchor"
local ORIGIN=function() return defines.wire_origin.player end
local CID=function() return defines.wire_connector_id.pole_copper end
local function connector(entity,create)
  return entity.get_wire_connector(CID(),create)
end
local function get(id,name)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  if e and e.valid and (e.name==name or (name==PARENT and is_parent(e.name))) then return e end
end
function M.ensure_storage()
  storage.em=storage.em or {}
  storage.em.native_25kv_028=storage.em.native_25kv_028 or {
    helpers={},calibration={},dirty=false,stats={}}
  local s=storage.em.native_25kv_028
  s.helpers=s.helpers or {}
  s.calibration=s.calibration or {}
  s.stats=s.stats or {}
  return s
end
local function destroy_helper(record)
  local e=get(record and record.id,ANCHOR)
  if e then e.destroy() end
end
function M.mark_dirty()
  M.ensure_storage().dirty=true
end
function M.on_parent_removed(e)
  if not (e and e.valid and is_parent(e.name)) then return end
  local s=M.ensure_storage()
  local record=s.helpers[e.unit_number]
  if record then
    destroy_helper(record)
    s.helpers[e.unit_number]=nil
  end
  s.dirty=true
end
local function eligible(sgraph,e)
  if e.kind~="contact" then return false end
  local a,b=sgraph.nodes[e.a],sgraph.nodes[e.b]
  return a and b and is_parent(a.name) and is_parent(b.name)
     and a.rail_adjacent and b.rail_adjacent
     and a.rail_id and b.rail_id
     and a.surface_index==b.surface_index
     and a.force_name==b.force_name
end
local function desired_links(graph)
  local adj={}
  local spans=0
  for _,edge in pairs(graph.edges or {}) do
    if eligible(graph,edge) then
      adj[edge.a]=adj[edge.a] or {}
      adj[edge.b]=adj[edge.b] or {}
      adj[edge.a][edge.b]=true
      adj[edge.b][edge.a]=true
      spans=spans+1
    end
  end
  return adj,spans
end
local function ensure_anchor(s,parent,node)
  local p=get(parent,PARENT)
  if not p then return nil end
  local face=node.face
  local pos=geo.tip_for_pole(p.position,face,s.calibration,p.name)
  if not pos then return nil end
  local record=s.helpers[parent]
  local helper=get(record and record.id,ANCHOR)
  if helper and (record.face~=face or not geo.same_pos(helper.position,pos)
      or helper.surface.index~=p.surface.index
      or helper.force.name~=p.force.name) then
    helper.destroy()
    helper=nil
  end
  if not helper then
    helper=p.surface.create_entity{
      name=ANCHOR,position=pos,force=p.force,snap_to_grid=false,
      raise_built=false,create_build_effect_smoke=false}
    if not (helper and helper.valid and helper.unit_number) then
      s.helpers[parent]=nil
      return nil
    end
    helper.destructible=false
  end
  s.helpers[parent]={id=helper.unit_number,face=face}
  return helper
end
local function allowed_connections(graph)
  local adj=desired_links(graph)
  return adj
end
local function audit(s,adj)
  local by_helper={}
  for parent,record in pairs(s.helpers) do
    by_helper[record.id]=parent
  end
  local stripped=0
  for parent,record in pairs(s.helpers) do
    local e=get(record.id,ANCHOR)
    if e then
      local c=connector(e,false)
      if c then
        for _,link in pairs(c.real_connections) do
          local target=link.target
          local owner=target and target.valid and target.owner
          local other=owner and owner.valid and by_helper[owner.unit_number]
          -- We control only this helper pole, never the other entity.
          if not (other and adj[parent] and adj[parent][other]
              and link.origin==ORIGIN()) then
            if target and target.valid
                and c.disconnect_from(target,link.origin or ORIGIN()) then
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
  local adj,spans=desired_links(graph)
  for parent,record in pairs(s.helpers) do
    if not adj[parent] or not get(parent,PARENT) then
      destroy_helper(record)
      s.helpers[parent]=nil
    end
  end
  local failures=0
  for parent in pairs(adj) do
    if not ensure_anchor(s,parent,graph.nodes[parent]) then
      failures=failures+1
    end
  end
  local stripped=audit(s,adj)
  local connected,missed=0,0
  for _,edge in pairs(graph.edges or {}) do
    if eligible(graph,edge) then
      local a=s.helpers[edge.a]
      local b=s.helpers[edge.b]
      local ea=get(a and a.id,ANCHOR)
      local eb=get(b and b.id,ANCHOR)
      local ca=ea and connector(ea,true)
      local cb=eb and connector(eb,true)
      if ca and cb and ca.can_wire_reach(cb) then
        if ca.is_connected_to(cb,ORIGIN())
           or ca.connect_to(cb,true,ORIGIN()) then
          connected=connected+1
        else
          missed=missed+1
        end
      else
        missed=missed+1
      end
    end
  end
  s.stats={eligible=spans,connected=connected,missed=missed,
     anchor_failures=failures,removed_unauthorized=stripped}
  s.dirty=false
end
function M.rebuild_all(graph)
  local s=M.ensure_storage()
  for _,surface in pairs(game.surfaces) do
    for _,a in pairs(surface.find_entities_filtered{name=ANCHOR}) do
      if a.valid then a.destroy() end
    end
  end
  s.helpers={}
  M.sync(graph)
end
function M.on_tick(tick,graph)
  local s=M.ensure_storage()
  if s.dirty then M.sync(graph) end
  -- Never leave third-party or player-added links to the factory grid
  -- permanently attached. Audits are read-only except invalid connectors.
  if tick%60==0 and next(s.helpers) then
    local adj=allowed_connections(graph)
    local n=audit(s,adj)
    if n>0 then
      log("[EM 25kV] detached "..n.." unauthorized copper connection(s)")
    end
  end
  -- Restore a legitimate link accidentally cut by the player.
  if tick%600==0 and next(s.helpers) then M.sync(graph) end
end
function M.status(player,graph)
  local s=M.ensure_storage()
  local n=0
  for _ in pairs(s.helpers) do n=n+1 end
  local stats=s.stats
  player.print(string.format(
    "[EM 25kV] helpers=%d spans=%d wires=%d missed=%d anchor_failures=%d; max_straight=32 max_curve=16 reach=40 power_MW=0",
    n,stats.eligible or 0,stats.connected or 0,
    stats.missed or 0,stats.anchor_failures or 0))
end
function M.tune(player,event,graph)
  local s=M.ensure_storage()
  local args={}
  for a in string.gmatch(event.parameter or "","%S+") do args[#args+1]=a end
  local face=args[1]
  if face=="reset" and #args==1 then
    s.calibration={}
    M.sync(graph)
    player.print("[EM 25kV] all 8 C-arm offsets reset to sprite defaults")
    return
  end
  if not geo.OFFSETS[face] or #args~=3 then
    player.print("[EM 25kV] /em-25kv-tune FACE DX DY (each -2..2); /em-25kv-tune reset")
    return
  end
  local dx,dy=tonumber(args[2]),tonumber(args[3])
  if not dx or not dy or dx~=dx or dy~=dy or
     math.abs(dx)>2 or math.abs(dy)>2 then
    player.print("[EM 25kV] invalid offsets, required -2..2 tiles")
    return
  end
  s.calibration[face]={x=dx,y=dy}
  M.sync(graph)
  player.print(string.format("[EM 25kV] face=%s adjusted (%.3f,%.3f) tiles",
    face,dx,dy))
end
return M
