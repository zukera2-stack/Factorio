from pathlib import Path
import shutil,subprocess,time,signal,json,zipfile
p=Path(__file__).parent;engine=Path('/mnt/data/em087c/factorio');binary=engine/'bin/x64/factorio';w=p/'disk';m=w/'mods';m.mkdir(parents=True,exist_ok=True)
shutil.copy2(p/'candidate/mods/ElectrifiedMainline_0.1.93.zip',m/'ElectrifiedMainline_0.1.93.zip');shutil.copytree(p/'localqa/mods/em-watch-qa_0.0.1',m/'em-watch-qa_0.0.1',dirs_exist_ok=True);shutil.copy2(p/'localqa/mods/mod-list.json',m/'mod-list.json')
f=m/'em-watch-qa_0.0.1/scenarios/pathmemo-save/control.lua';f.parent.mkdir(parents=True,exist_ok=True);s=(p/'pathfixture.lua').read_text().replace('elseif t==280 then repair(st,45,true)',"elseif t==250 and not script.test_arg then game.server_save('em087g-pathmemo-checkpoint')\n elseif t==260 then check(st,15,45)\n elseif t==280 then repair(st,45,true)");f.write_text(s)
cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={engine}/data\nwrite-data={w}\n');shutil.copy2('/mnt/data/em087e/watch/server-settings.json',w/'server-settings.json')
base=[str(binary),'--config',str(cfg),'--mod-directory',str(m)];save=w/'saves/em087g-pathmemo-checkpoint.zip'
(w/"saves").mkdir(exist_ok=True)
with (p/'disk-server.log').open('w') as out:
 proc=subprocess.Popen(base+['--start-server-load-scenario','em-watch-qa/pathmemo-save','--server-settings',str(w/'server-settings.json'),'--bind','127.0.0.1','--port','34201'],stdout=out,stderr=subprocess.STDOUT,stdin=subprocess.DEVNULL)
 try:
  for _ in range(200):
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
  try:proc.wait(timeout=15)
  except subprocess.TimeoutExpired:proc.kill();proc.wait()
assert save.exists();shutil.copy2(save,p/'pathmemo-checkpoint.zip')
with (p/'disk-reload.log').open('w') as out:rc=subprocess.run(base+['--test-save',str(p/'pathmemo-checkpoint.zip'),'--test-arg','load','--test-ticks','610'],stdout=out,stderr=subprocess.STDOUT,timeout=90).returncode
s=(p/'disk-reload.log').read_text();assert rc==0 and 'Test passed at tick' in s,(rc,s[-3000:]);print('PASS',save.stat().st_size)
