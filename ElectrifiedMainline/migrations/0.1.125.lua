-- Reconcile only the relocated recipe unlocks for existing forces.
for _, force in pairs(game.forces) do
  local tech = force.technologies["em-high-speed-rails"]
  if tech then
    for _, name in ipairs({"em-35kv-catenary-pole","em-35kv-catenary-pole-north","em-35kv-traction-substation"}) do
      local recipe=force.recipes[name]
      if recipe then recipe.enabled=tech.researched end
    end
  end
end
