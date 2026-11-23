-- EM074: UI-only status icons for actual electric and technical locomotives.
-- Native Factorio 2.1 BurnerUsagePrototype: per-burner no_fuel_status and alert icon.
-- No changes to fuel categories, paid Joules, propulsion or automatic mode.
local base = assert(data.raw["burner-usage"] and data.raw["burner-usage"]["fuel"])
local electric = table.deepcopy(base)
electric.name = "em-25kv-electric-status-074"
electric.no_fuel_status = {"em-traction-status.no-contact"}
electric.empty_slot_caption = {"em-traction-status.energy"}
electric.empty_slot_description = {"em-traction-status.energy-description"}
electric.icon = {
  filename = "__core__/graphics/icons/alerts/electricity-icon-red.png",
  priority = "extra-high-no-scale", width = 64, height = 64,
  flags = {"icon"}
}
local technical = table.deepcopy(base)
technical.name = "em-hidden-motor-status-074"
technical.no_fuel_status = {"em-traction-status.technical"}
technical.icon = {
  filename = "__core__/graphics/empty.png",
  width = 1, height = 1, flags = {"icon"}
}
-- All 256 hidden boosters are native locomotives; must not have 256 fuel alerts.
data:extend({electric,technical})
local real = assert(data.raw.locomotive["em-electric-locomotive"])
assert(real.energy_source and real.energy_source.type == "burner")
real.energy_source.burner_usage = electric.name
local count = 0
for name,proto in pairs(data.raw.locomotive) do
  if name:match("^em%-c5%-technical%-booster%-%d+$") then
    assert(proto.energy_source and proto.energy_source.type == "burner")
    proto.energy_source.burner_usage = technical.name
    count=count+1
  end
end
assert(count == 256, "EM074 expected exactly 256 finite-J hidden locomotive prototypes")
assert(data.raw.locomotive.locomotive.energy_source.burner_usage == nil,
 "EM074 must not alter vanilla fuel-status rendering")
log("[EM074 STATUS] electric=no-contact red-electricity; technical=transparent; boosters="..count)