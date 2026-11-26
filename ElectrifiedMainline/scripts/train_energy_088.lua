-- EM088: one accounted transfer boundary for the logical train energy bus.
-- Persistent history belongs to real locomotive unit_number, NEVER train.id.
-- Membership is derived from native consists, no stored authority or energy
-- follows a transient train ID. Battery/regen disabled until separately proven.
local M={}
local regen091=require("scripts.brake_recovery_091")
local EM="em-electric-locomotive"
local FUEL="em-c5-test-internal-joule-063"
local function ensure(stats)
  storage.em=storage.em or {}
  local b=storage.em.train_energy_088
  if not b then
    -- Historical credits from earlier versions cannot be attributed reliably.
    b={legacy_paid_J=stats.debited_J or 0,legacy_motor_J=stats.motor_paid_J or 0,
       retired_loco_J=0,retired_motor_J=0,owners={}}
    storage.em.train_energy_088=b
  end
  return b
end
function M.transfer_grid_to_burner(req,stats,native)
  local amount=req.grant
  if amount<=0 then return end
  local output=req.native_sink
  if not (output and output.valid and req.e.valid and req.source.output
    and req.source.output.valid and req.source.line_port.valid
    and output.electric_network_id==req.source.line_port.electric_network_id) then
    error("[EM068 NATIVE FAIL] paid native sink or true locomotive invalid")
  end
  local owner=req.owner
  if not (owner and owner.valid and owner.name==EM and owner.train and req.e.train
    and owner.train.id==req.e.train.id and owner.force==req.e.force
    and owner.surface==req.e.surface) then
    error("[EM088] invalid live energy bus membership")
  end
  local burner=req.burner
  local old=math.max(0,burner.remaining_burning_fuel or 0)
  amount=math.max(0,math.min(amount,req.limit,req.cap-old,
                            output.energy))
  if amount<=0 then return end
  if not burner.currently_burning then
    -- The native API initialises a new fuel item at full fuel_value.
    -- Set its J to zero in the SAME synchronous tick before any paid credit.
    burner.currently_burning=prototypes.item[FUEL]
    burner.remaining_burning_fuel=0
    old=0
  end
  local before=output.energy
  -- This is now an ACTUAL engine-charged 25kV SECONDARY INPUT consumer.
  -- Factorio's native solver already deducted source EEI energy to fill it.
  -- Debit ONLY this native sink before credit to locomotive burner.
  -- DO NOT subtract source.output.energy again (no double charge).
  output.energy=before-amount
  local after=output.energy
  if after< -0.0001 or math.abs((before-after)-amount)>0.05 then
    error("[EM066 PAID FAIL] real source debit mismatched native grant")
  end
  burner.remaining_burning_fuel=old+amount
  if math.abs(burner.remaining_burning_fuel-(old+amount))>0.05 then
    error("[EM066 PAID FAIL] native burner credit mismatch")
  end
  local ledger=ensure(stats)
  local id=owner.unit_number
  local row=ledger.owners[id]
  if not row then row={loco_J=0,motor_J=0};ledger.owners[id]=row end
  if req.kind=="motor" then row.motor_J=row.motor_J+amount else row.loco_J=row.loco_J+amount end
  stats.debited_J=stats.debited_J+amount
  native.metered_native_J=native.metered_native_J+amount
  stats.credited_J=stats.credited_J+amount
  stats.charged_ticks=stats.charged_ticks+1
  if req.kind=="motor" then
    stats.motor_paid_J=(stats.motor_paid_J or 0)+amount
    stats.motor_grants=(stats.motor_grants or 0)+1
  end
  regen091.credit(req.e,amount)
  return amount
end

