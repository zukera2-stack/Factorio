-- Native separate electrical networks; actual buffered joules, never generated.
local technical=require("scripts.technical_network_046")
local dispatch=require("scripts.bridge_dispatch_059")
local traction065=require("scripts.traction_paid_065")
local art030=require("scripts.catenary_art_030")
local pantograph049=require("scripts.pantograph_visual_049")
local devices=require("scripts.bridge_devices_060")
-- Owner rule: one station supplies at most 20 MW; scale by parallel stations.
local M={LIMIT=20000000/60,SUB="em-35kv-traction-substation"}
local PORT="em-25kv-bridge-port-058"
local INPUT,OUTPUT="em-25kv-bridge-input-058","em-25kv-bridge-output-058"
local LAB="em-25kv-isolated-bridge-058"
local function valid(e) return e and e.valid end
local function get(id)
 if not id then return nil end
 local e=game.get_entity_by_unit_number(id)
 return valid(e) and e or nil
end
local function state()
 storage.em=storage.em or {}
 storage.em.bridge058=storage.em.bridge058 or {stations={},feeders={},next_slot=0,dirty=true}
 return storage.em.bridge058
end
local function destroy(e) if valid(e) then e.destroy() end end
-- EM068: measure *before* engine entities are destroyed; no refund or energy mutation.
local function freeze_bridge(r)
  if valid(r.input) then
    r.input.input_flow_limit=0
    r.input.output_flow_limit=0
  end
  if valid(r.output) then
    r.output.input_flow_limit=0
    r.output.output_flow_limit=0
  end
end
local function stop(r,why)
  local a=valid(r.input) and r.input.energy or 0
  local b=valid(r.output) and r.output.energy or 0
  if a+b>0.5 and (not r.holding or why=="substation-demolished") then
    local s=state()
    s.buffer_event_seq=(s.buffer_event_seq or 0)+1
    log(string.format("[EM069 BUFFER STOP] event_id=%d tick=%d owner=%s reason=%s input_J=%.3f output_J=%.3f input_network=%s output_network=%s",
      s.buffer_event_seq,game.tick,tostring(r.owner_id or "unknown"),tostring(why or "unknown"),
      a,b,tostring(valid(r.input) and r.input.electric_network_id),tostring(valid(r.output) and r.output.electric_network_id)))
  end
  if r.input or r.output then r.window_j=0;r.last_mw=0 end
  -- EM069: electrically freeze live stored joules unless their owner is mined.
  -- They remain in Factorio native EEI storage and cannot power a broken path.
  if why~="substation-demolished"
     and (a>0.5 or b>0.5) then
    freeze_bridge(r)
    r.holding=true
    return
  end
  destroy(r.input);destroy(r.output);r.input=nil;r.output=nil
  r.holding=nil
end
local function detach(r,why)
  stop(r,why or "detach")
 local t=technical.ensure_storage()
 if r.port_id then t.bridge_ports[r.port_id]=nil end
 destroy(r.factory_port);destroy(r.line_port)
 r.factory_port=nil;r.line_port=nil;r.port_id=nil;r.anchor_id=nil
end
local function connector(e)
 if not valid(e) then return nil end
 local c=e.get_wire_connector(defines.wire_connector_id.pole_copper,true)
 return c and c.valid and c or nil
end
local function sole_link(port,target)
 local a,b=connector(port),connector(target)
 if not (a and b) then return false end
 -- Native count + native origin-aware connectivity; both connectors belong
 -- to live physical entities. No materialized WireConnection array needed.
 return a.real_connection_count==1 and a.is_connected_to(b,defines.wire_origin.script)
end
local function connect(port,target)
 local a,b=connector(port),connector(target)
 if not (a and b) then return false end
 local ok,result=pcall(function() return a.connect_to(b,false,defines.wire_origin.script) end)
 return ok and result and sole_link(port,target)
end
local function lab(s)
 local old=s.surface_index and game.surfaces[s.surface_index]
 if old and old.valid and old.name==LAB then return old end
 if game.get_surface(LAB) then return nil end
 local surface=game.create_surface(LAB)
 surface.generate_with_lab_tiles=true
 surface.always_day=true
 surface.show_clouds=false
 s.surface_index=surface.index
 for _,force in pairs(game.forces) do force.set_surface_hidden(surface.name,true) end
 return surface
