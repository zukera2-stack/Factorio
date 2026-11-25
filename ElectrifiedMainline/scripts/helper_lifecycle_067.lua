-- EM077: source-paid finite-J helpers, one per 200 motor wagons per real heading.
-- Factorio itself chooses which opposing locomotive provides native traction.
-- Its energy comes exclusively from EM070 native traction sink via 065.
-- The visible cargo/fluid wagons stay native; owner is a real EM loco unit ID.
-- Dismantling dissipates already-paid helper burner J by owner's explicit policy.
local M={}
local EM='em-electric-locomotive'
local MOTOR={['em-motor-cargo-wagon']=true,['em-motor-fluid-wagon']=true}
-- Preserve all 256 historical prototypes for save compatibility. New blocks use <=200.
local MAX_PROTOTYPE_MOTORS=256
local BLOCK_MOTORS=200
local PERIOD=10
-- Each added hidden locomotive must occupy a DIFFERENT actual native coupling.
local function blocks(n)
  local t={}
  while n>=BLOCK_MOTORS do
    t[#t+1]=BLOCK_MOTORS*500000
    n=n-BLOCK_MOTORS
  end
  if n>0 then t[#t+1]=n*500000 end
  return t
end
local function counts(n)
  local t={}
  for _,w in ipairs(blocks(n)) do t[w]=(t[w] or 0)+1 end
  return t
end
local function power(name)
  if type(name)~='string' then return nil end
  local kw=tonumber(name:match('^em%-c5%-technical%-booster%-(%d+)$'))
  if kw and kw>=500 and kw<=MAX_PROTOTYPE_MOTORS*500 and kw%500==0 then return kw*1000 end
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
  -- Do not decouple a moving physical train during reconfiguration.
  -- Targets stop receiving paid energy immediately when their block is stale.
  local tr=helper.train
  if tr and tr.valid and tr.speed~=0 and reason~='owner-removed-event'
      and reason~='owner-or-train-disconnected' then
    s.deferred=s.deferred+1
    return false
  end
  local j=fuel(helper)
  local train=helper.train
  if train and train.valid and #real_list(train)==0 then train.manual_mode=true end
  -- Removing a hidden rolling-stock splits the native train! Rejoin its
  -- original two adjacent real carriages (the insertion did not move them).
  -- This matters for 201->202 wagon rebuild and for owner reassignment.
  local left=helper.get_connected_rolling_stock(defines.rail_direction.front)
  local right=helper.get_connected_rolling_stock(defines.rail_direction.back)
  local function side_to(a,target)
    if not (a and a.valid and target and target.valid) then return nil end
    for _,d in ipairs({defines.rail_direction.front,defines.rail_direction.back}) do
      local b=a.get_connected_rolling_stock(d)
      if b and b.valid and b.unit_number==target.unit_number then return d end
    end
  end
  local left_side=side_to(left,helper)
  local right_side=side_to(right,helper)
  s.owners[id]=nil -- before destruction (including raised callback)
  local ok=helper.destroy{raise_destroy=true}
  if not ok or helper.valid then
    s.owners[id]=owner
    error('[EM072 RETIRE FAIL] helper='..tostring(id))
  end
  if left and left.valid and right and right.valid and left_side and right_side then
    -- Never write train.speed; native join keeps rolling-stock position intact.
    local connected=left.connect_rolling_stock(left_side)
    if not connected then connected=right.connect_rolling_stock(right_side) end
    if not connected or not left.train or not right.train or
       left.train.id~=right.train.id then
      error('[EM077 REJOIN FAIL] helper='..id..' from='..left.unit_number..' to='..right.unit_number)
    end
    log(string.format('[EM077 REJOIN] tick=%d helper=%d from=%d to=%d',
      game.tick,id,left.unit_number,right.unit_number))
  end
  s.orphan_helpers_removed=s.orphan_helpers_removed+1
  s.removed_loss_J=s.removed_loss_J+j
  log(string.format('[EM072 DISMANTLE LOSS] tick=%d helper=%d owner=%s lost_J=%.3f sum_lost_J=%.3f reason=%s',
    game.tick,id,tostring(owner),j,s.removed_loss_J,tostring(reason)))
  return true
end
-- ONLY registered, correctly sized, direction-authorised blocks can receive paid J.
-- For 401 motor wagons: [100MW,100MW,0.5MW] per physical heading.
function M.targets()
  local s=state()
  local results,used,cache={},{},{}
  local ids={}
  for id in pairs(s.owners) do ids[#ids+1]=id end
  table.sort(ids)
  for _,id in ipairs(ids) do
    local h=entity(id);local o=entity(s.owners[id])
    if h and o and power(h.name) and o.name==EM and
      h.force==o.force and h.surface==o.surface and
      h.train and h.train.valid and o.train and o.train.valid and
      h.train.id==o.train.id then
      local tr=h.train
      local k=tr.id
      local c=cache[k]
      if not c then
        c={allowed=authorised_owners(tr),needed=counts(n_motors(tr))}
        cache[k]=c
      end
      local watts=power(h.name)
      local owner=o.unit_number
      if c.allowed[owner] and (c.needed[watts] or 0)>0 then
        used[owner]=used[owner] or {}
        local seen=used[owner]
        if (seen[watts] or 0)<c.needed[watts] then
          seen[watts]=(seen[watts] or 0)+1
          results[#results+1]={helper=h,owner=o,watts=watts,motors=n_motors(tr)}
        end
      end
    end
  end
  return results
end
local function candidate(train,owner)
  -- Find an EMPTY native 7-tile coupling between two visible rolling stocks.
  -- A second helper cannot be inserted into the original half-sized gap.
  local options,used={},{ }
  for _,a in ipairs(train.carriages) do
    if a.valid and not power(a.name) then
      for _,side in ipairs({defines.rail_direction.back,defines.rail_direction.front}) do
        local b=a.get_connected_rolling_stock(side)
        if b and b.valid and not power(b.name) then
          local key=math.min(a.unit_number,b.unit_number)..':'..math.max(a.unit_number,b.unit_number)
          if not used[key] then
            used[key]=true
            local dx=a.position.x-b.position.x
            local dy=a.position.y-b.position.y
            local dist=math.sqrt(dx*dx+dy*dy)
            if math.abs(dist-7)<0.20 then
              local midx=(a.position.x+b.position.x)/2
              local midy=(a.position.y+b.position.y)/2
              local ox=midx-owner.position.x
              local oy=midy-owner.position.y
              options[#options+1]={a=a,b=b,side=side,
                x=midx,y=midy,dist2=ox*ox+oy*oy,
                prefer=(a.unit_number==owner.unit_number or b.unit_number==owner.unit_number) and 0 or 1,
                key=key}
            end
          end
        end
      end
    end
  end
  table.sort(options,function(a,b)
    if a.prefer~=b.prefer then return a.prefer<b.prefer end
    if a.dist2~=b.dist2 then return a.dist2<b.dist2 end
    return a.key<b.key
  end)
  return options[1]
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
local function mount(train,n,chosen_owner,watts)
  if not (train and train.valid and train.speed==0 and n>0 and
     watts and watts>=500000 and watts<=BLOCK_MOTORS*500000 and watts%500000==0) then return false end
  local spot=candidate(train,chosen_owner)
  if not spot then
    log('[EM072 MOUNT BLOCKED] tick='..game.tick..' train='..train.id..' reason=no_free_native_7_tile_joint')
    state().failed=state().failed+1
    return false
  end
  local owner,near=spot.a,spot.b
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
  local pos={x=spot.x,y=spot.y}
  local h=owner.surface.create_entity{name='em-c5-technical-booster-'..(watts/1000),
    -- LuaEntity.direction is 0 for rolling stock on rails in 2.1.24;
    -- actual engine heading is LuaEntity.orientation (0.75=west).
    position=pos,orientation=chosen_owner.orientation,force=owner.force,
    raise_built=false,create_build_effect_smoke=false}
  s.inserting=nil
  if not (h and h.valid and h.train and owner.valid and owner.train and
    h.train.valid and owner.train.valid and near.train and near.train.valid and
    h.train.id==owner.train.id and h.train.id==near.train.id and
    chosen_owner.valid and chosen_owner.train and chosen_owner.train.id==h.train.id and
    n_motors(h.train)==n and verify_visible(h.train,visible)) then
    if h and h.valid then h.destroy() end
    if owner.valid and near.valid then owner.connect_rolling_stock(spot.side) end
    s.failed=s.failed+1
    log('[EM072 MOUNT FAIL] tick='..game.tick..' owner='..owner.unit_number..' motors='..n..' reconnected_original=true')
    return false
  end
  s.owners[h.unit_number]=chosen_owner.unit_number
  h.minable_flag=false;h.destructible=false;h.operable=false
  if not (h.burner and fuel(h)==0) then
    retire(h,'initial-nonzero-j')
    error('[EM072 MOUNT FAIL] unpaid hidden burner starts with J')
  end
  if schedule then owner.train.schedule=schedule end
  if auto then owner.train.manual_mode=false end
  s.created=s.created+1
  log(string.format('[EM077 BLOCK AUTO MOUNT] tick=%d train=%d owner=%d helper=%d motors=%d nameplate_W=%d visible=%d mode=%s',
    game.tick,chosen_owner.train.id,chosen_owner.unit_number,h.unit_number,n,watts,#visible,
    auto and 'AUTO' or 'MANUAL'))
  return true
end
local function group_owner(train,helper)
  -- Recover distant helpers on SAVE/LOAD using FACTORIO native headings,
  -- rather than proximity to the locomotive (can be 1400+ tiles apart).
  local groups=train.locomotives
  if not groups then return nil end
  for _,heading in ipairs({'front_movers','back_movers'}) do
    local contains=false
    local best=nil
    for _,c in ipairs(groups[heading] or {}) do
      if c.valid and c.unit_number==helper.unit_number then contains=true end
      if c.valid and c.name==EM and c.unit_number and
         (not best or c.unit_number<best.unit_number) then best=c end
    end
    if contains then return best end
  end
  return nil
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
      local needed=counts(n)
      local helpers=helper_list(t)
      local s=state()
      -- Adopt saved hidden locomotives, including remote blocks within a long
      -- train. The engine heading, not Euclidean proximity, chooses owner.
      for _,h in ipairs(helpers) do
        -- Apply to retained helpers from older saves as well as new helpers.
        h.minable_flag=false;h.destructible=false;h.operable=false
        if not s.owners[h.unit_number] then
          local chosen=group_owner(t,h)
          if chosen then s.owners[h.unit_number]=chosen.unit_number end
        end
      end
      local kept={}
      for _,h in ipairs(helpers) do
        local owner=s.owners[h.unit_number]
        local watts=power(h.name)
        if owner then kept[owner]=kept[owner] or {} end
        local assigned=owner and kept[owner] or {}
        if not owner or not desired[owner] or not watts or
            (assigned[watts] or 0)>=(needed[watts] or 0) then
          if h.valid then retire(h,'invalid-duplicate-or-wrong-block') end
        else
          assigned[watts]=(assigned[watts] or 0)+1
        end
      end
      if n>0 then
        for _,o in ipairs(owners) do
          if o.valid then
            local assigned=kept[o.unit_number] or {}
            -- Do not assume the original LuaTrain reference survives a split.
            for _,watts in ipairs(blocks(n)) do
              local available=assigned[watts] or 0
              if available>0 then
                assigned[watts]=available-1
              else
                local tr=o.train
                if tr and tr.valid and tr.speed==0 then
                  if not mount(tr,n,o,watts) then break end
                else
                  s.deferred=s.deferred+1
                  break
                end
              end
            end
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
      local required=counts(n)
      if n==0 or not required[power(h.name)] or
          not authorised[o.unit_number] then
        retire(h,'motor-count-or-heading-changed')
      end
    end
  end
  if tick%PERIOD==0 or s.dirty then
    s.dirty=false
    scan_real_trains()
  end
  if tick%600==0 then
    log(string.format('[EM077 MOTOR STATE] tick=%d created=%d retired=%d dismantle_J=%.3f external_J=%.3f unknown=%d fails=%d deferred=%d registered=%d',
      tick,s.created,s.orphan_helpers_removed,s.removed_loss_J,s.external_loss_J,
      s.external_unobserved,s.failed,s.deferred,#M.targets()))
  end
end
return M