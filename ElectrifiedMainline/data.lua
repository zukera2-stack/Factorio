-- ElectrifiedMainline/data.lua
-- High-speed electric railway infrastructure for Factorio 2.1.20 with Space Age expansion.
--
-- API verification notes (2.1.20):
-- - Locomotives use energy_source :: BurnerEnergySource or VoidEnergySource
-- - Rail types are separate: straight-rail, curved-rail, half-diagonal-rail
-- - No electric-pole entity exists in 2.1 base data — poles are visual only.
-- - Train regenerative braking implemented via runtime events (on_tick)

data:extend({
    {
        type = "item",
        name = "em-concrete-beam",
        icon = "__base__/graphics/icons/concrete.png",
        icon_size = 64,
        subgroup = "intermediate-product",
        order = "a[raw-materials]-a[concrete-beam]",
        stack_size = 200,
        weight = 35,
    },
    {
        type = "item",
        name = "em-heavy-copper-cable",
        icon = "__base__/graphics/icons/copper-cable.png",
        icon_size = 64,
        subgroup = "intermediate-product",
        order = "a[raw-materials]-b[heavy-copper-cable]",
        stack_size = 200,
        weight = 28,
    },
    {
        type = "item",
        name = "em-traction-motor",
        icon = "__base__/graphics/icons/electric-engine-unit.png",
        icon_size = 64,
        subgroup = "intermediate-product",
        order = "a[raw-materials]-c[traction-motor]",
        stack_size = 50,
        weight = 20,
    },
    {
        type = "item",
        name = "em-battery-bank",
        icon = "__base__/graphics/icons/battery.png",
        icon_size = 64,
        subgroup = "intermediate-product",
        order = "a[raw-materials]-d[battery-bank]",
        stack_size = 50,
        weight = 12,
    },
})

data:extend({
    {
        type = "technology",
        name = "em-electrified-railways",
        icon = "__base__/graphics/icons/steel-plate.png",
        icon_size = 64,
        order = "a[electric-rails]",
        effects = {
            { type = "unlock-recipe", recipe = "em-concrete-beam" },
            { type = "unlock-recipe", recipe = "em-heavy-copper-cable" },
            { type = "unlock-recipe", recipe = "em-electric-pole" },
            { type = "unlock-recipe", recipe = "em-high-speed-straight-rail" },
            { type = "unlock-recipe", recipe = "em-high-speed-curved-rail" },
            { type = "unlock-recipe", recipe = "em-high-speed-half-diagonal-rail" },
        },
        prerequisites = { "electric-engine", "logistics-2", "steel-processing" },
        unit = { count = 500, time = 60, ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 } } },
    },

    {
        type = "technology",
        name = "em-high-speed-locomotive",
        icon = "__base__/graphics/icons/locomotive.png",
        icon_size = 64,
        order = "b[high-speed-locomotive]",
        effects = {
            { type = "unlock-recipe", recipe = "em-traction-motor" },
            { type = "unlock-recipe", recipe = "em-battery-bank" },
            { type = "unlock-recipe", recipe = "em-electric-locomotive" },
            { type = "unlock-recipe", recipe = "em-high-speed-cargo-wagon" },
            { type = "unlock-recipe", recipe = "em-high-speed-fluid-wagon" },
        },
        prerequisites = { "em-electrified-railways", "production-science-pack" },
        unit = { count = 2000, time = 60, ingredients = { { "automation-science-pack", 2 }, { "production-science-pack", 1 }, { "chemical-science-pack", 1 } } },
    },

    {
        type = "technology",
        name = "em-regenerative-braking",
        icon = "__base__/graphics/icons/battery.png",
        icon_size = 64,
        order = "c[regenerative-braking]",
        effects = {
            { type = "unlock-recipe", recipe = "em-regenerative-brake-unit" },
        },
        prerequisites = { "em-high-speed-locomotive", "automation-3" },
        -- TechnologyUnitDefinition.ingredients must contain science-pack items.
        -- Batteries are ordinary ingredients, not research packs, and cannot be
        -- supplied by labs. Use valid science packs for this research.
        unit = { count = 3000, time = 90, ingredients = { { "automation-science-pack", 3 }, { "logistic-science-pack", 2 } } },
    },

    {
        type = "technology",
        name = "em-high-speed-rails",
        icon = "__base__/graphics/icons/rail.png",
        icon_size = 64,
        order = "d[high-speed-rails]",
        effects = {
            { type = "unlock-recipe", recipe = "em-high-speed-straight-rail" },
            { type = "unlock-recipe", recipe = "em-high-speed-curved-rail" },
            { type = "unlock-recipe", recipe = "em-high-speed-half-diagonal-rail" },
        },
        prerequisites = { "em-electrified-railways", "logistics-3" },
        unit = { count = 3500, time = 120, ingredients = { { "automation-science-pack", 4 }, { "production-science-pack", 2 } } },
    },
})

