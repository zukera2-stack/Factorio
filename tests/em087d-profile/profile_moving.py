from pathlib import Path
import zipfile,shutil,subprocess,json,re,statistics
p=Path(__file__).parent; old=Path('/mnt/data/em087c');engine=old/'factorio';binary=engine/'bin/x64/factorio'
logs=p/'profile_logs';logs.mkdir(exist_ok=True)
for tag in ['base','codeonly']:
 w=p/('profile-'+tag);m=w/'mods';m.mkdir(parents=True,exist_ok=True);zname='ElectrifiedMainline_0.1.89.zip'
 with zipfile.ZipFile(p/tag/'mods'/zname) as src,zipfile.ZipFile(m/zname,'w',zipfile.ZIP_DEFLATED) as out:
  for n in src.namelist():
   data=src.read(n)
   if n.endswith('/scripts/power_bridge_058.lua'):
    s=data.decode();a=' local traction_demand=traction065.requests(art030,pantograph049,dispatch)';assert a in s
    s=s.replace(a,''' local prof_req=(tick>=130 and tick<=350 and tick%10==0) and helpers.create_profiler() or nil
'''+a+'''
 if prof_req then prof_req.stop();log({"","[EM087D PROFILE] requests tick="..tick.." ",prof_req}) end''',1);data=s.encode()
   if n.endswith('/scripts/traction_paid_065.lua'):
    s=data.decode();a='  fair_charge(owners,art,pantograph,stats)';assert a in s
    s=s.replace(a,'''  local prof_paid=(tick>=130 and tick<=350 and tick%10==0) and helpers.create_profiler() or nil
'''+a+'''
  if prof_paid then prof_paid.stop();log({"","[EM087D PROFILE] fair_charge tick="..tick.." ",prof_paid}) end''',1);data=s.encode()
   out.writestr(n,data)
 for q in (old/'evidence/qa_mods').iterdir():shutil.copytree(q,m/q.name,dirs_exist_ok=True)
 (m/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True}]+[{'name':json.loads((s/'info.json').read_text())['name'],'enabled':True} for s in m.iterdir() if s.is_dir()]}))
 cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={engine}/data\nwrite-data={w}\n')
 cmd=[str(binary),'--config',str(cfg),'--mod-directory',str(m),'--test-scenario','em-extended-qa/moving','--test-arg','100','--test-ticks','510'];out=logs/(tag+'.log')
 with out.open('w') as f:rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
 text=out.read_text();print(tag,rc,[l for l in text.splitlines() if '[MOVING] 100 PASS' in l or 'Test passed at tick' in l],flush=True)
 if rc or 'Test passed at tick' not in text:raise RuntimeError(out)
