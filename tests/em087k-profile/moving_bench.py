from pathlib import Path
import shutil,subprocess,time,signal,json,zipfile
p=Path(__file__).parent;eng=Path('/mnt/data/em087c/factorio');binary=eng/'bin/x64/factorio';w=p/'moving_save';m=w/'mods';m.mkdir(parents=True,exist_ok=True);(w/'saves').mkdir(exist_ok=True)
shutil.copy2(p/'base/mods/ElectrifiedMainline_0.1.96.zip',m/'ElectrifiedMainline_0.1.96.zip');q=m/'em-extended-qa_0.0.1';shutil.copytree('/mnt/data/em087c/evidence/qa_mods/em-extended-qa_0.0.1',q,dirs_exist_ok=True)
f=q/'scenarios/moving-save/control.lua';f.parent.mkdir(parents=True,exist_ok=True);s=(q/'scenarios/moving/control.lua').read_text().replace('local N=tonumber(script.test_arg) or 1','local N=100').replace("  say('dispatch '..N)","  say('dispatch '..N)\n  if not script.test_arg then game.server_save('moving100-t120') end");f.write_text(s)
(m/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True},{'name':'em-extended-qa','enabled':True}]}));cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n');shutil.copy2('/mnt/data/em087e/watch/server-settings.json',w/'server-settings.json')
base=[str(binary),'--config',str(cfg),'--mod-directory',str(m)];save=w/'saves/moving100-t120.zip'
with (p/'moving-server.log').open('w') as out:
 proc=subprocess.Popen(base+['--start-server-load-scenario','em-extended-qa/moving-save','--server-settings',str(w/'server-settings.json'),'--bind','127.0.0.1','--port','34201'],stdout=out,stderr=subprocess.STDOUT,stdin=subprocess.DEVNULL)
 try:
  for _ in range(1200):
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
assert save.exists();print('save',save.stat().st_size,flush=True)
# 200 ticks from dispatch, before arrival assertions at t500, no server_save invoked in window.
for tag in ['base','codeonly']:
 w=p/f'moving-{tag}';mods=w/'mods';mods.mkdir(parents=True,exist_ok=True);shutil.copytree(q,mods/q.name,dirs_exist_ok=True);shutil.copy2(m/'mod-list.json',mods/'mod-list.json');shutil.copy2(p/tag/'mods/ElectrifiedMainline_0.1.96.zip',mods/'ElectrifiedMainline_0.1.96.zip');cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
 with (p/f'moving-bench-{tag}.log').open('w') as out:rc=subprocess.run([str(binary),'--config',str(cfg),'--mod-directory',str(mods),'--benchmark',str(save),'--benchmark-ticks','200','--benchmark-runs','2'],stdout=out,stderr=subprocess.STDOUT,timeout=240).returncode
 t=(p/f'moving-bench-{tag}.log').read_text();print(tag,rc,[l.strip() for l in t.splitlines() if 'avg:' in l or 'checksum:' in l.lower()][-6:],flush=True)
 if rc:raise RuntimeError(tag)
