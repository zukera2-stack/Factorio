-- 0.1.13 pure-Lua geometry checks. No Factorio runtime, signals or power grid.
package.path = "./ElectrifiedMainline/?.lua;" .. package.path
local v = require("scripts.overhead_geometry_012")
local t = require("scripts.power_topology")
local function close(a, b)
    assert(math.abs(a-b) < 0.00001, tostring(a) .. " ~= " .. tostring(b))
end
local dirs = {
    {"east",1,0}, {"southeast",1,1}, {"south",0,1},
    {"southwest",-1,1}, {"west",-1,0}, {"northwest",-1,-1},
    {"north",0,-1}, {"northeast",1,-1},
}
for _,d in ipairs(dirs) do
    assert(v.face({x=0,y=0},{x=d[2],y=d[3]}) == d[1], "facing: " .. d[1])
end
assert(v.face({x=0,y=0},nil) == "east")
assert(v.face({x=0,y=0},{x=0,y=0}) == "east")
local anchor = v.wire_anchor({x=10,y=20,face="north"},0.5)
close(anchor.x,10);close(anchor.y,18)
local a={x=0,y=0,tx=1,ty=0}
local b={x=8,y=8,tx=0,ty=1}
local path=v.bezier(a,b,8)
assert(#path==9)
close(path[1].x,a.x);close(path[1].y,a.y)
close(path[9].x,b.x);close(path[9].y,b.y)
assert(path[5].x>0 and path[5].y>0)
local na={id=1,x=0,y=0,tx=1,ty=0,rail_adjacent=true,surface_index=1,force_name="player"}
local nb={id=2,x=8,y=8,tx=0,ty=1,rail_adjacent=true,surface_index=1,force_name="player"}
assert(v.corner_candidate(na,nb,16))
nb.ty=0;nb.tx=1
assert(not v.corner_candidate(na,nb,16),"parallel rails must not form a corner")
local n1={id=1,x=0,y=0,tx=1,ty=0,side=-1,rail_adjacent=true}
local n2={id=2,x=10,y=0,tx=1,ty=0,side=-1,rail_adjacent=true}
assert(t.compatible(n1,n2,16))
assert(select(1,t.choose(n1,{n2},16)).id==2)
n2.side=1
assert(not t.compatible(n1,n2,16),"opposite sides must not connect")
print("0.1.13 visual geometry: 8 facings, bezier, corner and topology PASS")