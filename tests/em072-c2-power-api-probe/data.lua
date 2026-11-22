local normal = table.deepcopy(data.raw.locomotive.locomotive)
normal.name="em-power-2mw"
normal.minable = {mining_time = 1, result = "locomotive"}
normal.max_power="2MW"
normal.energy_source={type="void"}
data:extend({normal})
local boost=table.deepcopy(data.raw.locomotive.locomotive)
boost.name="em-power-3mw"
boost.minable = {mining_time=1, result="locomotive"}
boost.max_power="3MW"
boost.energy_source={type="void"}
data:extend({boost})