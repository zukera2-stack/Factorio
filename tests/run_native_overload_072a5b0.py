#!/usr/bin/env python3
"""EM072-A5-B0 native overload: twelve real accelerating locomotives on one
physical HSR component and ONE EM070 with a finite, factory-side 420MJ reservoir.

The experiment modifies ONLY a disposable copy of a CI-produced mod ZIP.
It does not build/distribute an install ZIP, touch owner saves, or merge game code.
Linux Factorio 2.1.24 x64 (build 87808), Base-only DLC disabled.
"""
import argparse
import hashlib
import json
import re
import shutil
import socket
import subprocess
import time
import zipfile
from pathlib import Path

CI_ZIP_SHA256="91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575"
CI_RUN="https://github.com/zukera2-stack/Factorio/actions/runs/44925677432"
CORE_BLOBS={
 "scripts/power_bridge_058.lua":"4a4084e5cf71d57cc057aa15bc524ac68ff6268b",
 "scripts/technical_network_046.lua":"e8b1bad35fb60d22bdb91d2dd1c4c5055c58e172",
 "scripts/bridge_dispatch_059.lua":"4f4399d6277c27ec65b73d45fd1bf82f89d4bfe2",
 "scripts/control.lua":"3546d3b7c983856c367279d5dac21fe1c8b07f95",
 "prototypes/power_bridge_058.lua":"0a69ec8ef61bb62991b57e06581f0018a5159b40",
}
MARKERS=(
 "[EM072A5 B0 TRAINS PASS]",
 "[EM072A5 B0 PHYSICAL SOURCE PASS]",
 "[EM072A5 B0 NATIVE PASS]",
)

def sha256(data): return hashlib.sha256(data).hexdigest()
def blob(data): return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
def run(cmd,log,timeout=90):
 with log.open('w',encoding='utf8') as out:
  subprocess.run([str(x) for x in cmd],check=True,stdout=out,stderr=subprocess.STDOUT,timeout=timeout)
 return log.read_text(encoding='utf8')

def verified(text, after_reload=False):
 for marker in (MARKERS[-1:] if after_reload else MARKERS):
  if marker not in text: raise AssertionError("Missing native engine marker: "+marker)
 if "non-recoverable error" in text: raise AssertionError("Factorio native error")
 match=re.search(r"\[EM072A5 B0 NATIVE PASS\].*?actual_J=(\d+) spent_J=(\d+) min_train_J=([\d.]+) max_train_J=([\d.]+) peak_MW=([\d.]+).*?min_move_tiles=([\d.]+) ledger_residual_J=([-\d.]+) funded_ticks=(\d+) cache_builds=(\d+)",text)
 if not match:raise AssertionError("Native energy and movement telemetry missing")
 got,spent,mn,mx,peak,travel,res,ticks,cache=map(float,match.groups())
 assert got>80000000 and spent>80000000 and abs(res)<0.01 and abs(mx-mn)<0.01
 assert peak<=20.000001 and peak>=19.999999 and travel>0.05 and ticks>=200
 assert 1<=cache<=2
 return dict(actual_j=got,native_burned_j=spent,per_train_min_j=mn,per_train_max_j=mx,
             native_peak_mw=peak,min_travel_tiles=travel,ledger_residual_j=res,
             funded_ticks=int(ticks),hsr_cache_builds=int(cache))

