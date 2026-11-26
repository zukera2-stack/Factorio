-- Independent data-stage contract checks after the full mod's data stages.
local flags={'not-blueprintable','not-deconstructable','not-on-map','hide-alt-info','not-upgradable','no-automated-item-insertion','no-automated-item-removal','not-in-kill-statistics','not-repairable'}
for i=1,256 do
 local name='em-c5-technical-booster-'..(i*500)
 local p=assert(data.raw.locomotive[name],name)
 assert(p.max_power==(i*500)..'kW',name..' wrong max_power')
 assert(p.hidden and p.hidden_in_factoriopedia and p.selectable_in_game==false and p.allow_copy_paste==false,name..' exposed')
 assert(p.alert_icon_scale==0 and #p.icons_positioning==0 and not p.minimap_representation and not p.selected_minimap_representation,name..' visible marker')
 assert(p.energy_source.type=='burner' and p.energy_source.render_no_power_icon==false,name..' unpaid/no fuel warning')
 assert(p.pictures.rotated.filename=='__core__/graphics/empty.png' and p.wheels.rotated.filename=='__core__/graphics/empty.png',name..' non-empty sprites')
 local got={} for _,f in pairs(p.flags) do got[f]=true end for _,f in ipairs(flags) do assert(got[f],name..' missing '..f) end
end
log('[EXT DATA PASS] 256/256 max_power, hidden flags, transparent graphics, no fuel and no path indicators')
