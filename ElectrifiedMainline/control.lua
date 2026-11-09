-- ElectrifiedMainline/control.lua
-- Runtime scaffolding for Factorio 2.1.
-- Battery consumption and regenerative-energy calculations are intentionally
-- deferred to the energy-model pass; this file only maintains valid train state
-- and tracks which custom rail segments are adjacent to custom electric poles.

local TRAIN_UPDATE_INTERVAL = 30
local RAIL_RADIUS = 3

local RAIL_NAMES = {
    ["em-high-speed-straight-rail"] = true,
    ["em-curved-high-speed-rail"] = true,
    ["em-half-diagonal-high-speed-rail"] = true,
}

local function ensure_storage()
    storage.em = storage.em or {}
    storage.em.electrified_rails = storage.em.electrified_rails or {}
    storage.em.trains = storage.em.trains or {}
end

script.on_init(ensure_storage)
script.on_configuration_changed(ensure_storage)

local function rail_key(surface_index, position)
    return string.format("%d:%.1f:%.1f",
        surface_index, position.x, position.y)
end

local function mark_rail(rail)
    if not (rail and rail.valid and RAIL_NAMES[rail.name]) then return end
    local key = rail_key(rail.surface.index, rail.position)
    storage.em.electrified_rails[key] = true
end

local function unmark_rail(rail)
    if not (rail and rail.valid and RAIL_NAMES[rail.name]) then return end
    local key = rail_key(rail.surface.index, rail.position)
    storage.em.electrified_rails[key] = nil
end

local function mark_rails_near_pole(pole)
    if not (pole and pole.valid and pole.name == "em-electric-pole") then return end

    local p = pole.position
    local area = {
        { p.x - RAIL_RADIUS, p.y - RAIL_RADIUS },
        { p.x + RAIL_RADIUS, p.y + RAIL_RADIUS }
    }
    local rails = pole.surface.find_entities_filtered({
        area = area,
        name = {
            "em-high-speed-straight-rail",
            "em-curved-high-speed-rail",
            "em-half-diagonal-high-speed-rail"
        }
    })

    for _, rail in pairs(rails) do
        mark_rail(rail)
    end
end

local function on_built(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    if RAIL_NAMES[entity.name] then
        mark_rail(entity)
    elseif entity.name == "em-electric-pole" then
        mark_rails_near_pole(entity)
    end
end

local function cleanup_train_for_entity(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    if entity.type == "locomotive" or entity.type == "cargo-wagon"
        or entity.type == "fluid-wagon" then
        local train = entity.train
        if train and train.valid then
            storage.em.trains[train.id] = nil
        end
    end

    if RAIL_NAMES[entity.name] then
        unmark_rail(entity)
    end
end

local function get_custom_locomotives(train)
    local result = {}
    local locomotives = train.locomotives
    if not locomotives then return result end

    for _, loco in pairs(locomotives.front_movers or {}) do
        if loco.valid and loco.name == "em-electric-locomotive" then
            result[#result + 1] = loco
        end
    end

    for _, loco in pairs(locomotives.back_movers or {}) do
        if loco.valid and loco.name == "em-electric-locomotive" then
            result[#result + 1] = loco
        end
    end

    return result
end

-- Diagnostic pass: identify the rail closest to each custom locomotive.
-- This deliberately reports rail identity only; it does not infer that the rail
-- is powered and does not alter train movement or energy.
local function find_rail_under_locomotive(locomotive)
    local train = locomotive.train
    if not (train and train.valid) then return nil end

    local closest_rail = nil
    local best_distance_squared = math.huge

    for _, rail in pairs(train.get_rails()) do
        if rail.valid then
            local dx = rail.position.x - locomotive.position.x
            local dy = rail.position.y - locomotive.position.y
            local distance_squared = dx * dx + dy * dy

            if distance_squared < best_distance_squared then
                closest_rail = rail
                best_distance_squared = distance_squared
            end
        end
    end

    return closest_rail
end

local function update_rail_diagnostics(train, state)
    state.rail_diagnostics = state.rail_diagnostics or {}

    for _, locomotive in pairs(get_custom_locomotives(train)) do
        local locomotive_id = locomotive.unit_number or locomotive.name
        local rail = find_rail_under_locomotive(locomotive)
        local rail_name = rail and rail.name or "<no-rail>"
        local rail_id = rail and rail.unit_number or "nil"

        local previous = state.rail_diagnostics[locomotive_id]
        if not previous or previous.rail_name ~= rail_name or previous.rail_id ~= rail_id then
            local rail_position = rail
                and string.format("(%.2f, %.2f)", rail.position.x, rail.position.y)
                or "n/a"

            log(string.format(
                "[ElectrifiedMainline][rail-debug] train=%s locomotive=%s rail=%s rail_unit=%s rail_position=%s",
                tostring(train.id),
                tostring(locomotive_id),
                tostring(rail_name),
                tostring(rail_id),
                rail_position
            ))

            state.rail_diagnostics[locomotive_id] = {
                rail_name = rail_name,
                rail_id = rail_id
            }
        end
    end
end

local function initialize_train_state(train, previous_state)
    if not (train and train.valid) then return end
    if #get_custom_locomotives(train) == 0 then
        storage.em.trains[train.id] = nil
        return
    end

    storage.em.trains[train.id] = {
        previous_speed = previous_state and previous_state.previous_speed or train.speed
    }
end

local function on_train_created(event)
    local train = event.train
    if not (train and train.valid) then return end

    local previous_state =
        storage.em.trains[event.old_train_id_1]
        or storage.em.trains[event.old_train_id_2]

    -- Old train IDs can disappear after a merge/split. Remove only those that
    -- no longer resolve; a surviving train keeps its own tracking record.
    for _, old_id in pairs({ event.old_train_id_1, event.old_train_id_2 }) do
        if old_id and old_id ~= train.id
            and not game.train_manager.get_train_by_id(old_id) then
            storage.em.trains[old_id] = nil
        end
    end

    initialize_train_state(train, previous_state)
end

local function on_tick(event)
    if event.tick % TRAIN_UPDATE_INTERVAL ~= 0 then return end

    -- Filter at the engine level; do not scan players or every train in the game.
    local trains = game.train_manager.get_trains({
        stock = "em-electric-locomotive"
    })

    for _, train in pairs(trains) do
        if train.valid then
            local state = storage.em.trains[train.id]
            if not state then
                initialize_train_state(train)
                state = storage.em.trains[train.id]
            end

            if state then
                -- Diagnostic only: determine the rail under each custom locomotive.
                update_rail_diagnostics(train, state)

                -- Used by the later battery/regen implementation. No energy is
                -- added or consumed in this foundational pass.
                state.previous_speed = train.speed
            end
        end
    end
end

-- One registration per event. Factorio replaces a previous callback when the
-- same event is registered again; handlers are therefore consolidated here.
local built_events = {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
}
for _, event_id in pairs(built_events) do
    script.on_event(event_id, on_built)
end

local cleanup_events = {
    defines.events.on_entity_died,
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.script_raised_destroy
}
for _, event_id in pairs(cleanup_events) do
    script.on_event(event_id, cleanup_train_for_entity)
end

script.on_event(defines.events.on_train_created, on_train_created)
script.on_event(defines.events.on_tick, on_tick)
