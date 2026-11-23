local count=0
for name,p in pairs(data.raw.locomotive) do
 if name:match('^em%-c5%-technical%-booster%-%d+$') then
  assert(p.alert_icon_scale==0, 'helper alert scale not zero '..name)
  assert(p.icons_positioning==nil or next(p.icons_positioning)==nil, 'helper alt-inventory graphic still present '..name)
  assert(not p.selectable_in_game and p.hidden_in_factoriopedia, 'helper interactable '..name)
  assert(p.minimap_representation==nil and p.selected_minimap_representation==nil, 'helper minimap icon '..name)
  assert(p.energy_source.render_no_power_icon==false, 'helper fuel icon '..name)
  assert(p.pictures.rotated.filename=='__core__/graphics/empty.png', 'helper locomotive art '..name)
  assert(p.wheels.rotated.filename=='__core__/graphics/empty.png', 'helper wheels '..name)
  assert(p.front_light==nil and p.back_light==nil and p.stand_by_light==nil and p.minable==nil and p.placeable_by==nil, 'helper extra graphics '..name)
  count=count+1
 end
end
assert(count==256,'missing helper variants '..count)
assert(data.raw.locomotive['em-electric-locomotive'].alert_icon_scale~=0,'real EM path warning hidden')
assert(data.raw.locomotive.locomotive.alert_icon_scale~=0,'vanilla path warning hidden')
log('[EM078 QA DATA PASS] 256/256: helper alert-icon-scale=0, fuel/icons/minimap/wheels all hidden; real EM and vanilla train alerts retained')
