from pathlib import Path
import shutil,subprocess,time,signal,json,zipfile,io,hashlib
p=Path(__file__).resolve().parent;eng=p.parent/'em088/engine/factorio';binary=eng/'bin/x64/factorio';w=p/'pending-server';m=w/'mods';m.mkdir(parents=True,exist_ok=False);(w/'saves').mkdir()
archive=(p/'topology-probe-QA-ONLY.zip').read_bytes();assert hashlib.sha256(archive).hexdigest()=='dd6bc862cefd4c3c7815f847a3b58abb80afdfb79041ee8155cf3300056d8664'
with zipfile.ZipFile(io.BytesIO(archive)) as z:z.extractall(m)
q=m/'em-mixed-outposts-qa_0.0.1';shutil.copytree(p/'suite'/q.name,q);shutil.copy2(p/'suite/regen-mod-settings.dat',m/'mod-settings.dat')
(m/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','ElectrifiedMainline','em-mixed-outposts-qa')]}));cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n');settings=json.loads((eng/'data/server-settings.example.json').read_text());settings.update({'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':0});(w/'settings.json').write_text(json.dumps(settings));save=w/'saves/terminal-checkpoint.zip'
with (w/'server.log').open('w') as out:
 proc=subprocess.Popen([str(binary),'--config',str(cfg),'--mod-directory',str(m),'--start-server-load-scenario','em-mixed-outposts-qa/train-pending-save','--server-settings',str(w/'settings.json'),'--bind','127.0.0.1','--port','34302'],stdout=out,stderr=subprocess.STDOUT,stdin=subprocess.DEVNULL)
 try:
  for _ in range(600):
   if save.is_file() and '[TRAIN EXCHANGE PASS] reload' in (w/'server.log').read_text(errors='replace'):
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
shutil.copy2(save,p/'terminal-checkpoint.zip');print('checkpoint',save.stat().st_size,hashlib.sha256(save.read_bytes()).hexdigest(),flush=True)
