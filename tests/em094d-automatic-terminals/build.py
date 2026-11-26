import pathlib as P,zipfile,hashlib, json
r=P.Path(__file__).parent;base=P.Path('/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip');out=r/'candidate.zip'
assert hashlib.sha256(base.read_bytes()).hexdigest()=='eebed6e004a13b002a2a33101d771a3b7b0ee12d3dbba2bd12e19f6cb902e1a7'
s=P.Path('/mnt/data/em094c/line_terminal_094.lua').read_text()
s=s.replace('-- EM094A research-only terminal lifecycle. Native cross-surface port mechanism','-- EM094D opt-in terminal lifecycle. Native cross-surface port mechanism')
s=s.replace('local function state()','function M.enabled()\n local g=settings.global\n return g["em094-experimental-grid-regeneration"].value and g["em091-experimental-regeneration"].value and g["em089-experimental-onboard-storage"].value\nend\nlocal function state()')
s=s.replace('s.next_slot=s.next_slot+1;local pos={x=(s.next_slot%128)*4+1,y=math.floor(s.next_slot/128)*4+1}', 's.free=s.free or {};local slot=table.remove(s.free);if not slot then s.next_slot=s.next_slot+1;slot=s.next_slot end\n local pos={x=(slot%128)*4+1,y=math.floor(slot/128)*4+1}')
s=s.replace('r={mast=mast,','r={slot=slot,last_used=game.tick,mast=mast,')
# eliminate fixture-only mutators, keep read-only snapshot
s=s[:s.index('-- Test-only finite offer.')]+s[s.index('function M.snapshot()'):]
s=s.replace('local s=state();local out={offered=', 'local s=state();local out={retired=s.retired or 0,retired_sink_J=s.retired_sink_J or 0,unobserved=s.unobserved or 0,offered=')
s=s.replace('function M.append_donors(index)\n','function M.append_donors(index)\n if not M.enabled() then return end\n')
s=s.replace("mode='terminal-094-qa'","mode='terminal-094'")
s=s.replace('local s,ids=ordered()\n for _,id in ipairs(ids)do local r=s.ports[id];local key,a,p,output,sink=authorized(r)', '''local s,ids=ordered();local covered={}
 local b=storage.em.bridge058
 for _,st in pairs(b and b.stations or {})do local p=st.line_port;if valid(p) and p.electric_network_id then covered[p.force.index..':'..p.electric_network_id]=true end end
 for _,id in ipairs(ids)do local r=s.ports[id];local key,a,p,output,sink=authorized(r)''')
