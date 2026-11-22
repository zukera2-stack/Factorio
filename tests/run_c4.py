#!/usr/bin/env python3
import pathlib, argparse, shutil, subprocess, json, hashlib, socket, time, sys
P=pathlib.Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--factorio',required=True);ap.add_argument('--output',required=True);ap.add_argument('--server',action='store_true');a=ap.parse_args()
exe=pathlib.Path(a.factorio).resolve();out=pathlib.Path(a.output).resolve()
if out.exists() and list(out.iterdir()):raise RuntimeError('Output must be empty!')
out.mkdir(parents=True,exist_ok=True);mods=out/'mods';mods.mkdir()
shutil.copytree(P/'em-c4-loco-mounted-probe',mods/'em-c4-loco-mounted-probe_0.0.1')
(mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em-c4-loco-mounted-probe','enabled':True}]}))
private=out/'private';(private/'saves').mkdir(parents=True)
cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
cmd=[str(exe),'--config',str(cfg),'--mod-directory',str(mods)]
version=subprocess.run([str(exe),'--version'],capture_output=True,text=True).stdout
assert '2.1.24' in version and '87808' in version,version

def run(args,file,timeout=120):
 with (out/file).open('w') as f: p=subprocess.run(cmd+list(map(str,args)),stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
 if p.returncode:raise RuntimeError(str(p.returncode)+' '+str(out/file)+'\n'+(out/file).read_text()[-4000:])
 return (out/file).read_text()
run(['--create',out/'initial.zip'],'create.log')
bench=run(['--benchmark',out/'initial.zip','--benchmark-ticks', '365'],'native.log')
print('BENCH DONE',len(bench),'tail:\n', '\n'.join([l for l in bench.splitlines() if 'EMC4|' in l][-25:]))
if a.server:
 run(['--create',out/'server-start.zip'],'server-create.log')
 (out/'server-settings.json').write_text(json.dumps({'name':'C4 finite owner isolation native','description':'disposable no owner game','max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}))
 with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
 checkpoint=private/'saves'/'em-c4-probe-checkpoint.zip';serverlog=out/'server.log'
 with serverlog.open('w') as f:
  proc=subprocess.Popen(cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)],stdout=f,stderr=subprocess.STDOUT)
  try:
   for _ in range(250):
    time.sleep(.25);log=serverlog.read_text(errors='replace')
    if proc.poll() is not None:raise RuntimeError('SERVER died: '+log[-2400:])
    if checkpoint.exists() and 'Saving finished' in log and 'EMC4|save|tick=125|ok=true' in log: break
   else: raise TimeoutError('Missing native checkpoint '+log[-2400:])
  finally:
   proc.terminate()
   try:proc.wait(timeout=7)
   except subprocess.TimeoutExpired:proc.kill();proc.wait()
 reload=run(['--test-save',checkpoint,'--test-ticks','240'],'native-reload.log')
 print('RELOAD DONE',len(reload))
result={'engine':version.splitlines()[0], 'bench_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest(), 'save_load':a.server}
if a.server:result['reload_sha256']=hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest();result['checkpoint_bytes']=checkpoint.stat().st_size
(out/'result.json').write_text(json.dumps(result,indent=2))
if a.server:
 check=subprocess.run([sys.executable,str(P/'verify_c4.py'),'--output',str(out),'--source',str(P/'em-c4-loco-mounted-probe'/'control.lua')],capture_output=True,text=True)
 (out/'validation.log').write_text(check.stdout+'\n'+check.stderr)
 if check.returncode:raise RuntimeError('native C4 strict SAVE/LOAD validation FAILED; read '+str(out/'validation.log'))
 print(check.stdout[:500])