-- ElectrifiedMainline 0.1.9: visual/graph prototype; energy transfer remains OFF.
-- These are NOT functioning rail-signal snapped supports or a bidirectional grid.
local function flag_once(proto, flag)
    proto.flags = table.deepcopy(proto.flags or {})
    for _, value in pairs(proto.flags) do if value == flag then return end end
    table.insert(proto.flags, flag)
end

local catenary = table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
catenary.name = "em-35kv-catenary-pole"
catenary.minable = {mining_time = 0.3, result = catenary.name}
catenary.placeable_by = {item = catenary.name, count = 1}
catenary.next_upgrade = nil
catenary.maximum_wire_distance = 0
catenary.supply_area_distance = 0
catenary.auto_connect_up_to_n_wires = 0
catenary.draw_copper_wires = false
catenary.draw_circuit_wires = false
catenary.rewire_neighbours_when_destroying = false
flag_once(catenary, "get-by-unit-number")
-- 0.1.13: A one-direction RotatedSprite MUST have exactly one matching
-- WireConnectionPoint.  The copied vanilla small pole can have multiple
-- connection_points (rotations), even when its copper/circuit wires are disabled.
-- Factorio 2.1.20 rejects a mismatch at data-stage validation with:
-- "Count of wire positions doesn't match the count of pictures of the pole".
-- Retain one valid vanilla point rather than manufacturing an empty one.
-- The decorative contact wires remain LuaRendering objects; these connection
-- points do not create native power wires (all wire-reach flags are zero).
assert(catenary.connection_points and catenary.connection_points[1],
    "ElectrifiedMainline: base small-electric-pole has no wire connection point")
catenary.connection_points = {table.deepcopy(catenary.connection_points[1])}
-- 0.1.12: The electric-pole entity cannot be rotated like a RailSignal.
-- Hide only its ordinary picture; render the arm via runtime SpritePrototypes
-- selected from nearby high-speed rail geometry. Signal prototypes stay untouched.
local graphics = "__ElectrifiedMainline__/graphics/entity/35kv/"
catenary.pictures = {layers = {
    {filename = graphics .. "hidden-pole-012.png", width = 1,
        height = 1, direction_count = 1},
    {filename = graphics .. "pole-shadow-4dir-hr.png",
        width = 512, height = 384, direction_count = 1,
        scale = 0.5, shift = {0,-2.53125},
        draw_as_shadow = true},
}}
catenary.active_picture = nil

local substation = table.deepcopy(data.raw["electric-pole"]["substation"])
substation.name = "em-35kv-traction-substation"
substation.minable = {mining_time = 0.6, result = substation.name}
substation.placeable_by = {item = substation.name, count = 1}
substation.next_upgrade = nil
flag_once(substation, "get-by-unit-number")

data:extend({
    catenary, substation,
    -- Face names reflect the rail's position relative to the mast, not its own direction.
    {
        type = "sprite", name = "em-35kv-facing-east",
        filename = graphics .. "pole-east-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-southeast",
        filename = graphics .. "pole-southeast-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-south",
        filename = graphics .. "pole-south-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-southwest",
        filename = graphics .. "pole-southwest-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-west",
        filename = graphics .. "pole-west-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-northwest",
        filename = graphics .. "pole-northwest-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-north",
        filename = graphics .. "pole-north-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-northeast",
        filename = graphics .. "pole-northeast-012.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-contact-wire-texture",
        filename = graphics .. "contact-wire-hr.png",
        width = 512, height = 48, scale = 0.5,
    },
    {
        type = "item", name = "em-35kv-catenary-pole",
        icon = "__base__/graphics/icons/medium-electric-pole.png",
        icon_size = 64, subgroup = "energy",
        order = "a[electric-pole]-z[35kv-catenary]",
        stack_size = 50, place_result = "em-35kv-catenary-pole",
    },
    {
        type = "item", name = "em-35kv-traction-substation",
        icon = "__base__/graphics/icons/substation.png",
        icon_size = 64, subgroup = "energy",
        order = "a[electric-pole]-z[35kv-substation]",
        stack_size = 50, place_result = "em-35kv-traction-substation",
    },
    {
        type = "recipe", name = "em-35kv-catenary-pole", enabled = false,
        ingredients = {
            {type = "item", name = "em-concrete-beam", amount = 2},
            {type = "item", name = "em-heavy-copper-cable", amount = 4},
            {type = "item", name = "steel-plate", amount = 5},
        },
        results = {{type = "item", name = "em-35kv-catenary-pole", amount = 1}},
        energy_required = 5,
    },
    {
        type = "recipe", name = "em-35kv-traction-substation", enabled = false,
        ingredients = {
            {type = "item", name = "substation", amount = 1},
            {type = "item", name = "em-heavy-copper-cable", amount = 20},
            {type = "item", name = "advanced-circuit", amount = 5},
        },
        results = {{type = "item", name = "em-35kv-traction-substation", amount = 1}},
        energy_required = 15,
    },
})

local tech = data.raw.technology["em-electrified-railways"]
assert(tech, "ElectrifiedMainline: missing electrified railways technology")
tech.effects = tech.effects or {}
table.insert(tech.effects, {type = "unlock-recipe", recipe = "em-35kv-catenary-pole"})
table.insert(tech.effects, {type = "unlock-recipe", recipe = "em-35kv-traction-substation"})
