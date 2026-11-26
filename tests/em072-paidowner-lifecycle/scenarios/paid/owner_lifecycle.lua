-- EM072 owner-identity paid helper lifecycle, TEST-ONLY.
-- Reusable research logic for a future production controller.
-- Never drives train speed, mints energy, modifies visible rolling stock,
-- or silently destroys a positive-J helper.  One helper -> one EM owner ID.
local M={}
local HELPER_PREFIX="em-c5-technical-booster-"
local MOTOR={ ["em-motor-cargo-wagon"]=true, ["em-motor-fluid-wagon"]=true }
local TOL=0.1
local function lookup(id)
  local e=id and game.get_entity_by_unit_number(id)
  return e and e.valid and e or nil
end
local function state()
  storage.em072_owner_test=storage.em072_owner_test or {records={},escrow_J=0,escrow_by_helper={},removed=0,total_paid_refund_J=0,fail_count=0}
  local st=storage.em072_owner_test
  st.escrow_by_helper=st.escrow_by_helper or {}
  return st
end
local function getmotors(train)
  local m=0
  if not train or not train.valid then return 0 end
  for _,car in ipairs(train.carriages) do
    if car.valid and MOTOR[car.name] then m=m+1 end
  end
  return m
end
function M.register(owner,helper,sink,expected)
  assert(owner and owner.valid and owner.name=="em-electric-locomotive" and owner.unit_number)
  assert(helper and helper.valid and helper.name:sub(1,#HELPER_PREFIX)==HELPER_PREFIX)
  assert(sink and sink.valid and sink.electric_network_id and sink.force==owner.force)
  assert(owner.train and helper.train and owner.train.id==helper.train.id)
  assert(getmotors(owner.train)==expected and expected>=1)
  local st=state()
  local key=helper.unit_number
  assert(not st.records[key],"duplicate helper registration")
  for _,rec in pairs(st.records) do
    assert(rec.owner~=owner.unit_number,"more than one helper for one owner")
  end
  st.records[key]={owner=owner.unit_number,helper=key,sink=sink.unit_number,
    native_network=sink.electric_network_id,surface=sink.surface.index,
    force=sink.force.name,motors=expected}
  log(string.format("[EM072 OWNER REG] owner=%d helper=%d sink=%d motor=%d native_network=%d",
    owner.unit_number,key,sink.unit_number,expected,sink.electric_network_id))
end
function M.active(helper_id)
  return state().records[helper_id]
end
local function reconcile_one(rec,tick,reason)
  local st=state()
  local owner=lookup(rec.owner)
  local helper=lookup(rec.helper)
  if not helper then
    -- A different script may destroy a positive-J helper without a native
    -- pre-destroy callback. We cannot honestly refund Joules no longer
    -- observable; signal an explicit hard failure, NEVER count as safe GC.
    st.fail_count=st.fail_count+1
    error("[EM072 OWNER UNRECOVERABLE] registered helper vanished outside controlled settlement; paid-J provenance cannot be reconstructed: "..rec.helper)
  end
  local train=helper.train
  local valid=owner and owner.name=="em-electric-locomotive" and owner.force==helper.force
    and owner.surface==helper.surface and train and train.valid and owner.train
    and owner.train.id==train.id and getmotors(train)==rec.motors
  if valid then return end
  -- In the orphan train, disable AUTO immediately: after owner deletion an
  -- invisible locomotive could otherwise consume remaining paid fuel to move.
  if train and train.valid and not owner then train.manual_mode=true end
  local reserve=math.max(0,helper.burner and (helper.burner.remaining_burning_fuel or 0) or 0)
  local sink=lookup(rec.sink)
  local original_sink_J=sink and sink.energy or 0
  local before=reserve+original_sink_J+st.escrow_J
  local refund=0
  -- Refund only if the originally trusted sink is STILL on its authenticated
  -- native network, force and surface. Never redirect to a different grid.
  if sink and sink.electric_network_id==rec.native_network and
    sink.force.name==rec.force and sink.surface.index==rec.surface then
    sink.input_flow_limit=0
    local room=math.max(0,sink.electric_buffer_size-sink.energy)
    refund=math.min(room,reserve)
    sink.energy=sink.energy+refund
  end
  local escrow=reserve-refund
  st.escrow_J=st.escrow_J+escrow
  if escrow>0 then
    assert(not st.escrow_by_helper[rec.helper],"duplicate paid energy escrow")
    st.escrow_by_helper[rec.helper]={J=escrow,owner=rec.owner,
      source_sink=rec.sink,native_network=rec.native_network,
      force=rec.force,surface=rec.surface,spent=false}
  end
  if helper.burner then helper.burner.remaining_burning_fuel=0 end
  local helper_id=rec.helper
  helper.destroy{raise_destroy=true}
  assert(not helper.valid,"PAID OWNER FAIL helper survived verified removal")
  local after=(sink and sink.valid and sink.energy or 0)+st.escrow_J
  assert(math.abs(after-before)<TOL,
    string.format("PAID OWNER FAIL: J mismatch tick=%d before=%.3f after=%.3f",tick,before,after))
  st.total_paid_refund_J=st.total_paid_refund_J+refund
  st.records[helper_id]=nil
  st.removed=st.removed+1
  log(string.format("[EM072 OWNER SAFE GC] tick=%d reason=%s owner=%d helper=%d return_sink_J=%.3f escrow_J=%.3f delta_J=%.6f",
      tick,reason,rec.owner,helper_id,refund,escrow,after-before))
end
function M.reconcile(tick,reason)
  local st=state()
  if st.in_reconcile then return end
  st.in_reconcile=true
  local ids={}
  for id in pairs(st.records) do ids[#ids+1]=id end
  table.sort(ids)
  for _,id in ipairs(ids) do
    local rec=st.records[id]
    if rec then reconcile_one(rec,tick,reason or "tick") end
  end
  st.in_reconcile=nil
end
function M.stats() return state() end
return M