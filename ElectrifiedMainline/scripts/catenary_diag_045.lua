-- Read-only pair diagnostics; stable topology is unchanged.
local power=require("scripts.power_019")
local topo=require("scripts.power_topology")
local view=require("scripts.overhead_geometry_012")
local limits=require("scripts.catenary_limits_029")
local geo=require("scripts.catenary_visual_geometry_045")
local art=require("scripts.catenary_art_030")
local M={}
local function pole(n) return n and (n.name=="em-35kv-catenary-pole" or n.name=="em-35kv-catenary-pole-north") end
local function pstr(p) return p and string.format("(%.4f,%.4f)",p.x,p.y) or "nil" end
local function node(n)
  local v=geo.points(n,n.name,n.face)
  return string.format("id=%s type=%s pos=%s face=%s rail=%s tangent=(%s,%s) side=%s reference=%s contact=%s messenger=%s",
    tostring(n.id),n.name,pstr(n),tostring(n.face),tostring(n.rail_id),
    tostring(n.tx),tostring(n.ty),tostring(n.side),tostring(n.face_source),
    pstr(v and v.contact),pstr(v and v.messenger))
end
local function degree(graph,id)
  local n=0
  for _,e in pairs(graph.edges) do if e.kind=="contact" and (e.a==id or e.b==id) then n=n+1 end end
  return n
end
function M.report(player,param)
  local g=power.graph()
  local sel=player.selected
  local a=sel and sel.valid and g.nodes[sel.unit_number]
  if not pole(a) then player.print("[EM045] Select a real catenary mast first.");return end
  local target=tonumber(param)
  if param and param~="" and not target then player.print("[EM045] Optional neighbour unit ID must be numeric.");return end
  log("[EM045 pair] selected "..node(a))
  local count=0
  for id,b in pairs(g.nodes) do
    if id~=a.id and pole(b) and b.surface_index==a.surface_index and b.force_name==a.force_name then
      local dx,dy=b.x-a.x,b.y-a.y
      local d=math.sqrt(dx*dx+dy*dy)
      if (target and id==target) or (not target and d<=limits.STRAIGHT+4) then
        local info=power.rail_path_info(a,b)
        local ok=info and limits.allowed(a,b,info) or false
        local comp=topo.compatible(a,b,info and info.curved and limits.CURVE or limits.STRAIGHT)
        local corner=view.corner_candidate(a,b,limits.CURVE)
        local side=a.side and b.side and a.side~=0 and b.side~=0 and a.side~=b.side
        log("[EM045 pair] "..node(b))
        log(string.format("[EM045 pair] a=%d b=%d distance=%.3f rail_path=%s curved=%s limits=%s compatible=%s corner=%s side_conflict=%s degrees=%d,%d result=%s",
          a.id,b.id,d,info and tostring(info.length) or "none",tostring(info and info.curved),tostring(ok),
          tostring(comp),tostring(corner),tostring(side),degree(g,a.id),degree(g,b.id),art.inspect_pair(g,a.id,b.id)))
        count=count+1
      end
    end
  end
  player.print("[EM045] "..count.." pair reports written to factorio-current.log (filter EM045 pair).")
end
return M
