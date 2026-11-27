-- EM125: cardinal base frames contain closed doors; native animation overlays open poses.
local p=assert(data.raw["cargo-wagon"]["em-motor-cargo-wagon"])
-- Use the same half-turn symmetry as the native Base cargo wagon.
for _,layer in ipairs(p.pictures.rotated.layers) do
  layer.direction_count=128
  layer.back_equals_front=true
  for i=8,5,-1 do layer.filenames[i]=nil end
end
local root="__ElectrifiedMainline__/graphics/entity/wagon-v2/cargo/door-"
local function anim(axis,layer)
 local a={filename=root..axis.."-"..layer..".png",width=512,height=512,frame_count=8,line_length=4,scale=0.5,shift={0,-1},usage="train"}
 if layer=="shadow" then a.draw_as_shadow=true;a.flags={"shadow"} end
 if layer=="mask" then a.flags={"mask"};a.apply_runtime_tint=true;a.tint_as_overlay=false end
 return a
end
p.horizontal_doors={layers={anim("horizontal","body"),anim("horizontal","mask"),anim("horizontal","shadow")}}
p.vertical_doors={layers={anim("vertical","body"),anim("vertical","mask"),anim("vertical","shadow")}}
log("[EM106] all-hatch native animation 8 phases, two axes; symmetric cargo body")
