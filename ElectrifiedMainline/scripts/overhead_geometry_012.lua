-- Factorio-independent geometry: mast facing, gentle contact-line bends.
-- All directions are in world coordinates, x east, y south.
local M = {}
local sqrt, abs = math.sqrt, math.abs

function M.face(p, rail)
    if not rail then return "east" end
    local dx, dy = rail.x - p.x, rail.y - p.y
    if dx*dx + dy*dy < 0.02 then return "east" end
    local a = math.atan2 and math.atan2(dy, dx) or math.atan(dy / (abs(dx) < 0.00001 and 0.00001 or dx))
    if not math.atan2 and dx < 0 then a = a + (dy >= 0 and math.pi or -math.pi) end
    local idx = math.floor((a / (math.pi/4)) + 0.5) % 8
    return ({"east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast"})[idx+1]
end

local offsets = {
    east={1.5,0}, southeast={1.06,1.06}, south={0,1.5},
    southwest={-1.06,1.06}, west={-1.5,0}, northwest={-1.06,-1.06},
    north={0,-1.5}, northeast={1.06,-1.06},
}
function M.wire_anchor(n, height)
    local off = offsets[n.face] or offsets.east
    return {x=n.x+off[1],y=n.y+off[2]-(height or 0.5)}
end
function M.bezier(a, b, steps)
    steps = steps or 8
    if steps < 2 then steps=2 end
    local dx,dy=b.x-a.x,b.y-a.y
    local dist=sqrt(dx*dx+dy*dy)
    local tx1,ty1=a.tx or (dx/dist),a.ty or (dy/dist)
    local tx2,ty2=b.tx or (dx/dist),b.ty or (dy/dist)
    if tx1*dx + ty1*dy < 0 then tx1,ty1=-tx1,-ty1 end
    if tx2*dx + ty2*dy < 0 then tx2,ty2=-tx2,-ty2 end
    local k=math.min(dist*0.46,7.5)
    local p1={x=a.x+tx1*k,y=a.y+ty1*k}
    local p2={x=b.x-tx2*k,y=b.y-ty2*k}
    local points={}
    for i=0,steps do
        local t=i/steps
        local q=1-t
        local x=q*q*q*a.x+3*q*q*t*p1.x+3*q*t*t*p2.x+t*t*t*b.x
        local y=q*q*q*a.y+3*q*q*t*p1.y+3*q*t*t*p2.y+t*t*t*b.y
        points[#points+1]={x=x,y=y}
    end
    return points
end
function M.corner_candidate(a,b,span)
    if not (a and b and a.tx and b.tx and a.rail_adjacent and b.rail_adjacent) then return false end
    if a.id==b.id or a.surface_index~=b.surface_index or a.force_name~=b.force_name then return false end
    local dx,dy=b.x-a.x,b.y-a.y
    local d2=dx*dx+dy*dy
    if d2<0.01 or d2>(span*1.45)^2 then return false end
    local dot=abs(a.tx*b.tx+a.ty*b.ty)
    -- Only turns, not parallel neighbouring tracks; rule out facing directly across the railway.
    if dot>0.92 then return false end
    if abs(dx*a.tx+dy*a.ty)<1.0 or abs(dx*b.tx+dy*b.ty)<1.0 then return false end
    return true,d2
end
return M
