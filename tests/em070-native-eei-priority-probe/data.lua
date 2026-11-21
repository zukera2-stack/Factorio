-- Disposable Factorio 2.1.24 Base same-type prototype comparison.
local original=assert(data.raw["electric-energy-interface"]["electric-energy-interface"])
local variants={"secondary-input","secondary-output","dynamic"}
local copy={}
for _,priority in ipairs(variants) do
  local p=table.deepcopy(original)
  p.name="em070-"..priority
  p.energy_source={type="electric",usage_priority=priority,buffer_capacity="5MJ",
    input_flow_limit="20MW",output_flow_limit="20MW",drain="0W"}
  p.energy_production="0W";p.energy_usage="0W";p.gui_mode="none";p.hidden=true
  p.collision_box={{0,0},{0,0}};p.selection_box={{0,0},{0,0}}
  p.collision_mask={layers={}};p.selectable_in_game=false
  copy[#copy+1]=p
end
data:extend(copy)
