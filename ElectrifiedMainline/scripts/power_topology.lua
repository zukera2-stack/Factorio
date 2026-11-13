-- 0.1.12: deterministic curve-aware 35 kV topology; no rail signals.
local M={}
local sqrt,abs=math.sqrt,math.abs
local function dot(ax,ay,bx,by) return ax*bx+ay*by end
local function cross(ax,ay,bx,by) return ax*by-ay*bx end
function M.compatible(a,b,span)
    if not (a and b and a.rail_adjacent and b.rail_adjacent
        and a.tx and a.ty and b.tx and b.ty) or a.id==b.id then return false end
    local dx,dy=b.x-a.x,b.y-a.y
    local d2=dx*dx+dy*dy
    if d2<0.01 or d2>span*span then return false end
    local length=sqrt(d2)
    if abs(dot(dx,dy,a.tx,a.ty))<0.38*length
        or abs(dot(dx,dy,b.tx,b.ty))<0.38*length then return false end
    local similarity=abs(dot(a.tx,a.ty,b.tx,b.ty))
    if similarity<0.17 then return false end
    local lateral=similarity>0.91 and 2.5 or 7
    if abs(cross(a.tx,a.ty,dx,dy))>lateral
        or abs(cross(b.tx,b.ty,dx,dy))>lateral then return false end
    if similarity>0.91 and a.side and b.side and a.side~=0
        and b.side~=0 and a.side~=b.side then return false end
    return true
end
function M.choose(a,candidates,span,corridor_ok)
    local f,b,df,db=nil,nil,math.huge,math.huge
    for _,v in pairs(candidates) do
        if M.compatible(a,v,span) and (not corridor_ok or corridor_ok(a,v)) then
            local dx,dy=v.x-a.x,v.y-a.y
            local proj=dot(dx,dy,a.tx,a.ty)
            local d2=dx*dx+dy*dy
            if proj>0 and (d2<df-0.0001 or
                (abs(d2-df)<=0.0001 and f and v.id<f.id)) then
                f,df=v,d2
            elseif proj<0 and (d2<db-0.0001 or
                (abs(d2-db)<=0.0001 and b and v.id<b.id)) then
                b,db=v,d2
            end
        end
    end
    return f,b
end
function M.rail_normal(tx,ty,side,px,py,rx,ry)
    if side and side~=0 then return ty*side,-tx*side end
    local dx,dy=rx-px,ry-py
    local len=sqrt(dx*dx+dy*dy)
    if len>0.01 then return dx/len,dy/len end
    return 1,0
end
function M.sprite_orientation(nx,ny)
    -- Right-facing base sprite has orientation zero.
    -- Lua 5.2 math.atan(x,y) is not portable: use a one-argument atan.
    local angle
    if abs(nx)<0.00001 then angle=ny>=0 and math.pi/2 or -math.pi/2
    else
        angle=math.atan(ny/nx)
        if nx<0 then angle=angle+math.pi end
    end
    return (angle/(2*math.pi))%1
end
function M.anchor(n)
    local shift=n.rail_offset or 2
    if shift<0.5 then shift=0.5 end
    if shift>2.9 then shift=2.9 end
    return {x=n.x+(n.nx or 0)*shift,y=n.y+(n.ny or 0)*shift}
end
function M.path(a,b,steps)
    steps=steps or 8
    local p,q=M.anchor(a),M.anchor(b)
    local dx,dy=q.x-p.x,q.y-p.y
    local len=sqrt(dx*dx+dy*dy)
    local t0x,t0y=a.tx,a.ty
    local t1x,t1y=b.tx,b.ty
    if dot(t0x,t0y,dx,dy)<0 then t0x,t0y=-t0x,-t0y end
    if dot(t1x,t1y,dx,dy)<0 then t1x,t1y=-t1x,-t1y end
    local tension=math.min(len*0.32,4)
    local out={}
    for i=0,steps do
        local t=i/steps
        local t2,t3=t*t,t*t*t
        local h00=2*t3-3*t2+1
        local h10=t3-2*t2+t
        local h01=-2*t3+3*t2
        local h11=t3-t2
        out[#out+1]={x=h00*p.x+h10*tension*t0x+h01*q.x+h11*tension*t1x,
            y=h00*p.y+h10*tension*t0y+h01*q.y+h11*tension*t1y}
    end
    return out
end
return M
