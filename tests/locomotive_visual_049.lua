package.path='./ElectrifiedMainline/?.lua;'..package.path
storage={};local all={};local n=0
rendering={get_object_by_id=function(id)return all[id] end}
function rendering.draw_sprite(arg)
    n=n+1;local r={id=n,valid=true,sprite=arg.sprite,arg=arg};all[n]=r
    function r.destroy()r.valid=false end
    return r
end
local M=require("scripts.pantograph_visual_049")
for i=0,255 do assert(M.frame(i/256)==i) end
assert(M.frame(.9999)==0 and M.frame(-.25)==192)
assert(M.state(0)=="down" and M.state(-.1)=="up")
assert(M.state(.0015,"up")=="up" and M.state(.0015,"down")=="down")
assert(M.state(0,"up")=="down")
local e={valid=true,name="em-electric-locomotive",unit_number=1,orientation=0,surface={index=1}}
local e2={valid=true,name=e.name,unit_number=2,orientation=.5,surface=e.surface}
local vanilla={valid=true,name="locomotive",unit_number=3}
local t={valid=true,speed=0,locos={e,e2,e,vanilla}}
local function get(t)return t.locos end
M.sync({t},get);assert(n==2 and all[1].sprite=="em-panto-052-down-000" and all[2].sprite=="em-panto-052-down-128")
assert(all[1].arg.target.entity==e and all[1].arg.target.offset[2]==-1)
M.sync({t},get);assert(n==2)
t.speed=-.1;e.orientation=.25;M.sync({t},get)
assert(n==2 and all[1].sprite=="em-panto-052-up-064")
t.speed=0;M.sync({t},get);assert(all[1].sprite=="em-panto-052-down-064")
-- Engine destroys an entity-targeted sprite on surface change or removal.
all[1].valid=false;M.sync({t},get);assert(n==3 and all[3].valid)
M.remove(e2);assert(not all[2].valid)
t.locos={e};M.sync({t},get);assert(n==3)
M.sync({},get);assert(not all[3].valid and not next(storage.em.pantograph_049))
M.sync({t},get);assert(n==4);M.clear();assert(not all[4].valid)
-- Data stage mock: replace only intended graphics fields, retain native color and wheels.
local loco={pictures={},wheels={keep=true},color={r=1},default_copy_color_from_train_stop=true,max_power="600kW",energy_source={type="void"},max_speed=1.5}
local sprites={};data={raw={locomotive={["em-electric-locomotive"]=loco}}}
function data:extend(x)sprites=x end
require("prototypes.locomotive_visual_049")
assert(#sprites==513 and sprites[1].x==0 and sprites[32].x==3584 and sprites[32].y==1536)
assert(sprites[33].x==0 and sprites[33].y==0 and sprites[33].filename:find("up%-01%.png"))
assert(sprites[256].x==3584 and sprites[256].y==1536 and sprites[256].filename:find("up%-07%.png"))
assert(sprites[513].type=="animation" and sprites[513].frame_count==24 and sprites[513].draw_as_glow and loco.icon_size==64)
local layers=loco.pictures.rotated.layers
assert(#layers==3 and layers[2].apply_runtime_tint and not layers[2].tint_as_overlay and layers[3].draw_as_shadow)
for _,l in ipairs(layers) do assert(l.direction_count==256 and l.lines_per_file==4 and #l.filenames==8 and l.line_length==8 and l.scale==.5 and not l.apply_projection and l.shift[2]==-1) end
assert(loco.wheels.keep and loco.color.r==1 and loco.default_copy_color_from_train_stop and loco.max_power=="600kW" and loco.energy_source.type=="void" and loco.max_speed==1.5)
print("049 PASS: shared 256-frame mapping, native mask/physics contract, stop/reverse/hysteresis, stable render IDs and lifecycle cleanup (mock)")