end
local function create_ports(s,r,p,a)
 detach(r)
 local surface=lab(s)
 if not surface then return false end
 p.force.set_surface_hidden(surface.name,true)
 if not r.slot then s.next_slot=s.next_slot+1;r.slot=s.next_slot end
 local x=(r.slot%512)*8+1
 local y=math.floor(r.slot/512)*8+1
 local pos1,pos2={x=x,y=y},{x=x+3,y=y}
 surface.request_to_generate_chunks(pos1,0)
 surface.request_to_generate_chunks(pos2,0)
 surface.force_generate_chunk_requests()
 local function make(pos)
   local e=surface.create_entity{name=PORT,position=pos,force=p.force,auto_connect=false,raise_built=false}
   if valid(e) then e.destructible=false;return e end
 end
 r.factory_port=make(pos1);r.line_port=make(pos2)
 if not (valid(r.factory_port) and valid(r.line_port)) then detach(r);return false end
 r.anchor_id=a.unit_number;r.port_id=r.line_port.unit_number
 r.parent_force=p.force.name;r.parent_surface=p.surface.index
 technical.ensure_storage().bridge_ports[r.port_id]=r.anchor_id
 if not (connect(r.factory_port,p) and connect(r.line_port,a)) then detach(r);return false end
 return true
end
local function interface(port,name)
 local e=port.surface.create_entity{name=name,position=port.position,force=port.force,raise_built=false}
 if valid(e) then
   e.destructible=false;e.power_production=0;e.power_usage=0;e.energy=0
    e.electric_interface_mode=(name==INPUT) and defines.electric_interface_mode.secondary_input or defines.electric_interface_mode.secondary_output
   return e
 end
end
local function sync_graph(s,graph)
 local current={}
 for id,n in pairs(graph.nodes) do
   if n.name==M.SUB and get(id) then
     current[id]=true
     s.stations[id]=s.stations[id] or {mode="auto",status="waiting"}
      s.stations[id].owner_id=id
   end
 end
 for id,r in pairs(s.stations) do
   if not current[id] then
     if get(id) then
       -- Graph snapshot staleness is NOT permission to destroy a live station.
       stop(r,"station-temporarily-absent-from-graph")
       r.status="await-graph"
     else
       detach(r,"substation-demolished")
       s.stations[id]=nil
     end
   end
 end
 local feeders={}
 for _,edge in pairs(graph.edges) do
   if edge.kind=="feeder" then
     local p,a=edge.a,edge.b
     if not current[p] then p,a=a,p end
     if current[p] then feeders[p]=a end
   end
 end
 s.feeders=feeders;s.dirty=false
end
function M.mark_dirty() state().dirty=true end
function M.on_built(e)
 if e.name==M.SUB or e.name=="em-35kv-catenary-pole" or e.name=="em-35kv-catenary-pole-north" then M.mark_dirty() end
end
function M.on_removed(e)
 local s=state()
 if e.name==M.SUB then
   local r=s.stations[e.unit_number];if r then detach(r,"substation-demolished");s.stations[e.unit_number]=nil end
   s.dirty=true
 elseif e.name=="em-35kv-catenary-pole" or e.name=="em-35kv-catenary-pole-north" then
   for id,r in pairs(s.stations) do if s.feeders[id]==e.unit_number then detach(r,"feeder-mast-removed") end end
   s.dirty=true
 end
end
function M.rebuild(graph)
 local s=state()
  for _,r in pairs(s.stations) do
   freeze_bridge(r)
   if not s.auto_migrated and (r.mode=="import" or r.mode=="export") then r.mode="auto" end
   r.interface_retry=nil;r.retry=nil;r.status="revalidating-after-rebuild"
 end
 s.auto_migrated=true;s.last_auto={};s.sample_tick=nil;s.device_sample=nil;s.last_flow_log=nil
 -- Native EEIs already in the save retain their energy. Do not erase them
 -- merely because a config update re-runs the Lua script.
 local t=technical.ensure_storage();t.bridge_ports={}
 for _,r in pairs(s.stations) do
   if valid(r.line_port) and r.anchor_id and r.port_id then t.bridge_ports[r.port_id]=r.anchor_id end
 end
 sync_graph(s,graph)
