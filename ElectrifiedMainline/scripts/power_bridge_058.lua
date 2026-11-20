-- Native separate electrical networks; actual buffered joules, never generated.
local technical=require("scripts.technical_network_046")
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
local function stop(r)
 if r.input or r.output then r.window_j=0;r.last_mw=0 end
 destroy(r.input);destroy(r.output);r.input=nil;r.output=nil
end
local function detach(r)
 stop(r)
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
 local n=0
 for _,link in pairs(a.real_connections) do
   if not (link.target and link.target.valid and link.target.owner==target and link.origin==defines.wire_origin.script) then return false end
   n=n+1
 end
 return n==1 and a.is_connected_to(b,defines.wire_origin.script)
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
   return e
 end
end
local function sync_graph(s,graph)
 local current={}
 for id,n in pairs(graph.nodes) do
   if n.name==M.SUB and get(id) then
     current[id]=true
     s.stations[id]=s.stations[id] or {mode="off",status="off"}
   end
 end
 for id,r in pairs(s.stations) do if not current[id] then detach(r);s.stations[id]=nil end end
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
   local r=s.stations[e.unit_number];if r then detach(r);s.stations[e.unit_number]=nil end
   s.dirty=true
 elseif e.name=="em-35kv-catenary-pole" or e.name=="em-35kv-catenary-pole-north" then
   for id,r in pairs(s.stations) do if s.feeders[id]==e.unit_number then detach(r) end end
   s.dirty=true
 end
end
function M.rebuild(graph)
 local s=state()
 for _,r in pairs(s.stations) do detach(r) end
 local surface=s.surface_index and game.surfaces[s.surface_index]
 if surface and surface.valid and surface.name==LAB then
   for _,e in pairs(surface.find_entities_filtered{name={PORT,INPUT,OUTPUT}}) do destroy(e) end
 end
 technical.ensure_storage().bridge_ports={}
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
 stop(r);r.status=why
end
function M.on_tick(tick,graph)
 local s=state()
 if s.dirty or tick%60==0 then sync_graph(s,graph) end
 local t=technical.ensure_storage()
 local candidates={}
 for id,r in pairs(s.stations) do
   local p=get(id)
   local a=get(t.helpers[s.feeders[id]])
   if r.mode=="off" then if r.factory_port or r.line_port or r.input or r.output then detach(r) end;r.status="off"
   elseif not p or not a or p.force.name~=a.force.name or p.surface.index~=a.surface.index or (t.stats.audit_failed or 0)>0 then
     detach(r);r.status="no-feeder-or-audit-failed"
   else
     if not (valid(r.factory_port) and valid(r.line_port) and r.anchor_id==a.unit_number and r.parent_force==p.force.name and r.parent_surface==p.surface.index
       and sole_link(r.factory_port,p) and sole_link(r.line_port,a)) then
       detach(r)
       if not r.retry or tick>=r.retry then
         r.retry=tick+60
         local ok,result=pcall(create_ports,s,r,p,a)
         if not ok or not result then detach(r);log("[EM058] terminal creation/refused: "..tostring(result)) end
       end
       r.status="waiting-terminal"
     elseif r.mode=="import" or r.mode=="export" then
       local f,l=r.factory_port.electric_network_id,r.line_port.electric_network_id
       if f and l and f==p.electric_network_id and l==a.electric_network_id then
         local src,dst=r.factory_port,r.line_port
         if r.mode=="export" then src,dst=dst,src end
         candidates[#candidates+1]={id=id,source=src.electric_network_id,target=dst.electric_network_id,src=src,dst=dst}
       else reject(r,"network-id-mismatch") end
     else reject(r,"invalid-mode") end
   end
 end
 if #candidates==0 then return end
 -- Any factory terminal sharing a corridor network means actual isolation was lost.
 local corridor={}
 for _,aid in pairs(t.helpers) do
   local a=get(aid)
   if valid(a) and a.electric_network_id then corridor[a.electric_network_id]=true end
 end
 local safe,shorted={},{}
 for _,c in ipairs(candidates) do
   local r=s.stations[c.id]
   local id=r.factory_port.electric_network_id
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
     if not (valid(r.input) and valid(r.output)) then
       stop(r)
       if not r.interface_retry or tick>=r.interface_retry then
         r.interface_retry=tick+60
         local ok,result=pcall(function() r.input=interface(c.src,INPUT);r.output=interface(c.dst,OUTPUT) end)
         if not ok or not valid(r.input) or not valid(r.output) then reject(r,"interface-create-failed");log("[EM058] interface creation "..tostring(result)) end
       end
     end
     if valid(r.input) and valid(r.output) then
       if r.input.electric_network_id~=c.source or r.output.electric_network_id~=c.target or c.source==c.target then
         reject(r,"interface-network-mismatch")
       else
         local ei,eo,amount=M.transfer(r.input.energy,r.output.energy,r.output.electric_buffer_size)
         r.input.energy=ei
         r.output.energy=eo
         r.window_j=(r.window_j or 0)+amount;r.status="active"
         r.source_id=c.source;r.target_id=c.target
         if tick%60==0 then r.last_mw=r.window_j/1e6;r.window_j=0 end
       end
     end
   end
 end
end
function M.command(player,param)
 local e=player.selected
 if not (valid(e) and e.name==M.SUB and e.force==player.force) then player.print("[EM058] Select your 25 kV traction substation.");return end
 local s=state();local id=e.unit_number
 local r=s.stations[id] or {mode="off",status="off"};s.stations[id]=r
 param=(param or "status"):match("^%s*(.-)%s*$"):lower()
 if param=="" then param="status" end
 if param=="import" or param=="export" or param=="off" then
   if r.mode~=param then detach(r);r.mode=param;r.retry=nil;r.interface_retry=nil;r.status="waiting";s.dirty=true end
 elseif param~="status" then player.print("[EM058] import | export | off | status");return end
 local msg=string.format("[EM058] station=%d mode=%s status=%s bridge=%.3f MW / 20 MW | factory=%s line=%s input_J=%.0f output_J=%.0f feeder=%s",
 id,r.mode,r.status or "unknown",r.last_mw or 0,
 tostring(valid(r.factory_port) and r.factory_port.electric_network_id or "-"),
 tostring(valid(r.line_port) and r.line_port.electric_network_id or "-"),
 valid(r.input) and r.input.energy or 0,valid(r.output) and r.output.energy or 0,tostring(s.feeders[id]))
 player.print(msg);log(msg)
end
return M
