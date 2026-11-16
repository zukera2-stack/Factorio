-- 0.1.36: screenshot overlay correction: LOWER the SOUTH mast/arm by 0.40,
-- while preserving its actual native connector AND its drawn contact line.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local L=require("scripts.mast_visual_034")
local G=require("scripts.native_wire_geometry_028")
local A=require("scripts.catenary_art_030")
local equal=function(a,b,msg)
  assert(math.abs(a-b)<0.00001,(msg or "").." "..tostring(a).." != "..tostring(b))
end
local std,short=L.STANDARD,L.SHORT_NORTH
equal(L.SOUTH_RISE,0.40,"screenshot measured 0.40 tile")
equal(L.mast_shift(std),L.BASE_SHIFT,"footer lowered 0.40 to selection marker")
equal(L.cantilever_shift(std),L.BASE_SHIFT-L.SOUTH_EXTEND_TILES,
      "triangular hanger lowered 0.40; full 54-source-row truss retained")
equal(L.mast_shift(short),L.BASE_SHIFT+L.NORTH_DROP,"northern native mast unchanged")
equal(L.cantilever_shift(short),L.mast_shift(short),"northern arm unchanged")
-- Preserve the 0.1.35 contact graphic and native helper exactly.
equal(L.visual_delta(std,"north"),-L.SOUTH_RISE-L.SOUTH_EXTEND_TILES,
      "original custom contact wire level preserved")
equal(L.helper_delta(std,"north"),0,"original native south connector restored")
local pos={x=10,y=20}
local tip=G.tip_for_pole(pos,"north",nil,std)
local oldtip=G.tip(pos,"north")
equal(tip.x,oldtip.x);equal(tip.y,oldtip.y)
local src={x=15,y=12}
local shifted=A.visual_point(src,"north",std)
local old35=src.y-2.53125+0.90-L.SOUTH_RISE-L.SOUTH_EXTEND_TILES
equal(shifted.y,old35,"custom contact sprite MUST NOT be moved")
equal(shifted.x,src.x-0.22)
local northDraw=A.visual_point(src,"south",short)
equal(northDraw.y,src.y-2.53125,"northern contact unchanged")
local proto=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(proto:find('pole-south-lattice-036.png',1,true))
assert(proto:find('northern.pictures.layers[1].height=384',1,true))
local arm=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(arm:find("mast034.cantilever_shift(e.name)",1,true))
local ghost=assert(io.open("ElectrifiedMainline/scripts/ghost_mast_023.lua")):read("*a")
assert(ghost:find("mast034.cantilever_shift(entity.ghost_name)",1,true))
print("0.1.36 screenshot 0.40-tile south mast+arm alignment and intact native contact graph PASS")
