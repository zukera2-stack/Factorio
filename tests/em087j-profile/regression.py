from pathlib import Path
import json,subprocess,shutil,concurrent.futures,time,sys
p=Path(__file__).parent;old=Path('/mnt/data/em087c/evidence');engine=old.parent/'factorio';binary=engine/'bin/x64/factorio';logs=p/'regression';logs.mkdir(exist_ok=True)
source=p/'candidate/mods/ElectrifiedMainline_0.1.96.zip'
cases=json.loads((old/'regression_cases.json').read_text())
for name,cap in [('segments',30),('corridor',1270)]:cases.append(dict(case='native-'+name,marker='Test passed at tick',command=['','','','','','--test-scenario','em-native-segment-qa/'+name,'--test-ticks',str(cap)]))
# Prioritize paid traction, 401 and 100 moving, network fault/rejoin.
priority=['audit-fair','audit-offgrid','extended-power401','moving-100','extended-dual201','attach-bidir','network-topology','network-multi48','audit-retain','audit-churn100','migration085','extended-split','native-corridor','native-segments']
cases=sorted(cases,key=lambda r:priority.index(r['case']) if r['case'] in priority else len(priority));cases=[r for r in cases if not sys.argv[1:] or r['case'] in sys.argv[1:]]
workers=[]
for i in range(3):
 w=p/f'worker{i}';m=w/'mods';m.mkdir(parents=True,exist_ok=True);shutil.copy2(source,m/source.name)
 for s in (old/'qa_mods').iterdir():shutil.copytree(s,m/s.name,dirs_exist_ok=True)
 (m/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True}]+[{'name':json.loads((s/'info.json').read_text())['name'],'enabled':True} for s in m.iterdir() if s.is_dir()]}))
 cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={engine}/data\nwrite-data={w}\n');workers.append((w,m,cfg))
print('planned',len(cases),flush=True)
def run(i):
 w,m,cfg=workers[i]
 for r in cases[i::3]:
  args=[str(old/'saves/long201.zip') if x.endswith('/long201.zip') else x for x in r['command'][5:]]
  cmd=[str(binary),'--config',str(cfg),'--mod-directory',str(m)]+args;out=logs/(r['case']+'.log');t=time.monotonic()
  with out.open('w') as f:
   try:rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=240).returncode
   except subprocess.TimeoutExpired:rc=124
  data=out.read_text(errors='replace');status='PASS' if rc==0 and r['marker'] in data else 'FAIL' if rc!=0 else 'INCONCLUSIVE'
  rec=dict(case=r['case'],status=status,rc=rc,seconds=round(time.monotonic()-t,3),marker=r['marker'],command=cmd,last=data.splitlines()[-5:]);(logs/(r['case']+'.json')).write_text(json.dumps(rec,indent=2));print(r['case'],status,rec['seconds'],flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as ex:list(ex.map(run,range(3)))
