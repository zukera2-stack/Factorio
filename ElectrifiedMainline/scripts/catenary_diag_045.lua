-- 047: separate visual selection and actual technical HSR connection.
local power=require("scripts.power_019")
local limits=require("scripts.catenary_limits_029")
local geo=require("scripts.catenary_visual_geometry_045")
local art=require("scripts.catenary_art_030")
local technical=require("scripts.technical_network_046")
local M={}
local function pole(n) return n and (n.name=="em-35kv-catenary-pole" or n.name=="em-35kv-catenary-pole-north") end
local function pstr(p) return p and string.format("(%.4f,%.4f)",p.x,p.y) or "nil" end
local function node(n)
  local v=geo.points(n,n.name,n.face)
  return string.format("id=%s type=%s pos=%s face=%s technical_rail=%s visual_rail=%s attachment=%s station=%s contact=%s messenger=%s", tostring(n.id),n.name,pstr(n),tostring(n.face),tostring(n.rail_id),tostring(n.axis_rail_id),tostring(n.axis_status),tostring(n.axis_station),pstr(v and v.contact),pstr(v and v.messenger))
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
  if not pole(a) then player.print("[EM056] Select a real catenary mast first.");return end
  local target=tonumber(param)
  if param and param~="" and not target then player.print("[EM056] Optional neighbour unit ID must be numeric.");return end
  log("[EM056 pair] selected "..node(a))
  local count=0
  for id,b in pairs(g.nodes) do
    if id~=a.id and pole(b) and b.surface_index==a.surface_index and b.force_name==a.force_name then
      local dx,dy=b.x-a.x,b.y-a.y
      local d=math.sqrt(dx*dx+dy*dy)
      if (target and id==target) or (not target and d<=limits.WIRE_REACH) then
        local info=power.technical_path(a,b)
        local edge=art.inspect_pair(g,a.id,b.id)
        local da,db=degree(g,a.id),degree(g,b.id)
        local cause=edge
        if edge=="no-contact-edge" then
          if a.axis_status=="ambiguous" or b.axis_status=="ambiguous" then cause="ambiguous-visual-rail"
          elseif a.axis_status~="attached" or b.axis_status~="attached" then cause="mast-without-visual-HSR"
          elseif d>limits.STRAIGHT then cause="visual-distance-over-32"
          elseif da>=2 or db>=2 then cause="axis-neighbour-already-selected"
          else cause="no-mutual-first-mast-along-HSR-axis" end
        end
        local tech=technical.inspect_pair(a.id,b.id)
        local component=technical.same_component(a.id,b.id) and "same" or "separate"
        local why=not (a.rail_adjacent and b.rail_adjacent) and "mast-without-HSR" or d>limits.WIRE_REACH and "technical-distance-over-40" or not info and "no-bounded-connected-HSR-path" or "HSR-path-ok"
        log("[EM056 pair] "..node(b))
        log(string.format("[EM056 pair] a=%d b=%d distance=%.3f rail_path=%s visual=%s degrees=%d,%d technical=%s component=%s technical_gate=%s",
          a.id,b.id,d,info and tostring(info.length) or "none",cause,da,db,tech,component,why))
        count=count+1
      end
    end
  end
  player.print("[EM056] "..count.." pair reports written to factorio-current.log (filter EM056 pair).")
end
return M
