-- 0.1.16: read-only rail-end-based catenary geometry experiment.
-- Uses the rail END as its track reference; never changes entities or Undo.
local M={}
local rail_slots=require("scripts.rail_slot_debug_014")
local view=require("scripts.overhead_geometry_012")
local POLE="em-35kv-catenary-pole"
local DEFAULT_OFFSET=1.5
local TTL=900 -- 15s at 60 UPS
local MAX_CANDIDATES=4
local DEDUP_DISTANCE2=0.05*0.05

local function distance2(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy
end
function M.parse_options(param)
    if param==nil or param:match("^%s*$") then return DEFAULT_OFFSET,nil end
    local args={}
    for part in param:gmatch("%S+") do args[#args+1]=part end
    if #args<1 or #args>2 then return nil end
    local offset=tonumber(args[1])
    if not offset or offset~=offset or offset<0.5 or offset>3 then return nil end
    local chosen=nil
    if args[2] then
        chosen=tonumber(args[2])
        if not chosen or chosen~=chosen or chosen%1~=0
            or chosen<1 or chosen>MAX_CANDIDATES then return nil end
    end
    return offset,chosen
end

-- RailEnd.location is the engine-defined rail-end point/direction, not a
-- signal location. It may not be a literal overhead wire contact point.
function M.collect(rail,offset)
    local candidates,errors,skipped,duplicates={}, {}, 0, 0
    local ends=0
    for _,side_end in ipairs({
        defines.rail_direction.front,defines.rail_direction.back}) do
        local ok,endpoint=pcall(function() return rail.get_rail_end(side_end) end)
        if not ok or not endpoint then
            errors[#errors+1]="get_rail_end("..tostring(side_end).."): "..tostring(endpoint)
        else
            local loc=endpoint.location
            if not loc or not loc.position or loc.direction==nil then
                errors[#errors+1]="RailEnd.location missing at "..tostring(side_end)
            elseif loc.rail_layer~=defines.rail_layer.ground then
                skipped=skipped+1
            else
                ends=ends+1
                local angle=(loc.direction%16)*math.pi/8
                -- Perpendicular to an end's travel heading in x-east/y-south.
                local nx,ny=math.cos(angle),math.sin(angle)
                for _,side in ipairs({{label="L",sign=-1},{label="R",sign=1}}) do
                    local p={x=loc.position.x+side.sign*offset*nx,
                        y=loc.position.y+side.sign*offset*ny}
                    local duplicate=false
                    for _,existing in ipairs(candidates) do
                        if distance2(existing.position,p)<DEDUP_DISTANCE2 then
                            duplicates=duplicates+1
                            duplicate=true
                            break
                        end
                    end
                    if not duplicate then
                        candidates[#candidates+1]={
                            position=p,
                            reference={x=loc.position.x,y=loc.position.y},
                            rail_end=side_end,side=side.label,face=view.face(p,loc.position)
                        }
                    end
                end
            end
        end
    end
    return candidates,errors,ends,skipped,duplicates
end

-- Only selects an example to DISPLAY, not an authorised place to build.
function M.choose(candidates,requested,player_pos)
    if requested then
        if requested>#candidates then return nil,"Candidate index out of range" end
        return requested
    end
    local best,best_dist=nil,math.huge
    for i,c in ipairs(candidates) do
        if c.collision=="CLEAR" then
            local d=distance2(c.position,player_pos)
            if d<best_dist then best,best_dist=i,d end
        end
    end
    return best -- nil when no clear candidate; do not draw a misleading sprite
end

function M.show(player,command)
    local offset,requested=M.parse_options(command and command.parameter)
    if not offset then
        player.print("[EM 0.1.16] Usage: /em-35kv-geometry [0.5..3] [candidate_index 1..4]")
        return
    end
    local rail=rail_slots.nearest_rail(player)
    if not rail then
        player.print("[EM 0.1.16] No custom ВСМ rail selected/within 10 tiles; no geometry preview.")
        return
    end
    local candidates,errors,ends,skipped,duplicates=M.collect(rail,offset)
    if requested and requested>#candidates then
        player.print("[EM 0.1.16] Candidate "..requested.." not found ("..#candidates.." available).")
        return
    end
    for _,err in ipairs(errors) do player.print("[EM 0.1.16] API: "..err) end
    local clear,blocked,api_errors=0,0,0
    for _,c in ipairs(candidates) do
        -- Check prototype collision only: CLEAR != approved mast location.
        local ok,free=pcall(function()
            return rail.surface.can_place_entity{
                name=POLE,position=c.position,
                direction=defines.direction.north,force=rail.force
            }
        end)
        if not ok then
            c.collision="API_ERR";api_errors=api_errors+1
            player.print("[EM 0.1.16] can_place_entity: "..tostring(free))
        elseif free then
            c.collision="CLEAR";clear=clear+1
        else
            c.collision="BLOCKED";blocked=blocked+1
        end
    end
    local selected=M.choose(candidates,requested,player.position)
    local colors={
        CLEAR={r=0.1,g=0.9,b=0.3,a=0.95},
        BLOCKED={r=1,g=0.2,b=0.15,a=0.95},
        API_ERR={r=0.9,g=0.35,b=0.9,a=0.95}
    }
    player.print(string.format("[EM 0.1.16] %s rail_ends=%d candidates=%d duplicates=%d skipped_non_ground=%d offset=%.2f clear=%d blocked=%d api_error=%d selected=%s",
        rail.name,ends,#candidates,duplicates,skipped,offset,clear,blocked,api_errors,tostring(selected or "none")))
    for i,c in ipairs(candidates) do
        local color=colors[c.collision]
        rendering.draw_circle{
            surface=rail.surface,target=c.position,radius=(i==selected and 0.38 or 0.22),
            width=(i==selected and 4 or 2),color=color,filled=false,
            time_to_live=TTL,draw_on_ground=true,players={player}
        }
        rendering.draw_text{
            surface=rail.surface,
            target={x=c.position.x,y=c.position.y-0.42},
            text=tostring(i)..c.side..(i==selected and "*" or ""),
            color=color,scale=0.72,alignment="center",
            time_to_live=TTL,players={player}
        }
        player.print(string.format("  %d%s end=%s base=(%.3f,%.3f) target=(%.3f,%.3f) face=%s collision=%s",
            i,c.side,tostring(c.rail_end),c.position.x,c.position.y,
            c.reference.x,c.reference.y,c.face,c.collision))
    end
    if selected then
        local c=candidates[selected]
        rendering.draw_line{
            surface=rail.surface,from=c.position,to=c.reference,
            width=2,color={r=0.2,g=0.9,b=1,a=0.95},
            time_to_live=TTL,draw_on_ground=true,players={player}
        }
        if c.collision=="CLEAR" then
            -- Exactly the SpritePrototype already used by power_019, with its
            -- real map offset. Display only ONE translucent full-size mast.
            rendering.draw_sprite{
                sprite="em-35kv-facing-"..c.face,surface=rail.surface,
                target={x=c.position.x,y=c.position.y-2.53125},
                tint={r=0.6,g=0.9,b=1,a=0.40},
                time_to_live=TTL,players={player},render_layer="object"
            }
        else
            player.print("[EM 0.1.16] Selected candidate is blocked; no mast sprite shown.")
        end
    else
        player.print("[EM 0.1.16] No CLEAR candidates; no mast sprite shown.")
    end
    log(string.format("[ElectrifiedMainline][0.1.16][geometry] rail=%s ends=%d candidates=%d duplicate=%d clear=%d blocked=%d api_error=%d selected=%s",
        rail.name,ends,#candidates,duplicates,clear,blocked,api_errors,tostring(selected or "none")))
end
return M