s=s.replace('if net and not row[net] then row[net]=', 'if net and not row[net] and (not covered[f..\':\'..net] or r.actual or sink.energy>0.001) then row[net]=')
s=s.replace('if not contact or amount<=0 then return 0 end','if not M.enabled() or not contact or amount<=0 then return 0 end')
s=s.replace('anchor.surface==a.surface and anchor.force==o.force and p.electric_network_id==net','anchor.surface==a.surface and anchor.force==o.force and p.electric_network_id==net')
s=s.replace('function M.settle_actual(ledger,battery,tick,allow_fallback)','function M.settle_actual(ledger,battery,tick,allow_fallback)\n if not (storage.em and storage.em.em094_terminal) then return end')
# actual name verification
assert 'function M.settle_actual(ledger,battery,tick,allow_fallback)' in s
s=s.replace('return M\n','''-- At most one newly created terminal per currently contacted native network.
-- Anchors remain physical; live network identity is used only within this tick.
function M.prepare(owners,contact,tick)
 if not M.enabled() and not (storage.em and storage.em.em094_terminal) then return end
 local s,ids=ordered();local live={}
 for _,id in ipairs(ids) do
  local r=s.ports[id];local k,a,p,_,sink=authorized(r)
  local raw=entity(r.sink);if raw then raw.input_flow_limit=0 end
  if k then local key=a.force.index..':'..a.surface.index..':'..p.electric_network_id
   if not live[key] then live[key]=r end
  end
 end
 if not M.enabled() then return end
 for _,o in ipairs(owners) do
  local net,_,a,mast=contact(o)
  if net and a and mast then
   local key=a.force.index..':'..a.surface.index..':'..net
   local r=live[key]
   if not r then r=M.ensure(mast);if r then live[key]=r end end
   if r then r.last_used=tick end
  end
 end
end
-- Retire only after pending settlement. Never transfer stranded sink energy
-- to a different network. Count measured destruction as an explicit loss.
function M.retire(tick)
 if not (storage.em and storage.em.em094_terminal) then return end
 local s,ids=ordered();local n=storage.em.traction_native_068
 for _,id in ipairs(ids) do local r=s.ports[id]
  if not r.actual and (not M.enabled() or not authorized(r) or tick-(r.last_used or 0)>120) then
   local sink=entity(r.sink);local output=entity(r.output)
   if sink then sink.input_flow_limit=0;s.retired_sink_J=(s.retired_sink_J or 0)+sink.energy
    if n then n.discarded_J=(n.discarded_J or 0)+sink.energy end
   else s.unobserved=(s.unobserved or 0)+1 end
   if output then output.output_flow_limit=0 end
   if n then n.sinks[r.output]=nil;n.sinks_meta[r.output]=nil end
   technical.ensure_storage().bridge_ports[r.port]=nil
   destroy(sink);destroy(output);destroy(entity(r.port));s.ports[id]=nil
   s.retired=(s.retired or 0)+1;s.free=s.free or {};if r.slot then s.free[#s.free+1]=r.slot end
  end
 end
end
return M
''')
(r/'line_terminal_094.lua').write_text(s)
with zipfile.ZipFile(base) as z,zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as w:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/info.json'):
   d=json.loads(b);d['version']='0.1.103';d['description']+=' EM094D candidate: opt-in native grid regeneration and automatic terminals; not release.';b=(json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode()
  if n.endswith('/settings.lua'):
   b+=b'\ndata:extend{{type="bool-setting",name="em094-experimental-grid-regeneration",setting_type="runtime-global",default_value=false,order="em094-a"}}\n'
  if n.endswith('/scripts/control.lua'):
   s=b.decode().replace('local regen091 = require', 'local term094 = require("scripts.line_terminal_094")\nlocal regen091 = require').replace('regen091.finish(event.tick,onboard089)','regen091.finish(event.tick,onboard089,function(e) return paidTraction065.contact(e,art030,pantograph049) end)\n    term094.retire(event.tick)');s+='\nremote.add_interface("em094_line_terminal",{snapshot=term094.snapshot})\n';b=s.encode()
  if n.endswith('/scripts/traction_paid_065.lua'):
   s=b.decode().replace('return net,nil,aa','return net,nil,aa,a')
   s=s.replace('local function active_bridge_index()', 'M.contact=network_for_contact\nlocal term094=require("scripts.line_terminal_094")\nlocal function active_bridge_index()')
   s=s.replace('  return index\nend\nlocal function phase_bridge','  term094.append_donors(index)\n  return index\nend\nlocal function phase_bridge').replace('if not (bridge and bridge.stations) then return index end','if not (bridge and bridge.stations) then term094.append_donors(index);return index end')
   old='  local id=source.output.unit_number\n  local state=native_state()';assert s.count(old)==1
   s=s.replace(old,old+'''\n  if source.mode=='terminal-094' then
    local sink=source.terminal_sink
    if not(sink and sink.valid and sink.electric_network_id==source.line_port.electric_network_id)then return nil end
    state.sinks[id]=sink
    return sink
  end''')
   s=s.replace('  fair_charge(owners,art,pantograph,stats,charge_budget)','  term094.prepare(owners,function(e) return network_for_contact(e,art,pantograph) end,tick)\n  fair_charge(owners,art,pantograph,stats,charge_budget)');b=s.encode()
  if n.endswith('/scripts/brake_recovery_091.lua'):
   s=b.decode().replace('local estimate=require','local term094=require("scripts.line_terminal_094")\nlocal estimate=require').replace('function M.finish(tick,battery)','function M.finish(tick,battery,contact)')
   s=s.replace('  if not phase or phase.tick~=tick then return end\n  local s=state();local nextburn,nexttrain={},{}','  if storage.em and storage.em.em094_terminal then term094.settle_actual(state(),battery,tick,enabled()) end\n  if not phase or phase.tick~=tick then return end\n  local s=state();local nextburn,nexttrain={},{}')
   old='''local accepted=battery.recover(post.owners,grant,tick)
        if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
        s.estimated_J=s.estimated_J+grant;s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+grant-accepted;s.intervals=s.intervals+1''';assert old in s
   s=s.replace(old,'''s.estimated_J=s.estimated_J+grant;s.intervals=s.intervals+1
        local offered=term094.offer_actual(post,grant,contact)
        local remainder=grant-offered
        local accepted=battery.recover(post.owners,remainder,tick)
        if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
        s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+remainder-accepted''')
   s=s.replace('local e=unit and game.get_entity_by_unit_number(unit);','r.qa_grid_J=s.qa_grid_J or 0;r.qa_fallback_J=s.qa_fallback_J or 0;r.qa_uncertain_J=s.qa_uncertain_J or 0;r.qa_missing_J=s.qa_missing_J or 0;r.qa_pending_J=storage.em and storage.em.em094_terminal and term094.pending_actual() or 0\n  local e=unit and game.get_entity_by_unit_number(unit);');b=s.encode()
  w.writestr(n.replace('ElectrifiedMainline_0.1.102/','ElectrifiedMainline_0.1.103/'),b)
 w.writestr('ElectrifiedMainline_0.1.103/scripts/line_terminal_094.lua',(r/'line_terminal_094.lua').read_bytes())
 for lang,txt in [('ru','[mod-setting-name]\nem094-experimental-grid-regeneration=Экспериментальная рекуперация в контактную сеть\n'),('en','[mod-setting-name]\nem094-experimental-grid-regeneration=Experimental line regeneration\n')]:w.writestr('ElectrifiedMainline_0.1.103/locale/'+lang+'/em094.cfg',txt)
print(hashlib.sha256(out.read_bytes()).hexdigest())
