-- EM132: night headlight for the EM locomotive. Uses rendering so the light
-- can depend on actual traction availability instead of only prototype data.
local M={}
local EM='em-electric-locomotive'
local DARKNESS_THRESHOLD=0.45
local CHARGE_EPSILON=1
local BEAM_CENTER=7.5 -- tiles ahead; provisional visual calibration
local LIGHT_SCALE=1.65
local LIGHT_INTENSITY=0.95
local function rows(create)
  local em=storage.em
  if not em then if not create then return nil end;storage.em={};em=storage.em end
  if not em.locomotive_headlight_132 and create then em.locomotive_headlight_132={} end
  return em.locomotive_headlight_132
end
local function valid(e)
  return e and e.valid and e.name==EM and e.unit_number and e.surface
end
local function remove_row(id,r)
  if r and r.render_id then
    local obj=rendering.get_object_by_id(r.render_id)
    if obj and obj.valid then obj.destroy() end
  end
  local a=rows(false)
  if a and id then a[id]=nil end
end
function M.clear()
  local a=rows(false);if not a then return end
  for id,r in pairs(a) do remove_row(id,r) end
end
local function ensure_row(e)
  local a=rows(true)
  local r=a[e.unit_number]
  if not r then r={entity=e};a[e.unit_number]=r end
  return r
end
-- Only energy already present in the real locomotive or its own store is
-- evidence of power. Physical contact alone is not proof of available J.
function M.power_available(e,onboard,reserve)
  return valid(e) and (reserve.total(e)>CHARGE_EPSILON or onboard.has_charge(e,CHARGE_EPSILON))
end
local function beam_target(e)
  local a=e.orientation*2*math.pi
  return {entity=e,offset={BEAM_CENTER*math.sin(a),-BEAM_CENTER*math.cos(a)}}
end
local function update_locomotive(e,onboard,reserve)
  local a=rows(false)
  local r=a and a[e.unit_number]
  if e.surface.darkness<DARKNESS_THRESHOLD or not M.power_available(e,onboard,reserve) then
    if r then remove_row(e.unit_number,r) end
    return
  end
  r=ensure_row(e)
  local obj=r.render_id and rendering.get_object_by_id(r.render_id)
  if not obj or not obj.valid then
    -- oriented=true already follows the entity; orientation=0 adds no rotation.
    obj=rendering.draw_light{sprite='utility/light_cone',oriented=true,orientation=0,scale=LIGHT_SCALE,intensity=LIGHT_INTENSITY,minimum_darkness=DARKNESS_THRESHOLD,color={r=1.0,g=0.95,b=0.82},target=beam_target(e),surface=e.surface}
    r.render_id=obj.id;r.orientation=e.orientation
  elseif r.orientation~=e.orientation then
    obj.target=beam_target(e);r.orientation=e.orientation
  end
end
function M.tick(trains,get_locomotives,onboard,reserve)
  local seen={}
  for _,train in pairs(trains) do
    if train.valid then
      for _,e in pairs(get_locomotives(train)) do
        if valid(e) and not seen[e.unit_number] then
          seen[e.unit_number]=true
          update_locomotive(e,onboard,reserve)
        end
      end
    end
  end
  local a=rows(false);if not a then return end
  for id,r in pairs(a) do
    if not seen[id] then remove_row(id,r) end
  end
end
function M.on_removed(entity)
  if valid(entity) then
    local a=rows(false);local r=a and a[entity.unit_number]
    if r then remove_row(entity.unit_number,r) end
  end
end
return M
