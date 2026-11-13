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
-- 0.1.12: upright mast; arm is rendered independently facing nearby HSR.
-- Keep the native nonconducting electric pole and its original Undo identity.
local graphics = "__ElectrifiedMainline__/graphics/entity/35kv/"
catenary.pictures = {layers={
    {filename=graphics.."pole-mast-hr.png",width=512,height=384,
        direction_count=1,scale=0.5,shift={0,-2.53125}},
    {filename=graphics.."pole-shadow-static-hr.png",width=512,height=384,
        direction_count=1,scale=0.5,shift={0,-2.53125},draw_as_shadow=true},
}}

local substation = table.deepcopy(data.raw["electric-pole"]["substation"])
substation.name = "em-35kv-traction-substation"
substation.minable = {mining_time = 0.6, result = substation.name}
substation.placeable_by = {item = substation.name, count = 1}
substation.next_upgrade = nil
flag_once(substation, "get-by-unit-number")

data:extend({
    catenary, substation,
    {type="sprite",name="em-35kv-cantilever",
        filename=graphics.."pole-arm-hr.png",width=512,height=512,scale=0.5},
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
