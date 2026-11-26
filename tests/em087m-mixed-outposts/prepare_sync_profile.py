from pathlib import Path
import zipfile,shutil,argparse
p=argparse.ArgumentParser();p.add_argument('--base-profile',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();src=a.base_profile.resolve();w=a.output.resolve();w.mkdir(parents=True,exist_ok=False);shutil.copytree(src/'mods',w/'mods');(w/'config.ini').write_text((src/'config.ini').read_text().replace(str(src),str(w)))
m=w/'mods'/'ElectrifiedMainline_0.1.98.zip'; tmp=m.with_suffix('.tmp');
with zipfile.ZipFile(m) as z,zipfile.ZipFile(tmp,'w',zipfile.ZIP_DEFLATED) as out:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/scripts/technical_network_046.lua'):
   s=b.decode();start=s.index('function M.sync(graph,changes)');end=s.index('function M.mark_dirty',start);q=s[start:end]
   q=q.replace('  local s=M.ensure_storage()', '''  local prof=game.tick==600 and helpers.create_profiler() or nil
  local function mark(label) if prof then prof.stop();log({"","[EM087P SYNC] tick="..game.tick.." "..label.." ",prof});prof=helpers.create_profiler() end end
  local s=M.ensure_storage()''',1)
   for needle,label in [('  local failures=0','parents'),('  local candidates,valid=candidates_for(nodes)','anchors'),('  local old=s.plan_groups or {}','candidates_partition'),('  local fresh=select_edges','attachments'),('  for k,e in pairs(fresh)','path_selection'),('  update_watch(s,dependencies,reused)','collect_dependencies'),('  if not full then log','watch_update'),('  local connected,missed,desired=0,0,0','wire_audit'),('  s.stats={desired=','verify_repair')]:
    assert q.count(needle)==1,needle;q=q.replace(needle,'  mark("'+label+'")\n'+needle)
   q=q.replace('  return M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)','  local changed=M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)\n  mark("components")\n  return changed');b=(s[:start]+q+s[end:]).encode()
  if n.endswith('/scripts/power_bridge_058.lua'):
   s=b.decode();needle='     live_corridor={}';assert s.count(needle)==1;s=s.replace(needle,'''     local cp=prof and helpers.create_profiler() or nil
     live_corridor={}''');needle='   end\n   return live_corridor';assert s.count(needle)==1;s=s.replace(needle,'''     if cp then cp.stop();log({"","[EM087P CORRIDOR] tick="..tick.." scan ",cp}) end
   end
   return live_corridor''');b=s.encode()
  out.writestr(n,b)
tmp.replace(m)
