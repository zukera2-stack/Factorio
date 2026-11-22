-- EM072 owner-scoped hidden traction helper lifecycle (EXPERIMENT ONLY).
-- The engine drives the real train. Owner destruction / decoupling retires the
-- hidden locomotive; its already paid, finite burner remainder is a physical
-- dismantling loss. Never refund to grid or mint an escrow. No train.speed writes.
local M={}
local EM="em-electric-locomotive"
local MOTOR={ ["em-motor-cargo-wagon"]=true,["em-motor-fluid-wagon"]=true }
local PREFIX="em-c5-technical-booster-"
local INTERVAL=10
local POWER={
 ["em-c5-technical-booster-500"]=500000,
 ["em-c5-technical-booster-1000"]=1000000,
 ["em-c5-technical-booster-2000"]=2000000,
}
local function live(id)
  local e=id and game.get_entity_by_unit_number(id)
  return e and e.valid and e or nil
end
local function state()
  storage.em=storage.em or {}
  storage.em.helper067=storage.em.helper067 or {}
  local s=storage.em.helper067
  s.owners=s.owners or {} -- helper unit_number -> exact EM locomotive unit_number
  s.removed_loss_J=s.removed_loss_J or 0
  s.external_loss_J=s.external_loss_J or 0
  s.external_unobserved=s.external_unobserved or 0
  s.orphan_helpers_removed=s.orphan_helpers_removed or 0
  s.cleanup_events=s.cleanup_events or 0
  s.dirty=s.dirty or false
  return s
end
local function associated(helper)
  local train=helper.train
  if not (train and train.valid) then return nil,0,0 end
  local closest,best,alternate=nil,math.huge,math.huge
  local n_motor,sum_w=0,0
  for _,car in ipairs(train.carriages) do
    if car.valid then
      if MOTOR[car.name] then n_motor=n_motor+1 end
      sum_w=sum_w+(POWER[car.name] or 0)
      if car.name==EM and car.unit_number then
        local dx=car.position.x-helper.position.x
        local dy=car.position.y-helper.position.y
        local d=dx*dx+dy*dy
        if d<best then alternate=best;best=d;closest=car
        elseif d<alternate then alternate=d end
      end
    end
  end
  -- With no established owner mapping, the physically adjacent true EM may
  -- be inferred ONLY if it is unique and within 4.5 tiles of its helper.
  if best>4.5*4.5 or math.abs(alternate-best)<0.01 then closest=nil end
  return closest,n_motor,sum_w
end
local function fuel_J(helper)
  local burner=helper and helper.valid and helper.burner
  if not burner then return 0 end
  return math.max(0,burner.remaining_burning_fuel or 0)
end
local function retire(helper,why)
  if not (helper and helper.valid and POWER[helper.name]) then return false end
  local s=state()
  local id=helper.unit_number
  local owner=s.owners[id]
  local train=helper.train
  if train and train.valid then
    local real=false
    for _,e in ipairs(train.carriages) do if e.valid and e.name==EM then real=true;break end end
    if not real then train.manual_mode=true end
  end
  local waste=fuel_J(helper)
  -- Do not copy this energy into another burner, EEI, or Lua storage reserve.
  -- It was paid for before dismantling; only the loss meter retains a number.
  s.owners[id]=nil -- Remove before raised callback; do not count as external loss twice.
  local ok=helper.destroy{raise_destroy=true}
  if not ok or helper.valid then
    s.owners[id]=owner
    error("[EM072 RETIRE FAIL] native hidden booster refused removal unit="..id)
  end
  s.orphan_helpers_removed=s.orphan_helpers_removed+1
  s.removed_loss_J=s.removed_loss_J+waste
  log(string.format("[EM072 DISMANTLE LOSS] tick=%d helper=%d owner=%s lost_J=%.3f sum_lost_J=%.3f reason=%s",
    game.tick,id,tostring(owner),waste,s.removed_loss_J,tostring(why)))
  return true
