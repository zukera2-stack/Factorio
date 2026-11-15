-- 0.1.22: VISUAL ONLY. A curved rail's LuaEntity.position is not
-- generally the closest point on its running line. Use RailEnd geometry
-- for facing the cantilever, without changing placement or electric logic.
-- Pure mathematical functions in project(); requires no Factorio runtime.
local M={}
local abs,sqrt,pi=math.abs,math.sqrt,math.pi
local EPS=1e-8
local SAMPLES=20
local function dist2(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy
end
local function heading(direction)
    local rad=(direction%16)*pi/8
    return math.sin(rad),-math.cos(rad)
end
local function closest_segment(pos,a,b)
    local dx,dy=b.x-a.x,b.y-a.y
    local norm=dx*dx+dy*dy
    if norm<EPS then return a,dist2(pos,a) end
    local t=((pos.x-a.x)*dx+(pos.y-a.y)*dy)/norm
    if t<0 then t=0 elseif t>1 then t=1 end
    local p={x=a.x+t*dx,y=a.y+t*dy}
    return p,dist2(pos,p)
end
local function cubic(a,c1,c2,b,t)
    local u=1-t
    return {
        x=u*u*u*a.x+3*u*u*t*c1.x+3*u*t*t*c2.x+t*t*t*b.x,
        y=u*u*u*a.y+3*u*u*t*c1.y+3*u*t*t*c2.y+t*t*t*b.y
    }
end
function M.project(pos,first,second)
    if not (first and first.position and second and second.position) then
        return nil,nil,"missing_ends"
    end
    local a,b=first.position,second.position
    if dist2(a,b)<EPS then
        return {x=a.x,y=a.y},dist2(pos,a),"degenerate"
    end
    local dx,dy=b.x-a.x,b.y-a.y
    local chord=sqrt(dx*dx+dy*dy)
    local straight=first.direction==nil or second.direction==nil
    if not straight then
        straight=(first.direction-second.direction)%8==0
    end
    if straight then
        local p,score=closest_segment(pos,a,b)
        return p,score,"rail_end_chord"
    end
    local tx,ty=heading(first.direction)
    local ux,uy=heading(second.direction)
    -- Rail-end directions may be reversed: align both with chord travel.
    if tx*dx+ty*dy<0 then tx,ty=-tx,-ty end
    if ux*dx+uy*dy<0 then ux,uy=-ux,-uy end
    local k=chord*0.35
    local c1={x=a.x+tx*k,y=a.y+ty*k}
    local c2={x=b.x-ux*k,y=b.y-uy*k}
    local best,score=nil,math.huge
    local previous=a
    for i=1,SAMPLES do
        local next_point=cubic(a,c1,c2,b,i/SAMPLES)
        local p,d2=closest_segment(pos,previous,next_point)
        if d2<score then best,score=p,d2 end
        previous=next_point
    end
    return best,score,"rail_end_curve"
end
local function valid_ends(a,b,ground_layer)
    if not (a and b and a.position and b.position) then return false end
    if ground_layer==nil then return true end
    if a.rail_layer~=nil and a.rail_layer~=ground_layer then return false end
    if b.rail_layer~=nil and b.rail_layer~=ground_layer then return false end
    return true
end
function M.nearest(pos,rails,front,back,ground_layer)
    local best
    for _,rail in pairs(rails or {}) do
        if rail.valid then
            local ok_a,ra=pcall(function() return rail.get_rail_end(front) end)
            local ok_b,rb=pcall(function() return rail.get_rail_end(back) end)
            local a=ok_a and ra and ra.location or nil
            local b=ok_b and rb and rb.location or nil
            local p,score,method
            if valid_ends(a,b,ground_layer) then
                p,score,method=M.project(pos,a,b)
            end
            if not p then
                p={x=rail.position.x,y=rail.position.y}
                score=dist2(pos,p)
                method="entity_center_fallback"
            end
            local id=rail.unit_number or math.huge
            if not best or score<best.score-1e-7 or
                (abs(score-best.score)<=1e-7 and id<best.id) then
                best={point=p,score=score,method=method,rail_id=rail.unit_number,
                    rail_name=rail.name,rail_direction=rail.direction,id=id}
            end
        end
    end
    return best
end
return M
