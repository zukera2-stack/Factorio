-- 0.1.17 mocked connected-corridor preview. This is NOT a Factorio game test.
package.path="./ElectrifiedMainline/?.lua;"..package.path
defines={
    direction={north=0},
    rail_direction={front=0,back=1},
    rail_connection_direction={straight=0,left=1,right=2},
    rail_layer={ground=0,elevated=1}
}
local preview=require("scripts.catenary_corridor_017")
assert(preview.parse_radius(nil)==24)
assert(preview.parse_radius(" 12 ")==12)
for _,s in ipairs({"0","7","33","nan","inf","abc","12 16"}) do
    assert(preview.parse_radius(s)==nil,"invalid radius accepted "..s)
end
local surface,force={},{name="player"}
local function loc(x,y,d,layer)
    return {position={x=x,y=y},direction=d,rail_layer=layer or 0}
end
local function rail(name,id,x)
    return {name=name,valid=true,unit_number=id,
        position={x=x,y=0},surface=surface,force=force}
end
local a=rail("em-high-speed-straight-rail",1,0)
local b=rail("em-curved-high-speed-rail",2,8)
local vanilla=rail("straight-rail",3,10)
local isolated=rail("em-high-speed-straight-rail",4,12)
a.get_connected_rail=function(args)
    if args.rail_direction==0 and args.rail_connection_direction==0 then return b end
end
b.get_connected_rail=function(args)
    if args.rail_direction==1 and args.rail_connection_direction==0 then return a end
    if args.rail_direction==0 and args.rail_connection_direction==0 then return vanilla end
end
a.get_rail_end=function(d)
    if d==0 then return {out_signal_location=loc(1,2,0),
        in_signal_location=loc(1,-2,8)} end
    return {in_signal_location=loc(1,2,8)}
end
b.get_rail_end=function(d)
    if d==0 then return {out_signal_location=loc(1,2,0),
        in_signal_location=loc(9,-2,8)} end
    return {out_signal_location=loc(9,2,0),
        alternative_in_signal_location=loc(9,3,0,1)}
end
local checks,circles,prints=0,{},{}
surface.find_entities_filtered=function(_) return {a,b,isolated} end
surface.can_place_entity=function(args)
    checks=checks+1
    assert(args.name=="em-35kv-catenary-pole" and args.force==force)
    return args.position.y>0
end
rendering={draw_circle=function(args) circles[#circles+1]=args end}
log=function(_) end
local player={selected=a,valid=true,surface=surface,force=force,
    position={x=0,y=0},print=function(message) prints[#prints+1]=message end}
local c=assert(preview.collect(player,24))
assert(c.rails==2,"must traverse only connected custom rails")
assert(#c.markers==4,"native locations deduped by physical position")
assert(c.duplicates==2 and c.skipped_layer==1)
assert(c.api_errors==0 and c.capped==false)
local clear,blocked=preview.check(c)
assert(clear==2 and blocked==2 and checks==4)
preview.show(player,{parameter="24"})
assert(#circles==5,"4 native slots + one nearest-slot highlight")
assert(#prints==2)
assert(circles[1].time_to_live==900)
local old=#circles
preview.show(player,{parameter="50"})
assert(#circles==old,"invalid command must not render")
player.selected=vanilla
surface.find_entities_filtered=function(_) return {} end
preview.show(player,{parameter="24"})
assert(#circles==old,"no HSR may not produce a preview")
local f=assert(io.open("ElectrifiedMainline/scripts/control.lua","r"))
local control=f:read("*a");f:close()
assert(control:find('local corridor_preview017 = require("scripts.catenary_corridor_017")',1,true))
assert(control:find('corridor_preview017.show(player, event)',1,true))
local sf=assert(io.open("ElectrifiedMainline/scripts/catenary_corridor_017.lua","r"))
local source=sf:read("*a");sf:close()
for _,forbidden in ipairs({"create_entity","order_deconstruction","undo_index","teleport(","destroy("}) do
    assert(not source:find(forbidden,1,true),"mutating API forbidden: "..forbidden)
end
print("0.1.17 connected native slot preview (read-only) mocks: PASS")