-- Debit the finite physical onboard store before crediting the native burner.
-- Grid-history counters are deliberately unchanged.
function M.transfer_store_to_burner(req,donor,row,amount)
  local owner,e=req.owner,req.e
  if not (donor and donor.valid and donor.name==EM and owner and owner.valid and owner.name==EM
    and e and e.valid and donor.train and donor.train.valid and owner.train and owner.train.valid and e.train and e.train.valid
    and donor.train.id==owner.train.id and owner.train.id==e.train.id
    and donor.force==e.force and owner.force==e.force and donor.surface==e.surface and owner.surface==e.surface) then return 0 end
  local burner=req.burner;local old=math.max(0,burner.remaining_burning_fuel or 0)
  amount=math.max(0,math.min(amount,row.J,req.limit-(req.grid_paid or 0),req.cap-old))
  if amount<=0 then return 0 end
  if not burner.currently_burning then
    burner.currently_burning=prototypes.item[FUEL];burner.remaining_burning_fuel=0;old=0
  end
  row.J=row.J-amount
  burner.remaining_burning_fuel=old+amount
  if math.abs(burner.remaining_burning_fuel-(old+amount))>0.05 then error("[EM089] native burner credit mismatch") end
  regen091.credit(req.e,amount)
  return amount
end

-- A periodic audit retires history, not actual energy; never transfers J.
function M.audit(stats)
  local b=ensure(stats)
  local ids={}
  for id in pairs(b.owners) do ids[#ids+1]=id end
  table.sort(ids)
  local l,m=b.retired_loco_J,b.retired_motor_J
  for _,id in ipairs(ids) do
    local row=b.owners[id]
    local e=game.get_entity_by_unit_number(id)
    if not (e and e.valid and e.name==EM) then
      b.retired_loco_J=b.retired_loco_J+row.loco_J
      b.retired_motor_J=b.retired_motor_J+row.motor_J
      b.owners[id]=nil
    end
    l=l+row.loco_J;m=m+row.motor_J
  end
  local total=b.legacy_paid_J+l+m
  local motor=b.legacy_motor_J+m
  -- Floating-point summation order differs from the original cumulative ledger.
  local tolerance=math.max(0.05,math.abs(total)*1e-10)
  if math.abs(total-(stats.debited_J or 0))>tolerance or
     math.abs(motor-(stats.motor_paid_J or 0))>tolerance then
    error("[EM088] energy transfer history mismatch")
  end
end
-- Read-only QA view; native train membership is queried live, even after split.
-- These counters are cumulative credited energy, NOT battery state or consumption.
function M.snapshot(unit)
  local em=storage.em or {}
  local stats=em.traction_paid_065 or {}
  local b=em.train_energy_088
  local rows=b and b.owners or {}
  local l,m=0,0
  local ids={};for id in pairs(rows) do ids[#ids+1]=id end;table.sort(ids)
  for _,id in ipairs(ids) do l=l+rows[id].loco_J;m=m+rows[id].motor_J end
  local legacy=b and b.legacy_paid_J or (stats.debited_J or 0)
  local legacy_motor=b and b.legacy_motor_J or (stats.motor_paid_J or 0)
  local rl=b and b.retired_loco_J or 0
  local rm=b and b.retired_motor_J or 0
  local result={legacy_paid_J=legacy,legacy_motor_J=legacy_motor,retired_loco_J=rl,
    retired_motor_J=rm,live_loco_J=l,live_motor_J=m,paid_J=legacy+rl+rm+l+m,
    motor_paid_J=legacy_motor+rm+m,original_paid_J=stats.debited_J or 0,
    battery_enabled=settings and settings.global and settings.global["em089-experimental-onboard-storage"] and settings.global["em089-experimental-onboard-storage"].value==true or false,regen_enabled=regen091.enabled(),owners={}}
  if not unit then return result end
  local e=game.get_entity_by_unit_number(unit)
  if not (e and e.valid and e.name==EM and e.train and e.train.valid) then return result end
  local tr=e.train;result.train_id=tr.id
  local groups=tr.locomotives
  for _,heading in ipairs({"front_movers","back_movers"}) do
    for _,o in ipairs(groups[heading] or {}) do
      if o.valid and o.name==EM then
        local row=rows[o.unit_number]
        result.owners[#result.owners+1]={unit=o.unit_number,loco_J=row and row.loco_J or 0,
          motor_J=row and row.motor_J or 0,burner_J=o.burner and o.burner.remaining_burning_fuel or 0}
      end
    end
  end
  table.sort(result.owners,function(a,b)return a.unit<b.unit end)
  return result
end
return M
