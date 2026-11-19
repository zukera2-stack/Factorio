-- 0.1.23: visual ONLY overlay for ghosts of the catenary electric-pole.
-- 0.1.24: Factorio draws the common native steel shaft and its own ghost
-- shader; Lua only adds an orientation-specific tinted C cantilever.
-- LuaRendering is anchored to the ghost: the engine removes it on ghost death
-- or robot revival. No collision, build permissions, ghost manipulation or Undo.
local M={}
local power=require("scripts.power_019")
local mast034=require("scripts.mast_visual_034")
local art=require("scripts.catenary_art_030")
local POLE="em-35kv-catenary-pole"
local NORTH="em-35kv-catenary-pole-north"
local POLES={POLE,NORTH}
local function is_pole(name) return name==POLE or name==NORTH end
local TINT={r=0.53,g=0.84,b=1,a=0.64}

local function is_our_ghost(entity)
    return entity and entity.valid and entity.name=="entity-ghost"
        and is_pole(entity.ghost_name)
end
local function state()
    storage.em=storage.em or {}
    local s=storage.em.ghost_visual_023
    if not s then
        s={sprites={}}
        storage.em.ghost_visual_023=s
    end
    s.sprites=s.sprites or {};s.spans=s.spans or {}
    return s.sprites,s.spans,s
end
local function key(entity)
    local p=entity.position
    return string.format("%d:%s:%.3f:%.3f",
        entity.surface.index,entity.force.name,p.x,p.y).."#"..entity.ghost_name
end
local function clear_id(id)
    if not id then return end
    local object=rendering.get_object_by_id(id)
    if object and object.valid then object.destroy() end
end

function M.on_built(entity)
    if not is_our_ghost(entity) then return false end
    local sprites,spans=state()
    local k=key(entity)
    local old=sprites[k]
    if old then
        local obj=rendering.get_object_by_id(old)
        if obj and obj.valid then return true end
        sprites[k]=nil
    end
    art.clear_preview(spans[k]);spans[k]=nil
    -- Same RailEnd-based facing selection as real poles; no entity rotation.
    local node,predicted,preview_nodes=power.preview_at(entity)
    if node and ((node.axis_status and node.axis_status~="attached") or
        (not node.axis_status and not node.rail_adjacent)) then return false end
    local face=node and node.face or power.facing_at(entity)
    local obj=rendering.draw_sprite{
        sprite="em-35kv-facing-"..face,
        surface=entity.surface,
        target={entity=entity,offset={0,mast034.cantilever_shift(entity.ghost_name)}},
        tint=TINT,
        render_layer="higher-object-above",
    }
    sprites[k]=obj.id
    spans[k]={}
    if preview_nodes and predicted and #predicted>0 then
        for _,span in ipairs(predicted) do
                for _,rid in ipairs(art.preview_span(entity.surface,entity.force,span.a,span.b,span.corner)) do
                    spans[k][#spans[k]+1]=rid
                end
        end
    end
    return true
end

function M.on_removed(entity)
    if not is_our_ghost(entity) then return false end
    local sprites,spans=state()
    local k=key(entity)
    art.clear_preview(spans[k]);spans[k]=nil
    clear_id(sprites[k])
    sprites[k]=nil
    return true
end

function M.rebuild_all()
    local sprites,spans,s=state()
    for _,id in pairs(sprites) do clear_id(id) end
    for _,ids in pairs(spans) do art.clear_preview(ids) end
    s.sprites={};s.spans={};s.dirty=false
    local count=0
    for _,surface in pairs(game.surfaces) do
        for _,pole_name in pairs(POLES) do
            for _,entity in pairs(surface.find_entities_filtered{
                name="entity-ghost",ghost_name=pole_name}) do
                if M.on_built(entity) then count=count+1 end
            end
        end
    end
    log("[ElectrifiedMainline][ghost023] restored "..count.." visible catenary ghosts")
end

-- Ghost render objects self-destruct with their entity. Prune old ID keys
-- occasionally so large blueprint/undo sessions do not grow storage forever.
function M.mark_dirty() local _,_,s=state();s.dirty=true end
function M.on_tick(tick)
    local sprites,spans,s=state()
    if s.dirty and tick%30==0 then M.rebuild_all();return end
    if tick%60~=0 then return end
    for k,id in pairs(sprites) do
        local obj=rendering.get_object_by_id(id)
        if not (obj and obj.valid) then sprites[k]=nil;art.clear_preview(spans[k]);spans[k]=nil end
    end
end

return M
