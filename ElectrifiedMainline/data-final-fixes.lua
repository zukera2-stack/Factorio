-- ElectrifiedMainline/data-final-fixes.lua
-- Experimental 0.1.7: use Factorio's native rail upgrade path.
-- A distinct fast_replaceable_group is required for each rail geometry.
-- next_upgrade makes the default green Upgrade Planner recognize each pair.
-- No custom code is borrowed from other mods.

local rail_pairs = {
    { type = "straight-rail", vanilla = "straight-rail", custom = "em-high-speed-straight-rail" },
    { type = "curved-rail-a", vanilla = "curved-rail-a", custom = "em-curved-high-speed-rail" },
    { type = "curved-rail-b", vanilla = "curved-rail-b", custom = "em-curved-high-speed-rail-b" },
    { type = "half-diagonal-rail", vanilla = "half-diagonal-rail", custom = "em-half-diagonal-high-speed-rail" },
}

local ITEM_PROTOTYPE_TYPES = {
    "item", "rail-planner", "item-with-entity-data", "item-with-tags",
    "item-with-inventory", "item-with-label", "tool", "ammo", "capsule",
    "gun", "module", "armor", "repair-tool", "selection-tool",
    "copy-paste-tool", "blueprint", "blueprint-book", "deconstruction-item",
    "upgrade-item", "spidertron-remote",
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

local function remove_not_upgradable(prototype)
    local filtered = {}
    local removed = false
    for _, flag in ipairs(prototype.flags or {}) do
        if flag == "not-upgradable" then
            removed = true
        else
            filtered[#filtered + 1] = flag
        end
    end
    if removed then prototype.flags = filtered end
    return removed
end

local function find_item_prototype(item_name)
    for _, item_type in ipairs(ITEM_PROTOTYPE_TYPES) do
        local prototypes = data.raw[item_type]
        local item = prototypes and prototypes[item_name]
        if item then return item end
    end
    return nil
end

local function get_mining_item_names(minable)
    local names = {}
    if type(minable.result) == "string" then
        names[#names + 1] = minable.result
    end
    for _, product in pairs(minable.results or {}) do
        if (product.type or "item") == "item" and type(product.name) == "string" then
            names[#names + 1] = product.name
        end
    end
    return names
end

local function validate_source(source)
    local minable_ok = type(source.minable) == "table"
    local visible_ok = source.hidden ~= true
    local hidden_mining_item = nil
    if minable_ok then
        for _, item_name in ipairs(get_mining_item_names(source.minable)) do
            local item = find_item_prototype(item_name)
            if not item then
                hidden_mining_item = "<missing:" .. item_name .. ">"
                break
            end
            if item.hidden == true then
                hidden_mining_item = item_name
                break
            end
        end
    end
    return {
        minable_ok = minable_ok,
        visible_ok = visible_ok,
        hidden_mining_item = hidden_mining_item,
        eligible = minable_ok and visible_ok and hidden_mining_item == nil,
    }
end

local function add_placeable_by_items(target, item_names)
    local placeable_by = target.placeable_by
    if type(placeable_by) ~= "table" then return end
    if type(placeable_by.item) == "string" then
        item_names[placeable_by.item] = true
        return
    end
    for _, entry in pairs(placeable_by) do
        if type(entry) == "table" and type(entry.item) == "string" then
            item_names[entry.item] = true
        end
    end
end

local function find_visible_build_item(target)
    local candidates = {}
    add_placeable_by_items(target, candidates)
    -- Also inspect reverse links, covering prototypes that define place_result.
    for _, prototypes in pairs(data.raw) do
        for item_name, prototype in pairs(prototypes) do
            if prototype.place_result == target.name then
                candidates[item_name] = true
            end
        end
    end
    for item_name in pairs(candidates) do
        local item = find_item_prototype(item_name)
        if item and item.hidden ~= true then return item_name end
    end
    return nil
end

for _, pair in pairs(rail_pairs) do
    local prototypes = data.raw[pair.type]
    local vanilla = prototypes and prototypes[pair.vanilla]
    local custom = prototypes and prototypes[pair.custom]
    assert(vanilla, "ElectrifiedMainline: missing vanilla rail " .. pair.vanilla)
    assert(custom, "ElectrifiedMainline: missing custom rail " .. pair.custom)

    local collision_box_ok = tables_equal(vanilla.collision_box, custom.collision_box)
    local collision_mask_ok = tables_equal(vanilla.collision_mask, custom.collision_mask)
    -- Remove only the disqualifying flag; preserve all other prototype flags.
    local vanilla_flag_removed = remove_not_upgradable(vanilla)
    local custom_flag_removed = remove_not_upgradable(custom)
    local upgrade_group = "em-native-" .. pair.type
    local previous_next_upgrade = vanilla.next_upgrade
    local conflicting_upgrade = previous_next_upgrade ~= nil and previous_next_upgrade ~= pair.custom

    local source_check = validate_source(vanilla)
    local target_visible_item = find_visible_build_item(custom)
    local target_visible = custom.hidden ~= true
    local function status(value) return value and "PASS" or "FAIL" end
    local eligible = source_check.eligible and target_visible and target_visible_item
        and collision_box_ok and collision_mask_ok

    if conflicting_upgrade then
        -- Do not break another mod's existing upgrade chain.
        log("[ElectrifiedMainline][native-upgrade] SKIP existing next_upgrade on "
            .. pair.vanilla .. ": " .. tostring(previous_next_upgrade))
    elseif eligible then
        vanilla.fast_replaceable_group = upgrade_group
        custom.fast_replaceable_group = upgrade_group
        vanilla.next_upgrade = pair.custom
        log("[ElectrifiedMainline][native-upgrade] CONFIGURED "
            .. pair.vanilla .. " -> " .. pair.custom .. " group=" .. upgrade_group)
    else
        log("[ElectrifiedMainline][native-upgrade] INELIGIBLE "
            .. pair.vanilla .. " -> " .. pair.custom)
    end

    log(string.format(
        "[ElectrifiedMainline][upgrade-check] %s -> %s | source_minable=%s source_visible=%s source_hidden_mining_product=%s source_not_upgradable_removed=%s | target_visible=%s target_visible_build_item=%s | group=%s collision_box=%s collision_mask=%s",
        pair.vanilla, pair.custom,
        status(source_check.minable_ok),
        status(source_check.visible_ok),
        status(source_check.hidden_mining_item == nil),
        tostring(vanilla_flag_removed),
        status(target_visible and target_visible_item ~= nil),
        target_visible_item or "<none>",
        vanilla.fast_replaceable_group or "<none>",
        status(collision_box_ok),
        status(collision_mask_ok)
    ))

    if source_check.hidden_mining_item then
        log("[ElectrifiedMainline][upgrade-check] " .. pair.vanilla
            .. " has hidden or unresolved mining item: " .. source_check.hidden_mining_item)
    end
    if not source_check.eligible or not target_visible or not target_visible_item
        or not collision_box_ok or not collision_mask_ok then
        log("[ElectrifiedMainline][upgrade-check] INELIGIBLE pair: "
            .. pair.vanilla .. " -> " .. pair.custom)
    end
    if custom_flag_removed then
        log("[ElectrifiedMainline][upgrade-check] Removed not-upgradable from " .. pair.custom)
    end
end
