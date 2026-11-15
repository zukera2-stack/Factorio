-- 0.1.15 non-mutating visualization of candidate 35 kV mast bases.
-- A rail signal location is a REFERENCE, not the overhead wire contact point.
local M = {}
local slots = require("scripts.rail_slot_debug_014")
local view = require("scripts.overhead_geometry_012")
local POLE, TTL = "em-35kv-catenary-pole", 900 -- 15 s at 60 UPS

function M.parse_offset(param)
    if param == nil or param:match("^%s*$") then return 1 end
    local n = tonumber(param)
    if not n or n ~= n or n < 0.5 or n > 3 then return nil end
    return n
end

function M.candidates(rail, offset)
    local locations, errors = slots.collect(rail)
    local candidates, skipped = {}, 0
    for index, slot in ipairs(locations) do
        if slot.rail_layer == defines.rail_layer.ground then
            -- Factorio direction: 0 north, 4 east, 8 south, 12 west.
            -- Both normals are shown: slot direction alone cannot choose
            -- which track side provides safe placement, particularly on curves.
            local angle = (slot.direction % 16) * math.pi / 8
            local nx, ny = math.cos(angle), math.sin(angle)
            for _,side in ipairs({{name="L",sign=-1},{name="R",sign=1}}) do
                local base = {x=slot.position.x+side.sign*offset*nx,
                    y=slot.position.y+side.sign*offset*ny}
                candidates[#candidates+1] = {
                    slot_number=index, slot_label=slot.label, side=side.name,
                    base=base, reference={x=slot.position.x,y=slot.position.y},
                    face=view.face(base, slot.position)
                }
            end
        else
            skipped=skipped+1
        end
    end
    return candidates,errors,#locations,skipped
end

function M.show(player, command)
    local offset = M.parse_offset(command and command.parameter)
    if not offset then
        player.print("[EM 0.1.15] Usage: /em-35kv-preview [0.5..3] (tiles, default 1).")
        return
    end
    local rail = slots.nearest_rail(player)
    if not rail then
        player.print("[EM 0.1.15] No selected or nearby custom ВСМ rail (10 tiles); no preview.")
        return
    end
    local candidates,errors,count,skipped=M.candidates(rail,offset)
    player.print(string.format("[EM 0.1.15] %s: %d signal slots, %d mast candidates at %.2f tiles, %d non-ground slots skipped; 15s preview ONLY.",
        rail.name,count,#candidates,offset,skipped))
    for _,err in ipairs(errors) do player.print("[EM 0.1.15] Slot API: "..err) end
    local clear,blocked,failed=0,0,0
    for _,c in ipairs(candidates) do
        -- Collision clearance is not HSR-only placement eligibility.
        local ok,free=pcall(function()
            return rail.surface.can_place_entity{
                name=POLE,position=c.base,
                direction=defines.direction.north,force=rail.force
            }
        end)
        local status,color
        if not ok then
            failed=failed+1;status="API_ERR"
            color={r=0.95,g=0.35,b=0.9,a=0.95}
            player.print("[EM 0.1.15] can_place_entity error: "..tostring(free))
        elseif free then
            clear=clear+1;status="CLEAR"
            color={r=0.15,g=0.9,b=0.3,a=0.95}
        else
            blocked=blocked+1;status="BLOCKED"
            color={r=1,g=0.2,b=0.15,a=0.95}
        end
        rendering.draw_circle{
            surface=rail.surface,target=c.base,radius=0.30,width=3,
            color=color,filled=false,time_to_live=TTL,
            draw_on_ground=true,players={player}
        }
        rendering.draw_line{
            surface=rail.surface,from=c.base,to=c.reference,
            color=color,width=2,time_to_live=TTL,
            draw_on_ground=true,players={player}
        }
        rendering.draw_text{
            surface=rail.surface,target={x=c.base.x,y=c.base.y-0.48},
            text=string.format("%d%s %s %s",c.slot_number,c.side,c.face,status),
            color=color,scale=0.75,alignment="center",
            time_to_live=TTL,players={player}
        }
        player.print(string.format("  slot=%d%s (%s) mast=(%.3f,%.3f) face=%s collision=%s",
            c.slot_number,c.side,c.slot_label,c.base.x,c.base.y,c.face,status))
    end
    if #candidates==0 then player.print("[EM 0.1.15] No ground-layer candidates.") end
    log(string.format("[ElectrifiedMainline][0.1.15][preview] rail=%s offset=%.2f slots=%d candidates=%d clear=%d blocked=%d api_error=%d",
        rail.name,offset,count,#candidates,clear,blocked,failed))
end
return M
