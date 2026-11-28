-- EM138: clean synthetic traction sound, native wheel sound preserved.
-- Audio only. No runtime energy or train control changes.
local loco=assert(data.raw.locomotive["em-electric-locomotive"])
local original=assert(loco.working_sound)
local wheels
for _,layer in ipairs(original.main_sounds or {}) do
  if layer.sound and layer.sound.filename=="__base__/sound/train-wheels.ogg" then
    wheels=table.deepcopy(layer)
  end
end
assert(wheels,"EM138: expected native locomotive wheel sound")
local root="__ElectrifiedMainline__/sound/electric/"
loco.working_sound={
  main_sounds={
    {sound={filename=root.."em-electric-drive-loop.ogg",volume=0.55},
     match_volume_to_activity=true,
     activity_to_volume_modifiers={multiplier=1.5,offset=0,minimum=0,maximum=1},
     match_speed_to_activity=true,
     activity_to_speed_modifiers={multiplier=0.65,offset=0.80,minimum=0.80,maximum=1.45}},
    wheels
  },
  max_sounds_per_prototype=2,
  activate_sound={filename=root.."em-electric-start.ogg",volume=0.35},
  deactivate_sound={filename=root.."em-electric-stop.ogg",volume=0.35}
}
-- Helpers are not physical locomotives; do not duplicate traction or track sounds.
for name,p in pairs(data.raw.locomotive) do
  if name:match("^em%-c5%-technical%-booster%-%d+$") then
    p.working_sound=nil
    p.drive_over_tie_trigger=nil
    p.stop_trigger=nil
  end
end
