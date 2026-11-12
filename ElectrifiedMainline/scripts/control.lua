-- ElectrifiedMainline/control.lua
-- Runtime scaffolding for Factorio 2.1.
-- Battery consumption and regenerative-energy calculations are intentionally
-- deferred to the energy-model pass; this file only maintains valid train state
-- and tracks which custom rail segments are adjacent to custom electric poles.

local TRAIN_UPDATE_INTERVAL = 30
local RAIL_DIAGNOSTIC_INTERVAL = 1 -- temporary: catch rail transitions during testing
local RAIL_RADIUS = 3

local RAIL_NAMES = {
    ["em-high-speed-straight-rail"] = true,
    ["em-curved-high-speed-rail"] = true,
    ["em-curved-high-speed-rail-b"] = true,
    ["em-half-diagonal-high-speed-rail"] = true,
}

-- Intercept only the four explicit vanilla -> ВСМ geometry mappings. Factorio's
-- native robot upgrade operation does not safely replace rail entities.
local VANILLA_TO_CUSTOM_RAILS = {
    ["straight-rail"] = "em-high-speed-straight-rail",
    ["curved-rail-a"] = "em-curved-high-speed-rail",
    ["curved-rail-b"] = "em-curved-high-speed-rail-b",
    ["half-diagonal-rail"] = "em-half-diagonal-high-speed-rail",
}

local STORAGE_VERSION = 1

local function ensure_storage()
    storage.em = storage.em or {}

    -- Additive migration for saves created before rail replacement support.
    local version = storage.em.schema_version or 0
    if version < STORAGE_VERSION then
        storage.em.pending_rail_replacements =
            storage.em.pending_rail_replacements or {}
        storage.em.schema_version = STORAGE_VERSION
    end

    storage.em.electrified_rails = storage.em.electrified_rails or {}
    storage.em.trains = storage.em.trains or {}
    storage.em.pending_rail_replacements =
        storage.em.pending_rail_replacements or {}
    storage.em.blueprint_undo_join = storage.em.blueprint_undo_join or {last_build = {}, marks = {}}
    storage.em.blueprint_undo_join.last_build = storage.em.blueprint_undo_join.last_build or {}
    storage.em.blueprint_undo_join.marks = storage.em.blueprint_undo_join.marks or {}
end

script.on_init(ensure_storage)
script.on_configuration_changed(ensure_storage)

-- Temporary diagnostics for blueprint rail replacement and undo/redo.
-- These handlers observe events only; they do not change replacement behavior.
local function diag_value(value)
    if value == nil then return "nil" end
    return tostring(value)
end

local function diag_position(position)
    if not position then return "nil" end
    return string.format("(%.3f,%.3f)", position.x or position[1] or 0, position.y or position[2] or 0)
end

local function diag_entity(event_name, event, entity)
    entity = entity or (event and (event.entity or event.ghost))
    local player_index = event and event.player_index or nil
    local entity_name = "<none>"
    local entity_type = "<none>"
    local ghost_name = "nil"
    local position = "nil"
    local direction = "nil"
    local surface_index = "nil"
    local force_name = "nil"
    local quality_name = "nil"

    if entity then
        entity_name = diag_value(entity.name)
        entity_type = diag_value(entity.type)
        position = diag_position(entity.position)
        direction = diag_value(entity.direction)
        if entity.surface then surface_index = diag_value(entity.surface.index) end
        if entity.force then force_name = diag_value(entity.force.name) end
        if entity.quality then quality_name = diag_value(entity.quality.name) end
        if entity.type == "entity-ghost" then
            ghost_name = diag_value(entity.ghost_name)
        end
    end

    log(string.format(
        "[ElectrifiedMainline][em-rail-diag] event=%s tick=%s player=%s entity=%s type=%s ghost_name=%s surface=%s position=%s direction=%s force=%s quality=%s build_mode=%s",
        event_name, tostring(game.tick), diag_value(player_index), entity_name,
        entity_type, ghost_name, surface_index, position, direction, force_name,
        quality_name, diag_value(event and event.build_mode)
    ))
end

