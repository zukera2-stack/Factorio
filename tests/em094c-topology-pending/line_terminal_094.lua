-- EM094A research-only terminal lifecycle. Native cross-surface port mechanism
-- follows existing 058; no persistent network-ID authorization or free J.
local M={}
local technical=require('scripts.technical_network_046')
local dispatch=require('scripts.bridge_dispatch_059')
local PORT='em-25kv-bridge-port-058'
local LAB='em094-terminal-lab'
local function valid(e)return e and e.valid end
local function entity(id)local e=id and game.get_entity_by_unit_number(id);return valid(e) and e or nil end
local function conn(e)return valid(e) and e.get_wire_connector(defines.wire_connector_id.pole_copper,true) or nil end
local function state()
 storage.em=storage.em or {};storage.em.em094_terminal=storage.em.em094_terminal or {ports={},next_slot=0,offered=0,accepted=0,remainder=0,uncertain=0}
 return storage.em.em094_terminal
end
local function anchor(mast)
 local t=technical.ensure_storage();local m=entity(mast);local a=entity(t.helpers[mast]);
 if not (m and a and m.force==a.force and m.surface==a.surface and m.electric_network_id and m.electric_network_id==a.electric_network_id) then return nil end
 return a
end
local function authorized(r)
 local a=anchor(r.mast);local p=entity(r.port);local output=entity(r.output);local sink=entity(r.sink)
 if not(a and p and output and sink and a.unit_number==r.anchor and p.name==PORT and a.force==p.force and a.surface.index==r.surface and p.force.index==r.force and output.surface==p.surface and sink.surface==p.surface and output.force==p.force and sink.force==p.force and technical.ensure_storage().bridge_ports[p.unit_number]==a.unit_number)then return nil end
 local pc,ac=conn(p),conn(a);local key=dispatch.network_key(a)
 if not (pc and ac and pc.real_connection_count==1 and pc.is_connected_to(ac,defines.wire_origin.script) and key and dispatch.network_key(p)==key and dispatch.network_key(output)==key and dispatch.network_key(sink)==key) then return nil end
 return key,a,p,output,sink
end
local function destroy(e)if valid(e)then e.destroy()end end
function M.ensure(mast)
 local s=state();local r=s.ports[mast]
 if r then if authorized(r) then return r end;return nil end
 local a=anchor(mast);if not a then return nil end
 local lab=game.get_surface(LAB)
 if not lab then lab=game.create_surface(LAB);lab.generate_with_lab_tiles=true;lab.always_day=true;for _,f in pairs(game.forces)do f.set_surface_hidden(lab.name,true)end end
 s.next_slot=s.next_slot+1;local pos={x=(s.next_slot%128)*4+1,y=math.floor(s.next_slot/128)*4+1}
 lab.request_to_generate_chunks(pos,0);lab.force_generate_chunk_requests()
 local p=lab.create_entity{name=PORT,position=pos,force=a.force,auto_connect=false,raise_built=false}
 if not valid(p)then return nil end;p.destructible=false
 local pc,ac=conn(p),conn(a);technical.ensure_storage().bridge_ports[p.unit_number]=a.unit_number
 if not(pc and ac and pc.connect_to(ac,false,defines.wire_origin.script))then technical.ensure_storage().bridge_ports[p.unit_number]=nil;destroy(p);return nil end
 local function interface(name,mode)
  local e=lab.create_entity{name=name,position=pos,force=a.force,raise_built=false};if not valid(e)then return nil end
  e.destructible=false;e.electric_interface_mode=mode;e.electric_buffer_size=2000000;e.power_production=0;e.power_usage=0;e.input_flow_limit=0;e.output_flow_limit=0;e.energy=0;return e
 end
 local output=interface('em-25kv-bridge-output-058',defines.electric_interface_mode.secondary_output)
 local sink=interface('em-25kv-native-traction-consumer-068',defines.electric_interface_mode.secondary_input)
 if not(output and sink)then technical.ensure_storage().bridge_ports[p.unit_number]=nil;destroy(output);destroy(sink);destroy(p);return nil end
 r={mast=mast,anchor=a.unit_number,port=p.unit_number,output=output.unit_number,sink=sink.unit_number,surface=a.surface.index,force=a.force.index}
 if not authorized(r)then technical.ensure_storage().bridge_ports[p.unit_number]=nil;destroy(output);destroy(sink);destroy(p);return nil end
 s.ports[mast]=r;return r
end
-- Test-only finite offer. Origin of actual brake grants will be integrated
-- later. Each physical terminal owns a separate pending operation.
function M.offer(mast,amount)
 local r=M.ensure(mast);if not r or r.pending or amount<=0 or amount>20000000/60 then return false end
 local key,_,_,e=authorized(r);if not key or e.energy~=0 then return false end
 e.energy=amount;e.output_flow_limit=amount;r.pending={amount=amount,key=key,tick=game.tick};state().offered=state().offered+amount;return true
end
function M.demand(mast,rate)
 local r=M.ensure(mast);if not r then return false end
 local key,_,_,_,sink=authorized(r);if not key then return false end
 sink.input_flow_limit=math.min(rate,20000000/60);return true
