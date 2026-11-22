-- EM065 research P0: finite, source-paid native locomotive traction.
-- ALL charge comes from live native EM070 output buffer on same real 25kV network.
-- No speed writes or fabricated energy. One authenticated native booster per
-- REAL locomotive heading (up to two) shares the SAME actual paid 25kV sink.
-- Native Factorio alone decides which of the opposite locomotives moves.
local M={MAX_PER_TICK=2000000/60,BUFFER_CAP=2000000}
local FUEL="em-c5-test-internal-joule-063"
local motor067=require("scripts.helper_lifecycle_067")
local function entity(id)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  return e and e.valid and e or nil
end
local function ensure()
  storage.em=storage.em or {}
  storage.em.traction_paid_065=storage.em.traction_paid_065 or
    {debited_J=0,credited_J=0,charged_ticks=0,miss_contact=0,miss_grid=0,miss_supply=0}
  return storage.em.traction_paid_065
end
local function network_for_contact(e,art,pantograph)
  local h=pantograph.head_offset(pantograph.frame(e.orientation))
  local contact=art.contact_at(e.surface.index,e.force.name,
    {x=e.position.x+h.x,y=e.position.y+h.y})
  if not contact or not contact.key then return nil,"no-contact" end
  local a,b=contact.key:match("^(%d+):(%d+)$")
  a=tonumber(a);b=tonumber(b)
  if not (a and b and a~=b) then return nil,"invalid-contact-key" end
  local t=storage.em and storage.em.technical_046
  if not (t and t.helpers and t.mast_connected and t.mast_connected[a]
    and t.mast_connected[b]) then return nil,"mast-not-native-connected" end
  local aa,ab=entity(t.helpers[a]),entity(t.helpers[b])
  if not (aa and ab and aa.surface.index==e.surface.index
    and ab.surface.index==e.surface.index and aa.force==e.force
    and ab.force==e.force and aa.electric_network_id
    and aa.electric_network_id==ab.electric_network_id) then
    return nil,"native-25kv-network-unverified"
  end
  return aa.electric_network_id,nil