end
local function monitor(helper,why)
  local s=state()
  local id=helper.unit_number
  local owner=s.owners[id]
  local nearest,n_motor,sum_w=associated(helper)
  if not owner and nearest then
    owner=nearest.unit_number
    s.owners[id]=owner
  end
  local real=live(owner)
  if (owner and not real) or (real and (not helper.train or not real.train or
        not helper.train.valid or not real.train.valid or helper.train.id~=real.train.id))
        or not nearest and not real or n_motor==0 or sum_w>n_motor*500000 then
    retire(helper,why)
  end
end
local function snapshot_helpers()
  local helpers,seen={},{}
  if not (game.train_manager and game.train_manager.get_trains) then return helpers end
  for _,name in ipairs({"em-c5-technical-booster-500","em-c5-technical-booster-1000","em-c5-technical-booster-2000"}) do
    for _,train in pairs(game.train_manager.get_trains{stock=name}) do
      if train.valid then
        for _,car in ipairs(train.carriages) do
          if car.valid and POWER[car.name] and car.unit_number and not seen[car.unit_number] then
            seen[car.unit_number]=true
            helpers[#helpers+1]=car
          end
        end
      end
    end
  end
  table.sort(helpers,function(a,b)return a.unit_number<b.unit_number end)
  return helpers
end
function M.on_built(entity)
  if entity and entity.valid and POWER[entity.name] then
    local s=state()
    local nearest=associated(entity)
    if nearest then s.owners[entity.unit_number]=nearest.unit_number end
    s.dirty=true
  end
end
function M.on_train_created()
  state().dirty=true
end
function M.on_removed(entity)
  if not (entity and entity.valid) then return end
  local s=state()
  if POWER[entity.name] then
    -- Script/user destruction may give a pre-destruction event. Count actual
    -- measured native paid buffer as authorised loss; do not refund.
    local id=entity.unit_number
    if s.owners[id] then
      local lost=fuel_J(entity)
      s.external_loss_J=s.external_loss_J+lost
      s.owners[id]=nil
      log(string.format("[EM072 EXTERNAL HELPER LOSS] tick=%d helper=%d lost_J=%.3f",game.tick,id,lost))
    end
    return
  end
  if entity.name~=EM or not entity.unit_number then return end
  local id=entity.unit_number
  -- Native event fires while the removed true locomotive still exists.
  -- Retire only helpers that are explicitly mapped to this owner or those
  -- whose physically closest owner is this exact unit.
  local all=snapshot_helpers()
  for _,h in ipairs(all) do
    if h.valid and (s.owners[h.unit_number]==id or
      (not s.owners[h.unit_number] and (function()
        local nearest=associated(h)
        return nearest and nearest.unit_number==id
      end)())) then retire(h,"owner-removed-event") end
  end
  s.dirty=true
end
function M.on_tick(tick)
  local s=state()
  -- Fast, O(number of registered helpers), guards against native destruction
  -- with raise_destroy=false (no event) without scanning all world trains.
  local ids={}
  for id in pairs(s.owners) do ids[#ids+1]=id end
  table.sort(ids)
  for _,id in ipairs(ids) do
    local h=live(id)
    if h then monitor(h,"registered-owner-check")
    else
      -- External no-event destroy: remaining J no longer observable.
      -- Never invent a refund or pretend an exact loss amount was measured.
      s.external_unobserved=s.external_unobserved+1
      s.owners[id]=nil
      log("[EM072 UNOBSERVED LOSS] tick="..tick.." helper="..id.." no native energy snapshot")
    end
  end
  if tick%INTERVAL~=0 and not s.dirty then return end
  s.dirty=false
  for _,h in ipairs(snapshot_helpers()) do
    if h.valid then monitor(h,"native-train-reconciliation") end
  end
  if tick%60==0 then
    log(string.format("[EM072 LOSS LEDGER] tick=%d removed=%d dismantle_J=%.3f external_J=%.3f unobserved=%d",
      tick,s.orphan_helpers_removed,s.removed_loss_J,s.external_loss_J,s.external_unobserved))
  end
end
return M