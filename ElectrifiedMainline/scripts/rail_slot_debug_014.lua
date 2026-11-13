-- 0.1.14 read-only rail-signal slot diagnostic. Never creates rail signals or moves poles.
local M = {}
local RAILS = {
    ["em-high-speed-straight-rail"] = true,
    ["em-curved-high-speed-rail"] = true,
    ["em-curved-high-speed-rail-b"] = true,
    ["em-half-diagonal-high-speed-rail"] = true,
}
local RAIL_NAMES = {
    "em-high-speed-straight-rail", "em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b", "em-half-diagonal-high-speed-rail"
}
local MAX_RADIUS = 10
local TTL = 900 -- 15 seconds at 60 UPS
local function square_distance(a,b)
    local dx,dy=a.x-b.x,a.y-b.y
    return dx*dx+dy*dy
end
function M.nearest_rail(player)
    local selected=player.selected
    if selected and selected.valid and RAILS[selected.name] then return selected end
    local best, distance=nil,MAX_RADIUS*MAX_RADIUS
    for _,rail in pairs(player.surface.find_entities_filtered{
        position=player.position,radius=MAX_RADIUS,name=RAIL_NAMES,force=player.force
    }) do
        if rail.valid then
            local d=square_distance(rail.position,player.position)
            if d<distance or (d==distance and best and
                (rail.unit_number or 0)<(best.unit_number or 0)) then
                best,distance=rail,d
            end
        end
    end
    return best
end
local function key_for(loc)
    return string.format('%.4f:%.4f:%s:%s',loc.position.x,loc.position.y,
        tostring(loc.direction),tostring(loc.rail_layer))
end
function M.collect(rail)
    local slots,seen,failures={},{},{}
    for _,direction in ipairs({defines.rail_direction.front,defines.rail_direction.back}) do
        local ok,rail_end=pcall(function() return rail.get_rail_end(direction) end)
        if not ok or not rail_end then
            failures[#failures+1]='get_rail_end('..tostring(direction)..'): '..tostring(rail_end)
        else
            for _,entry in ipairs({
                {'out',rail_end.out_signal_location},
                {'in',rail_end.in_signal_location},
                {'alternative_out',rail_end.alternative_out_signal_location},
                {'alternative_in',rail_end.alternative_in_signal_location},
            }) do
                local loc=entry[2]
                if loc and loc.position and loc.direction~=nil then
                    local k=key_for(loc)
                    if not seen[k] then
                        seen[k]=true
                        slots[#slots+1]={label=entry[1],rail_end=direction,
                            position={x=loc.position.x,y=loc.position.y},
                            direction=loc.direction,rail_layer=loc.rail_layer}
                    end
                end
            end
        end
    end
    table.sort(slots,function(a,b)
        if a.position.x~=b.position.x then return a.position.x<b.position.x end
        if a.position.y~=b.position.y then return a.position.y<b.position.y end
        if a.direction~=b.direction then return a.direction<b.direction end
        return a.label<b.label
    end)
    return slots,failures
end
function M.show(player)
    local rail=M.nearest_rail(player)
    if not rail then
        player.print('[EM 0.1.14] No ВСМ rail selected or within 10 tiles. Point at a ВСМ rail and run /em-35kv-slots.')
        return
    end
    local slots,errors=M.collect(rail)
    player.print(string.format('[EM 0.1.14] %s direction=%s at (%.2f, %.2f): %d unique engine signal slots (15s)',
        rail.name,tostring(rail.direction),rail.position.x,rail.position.y,#slots))
    for i,slot in ipairs(slots) do
        local color=(slot.label=='out' or slot.label=='alternative_out')
            and {r=0.15,g=0.9,b=0.3,a=0.95} or {r=0.95,g=0.7,b=0.1,a=0.95}
        rendering.draw_circle{surface=rail.surface,target=slot.position,
            radius=0.22,width=3,color=color,filled=false,time_to_live=TTL,
            draw_on_ground=true,players={player}}
        rendering.draw_text{surface=rail.surface,target={x=slot.position.x,y=slot.position.y-0.45},
            text=tostring(i)..':'..slot.label..' d'..tostring(slot.direction),
            color=color,scale=0.85,time_to_live=TTL,players={player},
            alignment='center'}
        player.print(string.format('  %d %s end=%s pos=(%.3f,%.3f) dir=%s layer=%s',
            i,slot.label,tostring(slot.rail_end),slot.position.x,slot.position.y,
            tostring(slot.direction),tostring(slot.rail_layer)))
    end
    for _,err in ipairs(errors) do player.print('[EM 0.1.14] API: '..err) end
    if #slots==0 then player.print('[EM 0.1.14] No slot locations returned; check Factorio log.') end
    log('[ElectrifiedMainline][0.1.14][slots] '..rail.name..' '..#slots..' unique slots, '..#errors..' API errors')
end
return M