def main():
 ap=argparse.ArgumentParser()
 ap.add_argument('--factorio',type=Path,required=True)
 ap.add_argument('--ci-game-zip',type=Path,required=True)
 ap.add_argument('--output',type=Path,required=True,help="NEW EMPTY scratch directory")
 args=ap.parse_args()
 exe=args.factorio.resolve();zipfile_path=args.ci_game_zip.resolve();out=args.output.resolve()
 assert exe.is_file() and zipfile_path.is_file()
 version=subprocess.run([str(exe),'--version'],check=True,capture_output=True,text=True).stdout
 assert '2.1.24 (build 87808' in version and 'headless' in version,"Wrong native Factorio engine: "+version
 assert sha256(zipfile_path.read_bytes())==CI_ZIP_SHA256,"Not exact CI EM071 game ZIP"
 if out.exists() and any(out.iterdir()): raise ValueError("Output directory must be empty, never owner save dir")
 out.mkdir(parents=True,exist_ok=True)
 mods=out/'mods';mods.mkdir()
 game=mods/'ElectrifiedMainline';game.mkdir()
 with zipfile.ZipFile(zipfile_path) as archive:
  for name in archive.namelist():
   member=Path(name)
   assert member.parts and member.parts[0]=='ElectrifiedMainline' and '..' not in member.parts,name
   if len(member.parts)==1 or name.endswith('/'):continue
   target=game.joinpath(*member.parts[1:]);target.parent.mkdir(parents=True,exist_ok=True)
   target.write_bytes(archive.read(name))
 inf=json.loads((game/'info.json').read_text())
 assert inf['name']=='ElectrifiedMainline' and inf['version']=='0.1.62'
 for name,sha in CORE_BLOBS.items():
  if blob((game/name).read_bytes())!=sha:raise AssertionError('Core blob mismatch: '+name)
 assets=Path(__file__).resolve().parent/'em072a5-b0-probe'
 # This module is an ephemeral patch to the extracted copy ONLY.
 control=game/'control.lua';control.write_text(control.read_text()+'\n'+(assets/'root-hook.lua').read_text())
 bridge=game/'scripts/power_bridge_058.lua'
 original=bridge.read_text()
 anchor=' local direct=devices.sample(s,tick,physical,allowed)'
 assert original.count(anchor)==1
 bridge.write_text(original.replace(anchor,anchor+(assets/'auto-demand.patch.lua').read_text()))
 probe=mods/'em072a5-b0-probe_0.0.1';probe.mkdir()
 for name in ('info.json','data.lua','control.lua'):shutil.copy2(assets/name,probe/name)
 names=['base','ElectrifiedMainline','em072a5-b0-probe']
 dlc=['space-age','elevated-rails','quality','recycler']
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in names]+[{'name':n,'enabled':False} for n in dlc]}))
 private=out/'private';(private/'saves').mkdir(parents=True)
 config=out/'config.ini'
 config.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(config),'--mod-directory',str(mods)]
 run(cmd+['--create',str(out/'start.zip')],out/'create.log')
 result=verified(run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','365','--benchmark-runs','1'],out/'native.log'))
 run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
 settings={'name':'EM072A5 finite native overload test','description':'Disposable test only',
           'max_players':1,'visibility':{'public':False,'lan':False},
           'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
 (out/'server-settings.json').write_text(json.dumps(settings))
 with socket.socket() as sock:
  sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
 logfile=out/'server.log';checkpoint=private/'saves/em072a5-b0-checkpoint.zip'
 with logfile.open('w',encoding='utf8') as log:
  proc=subprocess.Popen(cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)],stdout=log,stderr=subprocess.STDOUT)
  try:
   for _ in range(160):
    time.sleep(0.25)
    body=logfile.read_text(encoding='utf8',errors='replace')
    if proc.poll() is not None:raise RuntimeError('server stopped: '+body[-1800:])
    if 'non-recoverable error' in body:raise RuntimeError('native server failed: '+body[-1800:])
    if checkpoint.exists() and 'Saving finished' in body and '[EM072A5 B0 DISK SAVE] t=151 requested=true' in body:break
   else:raise TimeoutError('No native server SAVE at tick 151: '+body[-1800:])
  finally:
   proc.terminate()
   try:proc.wait(timeout=5)
   except subprocess.TimeoutExpired:proc.kill();proc.wait()
 reloaded=verified(run(cmd+['--test-save',str(checkpoint),'--test-ticks','214'],out/'native-reload.log'),after_reload=True)
 for f in ('actual_j','native_burned_j','per_train_min_j','per_train_max_j','native_peak_mw','min_travel_tiles','ledger_residual_j','funded_ticks','hsr_cache_builds'):
  if abs(result[f]-reloaded[f])>0.005:raise AssertionError('Disk reload changed '+f)
 report={'status':'NATIVE_B0_PASS_ONLY','source_mod':'ElectrifiedMainline 0.1.62',
         'source_ci_run':CI_RUN,'source_inner_zip_sha256':CI_ZIP_SHA256,
         'game_code_changed_in_repository':False,'research_only':True,
         'factorio':'2.1.24 build 87808 linux headless','native_benchmark_ticks':365,
         'real_server_save_tick':151,'independent_reload_ticks':214,
         'checkpoint_bytes':checkpoint.stat().st_size,'native_result':result,'reload_result':reloaded,
         'native_log_sha256':sha256((out/'native.log').read_bytes()),
         'reload_log_sha256':sha256((out/'native-reload.log').read_bytes()),
         'limitations':['Fixed 2MW/tick demand per live test-driven locomotive; no dynamic throttle model',
                        'Native B0 overload only; no corridor accumulator outpost',
                        'No brownout, multi-component, rail cuts, split/merge or multiplayer',
                        'Test hooks apply only to disposable extracted CI ZIP']}
 (out/'result.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
 print('[EM072A5 B0 FULL NATIVE+SAVE PASS] '+json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()