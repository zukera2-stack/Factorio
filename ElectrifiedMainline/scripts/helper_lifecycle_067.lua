-- EM072/073 EXPERIMENT: one source-paid finite-J helper per REAL EM heading.
-- Factorio itself chooses which opposing locomotive provides native traction.
-- Its energy comes exclusively from EM070 native traction sink via 065.
-- The visible cargo/fluid wagons stay native; owner is a real EM loco unit ID.
-- Dismantling dissipates already-paid helper burner J by owner's explicit policy.
local M={}
local EM='em-electric-locomotive'
local MOTOR={['em-motor-cargo-wagon']=true,['em-motor-fluid-wagon']=true}
local MAX_MOTORS=256
local PERIOD=10
local function power(name)
  if type(name)~='string' then return nil end
  local kw=tonumber(name:match('^em%-c5%-technical%-booster%-(%d+)$'))
  if kw and kw>=500 and kw<=MAX_MOTORS*500 and kw%500==0 then return kw*1000 end
  return nil
end
local function entity(id)
  local e=id and game.get_entity_by_unit_number(id)
  return e and e.valid and e or nil
end
local function state()
  storage.em=storage.em or {}
  storage.em.helper067=storage.em.helper067 or {}
  local s=storage.em.helper067
  s.owners=s.owners or {}
  s.removed_loss_J=s.removed_loss_J or 0
  s.external_loss_J=s.external_loss_J or 0
  s.external_unobserved=s.external_unobserved or 0
  s.orphan_helpers_removed=s.orphan_helpers_removed or 0
  s.cleanup_events=s.cleanup_events or 0
  s.created=s.created or 0
  s.failed=s.failed or 0
  s.deferred=s.deferred or 0
  s.dirty=s.dirty or false
  return s
end
local function n_motors(train)
  if not (train and train.valid) then return 0 end
  local n=0
  for _,e in ipairs(train.carriages) do
    if e.valid and MOTOR[e.name] then n=n+1 end
  end
  return n
