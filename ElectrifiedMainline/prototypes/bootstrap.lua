-- ElectrifiedMainline/data.lua
-- High-speed electric railway infrastructure for Factorio 2.1.20 with Space Age expansion.
--
-- API verification notes (2.1.20):
-- - Locomotives use energy_source :: BurnerEnergySource or VoidEnergySource
-- - Rail types are separate: straight-rail, curved-rail, half-diagonal-rail
-- - The redundant legacy factory electric pole has been removed in EM085.
-- - New isolated 35kV supports are defined separately in prototypes/power_019.lua.
-- - Train regeneration is not implemented; on_tick only observes rail/speed.

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
        effects = {}, -- Research prerequisite for battery rolling stock.
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
            { type = "unlock-recipe", recipe = "em-high-speed-rail" },
            { type = "unlock-recipe", recipe = "em-rail-replacement-planner" },
        },
        prerequisites = { "em-electrified-railways", "logistics-3" },
        unit = { count = 3500, time = 120, ingredients = { { "automation-science-pack", 4 }, { "production-science-pack", 2 } } },
    },
})

-- A dedicated planner keeps the whole ВСМ geometry set in one inventory item.
-- Start from the vanilla planner to retain its version-specific item fields.
local em_high_speed_rail_planner = table.deepcopy(data.raw["rail-planner"]["rail"])
em_high_speed_rail_planner.name = "em-high-speed-rail"
em_high_speed_rail_planner.icons = nil
em_high_speed_rail_planner.icon = "__ElectrifiedMainline__/graphics/icons/hsr-057.png"
em_high_speed_rail_planner.icon_size = 64
em_high_speed_rail_planner.localised_name = {"item-name.em-high-speed-rail"}
em_high_speed_rail_planner.subgroup = "train-transport"
em_high_speed_rail_planner.order = "a[rail]-b[high-speed-rail]"
em_high_speed_rail_planner.place_result = "em-high-speed-straight-rail"
em_high_speed_rail_planner.stack_size = 100
em_high_speed_rail_planner.rails = {
    "em-high-speed-straight-rail",
    "em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b",
    "em-half-diagonal-high-speed-rail",
}
data:extend({em_high_speed_rail_planner})

-- Dedicated selection tool for replacing vanilla rails. It only selects the
-- four vanilla rail prototypes; the runtime handler schedules deconstruction
-- and recreates matching ВСМ ghosts after the old rails have been mined.
local em_rail_replacement_planner = table.deepcopy(data.raw["selection-tool"]["selection-tool"])
em_rail_replacement_planner.name = "em-rail-replacement-planner"
em_rail_replacement_planner.localised_name = {"item-name.em-rail-replacement-planner"}
em_rail_replacement_planner.localised_description = {"item-description.em-rail-replacement-planner"}
em_rail_replacement_planner.icons = nil
em_rail_replacement_planner.icon = "__ElectrifiedMainline__/graphics/icons/hsr-replacement-057.png"
em_rail_replacement_planner.icon_size = 64
em_rail_replacement_planner.subgroup = "train-transport"
em_rail_replacement_planner.order = "a[rail]-c[rail-replacement-planner]"
em_rail_replacement_planner.stack_size = 1
em_rail_replacement_planner.select = {
    mode = {"any-entity"},
    entity_filters = {
        "straight-rail",
        "curved-rail-a",
        "curved-rail-b",
        "half-diagonal-rail",
    },
    entity_filter_mode = "whitelist",
    cursor_box_type = "copy",
    border_color = {r = 0.15, g = 0.8, b = 1, a = 1},
}
em_rail_replacement_planner.alt_select = {
    mode = {"nothing"},
    cursor_box_type = "not-allowed",
    border_color = {r = 1, g = 0.2, b = 0.2, a = 1},
}
data:extend({em_rail_replacement_planner})


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
        max_power = "2MW",
        max_speed = 2.0,
        reversing_power_modifier = 0.6,
        braking_force = 20,
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
        ingredients = { { type = "item", name = "steel-plate", amount = 50 }, { type = "item", name = "em-traction-motor", amount = 5 }, { type = "item", name = "em-battery-bank", amount = 3 } },
        results = {{ type = "item", name = "em-electric-locomotive", amount = 1 }},
        energy_required = 100,
        categories = { "crafting" },
    },




})