data:extend({
    {
        type = "item",
        name = "em-electric-pole",
        icon = "__base__/graphics/icons/steel-chest.png",
        icon_size = 64,
        subgroup = "energy",
        order = "a[electric-pole]-e[electric-pole]",
        stack_size = 100,
        weight = 5
    },

    {
        type = "recipe",
        name = "em-electric-pole",
        enabled = false,
        ingredients = { { "em-concrete-beam", 2 }, { "em-heavy-copper-cable", 3 }, { "steel-plate", 5 } },
        results = {{ type = "item", name = "em-electric-pole", amount = 1 }},
        energy_required = 10,
        categories = { "crafting" },
    },
})

data:extend({
    {
        type = "item",
        name = "em-high-speed-rail",
        icon = "__base__/graphics/icons/rail.png",
        icon_size = 64,
        subgroup = "raw-material",
        order = "a[ground-rail]-f[high-speed-straight]",
        stack_size = 50,
        weight = 18,
    },
    {
        type = "item",
        name = "em-curved-high-speed-rail",
        icon = "__base__/graphics/icons/curved-rail.png",
        icon_size = 64,
        subgroup = "raw-material",
        order = "a[ground-rail]-f[high-speed-curved]",
        stack_size = 10,
        weight = 35,
    },
    {
        type = "item",
        name = "em-half-diagonal-high-speed-rail",
        icon = "__base__/graphics/icons/half-diagonal-rail.png",
        icon_size = 64,
        subgroup = "raw-material",
        order = "a[ground-rail]-f[high-speed-half-diagonal]",
        stack_size = 20,
        weight = 31,
    },

    {
        type = "straight-rail",
        name = "em-high-speed-straight-rail",
        icon = "__base__/graphics/icons/rail.png",
        icon_size = 64,
        flags = { "placeable-neutral", "player-creation", "building-direction-8-way" },
        minable = { mining_time = 0.2, result = "em-high-speed-rail" },
        max_health = 250,
        corpse = "straight-rail-remnants",
        dying_explosion = "rail-explosion",
        resistances = {{ type = "fire", percent = 100 }, { type = "acid", percent = 80 }},
        selection_box = {{ -1.7, -0.8 }, { 1.7, 0.8 }},
        damaged_trigger_effect = nil,
        pictures = data.raw["straight-rail"]["straight-rail"].pictures,
        placeable_by = { item = "em-high-speed-rail", count = 1 },
        walking_sound = data.raw["straight-rail"]["straight-rail"].walking_sound,
    },

    {
        type = "curved-rail-a",
        name = "em-curved-high-speed-rail",
        icon = "__base__/graphics/icons/curved-rail.png",
        icon_size = 64,
        flags = { "placeable-neutral", "player-creation", "building-direction-8-way" },
        minable = { mining_time = 0.2, result = "em-curved-high-speed-rail", count = 4 },
        max_health = 250,
        corpse = "curved-rail-a-remnants",
        dying_explosion = {{ name = "rail-explosion" }},
        resistances = {{ type = "fire", percent = 100 }, { type = "acid", percent = 80 }},
        selection_box = {{ -1.7, -0.8 }, { 1.7, 0.8 }},
        damaged_trigger_effect = nil,
        pictures = data.raw["curved-rail-a"]["curved-rail-a"].pictures,
        ending_shifts = data.raw["curved-rail-a"]["curved-rail-a"].ending_shifts,
        placeable_by = { item = "em-curved-high-speed-rail", count = 4 },
        walking_sound = data.raw["curved-rail-a"]["curved-rail-a"].walking_sound,
    },

    {
        type = "half-diagonal-rail",
        name = "em-half-diagonal-high-speed-rail",
        icon = "__base__/graphics/icons/half-diagonal-rail.png",
        icon_size = 64,
        flags = { "placeable-neutral", "player-creation", "building-direction-8-way" },
        minable = { mining_time = 0.2, result = "em-half-diagonal-high-speed-rail", count = 2 },
        max_health = 250,
        corpse = "half-diagonal-rail-remnants",
        dying_explosion = {{ name = "rail-explosion", offset = { 0.9, 2.2 } }},
        resistances = {{ type = "fire", percent = 100 }, { type = "acid", percent = 80 }},
        selection_box = {{ -1.7, -0.8 }, { 1.7, 0.8 }},
        damaged_trigger_effect = nil,
        pictures = data.raw["half-diagonal-rail"]["half-diagonal-rail"].pictures,
        placeable_by = { item = "em-half-diagonal-high-speed-rail", count = 2 },
        walking_sound = data.raw["half-diagonal-rail"]["half-diagonal-rail"].walking_sound,
    },
})

