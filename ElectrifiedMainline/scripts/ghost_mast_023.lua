-- 0.1.23: visual ONLY overlay for ghosts of the catenary electric-pole.
-- 0.1.24: Factorio draws the common native steel shaft and its own ghost
-- shader; Lua only adds an orientation-specific tinted C cantilever.
-- LuaRendering is anchored to the ghost: the engine removes it on ghost death
-- or robot revival. No collision, build permissions, ghost manipulation or Undo.
local M={}
local power=require("scripts.power_019")
local POLE="em-35kv-catenary-pole"
local OFFSET={0,-2.53125}
local TINT={r=0.53,g=0.84,b=1,a=0.64}

local function is_our_ghost(entity)
    return entity and entity.valid and entity.name=="entity-ghost"
        and entity.ghost_name==POLE
end
local function state()
    storage.em=storage.em or {}
    local s=storage.em.ghost_visual_023
    if not s then
        s={sprites={}}
        storage.em.ghost_visual_023=s
    end
    s.sprites=s.sprites or {}
    return s.sprites
end
local function key(entity)
    local p=entity.position
    return string.format("%d:%s:%.3f:%.3f",
        entity.surface.index,entity.force.name,p.x,p.y)
end
local function clear_id(id)
    if not id then return end
    local object=rendering.get_object_by_id(id)
    if object and object.valid then object.destroy() end
end

function M.on_built(entity)
    if not is_our_ghost(entity) then return false end
    local sprites=state()
    local k=key(entity)
    local old=sprites[k]
    if old then
        local obj=rendering.get_object_by_id(old)
        if obj and obj.valid then return true end
        sprites[k]=nil
    end
    -- Same RailEnd-based facing selection as real poles; no entity rotation.
    local face=power.facing_at(entity)
    local obj=rendering.draw_sprite{
        sprite="em-35kv-facing-"..face,
        surface=entity.surface,
        target={entity=entity,offset=OFFSET},
        tint=TINT,
        render_layer="higher-object-above",
    }
    sprites[k]=obj.id
    return true
end

function M.on_removed(entity)
    if not is_our_ghost(entity) then return false end
    local sprites=state()
    local k=key(entity)
    clear_id(sprites[k])
    sprites[k]=nil
    return true
end

function M.rebuild_all()
    local sprites=state()
    for _,id in pairs(sprites) do clear_id(id) end
    storage.em.ghost_visual_023.sprites={}
    local count=0
    for _,surface in pairs(game.surfaces) do
        for _,entity in pairs(surface.find_entities_filtered{
            name="entity-ghost",ghost_name=POLE}) do
            if M.on_built(entity) then count=count+1 end
        end
    end
    log("[ElectrifiedMainline][ghost023] restored "..count.." visible catenary ghosts")
end

-- Ghost render objects self-destruct with their entity. Prune old ID keys
-- occasionally so large blueprint/undo sessions do not grow storage forever.
function M.on_tick(tick)
    if tick%1800~=0 then return end
    local sprites=state()
    for k,id in pairs(sprites) do
        local obj=rendering.get_object_by_id(id)
        if not (obj and obj.valid) then sprites[k]=nil end
    end
end

return M
