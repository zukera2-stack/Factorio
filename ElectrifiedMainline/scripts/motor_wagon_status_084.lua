-- EM084: GUI-only custom status of the two genuine motor wagons.
-- Cargo and fluid wagons have no burner/fuel inventory. Their inherited train
-- status may display native "No fuel", which refers to an electric consist.
-- Never modify native train/loco status, power allocation or alerts.
local M={}
local MOTOR={['em-motor-cargo-wagon']=true,['em-motor-fluid-wagon']=true}

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

function M.refresh(entity)
  if not (entity and entity.valid and
      (entity.type=="cargo-wagon" or entity.type=="fluid-wagon") and
      MOTOR[entity.name]) then return false end
  local diode, text
  local train=entity.train
  if not has_em_locomotive(train) then
    diode=defines.entity_status_diode.red
    text={'em-motor-status.no-electric-locomotive'}
  elseif entity.status==defines.entity_status.no_fuel then
    diode=defines.entity_status_diode.red
    text={'em-traction-status.no-traction-power'}
  else
    -- Yellow means the car is part of a motor consist; NOT power confirmed.
    diode=defines.entity_status_diode.yellow
    text={'em-motor-status.from-locomotive'}
  end
  entity.custom_status={diode=diode,label=text}
  return true
end

function M.on_gui_opened(event)
  M.refresh(event.entity)
end

function M.refresh_opened_players()
  -- Limited to currently opened motor-wagon GUIs. Do not scan whole surfaces.
  for _,player in pairs(game.connected_players) do
    if player and player.valid then
      M.refresh(player.opened)
    end
  end
end

return M
