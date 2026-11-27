-- ElectrifiedMainline 0.1.9: visual/graph prototype; energy transfer remains OFF.
-- These are NOT functioning rail-signal snapped supports or a bidirectional grid.
local mast034=require("scripts.mast_visual_034")
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
-- The native picture now holds the common C mast shaft; Lua renders only
-- orientation-specific cantilevers. Signal prototypes stay untouched.
local graphics = "__ElectrifiedMainline__/graphics/entity/35kv/"
local mast_icon = "__ElectrifiedMainline__/graphics/icons/25kv-south-039.png"
local north_icon = "__ElectrifiedMainline__/graphics/icons/25kv-north-039.png"
-- 0.1.24: the engine owns the non-rotating steel truss and placement
-- preview/vanilla ghost tint. The cantilever alone is dynamically drawn
-- from the RailEnd-selected 8-way sprite set in scripts/power_019.lua.
-- The former placeable_position_visualization is NOT a cursor-model API.
catenary.placeable_position_visualization = nil
catenary.icons = nil
catenary.icon = mast_icon
catenary.icon_size = 64
catenary.pictures = {layers = {
    {filename = graphics .. "pole-south-039.png",
        width = 512, height = 512, direction_count = 1,
        scale = 0.5, shift = {0,mast034.mast_shift(catenary.name)}},
    {filename = graphics .. "pole-shadow-4dir-hr.png",
        width = 512, height = 384, direction_count = 1,
        scale = 0.5, shift = {0,mast034.mast_shift(catenary.name)},
        draw_as_shadow = true},
}}
-- The engine renders the accepted long shaft also for the hand cursor
-- and ghost. The 8 separate direction sprites render the cantilevers.
catenary.active_picture = nil

local substation = table.deepcopy(data.raw["electric-pole"]["substation"])
substation.name = "em-35kv-traction-substation"
substation.minable = {mining_time = 0.6, result = substation.name}
substation.placeable_by = {item = substation.name, count = 1}
substation.next_upgrade = nil
flag_once(substation, "get-by-unit-number")
-- EM128: industrial oxide-red traction substation; preserve wires, coverage and shadow.
local traction_tint = {r=0.86,g=0.29,b=0.24,a=1}
for _, layer in ipairs(substation.pictures.layers) do
    if not layer.draw_as_shadow then layer.tint=traction_tint end
end
local traction_icons = {
    {icon="__base__/graphics/icons/substation.png",icon_size=64,tint=traction_tint},
    {icon="__ElectrifiedMainline__/graphics/icons/traction-25kv-125.png",icon_size=64},
}
substation.icon=nil; substation.icons=table.deepcopy(traction_icons)

-- 0.1.33: an explicit NORTHERN placement variant keeps native electric-pole
-- placement, blueprint and Undo mechanics. Its shaft is shortened only in art.
-- It is an independent placeable prototype rather than a runtime entity swap.
local northern=table.deepcopy(catenary)
northern.name="em-35kv-catenary-pole-north"
northern.minable={mining_time=0.3,result=northern.name}
northern.placeable_by={item=northern.name,count=1}
northern.pictures.layers[1].filename=graphics.."pole-north-039.png"
-- Northern short source remains 512x384; do not inherit south sprite height.
northern.pictures.layers[1].height=384
-- Short mast sprite and final user-approved NORTH_DROP=2.02 are
-- independent of old raster-trimming experiments.
northern.pictures.layers[1].shift={0,mast034.mast_shift(northern.name)}
-- Shadow follows the footprint, not the contact wire.
northern.pictures.layers[2].shift={0,-2.53125+1.11}
northern.active_picture=nil
northern.icon=north_icon
northern.icon_size=64

data:extend({
    catenary, substation, northern,
    {
        type="item",name="em-35kv-catenary-pole-north",
        icon=north_icon,icon_size=64,subgroup="energy",
        order="a[electric-pole]-z[35kv-catenary]-b[north]",
        stack_size=50,place_result="em-35kv-catenary-pole-north",
    },
    {
        type="recipe",name="em-35kv-catenary-pole-north",enabled=false,
        ingredients={
            {type="item",name="em-concrete-beam",amount=2},
            {type="item",name="em-heavy-copper-cable",amount=4},
            {type="item",name="steel-plate",amount=5},
        },
        results={{type="item",name="em-35kv-catenary-pole-north",amount=1}},
        energy_required=5,
    },
    -- Face names reflect the rail's position relative to the mast, not its own direction.
    {
        type = "sprite", name = "em-35kv-facing-east",
        filename = graphics .. "pole-arm-east-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-southeast",
        filename = graphics .. "pole-arm-southeast-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-south",
        filename = graphics .. "pole-arm-south-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-southwest",
        filename = graphics .. "pole-arm-southwest-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-west",
        filename = graphics .. "pole-arm-west-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-northwest",
        filename = graphics .. "pole-arm-northwest-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-north",
        filename = graphics .. "pole-arm-north-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "sprite", name = "em-35kv-facing-northeast",
        filename = graphics .. "pole-arm-northeast-039.png",
        width = 512, height = 384, scale = 0.5,
    },
    {
        type = "item", name = "em-35kv-catenary-pole",
        icon = mast_icon,
        icon_size = 64, subgroup = "energy",
        order = "a[electric-pole]-z[35kv-catenary]",
        stack_size = 50, place_result = "em-35kv-catenary-pole",
    },
    {
        type = "item", name = "em-35kv-traction-substation",
        icons = table.deepcopy(traction_icons),
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
        icons = table.deepcopy(traction_icons),
        ingredients = {
            {type = "item", name = "substation", amount = 1},
            {type = "item", name = "em-heavy-copper-cable", amount = 20},
            {type = "item", name = "advanced-circuit", amount = 5},
        },
        results = {{type = "item", name = "em-35kv-traction-substation", amount = 1}},
        energy_required = 15,
    },
})

local tech = data.raw.technology["em-high-speed-rails"]
assert(tech, "ElectrifiedMainline: missing high-speed rails technology")
tech.effects = tech.effects or {}
table.insert(tech.effects, {type = "unlock-recipe", recipe = "em-35kv-catenary-pole"})
table.insert(tech.effects, {type = "unlock-recipe", recipe = "em-35kv-catenary-pole-north"})
table.insert(tech.effects, {type = "unlock-recipe", recipe = "em-35kv-traction-substation"})
