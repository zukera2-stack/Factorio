#!/usr/bin/env python3
"""Factorio EM072-C strictly native equal-mass wagon-vs-booster diagnostic; not a +500kW proof."""
import argparse,subprocess,shutil,json,hashlib,re,time,socket
from pathlib import Path

def main():
 p=argparse.ArgumentParser();p.add_argument('--factorio',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--benchmark-only',action='store_true');args=p.parse_args()
 exe=args.factorio.resolve();assert '2.1.24 (build 87808' in subprocess.run([str(exe),'--version'],capture_output=True,text=True,check=True).stdout
 out=args.output.resolve();assert not out.exists() or not any(out.iterdir());out.mkdir(parents=True,exist_ok=True)
 mods=out/'mods';mods.mkdir();shutil.copytree(Path(__file__).parent/'tests/em072-c-motor-force-probe',mods/'em072-c-motor-force-probe_0.0.1')
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em072-c-motor-force-probe','enabled':True}]+[{'name':n,'enabled':False} for n in ['space-age','elevated-rails','quality','recycler']]}))
 private=out/'private';(private/'saves').mkdir(parents=True)
 cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(cfg),'--mod-directory',str(mods)]
 for name,tail in [('create.log',['--create',str(out/'start.zip')]),('native.log',['--benchmark',str(out/'start.zip'),'--benchmark-ticks','241','--benchmark-runs','1'])]:
  with (out/name).open('w') as f:subprocess.run(cmd+tail,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=120)
 log=(out/'native.log').read_text()
 assert '[EM072C TOPOLOGY PASS]' in log and '[EM072C FINAL PASS]' in log,log[-2400:]
 pattern=r'\[EM072C MEASURE\] tick=(\d+) passive_tiles=([\d.]+) motor_label_tiles=([\d.]+) loco_fuel_boost_tiles=([\d.]+) passive_burned_J=([\d.]+) motor_label_burned_J=([\d.]+) boost_burned_J=([\d.]+) boost_vs_passive_tiles=([-\d.]+) boost_vs_passive_J=([-\d.]+) remaining_total_J=([\d.]+)'
 ms=re.findall(pattern,log);assert len(ms)==4,len(ms)
 keys=['tick','passive_tiles','motor_label_tiles','loco_booster_tiles','passive_burned_j','motor_label_burned_j','loco_booster_burned_j','booster_extra_tiles','booster_extra_burn_j','remaining_total_j']
 d=[dict(zip(keys,map(float,row))) for row in ms]
 assert all(abs(x['passive_tiles']-x['motor_label_tiles'])<.0001 and abs(x['passive_burned_j']-x['motor_label_burned_j'])<.01 for x in d)
 data={'engine':'Factorio 2.1.24 build87808 Base-only','status':'NOT A 500kW NATIVE WAGON TRACTION PROOF','config':'3 identical-mass trains with equal 2MW locomotive and cargo/fluid, motor wagon names differ only, third locomotive fuel acceleration multiplier 1.25','measurements':d,'log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest()}
 if not args.benchmark_only:
  with (out/'server-create.log').open('w') as f:subprocess.run(cmd+['--create',str(out/'server-start.zip')],stdout=f,stderr=subprocess.STDOUT,check=True,timeout=120)
  settings={'name':'EM072C native equal-mass diagnostic','description':'Disposable research only','max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
  (out/'server-settings.json').write_text(json.dumps(settings))
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
  server_log=out/'server.log'; checkpoint=private/'saves/em072c-checkpoint.zip'
  with server_log.open('w') as fh:
   proc=subprocess.Popen([str(x) for x in cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)]],stdout=fh,stderr=subprocess.STDOUT)
   try:
    for _ in range(180):
     time.sleep(.25);txt=server_log.read_text(errors='replace')
     if proc.poll() is not None: raise RuntimeError('server exited '+txt[-1700:])
     if checkpoint.exists() and '[EM072C DISK SAVE] tick=100 requested=true' in txt and 'Saving finished' in txt:break
    else:raise TimeoutError('checkpoint not saved '+txt[-1500:])
   finally:
    proc.terminate()
    try:proc.wait(timeout=8)
    except subprocess.TimeoutExpired:proc.kill();proc.wait()
  with (out/'native-reload.log').open('w') as fh:subprocess.run(cmd+['--test-save',str(checkpoint),'--test-ticks','141'],stdout=fh,stderr=subprocess.STDOUT,check=True,timeout=120)
  reload_log=(out/'native-reload.log').read_text();assert '[EM072C FINAL PASS]' in reload_log,'reload did not finish real target'
  post=re.findall(pattern,reload_log);assert len(post)==3,post
  post_rows=[dict(zip(keys,map(float,row))) for row in post]
  for row in post_rows:
   original=next(x for x in d if x['tick']==row['tick'])
   for k in keys: assert abs(original[k]-row[k])<.002,(row['tick'],k,original[k],row[k])
  data.update(real_server_SAVE_tick=100,independent_native_LOAD_ticks=141,checkpoint_bytes=checkpoint.stat().st_size,reload_log_sha256=hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest(),reload_measurements=post_rows)
 (out/'result.json').write_text(json.dumps(data,indent=2)+'\n')
 print(json.dumps(data,indent=2))
if __name__=='__main__':main()