-- 056: cosmetic-only centreline planner; never touches technical connectors.
local M={REACH=32,ATTACH=3}
local EPS=0.0001
local names={"em-high-speed-straight-rail","em-half-diagonal-high-speed-rail","em-curved-high-speed-rail","em-curved-high-speed-rail-b"}
local allowed={}
for _,n in ipairs(names) do allowed[n]=true end
local function mast(n) return n.name=="em-35kv-catenary-pole" or n.name=="em-35kv-catenary-pole-north" end
local function d2(a,b) return (a.x-b.x)^2+(a.y-b.y)^2 end
local function heading(d) local a=(d%16)*math.pi/8;return math.sin(a),-math.cos(a) end
local function edgekey(a,b) if a>b then a,b=b,a end;return tostring(a)..":"..tostring(b) end
-- Native RailLocation endpoints/tangents; approximate arc with 24 chords.
-- Same Hermite/Bezier construction as mast_facing_022, but arc station retained.
function M.polyline(a,b)
 local p,q=a.position,b.position
 local dx,dy=q.x-p.x,q.y-p.y
 local l=math.sqrt(dx*dx+dy*dy);if l<EPS then return nil end
 local tx,ty=heading(a.direction or 0);local ux,uy=heading(b.direction or 0)
 if tx*dx+ty*dy<0 then tx,ty=-tx,-ty end
 if ux*dx+uy*dy<0 then ux,uy=-ux,-uy end
 local straight=a.direction==nil or b.direction==nil or (a.direction-b.direction)%8==0
 local points={{x=p.x,y=p.y,s=0}}
 local k=l*.35
 local c={x=p.x+tx*k,y=p.y+ty*k};local d={x=q.x-ux*k,y=q.y-uy*k}
 local count=straight and 1 or 24
 for i=1,count do
  local t=i/count;local u=1-t
  local v=straight and {x=p.x+dx*t,y=p.y+dy*t} or {
   x=u^3*p.x+3*u*u*t*c.x+3*u*t*t*d.x+t^3*q.x,
   y=u^3*p.y+3*u*u*t*c.y+3*u*t*t*d.y+t^3*q.y}
  local prev=points[#points];v.s=prev.s+math.sqrt(d2(prev,v));points[#points+1]=v
 end
 return points,points[#points].s
end
function M.project(pos,points)
 local best
 for i=2,#points do
  local a,b=points[i-1],points[i];local dx,dy=b.x-a.x,b.y-a.y
  local len2=dx*dx+dy*dy
  if len2>EPS then
   local t=math.max(0,math.min(1,((pos.x-a.x)*dx+(pos.y-a.y)*dy)/len2))
   local point={x=a.x+t*dx,y=a.y+t*dy,s=a.s+t*(b.s-a.s)}
   point.d2=d2(pos,point)
   if not best or point.d2<best.d2-EPS then best=point end
  end
 end
 return best
end
-- Pure planner. Adapter: rails(id) -> {length, links(sign), stations}.
-- Walk from each mast in BOTH directions, only through actual connected ends.
-- Stop at first mast on each route; no skipping a nearer mast to join a remote one.
-- At a true rail fork, nearest mast on each branch may join; never more than three.
function M.select(placements,rail)
 local byrail={}
 for id,p in pairs(placements) do
  byrail[p.rail]=byrail[p.rail] or {};local t=byrail[p.rail];t[#t+1]={id=id,s=p.s}
 end
 for _,t in pairs(byrail) do table.sort(t,function(a,b) if a.s~=b.s then return a.s<b.s end;return a.id<b.id end) end
 local function walk(id,p,sign)
  local queue={{rid=p.rail,sign=sign,at=p.s,cost=0,fork=false}}
  local seen,found={},{}
  local best,visits=nil,0
  while #queue>0 and visits<192 do
   table.sort(queue,function(a,b) if a.cost~=b.cost then return a.cost<b.cost end;if a.rid~=b.rid then return a.rid<b.rid end;return a.sign<b.sign end)
   local cur=table.remove(queue,1);visits=visits+1
   if cur.cost>M.REACH then break end
   local r=rail(cur.rid)
   if r then
    local key=cur.rid..":"..cur.sign
    if not seen[key] or cur.cost<seen[key]-EPS then
     seen[key]=cur.cost
     local nearest
     for _,m in ipairs(byrail[cur.rid] or {}) do
      local delta=(m.s-cur.at)*cur.sign
      if m.id~=id and delta>=-EPS and (cur.rid~=p.rail or cur.cost>EPS or delta>EPS) then
       local cost=cur.cost+math.max(0,delta)
       if not nearest or cost<nearest.cost-EPS or (math.abs(cost-nearest.cost)<=EPS and m.id<nearest.id) then nearest={id=m.id,cost=cost} end
      end
     end
     if nearest then
      if nearest.cost<=M.REACH and nearest.cost>EPS then
       if not best or nearest.cost<best.cost-EPS or (math.abs(nearest.cost-best.cost)<=EPS and nearest.id<best.id) then best=nearest end
       -- A real rail fork permits one second nearest-first route, not a
       -- geometric shortcut toward an unrelated adjacent track.
       if cur.fork and (not found[nearest.id] or nearest.cost<found[nearest.id].cost) then found[nearest.id]=nearest end
      end
     else
      local cost=cur.cost+(cur.sign==1 and r.length-cur.at or cur.at)
      if cost<=M.REACH then
       local links=r.links(cur.sign)
       local fork=cur.fork or #links>1
       for _,link in ipairs(links) do
        local next=rail(link.id)
        if next then queue[#queue+1]={rid=link.id,sign=link.sign,at=link.sign==1 and 0 or next.length,cost=cost,fork=fork} end
       end
      end
     end
    end
   end
  end
  local result={}
  if best then result[best.id]={cost=best.cost,fork=found[best.id]~=nil} end
  local extras={}
  for other,q in pairs(found) do if not best or other~=best.id then extras[#extras+1]=q end end
  table.sort(extras,function(a,b) if a.cost~=b.cost then return a.cost<b.cost end;return a.id<b.id end)
  if extras[1] then result[extras[1].id]={cost=extras[1].cost,fork=true} end
  return result
 end
 local choices={}
 for id,p in pairs(placements) do
  choices[id]={}
  for _,sign in ipairs({-1,1}) do
   for other,q in pairs(walk(id,p,sign)) do choices[id][other]=q end
  end
 end
 local candidates={}
 for a,targets in pairs(choices) do
  for b,q in pairs(targets) do
   if a<b and choices[b] and choices[b][a] then
    local pa,pb=placements[a],placements[b]
    local chord=math.sqrt(d2(pa,pb))
    if chord>EPS and q.cost<=chord*1.35+1.5 then
     candidates[#candidates+1]={a=a,b=b,cost=q.cost,fork=q.fork or choices[b][a].fork}
    end
   end
  end
 end
 table.sort(candidates,function(a,b)
  -- Existing through-wire takes precedence over optional fork spans.
  -- Otherwise both shorter branch legs can consume the two ordinary
  -- ports before the straight approach has been considered.
  if a.fork~=b.fork then return not a.fork end
  if a.cost~=b.cost then return a.cost<b.cost end
  if a.a~=b.a then return a.a<b.a end
  return a.b<b.b
 end)
 local edges,degree={},{}
 for _,c in ipairs(candidates) do
  local da,db=degree[c.a] or 0,degree[c.b] or 0
  -- Keep ordinary masts at two spans. A third is allowed only after
  -- native get_connected_rail exposed a fork along this very route.
  if da<3 and db<3 and ((da<2 and db<2) or c.fork) then
   edges[edgekey(c.a,c.b)]={a=c.a,b=c.b,kind="contact",corner=false,axis=true,axis_length=c.cost}
   degree[c.a]=da+1;degree[c.b]=db+1
  end
 end
 return edges
end
function M.plan(nodes)
 local cache,placements={},{}
 local front,back=defines.rail_direction.front,defines.rail_direction.back
 local turns={defines.rail_connection_direction.straight,defines.rail_connection_direction.left,defines.rail_connection_direction.right}
 local function read(r)
  if not (r and r.valid and r.unit_number and allowed[r.name]) then return nil end
  local id=r.unit_number
  if cache[id]~=nil then return cache[id] or nil end
  local ok,a,b=pcall(function() return r.get_rail_end(back).location,r.get_rail_end(front).location end)
  if not ok or not a or not b or not a.position or not b.position or
    (a.rail_layer~=nil and a.rail_layer~=defines.rail_layer.ground) or
    (b.rail_layer~=nil and b.rail_layer~=defines.rail_layer.ground) then cache[id]=false;return nil end
  local points,length=M.polyline(a,b)
  if not points then cache[id]=false;return nil end
  local row={points=points,length=length,link_cache={}}
  cache[id]=row
  function row.links(sign)
   if row.link_cache[sign] then return row.link_cache[sign] end
   local list={}
   for _,turn in ipairs(turns) do
    local other,entry=r.get_connected_rail{rail_direction=sign==1 and front or back,rail_connection_direction=turn}
    if other and other.valid and allowed[other.name] and other.force.name==r.force.name
       and other.surface.index==r.surface.index and (entry==front or entry==back) and read(other) then
     list[#list+1]={id=other.unit_number,sign=entry==back and 1 or -1}
    end
   end
   row.link_cache[sign]=list;return list
  end
  return row
 end
 for id,n in pairs(nodes) do
  if mast(n) then
   local surface=game.surfaces[n.surface_index];local force=game.forces[n.force_name]
   local best
   if surface and force then
    for _,r in pairs(surface.find_entities_filtered{position={x=n.x,y=n.y},radius=5,name=names,force=force}) do
     local row=read(r)
     if row then
      local p=M.project(n,row.points)
      if p and p.d2<=M.ATTACH^2 and (not best or p.d2<best.d2-EPS or (math.abs(p.d2-best.d2)<=EPS and r.unit_number<best.rail)) then
       p.rail=r.unit_number;best=p
      end
     end
    end
   end
   if best then placements[id]=best end
  end
 end
 return M.select(placements,function(id) return cache[id] or nil end),placements
end
return M
