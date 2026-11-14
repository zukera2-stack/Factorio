-- Lua 5.2 contract test for native-player electric-pole cursor build.
-- No real Factorio executable or native Undo implementation is present here.
package.path="./ElectrifiedMainline/?.lua;"..package.path
defines={direction={north=0},rail_direction={front=0,back=1},
    rail_layer={ground=0,elevated=1}}
local M=require("scripts.catenary_cursor_018")
local S,F={}, {name="player"}
local rails={}
local function loc(x,y,dir,layer)
    return {position={x=x,y=y},direction=dir or 0,rail_layer=layer or 0}
end
local railA={valid=true,name="em-high-speed-straight-rail",
    unit_number=100,position={x=0,y=0},force=F,surface=S}
local railB={valid=true,name="em-curved-high-speed-rail-b",
    unit_number=101,position={x=2,y=0},force=F,surface=S}
railA.get_rail_end=function(d)
    if d==0 then return {out_signal_location=loc(2,0),in_signal_location=loc(2,-2)} end
    return {out_signal_location=loc(4,0),alternative_in_signal_location=loc(99,99,0,1)}
end
railB.get_rail_end=function(d)
    if d==0 then return {out_signal_location=loc(2,0),in_signal_location=loc(2,-2)} end
    return {out_signal_location=loc(2,3)}
end
S.find_entities_filtered=function(_) return rails end
local cursor={valid_for_read=true,name="em-35kv-catenary-pole",count=4}
local count_checks, built={},{}
local player={
    valid=true,index=1,cursor_stack=cursor,position={x=0,y=0},
    surface=S,force=F,
    print=function(_) end,
    can_build_from_cursor=function(p)
        count_checks[#count_checks+1]=p.position
        return p.position.y>=0
    end,
    build_from_cursor=function(p)
        assert(p.position.x==2.5 and p.position.y==0.5)
        cursor.count=cursor.count-1
        built[#built+1]=p.position
    end,
}
S.can_place_entity=function(p) return p.position.y<0 end
game={tick=23,connected_players={player},
    get_player=function(i) return i==1 and player end}
rendering={draw_rectangle=function(p)
    count_checks[#count_checks+1]={render=true,ttl=p.time_to_live}
end}
log=function(_) end
assert(M.holding_mast(player))
rails={railA,railB}
local marks=M.collect(S,F,{x=0,y=0},12)
assert(#marks==4,"two rails must provide four unique native-grid points")
assert(marks[1].position.x==2.5 and marks[1].position.y==0.5)
assert(M.classify(player,marks[1])=="READY")
local blocked=assert((function()
    for _,v in ipairs(marks) do if v.position.y<0 then return v end end
end)())
assert(M.classify(player,blocked)=="OUT_OF_REACH")
local drawn=M.show_held(player)
assert(drawn==4)
local render_count=0
for _,entry in ipairs(count_checks) do if entry.render then
    render_count=render_count+1;assert(entry.ttl==17)
end end
assert(render_count==8)
M.on_place({player_index=1,cursor_position={x=2.61,y=0.56}})
assert(#built==1 and cursor.count==3,"native API invoked only once, no manual refund")
M.on_place({player_index=1,cursor_position={x=2.6,y=-1.4}})
assert(#built==1,"engine rejected unavailable position")
M.on_place({player_index=1,cursor_position={x=30,y=30}})
assert(#built==1,"no HSR location: must never build")
cursor.name="iron-plate"
assert(not M.holding_mast(player))
M.on_place({player_index=1,cursor_position={x=2.5,y=0.5}})
assert(#built==1,"other cursor item protected")
assert(M.show_held(player)==0)
cursor.name="em-35kv-catenary-pole"
rails={}
M.on_place({player_index=1,cursor_position={x=2.5,y=0.5}})
assert(#built==1,"vanilla-only/empty area must never build")
local control=assert(io.open("ElectrifiedMainline/scripts/control.lua","r")):read("*a")
assert(control:find('require("scripts.catenary_cursor_018")',1,true))
assert(control:find('script.on_event("em-place-catenary-native"',1,true))
local datafile=assert(io.open("ElectrifiedMainline/data.lua","r")):read("*a")
assert(datafile:find('require("prototypes.catenary_cursor_input_018")',1,true))
local core=assert(io.open("ElectrifiedMainline/scripts/catenary_cursor_018.lua","r")):read("*a")
assert(core:find("player.build_from_cursor",1,true))
for _,forbidden in ipairs({"create_entity","destroy(", "undo_index", "teleport(", "order_deconstruction"}) do
    assert(not core:find(forbidden,1,true),"forbidden API found: "..forbidden)
end
print("0.1.18 native player cursor build + per-item overlay mocks: PASS")
