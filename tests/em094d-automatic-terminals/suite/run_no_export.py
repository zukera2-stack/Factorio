#!/usr/bin/env python3
"""Linux cgroup v2 bounded QA, separate config/write-data/mods/log for every process."""
import zipfile,io
import argparse, concurrent.futures as cf, hashlib, json, os, pathlib as P, shutil, subprocess as S, time, threading, signal
p=argparse.ArgumentParser(); p.add_argument('--factorio',type=P.Path,required=True);p.add_argument('--full-mod',type=P.Path,required=True);p.add_argument('--output',type=P.Path,required=True);p.add_argument('--workers',type=int,default=2);p.add_argument('--case',action='append');p.add_argument('--reserve-mib',type=int,default=768);p.add_argument('--worker-mib',type=int,default=1024);p.add_argument('--timeout',type=int,default=240);a=p.parse_args()
root=P.Path(__file__).resolve().parent;eng=a.factorio.resolve();archive=a.full_mod.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
cg=P.Path('/sys/fs/cgroup')
def read(n):return (cg/n).read_text().strip()
limit=int(read('memory.max'));base=int(read('memory.current'));cpu=read('cpu.max').split();quota=int(cpu[0])/int(cpu[1]) if cpu[0]!='max' else len(os.sched_getaffinity(0)); reserve=a.reserve_mib*2**20
workers=min(a.workers,max(1,int(quota)),(limit-base-reserve)//(a.worker_mib*2**20));assert workers>=1,'insufficient budget'
archive_bytes=archive.read_bytes()
assert hashlib.sha256(archive_bytes).hexdigest()=='323ce8ab0aa14efcf5a2c78f6b46fcb0ae6a237ef38bbd7482d89725501c14e1'
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
 if name.startswith('onboard-'):shutil.copy2(root/'onboard-mod-settings.dat',mods/'mod-settings.dat')
 if name in ('train-same-terminal','train-lifecycle'):shutil.copy2(root/'regen-mod-settings.dat',mods/'mod-settings.dat')
 if name.startswith(('train-exchange-','train-topology-','train-pending-')):shutil.copy2(root/'regen-mod-settings.dat',mods/'mod-settings.dat')
 if name.startswith('regen-'):shutil.copy2(root/('regen-onboard-only.dat' if name=='regen-stress-control' else 'onboard-mod-settings.dat' if name=='regen-disabled' else 'regen-mod-settings.dat'),mods/'mod-settings.dat')
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','ElectrifiedMainline','em-mixed-outposts-qa')]}))
 cfg=d/'config.ini';cfg.write_text(f'[path]\nread-data={eng.parents[2]/"data"}\nwrite-data={d}\n')
 args=['--test-scenario','em-mixed-outposts-qa/native','--test-arg',name,'--test-ticks','1520']
 if name.startswith('regen-'):args=['--test-scenario','em-mixed-outposts-qa/regen','--test-arg',name.removeprefix('regen-'),'--test-ticks','3500']
 if name.startswith('onboard-'):args=['--test-scenario','em-mixed-outposts-qa/onboard','--test-arg',name.removeprefix('onboard-'),'--test-ticks','2450']
 if name.startswith('onboard-stress'):args=['--test-scenario','em-mixed-outposts-qa/onboard-stress','--test-arg',name.removeprefix('onboard-stress'),'--test-ticks','1520']
 if name.startswith('regen-stress'):args=['--test-scenario','em-mixed-outposts-qa/regen-stress','--test-arg',name.removeprefix('regen-stress'),'--test-ticks','1520']
 if name=='regen-stress-no-export':args=['--test-scenario','em-mixed-outposts-qa/regen-stress-no-export','--test-arg','12','--test-ticks','1520']
 if name=='regen-stress-control':args=['--test-scenario','em-mixed-outposts-qa/regen-stress','--test-arg','12','--test-ticks','1520']
 if name=='regen-reload-load':args=['--test-save',str(out.parent/'regen-checkpoint.zip'),'--test-arg','reload','--test-ticks','1500']
 if name=='onboard-migration-load':args=['--test-save',str(out.parent/'onboard-migration.zip'),'--test-ticks','450']
 if name=='onboard-reload-load':args=['--test-save',str(out.parent/'onboard-checkpoint.zip'),'--test-arg','reload','--test-ticks','800']
 if name.startswith('line-'):args=['--test-scenario','em-mixed-outposts-qa/line-probe','--test-arg',name.removeprefix('line-'),'--test-ticks','560']
 if name.startswith('terminal-'):args=['--test-scenario','em-mixed-outposts-qa/terminal','--test-arg',name.removeprefix('terminal-'),'--test-ticks','620']
 if name.startswith('train-exchange-'):args=['--test-scenario','em-mixed-outposts-qa/train-exchange','--test-arg',name.removeprefix('train-exchange-'),'--test-ticks','560']
 if name.startswith('topology-'):args=['--test-scenario','em-mixed-outposts-qa/topology','--test-arg',name.removeprefix('topology-'),'--test-ticks','140']
 if name.startswith('train-topology-'):args=['--test-scenario','em-mixed-outposts-qa/train-topology','--test-arg',name.removeprefix('train-topology-'),'--test-ticks','560']
 if name=='train-pending-reload':args=['--test-save',str(root.parent/'terminal-checkpoint.zip'),'--test-arg','reload','--test-ticks','560']
 if name=='train-lifecycle':args=['--test-scenario','em-mixed-outposts-qa/train-lifecycle','--test-ticks','450']
 if name=='train-same-terminal':args=['--test-scenario','em-mixed-outposts-qa/train-same-terminal','--test-ticks','560']
 if name=='bus':args=['--test-scenario','em-mixed-outposts-qa/bus','--test-ticks','450']
 if name=='migration-load':args=['--test-save',str(out.parent/'migration-checkpoint.zip'),'--test-ticks','450']
 if name=='bus-load':args=['--test-save',str(out.parent/'bus-checkpoint.zip'),'--test-ticks','450']
 if name=='scale':args=['--test-scenario','em-mixed-outposts-qa/scale','--test-ticks','1520']
 if name=='disk-load':args=['--test-save',str(root/'mixed-outposts-t901.zip'),'--test-arg','mixed','--test-ticks','1520']
 if name.startswith('stress'):args=['--test-scenario','em-mixed-outposts-qa/stress','--test-arg',name.removeprefix('stress'),'--test-ticks','1520']
 t=time.monotonic();log=d/'stdout.log'
 with log.open('w') as f:
  with lock:
   if abort.is_set():return {'case':name,'pass':False,'rc':None,'reason':'memory guard'}
   proc=S.Popen(['/usr/bin/time','-f','%M %e','-o',str(d/'resource.txt'),str(eng),'--config',str(cfg),'--mod-directory',str(mods),'--threads','1']+args,stdout=f,stderr=S.STDOUT,start_new_session=True);active[name]=proc
  try:rc=proc.wait(timeout=a.timeout)
  except S.TimeoutExpired:os.killpg(proc.pid,9);rc=proc.wait()
  finally:
   with lock:active.pop(name,None)
 s=log.read_text(errors='replace');r={'case':name,'rc':rc,'pass':rc==0 and 'Test passed at tick' in s,'wall_s':round(time.monotonic()-t,3),'resource':(d/'resource.txt').read_text().strip() if (d/'resource.txt').exists() else None};print(json.dumps(r),flush=True);return r
start=time.monotonic();th=threading.Thread(target=monitor,daemon=True);th.start();names=a.case or ['mixed','reverse','ring','train','solar','empty','battery','buffer','limit','scale','disk-load']
assert len(names)==len(set(names)) and all(n.replace('-','').isalnum() for n in names)
try:
 with cf.ThreadPoolExecutor(max_workers=workers) as ex:results=list(ex.map(run,names))
finally:stop.set();th.join()
report={'workers':workers,'limit_bytes':limit,'initial_bytes':base,'peak_bytes':peak,'reserve_bytes':reserve,'worker_budget_bytes':a.worker_mib*2**20,'cpu_quota':quota,'wall_s':round(time.monotonic()-start,3),'guard':guard,'memory_events':read('memory.events'),'results':results,'samples':samples};(out/'parallel.json').write_text(json.dumps(report,indent=2));print({k:v for k,v in report.items() if k not in ('results','samples')},flush=True);assert all(r['pass'] for r in results)
