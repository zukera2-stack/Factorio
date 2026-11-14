-- ElectrifiedMainline 0.1.17: connected high-speed corridor / native rail signal slot preview.
-- READ-ONLY. No signal proxy, pole/ghost creation, teleport, inventory or Undo changes.
local M = {}
local rail_slots = require("scripts.rail_slot_debug_014")
local POLE = "em-35kv-catenary-pole"
local RAILS = {
    ["em-high-speed-straight-rail"] = true,
    ["em-curved-high-speed-rail"] = true,
    ["em-curved-high-speed-rail-b"] = true,
    ["em-half-diagonal-high-speed-rail"] = true,
}
local MAX_RAILS, MAX_SLOTS, TTL = 128, 160, 900
local DEFAULT_RADIUS = 24
local CONNECTIONS = {
    defines.rail_connection_direction.straight,
    defines.rail_connection_direction.left,
    defines.rail_connection_direction.right,
}

local function dist2(a,b)
    local dx,dy = a.x-b.x, a.y-b.y
    return dx*dx+dy*dy
end

local function rail_key(rail)
    return tostring(rail.unit_number or (
        rail.name .. ":" .. rail.position.x .. ":" .. rail.position.y ..
        ":" .. tostring(rail.direction)))
end

-- One physical base marker per native location, even when two signal
-- directions or neighbouring rail ends report the same physical coordinate.
local function location_key(p)
    return string.format("%d:%d", math.floor(p.x*256+0.5),
        math.floor(p.y*256+0.5))
end

function M.parse_radius(parameter)
    if not parameter or parameter:match("^%s*$") then return DEFAULT_RADIUS end
    if not parameter:match("^%s*%S+%s*$") then return nil end
    local radius = tonumber(parameter)
    if not radius or radius~=radius or radius<8 or radius>32 then return nil end
    return radius
end

-- Follow the ACTUAL HSR rail graph. Nearby parallel but disconnected
-- tracks, ordinary rails, elevated rails and foreign rail types are excluded.
-- This does not compute a hand-drawn approximation of track geometry:
-- signal locations come from the game engine's LuaRailEnd.
function M.collect(player, radius)
    local start = rail_slots.nearest_rail(player)
    if not start then return nil, "no-hsr" end
    local queue = {start}
    local visited = {[rail_key(start)] = true}
    local markers, seen_positions = {}, {}
    local n_rails, skipped_layer, api_errors, duplicates = 0, 0, 0, 0
    local capped = false
    local idx = 1
    while idx<=#queue and n_rails<MAX_RAILS do
        local rail = queue[idx]
        idx = idx+1
        if rail.valid then
            n_rails = n_rails+1
            local locations, errors = rail_slots.collect(rail)
            api_errors = api_errors + #errors
            for _,location in ipairs(locations) do
                if location.rail_layer~=defines.rail_layer.ground then
                    skipped_layer = skipped_layer+1
                else
                    local key = location_key(location.position)
                    if seen_positions[key] then
                        duplicates = duplicates+1
                    elseif #markers<MAX_SLOTS then
                        seen_positions[key] = true
                        markers[#markers+1] = {
                            position={x=location.position.x,y=location.position.y},
                            direction=location.direction,
                            rail_layer=location.rail_layer,
                            rail_name=rail.name,
                            reference={x=rail.position.x,y=rail.position.y}
                        }
                    else
                        capped = true
                    end
                end
            end
            for _,rail_dir in ipairs({
                defines.rail_direction.front, defines.rail_direction.back}) do
                for _,connection in ipairs(CONNECTIONS) do
                    local ok,other = pcall(function()
                        return rail.get_connected_rail{
                            rail_direction=rail_dir,
                            rail_connection_direction=connection}
                    end)
                    if not ok then
                        api_errors = api_errors+1
                    elseif other and other.valid and RAILS[other.name]
                        and other.surface==start.surface
                        and other.force==start.force
                        and dist2(other.position,start.position)<=radius*radius then
                        local key = rail_key(other)
                        if not visited[key] then
                            visited[key] = true
                            if #queue<MAX_RAILS then
                                queue[#queue+1] = other
                            else
                                capped = true
                            end
                        end
                    end
                end
            end
        end
    end
    if idx<=#queue then capped=true end
    table.sort(markers,function(a,b)
        if a.position.x~=b.position.x then
            return a.position.x<b.position.x end
        return a.position.y<b.position.y
    end)
    return {
        start=start, rails=n_rails, markers=markers, duplicates=duplicates,
        skipped_layer=skipped_layer, api_errors=api_errors, capped=capped
    }
end

-- Collision checks are an engine preflight, not permission to place a mast
-- and not evidence that its cantilever physically reaches the track.
function M.check(result)
    local clear, blocked = 0, 0
    for _,mark in ipairs(result.markers) do
        local ok,can = pcall(function()
            return result.start.surface.can_place_entity{
                name=POLE, position=mark.position,
                direction=defines.direction.north, force=result.start.force}
        end)
        if not ok then
            mark.status="API_ERR"
            result.api_errors=result.api_errors+1
        elseif can then
            mark.status="CLEAR";clear=clear+1
        else
            mark.status="BLOCKED";blocked=blocked+1
        end
    end
    return clear, blocked
end

function M.show(player, command)
    local radius=M.parse_radius(command and command.parameter)
    if not radius then
        player.print("[EM 0.1.17] Usage: /em-35kv-corridor [radius 8..32] (default 24).")
        return
    end
    local result,err=M.collect(player,radius)
    if not result then
        player.print("[EM 0.1.17] No selected/nearby custom ВСМ rail; no preview.")
        return
    end
    local clear,blocked=M.check(result)
    local nearest, nearest_distance=nil,math.huge
    for i,mark in ipairs(result.markers) do
        local color=mark.status=="CLEAR" and {r=0.1,g=0.95,b=0.35,a=0.95}
            or mark.status=="BLOCKED" and {r=1,g=0.25,b=0.15,a=0.95}
            or {r=0.95,g=0.3,b=0.95,a=0.95}
        rendering.draw_circle{
            surface=result.start.surface,target=mark.position,
            radius=0.23,width=2.5,color=color,
            filled=false,draw_on_ground=true,
            time_to_live=TTL,players={player}}
        if mark.status=="CLEAR" then
            local d=dist2(mark.position,player.position)
            if d<nearest_distance then
                nearest,nearest_distance=i,d
            end
        end
    end
    if nearest then
        local mark=result.markers[nearest]
        rendering.draw_circle{
            surface=result.start.surface,target=mark.position,
            radius=0.38,width=3,color={r=0.1,g=0.8,b=1,a=0.95},
            filled=false,draw_on_ground=true,
            time_to_live=TTL,players={player}}
        player.print(string.format("[EM 0.1.17] Nearest clear native slot (%.3f, %.3f), rail=%s; candidate only.",
            mark.position.x,mark.position.y,mark.rail_name))
    end
    local message=string.format(
        "[EM 0.1.17] rails=%d native_slots=%d clear=%d blocked=%d duplicates=%d non_ground=%d api_errors=%d capped=%s radius=%.1f. NO entities created.",
        result.rails,#result.markers,clear,blocked,result.duplicates,
        result.skipped_layer,result.api_errors,tostring(result.capped),radius)
    player.print(message)
    log("[ElectrifiedMainline][0.1.17][corridor] "..message)
end

return M
