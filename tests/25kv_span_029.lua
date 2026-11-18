-- 0.1.29 HSR catenary span limits + helper reach contract.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local L=require("scripts.catenary_limits_029")
local V=require("scripts.overhead_geometry_012")
assert(L.STRAIGHT==32 and L.CURVE==16 and L.WIRE_REACH==40)
local function mast(id,x,y,tx,ty,side)
 return {id=id,x=x,y=y,tx=tx or 1,ty=ty or 0,side=side or 1,
   rail_adjacent=true,surface_index=1,force_name="player"}
end
local a=mast(1,0,0)
local s32=mast(2,32,0)
local s33=mast(3,33,0)
assert(L.allowed(a,s32,{length=32,curved=false}))
assert(not L.allowed(a,s33,{length=33,curved=false}))
assert(not L.allowed(a,s32,{length=33,curved=true}))
local c16=mast(4,12,10,0,1)
local c17=mast(5,12,12,0,1)
assert(L.allowed(a,c16,{length=18,curved=true}))
assert(not L.allowed(a,c17,{length=19,curved=true}))
assert(not L.allowed(a,c16,{length=40,curved=true}))
assert(not L.allowed(a,c16,nil))
assert(V.corner_candidate(a,c16,16))
assert(not V.corner_candidate(a,c17,16))
local different_side=mast(6,12,10,0,1,-1)
assert(not V.corner_candidate(a,different_side,16))
local s=require("scripts.power_topology")
assert(s.compatible(a,s32,L.STRAIGHT))
assert(not s.compatible(a,s33,L.STRAIGHT))
local p=assert(io.open("ElectrifiedMainline/prototypes/native_wire_auto_028.lua")):read("*a")
assert(p:find('require("scripts.catenary_limits_029").WIRE_REACH',1,true))
local script=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
local info=assert(io.open("ElectrifiedMainline/info.json")):read("*a")
if not info:find('"version": "0.1.47"',1,true) then
for _,marker in ipairs({
 'local SPAN,CURVE_SPAN,RADIUS = limits.STRAIGHT,limits.CURVE,3',
 'position=e.position,radius=CURVE_SPAN,name=POLES',
 'position=change.position,radius=SPAN+RADIUS+4',
 'max_walk=limits.STRAIGHT*1.5+4',
 'and limits.allowed(x,y,info)',
 'and limits.allowed(a,b,info)',
 'local samples=math.max(3,math.ceil(distance/2))'
}) do assert(script:find(marker,1,true),marker) end
else
 assert(script:find("limits.WIRE_REACH*1.5+4",1,true))
 assert(script:find("visual047.plan(s.nodes)",1,true))
end
assert(not script:find("rendering.draw_line",1,true))
print("0.1.29 limits straight=32 curve=16 connector=40: pure Lua PASS")
