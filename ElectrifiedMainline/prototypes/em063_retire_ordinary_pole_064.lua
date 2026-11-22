-- EM064 isolated trial: retire redundant ordinary factory pole from player menus.
-- KEEP legacy prototype names for existing save files/blueprints/inventories.
local name="em-electric-pole"
local entity=assert(data.raw["electric-pole"][name])
local item=assert(data.raw.item[name])
local recipe=assert(data.raw.recipe[name])
local tech=assert(data.raw.technology["em-electrified-railways"])
assert(item.place_result==name)
assert(entity.minable and entity.minable.result==name)
item.hidden=true
recipe.hidden=true
recipe.enabled=false
local effects={}
for _,e in ipairs(tech.effects or {}) do
  if not (e.type=="unlock-recipe" and e.recipe==name) then
    effects[#effects+1]=e
  end
end
tech.effects=effects
-- Base small electric pole, 25kV masts/substation, and all graphics untouched.
log("[EM064 LEGACY POLE RETIRE] recipe hidden, tech unlock removed, legacy item/entity kept")
