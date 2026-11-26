local E=assert(data.raw["burner-usage"]["em-25kv-electric-status-074"])
local H=assert(data.raw["burner-usage"]["em-hidden-motor-status-074"])
local standard=assert(data.raw["burner-usage"].fuel)
assert(E.no_fuel_status[1]=="em-traction-status.no-traction-power")
assert(E.icon.filename=="__core__/graphics/icons/alerts/electricity-icon-red.png")
assert(H.icon.filename=="__core__/graphics/empty.png")
assert(H.icon.width==1 and H.icon.height==1)
assert(standard.no_fuel_status[1]=="entity-status.no-fuel")
assert(standard.icon.filename=="__core__/graphics/icons/alerts/fuel-icon-red.png")
local loco=assert(data.raw.locomotive["em-electric-locomotive"])
assert(loco.energy_source.type=="burner")
assert(loco.energy_source.burner_usage==E.name)
assert(loco.energy_source.render_no_power_icon~=false,"real electric locomotive warning must remain visible")
assert(loco.energy_source.fuel_categories[1]=="em-c5-test-internal-energy-063")
assert(loco.max_power=="2MW")
local vanilla=assert(data.raw.locomotive.locomotive)
assert(vanilla.energy_source.burner_usage==nil)
local count=0
for n,e in pairs(data.raw.locomotive) do
 if n:match("^em%-c5%-technical%-booster%-%d+$") then
  assert(e.energy_source.type=="burner" and e.energy_source.burner_usage==H.name)
  assert(e.energy_source.render_no_power_icon==false,"hidden helper renders no-fuel icon: "..n)
  assert(e.energy_source.fuel_categories[1]=="em-c5-test-internal-energy-063")
  assert(e.selectable_in_game==false)
  count=count+1
 end
end
assert(count==256,"all 256 boosters must use hidden status")
log('[EM076 STATUS QA DATA] PASS: 256/256 hidden no-fuel warning renders OFF, electric traction-power status, vanilla unchanged, native burner intact')