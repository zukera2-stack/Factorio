from pathlib import Path
import shutil,subprocess,time,signal,json,zipfile,os
p=Path(__file__).resolve().parent;eng=p.parent/'em088/engine/factorio';binary=eng/'bin/x64/factorio';w=p/'onboard-checkpoint';m=w/'mods';m.mkdir(parents=True,exist_ok=False);(w/'saves').mkdir()
os.link(p/'EM089_0.1.101_full_EXPERIMENT.zip',m/'ElectrifiedMainline_0.1.101.zip');q=m/'em-mixed-outposts-qa_0.0.1';shutil.copytree(p/'suite'/q.name,q);shutil.copy2(p/'suite/onboard-mod-settings.dat',m/'mod-settings.dat')
(m/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','ElectrifiedMainline','em-mixed-outposts-qa')]}));cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n');settings=json.loads((eng/'data/server-settings.example.json').read_text());settings.update({'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':0});(w/'settings.json').write_text(json.dumps(settings));save=w/'saves/onboard-checkpoint.zip'
with (w/'server.log').open('w') as out:
 proc=subprocess.Popen([str(binary),'--config',str(cfg),'--mod-directory',str(m),'--start-server-load-scenario','em-mixed-outposts-qa/onboard','--server-settings',str(w/'settings.json'),'--bind','127.0.0.1','--port','34290'],stdout=out,stderr=subprocess.STDOUT,stdin=subprocess.DEVNULL)
 try:
  for _ in range(500):
   if save.is_file():
    try:
     with zipfile.ZipFile(save) as z:
      if z.testzip() is None:break
    except zipfile.BadZipFile:pass
   if proc.poll() is not None:raise RuntimeError('server exited')
   time.sleep(.1)
  else:raise RuntimeError('checkpoint timeout')
 finally:
  if proc.poll() is None:proc.send_signal(signal.SIGINT)
  try:proc.wait(timeout=10)
  except subprocess.TimeoutExpired:proc.kill();proc.wait()
shutil.copy2(save,p/'onboard-checkpoint.zip');print('checkpoint',save.stat().st_size,flush=True)