end
local function donor(network,force)
  local bridge=storage.em and storage.em.bridge058
  if not (bridge and bridge.stations) then return nil end
  local list={}
  for id,r in pairs(bridge.stations) do
    local output=r.output
    if r.direction=="import" and r.status=="active"
      and output and output.valid and r.input and r.input.valid
      and r.factory_port and r.factory_port.valid
      and r.line_port and r.line_port.valid
      and output.electric_network_id==network
      and r.line_port.electric_network_id==network
      and output.force==force
      and entity(id) then
      list[#list+1]={id=id,r=r}
    end
  end
  table.sort(list,function(a,b)return a.id<b.id end)
  return list[1] and list[1].r or nil
end

local SINK="em-25kv-native-traction-consumer-068"
local MAX_SOURCE_PER_TICK=120000000/60
local function native_state()
  storage.em=storage.em or {}
  storage.em.traction_native_068=storage.em.traction_native_068 or
    {sinks={},metered_native_J=0,discarded_J=0,created=0}
  local n=storage.em.traction_native_068
  n.sinks_meta=n.sinks_meta or {}
  return n
end
local function sink_for_output(source)
  local id=source.output.unit_number
  local state=native_state()
  local sink=state.sinks[id]
  if sink and not sink.valid then state.sinks[id]=nil;sink=nil end
  local port=source.line_port
  if not (port and port.valid and port.electric_network_id and source.output
    and source.output.valid and source.output.electric_network_id==
      port.electric_network_id) then return nil end
  -- Reuse paid native-J buffers after a same-feeder station is rebuilt.
  -- Demolishing a bridge station removes its old port: the native sink may
  -- survive at 0-connection with real credited Joules but no grid. We may
  -- reattach ONLY to the exact original physical feeder and original native
  -- network ID, with equal surface/force and confirmed old output removal.
  -- Native same-surface EEI teleport reconnects wires while preserving J.
  -- No cross-grid refund, no deletion of positive energy, no double credit.
  local bridge=storage.em and storage.em.bridge058
  local feeder=bridge and bridge.feeders and bridge.feeders[source.owner_id]
  -- Populate provenance for sinks created by the older 0.1.68 runtime, too.
  -- Otherwise an old save retains paid native sinks with no recovery metadata.
  if sink and feeder and not state.sinks_meta[id]
      and sink.electric_network_id==port.electric_network_id then
    state.sinks_meta[id]={feeder=feeder,network=port.electric_network_id}
  end
  if not sink and feeder then
    local ids={}
    for old_id in pairs(state.sinks) do ids[#ids+1]=old_id end
    table.sort(ids)
    for _,old_id in ipairs(ids) do
      local old=state.sinks[old_id]
      local meta=state.sinks_meta[old_id]
      if old_id~=id and old and old.valid and meta
         and meta.feeder==feeder and meta.network==port.electric_network_id
         and not entity(old_id) and not old.electric_network_id
         and old.force==port.force and old.surface==port.surface then
        local before=old.energy
        local pos=old.position
        old.input_flow_limit=0; old.output_flow_limit=0
        local ok=old.teleport(port.position)
        if ok and old.electric_network_id==port.electric_network_id
           and math.abs(old.energy-before)<0.05 then
          state.sinks[old_id]=nil;state.sinks_meta[old_id]=nil
          state.sinks[id]=old;state.sinks_meta[id]=meta
          sink=old
          log(string.format("[EM069 NATIVE PAID SINK REJOIN] former_output=%d new_output=%d sink=%d feeder=%d paid_J=%.3f native_net=%d",
              old_id,id,sink.unit_number,feeder,before,port.electric_network_id))
          break
        end
        if ok then old.teleport(pos) end
        -- A disputed topology stays isolated with all real J unchanged.
        log("[EM069 NATIVE REJOIN DENIED] old_output="..old_id..
          " new_output="..id.." native sink retained isolated")
      end
    end
  end
  if sink then
    if sink.electric_network_id~=port.electric_network_id or
      sink.force~=port.force then
      -- Do not destroy a native sink holding paid Joules when a network splits.
      sink.input_flow_limit=0
      log("[EM068 NATIVE SINK ISOLATED] id="..id..
        " saved_J="..sink.energy.." disconnected; no free refund")
      return nil
    end
    return sink
  end
  sink=port.surface.create_entity{name=SINK,position=port.position,
    force=port.force,raise_built=false,create_build_effect_smoke=false}
  if not (sink and sink.valid and sink.unit_number) then
    error("[EM068 NATIVE FAIL] real EEI sink creation refused")
  end
  sink.electric_interface_mode=defines.electric_interface_mode.secondary_input
  sink.electric_buffer_size=2000000
  sink.input_flow_limit=0
  sink.output_flow_limit=0
  sink.power_production=0
  sink.power_usage=0
  sink.energy=0
  if sink.electric_network_id~=port.electric_network_id then
    error("[EM068 NATIVE FAIL] sink not on ACTUAL native 25kv network "..id)
  end
  state.sinks[id]=sink
  state.sinks_meta[id]={feeder=feeder,network=port.electric_network_id}
  state.created=state.created+1
  log(string.format("[EM068 NATIVE EEI CREATED] sink=%d port=%d native_line_net=%d source_output=%d buffer_cap_J=2000000",
    sink.unit_number,port.unit_number,sink.electric_network_id,id))
  return sink
end

-- Source-paid Joules are allocated per actual native EM070 output buffer.
-- Two equal-need real locomotives can never be charged greedily by unit_number.
-- No train.speed writes; no extra fuel; only the real EM locomotive has a reserve.
local function eligible(e,art,pantograph,stats,target)
  local contact_owner=target and target.owner or e
  if not (e and e.valid and e.unit_number and e.burner and
      contact_owner and contact_owner.valid and
      contact_owner.name=="em-electric-locomotive") then return nil end
  if target then
    if e.name:match('^em%-c5%-technical%-booster%-%d+$')==nil or
      e.train.id~=contact_owner.train.id or e.force~=contact_owner.force or
      e.surface~=contact_owner.surface then return nil end
  elseif e.name~="em-electric-locomotive" then return nil end
  local limit=target and target.watts/60 or M.MAX_PER_TICK
  local cap=target and limit or M.BUFFER_CAP
  local burner=e.burner
  local old=math.max(0,burner.remaining_burning_fuel or 0)
  if old>cap+1 then
    error('[EM072 PAID FAIL] finite native burner exceeded cap unit='..e.unit_number..' J='..old..' cap='..cap)
  end
  -- Keep one native-tick reserve in the hidden engine; real EM retains 2 MJ.
  if old>=cap-limit/2 then return nil end
  local net,why=network_for_contact(contact_owner,art,pantograph)
  if not net then
    stats.miss_contact=stats.miss_contact+1
    stats.last_contact_reason=why
    return nil
  end
  local source=donor(net,contact_owner.force)
  if not source then
    stats.miss_supply=stats.miss_supply+1
    return nil
  end
  local want=math.max(0,math.min(limit,cap-old))
  if want<=0 then return nil end
  return {e=e,burner=burner,source=source,want=want,grant=0,limit=limit,cap=cap,kind=target and "motor" or "loco"}
end

local function credit_paid(req,stats)
  local amount=req.grant
  if amount<=0 then return end
  local output=req.native_sink
  if not (output and output.valid and req.e.valid and req.source.output
    and req.source.output.valid and req.source.line_port.valid
    and output.electric_network_id==req.source.line_port.electric_network_id) then
    error("[EM068 NATIVE FAIL] paid native sink or true locomotive invalid")
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
  stats.debited_J=stats.debited_J+amount
  native_state().metered_native_J=native_state().metered_native_J+amount
  stats.credited_J=stats.credited_J+amount
  stats.charged_ticks=stats.charged_ticks+1
  if req.kind=="motor" then
    stats.motor_paid_J=(stats.motor_paid_J or 0)+amount
    stats.motor_grants=(stats.motor_grants or 0)+1
  end
end

local function fair_charge(owners,art,pantograph,stats)
  local groups,ids={},{}
  for _,e in ipairs(owners) do
    local req=eligible(e,art,pantograph,stats)
    if req then
      local id=req.source.output.unit_number
      if not id then error("[EM066 PAID FAIL] donor EEI has no native unit_number") end
      if not groups[id] then
        groups[id]={source=req.source,requests={}}
        ids[#ids+1]=id
      end
      groups[id].requests[#groups[id].requests+1]=req
    end
  end
  -- Source topology, contact and donor authorization belong ONLY to an EM
  -- locomotive. Helpers cannot touch a mast directly and never get a second
  -- independent reservoir or second direct EEI sink.
  for _,target in ipairs(motor067.targets()) do
    local req=eligible(target.helper,art,pantograph,stats,target)
    if req then
      local id=req.source.output.unit_number
      if not groups[id] then groups[id]={source=req.source,requests={}};ids[#ids+1]=id end
      groups[id].requests[#groups[id].requests+1]=req
    end
  end
  table.sort(ids)
  for _,id in ipairs(ids) do
    local group=groups[id]
    local output=sink_for_output(group.source)
    if output then
      local requested=0
      for _,req in ipairs(group.requests) do
        requested=requested+req.want
        req.native_sink=output
      end
      -- Genuine 25kV native input power demand, never a virtual Lua consumer.
      output.input_flow_limit=math.min(MAX_SOURCE_PER_TICK,requested)
    end
    local available=output and output.valid and
      math.max(0,output.energy) or 0
    -- Finite max-min water-fill: an underfilled equal-priority locomotive
    -- receives its share before the first locomotive gets any second share.
    local pending={}
    for _,req in ipairs(group.requests) do
      if req.want>0 then pending[#pending+1]=req end
    end
    while available>0.0001 and #pending>0 do
      local share=available/#pending
      local delivered=0
      local next_pending={}
      for _,req in ipairs(pending) do
        local remaining=req.want-req.grant
        local amount=math.max(0,math.min(share,remaining))
        req.grant=req.grant+amount
        delivered=delivered+amount
        if remaining-amount>0.0001 then
          next_pending[#next_pending+1]=req
        end
      end
      if delivered<=0.0001 then break end
      available=math.max(0,available-delivered)
      pending=next_pending
    end
    for _,req in ipairs(group.requests) do credit_paid(req,stats) end
  end
end

local function all_real_locomotives()
  -- Static 0.1.62 legacy Lua mock tests intentionally lack the actual native
  -- train_manager. In real Factorio 2.1.24 this manager always exists.
  if not (game and game.train_manager and game.train_manager.get_trains) then
    return {}
  end
  local owners={}
  for _,t in pairs(game.train_manager.get_trains{stock="em-electric-locomotive"}) do
    if t.valid then
      for _,e in ipairs(t.carriages) do
        if e.valid and e.name=="em-electric-locomotive" then
          owners[#owners+1]=e
        end
      end
    end
  end
  table.sort(owners,function(a,b)return a.unit_number<b.unit_number end)
  return owners
end

function M.requests(art,pantograph,dispatch)
  local helpers={}
  for _,target in ipairs(motor067.targets()) do
    local old=target.helper.burner and (target.helper.burner.remaining_burning_fuel or 0) or 0
    local cap=target.watts/60
    local left=math.max(0,math.min(cap,cap-old))
    helpers[target.owner.unit_number]=(helpers[target.owner.unit_number] or 0)+left
  end
  -- The native EM070 planner otherwise sees zero factory-grid/line demand:
  -- a Lua locomotive has no native electrical energy source. Advertise only
  -- finite, verified pending train demand on that REAL anchor network.
  local requests={}
  for _,e in ipairs(all_real_locomotives()) do
    local burner=e.burner
    if burner then
      local left=math.min(M.MAX_PER_TICK,math.max(0,M.BUFFER_CAP-(burner.remaining_burning_fuel or 0)))+(helpers[e.unit_number] or 0)
      if left>1 then
        local net=network_for_contact(e,art,pantograph)
        if net then
          local anchor=nil
          local tech=storage.em and storage.em.technical_046
          -- Same exact IDs as those already verified in network_for_contact.
          local h=pantograph.head_offset(pantograph.frame(e.orientation))
          local contact=art.contact_at(e.surface.index,e.force.name,
            {x=e.position.x+h.x,y=e.position.y+h.y})
          local a=contact and tonumber(contact.key:match("^(%d+):"))
          if a and tech then anchor=entity(tech.helpers[a]) end
          local key=anchor and dispatch.network_key(anchor)
          if key then
            -- Keep ONLY cold-start bootstrap virtual demand. Once an actual
            -- native 25kV consumer is installed and connected, native
            -- flow_last_tick.secondary_demand is the real EM070 input signal.
            local n=storage.em and storage.em.traction_native_068
            local has_native=false
            if n and n.sinks then
              for _,sink in pairs(n.sinks) do
                if sink.valid and sink.electric_network_id==net
                    and sink.force==e.force then has_native=true;break end
              end
            end
            -- A native sink can outlive a contact outage. Once the bridge
            -- goes auto-idle, it cannot reactivate from sink demand alone:
            -- fair_charge only enables that sink after donor() is active.
            -- Restore the finite virtual BOOTSTRAP request while the donor
            -- is inactive, even if a valid native sink already exists.
            -- The request does not grant Joules; only the engine-paid sink
            -- can credit the real burner. Once donor() is active, native
            -- demand takes over without double-advertising the same train.
            local active_donor=donor(net,e.force)
            if not has_native or not active_donor then
              requests[key]=(requests[key] or 0)+
                left
            end
          end
        end
      end
    end
  end
  return requests
end

function M.on_tick(tick,art,pantograph)
  local stats=ensure()
  local n=native_state()
  -- Disabled default for every old sink. Only current live authenticated
  -- real-loco contact permits native 25kV current input this tick.
  for _,sink in pairs(n.sinks) do
    if sink.valid then sink.input_flow_limit=0 end
  end
  local owners=all_real_locomotives()
  fair_charge(owners,art,pantograph,stats)
  if tick%60==0 then
    local nSinks,total,nativeDemand=0,0,0
    for _,sink in pairs(n.sinks) do
      if sink.valid then
        nSinks=nSinks+1
        total=total+sink.energy
        local parent=sink.electric_network and sink.electric_network.parent_network
        local f=parent and parent.flow_last_tick
        if f then nativeDemand=math.max(nativeDemand,(f.primary_demand or 0)+
          (f.secondary_demand or 0)) end
      end
    end
    log(string.format("[EM068 ACTUAL NATIVE TRAIN LOAD] tick=%d genuine_25kv_sinks=%d native_25kv_demand_J_tick=%.3f native_sink_stored_J=%.3f cumulative_paid_sink_to_real_burner_J=%.3f",
      tick,nSinks,nativeDemand,total,n.metered_native_J))
  end
  if tick%60==0 then
    log(string.format('[EM072 PAID LEDGER] tick=%d locos=%d helpers=%d debited_J=%.1f credited_J=%.1f motor_paid_J=%.1f motor_grants=%d charged_ticks=%d no_contact=%d no_supply=%d',
      tick,#owners,#motor067.targets(),stats.debited_J,stats.credited_J,
      stats.motor_paid_J or 0,stats.motor_grants or 0,stats.charged_ticks,
      stats.miss_contact,stats.miss_supply))
    log("[EM065 CONTACT] last_reason="..tostring(stats.last_contact_reason))
  end
end
return M