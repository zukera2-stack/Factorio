-- Pure Lua visual suspension profile QA, requires no Factorio runtime.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local v=require("scripts.overhead_geometry_012")
local function close(a,b) assert(math.abs(a-b)<0.000001,tostring(a).." ~= "..tostring(b)) end
local p={}
for i=0,8 do p[#p+1]={x=i,y=1.0} end
local lower,upper,drops=v.suspension(p,0.30,0.11)
assert(#lower==9 and #upper==9 and #drops==3)
close(lower[1].x,0);close(lower[9].x,8)
close(upper[1].y,0.70);close(upper[9].y,0.70)
close(upper[5].y,0.81)
close(drops[2].from.x,4);close(drops[2].to.x,4)
close(drops[2].to.y,1)
assert(drops[2].from.y<drops[2].to.y)
-- The contact wire does not deviate from the approved mast P2 anchor.
local a=v.wire_anchor({x=10,y=20,face="east"},0.5)
local b=v.wire_anchor({x=18,y=20,face="east"},0.5)
p={}
for i=0,8 do local t=i/8;p[#p+1]={x=a.x+t*(b.x-a.x),y=a.y+t*(b.y-a.y)} end
lower,upper,drops=v.suspension(p,0.30,0.11)
close(lower[1].x,a.x);close(lower[#lower].x,b.x)
close(lower[1].y,a.y);close(lower[#lower].y,b.y)
-- Curved contact path is preserved, only messenger y is offset.
local curve=v.bezier({x=0,y=0,tx=1,ty=0},{x=8,y=8,tx=0,ty=1},8)
lower,upper,drops=v.suspension(curve,0.3,0.11)
for i=1,#curve do close(lower[i].x,curve[i].x);close(lower[i].y,curve[i].y) end
-- Short and empty path edge safety.
assert(#(select(1,v.suspension({})))==0)
assert(#(select(1,v.suspension({{x=0,y=0}})))==0)
-- The renderer retains the same edge kind, avoids changes to power/Undo.
local f=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(f:find("view.suspension(pts,0.30,0.11)",1,true))
assert(f:find('kind=="feeder"',1,true))
assert(f:find("connected_rail_path(a,b)",1,true))
assert(f:find('transfer_MW=0',1,true))
print("0.1.25 suspended contact + messenger + three droppers static QA PASS")