end
local function helper_list(train)
  local r={}
  for _,e in ipairs(train.carriages) do
    if e.valid and power(e.name) then r[#r+1]=e end
  end
  table.sort(r,function(a,b) return a.unit_number<b.unit_number end)
  return r
end
local function real_list(train)
  local r={}
  for _,e in ipairs(train.carriages) do
    if e.valid and e.name==EM and e.unit_number then r[#r+1]=e end
  end
  table.sort(r,function(a,b)return a.unit_number<b.unit_number end)
  return r
end

-- The native train engine classifies physical headings. Only real EM
-- locomotives may authorize helpers; same-heading EMs count ONCE.
-- Do not group by LuaEntity.direction: that is 0 on native rolling stock.
local function directional_owners(train)
  local groups=train and train.valid and train.locomotives
  if not groups then return {} end
  local out={}
  for _,heading in ipairs({'front_movers','back_movers'}) do
    local best=nil
    for _,e in ipairs(groups[heading] or {}) do
      if e.valid and e.name==EM and e.unit_number and
          (not best or e.unit_number<best.unit_number) then best=e end
    end
    if best then out[#out+1]=best end
  end
  table.sort(out,function(a,b)return a.unit_number<b.unit_number end)
  return out
end
local function authorised_owners(train)
  local ids={}
  for _,e in ipairs(directional_owners(train)) do ids[e.unit_number]=true end
  return ids
end
local function fuel(e)
  return e and e.valid and e.burner and math.max(0,e.burner.remaining_burning_fuel or 0) or 0
end
local function retire(helper,reason)
  if not (helper and helper.valid and power(helper.name)) then return false end
  local s=state()
  local id=helper.unit_number
  local owner=s.owners[id]
  local j=fuel(helper)
  local train=helper.train
  if train and train.valid and #real_list(train)==0 then train.manual_mode=true end
  s.owners[id]=nil -- before destruction (including raised callback)
  local ok=helper.destroy{raise_destroy=true}
  if not ok or helper.valid then
    s.owners[id]=owner
    error('[EM072 RETIRE FAIL] helper='..tostring(id))
  end
  s.orphan_helpers_removed=s.orphan_helpers_removed+1
  s.removed_loss_J=s.removed_loss_J+j
  log(string.format('[EM072 DISMANTLE LOSS] tick=%d helper=%d owner=%s lost_J=%.3f sum_lost_J=%.3f reason=%s',
    game.tick,id,tostring(owner),j,s.removed_loss_J,tostring(reason)))
  return true
end
-- A helper is never allowed to charge simply by sitting under overhead wires.
-- It must be physically attached to exactly its registered genuine owner and
-- correspond to exactly the current native consist's MOTOR wagon count.
function M.targets()
  local s=state()
  local results,seen={},{ }
  local ids={}
  for id in pairs(s.owners) do ids[#ids+1]=id end
  table.sort(ids)
  for _,id in ipairs(ids) do
    local h=entity(id); local o=entity(s.owners[id])
    if h and o and power(h.name) and o.name==EM
      and h.force==o.force and h.surface==o.surface
      and h.train and h.train.valid and o.train and o.train.valid
      and h.train.id==o.train.id and not seen[o.unit_number] then
      local allowed=authorised_owners(h.train)
      local n=n_motors(h.train)
      if allowed[o.unit_number] and n>=1 and n<=MAX_MOTORS
         and power(h.name)==n*500000 then
        results[#results+1]={helper=h,owner=o,watts=n*500000,motors=n}
        seen[o.unit_number]=true
      end
    end
  end
  return results
end
local function dir_to_neighbor(owner,neighbor)
  -- Native 2.1 rolling-stock front/back is relative to locomotive orientation.
  local f=owner.orientation*2*math.pi
  local forward_x=math.sin(f)
  local forward_y=-math.cos(f)
  local dx=neighbor.position.x-owner.position.x
  local dy=neighbor.position.y-owner.position.y
  local dot=dx*forward_x+dy*forward_y
  return dot>0 and defines.rail_direction.front or defines.rail_direction.back
end
local function candidate(train,owner)
  -- The owner has already been chosen from native front_movers/back_movers.
  -- Prefer a native visible joint at the rear of this particular EM head.
  local found={}
  for _,near in ipairs(train.carriages) do
    if near.valid and near.unit_number~=owner.unit_number and not power(near.name) then
      local dx=near.position.x-owner.position.x
      local dy=near.position.y-owner.position.y
      local dist=math.sqrt(dx*dx+dy*dy)
      if math.abs(dist-7)<0.20 then
        local side=dir_to_neighbor(owner,near)
        found[#found+1]={owner=owner,neighbor=near,side=side,
          priority=(side==defines.rail_direction.back and 0 or 1),
          id=near.unit_number}
      end
    end
  end
  table.sort(found,function(a,b)
    if a.priority~=b.priority then return a.priority<b.priority end
    return a.id<b.id
  end)
  return found[1]
end
local function verify_visible(train,visible)
  if not (train and train.valid) then return false end
  local seen={}
  for _,c in ipairs(train.carriages) do if c.valid then seen[c.unit_number]=true end end
  for _,rec in ipairs(visible) do
    if not rec.entity.valid or not seen[rec.id] or
      math.abs(rec.x-rec.entity.position.x)>0.001 or
      math.abs(rec.y-rec.entity.position.y)>0.001 then return false end
  end
  return true
end
local function mount(train,n,chosen_owner)
  if not (train and train.valid and train.speed==0 and n>0 and n<=MAX_MOTORS) then return false end
  local spot=candidate(train,chosen_owner)
  if not spot then
    log('[EM072 MOUNT BLOCKED] tick='..game.tick..' train='..train.id..' reason=no_native_7_tile_joint')
    state().failed=state().failed+1
    return false
  end
  local owner,near=spot.owner,spot.neighbor
  local auto=not train.manual_mode
  local schedule=train.schedule
  local visible={}
  for _,e in ipairs(train.carriages) do
    if e.valid and not power(e.name) then visible[#visible+1]={entity=e,id=e.unit_number,x=e.position.x,y=e.position.y} end
  end
  local s=state()
  s.inserting=true
  local disconnected=owner.disconnect_rolling_stock(spot.side)
  if not disconnected then
    s.inserting=nil;s.failed=s.failed+1
    log('[EM072 MOUNT BLOCKED] train='..train.id..' reason=disconnect_refused')
    return false
  end
  local pos={x=(owner.position.x+near.position.x)/2,y=(owner.position.y+near.position.y)/2}
  local h=owner.surface.create_entity{name='em-c5-technical-booster-'..(500*n),
    -- LuaEntity.direction is 0 for rolling stock on rails in 2.1.24;
    -- actual engine heading is LuaEntity.orientation (0.75=west).
    position=pos,orientation=owner.orientation,force=owner.force,
    raise_built=false,create_build_effect_smoke=false}
  s.inserting=nil
  if not (h and h.valid and h.train and owner.valid and owner.train and
    h.train.valid and owner.train.valid and h.train.id==owner.train.id and
    n_motors(h.train)==n and verify_visible(h.train,visible)) then
    if h and h.valid then h.destroy() end
    if owner.valid and near.valid then owner.connect_rolling_stock(spot.side) end
    s.failed=s.failed+1
    log('[EM072 MOUNT FAIL] tick='..game.tick..' owner='..owner.unit_number..' motors='..n..' reconnected_original=true')
    return false
  end
  s.owners[h.unit_number]=owner.unit_number
  h.minable_flag=false;h.destructible=false
  if not (h.burner and fuel(h)==0) then
    retire(h,'initial-nonzero-j')
    error('[EM072 MOUNT FAIL] unpaid hidden burner starts with J')
  end
  if schedule then owner.train.schedule=schedule end
  if auto then owner.train.manual_mode=false end
  s.created=s.created+1
  log(string.format('[EM072 DIRECTIONAL AUTO MOUNT] tick=%d train=%d owner=%d helper=%d motors=%d nameplate_W=%d visible=%d mode=%s',
    game.tick,owner.train.id,owner.unit_number,h.unit_number,n,500000*n,#visible,
    auto and 'AUTO' or 'MANUAL'))
  return true
end
local function scan_real_trains()
  local trains=game.train_manager.get_trains{stock=EM}
  local tracked={}
  for _,t in pairs(trains) do
    if t.valid and not tracked[t.id] then
      tracked[t.id]=true
      local n=n_motors(t)
      local owners=directional_owners(t)
      local desired={}
      for _,o in ipairs(owners) do desired[o.unit_number]=o end
      local helpers=helper_list(t)
      -- Existing 0.1.71 helpers can be adopted on SAVE/LOAD. Never assume
      -- a helper is paid simply because it is physically in a real train.
      for _,h in ipairs(helpers) do
        if not state().owners[h.unit_number] then
          local near,best=nil,math.huge
          for _,o in ipairs(real_list(t)) do
            local dx=o.position.x-h.position.x
            local dy=o.position.y-h.position.y
            local d=math.sqrt(dx*dx+dy*dy)
            if d<4.5 and d<best then near=o;best=d end
          end
          if near then state().owners[h.unit_number]=near.unit_number end
        end
      end
      -- One helper per allowed REAL heading (not one per visible loco),
      -- and always 500kW x native motor wagons per heading, not double J.
      local found={}
      for _,h in ipairs(helpers) do
        local owner=state().owners[h.unit_number]
        if not owner or not desired[owner] or found[owner] or n<1
          or n>MAX_MOTORS or power(h.name)~=500000*n then
          if h.valid then retire(h,'invalid-or-duplicate-direction-helper') end
        else
          found[owner]=true
        end
      end
      if n>MAX_MOTORS then
        state().failed=state().failed+1
        log('[EM072 LIMIT] train='..t.id..' motor_wagons='..n..' maximum='..MAX_MOTORS..' no_claim_of_full_traction')
      elseif n>0 then
        -- Each mount invalidates the old LuaTrain. Re-query from the live
        -- owner's entity before the next insertion; preserve native schedule.
        for _,o in ipairs(owners) do
          if o.valid and not found[o.unit_number] then
            local tr=o.train
            if tr and tr.valid and tr.speed==0 then
              if mount(tr,n,o) then found[o.unit_number]=true end
            else state().deferred=state().deferred+1 end
          end
        end
      end
    end
  end
end
function M.on_built(e)
  if e and e.valid and (e.name==EM or MOTOR[e.name] or power(e.name)) then
    state().dirty=true
  end
end
function M.on_train_created(_)
  if not state().inserting then state().dirty=true end
end
function M.on_removed(e)
  if not (e and e.valid) then return end
  local s=state()
  if power(e.name) then
    local id=e.unit_number
    if s.owners[id] then
      local j=fuel(e)
      s.owners[id]=nil
      s.external_loss_J=s.external_loss_J+j
      log(string.format('[EM072 EXTERNAL HELPER LOSS] tick=%d helper=%d lost_J=%.3f',game.tick,id,j))
    end
    s.dirty=true
    return
  end
  if e.name==EM and e.unit_number then
    local owner=e.unit_number
    local ids={}
    for helper,id in pairs(s.owners) do if id==owner then ids[#ids+1]=helper end end
    table.sort(ids)
    for _,id in ipairs(ids) do
      local h=entity(id)
      if h then retire(h,'owner-removed-event') end
    end
  end
  if e.name==EM or MOTOR[e.name] then s.dirty=true end
end
function M.on_tick(tick)
  local s=state()
  local ids={}
  for id in pairs(s.owners) do ids[#ids+1]=id end
  table.sort(ids)
  for _,id in ipairs(ids) do
    local h=entity(id)
    local o=entity(s.owners[id])
    if not h then
      s.owners[id]=nil
      s.external_unobserved=s.external_unobserved+1
      log('[EM072 UNOBSERVED LOSS] tick='..tick..' helper='..id..' native J unavailable')
    elseif not o or o.name~=EM or not h.train or not o.train or
        not h.train.valid or not o.train.valid or h.train.id~=o.train.id then
      retire(h,'owner-or-train-disconnected')
    else
      local n=n_motors(h.train)
      local authorised=authorised_owners(h.train)
      if n==0 or n>MAX_MOTORS or power(h.name)~=n*500000
          or not authorised[o.unit_number] then
        retire(h,'motor-count-or-heading-changed')
      end
    end
  end
  if tick%PERIOD==0 or s.dirty then
    s.dirty=false
    scan_real_trains()
  end
  if tick%600==0 then
    log(string.format('[EM072 MOTOR STATE] tick=%d created=%d retired=%d dismantle_J=%.3f external_J=%.3f unknown=%d fails=%d deferred=%d registered=%d',
      tick,s.created,s.orphan_helpers_removed,s.removed_loss_J,s.external_loss_J,
      s.external_unobserved,s.failed,s.deferred,#M.targets()))
  end
end
return M