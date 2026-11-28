-- EM139: two motor layers using vanilla activity mixing. Preserve EM138 drive tone/pitch.
-- Audio only. No runtime energy or train control changes.
local loco=assert(data.raw.locomotive["em-electric-locomotive"])
local original=assert(loco.working_sound)
local drive,idle,wheels
for _,layer in ipairs(original.main_sounds or {}) do
  local f=layer.sound and layer.sound.filename
  if f=="__base__/sound/train-engine-driving.ogg" then drive=table.deepcopy(layer)
  elseif f=="__base__/sound/train-engine.ogg" then idle=table.deepcopy(layer)
  elseif f=="__base__/sound/train-wheels.ogg" then wheels=table.deepcopy(layer) end
end
assert(drive and idle and wheels,"EM139: expected native locomotive sound layers")
local root="__ElectrifiedMainline__/sound/electric/"
drive.sound.filename=root.."em-electric-drive-loop.ogg"
drive.sound.volume=0.86587
-- Preserve the owner-approved EM138 pitch range; volume activity follows vanilla.
drive.activity_to_speed_modifiers={multiplier=0.65,offset=0.80,minimum=0.80,maximum=1.45}
idle.sound.filename=root.."em-electric-idle-loop.ogg"
idle.sound.volume=0.34847
loco.working_sound=table.deepcopy(original)
loco.working_sound.main_sounds={drive,idle,wheels}
loco.working_sound.activate_sound.filename=root.."em-electric-start.ogg"
loco.working_sound.activate_sound.volume=0.73462
loco.working_sound.deactivate_sound.filename=root.."em-electric-stop.ogg"
loco.working_sound.deactivate_sound.volume=0.68456
-- Helpers are not physical locomotives; do not duplicate traction or track sounds.
for name,p in pairs(data.raw.locomotive) do
  if name:match("^em%-c5%-technical%-booster%-%d+$") then
    p.working_sound=nil
    p.drive_over_tie_trigger=nil
    p.stop_trigger=nil
  end
end
