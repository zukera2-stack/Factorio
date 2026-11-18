-- 0.1.27 static geometry and no-old-line regression.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local g=require("scripts.native_wire_geometry_026")
local function close(a,b) assert(math.abs(a-b)<0.00001,tostring(a).." ~= "..tostring(b)) end
local faces={
 east={1.75,-0.80},southeast={1.68,-0.84},south={1.75,-0.80},
 southwest={-1.68,-0.84},west={-1.75,-0.80},
 northwest={-1.68,-0.84},north={-1.75,-0.80},
 northeast={1.68,-0.84}
}
for face,off in pairs(faces) do
 local tip=assert(g.tip({x=10,y=20},face))
 close(tip.x,10+off[1]);close(tip.y,20+off[2])
 local fine=assert(g.tip({x=10,y=20},face,-0.25,0.15))
 close(fine.x,tip.x-0.25);close(fine.y,tip.y+0.15)
end
local south=g.tip({x=-33.5,y=-0.5},"south")
close(south.x,-31.75);close(south.y,-1.3)
assert(g.tip({x=0,y=0},"invalid")==nil)
local function mast(id,x,y) return {unit_number=id,position={x=x,y=y},valid=true} end
local a,b,far=mast(1,1,0),mast(2,12,0),mast(3,30,0)
local x,y,err=g.pick_pair({far,b,a},{x=0,y=0},24,16)
assert(x==a and y==b and err==nil)
assert(select(3,g.pick_pair({a},{x=0,y=0},24,16)))
assert(select(3,g.pick_pair({a,far},{x=0,y=0},40,16)))
local p=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(not p:find("rendering.draw_line",1,true))
assert(p:find("rendering.draw_sprite",1,true))
assert(p:find("o.destroy()",1,true))
local r=assert(io.open("ElectrifiedMainline/scripts/native_wire_probe_026.lua")):read("*a")
for _,token in ipairs({"defines.wire_origin.player","ca.can_wire_reach(cb)",
 "ca.connect_to(cb,true,defines.wire_origin.player)",
 "anchor.destructible=false","cleanup_on_version_change",
 "negative DY moves UP"}) do assert(r:find(token,1,true),token) end
local ctl=assert(io.open("ElectrifiedMainline/scripts/control.lua")):read("*a")
assert(ctl:find("native_wire_probe026.cleanup_on_version_change()",1,true))
local proto=assert(io.open("ElectrifiedMainline/prototypes/native_wire_probe_026.lua")):read("*a")
for _,token in ipairs({"auto_connect_up_to_n_wires = 0",
 "supply_area_distance = 0","draw_copper_wires = true"}) do
 assert(proto:find(token,1,true),token) end
print("0.1.27 insulator calibration and no-Lua-wire static QA PASS (game UNTESTED)")
