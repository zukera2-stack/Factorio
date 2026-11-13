-- Deterministic pure-Lua 35 kV span selection (no Factorio runtime).
local M = {}
function M.compatible(a, b, span)
    if not (a and b and a.rail_adjacent and b.rail_adjacent
        and a.tx and a.ty and b.tx and b.ty) or a.id == b.id then return false end
    local dx, dy = b.x-a.x, b.y-a.y
    local d2 = dx*dx+dy*dy
    if d2 < 0.01 or d2 > span*span then return false end
    local length = math.sqrt(d2)
    if math.abs(dx*a.tx+dy*a.ty) < 0.90*length
        or math.abs(dx*b.tx+dy*b.ty) < 0.90*length then return false end
    if math.abs(a.tx*b.tx+a.ty*b.ty) < 0.84 then return false end
    if math.abs(a.tx*dy-a.ty*dx) > 2
        or math.abs(b.tx*dy-b.ty*dx) > 2 then return false end
    if a.side and b.side and a.side ~= 0 and b.side ~= 0
        and a.side ~= b.side then return false end
    return true
end
function M.choose(a, candidates, span, corridor_ok)
    local forward, backward, df, db = nil, nil, math.huge, math.huge
    for _, b in pairs(candidates) do
        if M.compatible(a,b,span) and (not corridor_ok or corridor_ok(a,b)) then
            local dx,dy = b.x-a.x,b.y-a.y
            local projection = dx*a.tx+dy*a.ty
            local d2 = dx*dx+dy*dy
            if projection > 0 and (d2 < df-0.0001 or
                (math.abs(d2-df) <= 0.0001 and b.id < forward.id)) then
                forward,df=b,d2
            elseif projection < 0 and (d2 < db-0.0001 or
                (math.abs(d2-db) <= 0.0001 and b.id < backward.id)) then
                backward,db=b,d2
            end
        end
    end
    return forward,backward
end
return M