data:extend({
    {
        type = "locomotive",
        name = "em-electric-locomotive",
        icon = "__base__/graphics/icons/locomotive.png",
        icon_size = 64,
        subgroup = "train-transport",
        order = "c[locomotive]-e[electric-mainline]",
        max_health = 500,
        weight = 2000,
        corpse = "diesel-locomotive-remnants",
        dying_explosion = "diesel-locomotive-explosion",
        collision_box = {{ -1.2, -2.2 }, { 1.2, 2.2 }},
        selection_box = {{ -1.5, -2.5 }, { 1.5, 2.5 }},
        resistances = {{ type = "physical", decrease = 80, percent = 80 }, { type = "fire", decrease = 50, percent = 50 }},
        energy_source = { type = "void" },
        max_power = "600kW",
        max_speed = 1.5,
        reversing_power_modifier = 0.6,
        braking_force = 10,
        friction_force = 0.50,
        energy_per_hit_point = 5,
        pictures = data.raw["locomotive"]["locomotive"].pictures,
        wheels = data.raw["locomotive"]["locomotive"].wheels,
        front_light_pictures = data.raw["locomotive"]["locomotive"].front_light_pictures,
    },

    {
        type = "item",
        name = "em-electric-locomotive",
        icon = "__base__/graphics/icons/locomotive.png",
        icon_size = 64,
        subgroup = "train-transport",
        order = "c[locomotive]-e[electric-mainline]",
        stack_size = 10,
        weight = 18,
    },

    {
        type = "recipe",
        name = "em-electric-locomotive",
        enabled = false,
        ingredients = { { "steel-plate", 50 }, { "em-traction-motor", 5 }, { "em-battery-bank", 3 } },
        results = {{ type = "item", name = "em-electric-locomotive", amount = 1 }},
        energy_required = 100,
        categories = { "crafting" },
    },

    {
        type = "item",
        name = "em-high-speed-cargo-wagon",
        icon = "__base__/graphics/icons/cargo-wagon.png",
        icon_size = 64,
        subgroup = "train-transport",
        order = "c[wagon]-f[high-speed-cargo]",
        stack_size = 10,
        weight = 25,
    },

    {
        type = "item",
        name = "em-high-speed-fluid-wagon",
        icon = "__base__/graphics/icons/fluid-wagon.png",
        icon_size = 64,
        subgroup = "train-transport",
        order = "c[wagon]-f[high-speed-fluid]",
        stack_size = 10,
        weight = 25,
    },

    {
        type = "recipe",
        name = "em-high-speed-cargo-wagon",
        enabled = false,
        ingredients = { { "steel-plate", 30 }, { "copper-cable", 50 }, { "em-heavy-copper-cable", 10 } },
        results = {{ type = "item", name = "em-high-speed-cargo-wagon", amount = 1 }},
        energy_required = 10,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-high-speed-fluid-wagon",
        enabled = false,
        ingredients = { { "steel-plate", 30 }, { "copper-cable", 50 }, { "em-heavy-copper-cable", 10 } },
        results = {{ type = "item", name = "em-high-speed-fluid-wagon", amount = 1 }},
        energy_required = 10,
        categories = { "crafting" },
    },
})

data:extend({
    {
        type = "recipe",
        name = "em-concrete-beam",
        enabled = false,
        ingredients = { { "stone-brick", 2 }, { "steel-plate", 4 }, { "iron-pipe", 1 } },
        results = {{ type = "item", name = "em-concrete-beam", amount = 1 }},
        energy_required = 5,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-heavy-copper-cable",
        enabled = false,
        ingredients = { { "copper-cable", 3 }, { "plastic-bar", 1 } },
        results = {{ type = "item", name = "em-heavy-copper-cable", amount = 1 }},
        energy_required = 2,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-traction-motor",
        enabled = false,
        ingredients = { { "copper-cable", 10 }, { "steel-gear-wheel", 5 }, { "advanced-circuit", 2 } },
        results = {{ type = "item", name = "em-traction-motor", amount = 1 }},
        energy_required = 10,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-battery-bank",
        enabled = false,
        ingredients = { { "battery", 10 }, { "steel-plate", 5 } },
        results = {{ type = "item", name = "em-battery-bank", amount = 1 }},
        energy_required = 8,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-regenerative-brake-unit",
        enabled = false,
        ingredients = { { "copper-plate", 5 }, { "advanced-circuit", 2 } },
        results = {{ type = "item", name = "em-regenerative-brake-unit", amount = 1 }},
        energy_required = 3,
        categories = { "crafting" },
    },

    -- High-speed rail recipes
    {
        type = "recipe",
        name = "em-high-speed-straight-rail",
        enabled = false,
        ingredients = { { "steel-plate", 2 }, { "copper-cable", 2 } },
        results = {{ type = "item", name = "em-high-speed-rail", amount = 4 }},
        energy_required = 0.5,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-high-speed-curved-rail",
        enabled = false,
        ingredients = { { "steel-plate", 4 }, { "copper-cable", 4 } },
        results = {{ type = "item", name = "em-curved-high-speed-rail", amount = 1 }},
        energy_required = 1,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-high-speed-half-diagonal-rail",
        enabled = false,
        ingredients = { { "steel-plate", 3 }, { "copper-cable", 3 } },
        results = {{ type = "item", name = "em-half-diagonal-high-speed-rail", amount = 1 }},
        energy_required = 0.75,
        categories = { "crafting" },
    },
})

