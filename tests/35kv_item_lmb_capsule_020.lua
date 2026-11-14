-- Mocked contracts. Do NOT interpret as proof of Factorio dual-use capsule LMB.
package.path="./ElectrifiedMainline/?.lua;"..package.path
defines={direction={north=0}}
local points={
    {position={x=2.5,y=1.5},rail_name="em-high-speed-straight-rail"},
    {position={x=4.5,y=1.5},rail_name="em-curved-high-speed-rail"}
}
local calls={}
package.loaded["scripts.catenary_cursor_018"]={
    collect=function(surface,force,center,radius)
        calls[#calls+1]=radius
        local out={}
        for _,v in ipairs(points) do
            local dx,dy=v.position.x-center.x,v.position.y-center.y
            if dx*dx+dy*dy<=radius*radius then out[#out+1]=v end
        end
        return out
    end
}
local M=require("scripts.catenary_click_020")
local surface,force={},{name="player"}
local cursor={valid_for_read=true,name="em-35kv-click-probe-020",count=3}
local count_built,draws,logs=0,{},{}
local pl={valid=true,index=1,surface=surface,force=force,cursor_stack=cursor,
    position={x=3,y=1},
    can_build_from_cursor=function(a) return a.position.x==2.5 end,
    build_from_cursor=function(a)
        assert(a.position.x==2.5 and a.position.y==1.5)
        count_built=count_built+1;cursor.count=cursor.count-1
    end}
surface.can_place_entity=function(_) return true end
game={tick=200,connected_players={pl},get_player=function(i) return i==1 and pl end}
log=function(s) logs[#logs+1]=s end
rendering={draw_rectangle=function(a) draws[#draws+1]=a end}
assert(M.holding(pl))
assert(M.pick(pl,{x=2.5,y=1.5})==points[1])
assert(M.pick(pl,{x=3,y=5})==nil)
assert(M.pick(pl,{x=2.9,y=1.5})==points[1])
assert(M.pick(pl,{x=2.99,y=1.5})==nil)
assert(M.status(pl,points[1])=="GREEN")
assert(M.status(pl,points[2])=="YELLOW")
assert(M.preview(pl)==2 and #draws==2)
M.on_capsule({item={name="other"},player_index=1,position={x=2.5,y=1.5}})
assert(count_built==0)
M.on_capsule({item={name=cursor.name},player_index=1,position={x=12,y=12}})
assert(count_built==0 and cursor.count==3,"off-rail click must be ignored")
M.on_capsule({item={name=cursor.name},player_index=1,position={x=4.5,y=1.5}})
assert(count_built==0 and cursor.count==3,"blocked/engine denied must not consume")
M.on_capsule({item={name=cursor.name},player_index=1,position={x=2.5,y=1.5},tick=201})
assert(count_built==1 and cursor.count==2,"native build API should consume exactly once")
M.on_capsule({item={name=cursor.name},player_index=1,position={x=2.5,y=1.5},tick=202})
assert(count_built==2 and cursor.count==1)
cursor.name="em-35kv-catenary-pole"
assert(not M.holding(pl) and M.preview(pl)==0)
M.on_capsule({item={name="em-35kv-click-probe-020"},player_index=1,position={x=2.5,y=1.5}})
assert(count_built==2)
local p=assert(io.open("ElectrifiedMainline/prototypes/click_capsule_probe_020.lua")):read("*a")
assert(p:find('probe.place_result=POLE',1,true))
assert(p:find('probe.capsule_action.uses_stack=false',1,true))
assert(p:find('type="instant"',1,true))
assert(p:find('type="script"',1,true))
local c=assert(io.open("ElectrifiedMainline/scripts/control.lua")):read("*a")
assert(c:find('script.on_event(defines.events.on_player_used_capsule',1,true))
local s=assert(io.open("ElectrifiedMainline/scripts/catenary_click_020.lua")):read("*a")
for _,bad in ipairs({"create_entity","destroy(","undo_index","teleport(","set_tiles("}) do
    assert(not s:find(bad,1,true),"forbidden entity or Undo hack: "..bad)
end
print("0.1.20 item-local capsule/pole build mocked contract PASS (game precedence unverified)")
