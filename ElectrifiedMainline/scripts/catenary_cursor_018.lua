-- 0.1.18: Factorio-owned electric-pole placement at engine-derived HSR slots.
-- No rail signal proxies. No entity create/destroy, refunds or Undo injection.
local M={}
local rail_slots=require("scripts.rail_slot_debug_014")
local POLE="em-35kv-catenary-pole"
local RAILS={
    "em-high-speed-straight-rail","em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b","em-half-diagonal-high-speed-rail"
}
local PREVIEW_RADIUS=12
local CLICK_RADIUS=1.25
local MAX_RAILS=96
local MAX_POINTS=160

local function dist2(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy
end

function M.holding_mast(player)
    local stack=player.cursor_stack
    return stack and stack.valid_for_read and stack.name==POLE or false
end

-- Signal slots are an engine reference for nearby rails. The actual mast is
-- a 1x1 electric-pole and is placed on its OWN native half-tile build grid.
-- Never claim an arbitrary signal position is a legal electric-pole center.
local function pole_grid_point(p)
    return {x=math.floor(p.x)+0.5,y=math.floor(p.y)+0.5}
end

-- No 16-tile spacing filter: EVERY near-by distinct available pole grid cell
-- derived from the native rail signal locations is a candidate.
function M.collect(surface,force,center,radius)
    local rails=surface.find_entities_filtered{
        position=center,radius=radius+5,name=RAILS,force=force
    }
    table.sort(rails,function(a,b)
        local da,db=dist2(a.position,center),dist2(b.position,center)
        if da~=db then return da<db end
        return (a.unit_number or 0)<(b.unit_number or 0)
    end)
    local by_key, list = {},{}
    for i=1,math.min(#rails,MAX_RAILS) do
        local rail=rails[i]
        if rail.valid then
            local slots=rail_slots.collect(rail)
            for _,slot in ipairs(slots) do
                if slot.rail_layer==defines.rail_layer.ground then
                    local p=pole_grid_point(slot.position)
                    if dist2(p,center)<=radius*radius then
                        local key=tostring(p.x)..":"..tostring(p.y)
                        local record=by_key[key]
                        local rail_distance=dist2(p,rail.position)
                        if not record then
                            record={position=p,rail_position={
                                x=rail.position.x,y=rail.position.y},
                                rail_name=rail.name,rail_distance=rail_distance,
                                source={x=slot.position.x,y=slot.position.y}}
                            by_key[key]=record
                            list[#list+1]=record
                        elseif rail_distance<record.rail_distance then
                            record.rail_position={x=rail.position.x,y=rail.position.y}
                            record.rail_name=rail.name
                            record.rail_distance=rail_distance
                        end
                    end
                end
            end
        end
    end
    table.sort(list,function(a,b)
        local da,db=dist2(a.position,center),dist2(b.position,center)
        if da~=db then return da<db end
        if a.position.x~=b.position.x then return a.position.x<b.position.x end
        return a.position.y<b.position.y
    end)
    local results={}
    for i=1,math.min(#list,MAX_POINTS) do results[i]=list[i] end
    return results
end

-- The engine, not our collision approximation, is the final authority.
-- Even collision-clear squares can be unavailable due to build reach, items,
-- enemy force rules or player controller state.
function M.classify(player,point)
    local ok,allowed=pcall(function()
        return player.can_build_from_cursor{position=point.position}
    end)
    if not ok then return "ERROR" end
    if allowed then return "READY" end
    local collision_ok,collision_free=pcall(function()
        return player.surface.can_place_entity{
            name=POLE,position=point.position,
            direction=defines.direction.north,force=player.force
        }
    end)
    if collision_ok and collision_free then return "OUT_OF_REACH" end
    return "BLOCKED"
end

local COLORS={
    READY={r=0.10,g=1,b=0.38},
    BLOCKED={r=1,g=0.20,b=0.19},
    OUT_OF_REACH={r=1,g=0.73,b=0.18},
    ERROR={r=1,g=0.25,b=1}
}

function M.show_held(player)
    if not M.holding_mast(player) then return 0 end
    local candidates=M.collect(player.surface,player.force,
        player.position,PREVIEW_RADIUS)
    for _,point in ipairs(candidates) do
        local color=COLORS[M.classify(player,point)]
        local x,y=point.position.x,point.position.y
        -- Subtle ground tiles, styled after signal availability cells.
        rendering.draw_rectangle{
            surface=player.surface,left_top={x=x-0.33,y=y-0.33},
            right_bottom={x=x+0.33,y=y+0.33},
            color={r=color.r,g=color.g,b=color.b,a=0.16},
            filled=true,draw_on_ground=true,
            time_to_live=17,players={player}
        }
        rendering.draw_rectangle{
            surface=player.surface,left_top={x=x-0.33,y=y-0.33},
            right_bottom={x=x+0.33,y=y+0.33},
            color={r=color.r,g=color.g,b=color.b,a=0.85},
            width=1.8,draw_on_ground=true,
            time_to_live=17,players={player}
        }
    end
    return #candidates
end

function M.refresh_all()
    for _,player in pairs(game.connected_players) do
        if player.valid and M.holding_mast(player) then
            M.show_held(player)
        end
    end
end

function M.on_place(event)
    local player=event.player_index and game.get_player(event.player_index)
    if not (player and player.valid and M.holding_mast(player)) then return end
    if not event.cursor_position then return end
    local candidates=M.collect(player.surface,player.force,
        event.cursor_position,CLICK_RADIUS)
    local candidate=candidates[1]
    if not candidate then
        player.print("[EM 0.1.18] No ВСМ native rail location near cursor (Alt+LMB).")
        return
    end
    local status=M.classify(player,candidate)
    if status~="READY" then
        player.print("[EM 0.1.18] Mast position unavailable: "..status)
        return
    end
    -- This is the REAL item and the official player build API.
    -- Native engine owns the actual build, stack consumption and events.
    -- Undo records MUST be checked in Factorio; never fabricate them here.
    log(string.format(
        "[ElectrifiedMainline][0.1.18][place] request player=%d cursor=(%.3f,%.3f) base=(%.3f,%.3f) source_rail=%s tick=%d",
        event.player_index,event.cursor_position.x,event.cursor_position.y,
        candidate.position.x,candidate.position.y,candidate.rail_name,game.tick
    ))
    player.build_from_cursor{position=candidate.position}
end

return M
