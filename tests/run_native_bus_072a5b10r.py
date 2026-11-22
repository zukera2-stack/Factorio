#!/usr/bin/env python3
"""Research ONLY: true Factorio native train split/merge + finite shared battery and protected standalone reserve.
No gameplay source or owner saves touched; Base native locomotives + non-generating/no-battery motor-cargo and motor-fluid wagons.
"""
import argparse, subprocess, json, shutil, hashlib, re, time, socket
from pathlib import Path

def run(cmd,path,timeout=120):
 with path.open('w') as f:subprocess.run([str(x) for x in cmd],stdout=f,stderr=subprocess.STDOUT,check=True,timeout=timeout)
 return path.read_text()

def verify(log,full=True):
 required=['[B10R VERIFIED PASS]','[B10R FINAL PASS]']
 if full: required=['[B10R TOPOLOGY PASS]','[B10R SPLIT PASS]','[B10R REJOIN PASS]','[B10R WAGON FORGED BATTERY REJECTED PASS]','[B10R GROUP RESERVE PASS]','[B10R BEFORE FORMER MEMBER SPLIT PASS]','[B10R FORMER MEMBER SPLIT PASS]']+required
 for m in required:
  assert m in log,'Native Factorio marker missing: '+m+' '+log[-1800:]
 match=re.search(r'\[B10R VERIFIED PASS\] split_events=(\d+) group_moved_tiles=([\d.]+) independent_solo_moved_tiles=([\d.]+) former_member_solo_moved_tiles=([\d.]+) pooled_battery_to_burner_J=(\d+) original_solo_to_burner_J=(\d+) former_solo_to_burner_J=(\d+) remaining_A_protected_J=(\d+) wagon_saved_J=(\d+) gross_native_spent_J=([\d.]+) finite_ledger_residual_J=([-\d.]+)',log)
 assert match,'Native measured ledger line missing'
 d=list(map(float,match.groups()))
 assert d[0]>=10 and min(d[1],d[2],d[3])>.5,'real movement or split count failed'
 assert [int(x) for x in d[4:9]]==[800000,300000,200000,200000,0],d
 assert abs(d[9]-1300000)<.01 and abs(d[10])<.01,d
 keys=['split_events','group_moved_tiles','independent_solo_moved_tiles','former_member_solo_moved_tiles','pooled_battery_j','original_solo_battery_j','former_member_solo_battery_j','remaining_loco_a_j','motor_wagon_storage_j','burner_spent_j','energy_residual_j']
 return dict(zip(keys,d))

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--factorio',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--probe',type=Path,default=Path(__file__).parent/'tests/em072a5-b10r-probe');ap.add_argument('--benchmark-only',action='store_true');a=ap.parse_args()
 exe=a.factorio.resolve();assert '2.1.24 (build 87808' in subprocess.run([str(exe),'--version'],capture_output=True,text=True,check=True).stdout
 out=a.output.resolve();assert not out.exists() or not any(out.iterdir()),'scratch output must be empty';out.mkdir(parents=True,exist_ok=True)
 mods=out/'mods';mods.mkdir();shutil.copytree(a.probe.resolve(),mods/'em072a5-b10r-probe_0.0.1')
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em072a5-b10r-probe','enabled':True}]+[{'name':n,'enabled':False} for n in ['space-age','elevated-rails','quality','recycler']]}))
 private=out/'private';(private/'saves').mkdir(parents=True)
 cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(cfg),'--mod-directory',str(mods)]
 run(cmd+['--create',str(out/'start.zip')],out/'create.log')
 bench=run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','241','--benchmark-runs','1'],out/'native.log')
 base=verify(bench)
 info={'engine':'Factorio 2.1.24 build 87808','source':'Base-only native B10R compliant locomotive battery-only bus; GAMEPLAY MOD UNCHANGED','benchmark_native_ticks':241,'benchmark':base,'benchmark_log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest()}
 if a.benchmark_only:
  (out/'result.json').write_text(json.dumps(info,indent=2)+'\n');print('[B10R NATIVE BENCHMARK PASS]',json.dumps(info));return
 run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
 settings={'name':'B10R compliant locomotive-only battery train bus research','description':'disposable no owner save','max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
 (out/'server-settings.json').write_text(json.dumps(settings))
 with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
 serverlog=out/'server.log';save=private/'saves/em072a5-b10r-checkpoint.zip'
 with serverlog.open('w') as f:
  proc=subprocess.Popen([str(x) for x in cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
  try:
   for _ in range(190):
    time.sleep(.25);txt=serverlog.read_text(errors='replace')
    if proc.poll() is not None:raise RuntimeError('native headless server exited: '+txt[-2000:])
    if save.is_file() and '[B10R DISK SAVE] tick=100 requested=true' in txt and 'Saving finished' in txt:break
   else:raise TimeoutError('independent SAVE t100 not completed; '+txt[-1600:])
  finally:
   proc.terminate()
   try:proc.wait(timeout=7)
   except subprocess.TimeoutExpired:proc.kill();proc.wait()
 reload=run(cmd+['--test-save',str(save),'--test-ticks','141'],out/'native-reload.log')
 post=verify(reload,full=False)
 for k,v in base.items():assert abs(v-post[k])<.001, 'SAVE LOAD changed measured metric: '+k
 info.update(reload=post,server_SAVE_tick=100,independent_LOAD_ticks=141,checkpoint_bytes=save.stat().st_size,reload_log_sha256=hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest())
 (out/'result.json').write_text(json.dumps(info,indent=2)+'\n')
 print('[EM072 A5 B10R REAL FACTORIO ENGINE + DISK SAVE LOAD PASS]',json.dumps(info))
if __name__=='__main__':main()