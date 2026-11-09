-- ElectrifiedMainline/control.lua
-- High-speed electric railway for Factorio 2.1.20 with Space Age expansion.
--
-- API notes (2.1):
-- - No electric-pole entity exists in base data — simplified electrical network
-- - Train power is battery-based (void energy source)
-- - Regenerative braking via on_tick event

-- ------------------------------------------------------------
-- Global state
-- ------------------------------------------------------------
-- Note: global variables are initialized in script.on_init below.
-- This section is just for documentation.

-- ------------------------------------------------------------
-- Event: On init - initialize global state
-- ------------------------------------------------------------
script.on_init(function()
    global.em_locomotive_battery = {}  -- Battery charge per locomotive
    global.em_electrified_high_speed_rails = {}  -- Track electrified high-speed rail segments
end)

-- ------------------------------------------------------------
-- Helper: Check if position is adjacent to high-speed rail
-- ------------------------------------------------------------
local function is_adjacent_to_high_speed_rail(position, radius)
    radius = radius or 1.5
    local min_x = math.floor(position.x - radius)
    local max_x = math.ceil(position.x + radius)
    local min_y = math.floor(position.y - radius)
    local max_y = math.ceil(position.y + radius)

    for x = min_x, max_x do
        for y = min_y, max_y do
            local entity = game.get_entity_at({x = x, y = y})
            if entity and entity.valid then
                local etype = entity.type
                -- Check high-speed rail variants (our mod's rails)
                if etype == "em-high-speed-rail" or etype == "em-curved-high-speed-rail" or
                    etype == "em-half-diagonal-high-speed-rail" then
                    return true, entity
                end
            end
        end
    end
    return false, nil
end

-- ------------------------------------------------------------
-- Helper: Get rail segment key from position
-- ------------------------------------------------------------
local function rail_segment_key(position)
    return tostring(math.floor(position.x)) .. "," .. tostring(math.floor(position.y))
end

-- ------------------------------------------------------------
-- Helper: Check if position is on electrified rail segment
-- ------------------------------------------------------------
local function is_on_electrified_high_speed_rail(position)
    local key = rail_segment_key(position)
    if global.em_electrified_high_speed_rails and global.em_electrified_high_speed_rails[key] then
        return true
    end
    -- Check adjacent tiles too (rails span multiple tiles)
    for dx = -1, 1 do
        for dy = -1, 1 do
            local adj_key = tostring(math.floor(position.x) + dx) .. "," .. tostring(math.floor(position.y) + dy)
            if global.em_electrified_high_speed_rails and global.em_electrified_high_speed_rails[adj_key] then
                return true
            end
        end
    end
    return false
end

-- ------------------------------------------------------------
-- Helper: Mark high-speed rails as electrified around a pole
-- Note: In 2.1, poles are visual only — they don't actually power trains.
-- This is kept for mod compatibility with mods that use upgraded rails.
-- ------------------------------------------------------------
local function mark_rails_as_electrified_around_pole(pole)
    local position = pole.position
    local radius = 3  -- Mark rails within 3 tiles of the pole

    for dx = -radius, radius do
        for dy = -radius, radius do
            local check_pos = {x = position.x + dx, y = position.y + dy}
            local adjacent, rail_entity = is_adjacent_to_high_speed_rail(check_pos, 1.0)
            if adjacent and rail_entity then
                local key = rail_segment_key(rail_entity.position)
                global.em_electrified_high_speed_rails[key] = {
                    pole = pole.unit_number,
                    position = rail_entity.position,
                    electrified = true,
                }
            end
        end
    end
end

-- ------------------------------------------------------------
-- Event: On electric pole placement (mark rails as electrified)
-- Note: This is for compatibility with mods that use upgraded rails.
-- In pure 2.1 base, poles are visual only.
-- ------------------------------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
    local entity = game.get_entity_at({x = event.position.x, y = event.position.y})
    if not entity or not entity.valid then return end

    -- Check if this is an electric pole (our mod's visual marker)
    if entity.name == "em-electric-pole" then
        mark_rails_as_electrified_around_pole(entity)
    end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    local entity = game.get_entity_at({x = event.position.x, y = event.position.y})
    if not entity or not entity.valid then return end

    -- Check if this is an electric pole (our mod's visual marker)
    if entity.name == "em-electric-pole" then
        mark_rails_as_electrified_around_pole(entity)
    end
end)

-- ------------------------------------------------------------
-- Event: On high-speed rail placement (mark as electrified immediately)
-- This ensures high-speed rails are always treated as electrified.
-- ------------------------------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
    local entity = game.get_entity_at({x = event.position.x, y = event.position.y})
    if not entity or not entity.valid then return end

    -- Mark high-speed rails as electrified when placed
    if entity.type == "straight-rail" and entity.name == "em-high-speed-straight-rail" then
        local key = rail_segment_key(entity.position)
        global.em_electrified_high_speed_rails[key] = {
            position = entity.position,
            electrified = true,
        }
    elseif entity.type == "curved-rail" and entity.name == "em-curved-high-speed-rail" then
        local key = rail_segment_key(entity.position)
        global.em_electrified_high_speed_rails[key] = {
            position = entity.position,
            electrified = true,
        }
    elseif entity.type == "half-diagonal-rail" and entity.name == "em-half-diagonal-high-speed-rail" then
        local key = rail_segment_key(entity.position)
        global.em_electrified_high_speed_rails[key] = {
            position = entity.position,
            electrified = true,
        }
    end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    local entity = game.get_entity_at({x = event.position.x, y = event.position.y})
    if not entity or not entity.valid then return end

    -- Mark high-speed rails as electrified when placed by robot
    if entity.type == "straight-rail" and entity.name == "em-high-speed-straight-rail" then
        local key = rail_segment_key(entity.position)
        global.em_electrified_high_speed_rails[key] = {
            position = entity.position,
            electrified = true,
        }
    elseif entity.type == "curved-rail" and entity.name == "em-curved-high-speed-rail" then
        local key = rail_segment_key(entity.position)
        global.em_electrified_high_speed_rails[key] = {
            position = entity.position,
            electrified = true,
        }
    elseif entity.type == "half-diagonal-rail" and entity.name == "em-half-diagonal-high-speed-rail" then
        local key = rail_segment_key(entity.position)
        global.em_electrified_high_speed_rails[key] = {
            position = entity.position,
            electrified = true,
        }
    end
end)

-- ------------------------------------------------------------
-- Event: On high-speed rail deconstruction (remove electrification marker)
-- ------------------------------------------------------------
script.on_event(defines.events.on_entity_died, function(event)
    if event.entity and event.entity.valid then
        local entity_type = event.entity.type
        -- Check for high-speed rails being destroyed
        if entity_type == "straight-rail" or entity_type == "curved-rail" or entity_type == "half-diagonal-rail" then
            if global.em_electrified_high_speed_rails then
                local key = rail_segment_key(event.entity.position)
                global.em_electrified_high_speed_rails[key] = nil
            end
        end
    end
end)

-- ------------------------------------------------------------
-- Event: Tick-based train battery management and regenerative braking
-- ------------------------------------------------------------
script.on_event(defines.events.on_tick, function(event)
    if event.tick % update_interval ~= 0 then return end

    -- Process all trains
    for _, player in pairs(game.players) do
        for _, train in pairs(player.trains) do
            if not train or not train.valid then goto continue end

            -- Check each locomotive in the train
            local locomotives = train.locomotives
            if not locomotives then goto continue end

            for _, loco in pairs(locomotives) do
                if not loco or not loco.valid then goto continue end

                -- Only process our electric locomotive
                if loco.name ~= "em-electric-locomotive" then goto continue end

                local train_id = train.unit_number
                local position = loco.position

                -- Initialize battery state if needed
                if not global.em_locomotive_battery[train_id] then
                    global.em_locomotive_battery[train_id] = {
                        charge = 600000000000,  -- 600 MJ in Joules
                        max_charge = 600000000000,
                        on_electrified = true,  -- High-speed rails are always electrified
                    }
                end

                local battery = global.em_locomotive_battery[train_id]

                -- Check if train is on high-speed rail (always electrified)
                local on_electrified = true  -- Simplified: high-speed rails are always electrified

                -- Get current train state
                -- FIX: In Factorio 2.1, use train.speed directly
                local current_speed = train.speed
                local prev_speed = train.previous_speed or current_speed

                    -- Charging on electrified section (small trickle charge)
                    if on_electrified then
                        battery.charge = math.min(
                            battery.charge + 1000000,  -- 1 MJ per update interval
                            battery.max_charge
                        )
                        battery.on_electrified = true
                    else
                        -- Discharging battery (power usage proportional to speed)
                        local power_draw = current_speed * 5000000  -- 5 MJ per tile at speed 1.0
                        battery.charge = math.max(battery.charge - power_draw, 0)
                        battery.on_electrified = false
                    end

                    -- Regenerative braking detection
                    if current_speed < prev_speed and current_speed > 0.01 then
                        -- Train is decelerating (regenerative braking)
                        local speed_diff = prev_speed - current_speed
                        local regen_amount = speed_diff * 2000000  -- 2 MJ per speed unit diff
                        battery.charge = math.min(
                            battery.charge + regen_amount,
                            battery.max_charge
                        )
                    end
                end

                ::continue::
            end
        end
    end
end)

-- ------------------------------------------------------------
-- Event: Train created/changed - initialize battery
-- ------------------------------------------------------------
script.on_event(defines.events.on_train_created, function(event)
    if event.train and event.train.valid then
        -- Initialize battery for new trains with electric locomotive
        if global.em_locomotive_battery[event.train.unit_number] then return end

        global.em_locomotive_battery[event.train.unit_number] = {
            charge = 600000000000,
            max_charge = 600000000000,
            on_electrified = true,
        }
    end
end)

-- ------------------------------------------------------------
-- Event: Train removed - cleanup battery state
-- ------------------------------------------------------------
script.on_event(defines.events.on_train_destroyed, function(event)
    if event.train and event.train.valid then
        local train_id = event.train.unit_number
        if global.em_locomotive_battery[train_id] then
            global.em_locomotive_battery[train_id] = nil
        end
    end
end)

-- ------------------------------------------------------------
-- Event: Train destroyed - cleanup battery state
-- ------------------------------------------------------------
script.on_event(defines.events.on_entity_died, function(event)
    if event.entity and event.entity.valid then
        local entity_type = event.entity.type
        -- Check for trains being destroyed
        if entity_type == "locomotive" or entity_type == "cargo-wagon" or entity_type == "fluid-wagon" or entity_type == "infinity-cargo-wagon" then
            if global.em_locomotive_battery[event.entity.unit_number] then
                global.em_locomotive_battery[event.entity.unit_number] = nil
            end
        end
    end
end)
