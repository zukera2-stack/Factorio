-- EM123: production and localization only. Keep all energy settings and runtime unchanged.
local function item(name,amount) return {type="item",name=name,amount=amount} end
local function recipe(name,ingredients,seconds)
  local r=assert(data.raw.recipe[name]); r.ingredients=ingredients; r.energy_required=seconds
  r.localised_name={"recipe-name."..name};r.localised_description={"item-description."..name}
end
local function prereq(name, additions)
  local t=assert(data.raw.technology[name]);local present={}
  for _,n in ipairs(t.prerequisites or {}) do present[n]=true end
  for _,n in ipairs(additions) do if not present[n] then table.insert(t.prerequisites,n);present[n]=true end end
end
-- Ensure every science pack and recipe ingredient is reachable at its unlock.
prereq("em-electrified-railways",{"railway","plastics","concrete","electric-energy-distribution-2","chemical-science-pack"})
prereq("em-high-speed-rails",{"production-science-pack"})
prereq("em-high-speed-locomotive",{"em-high-speed-rails","battery","fluid-wagon"})
recipe("em-concrete-beam",{item("concrete",4),item("steel-plate",2)},5)
recipe("em-high-speed-rail",{item("steel-plate",4),item("copper-cable",4),item("concrete",4)},1)
recipe("em-motor-cargo-wagon",{item("cargo-wagon",1),item("em-traction-motor",1),item("advanced-circuit",2)},10)
recipe("em-motor-fluid-wagon",{item("fluid-wagon",1),item("em-traction-motor",1),item("advanced-circuit",2)},10)
local name="em-battery-wagon"
local wagon=assert(data.raw["cargo-wagon"][name]);local witem=assert(data.raw["item-with-entity-data"][name])
wagon.hidden=false;wagon.hidden_in_factoriopedia=false
witem.hidden=false;witem.hidden_in_factoriopedia=false
witem.localised_description={"item-description."..name}
witem.order="c[rolling-stock]-z[em-battery-wagon]"
data:extend({
  {type="recipe",name=name,enabled=false,energy_required=60,
    ingredients={item("cargo-wagon",1),item("em-traction-motor",1),item("em-battery-bank",30),item("advanced-circuit",5)},
    results={item(name,1)},localised_name={"recipe-name."..name},localised_description={"item-description."..name}},
  {type="technology",name="em-battery-rolling-stock",icon=witem.icon,icon_size=witem.icon_size,
    prerequisites={"em-regenerative-braking","electric-energy-accumulators"},
    unit={count=500,time=30,ingredients={{"automation-science-pack",1},{"logistic-science-pack",1},{"chemical-science-pack",1},{"production-science-pack",1}}},
    effects={{type="unlock-recipe",recipe=name}},order="e[em-battery-rolling-stock]"}
})
local public={"em-concrete-beam","em-heavy-copper-cable","em-traction-motor","em-battery-bank","em-high-speed-rail","em-electric-locomotive","em-rail-replacement-planner","em-35kv-catenary-pole-north","em-35kv-catenary-pole","em-35kv-traction-substation","em-motor-cargo-wagon","em-motor-fluid-wagon",name}
for _,n in ipairs(public) do
  local r=assert(data.raw.recipe[n]);r.localised_name={"recipe-name."..n};r.localised_description={"item-description."..n}
  for _,t in ipairs({"item","item-with-entity-data","rail-planner","selection-tool"}) do
    local it=data.raw[t] and data.raw[t][n]
    if it then it.localised_name={"item-name."..n};it.localised_description={"item-description."..n} end
  end
end
for _,t in ipairs({"locomotive","cargo-wagon","fluid-wagon","electric-pole"}) do
  for _,n in ipairs(public) do
    local e=data.raw[t] and data.raw[t][n]
    if e then e.localised_name={"entity-name."..n};e.localised_description={"item-description."..n} end
  end
end
