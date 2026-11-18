-- Cosmetic graph only; no electrical or rail traversal API.
local M={REACH=require("scripts.catenary_limits_029").STRAIGHT,MAX_DEGREE=2}
local function mast(n)
  return n.rail_adjacent and n.rail_id and (n.name=="em-35kv-catenary-pole" or n.name=="em-35kv-catenary-pole-north")
end
local function key(a,b) if a>b then a,b=b,a end;return tostring(a)..":"..tostring(b) end
local function d2(a,b) return (a.x-b.x)^2+(a.y-b.y)^2 end
local function cell(n,x,y) return tostring(n.surface_index).."/"..n.force_name.."/"..x.."/"..y end
local function score(a,b) return d2(a.face_target or a,b.face_target or b),d2(a,b) end
local function less(a,b,c,d) return a<c-1e-8 or (math.abs(a-c)<=1e-8 and b<d-1e-8) end
function M.plan(nodes)
  local valid,buckets={},{}
  for id,n in pairs(nodes) do
    if mast(n) then
      valid[id]=n
      local k=cell(n,math.floor(n.x/M.REACH),math.floor(n.y/M.REACH))
      buckets[k]=buckets[k] or {};buckets[k][#buckets[k]+1]=id
    end
  end
  local candidates,near={},{}
  for id,a in pairs(valid) do
    local x,y=math.floor(a.x/M.REACH),math.floor(a.y/M.REACH)
    near[id]={}
    for dx=-1,1 do for dy=-1,1 do
      for _,other in ipairs(buckets[cell(a,x+dx,y+dy)] or {}) do
        local b=valid[other];local d=d2(a,b)
        if id~=other and d>0 and d<=M.REACH^2 then
          near[id][other]=true
          if id<other then candidates[#candidates+1]={a=id,b=other,p=score(a,b),d=d} end
        end
      end
    end end
  end
  table.sort(candidates,function(a,b)
    if a.p~=b.p then return a.p<b.p end
    if a.d~=b.d then return a.d<b.d end
    if a.a~=b.a then return a.a<b.a end
    return a.b<b.b
  end)
  local edges,degree,adj={},{},{}
  for _,e in ipairs(candidates) do
    if (degree[e.a] or 0)<M.MAX_DEGREE and (degree[e.b] or 0)<M.MAX_DEGREE then
      local skip=false
      -- Suppress redundant shortcuts over nearer intermediate masts.
      for id in pairs(near[e.a]) do
        if near[e.b][id] then
          local ap,ad=score(valid[e.a],valid[id])
          local bp,bd=score(valid[e.b],valid[id])
          if less(ap,ad,e.p,e.d) and less(bp,bd,e.p,e.d) then skip=true;break end
        end
      end
      for id in pairs(adj[e.a] or {}) do if adj[e.b] and adj[e.b][id] then skip=true;break end end
      if not skip then
        edges[key(e.a,e.b)]={a=e.a,b=e.b,kind="contact",corner=false}
        degree[e.a]=(degree[e.a] or 0)+1;degree[e.b]=(degree[e.b] or 0)+1
        adj[e.a]=adj[e.a] or {};adj[e.b]=adj[e.b] or {};adj[e.a][e.b]=true;adj[e.b][e.a]=true
      end
    end
  end
  return edges
end
return M
