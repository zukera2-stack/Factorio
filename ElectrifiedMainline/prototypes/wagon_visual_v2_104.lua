-- V2 static art only. Native cargo/fluid gameplay and EM082 locomotive wheels unchanged.
local root="__ElectrifiedMainline__/graphics/entity/wagon-v2/"
local function layer(kind,name)
  local files={}
  for i=0,7 do files[#files+1]=root..kind.."/"..string.format("%s-%02d.png",name,i) end
  return {filenames=files,lines_per_file=4,width=512,height=512,direction_count=256,
    line_length=8,scale=0.5,shift={0,-1},apply_projection=false,back_equals_front=false,
    dice=4,priority="high",usage="train"}
end
local loco=assert(data.raw.locomotive["em-electric-locomotive"])
local function apply(type_name,entity_name,kind)
  local p=assert(data.raw[type_name][entity_name])
  assert(p.joint_distance==4 and p.connection_distance==3,"V2 requires native joint geometry")
  local body,mask,shadow=layer(kind,"body"),layer(kind,"mask"),layer(kind,"shadow")
  mask.flags={"mask"};mask.apply_runtime_tint=true;mask.tint_as_overlay=false
  shadow.flags={"shadow"};shadow.draw_as_shadow=true
  p.pictures={rotated={layers={body,mask,shadow}}}
  p.color={r=0.92,g=0.07,b=0,a=1}
  p.wheels=table.deepcopy(assert(loco.wheels))
  -- The closed V2 body includes its own hatches. Vanilla doors would double-render.
  -- Native animated door mapping is a separate visual acceptance gate.
  p.horizontal_doors=nil;p.vertical_doors=nil
  local function icon(proto)
    if proto then proto.icons=nil;proto.icon=root..kind.."/icon.png";proto.icon_size=64 end
  end
  icon(p);icon(assert(data.raw["item-with-entity-data"][entity_name]));icon(assert(data.raw.recipe[entity_name]))
  log("[V2 WAGON 104] static art "..entity_name.." native joints and EM082 wheels")
end
apply("cargo-wagon","em-motor-cargo-wagon","cargo")
apply("fluid-wagon","em-motor-fluid-wagon","tank")

-- EM126: valve coordinates match calibrated body frames; original model untouched.
local tank=assert(data.raw["fluid-wagon"]["em-motor-fluid-wagon"])
tank.tank_spacing=1.7293
tank.valve_to_valve_offset_when_horizontal={1.7293,0}
tank.valve_to_valve_offset_when_vertical={0,1.4436}
tank.base_valve_xy_offset_when_horizontal={0,0}
tank.base_valve_xy_offset_when_vertical={0,0}
tank.base_valve_z_offset_projected_when_horizontal=-1.4708
tank.base_valve_z_offset_projected_when_vertical=-1.4648