local function diag_undo_actions(event_name, event)
    log(string.format(
        "[ElectrifiedMainline][em-rail-diag] event=%s tick=%s player=%s action_count=%s",
        event_name, tostring(game.tick), diag_value(event and event.player_index),
        tostring(event and event.actions and #event.actions or 0)
    ))

    for index, action in pairs((event and event.actions) or {}) do
        local target = action.target
        local target_name = target and target.name or nil
        local target_position = target and target.position or nil
        local target_direction = target and target.direction or nil
        local target_quality = target and target.quality or nil
        local target_quality_name = type(target_quality) == "table"
            and target_quality.name or target_quality
        log(string.format(
            "[ElectrifiedMainline][em-rail-diag] %s_action=%s type=%s target_name=%s target_position=%s target_direction=%s target_quality=%s surface_index=%s original_name=%s original_quality=%s",
            event_name, tostring(index), diag_value(action.type),
            diag_value(target_name), diag_position(target_position),
            diag_value(target_direction), diag_value(target_quality_name),
            diag_value(action.surface_index), diag_value(action.original_name),
            diag_value(action.original_quality_name)
        ))
    end
end

local function on_diag_pre_build(event)
    ensure_storage()
    if event.player_index then
        storage.em.blueprint_undo_join.last_build[event.player_index] = {tick = game.tick, blueprint_super_force = event.build_mode == 2}
    end
    log(string.format(
        "[ElectrifiedMainline][em-rail-diag] event=on_pre_build tick=%s player=%s position=%s direction=%s build_mode=%s flip_horizontal=%s flip_vertical=%s",
        tostring(game.tick), diag_value(event.player_index),
        diag_position(event.position), diag_value(event.direction),
        diag_value(event.build_mode), diag_value(event.flip_horizontal),
        diag_value(event.flip_vertical)
    ))
end

local function on_diag_marked_for_deconstruction(event)
    diag_entity("on_marked_for_deconstruction", event, event.entity)
    local entity = event.entity
    if not (entity and entity.valid and entity.name == "straight-rail" and event.player_index) then return end
    ensure_storage()
    local state = storage.em.blueprint_undo_join
    local last = state.last_build[event.player_index]
    if not (last and last.blueprint_super_force and last.tick == game.tick) then return end
    local key = string.format("%d:%s:%.3f:%.3f:%d",
        entity.surface.index, entity.name, entity.position.x, entity.position.y, entity.direction)
    state.marks[key] = {
        player_index = event.player_index, surface_index = entity.surface.index,
        force_name = entity.force.name, position = {x = entity.position.x, y = entity.position.y},
        direction = entity.direction, target_name = "em-high-speed-straight-rail",
        marked_tick = game.tick, mined = false, retry_tick = 0
    }
    log("[ElectrifiedMainline][em-undo-join] marked key=" .. key .. " player=" .. event.player_index)
end

local function on_diag_pre_ghost_deconstructed(event)
    diag_entity("on_pre_ghost_deconstructed", event, event.ghost)
end

local function on_diag_undo(event)
    diag_undo_actions("on_undo_applied", event)
end

local function on_diag_redo(event)
    diag_undo_actions("on_redo_applied", event)
end

local function rail_key(surface_index, position)
    return string.format("%d:%.1f:%.1f",
        surface_index, position.x, position.y)
end

local function replacement_key(entity)
    return string.format("%d:%s:%.3f:%.3f:%d",
        entity.surface.index,
        entity.name,
        entity.position.x,
        entity.position.y,
        entity.direction)
end

local function queue_rail_replacement(entity, force, player, cancel_upgrade)
    local expected_target = VANILLA_TO_CUSTOM_RAILS[entity.name]
    if not expected_target then return false end

    local key = replacement_key(entity)

    -- Persist primitive values only; LuaObjects must not be stored.
    -- Quality belongs to the rail entity, not to the planner item used by the player.
    storage.em.pending_rail_replacements[key] = {
        target_name = expected_target,
        surface_index = entity.surface.index,
        position = { x = entity.position.x, y = entity.position.y },
        direction = entity.direction,
        force_name = force.name,
        quality_name = (entity.quality and entity.quality.name) or nil,
        mined = false,
        retry_tick = 0,
    }

    if cancel_upgrade and not entity.cancel_upgrade(force, player) then
        storage.em.pending_rail_replacements[key] = nil
        return false
    end

    if not entity.order_deconstruction(force, player) then
        storage.em.pending_rail_replacements[key] = nil
        log("[ElectrifiedMainline] Could not order rail deconstruction for " .. entity.name)
        if player and player.valid then
            player.print("Electrified Mainline: could not schedule this rail for replacement.")
        end
        return false
    end

    return true
end

-- 0.1.7: do not cancel native rail upgrades. The engine handles construction
-- robot replacement and its native Undo/Redo record, as for assembling machines.
-- The dedicated rail replacement selection tool remains a separate fallback.
local function on_marked_for_upgrade(event)
    local entity = event.entity
    local target = event.target
    if not (entity and entity.valid and target) then return end
    if VANILLA_TO_CUSTOM_RAILS[entity.name] ~= target.name then return end

    log("[ElectrifiedMainline][native-upgrade] ordered source=" .. entity.name
        .. " target=" .. target.name
        .. " tick=" .. tostring(game.tick)
        .. " player=" .. tostring(event.player_index))
end

local function on_player_selected_area(event)
    if event.item ~= "em-rail-replacement-planner" then return end

    ensure_storage()
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end

    local queued = 0
    for _, entity in pairs(event.entities or {}) do
        if entity and entity.valid and VANILLA_TO_CUSTOM_RAILS[entity.name] then
            if queue_rail_replacement(entity, entity.force, player, false) then
                queued = queued + 1
            end
        end
    end

    if queued > 0 then
        player.print({"message.em-rail-replacement-marked", queued})
        log("[ElectrifiedMainline] Custom rail replacement planner queued "
            .. tostring(queued) .. " vanilla rail entities.")
    else
        player.print({"message.em-rail-replacement-none"})
    end
end

local function try_create_replacement_ghost(key, pending)
    local surface = game.surfaces[pending.surface_index]
    local force = game.forces[pending.force_name]
    if not (surface and force) then
        log("[ElectrifiedMainline] Rail replacement lost its surface or force: " .. key)
        return false
    end

    local ghost_spec = {
        name = "entity-ghost",
        inner_name = pending.target_name,
        position = pending.position,
        direction = pending.direction,
        force = force,
        expires = false,
    }
    if pending.quality_name then
        ghost_spec.quality = pending.quality_name
    end

    local ghost = surface.create_entity(ghost_spec)
    if not (ghost and ghost.valid) then
        return false
    end

    storage.em.pending_rail_replacements[key] = nil
    return true
end

local function process_mined_rail_replacement(event, entity)
    if event.name ~= defines.events.on_robot_mined_entity
        and event.name ~= defines.events.on_player_mined_entity then
        return
    end

    local expected_target = VANILLA_TO_CUSTOM_RAILS[entity.name]
    if not expected_target then return end

    local key = replacement_key(entity)
    if event.name == defines.events.on_robot_mined_entity then
        local join = storage.em.blueprint_undo_join.marks[key]
        if join and not join.mined then
            join.mined = true
            join.retry_tick = game.tick + 1
            log("[ElectrifiedMainline][em-undo-join] mined key=" .. key .. " tick=" .. game.tick)
        end
    end
    local pending = storage.em.pending_rail_replacements[key]
    if not pending or pending.target_name ~= expected_target then return end

    -- The mined-entity event fires just before the old entity is destroyed.
    -- Defer ghost creation until the following tick to avoid overlap.
    pending.mined = true
    pending.retry_tick = game.tick + 1
end

local function process_pending_rail_ghosts(tick)
    for key, pending in pairs(storage.em.pending_rail_replacements) do
        if pending.mined and tick >= (pending.retry_tick or 0) then
            pending.retry_tick = tick + 60
            try_create_replacement_ghost(key, pending)
        end
    end
end

-- Experimental: attach existing blueprint ghosts to native Undo; straight rails only.
local function process_blueprint_undo_joins(tick)
    local state = storage.em.blueprint_undo_join
    for key, pending in pairs(state.marks) do
        if tick - pending.marked_tick > 3600 then
            state.marks[key] = nil
        elseif pending.mined and tick >= pending.retry_tick then
            local surface = game.surfaces[pending.surface_index]
            local player = game.get_player(pending.player_index)
            if not (surface and player and player.valid and player.force.name == pending.force_name) then
                state.marks[key] = nil
            else
                local matched
                for _, ghost in pairs(surface.find_entities_filtered{position = pending.position, name = "entity-ghost"}) do
                    if ghost.valid and ghost.ghost_name == pending.target_name
                        and ghost.direction == pending.direction
                        and ghost.force.name == pending.force_name then
                        matched = ghost
                        break
                    end
                end
                if matched then
                    local pos = {x = matched.position.x, y = matched.position.y}
                    local direction = matched.direction
                    local quality = matched.quality and matched.quality.name or nil
                    matched.destroy()
                    local spec = {
                        name = "entity-ghost", inner_name = pending.target_name,
                        position = pos, direction = direction, force = player.force,
                        player = player, undo_index = 1, expires = false
                    }
                    if quality then spec.quality = quality end
                    local ok, new_ghost = pcall(function() return surface.create_entity(spec) end)
                    if not (ok and new_ghost and new_ghost.valid) then
                        spec.player = nil
                        spec.undo_index = nil
                        local restored_ok, restored = pcall(function() return surface.create_entity(spec) end)
                        log("[ElectrifiedMainline][em-undo-join] ERROR rejoin key=" .. key
                            .. " error=" .. tostring(new_ghost) .. " restored="
                            .. tostring(restored_ok and restored and restored.valid or false))
                    else
                        log("[ElectrifiedMainline][em-undo-join] joined key=" .. key
                            .. " tick=" .. tick .. " player=" .. pending.player_index
                            .. " undo_index=1")
                    end
                    state.marks[key] = nil
                elseif tick > pending.retry_tick + 300 then
                    log("[ElectrifiedMainline][em-undo-join] missing_blueprint_ghost key=" .. key)
                    state.marks[key] = nil
                end
            end
        end
    end
end

local function on_cancelled_deconstruction(event)
    ensure_storage()
    diag_entity("on_cancelled_deconstruction", event, event.entity)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    storage.em.pending_rail_replacements[replacement_key(entity)] = nil
    storage.em.blueprint_undo_join.marks[replacement_key(entity)] = nil
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
            "em-curved-high-speed-rail-b",
            "em-half-diagonal-high-speed-rail"
        }
    })

    for _, rail in pairs(rails) do
        mark_rail(rail)
    end