end
-- Pure deterministic directed graph. Reject same-net links and edges closing any cycle.
function M.select(candidates)
 local accepted,rejected,adj={}, {},{}
 local function reaches(a,b)
   local stack,seen={a},{}
   while #stack>0 do
     local x=table.remove(stack)
     if x==b then return true end
     if not seen[x] then
       seen[x]=true
       for y in pairs(adj[x] or {}) do stack[#stack+1]=y end
     end
   end
   return false
 end
 table.sort(candidates,function(a,b)return a.id<b.id end)
 for _,c in ipairs(candidates) do
   if c.source==nil or c.target==nil then rejected[c.id]="no-network"
   elseif c.source==c.target or reaches(c.target,c.source) then rejected[c.id]="cycle-or-same-network"
   else
     accepted[c.id]=true
     adj[c.source]=adj[c.source] or {};adj[c.source][c.target]=true
   end
 end
 return accepted,rejected
end
function M.transfer(input,output,capacity)
 local amount=math.max(0,math.min(M.LIMIT,input,math.max(0,capacity-output)))
 return input-amount,output+amount,amount
end
local function reject(r,why)
  stop(r,"reject:"..tostring(why));r.status=why
end
-- 063: Native EEI outputs still hold real joules at auto-idle transitions.
-- Do not destroy these buffers before the game has discharged them. The station
-- itself is still an electric pole (no persistent internal accumulator).
local function idle_or_drain(r,raw_flows,route_open,is_isolated,factory_key,line_key)
  if not route_open then reject(r,"auto-idle-no-connected-peer");return end
 -- Factory generators still running? An ordinary factory brownout takes priority.
 -- Never keep secondary bridge power attached in auto-idle while the source
 -- factory has even partial native production; otherwise it steals factory MW.
 if r.direction=="import" then
   local f=raw_flows and raw_flows[r.source_id] or nil
   local production=f and math.max(0,(f.primary_output or 0)+(f.secondary_output or 0)+(f.solar_output or 0)) or 0
   if production>1 then reject(r,"auto-idle");return end
 end
 local src,dst=r.input,r.output
 local src_port=r.direction=="import" and r.factory_port or r.line_port
 local dst_port=r.direction=="import" and r.line_port or r.factory_port
 if r.mode=="auto" and valid(src) and valid(dst) and valid(src_port) and valid(dst_port)
   and src.electric_network_id==src_port.electric_network_id
   and dst.electric_network_id==dst_port.electric_network_id
   and (src.energy>1 or dst.energy>1) then
   -- A native peer alone is not isolation proof. Stored joules must remain
   -- frozen if this factory shares any physical corridor parent network.
   if not is_isolated(factory_key,line_key) then reject(r,"factory-corridor-short");return end
   -- Stop new imports; old J can leave ONLY when a peer is connected.
   src.input_flow_limit=0
   src.output_flow_limit=0
   dst.input_flow_limit=0
   dst.output_flow_limit=math.min(M.LIMIT,dst.energy)
   if src.energy>0 then
     local _,new_out,amount=M.transfer(math.min(src.energy,M.LIMIT),dst.energy,dst.electric_buffer_size)
     if amount>0 then
       src.energy=src.energy-amount;dst.energy=new_out
       dst.output_flow_limit=math.min(M.LIMIT,dst.energy)
       r.window_j=(r.window_j or 0)+amount
     end
   end
   r.status="draining-buffer"
   return
 end
 reject(r,"auto-idle")
end
function M.on_tick(tick,graph)
 local s=state()
 if s.dirty or tick%60==0 then sync_graph(s,graph) end
 local t=technical.ensure_storage()
 -- Native entity references are stable by unit_number within this phase.
 -- Never cache a network ID across a topology mutation; all existing live
 -- network/isolation/sole-link tests remain in place.
 local entities={}
 local function lookup(id)
   if not id then return nil end
   local e=entities[id]
   if e and e.valid then return e end
   e=get(id);entities[id]=e
   return e
 end
 local candidates,auto_edges,networks={},{},{}
 local cache,raw_flows,physical,allowed={},{},{},{}
 for id,station in pairs(s.stations) do
   if station.mode~="off" then
     local p=lookup(id)
     if p then local key=dispatch.network_key(p);if key then physical[p.surface.index]=p.surface;allowed[key]=true end end
   end
 end
 local direct=devices.sample(s,tick,physical,allowed)
 local previous=(s.sample_tick==tick-1 and s.last_auto or {})
 local function observe(e,raw)
   raw=raw or e.electric_network_id
   if not raw then return nil end
   if cache[raw] then return cache[raw] end
   local k,flow=dispatch.read_network(e)
   if k and flow then
     cache[raw]=k
     raw_flows[k]=flow
     networks[k]=networks[k] or dispatch.balance(flow,previous[k],direct[k])
     return k
   end
 end
 for id,r in pairs(s.stations) do
   local p=lookup(id)
   local a=lookup(t.helpers[s.feeders[id]])
   if r.mode=="off" then if r.factory_port or r.line_port or r.input or r.output then detach(r,"mode-off") end;r.status="off"
   elseif not p or not a or p.force.name~=a.force.name or p.surface.index~=a.surface.index or (t.stats.audit_failed or 0)>0 or (t.stats.mast_audit_failed or 0)>0 then
      detach(r,"no-feeder-or-audit-failed");r.status="no-feeder-or-audit-failed"
   else
     if not (valid(r.factory_port) and valid(r.line_port) and r.anchor_id==a.unit_number and r.parent_force==p.force.name and r.parent_surface==p.surface.index
       and sole_link(r.factory_port,p) and sole_link(r.line_port,a)) then
        detach(r,"terminal-repair")
        if not r.retry or tick>=r.retry then
         r.retry=tick+60
         local ok,result=pcall(create_ports,s,r,p,a)
         if not ok or not result then detach(r,"terminal-create-failed");log("[EM058] terminal creation/refused: "..tostring(result)) end
       end
       r.status="waiting-terminal"
     elseif r.mode=="import" or r.mode=="export" or r.mode=="auto" then
       local f,l=r.factory_port.electric_network_id,r.line_port.electric_network_id
       if f and l and f==p.electric_network_id and l==a.electric_network_id then
         local fk,lk=observe(r.factory_port,f),observe(r.line_port,l)
         if r.mode=="auto" then
           local mast=lookup(s.feeders[id])
           if not (fk and lk and mast and mast.electric_network_id==l and t.mast_connected and t.mast_connected[s.feeders[id]]) then
             reject(r,"auto-network-or-mast-unverified")
           else auto_edges[#auto_edges+1]={id=id,a=fk,b=lk,raw_a=f,raw_b=l} end
         else
           local src,dst=r.factory_port,r.line_port
           if r.mode=="export" then src,dst=dst,src end
           local sk,dk=fk or f,lk or l
           if r.mode=="export" then sk,dk=dk,sk end
           candidates[#candidates+1]={id=id,source=sk,target=dk,raw_source=src.electric_network_id,raw_target=dst.electric_network_id,src=src,dst=dst,limit=M.LIMIT,direction=r.mode}
         end
       else reject(r,"network-id-mismatch") end
     else reject(r,"invalid-mode") end
   end
 end
 -- Automatic allocation is coordinated across every connected ordinary/corridor network.
 -- EM065 test branch: a native locomotive is NOT itself an electric network
 -- consumer. Register only its finite, authenticated pending 2MW demand in the
 -- existing native EM070 dispatch planner; every delivered joule is still
 -- physically debited later from the native charged 25kV output EEI.
 local traction_demand,battery_charge=traction065.requests(art030,pantograph049,dispatch)
 for id,j in pairs(traction_demand) do
   if networks[id] then networks[id].load=networks[id].load+j end
 end
 for id,j in pairs(battery_charge or {}) do
   if networks[id] then networks[id].charge=math.max(networks[id].charge,j) end
 end
 local plan,charge_budget=dispatch.plan(networks,auto_edges,M.LIMIT)
 local connected_peers={}
 for _,edge in ipairs(auto_edges) do connected_peers[edge.b]=(connected_peers[edge.b] or 0)+1 end
 -- Only build this synchronous native-network set for an actual drain.
 -- No permission survives a tick; normal candidate isolation below remains.
 local live_corridor
 local function corridor_keys()
   if not live_corridor then
     live_corridor={}
     for _,aid in pairs(t.helpers) do
       local a=lookup(aid)
       if valid(a) then
         local raw=a.electric_network_id
         if raw then live_corridor[observe(a,raw) or raw]=true end
       end
     end
   end
   return live_corridor
 end
 local function idle_isolated(factory_key,line_key)
   if not factory_key or factory_key==line_key then return false end
   return not corridor_keys()[factory_key]
 end
 for _,edge in ipairs(auto_edges) do
   local r=s.stations[edge.id]
   local v=plan[edge.id] or 0
   if math.abs(v)>1 then
     local direction=v>0 and "import" or "export"
     local src,dst=r.factory_port,r.line_port
     local sk,dk=edge.a,edge.b
     if v<0 then src,dst=dst,src;sk,dk=dk,sk end
     candidates[#candidates+1]={id=edge.id,source=sk,target=dk,raw_source=src.electric_network_id,raw_target=dst.electric_network_id,src=src,dst=dst,limit=math.min(M.LIMIT,math.abs(v)),direction=direction,auto=true}
    else idle_or_drain(r,raw_flows,(connected_peers[edge.b] or 0)>1,idle_isolated,edge.a,edge.b) end
 end
 s.last_auto={};s.sample_tick=tick
 -- Any factory terminal sharing a corridor network means actual isolation was lost.
 -- Port repairs have finished; idle_or_drain only changes EEI buffers/flows
 -- or retires empty EEIs. No pole or wire is edited between these checks.
 -- Retain live isolation for every nonempty batch, using the same native
 -- corridor set if a drain already required it in this synchronous phase.
 local corridor=#candidates>0 and corridor_keys() or {}
 local safe,shorted={},{}
 for _,c in ipairs(candidates) do
   local r=s.stations[c.id]
   local id=observe(r.factory_port) or r.factory_port.electric_network_id
   if corridor[id] then shorted[id]=true end
 end
 for _,c in ipairs(candidates) do
   if shorted[c.source] or shorted[c.target] then reject(s.stations[c.id],"factory-corridor-short")
   else safe[#safe+1]=c end
 end
 local accepted,rejected=M.select(safe)
 -- Disable ALL blocked interfaces before crediting any source/sink.
 for id,why in pairs(rejected) do reject(s.stations[id],why) end
 for _,c in ipairs(safe) do
   if accepted[c.id] then
     local r=s.stations[c.id]
     local created=false
     if r.direction~=c.direction then
       if valid(r.input) and valid(r.output) and r.direction then
         -- Exchange the physical port roles, not entities: no EEI is destroyed.
         -- Both interfaces stay on their old electric networks; producer and
         -- consumer roles swap, returning any buffered old-source joules locally.
         freeze_bridge(r)
         local old_input,old_output=r.input,r.output
         old_input.electric_interface_mode=defines.electric_interface_mode.secondary_output
         old_output.electric_interface_mode=defines.electric_interface_mode.secondary_input
         r.input=old_output;r.output=old_input
         r.holding=nil
         log(string.format("[EM069 DIRECTION SWAP] tick=%d owner=%s from=%s to=%s input_J=%.0f output_J=%.0f",tick,tostring(r.owner_id),tostring(r.direction),tostring(c.direction),r.input.energy,r.output.energy))
       else
         stop(r,"direction-change")
       end
       r.direction=c.direction;r.interface_retry=nil
     end
      if not (valid(r.input) and valid(r.output)) then
        stop(r,"interface-recreate")
       if not r.interface_retry or tick>=r.interface_retry then
         r.interface_retry=tick+60
         local ok,result=pcall(function() r.input=interface(c.src,INPUT);r.output=interface(c.dst,OUTPUT) end)
         if not ok or not valid(r.input) or not valid(r.output) then reject(r,"interface-create-failed");log("[EM058] interface creation "..tostring(result)) else created=true end
       end
     end
     if valid(r.input) and valid(r.output) then
       if r.input.electric_network_id~=c.raw_source or r.output.electric_network_id~=c.raw_target or c.source==c.target then
         reject(r,"interface-network-mismatch")
       else
         r.holding=nil
         local cap=math.min(c.limit, M.LIMIT)
         local old_size=r.input.electric_buffer_size
         local ok,old_in,old_out=pcall(function()return r.input.input_flow_limit,r.output.output_flow_limit end)
         old_in=(ok and type(old_in)=="number") and math.min(M.LIMIT,old_in) or M.LIMIT
         old_out=(ok and type(old_out)=="number") and math.min(M.LIMIT,old_out) or M.LIMIT
         -- EM094D.2: a role-swapped EEI inherits its former input capacity.
         -- A tiny previous input allocation must not cap a later output forever.
         -- Grow only (never discard retained joules), bounded by the current
         -- station transfer plan and the existing 20 MW ceiling.
         if r.output.electric_buffer_size<cap then
           r.output.electric_buffer_size=cap
         end
         local ei,eo,amount=M.transfer(math.min(r.input.energy,cap),r.output.energy,r.output.electric_buffer_size)
         r.input.energy=r.input.energy-amount
         r.output.energy=eo
         -- Engine 2.1.24 trace: an EEI newly created with the 20MW prototype
         -- advertised its original 333333J demand for one update even after
         -- input_flow_limit read back the requested 20000J. Keep both buffer
         -- and flow limit bounded, and account for one transitional old limit.
         local old_demand=math.min(old_in,math.max(0,old_size-r.input.energy))
         local old_offer=math.min(old_out,r.output.energy)
         if c.auto then
           local desired=math.max(r.input.energy,cap)
           if math.abs(r.input.electric_buffer_size-desired)>0.01 then r.input.electric_buffer_size=desired end
           pcall(function()
             if r.input.input_flow_limit~=cap then r.input.input_flow_limit=cap end
             if r.output.output_flow_limit~=cap then r.output.output_flow_limit=cap end
           end)
         end
         local demand=math.min(cap,math.max(0,r.input.electric_buffer_size-r.input.energy))
         local offer=math.min(cap,r.output.energy)
         if c.auto and (created or math.abs(old_in-cap)>0.01 or math.abs(old_size-r.input.electric_buffer_size)>0.01) then
           demand=math.max(demand,old_demand)
         end
         if c.auto and (created or math.abs(old_out-cap)>0.01) then offer=math.max(offer,old_offer) end
         local x=s.last_auto[c.source] or {demand=0,offer=0}
         x.demand=x.demand+demand;s.last_auto[c.source]=x
         local y=s.last_auto[c.target] or {demand=0,offer=0}
         y.offer=y.offer+offer;s.last_auto[c.target]=y
         r.window_j=(r.window_j or 0)+amount;r.status="active"
         r.source_id=c.source;r.target_id=c.target
         if tick%60==0 then r.last_mw=r.window_j/1e6;r.window_j=0 end
       end
     end
   end
 end
 -- Preserve the player-facing planned power value, without per-tick log formatting.
 for id,r in pairs(s.stations) do
   r.planned_mw=(plan[id] or 0)*60/1e6
 end
 -- Only this tick's generator-to-charge allocation; not a grant of Joules.
 local authorized={}
 -- A rejected planned bridge makes generator-to-charge provenance ambiguous.
 -- Conservatively freeze all new onboard charging for this tick.
 if #safe~=#candidates or next(rejected) then return authorized end
 for id,j in pairs(battery_charge or {}) do
   authorized[id]=math.min(j,charge_budget[id] or 0)
 end
 return authorized
end
function M.command(player,param)
 local e=player.selected
 if not (valid(e) and e.name==M.SUB and e.force==player.force) then player.print("[EM059] Select your 25 kV traction substation for mode; /em-25kv-network for mast.");return end
 local s=state();local id=e.unit_number
 local r=s.stations[id] or {mode="auto",status="waiting"};s.stations[id]=r
 param=(param or "status"):match("^%s*(.-)%s*$"):lower()
 if param=="" then param="status" end
 if param=="auto" or param=="import" or param=="export" or param=="off" then
   if r.mode~=param then
      local previous_direction=r.direction
      detach(r,"manual-mode-change")
      r.mode=param
      -- A buffered bridge retains its physical old direction across OFF/MANUAL
      -- so the next opposite command can swap roles without discarding Joules.
      r.direction=(valid(r.input) and valid(r.output)) and previous_direction or nil
      r.retry=nil;r.interface_retry=nil;r.status="waiting";s.dirty=true
    end
 elseif param~="status" then player.print("[EM059] auto | import | export | off | status");return end
 local msg=string.format("[EM060] station=%d mode=%s status=%s bridge=%.3f MW / 20 MW | factory=%s line=%s input_J=%.0f output_J=%.0f feeder=%s planned=%.3fMW",
 id,r.mode,r.status or "unknown",r.last_mw or 0,
 tostring(valid(r.factory_port) and r.factory_port.electric_network_id or "-"),
 tostring(valid(r.line_port) and r.line_port.electric_network_id or "-"),
 valid(r.input) and r.input.energy or 0,valid(r.output) and r.output.energy or 0,tostring(s.feeders[id]),r.planned_mw or 0)
 player.print(msg);log(msg)
 s.device_sample=nil;s.last_flow_log=nil
end
return M