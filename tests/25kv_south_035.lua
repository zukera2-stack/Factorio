-- 0.1.35: user screenshot measured 27px wire-level gap, source at scale .5.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local L=require("scripts.mast_visual_034")
local G=require("scripts.native_wire_geometry_028")
local A=require("scripts.catenary_art_030")
local eq=function(a,b,msg)
 assert(math.abs(a-b)<0.000001,(msg or "").." "..tostring(a).." != "..tostring(b))
end
assert(L.SOUTH_EXTEND_SOURCE_ROWS==54)
eq(L.SOUTH_EXTEND_TILES,0.84375,"27/32px")
local std,north=L.STANDARD,L.SHORT_NORTH
eq(L.mast_shift(std),-2.53125,"0.1.36 foundation lowered 0.40 to world placement marker")
eq(L.cantilever_shift(std),L.mast_shift(std)-27/32,"southern arm up")
eq(L.cantilever_shift(north),L.mast_shift(north),"northern arm unchanged")
eq(L.helper_delta(std,"north"),0,"restore native helper pre-0.1.34")
eq(L.helper_delta(north,"south"),L.NORTH_DROP,"north helper unchanged")
local e={x=0,y=0}
local native=G.tip_for_pole(e,"north",nil,std)
local old=G.tip(e,"north")
eq(native.x,old.x);eq(native.y,old.y,"restore actual native connector")
local p={x=12,y=25}
local previous=A.visual_point(p,"north") -- pure legacy 0.1.32
local actual=A.visual_point(p,"north",std)
eq(actual.x,previous.x,"do not shift x")
eq(actual.y,previous.y-L.SOUTH_RISE-L.SOUTH_EXTEND_TILES,"source-derived 27px")
-- Actual previous 0.1.34 helper was 0.4 tiles higher. Restoring
-- it and adjusting visual delta causes net (old-27px) visible contact.
eq(actual.y-(previous.y-L.SOUTH_RISE),
   -L.SOUTH_EXTEND_TILES,"net visible contact moves up 27px")
local unchanged=A.visual_point(p,"south",north)
local legacy=A.visual_point(p,"south")
eq(unchanged.x,legacy.x);eq(unchanged.y,legacy.y)
local proto=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(proto:find('catenary.pictures.layers[1].height=512',1,true))
assert(proto:find('pole-south-lattice-036.png',1,true))
assert(proto:find('northern.pictures.layers[1].height=384',1,true))
local arm=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(arm:find("mast034.cantilever_shift(e.name)",1,true))
local ghosts=assert(io.open("ElectrifiedMainline/scripts/ghost_mast_023.lua")):read("*a")
assert(ghosts:find("mast034.cantilever_shift(entity.ghost_name)",1,true))
print("0.1.36 south native shaft lowered; lattice source changed; hidden anchor unchanged PASS")
