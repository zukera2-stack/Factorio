-- Pure Lua tests for deterministic selection and C-mast attachment projection.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local g=require("scripts.native_wire_geometry_026")
local function eq(a,b) assert(math.abs(a-b)<0.00001,tostring(a).." ~= "..tostring(b)) end
local faces={
 east={1.5,0},southeast={1.06,1.06},south={0,1.5},
 southwest={-1.06,1.06},west={-1.5,0},
 northwest={-1.06,-1.06},north={0,-1.5},
 northeast={1.06,-1.06}}
for face,p in pairs(faces) do
 local tip=assert(g.tip({x=10,y=20},face))
 eq(tip.x,10+p[1]);eq(tip.y,20+p[2])
end
assert(g.tip({x=0,y=0},"bogus")==nil)
local function mast(id,x,y) return {unit_number=id,position={x=x,y=y},valid=true} end
local a=mast(1,1,0)
local b=mast(2,12,0)
local far=mast(3,30,0)
local x,y,err=g.pick_pair({far,b,a},{x=0,y=0},24,16)
assert(x==a and y==b and err==nil)
assert(select(3,g.pick_pair({a},{x=0,y=0},24,16)))
assert(select(3,g.pick_pair({a,far},{x=0,y=0},40,16)))
local r=assert(io.open("ElectrifiedMainline/scripts/native_wire_probe_026.lua")):read("*a")
assert(r:find("defines.wire_origin.player",1,true))
assert(r:find("ca.can_wire_reach(cb)",1,true))
assert(r:find("ca.connect_to(cb,true,defines.wire_origin.player)",1,true))
assert(r:find("anchor.destructible=false",1,true))
assert(r:find("destroy_anchors(run)",1,true))
local p=assert(io.open("ElectrifiedMainline/prototypes/native_wire_probe_026.lua")):read("*a")
assert(p:find("auto_connect_up_to_n_wires = 0",1,true))
assert(p:find("supply_area_distance = 0",1,true))
assert(p:find("draw_copper_wires = true",1,true))
print("0.1.26 native wire probe geometry/API contract QA PASS (Factorio gameplay NOT tested)")
