-- 0.1.42: exact accepted north height / native tips; pure Lua, not game QA.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local layout=require("scripts.mast_visual_034")
local geo=require("scripts.native_wire_geometry_028")
local function near(a,b) assert(math.abs(a-b)<0.000001,tostring(a).." ~= "..tostring(b)) end
assert(layout.STANDARD=="em-35kv-catenary-pole")
assert(layout.SHORT_NORTH=="em-35kv-catenary-pole-north")
near(layout.NORTH_DROP,2.02)
near(layout.mast_shift(layout.STANDARD),-2.53125)
near(layout.mast_shift(layout.SHORT_NORTH),-2.53125+2.02)
near(layout.cantilever_shift(layout.SHORT_NORTH),layout.mast_shift(layout.SHORT_NORTH))
near(layout.helper_delta(layout.SHORT_NORTH,"south"),2.02)
near(layout.helper_delta(layout.STANDARD,"north"),0)
local at={x=100,y=-20}
local north=geo.tip_for_pole(at,"south",nil,layout.SHORT_NORTH)
local standard=geo.tip_for_pole(at,"south",nil,layout.STANDARD)
near(north.y-standard.y,2.02)
near(north.x,standard.x)
for _,face in ipairs({"east","southeast","south","southwest","west","northwest","north","northeast"}) do
  local old=geo.tip(at,face)
  local standard_tip=geo.tip_for_pole(at,face,nil,layout.STANDARD)
  near(old.x,standard_tip.x);near(old.y,standard_tip.y)
end
local proto=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(proto:find('pole-south-039.png',1,true))
assert(proto:find('pole-north-039.png',1,true))
assert(proto:find('25kv-south-039.png',1,true))
assert(proto:find('25kv-north-039.png',1,true))
for _,face in ipairs({"east","southeast","south","southwest","west","northwest","north","northeast"}) do
  assert(proto:find("pole-arm-"..face.."-039.png",1,true))
end
print("0.1.42 dual native mast + 8 accepted arm sprites + helper y=2.02 PASS")