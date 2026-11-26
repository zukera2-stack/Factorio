import concurrent.futures as C, pathlib as P, subprocess as S, shutil, json, os, time, threading, signal
root=P.Path(__file__).parent.resolve();engine=P.Path(os.environ.get('FACTORIO_BIN','/mnt/data/em088/engine/factorio/bin/x64/factorio')).resolve();cg=P.Path('/sys/fs/cgroup');limit=int((cg/'memory.max').read_text());initial=int((cg/'memory.current').read_text());quota=(cg/'cpu.max').read_text().split();workers=min(3,int(quota[0])//int(quota[1]),(limit-initial-768*2**20)//(700*2**20));assert workers>=1
import sys
cases=sys.argv[1:] or ['station600','station2000','station4000','heavy2000','bonus2000','coast2000'];active={};lock=threading.Lock();stop=threading.Event();peak=initial;guard=[]
def monitor():
 global peak
 while not stop.wait(.15):
  m=int((cg/'memory.current').read_text());peak=max(peak,m)
  if m>limit-768*2**20:
   with lock:
    if active:guard.append(m)
    for p in active.values():os.killpg(p.pid,signal.SIGKILL)
def run(case):
 d=root/'runs'/case;d.mkdir(parents=True,exist_ok=False);mods=d/'mods';mods.mkdir();shutil.copytree(root/'qa'/'em090-brake-qa_0.0.1',mods/'em090-brake-qa_0.0.1');(mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','em090-brake-qa')]}));cfg=d/'config.ini';cfg.write_text(f'[path]\nread-data={engine.parents[2]/"data"}\nwrite-data={d}\n')
 with (d/'stdout.log').open('w') as f:
  with lock:
   if guard:return {'case':case,'pass':False,'guard':True}
   p=S.Popen(['/usr/bin/time','-f','%M %e','-o',str(d/'resource.txt'),str(engine),'--config',str(cfg),'--mod-directory',str(mods),'--threads','1','--test-scenario','em090-brake-qa/probe','--test-arg',case,'--test-ticks','910'],stdout=f,stderr=S.STDOUT,start_new_session=True);active[case]=p
  try:rc=p.wait(timeout=100)
  except S.TimeoutExpired:os.killpg(p.pid,9);rc=p.wait()
  finally:
   with lock:active.pop(case,None)
 s=(d/'stdout.log').read_text();r={'case':case,'rc':rc,'pass':rc==0 and 'Test passed at tick' in s,'result':[l for l in s.splitlines() if '[RESULT]' in l],'resource':(d/'resource.txt').read_text()};print(r,flush=True);return r
start=time.monotonic();thread=threading.Thread(target=monitor);thread.start()
try:
 with C.ThreadPoolExecutor(workers) as ex:results=list(ex.map(run,cases))
finally:stop.set();thread.join()
r={'workers':workers,'initial_bytes':initial,'peak_bytes':peak,'limit_bytes':limit,'guard':guard,'wall_s':time.monotonic()-start,'memory_events':(cg/'memory.events').read_text(),'results':results};(root/('results-'+cases[0]+'.json')).write_text(json.dumps(r,indent=2));print(r,flush=True)
