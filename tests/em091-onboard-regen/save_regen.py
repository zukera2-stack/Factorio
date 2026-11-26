from pathlib import Path
import shutil,subprocess,time,signal,json,zipfile,io
p=Path(__file__).resolve().parent;eng=p.parent/'em088/engine/factorio';binary=eng/'bin/x64/factorio';w=p/'regen-server';m=w/'mods';m.mkdir(parents=True,exist_ok=False);(w/'saves').mkdir()
with zipfile.ZipFile(io.BytesIO((p/'EM091_0.1.102_full_EXPERIMENT.zip').read_bytes())) as z:z.extractall(m)
q=m/'em-mixed-outposts-qa_0.0.1';shutil.copytree(p/'suite'/q.name,q);shutil.copy2(p/'suite/regen-mod-settings.dat',m/'mod-settings.dat')
(m/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','ElectrifiedMainline','em-mixed-outposts-qa')]}));cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n');settings=json.loads((eng/'data/server-settings.example.json').read_text());settings.update({'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':0});(w/'settings.json').write_text(json.dumps(settings));save=w/'saves/regen-checkpoint.zip'
with (w/'server.log').open('w') as out:
 proc=subprocess.Popen([str(binary),'--config',str(cfg),'--mod-directory',str(m),'--start-server-load-scenario','em-mixed-outposts-qa/regen','--server-settings',str(w/'settings.json'),'--bind','127.0.0.1','--port','34301'],stdout=out,stderr=subprocess.STDOUT,stdin=subprocess.DEVNULL)
 try:
  for _ in range(600):
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
shutil.copy2(save,p/'regen-checkpoint.zip');print('checkpoint',save.stat().st_size,flush=True)