end
-- Separate uncertain topology from accepted native debit. Never refund a
-- missing entity or an already-delivered amount; no fabricated fallback.
function M.settle()
 local s=state();local ids={};for id in pairs(s.ports)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do local r=s.ports[id];local p=r.pending
  if p and p.tick<game.tick then
   local key,_,_,e=authorized(r);e=e or entity(r.output)
   if e then
    e.output_flow_limit=0;local rem=e.energy
    assert(rem>=0 and rem<=p.amount+.01,'EM094 invalid native residual')
    e.energy=0
    if key then s.accepted=s.accepted+p.amount-rem else s.uncertain=s.uncertain+p.amount-rem end
    s.remainder=s.remainder+rem
   else s.uncertain=s.uncertain+p.amount end
   r.pending=nil
  end
 end
end
function M.snapshot()
 local s=state();local out={offered=s.offered,accepted=s.accepted,remainder=s.remainder,uncertain=s.uncertain,pending=0,source=0,sink=0,ports=0,valid=0,rows={}}
 for id,r in pairs(s.ports)do local e=entity(r.output);local sink=entity(r.sink);local key=authorized(r);out.ports=out.ports+1;if key then out.valid=out.valid+1 end
  out.pending=out.pending+(r.pending and r.pending.amount or 0);out.source=out.source+(e and e.energy or 0);out.sink=out.sink+(sink and sink.energy or 0);out.rows[id]={key=key,port=r.port,anchor=r.anchor,output=r.output,sink=r.sink,sink_J=sink and sink.energy or 0,source_J=e and e.energy or 0}
 end
 return out
end
-- QA integration: use real registered terminal output and input, not a
-- special fixture-source prototype or a station record. Still test-only.
local function ordered()
 local s=state();local ids={};for id in pairs(s.ports)do ids[#ids+1]=id end;table.sort(ids);return s,ids
end
function M.append_donors(index)
 local s,ids=ordered()
 for _,id in ipairs(ids)do local r=s.ports[id];local key,a,p,output,sink=authorized(r)
  if key then
   local net=p.electric_network_id;local f=p.force.index;index[f]=index[f] or {};local row=index[f]
   if net and not row[net] then row[net]={count=1,id=output.unit_number,donor={mode='terminal-094-qa',output=output,line_port=p,terminal_sink=sink}} end
  end
 end
end
function M.offer_actual(post,amount,contact)
 if not contact or amount<=0 then return 0 end
 local s,ids=ordered()
 for _,o in ipairs(post.owners)do local net,_,a=contact(o)
  if net and a then for _,id in ipairs(ids)do local r=s.ports[id];local key,anchor,p,e=authorized(r)
   if key and anchor.surface==a.surface and anchor.force==o.force and p.electric_network_id==net then
    local pend=r.actual
    if pend and (pend.tick~=game.tick or pend.key~=key) then return 0 end
    local prior=pend and pend.amount or 0
    if math.abs(e.energy-prior)>.001 then return 0 end
    local j=math.min(amount,20000000/60-prior)
    if j<=0 then return 0 end
    local owners={};for _,owner in ipairs(post.owners)do owners[#owners+1]=owner.unit_number end
    if not pend then pend={tick=game.tick,key=key,amount=0,offers={}};r.actual=pend end
    pend.amount=pend.amount+j;pend.offers[#pend.offers+1]={amount=j,owners=owners,identity=post.identity,train=post.id}
    e.energy=pend.amount;e.output_flow_limit=pend.amount;return j
   end
  end end
 end
 return 0
end
function M.pending_actual()
 local s=state();local j=0;for _,r in pairs(s.ports)do if r.actual then j=j+r.actual.amount end end;return j
end
function M.settle_actual(ledger,battery,tick,allow_fallback)
 local s,ids=ordered()
 for _,id in ipairs(ids)do local r=s.ports[id];local p=r.actual
  if p and p.tick<tick then
   local key,_,_,e=authorized(r);e=e or entity(r.output)
   local remaining=e and e.energy or 0
   if e then e.output_flow_limit=0;e.energy=0 end
   assert(remaining>=0 and remaining<=p.amount+.01,'EM094 invalid actual residual')
   local delivered=p.amount-remaining
   local certain=e and key~=nil
   if certain then ledger.qa_grid_J=(ledger.qa_grid_J or 0)+delivered;ledger.recovered_J=ledger.recovered_J+delivered
   elseif e then
     -- Physically observed source debit, even if the topology certificate is invalid.
     -- Record exactly once; never refund it or claim a verified destination.
     ledger.qa_uncertain_J=(ledger.qa_uncertain_J or 0)+delivered
     ledger.recovered_J=ledger.recovered_J+delivered
   else
     ledger.qa_missing_J=(ledger.qa_missing_J or 0)+delivered
     ledger.rejected_J=ledger.rejected_J+delivered
   end
   for _,offer in ipairs(p.offers)do
    local residual=remaining*offer.amount/p.amount;local owners={};local verified=e~=nil and allow_fallback
    for _,uid in ipairs(offer.owners)do local o=entity(uid)
     if not(o and o.train and o.train.valid and o.train.id==offer.train)then verified=false else owners[#owners+1]=o end
    end
    if verified and owners[1] then
     local tr=owners[1].train;local units={};for _,c in ipairs(tr.carriages)do units[#units+1]=c.unit_number end
     local identity=tr.id..':'..table.concat(units,',')..':'..owners[1].force.index..':'..owners[1].surface.index
     verified=identity==offer.identity
    end
    local stored=verified and battery.recover(owners,residual,tick) or 0
    ledger.qa_fallback_J=(ledger.qa_fallback_J or 0)+stored;ledger.recovered_J=ledger.recovered_J+stored;ledger.rejected_J=ledger.rejected_J+residual-stored
   end
   r.actual=nil
  end
 end
end
return M
