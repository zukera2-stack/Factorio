-- ElectrifiedMainline/data-final-fixes.lua
-- Validate and expose the four vanilla -> Electrified Mainline rail upgrade pairs.
-- The shared group only makes compatible prototypes eligible for planner pairing;
-- it does not make Factorio's native robot rail replacement work by itself.

local UPGRADE_GROUP = "em-rail-upgrade"

local rail_pairs = {
    { type = "straight-rail", vanilla = "straight-rail", custom = "em-high-speed-straight-rail" },
    { type = "curved-rail-a", vanilla = "curved-rail-a", custom = "em-curved-high-speed-rail" },
    { type = "curved-rail-b", vanilla = "curved-rail-b", custom = "em-curved-high-speed-rail-b" },
    { type = "half-diagonal-rail", vanilla = "half-diagonal-rail", custom = "em-half-diagonal-high-speed-rail" },
}

local function tables_equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end

    for key, value in pairs(a) do
        if not tables_equal(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

for _, pair in pairs(rail_pairs) do
    local prototypes = data.raw[pair.type]
    local vanilla = prototypes and prototypes[pair.vanilla]
    local custom = prototypes and prototypes[pair.custom]

    assert(vanilla, "ElectrifiedMainline: missing vanilla rail " .. pair.vanilla)
    assert(custom, "ElectrifiedMainline: missing custom rail " .. pair.custom)

    -- Fail during data loading if a mod changes either geometry/mask and makes
    -- the pair invalid for UpgradeItemPrototype compatibility.
    assert(tables_equal(vanilla.collision_box, custom.collision_box),
        "ElectrifiedMainline: collision_box mismatch for "
            .. pair.vanilla .. " -> " .. pair.custom)
    assert(tables_equal(vanilla.collision_mask, custom.collision_mask),
        "ElectrifiedMainline: collision_mask mismatch for "
            .. pair.vanilla .. " -> " .. pair.custom)

    vanilla.fast_replaceable_group = UPGRADE_GROUP
    custom.fast_replaceable_group = UPGRADE_GROUP

    log("[ElectrifiedMainline] Upgrade pair validated: "
        .. pair.vanilla .. " -> " .. pair.custom
        .. " (collision_box and collision_mask match)")
end
