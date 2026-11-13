-- Factorio-free tests for 0.1.12; do not modify signals or engine rail blocks.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local t=require("scripts.power_topology")
local function n(id,x,y,tx,ty,side,nx,ny)
    return {id=id,x=x,y=y,tx=tx,ty=ty,side=side,nx=nx or 0,
        ny=ny or 1,rail_adjacent=true,rail_offset=2}
end
local line={}
for i=1,5 do line[i]=n(i,(i-1)*10,-2,1,0,-1,0,1) end
for i,a in ipairs(line) do
    local f,b=t.choose(a,line,16)
    assert((f and f.id)==(i<5 and i+1 or nil))
    assert((b and b.id)==(i>1 and i-1 or nil))
end
assert(not t.compatible(line[1],n(6,7,5,1,0,1),16))
assert(not t.compatible(line[1],n(7,7,2.1,1,0,-1),16))
assert(not t.compatible(line[1],n(8,17,-2,1,0,-1),16))
assert(not t.compatible(line[1],n(9,10,-2,0,1,-1),16))
local bend=n(10,8,3,0.70710678,0.70710678,-1,-0.70710678,0.70710678)
assert(t.compatible(line[1],bend,16))
local path=t.path(line[1],bend)
assert(#path==9)
local p,q=t.anchor(line[1]),t.anchor(bend)
assert(math.abs(path[1].x-p.x)<0.0001 and math.abs(path[1].y-p.y)<0.0001)
assert(math.abs(path[#path].x-q.x)<0.0001 and math.abs(path[#path].y-q.y)<0.0001)
assert(math.abs(t.sprite_orientation(1,0))<0.0001)
assert(math.abs(t.sprite_orientation(0,1)-0.25)<0.0001)
assert(math.abs(t.sprite_orientation(-1,0)-0.5)<0.0001)
assert(math.abs(t.sprite_orientation(0,-1)-0.75)<0.0001)
print("35 kV curve geometry and pole orientation PASS")
