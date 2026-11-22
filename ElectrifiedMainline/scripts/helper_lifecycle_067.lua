-- EM067 isolated zero-J C5 hidden helper cleanup. NOT an energy-delivering
-- wagon booster and NOT general train-speed or stock mutation.
-- The exact experimental helper is permitted only in a native train
-- carrying at least one REAL em-electric-locomotive. Once its owner
-- disappears or the helper is split away, free the orphan deterministically.
local M={}
local HIDDEN="em-c5-technical-booster-1000"
local REAL="em-electric-locomotive"
local PERIOD=10
local function stats()
  storage.em=storage.em or {}
  storage.em.helper067=storage.em.helper067 or
    {orphan_helpers_removed=0,charged_orphans_unresolved=0}
  return storage.em.helper067
end
function M.on_tick(tick)
  if tick%PERIOD~=0 then return end
  if not (game.train_manager and game.train_manager.get_trains) then return end
  local st=stats()
  local to_remove={}
  for _,train in pairs(game.train_manager.get_trains{stock=HIDDEN}) do
    if train.valid then
      local has_real_owner=false
      local helpers={}
      for _,car in ipairs(train.carriages) do
        if car.valid and car.name==REAL then has_real_owner=true end
        if car.valid and car.name==HIDDEN then helpers[#helpers+1]=car end
      end
      if not has_real_owner then
        for _,h in ipairs(helpers) do to_remove[#to_remove+1]=h end
      end
    end
  end
  table.sort(to_remove,function(a,b)return a.unit_number<b.unit_number end)
  for _,helper in ipairs(to_remove) do
    if helper.valid then
      local energy=helper.burner and
        math.max(0,helper.burner.remaining_burning_fuel or 0) or 0
      if energy>0.5 then
        -- Must NEVER silently destroy real paid J from a future wagon booster.
        -- This module is only allowed for the present 0J C5 GUI adapter.
        st.charged_orphans_unresolved=st.charged_orphans_unresolved+1
        log(string.format("[EM067 ORPHAN BLOCKED] tick=%d helper=%d hidden_J=%.3f; positive-energy refund contract NOT implemented",
          tick,helper.unit_number,energy))
      else
        local id=helper.unit_number
        helper.destroy{raise_destroy=true}
        if helper.valid then
          error("[EM067 ORPHAN FAIL] native helper refused destroy: "..id)
        end
        st.orphan_helpers_removed=st.orphan_helpers_removed+1
        log(string.format("[EM067 ORPHAN REMOVED] tick=%d helper=%d hidden_J=0 native_locomotive_only_cleanup=true",
          tick,id))
      end
    end
  end
  if tick%60==0 then
    log(string.format("[EM067 LIFECYCLE] tick=%d removed=%d charged_unresolved=%d",
      tick,st.orphan_helpers_removed,st.charged_orphans_unresolved))
  end
end
return M
