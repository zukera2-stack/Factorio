#!/usr/bin/env python3
"""Linux cgroup v2 bounded QA, separate config/write-data/mods/log for every process."""
import zipfile,io
import argparse, concurrent.futures as cf, hashlib, json, os, pathlib as P, shutil, subprocess as S, time, threading, signal
p=argparse.ArgumentParser(); p.add_argument('--factorio',type=P.Path,required=True);p.add_argument('--full-mod',type=P.Path,required=True);p.add_argument('--output',type=P.Path,required=True);p.add_argument('--workers',type=int,default=2);p.add_argument('--case',action='append');p.add_argument('--reserve-mib',type=int,default=768);p.add_argument('--worker-mib',type=int,default=1024);p.add_argument('--timeout',type=int,default=240);a=p.parse_args()
root=P.Path(__file__).resolve().parent;core=root.parent.parent/'em088/k';history=root.parent.parent/'em088/l';eng=a.factorio.resolve();archive=a.full_mod.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
cg=P.Path('/sys/fs/cgroup')
def read(n):return (cg/n).read_text().strip()
limit=int(read('memory.max'));base=int(read('memory.current'));cpu=read('cpu.max').split();quota=int(cpu[0])/int(cpu[1]) if cpu[0]!='max' else len(os.sched_getaffinity(0)); reserve=a.reserve_mib*2**20
workers=min(a.workers,max(1,int(quota)),(limit-base-reserve)//(a.worker_mib*2**20));assert workers>=1,'insufficient budget'
archive_bytes=archive.read_bytes()
assert hashlib.sha256(archive_bytes).hexdigest()=='eebed6e004a13b002a2a33101d771a3b7b0ee12d3dbba2bd12e19f6cb902e1a7'
assert '2.1.24 (build 87808' in S.check_output([str(eng),'--version'],text=True)
print('budget',limit,base,'CPU',quota,'workers',workers,flush=True)
lock=threading.Lock();active={};peak=base;samples=[];stop=threading.Event();guard=[];abort=threading.Event()
def monitor():
 global peak
 while not stop.wait(.15):
  m=int(read('memory.current'));peak=max(peak,m)
  with lock:
   samples.append([round(time.monotonic()-start,3),m,len(active)])
   if m>limit-reserve and active and not abort.is_set():
    abort.set();guard.append({'cases':list(active),'memory':m})
    for proc in active.values():
     try:os.killpg(proc.pid,signal.SIGKILL)
     except ProcessLookupError:pass
def run(name):
 if abort.is_set():return {'case':name,'pass':False,'rc':None,'reason':'memory guard'}
 d=out/name;mods=d/'mods';mods.mkdir(parents=True);zipfile.ZipFile(io.BytesIO(archive_bytes)).extractall(mods);q=root/'em-mixed-outposts-qa_0.0.1';shutil.copytree(q,mods/q.name)
 if name in core_cases:
  for src in list((core/'qa/core').iterdir())+[core/'qa/watch',core/'qa/fault',core/'qa/vanilla']:
   info=json.loads((src/'info.json').read_text());shutil.copytree(src,mods/(info['name']+'_'+info['version']))
  shutil.copytree(history/'qa/wake-idle',mods/'em-extended-qa_0.0.1/scenarios/wake-idle',dirs_exist_ok=True)
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in (['base','ElectrifiedMainline','em-mixed-outposts-qa']+[json.loads((x/'info.json').read_text())['name'] for x in mods.iterdir() if x.is_dir() and x.name not in ('em-mixed-outposts-qa_0.0.1','ElectrifiedMainline_0.1.102')])]}))
 cfg=d/'config.ini';cfg.write_text(f'[path]\nread-data={eng.parents[2]/"data"}\nwrite-data={d}\n')
 args=['--test-scenario','em-mixed-outposts-qa/native','--test-arg',name,'--test-ticks','1520']
 if name=='bus':args=['--test-scenario','em-mixed-outposts-qa/bus','--test-ticks','450']
 if name=='bus-load':args=['--test-save',str(out.parent/'bus-checkpoint.zip'),'--test-ticks','450']
 if name=='scale':args=['--test-scenario','em-mixed-outposts-qa/scale','--test-ticks','1520']
 if name=='disk-load':args=['--test-save',str(root/'mixed-outposts-t901.zip'),'--test-arg','mixed','--test-ticks','1520']
 if name.startswith('stress'):args=['--test-scenario','em-mixed-outposts-qa/stress','--test-arg',name.removeprefix('stress'),'--test-ticks','1520']
 if name in core_cases:args=core_cases[name]['args']
 t=time.monotonic();log=d/'stdout.log'
 with log.open('w') as f:
  with lock:
   if abort.is_set():return {'case':name,'pass':False,'rc':None,'reason':'memory guard'}
   proc=S.Popen(['/usr/bin/time','-f','%M %e','-o',str(d/'resource.txt'),str(eng),'--config',str(cfg),'--mod-directory',str(mods),'--threads','1']+args,stdout=f,stderr=S.STDOUT,start_new_session=True);active[name]=proc
  try:rc=proc.wait(timeout=a.timeout)
  except S.TimeoutExpired:os.killpg(proc.pid,9);rc=proc.wait()
  finally:
   with lock:active.pop(name,None)
 shutil.rmtree(mods/'ElectrifiedMainline_0.1.102')
 s=log.read_text(errors='replace');r={'case':name,'rc':rc,'pass':rc==0 and (core_cases[name]['marker'] if name in core_cases else 'Test passed at tick') in s,'wall_s':round(time.monotonic()-t,3),'resource':(d/'resource.txt').read_text().strip() if (d/'resource.txt').exists() else None};print(json.dumps(r),flush=True);return r
core_cases={}
for f in (history/'qa087l').glob('*.json'):
 d=json.loads(f.read_text());args=[str(core/'saves'/P.Path(x).name) if x.endswith('.zip') else x for x in d['command'][5:]];core_cases[d['name']]={'args':args,'marker':d['marker']}
core_cases['wake-idle']={'args':['--test-scenario','em-extended-qa/wake-idle','--test-arg','1','--test-ticks','670'],'marker':'Test passed at tick'}
start=time.monotonic();th=threading.Thread(target=monitor,daemon=True);th.start();names=a.case or sorted(core_cases,key=lambda n:0 if n in ('moving-100','audit-churn100','network-topology','network-multi48','moving-50','bench-100x2') else 1)
assert len(names)==len(set(names)) and all(n.replace('-','').isalnum() for n in names)
try:
 with cf.ThreadPoolExecutor(max_workers=workers) as ex:results=list(ex.map(run,names))
finally:stop.set();th.join()
report={'workers':workers,'limit_bytes':limit,'initial_bytes':base,'peak_bytes':peak,'reserve_bytes':reserve,'worker_budget_bytes':a.worker_mib*2**20,'cpu_quota':quota,'wall_s':round(time.monotonic()-start,3),'guard':guard,'memory_events':read('memory.events'),'results':results,'samples':samples};(out/'parallel.json').write_text(json.dumps(report,indent=2));print({k:v for k,v in report.items() if k not in ('results','samples')},flush=True);assert all(r['pass'] for r in results)
