import pathlib as P,zipfile,hashlib
r=P.Path('/mnt/data/em092');base=r/'direct-probe.zip';out=r/'exchange-probe.zip'
with zipfile.ZipFile(base) as z,zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as w:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/scripts/traction_paid_065.lua'):
   s=b.decode().replace('local function active_bridge_index()', 'M.qa_contact=network_for_contact\nlocal function active_bridge_index()'); b=s.encode()
  if n.endswith('/scripts/control.lua'):
   s=b.decode().replace('regen091.finish(event.tick,onboard089)','regen091.finish(event.tick,onboard089,function(e) return paidTraction065.qa_contact(e,art030,pantograph049) end)');b=s.encode()
  if n.endswith('/scripts/brake_recovery_091.lua'):
   s=b.decode();s=s.replace('function M.finish(tick,battery)','''-- EM092/093 proof only: no production release. The fixture's source marker
-- is not available in the real mod. One pending native offer at a time.
local function settle_qa(s,battery,tick,contact)
  local p=s.qa_pending;if not p then return end
  local e=game.get_entity_by_unit_number(p.source)
  assert(e and e.valid and e.electric_network_id==p.net and e.energy<=p.amount+.01 and e.energy>=0,'QA pending topology/energy mismatch')
  local remaining=e.energy;e.output_flow_limit=0;e.energy=0
  local sent=p.amount-remaining
  local owners={};local valid=true
  for _,id in ipairs(p.owners) do local o=game.get_entity_by_unit_number(id);if not(o and o.valid and o.train and o.train.id==p.train and contact(o)==p.net) then valid=false else owners[#owners+1]=o end end
  local stored=valid and battery.recover(owners,remaining,tick) or 0
  s.qa_grid_J=(s.qa_grid_J or 0)+sent;s.qa_fallback_J=(s.qa_fallback_J or 0)+stored
  s.recovered_J=s.recovered_J+sent+stored;s.rejected_J=s.rejected_J+remaining-stored
  s.qa_pending=nil
end
local function offer_qa(s,post,grant,contact)
  if s.qa_pending or not prototypes.entity['em092-qa-finite-source'] then return false end
  local lab=game.surfaces['em-25kv-isolated-bridge-058'];if not lab then return false end
  for _,o in ipairs(post.owners) do
    local net=contact(o)
    if net then for _,e in ipairs(lab.find_entities_filtered{name='em092-qa-finite-source'}) do
      if e.valid and e.force==o.force and e.electric_network_id==net and e.energy<1e-8 then
        local owners={};for _,a in ipairs(post.owners)do owners[#owners+1]=a.unit_number end
        e.energy=grant;e.output_flow_limit=grant;s.qa_pending={source=e.unit_number,net=net,amount=grant,owners=owners,train=post.id};s.qa_offered_J=(s.qa_offered_J or 0)+grant
        return true
      end
    end end
  end
  return false
end
function M.finish(tick,battery,contact)''');s=s.replace('local s=state();local nextburn,nexttrain={},{}','local s=state();settle_qa(s,battery,tick,contact);local nextburn,nexttrain={},{}');old='''local accepted=battery.recover(post.owners,grant,tick)
        if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
        s.estimated_J=s.estimated_J+grant;s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+grant-accepted;s.intervals=s.intervals+1''';new='''s.estimated_J=s.estimated_J+grant;s.intervals=s.intervals+1
        if not offer_qa(s,post,grant,contact) then
          local accepted=battery.recover(post.owners,grant,tick)
          if accepted>0 then s.last_credit_tick=tick;s.last_credit_J=accepted end
          s.recovered_J=s.recovered_J+accepted;s.rejected_J=s.rejected_J+grant-accepted
        end''';assert old in s;s=s.replace(old,new);s=s.replace('local e=unit and game.get_entity_by_unit_number(unit);','r.qa_grid_J=s.qa_grid_J or 0;r.qa_offered_J=s.qa_offered_J or 0;r.qa_fallback_J=s.qa_fallback_J or 0;r.qa_pending_J=s.qa_pending and s.qa_pending.amount or 0\n  local e=unit and game.get_entity_by_unit_number(unit);');b=s.encode()
  w.writestr(n,b)
print(hashlib.sha256(out.read_bytes()).hexdigest())
