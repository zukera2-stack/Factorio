-- 0.1.20: item-local normal LMB hypothesis, NOT global mouse interception.
-- A capsule has its own vanilla use action. We only respond to the named
-- experimental item. This module never creates/destroys any world entity.
local M={}
local native=require("scripts.catenary_cursor_018")
local ITEM="em-35kv-click-probe-020"
local POLE="em-35kv-catenary-pole"
local RADIUS=12
local CLICK_HALF=0.42 -- rendered square half-width 0.33 + 0.09 tolerance
local TTL=17

local function dist2(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy
end

function M.holding(player)
    local stack=player and player.cursor_stack
    return stack and stack.valid_for_read and stack.name==ITEM or false
end

function M.pick(player,mouse)
    local points=native.collect(player.surface,player.force,mouse,1)
    for _,p in ipairs(points) do
        if math.abs(p.position.x-mouse.x)<=CLICK_HALF
            and math.abs(p.position.y-mouse.y)<=CLICK_HALF then
            return p
        end
    end
    return nil
end

function M.status(player,point)
    local ok,yes=pcall(function()
        return player.can_build_from_cursor{position=point.position}
    end)
    if not ok then return "API_ERROR" end
    if yes then return "GREEN" end
    local collision_ok,clear=pcall(function()
        return player.surface.can_place_entity{
            name=POLE,position=point.position,
            direction=defines.direction.north,force=player.force
        }
    end)
    if collision_ok and clear then return "YELLOW" end
    return "RED"
end

local COLORS={
    GREEN={r=0.09,g=0.97,b=0.37,a=0.85},
    YELLOW={r=1,g=0.75,b=0.15,a=0.85},
    RED={r=0.97,g=0.23,b=0.18,a=0.85},
    API_ERROR={r=1,g=0.2,b=0.9,a=0.85}
}
function M.preview(player)
    if not M.holding(player) then return 0 end
    local candidates=native.collect(player.surface,player.force,player.position,RADIUS)
    for _,p in ipairs(candidates) do
        local c=COLORS[M.status(player,p)]
        local x,y=p.position.x,p.position.y
        rendering.draw_rectangle{
            surface=player.surface,
            left_top={x=x-0.33,y=y-0.33},
            right_bottom={x=x+0.33,y=y+0.33},
            color=c,width=1.8,time_to_live=TTL,
            draw_on_ground=true,players={player}
        }
    end
    return #candidates
end

function M.refresh_all()
    for _,player in pairs(game.connected_players) do
        if player.valid and M.holding(player) then M.preview(player) end
    end
end

local function cursor_count(player)
    local s=player.cursor_stack
    if s and s.valid_for_read and s.name==ITEM then return s.count end
    return 0
end

function M.on_capsule(event)
    if not (event.item and event.item.name==ITEM) then return end
    local player=game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local p=event.position
    if not (p and p.x and p.y) then
        log("[ElectrifiedMainline][0.1.20][probe] capsule-event-no-position")
        return
    end
    if not M.holding(player) then
        log("[ElectrifiedMainline][0.1.20][probe] capsule-event-cursor-not-probe")
        return
    end
    local point=M.pick(player,p)
    if not point then
        log(string.format(
            "[ElectrifiedMainline][0.1.20][probe] REJECT outside-green player=%d click=(%.3f,%.3f) tick=%d",
            event.player_index,p.x,p.y,event.tick or game.tick))
        return
    end
    local state=M.status(player,point)
    if state~="GREEN" then
        log(string.format(
            "[ElectrifiedMainline][0.1.20][probe] REJECT %s at=(%.3f,%.3f) tick=%d",
            state,point.position.x,point.position.y,event.tick or game.tick))
        return
    end
    local before=cursor_count(player)
    log(string.format(
        "[ElectrifiedMainline][0.1.20][probe] BUILD_REQUEST player=%d click=(%.3f,%.3f) pole=(%.3f,%.3f) rail=%s count_before=%d tick=%d",
        event.player_index,p.x,p.y,point.position.x,point.position.y,
        point.rail_name or "unknown",before,event.tick or game.tick))
    -- Engine-owned actual entity placement, inventory and Undo.
    -- If the capsule-with-place_result dual-use is unsupported, this API
    -- may reject the build; the log records it, and we reject the approach.
    local ok,err=pcall(function()
        player.build_from_cursor{position=point.position}
    end)
    log(string.format(
        "[ElectrifiedMainline][0.1.20][probe] BUILD_RESULT ok=%s count_before=%d count_after=%d error=%s",
        tostring(ok),before,cursor_count(player),ok and "nil" or tostring(err)))
end

return M