end

local function on_built(event)
    ensure_storage()
    local entity = event.entity
    diag_entity(event.name == defines.events.on_robot_built_entity and "on_robot_built_entity"
        or event.name == defines.events.script_raised_revive and "script_raised_revive"
        or event.name == defines.events.script_raised_built and "script_raised_built"
        or "on_built_entity", event, entity)
    if not (entity and entity.valid) then return end

    if RAIL_NAMES[entity.name] then
        mark_rail(entity)
    elseif entity.name == "em-electric-pole" then
        mark_rails_near_pole(entity)
    end
end

local function cleanup_train_for_entity(event)
    ensure_storage()
    local entity = event.entity
    local diag_name = event.name == defines.events.on_robot_mined_entity and "on_robot_mined_entity"
        or event.name == defines.events.on_player_mined_entity and "on_player_mined_entity"
        or event.name == defines.events.on_entity_died and "on_entity_died"
        or "script_raised_destroy"
    diag_entity(diag_name, event, entity)
    if not (entity and entity.valid) then return end

    if event.name == defines.events.on_robot_mined_entity
        or event.name == defines.events.on_player_mined_entity then
        process_mined_rail_replacement(event, entity)
    elseif event.name == defines.events.on_entity_died
        or event.name == defines.events.script_raised_destroy then
        storage.em.pending_rail_replacements[replacement_key(entity)] = nil
    end

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
    ensure_storage()
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
    -- Saves made before the replacement queue existed may not run
    -- on_configuration_changed when only runtime code changed. Initialize
    -- persistent state lazily before any tick handler reads it.
    ensure_storage()
    local update_speed = event.tick % TRAIN_UPDATE_INTERVAL == 0
    local update_rails = event.tick % RAIL_DIAGNOSTIC_INTERVAL == 0
    if not update_speed and not update_rails then return end

    process_blueprint_undo_joins(event.tick)
    local pending_replacements = storage.em.pending_rail_replacements
    if pending_replacements and next(pending_replacements) then
        process_pending_rail_ghosts(event.tick)
    end

    -- Filter at the engine level; do not scan players or every train in the game.
    -- Rail diagnostics are temporary and run every tick to avoid skipping short
    -- rail segments at high train speed.
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
                if update_rails then
                    -- Diagnostic only: determine the rail under each custom locomotive.
                    update_rail_diagnostics(train, state)
                end

                -- Used by the later battery/regen implementation. No energy is
                -- added or consumed in this foundational pass.
                if update_speed then
                    state.previous_speed = train.speed
                end
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

script.on_event(defines.events.on_marked_for_upgrade, on_marked_for_upgrade)
script.on_event(defines.events.on_pre_build, on_diag_pre_build)
script.on_event(defines.events.on_marked_for_deconstruction, on_diag_marked_for_deconstruction)
script.on_event(defines.events.on_pre_ghost_deconstructed, on_diag_pre_ghost_deconstructed)
script.on_event(defines.events.on_undo_applied, on_diag_undo)
script.on_event(defines.events.on_redo_applied, on_diag_redo)
script.on_event(defines.events.on_player_selected_area, on_player_selected_area)
script.on_event(defines.events.on_cancelled_deconstruction, on_cancelled_deconstruction)
script.on_event(defines.events.on_train_created, on_train_created)
script.on_event(defines.events.on_tick, on_tick)
