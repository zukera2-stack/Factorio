from pathlib import Path
import zipfile,subprocess,shutil,sys
p=Path(__file__).parent;old=Path('/mnt/data/em087i');eng=Path('/mnt/data/em087c/factorio'); base=p/'codeonly/mods/ElectrifiedMainline_0.1.95.zip'
w=p/'profile-new';m=w/'mods';m.mkdir(parents=True,exist_ok=True)
shutil.copytree(old/'candidate/mods/em-audit-qa_0.0.1',m/'em-audit-qa_0.0.1',dirs_exist_ok=True);shutil.copy2(old/'candidate/mods/mod-list.json',m/'mod-list.json');(w/'config.ini').write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
with zipfile.ZipFile(base) as z,zipfile.ZipFile(m/base.name,'w',zipfile.ZIP_DEFLATED) as out:
 for f in z.namelist():
  b=z.read(f)
  if f.endswith('/scripts/control.lua'):
   s=b.decode();s=s.replace('local function on_tick(event)','''local function emj_profile(label,fn,...)
    local tick=game.tick
    if tick%60~=0 and tick%60~=1 and tick%60~=59 then return fn(...) end
    local p=helpers.create_profiler();local a,b=fn(...);p.stop();log({"",'[EM087J PROFILE] tick='..tick..' '..label..' ',p});return a,b
end
local function on_tick(event)''')
   for name in ['technical046','mast059','bridge058','art030','helper067','paidTraction065','power019']:
    s=s.replace(name+'.on_tick(', 'emj_profile("'+name+'",'+name+'.on_tick,')
   b=s.encode()
  if f.endswith('/scripts/technical_network_046.lua'):
   s=b.decode();s=s.replace('  local nodes,parents={},{}','  local prof=helpers.create_profiler()\n  local function mark(label) prof.stop();log({"","[EM087J SYNC] tick="..game.tick.." "..label.." ",prof});prof=helpers.create_profiler() end\n  local nodes,parents={},{}');
   for before,label in [('  local candidates,valid=candidates_for(nodes)\n  local groups','anchors'),('  local fresh=select_edges(work','partition'),('  for k,e in pairs(fresh)','path_search'),('  local removed,rejected,verified,anchors,connectors=audit(s)','watch'),('  local connected,missed,desired=0,0,0','wire_audit'),('  s.stats={desired=desired','connect')]:
    assert s.count(before)==1,(label,s.count(before));s=s.replace(before,'  mark("'+label+'")\n'+before)
   b=s.encode()
  out.writestr(f,b)
cmd=[str(eng/'bin/x64/factorio'),'--config',str(w/'config.ini'),'--mod-directory',str(m),'--benchmark','/mnt/data/em087c/evidence/saves/100x2.zip','--benchmark-ticks','500','--benchmark-runs','1']
with (p/'profile100-new.log').open('w') as f: rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
print(rc)
