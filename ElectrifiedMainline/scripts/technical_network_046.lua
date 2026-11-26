-- Native copper electrical topology, separate from rail/visual graph.
-- Zero ordinary reach: only this module may create our bounded script wires.
local power=require("scripts.power_019")
local M={REACH=require("scripts.catenary_limits_029").WIRE_REACH,MAX_DEGREE=5}
local NAME="em-25kv-technical-anchor-046"
local POLE,NORTH="em-35kv-catenary-pole","em-35kv-catenary-pole-north"
local function mast(name) return name==POLE or name==NORTH end
local function get(id)
  if id then local e=game.get_entity_by_unit_number(id);if e and e.valid then return e end end
end
local function helper(id)
  local e=get(id);if e and e.name==NAME then return e end
end
local function conn(e,create)
  if not e then return nil end
  local ok,c=pcall(function() return e.get_wire_connector(defines.wire_connector_id.pole_copper,create) end)
  return ok and c or nil
end
local function origin() return defines.wire_origin.script end
local function key(a,b) if a>b then a,b=b,a end;return tostring(a)..":"..tostring(b) end
local function group(n) return tostring(n.surface_index).."/"..n.force_name end
local function d2(a,b) return (a.x-b.x)^2+(a.y-b.y)^2 end
-- Spatial buckets and actual continuous HSR path; no visual edges.
-- Vanilla-inspired 5-link cap. Not a claim to reproduce engine auto-connect.
local function candidates_for(nodes)
  local buckets,valid={},{}
  local function cell(n,x,y) return group(n).."/"..x.."/"..y end
  for id,n in pairs(nodes) do
    if mast(n.name) and n.rail_adjacent and n.rail_id then
      valid[id]=n
      local k=cell(n,math.floor(n.x/M.REACH),math.floor(n.y/M.REACH))
      buckets[k]=buckets[k] or {};buckets[k][#buckets[k]+1]=id
    end
  end
  local candidates={}
  for id,a in pairs(valid) do
    local x,y=math.floor(a.x/M.REACH),math.floor(a.y/M.REACH)
    for dx=-1,1 do for dy=-1,1 do
      for _,other in ipairs(buckets[cell(a,x+dx,y+dy)] or {}) do
        if id<other then
          local d=d2(a,valid[other])
          if d<=M.REACH^2 and d>0 then candidates[#candidates+1]={a=id,b=other,d=d} end
        end
      end
    end end
  end
  table.sort(candidates,function(a,b)
    if a.d~=b.d then return a.d<b.d end
    if a.a~=b.a then return a.a<b.a end
    return a.b<b.b
  end)
  return candidates,valid
end
local function select_edges(candidates,valid,path_check,capture)
  local edges,adj,degree={},{},{}
  for _,e in ipairs(candidates) do
    if (degree[e.a] or 0)<M.MAX_DEGREE and (degree[e.b] or 0)<M.MAX_DEGREE then
      -- Avoid redundant triangles like ordinary short-neighbour wiring.
      local redundant=false
      for n in pairs(adj[e.a] or {}) do if adj[e.b] and adj[e.b][n] then redundant=true;break end end
      local path=not redundant and path_check(valid[e.a],valid[e.b])
      if path then
        if capture then capture(path,e) end
        edges[key(e.a,e.b)]=e
        adj[e.a]=adj[e.a] or {};adj[e.b]=adj[e.b] or {}
        adj[e.a][e.b]=true;adj[e.b][e.a]=true
        degree[e.a]=(degree[e.a] or 0)+1;degree[e.b]=(degree[e.b] or 0)+1
      end
    end
  end
  return edges
end
function M.plan(nodes,path_check,capture)
  local candidates,valid=candidates_for(nodes)
  if not path_check then
    local context={starts={},neighbours={},capture_paths=capture~=nil}
    path_check=function(a,b) return power.technical_path(a,b,context) end
  end
  return select_edges(candidates,valid,path_check,capture)
end
-- Potential components use EVERY geometric candidate, not selected wires.
-- Hence degree/triangle decisions cannot interact across component borders.
local function partitions(valid,candidates)
  local parent={}
  for id in pairs(valid) do parent[id]=id end
  local function root(id)
    local r=id
    while parent[r]~=r do r=parent[r] end
    while parent[id]~=id do local q=parent[id];parent[id]=r;id=q end
    return r
  end
  for _,e in ipairs(candidates) do
    local a,b=root(e.a),root(e.b)
    if a~=b then parent[math.max(a,b)]=math.min(a,b) end
  end
  local groups,by_node={},{}
  for id,n in pairs(valid) do
    local r=root(id);local g=groups[r]
    if not g then g={nodes={},count=0,edges={},deps={}};groups[r]=g end
    g.nodes[id]=n;g.count=g.count+1;by_node[id]=g
  end
  return groups,by_node
end
local function same_nodes(a,b)
  if not b or a.count~=b.count then return false end
  for id,n in pairs(a.nodes) do
    local o=b.nodes[id]
    if not o or o.x~=n.x or o.y~=n.y or o.name~=n.name or
      o.rail_id~=n.rail_id or o.surface_index~=n.surface_index or o.force_name~=n.force_name then return false end
  end
  return true
end
-- A bounded walk is <=64 tiles from its start attachment. Add 3 tiles
-- mast offset and 6 tiles for coalesced 4x4 edit buckets, conservatively.
local INVALIDATE_RADIUS=M.REACH*1.5+4+3+6
local function affected(g,old,changes,watches)
  if not same_nodes(g,old) then return true end
  for _,n in pairs(g.nodes) do
    for _,c in ipairs(changes) do
      if n.surface_index==c.surface_index and n.force_name==c.force_name and
        d2(n,c.position)<=INVALIDATE_RADIUS^2 then return true end
    end
  end
  -- Never reuse a group with a destroyed or moved dependency even if the
  -- notification is still queued. Full periodic replan remains independent.
  for id,r in pairs(old.deps) do
    local w=watches[id]
    if not (r.valid and w and r.surface.index==w.surface_index and r.force.name==w.force_name) then return true end
    local pos=r.position
    if pos.x~=w.position.x or pos.y~=w.position.y then return true end
  end
  return false
end
function M.ensure_storage()
  storage.em=storage.em or {}
  local s=storage.em.technical_046
  if not s then s={helpers={},edges={},stats={},dirty=true};storage.em.technical_046=s end
  s.components=s.components or {}
  s.bridge_ports=s.bridge_ports or {}
  s.rail_watch=s.rail_watch or {}
  s.rail_registration=s.rail_registration or {}
  return s
end
local function destroy(id)
  local e=helper(id);if e then e.destroy() end
end
local function anchor(s,id,p)
  local e=helper(s.helpers[id])
  if e and (e.position.x~=p.position.x or e.position.y~=p.position.y
      or e.surface.index~=p.surface.index or e.force.name~=p.force.name) then
    e.destroy();e=nil
  end
  if not e then
    e=p.surface.create_entity{name=NAME,position=p.position,force=p.force,
      auto_connect=false,snap_to_grid=false,raise_built=false,create_build_effect_smoke=false}
    if not (e and e.valid and e.unit_number) then s.helpers[id]=nil;return nil end
    e.destructible=false
  end
  s.helpers[id]=e.unit_number
  return e
end
-- Read actual connections; detach only links touching our hidden helpers.
-- Snapshot before disconnecting so array mutation cannot skip an entry.
local function audit(s)
  local reverse={}
  for id,h in pairs(s.helpers) do reverse[h]=id end
  local removed,failed=0,0
  local seen,anchors,connectors={},{},{}
  for id,h in pairs(s.helpers) do
    local a=helper(h)
    anchors[id]=a
    connectors[id]=conn(a,false)
  end
  for id,h in pairs(s.helpers) do
    local anchor_entity=anchors[id]
    local c=connectors[id]
    if c then
      local reject={}
      for _,link in pairs(c.real_connections) do
        local target=link.target
        local owner=target and target.valid and target.owner
        local other=owner and owner.valid and reverse[owner.unit_number]
        local permitted_port=owner and owner.valid and owner.name=="em-25kv-bridge-port-058"
          and s.bridge_ports[owner.unit_number]==h
          and owner.force.name==anchor_entity.force.name
          and link.origin==origin()
        local permitted_mast=owner and owner.valid and owner.unit_number==id and mast(owner.name)
          and owner.surface.index==anchor_entity.surface.index and owner.force.name==anchor_entity.force.name
          and link.origin==origin()
        -- Use the actual native copper connector snapshot; never treat a
        -- planned edge or a shared electrical ID as proof of a real wire.
        local edge_key=other and key(id,other)
        local planned=edge_key and s.edges[edge_key]
        if planned and other~=id and link.origin==origin()
          and target.valid and owner.surface.index==anchor_entity.surface.index
          and owner.force.name==anchor_entity.force.name
          and target==connectors[other] then
          local row=seen[edge_key] or {};row[id]=true;seen[edge_key]=row
        end
        if target and target.valid and not (permitted_mast or permitted_port or (other and s.edges[key(id,other)] and link.origin==origin())) then
          reject[#reject+1]={target=target,origin=link.origin or defines.wire_origin.player}
        end
      end
      for _,link in ipairs(reject) do
        if link.target.valid then
          local ok,res=pcall(function() return c.disconnect_from(link.target,link.origin) end)
          if ok and res then removed=removed+1 else failed=failed+1 end
        end
      end
    end
  end
  local verified={}
  for k,row in pairs(seen) do
    local e=s.edges[k]
    if e and row[e.a] and row[e.b] then verified[k]=e end
  end
  return removed,failed,verified,anchors,connectors
end
-- Stable component label = minimum unit number in the component.
-- Only add edges supplied by the caller; runtime supplies verified script links,
-- preview supplies planned edges for hypothetical construction.
function M.components(edges)
  local parent={}
  local function root(id)
    if not parent[id] then parent[id]=id end
    local r=id
    while parent[r]~=r do r=parent[r] end
    while parent[id]~=id do local p=parent[id];parent[id]=r;id=p end
    return r
  end
  for _,e in pairs(edges) do
    local a,b=root(e.a),root(e.b)
    if a~=b then parent[math.max(a,b)]=math.min(a,b) end
  end
  local result={}
  for id in pairs(parent) do result[id]=root(id) end
  return result
end
function M.same_component(a,b,components)
  local c=components or M.ensure_storage().components
  return a~=b and c[a]~=nil and c[a]==c[b]
end
function M.span_state(a,b,components)
  if not (a and b and power.technical_path(a,b)) then return "no-HSR-path" end
  if not M.same_component(a.id,b.id,components) then return "technical-split" end
  return "connected"
end
function M.preview_components(nodes)
  -- Pure forecast. No electric entity, connector, storage or Undo mutation.
  return M.components(M.plan(nodes))
end
function M.refresh_components(verified)
  local s=M.ensure_storage()
  if not verified then
  verified={}
  for k,e in pairs(s.edges) do
    local a,b=helper(s.helpers[e.a]),helper(s.helpers[e.b])
    local ca,cb=conn(a,false),conn(b,false)
    if a and b and ca and cb and a.surface.index==b.surface.index
       and a.force.name==b.force.name then
      local ok,res=pcall(function() return ca.is_connected_to(cb,origin()) end)
      if ok and res then verified[k]=e end
    end
  end
  end
  local next_components=M.components(verified)
  local old=s.components
  local changed=false
  for id,v in pairs(next_components) do if old[id]~=v then changed=true;break end end
  if not changed then
    for id,v in pairs(old) do if next_components[id]~=v then changed=true;break end end
  end
  s.components=next_components
  return changed
end
-- Watch only actual selected path dependencies and mast attachment rails.
-- No permission is cached: full plan/audit cadence remains unchanged.
-- Registrations are globally deduplicated by the engine and survive reload.
local function update_watch(s,ids,reused)
  local watches,registrations={},{}
  for id,r in pairs(ids) do
    if r and r.valid then
      local old=s.rail_watch[id]
      local rec=old and reused[id] and old or nil
      if not rec then
        local registration=old and old.registration or script.register_on_object_destroyed(r)
        local pos=r.position
        local surface_index,force_name=r.surface.index,r.force.name
        if old and old.surface_index==surface_index and old.force_name==force_name and
          old.position.x==pos.x and old.position.y==pos.y then rec=old
        else rec={registration=registration,unit=id,surface_index=surface_index,
          force_name=force_name,position=pos} end
      end
      local registration=rec.registration
      watches[id]=rec;registrations[registration]=rec
    end
  end
  s.rail_watch=watches;s.rail_registration=registrations
end
function M.on_object_destroyed(event)
  local s=M.ensure_storage()
  local rec=s.rail_registration[event.registration_number]
  if not rec then return end
  s.rail_registration[event.registration_number]=nil
  s.rail_watch[rec.unit]=nil
  -- The callback may arrive at the end of the tick; the ordinary queue
  -- refreshes mast attachment and syncs copper BEFORE the next paid phase.
  power.queue_rail_change(rec.surface_index,rec.force_name,rec.position)
  log('[EM087E RAIL DESTROYED] tick='..game.tick..' rail='..rec.unit)
end
function M.sync(graph,changes)
  local s=M.ensure_storage()
  local nodes,parents={},{}
  for id,n in pairs(graph.nodes or {}) do
    local p=mast(n.name) and get(id)
    if p and mast(p.name) and n.rail_adjacent and n.rail_id then
      nodes[id]={id=id,name=p.name,x=p.position.x,y=p.position.y,
        surface_index=p.surface.index,force_name=p.force.name,rail_adjacent=true,rail_id=n.rail_id}
      parents[id]=p
    end
  end
  for id,h in pairs(s.helpers) do
    if not parents[id] then destroy(h);s.helpers[id]=nil end
  end
  local failures=0
  for id,p in pairs(parents) do if not anchor(s,id,p) then failures=failures+1 end end
  local candidates,valid=candidates_for(nodes)
  local groups,by_node=partitions(valid,candidates)
  local old=s.plan_groups or {}
  local reuse,work={},{}
  local dependencies,reused={},{}
  local full=not changes or not s.plan_groups
  local rebuilt,retained=0,0
  local context={starts={},neighbours={},capture_paths=true}
  for id,g in pairs(groups) do
    if not full and not affected(g,old[id],changes,s.rail_watch) then
      g.edges=old[id].edges;g.deps=old[id].deps;reuse[g]=true;retained=retained+1
    else
      rebuilt=rebuilt+1
      for nid,n in pairs(g.nodes) do
        local r=power.attached_rail(n)
        context.starts[nid]=r or false
        if r then g.deps[r.unit_number]=r end
      end
    end
  end
  for _,e in ipairs(candidates) do
    if not reuse[by_node[e.a]] then work[#work+1]=e end
  end
  local fresh=select_edges(work,valid,function(a,b) return power.technical_path(a,b,context) end,function(path,e)
    local deps=by_node[e.a].deps
    for _,r in ipairs(path.rails or {}) do deps[r.unit_number]=r end
    local link=path.path
    while link do deps[link.rail.unit_number]=link.rail;link=link.previous end
  end)
  for k,e in pairs(fresh) do by_node[e.a].edges[k]=e end
  s.edges={}
  for _,g in pairs(groups) do
    for k,e in pairs(g.edges) do s.edges[k]=e end
    for id,r in pairs(g.deps) do
      dependencies[id]=r
      if reuse[g] and reused[id]~=false then reused[id]=true else reused[id]=false end
    end
  end
  s.plan_groups=groups
  update_watch(s,dependencies,reused)
  if not full then log(string.format('[EM087F LOCAL PLAN] tick=%d rebuilt=%d retained=%d candidates=%d/%d',game.tick,rebuilt,retained,#work,#candidates)) end
  local removed,rejected,verified,anchors,connectors=audit(s)
  local connected,missed,desired=0,0,0
  for _,e in pairs(s.edges) do
    desired=desired+1
    local a,b=anchors[e.a],anchors[e.b]
    local ca,cb=connectors[e.a],connectors[e.b]
    if not (ca and ca.valid) then ca=conn(a,true) end
    if not (cb and cb.valid) then cb=conn(b,true) end
    -- Check ownership, surface, force and physical distance AGAIN before
    -- bypassing native reach. Never bypass a different network's connector.
    if rejected==0 and a and a.valid and b and b.valid and ca and cb and a.surface.index==b.surface.index
       and a.force.name==b.force.name and d2(a.position,b.position)<=M.REACH^2 then
      local ok,res=pcall(function()
        return verified[key(e.a,e.b)]~=nil or ca.is_connected_to(cb,origin()) or ca.connect_to(cb,false,origin())
      end)
      if ok and res then connected=connected+1;verified[key(e.a,e.b)]=e
      else
        missed=missed+1
        log("[EM048 tech] script copper refused "..key(e.a,e.b).." "..tostring(res))
      end
    else missed=missed+1 end
  end
  s.stats={desired=desired,connected=connected,missed=missed,failures=failures,
    removed=removed,audit_failed=rejected}
  s.sync_generation=(s.sync_generation or 0)+1
  s.dirty=false;s.dirty_changes=nil
  -- In a clean sync the engine has confirmed every edge, including newly
  -- created ones. An abnormal sync takes the original independent path.
  return M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)
end
function M.mark_dirty(changes)
  local s=M.ensure_storage()
  if not changes then s.dirty_changes=nil
  elseif not s.dirty then s.dirty_changes=changes
  elseif s.dirty_changes then
    for _,c in ipairs(changes) do s.dirty_changes[#s.dirty_changes+1]=c end
  end
  s.dirty=true
end
function M.on_parent_removed(e)
  if not (e and e.valid and mast(e.name)) then return end
  local s=M.ensure_storage()
  destroy(s.helpers[e.unit_number]);s.helpers[e.unit_number]=nil
  M.mark_dirty()
end
function M.rebuild_all(graph)
  local s=M.ensure_storage()
  for _,surface in pairs(game.surfaces) do
    for _,e in pairs(surface.find_entities_filtered{name=NAME}) do if e.valid then e.destroy() end end
  end
  s.helpers={};s.edges={};s.plan_groups=nil;M.sync(graph)
end
function M.on_tick(tick,graph)
  local s=M.ensure_storage()
  if tick%600==0 then return M.sync(graph)
  elseif s.dirty then return M.sync(graph,s.dirty_changes)
  elseif tick%60==0 then
    local n,f,verified=audit(s)
    s.stats.audit_failed=f
    if n>0 or f>0 then log("[EM048 tech] unauthorized removed="..n.." failed="..f);M.mark_dirty() end
    return M.refresh_components((n==0 and f==0) and verified or nil)
  end
  return false
end
function M.inspect_pair(a,b)
  local s=M.ensure_storage()
  local ca,cb=conn(helper(s.helpers[a]),false),conn(helper(s.helpers[b]),false)
  if not s.edges[key(a,b)] then return "not-selected" end
  if not (ca and cb) then return "missing-connector" end
  local ok,res=pcall(function() return ca.is_connected_to(cb,origin()) end)
  return ok and res and "script-connected" or "script-missing"
end
function M.status(player)
  local s=M.ensure_storage();local n=0
  for _ in pairs(s.helpers) do n=n+1 end
  local v=s.stats
  local msg=string.format("[EM048 tech] anchors=%d desired=%d connected=%d missed=%d anchor_fail=%d removed=%d audit_failed=%d reach=40 HSR-continuous origin=script; see /em-25kv-mode status",
    n,v.desired or 0,v.connected or 0,v.missed or 0,v.failures or 0,v.removed or 0,v.audit_failed or 0)
  player.print(msg);log(msg)
  local e=player.selected
  if e and e.valid and mast(e.name) then
    local h=helper(s.helpers[e.unit_number]);local c=conn(h,false)
    local detail="[EM048 tech] mast="..e.unit_number.." anchor="..tostring(h and h.unit_number).." network_id="..tostring(c and c.network_id).." visible_network_id="..tostring(e.electric_network_id).." verified_component="..tostring(s.components[e.unit_number])
    player.print(detail);log(detail)
    if c then for _,link in pairs(c.real_connections) do
      local target=link.target and link.target.valid and link.target.owner
      if target and target.valid then log("[EM048 tech] neighbour="..target.name.." id="..tostring(target.unit_number).." origin="..tostring(link.origin)) end
    end end
  end
end
return M
