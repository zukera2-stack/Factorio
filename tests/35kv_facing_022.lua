-- 0.1.22 mocked geometric case: green placement is unchanged.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local g=require("scripts.mast_facing_022")
local view=require("scripts.overhead_geometry_012")
local function rail(id,name,x,y,ax,ay,bx,by,da,db)
    local a={position={x=ax,y=ay},direction=da,rail_layer=0}
    local b={position={x=bx,y=by},direction=db,rail_layer=0}
    return {valid=true,unit_number=id,name=name,
        position={x=x,y=y},direction=0,
        get_rail_end=function(d) return {location=(d==0 and a or b)} end}
end
local straight=rail(1,"em-high-speed-straight-rail",-4,-3,0,0,6,0,4,12)
local mast={x=3,y=1.6}
local picked=g.nearest(mast,{straight},0,1,0)
assert(picked and picked.method=="rail_end_chord")
assert(math.abs(picked.point.x-3)<0.001)
assert(math.abs(picked.point.y)<0.001)
assert(view.face(mast,straight.position)=="northwest")
assert(view.face(mast,picked.point)=="north")
local flipped=rail(2,"em-high-speed-straight-rail",-4,-3,6,0,0,0,12,4)
local rev=g.nearest(mast,{flipped},0,1,0)
assert(math.abs(rev.point.x-picked.point.x)<0.001)
local curve=rail(3,"em-curved-high-speed-rail",-5,-5,0,0,4,4,4,8)
local cp=g.nearest({x=3,y=1},{curve},0,1,0)
assert(cp.method=="rail_end_curve")
assert(cp.point.x>=-0.1 and cp.point.x<=4.1)
assert(cp.point.y>=-0.1 and cp.point.y<=4.1)
local other=rail(4,"em-high-speed-straight-rail",3,8,0,7,6,7,4,12)
assert(g.nearest(mast,{other,straight},0,1,0).rail_id==1)
local same=rail(5,"em-high-speed-straight-rail",-4,-3,0,0,6,0,4,12)
assert(g.nearest(mast,{same,straight},0,1,0).rail_id==1)
local invalid=rail(6,"em-high-speed-straight-rail",1,1,0,0,6,0,4,12)
invalid.get_rail_end=function(_) return {
    location={position={x=0,y=0},rail_layer=3}
} end
assert(g.nearest(mast,{invalid},0,1,0).method=="entity_center_fallback")
local src=assert(io.open("ElectrifiedMainline/scripts/power_019.lua")):read("*a")
assert(src:find('n.face=view.face(e.position,target)',1,true))
assert(src:find('n.tx,n.ty,n.side,rail=rail_tangent(e)',1,true))
assert(src:find('[ElectrifiedMainline][face022]',1,true))
print("0.1.22 RailEnd-based sprite facing: mock PASS; gameplay unverified")
