-- 0.1.33 north-side native item/prototype, HSR graph and pixel contract.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local geo=require("scripts.native_wire_geometry_028")
local mast034=require("scripts.mast_visual_034")
local pos={x=5,y=10}
local normal=assert(geo.tip_for_pole(pos,"south",nil,"em-35kv-catenary-pole"))
local northern=assert(geo.tip_for_pole(pos,"south",nil,"em-35kv-catenary-pole-north"))
assert(math.abs(northern.x-normal.x)<1e-6)
-- Original standard south-of-rail mast and connector are now raised 0.40.
-- A shorter north-side variant keeps the old native +2.20 shift.
assert(math.abs(northern.y-normal.y-mast034.NORTH_DROP)<1e-6)
local n1=assert(geo.tip_for_pole(pos,"north",nil,"em-35kv-catenary-pole"))
local n2=assert(geo.tip_for_pole(pos,"north",nil,"em-35kv-catenary-pole-north"))
assert(n1.x==n2.x and math.abs(n2.y-n1.y-mast034.SOUTH_RISE)<1e-6)
local proto=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(proto:find('northern.pictures.layers[1].filename=graphics.."pole-north-short-033.png"',1,true))
assert(proto:find('northern.pictures.layers[1].shift={0,mast034.mast_shift(northern.name)}',1,true))
assert(proto:find('type="item",name="em-35kv-catenary-pole-north"',1,true))
local power=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(power:find("local POLES={POLE,NORTH}",1,true))
assert(not power:find("if e.name==NORTH then return end",1,true),
  "0.1.33 bare northern shaft regression: arm overlay must be rendered")
assert(power:find("mast034.cantilever_shift(e.name)",1,true))
assert(not power:find("rendering.draw_line",1,true))
local nat=assert(io.open("ElectrifiedMainline/scripts/native_wire_028.lua")):read("*a")
local art=assert(io.open("ElectrifiedMainline/scripts/catenary_art_030.lua")):read("*a")
local ctrl=assert(io.open("ElectrifiedMainline/scripts/control.lua")):read("*a")
assert(nat:find("geo.tip_for_pole",1,true))
assert(art:find("geo.tip_for_pole",1,true))
assert(ctrl:find('entity.name=="em-35kv-catenary-pole-north"',1,true))
print("0.1.33 north-of-rail shorter native mast and wire-tip contract PASS")
