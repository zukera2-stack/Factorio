-- EM080: locally rendered V3; native folded body, independent bogies and raised roof replacement.
-- Identical frame geometry/pivot for native body, color mask and script overlay.
local root="__ElectrifiedMainline__/graphics/entity/locomotive-052/"
local function layer(name)
    local files={}
    for j=0,7 do files[#files+1]=root..string.format("%s-%02d.png",name,j) end
    return {filenames=files,lines_per_file=4,width=512,height=512,direction_count=256,
        line_length=8,scale=0.5,shift={0,-1},apply_projection=false,
        dice=4,priority="high",usage="train"}
end
local body,mask,shadow=layer("body"),layer("mask"),layer("shadow")
-- 050: authored shaded grayscale mask, normal runtime pixel multiplication.
mask.flags={"mask"};mask.apply_runtime_tint=true;mask.tint_as_overlay=false
shadow.flags={"shadow"};shadow.draw_as_shadow=true
local loco=assert(data.raw.locomotive["em-electric-locomotive"])
loco.pictures={rotated={layers={body,mask,shadow}}}
-- Single two-axle bogie at each native joint. No baked wheels in body.
local bogie,bogie_shadow=layer("bogie"),layer("bogie-shadow")
-- EM081: wheel-only 256px cells, centered at the rail-plane joint.
-- Equivalent physical anchor to old 512px cells shifted by -1 tile.
for _,wheel in ipairs({bogie,bogie_shadow}) do
    wheel.width=256;wheel.height=256;wheel.shift={0,0}
end
bogie_shadow.flags={"shadow"};bogie_shadow.draw_as_shadow=true
loco.wheels={rotated={layers={bogie,bogie_shadow}}}
-- Physics, item, color and rail orientation policy remain inherited.
-- Down sprites are fully transparent; folded collector is already in body.
-- Up sprites replace the folded roof region with the independently rendered raised state.
-- No headlights or human cabin in the approved autonomous concept.
loco.front_light=nil
loco.front_light_pictures=nil
loco.back_light=nil
loco.stand_by_light=nil
loco.water_reflection=nil
local sprites={}
for _,state in ipairs({"up","down"}) do
    for i=0,255 do
        sprites[#sprites+1]={type="sprite",name=string.format("em-panto-052-%s-%03d",state,i),
            filename=root..string.format("pantograph-%s-%02d.png",state,math.floor(i/32)),width=512,height=512,
            x=(i%8)*512,y=math.floor((i%32)/8)*512,scale=0.5,priority="high"}
    end
end
-- Base accumulator discharge glow only (no accumulator body or power).
sprites[#sprites+1]={type="animation",name="em-panto-discharge-052",
    filename="__base__/graphics/entity/accumulator/accumulator-discharge.png",
    width=174,height=214,line_length=6,frame_count=24,scale=.5,draw_as_glow=true,priority="high"}
data:extend(sprites)
local function icon(p)
    if p then p.icons=nil;p.icon=root.."icon.png";p.icon_size=64 end
end
icon(loco)
icon(data.raw.item and data.raw.item["em-electric-locomotive"])
icon(data.raw.recipe and data.raw.recipe["em-electric-locomotive"])
icon(data.raw.technology and data.raw.technology["em-high-speed-locomotive"])
