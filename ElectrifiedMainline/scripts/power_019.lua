-- Nonconducting visual 35kV graph, prototype 0.1.9.
-- No energy is produced, removed or transferred in this module.
-- No LuaObjects are saved in storage.
local M = {}
local POLE, SUB = "em-35kv-catenary-pole", "em-35kv-traction-substation"
local SPAN, RAIL_RADIUS = 16, 3
local RAILS = {
    "em-high-speed-straight-rail", "em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b", "em-half-diagonal-high-speed-rail",
}

function M.ensure_storage()
    storage.em = storage.em or {}
    storage.em.power_019 = storage.em.power_019 or {version = 1, nodes = {}, edges = {}}
    local power = storage.em.power_019
    power.nodes = power.nodes or {}
    power.edges = power.edges or {}
    return power
end

local function near_rail(entity)
    return entity.surface.count_entities_filtered{
        position = entity.position, radius = RAIL_RADIUS, name = RAILS,
        force = entity.force, limit = 1,
    } > 0
end

local function key(a, b)
    if a > b then a, b = b, a end
    return tostring(a) .. ":" .. tostring(b)
end

local function kill_render(id)
    if not id then return end
    local render = rendering.get_object_by_id(id)
    if render and render.valid then render.destroy() end
end

local function link(power, a, b)
    local id_a, id_b = a.unit_number, b.unit_number
    if not (id_a and id_b) or id_a == id_b then return end
    local k = key(id_a, id_b)
    if power.edges[k] then return end
    local x, y = power.nodes[id_a], power.nodes[id_b]
    if not (x and y) or x.force_name ~= y.force_name
       or x.surface_index ~= y.surface_index then return end
    if (x.name == POLE and not x.rail_adjacent)
       or (y.name == POLE and not y.rail_adjacent) then return end
    local dx, dy = a.position.x - b.position.x, a.position.y - b.position.y
    if dx*dx + dy*dy > SPAN*SPAN then return end

    -- Script rendering is deliberately NOT Factorio copper wire.
    local contact = rendering.draw_line{
        surface = a.surface,
        from = {entity = a, offset = {0, -0.5}},
        to = {entity = b, offset = {0, -0.5}},
        color = {r = 0.95, g = 0.7, b = 0.2, a = 0.95},
        width = 2,
    }
    local messenger = rendering.draw_line{
        surface = a.surface,
        from = {entity = a, offset = {0, -0.75}},
        to = {entity = b, offset = {0, -0.75}},
        color = {r = 0.5, g = 0.6, b = 0.85, a = 0.7},
        width = 1,
    }
    power.edges[k] = {
        a = id_a, b = id_b,
        contact_render = contact.id,
        messenger_render = messenger.id,
    }
end

function M.on_built(event)
    local entity = event.entity
    if not (entity and entity.valid and (entity.name == POLE or entity.name == SUB)) then return end
    local id = entity.unit_number
    if not id then
        log("[ElectrifiedMainline][35kv] missing unit_number for " .. entity.name)
        return
    end
    local power = M.ensure_storage()
    local is_near = entity.name ~= POLE or near_rail(entity)
    power.nodes[id] = {
        name = entity.name, surface_index = entity.surface.index,
        force_name = entity.force.name,
        position = {x = entity.position.x, y = entity.position.y},
        rail_adjacent = is_near,
    }
    if entity.name == POLE and not is_near then
        local player = event.player_index and game.get_player(event.player_index)
        if player and player.valid then player.print({"message.em-35kv-no-rail"}) end
        return
    end
    local others = entity.surface.find_entities_filtered{
        position = entity.position, radius = SPAN,
        name = {POLE, SUB}, force = entity.force,
    }
    for _, candidate in pairs(others) do
        if candidate.valid and candidate.unit_number ~= id then
            link(power, entity, candidate)
        end
    end
end

function M.on_removed(event)
    local entity = event.entity
    if not (entity and entity.valid and (entity.name == POLE or entity.name == SUB)) then return end
    local id = entity.unit_number
    if not id then return end
    local power = M.ensure_storage()
    power.nodes[id] = nil
    local removed = {}
    for k, edge in pairs(power.edges) do
        if edge.a == id or edge.b == id then removed[#removed + 1] = k end
    end
    for _, k in ipairs(removed) do
        local edge = power.edges[k]
        kill_render(edge.contact_render)
        kill_render(edge.messenger_render)
        power.edges[k] = nil
    end
end

function M.status(player)
    local power = M.ensure_storage()
    local nodes, spans, missing = 0, 0, 0
    for id, node in pairs(power.nodes) do
        nodes = nodes + 1
        local entity = game.get_entity_by_unit_number(id)
        if not (entity and entity.valid and entity.name == node.name) then
            missing = missing + 1
        end
    end
    for _ in pairs(power.edges) do spans = spans + 1 end
    player.print("[ElectrifiedMainline][35kv] nodes=" .. nodes
        .. " spans=" .. spans .. " missing=" .. missing
        .. " energized=NO transfer_MW=0 (early prototype)")
end

return M
