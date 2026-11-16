-- 0.1.34: regression of missing northern cantilever and wire levels.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local layout=require("scripts.mast_visual_034")
local geo=require("scripts.native_wire_geometry_028")
local eq=function(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." != "..tostring(b)) end
assert(layout.SOUTH_RISE==0.40)
assert(layout.NORTH_DROP==2.20)
local standard="em-35kv-catenary-pole"
local north="em-35kv-catenary-pole-north"
eq(layout.mast_shift(standard),-2.93125)
eq(layout.mast_shift(north),-0.33125)
eq(layout.cantilever_shift(standard),layout.mast_shift(standard))
eq(layout.cantilever_shift(north),layout.mast_shift(north))
local pos={x=0,y=0}
local southStandard=geo.tip_for_pole(pos,"north",nil,standard)
local oldStandard=geo.tip(pos,"north")
eq(southStandard.y,oldStandard.y-layout.SOUTH_RISE)
eq(southStandard.x,oldStandard.x)
local northern=geo.tip_for_pole(pos,"south",nil,north)
local oldNorth=geo.tip(pos,"south")
eq(northern.y,oldNorth.y+layout.NORTH_DROP)
eq(northern.x,oldNorth.x)
for _,face in ipairs({"east","west","northeast","northwest","southeast","southwest"}) do
  local old=geo.tip(pos,face)
  local a=geo.tip_for_pole(pos,face,nil,standard)
  local b=geo.tip_for_pole(pos,face,nil,north)
  eq(old.x,a.x);eq(old.y,a.y)
  eq(old.x,b.x);eq(old.y,b.y)
end
local proto=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(proto:find('scale = 0.5, shift = {0,mast034.mast_shift(catenary.name)}}',1,true))
assert(proto:find('northern.pictures.layers[1].shift={0,mast034.mast_shift(northern.name)}',1,true))
local power=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(power:find('target={entity=e,offset={0,mast034.cantilever_shift(e.name)}}',1,true))
assert(not power:find('if e.name==NORTH then return end',1,true))
local ghosts=assert(io.open("ElectrifiedMainline/scripts/ghost_mast_023.lua")):read("*a")
assert(ghosts:find('local POLES={POLE,NORTH}',1,true))
assert(ghosts:find('mast034.cantilever_shift(entity.ghost_name)',1,true))
local catenary=assert(io.open("ElectrifiedMainline/scripts/catenary_art_030.lua")):read("*a")
local native=assert(io.open("ElectrifiedMainline/scripts/native_wire_028.lua")):read("*a")
assert(catenary:find("geo.tip_for_pole",1,true))
assert(native:find("geo.tip_for_pole",1,true))
print("0.1.34 both C arms, south raised, native helper/ghost alignment PASS")
