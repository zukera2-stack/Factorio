-- EM133: one presentation path for selected/opened motor wagons.
-- The native UI may report "No fuel" for electric rolling stock. Override the
-- opened entity status with EM-specific text, but never change native traction,
-- alerts, inventories or train state.
local M={}
local MOTOR={['em-motor-cargo-wagon']=true,['em-motor-fluid-wagon']=true,['em-battery-wagon']=true}

local function is_motor_wagon(entity)
  return entity and entity.valid and entity.object_name=='LuaEntity' and entity.unit_number and MOTOR[entity.name]
    and (entity.type=='cargo-wagon' or entity.type=='fluid-wagon')
end

local function has_em_locomotive(train)
  if not (train and train.valid) then return false end
  local sides=train.locomotives
  if not sides then return false end
  for _,list in pairs({sides.front_movers or {},sides.back_movers or {}}) do
    for _,loco in pairs(list) do
      if loco.valid and loco.name=='em-electric-locomotive' then return true end
    end
  end
  return false
end

function M.refresh(entity,onboard,cooling,tick)
  if not is_motor_wagon(entity) then return false end
  if entity.name=='em-battery-wagon' then
    cooling.refresh(entity,onboard,tick)
    return true
  end
  local diode, text
  local train=entity.train
  if not has_em_locomotive(train) then
    diode=defines.entity_status_diode.red
    text={'em-motor-status.no-electric-locomotive'}
  elseif entity.status==defines.entity_status.no_fuel then
    diode=defines.entity_status_diode.red
    text={'em-traction-status.no-traction-power'}
  else
    diode=defines.entity_status_diode.yellow
    text={'em-motor-status.from-locomotive'}
  end
  entity.custom_status={diode=diode,label=text}
  return true
end

-- Refresh both hover tooltip and opened entity; player.opened may be a GUI object.
function M.refresh_player(player,onboard,cooling,tick)
  if not (player and player.valid) then return end
  M.refresh(player.selected,onboard,cooling,tick)
  if player.opened~=player.selected then M.refresh(player.opened,onboard,cooling,tick) end
end
function M.refresh_players(onboard,cooling,tick)
  for _,player in pairs(game.connected_players) do
    M.refresh_player(player,onboard,cooling,tick)
  end
end
function M.reconcile(onboard,cooling,tick)
  -- Once on configuration change, including standalone/uncoupled wagons.
  for _,surface in pairs(game.surfaces) do
    for _,e in pairs(surface.find_entities_filtered{name={'em-motor-cargo-wagon','em-motor-fluid-wagon','em-battery-wagon'}}) do
      M.refresh(e,onboard,cooling,tick)
    end
  end
end
return M
