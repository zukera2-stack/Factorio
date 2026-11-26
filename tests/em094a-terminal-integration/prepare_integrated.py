import pathlib as P,zipfile,hashlib
r=P.Path(__file__).parent;base=P.Path('/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip');out=r/'integrated-probe-QA-ONLY.zip'
assert hashlib.sha256(base.read_bytes()).hexdigest()=='eebed6e004a13b002a2a33101d771a3b7b0ee12d3dbba2bd12e19f6cb902e1a7'
with zipfile.ZipFile(base) as z,zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as w:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/scripts/control.lua'):
   s=b.decode().replace('regen091.finish(event.tick,onboard089)','regen091.finish(event.tick,onboard089,function(e) return paidTraction065.qa_contact(e,art030,pantograph049) end)')
   s+='''\n-- QA-ONLY diagnostic terminal interface. Never ship this mutation interface.\nlocal term094=require('scripts.line_terminal_094')\nremote.add_interface('em094_terminal_QA_ONLY',{ensure=function(mast)return term094.ensure(mast)~=nil end,snapshot=term094.snapshot})\n''';b=s.encode()
  if n.endswith('/scripts/traction_paid_065.lua'):
   s=b.decode().replace('local function active_bridge_index()', 'M.qa_contact=network_for_contact\nlocal term094=require("scripts.line_terminal_094")\nlocal function active_bridge_index()')
   old='  return index\nend\nlocal function phase_bridge';assert s.count(old)==1
   s=s.replace(old,'  term094.append_donors(index)\n  return index\nend\nlocal function phase_bridge')
   s=s.replace('if not (bridge and bridge.stations) then return index end','if not (bridge and bridge.stations) then term094.append_donors(index);return index end')
   old='  local id=source.output.unit_number\n  local state=native_state()';assert s.count(old)==1
   s=s.replace(old,'''  local id=source.output.unit_number
  local state=native_state()
  if source.mode=='terminal-094-qa' then
    local sink=source.terminal_sink
    if not(sink and sink.valid and sink.electric_network_id==source.line_port.electric_network_id)then return nil end
    state.sinks[id]=sink
    return sink
  end''');b=s.encode()
  if n.endswith('/scripts/brake_recovery_091.lua'):
   s=b.decode().replace('local estimate=require', 'local term094=require("scripts.line_terminal_094")\nlocal estimate=require')
   s=s.replace('function M.finish(tick,battery)','function M.finish(tick,battery,contact)')
   s=s.replace('local s=state();local nextburn,nexttrain={},{}','local s=state();term094.settle_actual(s,battery,tick,contact);local nextburn,nexttrain={},{}')
   old='''local accepted=battery.recover(post.owners,grant,tick)
        if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
        s.estimated_J=s.estimated_J+grant;s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+grant-accepted;s.intervals=s.intervals+1''';assert old in s
   s=s.replace(old,'''s.estimated_J=s.estimated_J+grant;s.intervals=s.intervals+1
        local offered=term094.offer_actual(post,grant,contact)
        local remainder=grant-offered
        local accepted=battery.recover(post.owners,remainder,tick)
        if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
        s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+remainder-accepted''')
   s=s.replace('local e=unit and game.get_entity_by_unit_number(unit);','r.qa_grid_J=s.qa_grid_J or 0;r.qa_fallback_J=s.qa_fallback_J or 0;r.qa_uncertain_J=s.qa_uncertain_J or 0;r.qa_pending_J=term094.pending_actual()\n  local e=unit and game.get_entity_by_unit_number(unit);');b=s.encode()
  w.writestr(n,b)
 w.writestr('ElectrifiedMainline_0.1.102/scripts/line_terminal_094.lua',(r/'line_terminal_094.lua').read_bytes())
print(hashlib.sha256(out.read_bytes()).hexdigest())
