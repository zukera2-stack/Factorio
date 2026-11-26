-- EM065 RESEARCH ONLY: actual EM 2MW locomotive no longer has free void drive.
-- Prior full mod 0.1.64 installed by owner is NOT modified.
local loco=assert(data.raw.locomotive["em-electric-locomotive"])
assert(loco.energy_source and loco.energy_source.type=="void",
  "EM065 native burner adapter must replace exactly the known void source")
assert(data.raw["fuel-category"]["em-c5-test-internal-energy-063"])
local fuel=assert(data.raw.item["em-c5-test-internal-joule-063"])
assert(fuel.hidden==true,"internal Joule carrier must not be user-visible")
assert(not data.raw.recipe["em-c5-test-internal-joule-063"],
  "internal Joule carrier must have no crafting recipe")
loco.energy_source={
  type="burner",
  fuel_categories={"em-c5-test-internal-energy-063"},
  effectivity=1,
  fuel_inventory_size=1,
}
-- Max native locomotive power/weight/speed/collision/visuals unchanged.
assert(loco.max_power=="2MW")
log("[EM065 FINITE LOCOMOTIVE] native BurnerEnergySource 2MW; only paid EM070 J allowed")
