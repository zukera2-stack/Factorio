#!/usr/bin/env python3
"""Research ONLY: true Factorio native train split/merge + finite shared battery and protected standalone reserve.
No gameplay source or owner saves touched; Base native locomotives + experimental motor-wagon energy contributor.
"""
import argparse, subprocess, json, shutil, hashlib, re, time, socket
from pathlib import Path

def run(cmd,path,timeout=120):
 with path.open('w') as f:subprocess.run([str(x) for x in cmd],stdout=f,stderr=subprocess.STDOUT,check=True,timeout=timeout)
 return path.read_text()

def verify(log,full=True):
 required=['[EM072 B10 REAL SPLIT PASS]','[EM072 B10 REAL REJOIN PASS]','[EM072 B10 BUS RESERVE PASS]','[EM072 B10 BATTERY BUS NATIVE PASS]','[EM072 B10 FINAL PASS]']
 if full:required.insert(0,'[EM072 B10 TOPOLOGY PASS]')
 else:required=['[EM072 B10 BATTERY BUS NATIVE PASS]','[EM072 B10 FINAL PASS]']
 for m in required:assert m in log,'Native Factorio PASS marker missing: '+m+' '+log[-1000:]
 m=re.search(r'\[EM072 B10 BATTERY BUS NATIVE PASS\] real_split_rejoin_events=(\d+) coupled_moving_delta=([\d.]+) solo_moving_delta=([\d.]+) train_bus_grants_J=(\d+) solo_grants_J=(\d+) protected_coupled_J=(\d+) solo_remaining_J=([\d.]+) native_spent_J=([\d.]+) total_ledger_residual_J=([-\d.]+)',log)
 assert m, 'Missing native J ledger'
 v=[float(x) for x in m.groups()];assert v[0]>=6 and v[1]>.5 and v[2]>.5
 assert abs(v[3]-1100000)<.01 and abs(v[4]-300000)<.01 and abs(v[5]-500000)<.01 and v[6]<.01 and abs(v[8])<.01
 assert abs(v[7]-1400000)<.01,'actual LuaBurner did not spend native credited J'
 return dict(zip(['split_merge_events','consist_real_movement_tiles','solo_real_movement_tiles','train_bus_credited_j','solo_native_burner_credited_j','all_coupled_protected_reserve_j','solo_final_j','native_spent_j','finite_ledger_residual_j'],v))

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--factorio',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--probe',type=Path,default=Path(__file__).parent/'tests/em072a5-b10-probe');ap.add_argument('--benchmark-only',action='store_true');a=ap.parse_args()
 exe=a.factorio.resolve();assert '2.1.24 (build 87808' in subprocess.run([str(exe),'--version'],capture_output=True,text=True,check=True).stdout
 out=a.output.resolve();assert not out.exists() or not any(out.iterdir()),'scratch output must be empty';out.mkdir(parents=True,exist_ok=True)
 mods=out/'mods';mods.mkdir();shutil.copytree(a.probe.resolve(),mods/'em072a5-b10-probe_0.0.1')
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em072a5-b10-probe','enabled':True}]+[{'name':n,'enabled':False} for n in ['space-age','elevated-rails','quality','recycler']]}))
 private=out/'private';(private/'saves').mkdir(parents=True)
 cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(cfg),'--mod-directory',str(mods)]
 run(cmd+['--create',str(out/'start.zip')],out/'create.log')
 bench=run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','181','--benchmark-runs','1'],out/'native.log')
 base=verify(bench)
 info={'engine':'Factorio 2.1.24 build 87808','source':'base 2.1.24 + disposable native research prototype; GAMEPLAY MOD UNCHANGED','benchmark_native_ticks':181,'benchmark':base,'benchmark_log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest()}
 if a.benchmark_only:
  (out/'result.json').write_text(json.dumps(info,indent=2)+'\n');print('[B10 NATIVE BENCHMARK PASS]',json.dumps(info));return
 run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
 settings={'name':'B10 train bus native research','description':'disposable no owner save','max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
 (out/'server-settings.json').write_text(json.dumps(settings))
 with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
 serverlog=out/'server.log';save=private/'saves/em072a5-b10-checkpoint.zip'
 with serverlog.open('w') as f:
  proc=subprocess.Popen([str(x) for x in cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
  try:
   for _ in range(190):
    time.sleep(.25);txt=serverlog.read_text(errors='replace')
    if proc.poll() is not None:raise RuntimeError('native headless server exited: '+txt[-2000:])
    if save.is_file() and '[EM072 B10 DISK SAVE] tick=75 requested=true' in txt and 'Saving finished' in txt:break
   else:raise TimeoutError('independent SAVE t75 not completed; '+txt[-1600:])
  finally:
   proc.terminate()
   try:proc.wait(timeout=7)
   except subprocess.TimeoutExpired:proc.kill();proc.wait()
 reload=run(cmd+['--test-save',str(save),'--test-ticks','106'],out/'native-reload.log')
 post=verify(reload,full=False)
 for k,v in base.items():assert abs(v-post[k])<.001, 'SAVE LOAD changed measured metric: '+k
 info.update(reload=post,server_SAVE_tick=75,independent_LOAD_ticks=106,checkpoint_bytes=save.stat().st_size,reload_log_sha256=hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest())
 (out/'result.json').write_text(json.dumps(info,indent=2)+'\n')
 print('[EM072 A5 B10 REAL FACTORIO ENGINE + DISK SAVE LOAD PASS]',json.dumps(info))
if __name__=='__main__':main()