-- ---------------------------------------------------------------------------
-- Complete the placeable entities using the matching vanilla prototypes.
-- Cloning preserves version-specific mandatory fields and graphics.
-- ---------------------------------------------------------------------------

local function clone_placeable_entity(source_type, source_name, target_name, item_name, place_count, mined_count)
    local source = data.raw[source_type] and data.raw[source_type][source_name]
    assert(source, "ElectrifiedMainline: missing base prototype " .. source_type .. "/" .. source_name)

    local prototype = table.deepcopy(source)
    prototype.name = target_name
    prototype.minable = { mining_time = 0.2, result = item_name, count = mined_count or 1 }
    prototype.placeable_by = { item = item_name, count = place_count or 1 }
    prototype.next_upgrade = nil
    data.raw[source_type][target_name] = prototype

    local item = data.raw.item[item_name]
    assert(item, "ElectrifiedMainline: missing item prototype " .. item_name)
    item.place_result = target_name
end

-- Replace the hand-built rail prototypes with complete copies of the matching
-- vanilla prototypes. This avoids silently omitting required fields as the API evolves.
clone_placeable_entity("straight-rail", "straight-rail",
    "em-high-speed-straight-rail", "em-high-speed-rail", 1, 1)
clone_placeable_entity("curved-rail-a", "curved-rail-a",
    "em-curved-high-speed-rail", "em-curved-high-speed-rail", 4, 4)
clone_placeable_entity("half-diagonal-rail", "half-diagonal-rail",
    "em-half-diagonal-high-speed-rail", "em-half-diagonal-high-speed-rail", 2, 2)

-- A real small electric pole, not an item-only visual marker.
clone_placeable_entity("electric-pole", "small-electric-pole",
    "em-electric-pole", "em-electric-pole")
data.raw.item["em-electric-pole"].icon = "__base__/graphics/icons/small-electric-pole.png"

-- Keep the custom locomotive's intended performance and energy-source concept,
-- but inherit the complete rolling-stock prototype from the base locomotive.
local electric_locomotive = table.deepcopy(data.raw.locomotive.locomotive)
electric_locomotive.name = "em-electric-locomotive"
electric_locomotive.weight = 2000
electric_locomotive.energy_source = { type = "void" }
electric_locomotive.max_power = "600kW"
electric_locomotive.max_speed = 1.5
electric_locomotive.reversing_power_modifier = 0.6
electric_locomotive.braking_force = 10
electric_locomotive.friction_force = 0.50
electric_locomotive.minable = { mining_time = 0.5, result = "em-electric-locomotive" }
electric_locomotive.placeable_by = { item = "em-electric-locomotive", count = 1 }
electric_locomotive.next_upgrade = nil
data.raw.locomotive["em-electric-locomotive"] = electric_locomotive
data.raw.item["em-electric-locomotive"].place_result = "em-electric-locomotive"

-- The custom wagons now have actual rolling-stock entities. Their capacities
-- intentionally remain at vanilla values until the balancing pass.
clone_placeable_entity("cargo-wagon", "cargo-wagon",
    "em-high-speed-cargo-wagon", "em-high-speed-cargo-wagon")
clone_placeable_entity("fluid-wagon", "fluid-wagon",
    "em-high-speed-fluid-wagon", "em-high-speed-fluid-wagon")

-- This recipe already existed, but its result item prototype was missing.
data:extend({
    {
        type = "item",
        name = "em-regenerative-brake-unit",
        icon = "__base__/graphics/icons/battery.png",
        icon_size = 64,
        subgroup = "intermediate-product",
        order = "a[energy]-z[regenerative-brake-unit]",
        stack_size = 50,
        weight = 10,
    },
})