data:extend({
    {
        type = "recipe",
        name = "em-concrete-beam",
        enabled = false,
        ingredients = { { type = "item", name = "stone-brick", amount = 2 }, { type = "item", name = "steel-plate", amount = 4 }, { type = "item", name = "pipe", amount = 1 } },
        results = {{ type = "item", name = "em-concrete-beam", amount = 1 }},
        energy_required = 5,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-heavy-copper-cable",
        enabled = false,
        ingredients = { { type = "item", name = "copper-cable", amount = 3 }, { type = "item", name = "plastic-bar", amount = 1 } },
        results = {{ type = "item", name = "em-heavy-copper-cable", amount = 1 }},
        energy_required = 2,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-traction-motor",
        enabled = false,
        ingredients = { { type = "item", name = "copper-cable", amount = 10 }, { type = "item", name = "iron-gear-wheel", amount = 5 }, { type = "item", name = "advanced-circuit", amount = 2 } },
        results = {{ type = "item", name = "em-traction-motor", amount = 1 }},
        energy_required = 10,
        categories = { "crafting" },
    },

    {
        type = "recipe",
        name = "em-battery-bank",
        enabled = false,
        ingredients = { { type = "item", name = "battery", amount = 10 }, { type = "item", name = "steel-plate", amount = 5 } },
        results = {{ type = "item", name = "em-battery-bank", amount = 1 }},
        energy_required = 8,
        categories = { "crafting" },
    },

    -- One recipe creates planner stock used by every ВСМ rail geometry.
    {
        type = "recipe",
        name = "em-high-speed-rail",
        enabled = false,
        ingredients = {
            { type = "item", name = "steel-plate", amount = 4 },
            { type = "item", name = "copper-cable", amount = 4 },
        },
        results = {{ type = "item", name = "em-high-speed-rail", amount = 4 }},
        energy_required = 1,
        categories = { "crafting" },
    },
    {
        type = "recipe",
        name = "em-rail-replacement-planner",
        enabled = false,
        ingredients = {
            { type = "item", name = "em-high-speed-rail", amount = 1 },
            { type = "item", name = "electronic-circuit", amount = 5 },
            { type = "item", name = "steel-plate", amount = 5 },
        },
        results = {{ type = "item", name = "em-rail-replacement-planner", amount = 1 }},
        energy_required = 5,
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

    local item = (data.raw.item and data.raw.item[item_name])
        or (data.raw["rail-planner"] and data.raw["rail-planner"][item_name])
    assert(item, "ElectrifiedMainline: missing placeable item prototype " .. item_name)
    item.place_result = target_name
end

-- Replace the hand-built rail prototypes with complete copies of the matching
-- vanilla prototypes. This avoids silently omitting required fields as the API evolves.
clone_placeable_entity("straight-rail", "straight-rail",
    "em-high-speed-straight-rail", "em-high-speed-rail", 1, 1)
clone_placeable_entity("curved-rail-a", "curved-rail-a",
    "em-curved-high-speed-rail", "em-high-speed-rail", 3, 3)
clone_placeable_entity("curved-rail-b", "curved-rail-b",
    "em-curved-high-speed-rail-b", "em-high-speed-rail", 3, 3)
clone_placeable_entity("half-diagonal-rail", "half-diagonal-rail",
    "em-half-diagonal-high-speed-rail", "em-high-speed-rail", 2, 2)

-- The helper assigns place_result for each geometry; keep the planner's
-- default placement result on the straight rail.
data.raw["rail-planner"]["em-high-speed-rail"].place_result = "em-high-speed-straight-rail"

-- Match inventory, recipe, technology and all four HSR entity icons.
local function hsr_icon(p, replacement)
    p.icons = nil
    p.icon = "__ElectrifiedMainline__/graphics/icons/" .. (replacement and "hsr-replacement-057.png" or "hsr-057.png")
    p.icon_size = 64
end
for _, pair in ipairs({{"straight-rail","em-high-speed-straight-rail"},{"curved-rail-a","em-curved-high-speed-rail"},{"curved-rail-b","em-curved-high-speed-rail-b"},{"half-diagonal-rail","em-half-diagonal-high-speed-rail"}}) do
    hsr_icon(data.raw[pair[1]][pair[2]])
end
hsr_icon(data.raw.recipe["em-high-speed-rail"])
hsr_icon(data.raw.recipe["em-rail-replacement-planner"], true)
hsr_icon(data.raw.technology["em-high-speed-rails"])

-- Keep the custom locomotive's intended performance and energy-source concept,
-- but inherit the complete rolling-stock prototype from the base locomotive.
local electric_locomotive = table.deepcopy(data.raw.locomotive.locomotive)
electric_locomotive.name = "em-electric-locomotive"
electric_locomotive.weight = 2000
electric_locomotive.energy_source = { type = "void" }
electric_locomotive.max_power = "2MW"
electric_locomotive.max_speed = 2.0
electric_locomotive.reversing_power_modifier = 0.6
electric_locomotive.braking_force = 20
electric_locomotive.friction_force = 0.50
electric_locomotive.minable = { mining_time = 0.5, result = "em-electric-locomotive" }
electric_locomotive.placeable_by = { item = "em-electric-locomotive", count = 1 }
electric_locomotive.next_upgrade = nil
data.raw.locomotive["em-electric-locomotive"] = electric_locomotive
data.raw.item["em-electric-locomotive"].place_result = "em-electric-locomotive"

-- 057: use native cargo and fluid wagons only; JSON migration preserves legacy names.

-- Legacy item retained to preserve inventory contents in existing saves. No recipe.
data:extend({
    {
        type = "item",
        name = "em-regenerative-brake-unit",
        auto_recycle = false,
        hidden = true,
        hidden_in_factoriopedia = true,
        icon = "__base__/graphics/icons/battery.png",
        icon_size = 64,
        subgroup = "intermediate-product",
        order = "a[energy]-z[regenerative-brake-unit]",
        stack_size = 50,
        weight = 10,
    },
})
