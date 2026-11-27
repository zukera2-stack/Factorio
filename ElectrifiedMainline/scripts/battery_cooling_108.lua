-- Visual-only cooling driven by battery state and confirmed transfers.
-- No energy mutation.
local M={}
local offsets=require('scripts.battery_fan_offsets_108')
local NAME='em-battery-wagon'
local HOLD=12
local SLOW_SPEED=0.08
local ACTIVE_SPEED={charging=0.25,discharging=0.35,recovering=0.30,idle=SLOW_SPEED}
local function valid(e) return e and e.valid and e.name==NAME and e.unit_number end
local function rows(create)
  local em=storage.em
  if not em then if not create then return nil end;storage.em={};em=storage.em end
  if not em.battery_cooling_108 and create then em.battery_cooling_108={} end
  return em.battery_cooling_108
end
local function remove_render(r)
  if r.render_id then
    local obj=rendering.get_object_by_id(r.render_id)
    if obj and obj.valid then obj.destroy() end
    r.render_id=nil;r.direction=nil
  end
end
local function ensure_row(e)
  local a=rows(true)
  local r=a[e.unit_number]
  if not r then r={entity=e};a[e.unit_number]=r end
  return r
end
local function desired_speed(mode)
  return ACTIVE_SPEED[mode] or SLOW_SPEED
end
function M.mark(e,j,mode,tick)
  if not valid(e) or j<=0 then return end
  local r=ensure_row(e)
  if r.tick~=tick then r.tick=tick;r.J=0 end
  r.mode=mode;r.J=r.J+j
end
local function seed_charged_rows(onboard,tick)
  if not onboard then return end
  for _,e in ipairs(onboard.charged_wagons()) do
    local r=ensure_row(e)
    if not r.tick then r.tick=tick-HOLD end
    if not r.mode then r.mode='idle' end
  end
end
-- Exact frame indices only. No rotating a screen-space overlay or rounding
-- to a nearby available direction.
function M.tick(tick,onboard)
  local enabled=onboard and onboard.enabled() and onboard.wagons_enabled()
  if not enabled then
    local a=rows(false);if not a then return end
    for id,r in pairs(a) do remove_render(r);a[id]=nil end
    return
  end
  if tick%30==0 then seed_charged_rows(onboard,tick) end
  local a=rows(false);if not a then return end
  for id,r in pairs(a) do
    local e=r.entity
    if not valid(e) then
      remove_render(r);a[id]=nil
    else
      local status=onboard.wagon_status(e,tick)
      local has_charge=status.J>1
      local active_recent=r.tick and tick-r.tick<HOLD
      local mode=active_recent and (r.mode or status.mode) or (has_charge and 'idle' or status.mode)
      if not has_charge and not active_recent then
        remove_render(r);a[id]=nil
      else
        local k=math.floor((e.orientation%1)*256+0.5)%256
        local off=offsets[k]
        local speed=desired_speed(mode)
        local obj=r.render_id and rendering.get_object_by_id(r.render_id)
        if not off then
          remove_render(r)
        elseif not obj or not obj.valid then
          remove_render(r)
          obj=rendering.draw_animation{animation=string.format('em-battery-fan-107-%03d',k),target={entity=e,offset=off},surface=e.surface,render_layer='higher-object-above',animation_speed=speed,animation_frame=0}
          r.render_id=obj.id;r.direction=k;r.speed=speed
        else
          if r.direction~=k then
            local phase_offset=obj.animation_offset
            obj.animation=string.format('em-battery-fan-107-%03d',k)
            obj.target={entity=e,offset=off}
            obj.animation_offset=phase_offset
            r.direction=k
          end
          if math.abs((r.speed or 0)-speed)>1e-6 then
            obj.animation_speed=speed
            r.speed=speed
          end
        end
      end
    end
  end
end
function M.remove(e)
  if not valid(e) then return end
  local a=rows(false);local r=a and a[e.unit_number]
  if r then remove_render(r);a[e.unit_number]=nil end
end
function M.refresh(e,onboard,tick)
  if not valid(e) then return end
  local s=onboard.wagon_status(e,tick)
  local diode=defines.entity_status_diode.yellow
  if not s.enabled then diode=defines.entity_status_diode.red
  elseif s.J>1 then diode=defines.entity_status_diode.green end
  if s.enabled and s.mode~='idle' then diode=defines.entity_status_diode.green end
  e.custom_status={diode=diode,label={'em-battery-status.'..s.mode,string.format('%.2f',s.J/1000000),string.format('%.2f',s.capacity_J/1000000),string.format('%.1f',100*s.J/s.capacity_J)}}
end
function M.refresh_opened(onboard,tick)
  for _,p in pairs(game.connected_players) do
    if p.valid then
      local e=p.opened
      if e and e.object_name=='LuaEntity' then M.refresh(e,onboard,tick) end
    end
  end
end
function M.snapshot(unit,onboard)
  local a=rows(false) or {};local count,drawn=0,0
  for _,r in pairs(a) do
    count=count+1
    local o=r.render_id and rendering.get_object_by_id(r.render_id)
    if o and o.valid then drawn=drawn+1 end
  end
  local r=a[unit];local o=r and r.render_id and rendering.get_object_by_id(r.render_id)
  local e=unit and game.get_entity_by_unit_number(unit)
  local s=valid(e) and onboard.wagon_status(e,game.tick) or nil
  return {active_count=count,render_count=drawn,active=r~=nil,render_valid=o and o.valid or false,direction=r and r.direction,mode=r and r.mode,last_J=r and r.J,last_tick=r and r.tick,render_speed=o and o.valid and o.animation_speed or 0,render_id=o and o.valid and o.id or nil,animation_offset=o and o.valid and o.animation_offset or nil,charge=s}
end
return M
