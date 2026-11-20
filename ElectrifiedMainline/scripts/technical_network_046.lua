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
function M.plan(nodes,path_check)
  path_check=path_check or power.technical_path
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
  local edges,adj,degree={},{},{}
  for _,e in ipairs(candidates) do
    if (degree[e.a] or 0)<M.MAX_DEGREE and (degree[e.b] or 0)<M.MAX_DEGREE then
      -- Avoid redundant triangles like ordinary short-neighbour wiring.
      local redundant=false
      for n in pairs(adj[e.a] or {}) do if adj[e.b] and adj[e.b][n] then redundant=true;break end end
      if not redundant and path_check(valid[e.a],valid[e.b]) then
        edges[key(e.a,e.b)]=e
        adj[e.a]=adj[e.a] or {};adj[e.b]=adj[e.b] or {}
        adj[e.a][e.b]=true;adj[e.b][e.a]=true
        degree[e.a]=(degree[e.a] or 0)+1;degree[e.b]=(degree[e.b] or 0)+1
      end
    end
  end
  return edges
end
function M.ensure_storage()
  storage.em=storage.em or {}
  local s=storage.em.technical_046
  if not s then s={helpers={},edges={},stats={},dirty=true};storage.em.technical_046=s end
  s.components=s.components or {}
  s.bridge_ports=s.bridge_ports or {}
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
  for id,h in pairs(s.helpers) do
    local c=conn(helper(h),false)
    if c then
      local reject={}
      for _,link in pairs(c.real_connections) do
        local target=link.target
        local owner=target and target.valid and target.owner
        local other=owner and owner.valid and reverse[owner.unit_number]
        local permitted_port=owner and owner.valid and owner.name=="em-25kv-bridge-port-058"
          and s.bridge_ports[owner.unit_number]==h
          and owner.force.name==helper(h).force.name
          and link.origin==origin()
        if target and target.valid and not (permitted_port or (other and s.edges[key(id,other)] and link.origin==origin())) then
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
  return removed,failed
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
function M.refresh_components()
  local s=M.ensure_storage()
  local verified={}
  for k,e in pairs(s.edges) do
    local a,b=helper(s.helpers[e.a]),helper(s.helpers[e.b])
    local ca,cb=conn(a,false),conn(b,false)
    if a and b and ca and cb and a.surface.index==b.surface.index
       and a.force.name==b.force.name then
      local ok,res=pcall(function() return ca.is_connected_to(cb,origin()) end)
      if ok and res then verified[k]=e end
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
function M.sync(graph)
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
  s.edges=M.plan(nodes)
  local removed,rejected=audit(s)
  local connected,missed,desired=0,0,0
  for _,e in pairs(s.edges) do
    desired=desired+1
    local a,b=helper(s.helpers[e.a]),helper(s.helpers[e.b])
    local ca,cb=conn(a,true),conn(b,true)
    -- Check ownership, surface, force and physical distance AGAIN before
    -- bypassing native reach. Never bypass a different network's connector.
    if rejected==0 and a and b and ca and cb and a.surface.index==b.surface.index
       and a.force.name==b.force.name and d2(a.position,b.position)<=M.REACH^2 then
      local ok,res=pcall(function()
        return ca.is_connected_to(cb,origin()) or ca.connect_to(cb,false,origin())
      end)
      if ok and res then connected=connected+1
      else
        missed=missed+1
        log("[EM048 tech] script copper refused "..key(e.a,e.b).." "..tostring(res))
      end
    else missed=missed+1 end
  end
  s.stats={desired=desired,connected=connected,missed=missed,failures=failures,
    removed=removed,audit_failed=rejected}
  s.dirty=false
  return M.refresh_components()
end
function M.mark_dirty() M.ensure_storage().dirty=true end
function M.on_parent_removed(e)
  if not (e and e.valid and mast(e.name)) then return end
  local s=M.ensure_storage()
  destroy(s.helpers[e.unit_number]);s.helpers[e.unit_number]=nil
  s.dirty=true
end
function M.rebuild_all(graph)
  local s=M.ensure_storage()
  for _,surface in pairs(game.surfaces) do
    for _,e in pairs(surface.find_entities_filtered{name=NAME}) do if e.valid then e.destroy() end end
  end
  s.helpers={};s.edges={};M.sync(graph)
end
function M.on_tick(tick,graph)
  local s=M.ensure_storage()
  if s.dirty or tick%600==0 then return M.sync(graph)
  elseif tick%60==0 then
    local n,f=audit(s)
    s.stats.audit_failed=f
    if n>0 or f>0 then log("[EM048 tech] unauthorized removed="..n.." failed="..f);s.dirty=true end
    return M.refresh_components()
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
    local detail="[EM048 tech] mast="..e.unit_number.." anchor="..tostring(h and h.unit_number).." network_id="..tostring(c and c.network_id).." verified_component="..tostring(s.components[e.unit_number])
    player.print(detail);log(detail)
    if c then for _,link in pairs(c.real_connections) do
      local target=link.target and link.target.valid and link.target.owner
      if target and target.valid then log("[EM048 tech] neighbour="..target.name.." id="..tostring(target.unit_number).." origin="..tostring(link.origin)) end
    end end
  end
end
return M
