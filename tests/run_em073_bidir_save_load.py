#!/usr/bin/env python3
"""Actual Factorio headless server SAVE/LOAD, two independent processes.
No fixture creates booster/J in runtime; it uses tests/em072-bidir-server.
Required environment variables document/identify all user-isolated inputs.
"""
import json,os,pathlib,subprocess,time

def value(name):
    v=os.getenv(name)
    if not v: raise SystemExit('Set '+name)
    return v

BIN=value('FACTORIO_BIN')
MODS=value('EM073_SERVER_MODS_DIR')
INITIAL=pathlib.Path(value('EM073_INITIAL_SAVE'))
SETTINGS=value('EM073_SERVER_SETTINGS')
CHECKPOINT=pathlib.Path(value('EM073_CHECKPOINT_PATH'))
OUTPUT=pathlib.Path(value('EM073_LOG_DIR'))
OUTPUT.mkdir(parents=True,exist_ok=True)
if CHECKPOINT.exists(): raise SystemExit('Refuse to overwrite existing save '+str(CHECKPOINT))
if '2.1.24' not in subprocess.check_output([BIN,'--version'],text=True):raise SystemExit('Engine must be Factorio 2.1.24')

def run(label, source,port,require_save):
 log=OUTPUT/(label+'.log')
 cmd=[BIN,'--mod-directory',MODS,'--start-server',str(source),'--server-settings',SETTINGS,'--bind','127.0.0.1:'+str(port)]
 with log.open('w') as out:
  process=subprocess.Popen(cmd,stdout=out,stderr=subprocess.STDOUT)
  try:
   start=time.monotonic()
   while time.monotonic()-start<120:
    time.sleep(.25)
    lines=log.read_text(errors='replace').splitlines()
    if any('non-recoverable error' in x or '[EM073 BIDIR QA FAIL]' in x for x in lines):raise RuntimeError(label+' native error: '+'\n'.join(lines[-40:]))
    snap=[x.split('double_opposite|SNAP|',1)[1] for x in lines if '[EM073 BIDIR QA] double_opposite|SNAP|tick=300' in x]
    burn=[x.split('double_opposite|BURNERS|',1)[1] for x in lines if '[EM073 BIDIR QA] double_opposite|BURNERS|tick=300' in x]
    passes=[x for x in lines if '[EM073 BIDIR QA] double_opposite|PASS|' in x]
    if snap and burn and passes:
     if require_save and not CHECKPOINT.exists():raise RuntimeError('Native game.server_save did not write the physical checkpoint')
     return {'snap':snap[-1], 'burners':burn[-1], 'log':str(log)}
    if process.poll() is not None:raise RuntimeError(label+f': process died {process.returncode}')
   raise RuntimeError(label+': 120s timeout')
  finally:
   if process.poll() is None:
    process.terminate()
    try:process.wait(8)
    except subprocess.TimeoutExpired:process.kill();process.wait(5)

original=run('continuous',INITIAL,25373,True)
reloaded=run('reloaded',CHECKPOINT,25374,False)
if original['snap']!=reloaded['snap'] or original['burners']!=reloaded['burners']:
 raise SystemExit('FAIL: native SAVE/LOAD numerical state differs\n'+str((original,reloaded)))
report={'result':'PASS','check_tick':300,'save_tick':125,'independent_real_processes':2,'physical_checkpoint_bytes':CHECKPOINT.stat().st_size,'continuous':original,'reloaded':reloaded}
(OUTPUT/'result.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(report,indent=2,ensure_ascii=False))