#!/usr/bin/env python3
"""EM072-A5-B3 native ZERO-CHARGE corridor outpost: twelve real accelerating locomotives on one
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
 "[EM072A5 B3 TRAINS PASS]",
 "[EM072A5 B3 ZERO PASS]",
 "[EM072A5 B3 NATIVE CHARGE PASS]",
 "[EM072A5 B3 NEGATIVE PASS]",
 "[EM072A5 B3 EMPTY PASS]",
 "[EM072A5 B3 EXHAUSTION STOP PASS]",
 "[EM072A5 B3 NATIVE CORRIDOR PASS]",
 "[EM072A5 B3 OFF PASS]",
 "[EM072A5 B3 NATIVE PASS]",
)

def sha256(data): return hashlib.sha256(data).hexdigest()
def blob(data): return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
def run(cmd,log,timeout=90):
 with log.open('w',encoding='utf8') as out:
  subprocess.run([str(x) for x in cmd],check=True,stdout=out,stderr=subprocess.STDOUT,timeout=timeout)
 return log.read_text(encoding='utf8')

def verified(text, after_reload=False):
 if "[EM072A5 B3 NATIVE CHARGE PASS]" not in text: raise AssertionError("no verified native recharge from zero")
 for marker in ((MARKERS[2],MARKERS[4],MARKERS[5],MARKERS[-2],MARKERS[-1]) if after_reload else MARKERS):
  if marker not in text: raise AssertionError("Missing native engine marker: "+marker)
 charge=re.search(r'\[EM072A5 B3 NATIVE CHARGE PASS\].*?charged_native_J=([\d.]+)',text)
 if not charge or float(charge[1])<=1000000:raise AssertionError('native recharge never crossed 1MJ')
 off=re.search(r"\[EM072A5 B3 OFF PASS\].*?off_delivered_J=([\d.]+) outpost_before_J=([\d.]+) outpost_after_J=([\d.]+) min_off_movement_tiles=([\d.]+).*?factory_change_J=([-\d.]+)", text)
 if not off: raise AssertionError('No measured station OFF proof')
 delivered,charged_before,charged_after,off_move,factory_delta=map(float,off.groups())
 assert delivered>3000000 and charged_before-charged_after>delivered-100000 and off_move>0.05 and abs(factory_delta)<0.01
 if "non-recoverable error" in text: raise AssertionError("Factorio native error")
 match=re.search(r"\[EM072A5 B3 NATIVE PASS\].*?actual_J=(\d+) spent_J=(\d+) min_train_J=([\d.]+) max_train_J=([\d.]+) peak_MW=([\d.]+).*?min_move_tiles=([\d.]+) ledger_residual_J=([-\d.]+) funded_ticks=(\d+) cache_builds=(\d+)",text)
 if not match:raise AssertionError("Native energy and movement telemetry missing")
 got,spent,mn,mx,peak,travel,res,ticks,cache=map(float,match.groups())
 assert got>12000000 and spent>12000000 and abs(res)<0.01 and abs(mx-mn)<0.01
 assert peak<=24.000001 and peak>=7.19999 and travel>0.05 and ticks>=100
 assert 1<=cache<=3
 return dict(outpost_charged_at_t200_j=float(charge[1]),actual_j=got,native_burned_j=spent,per_train_min_j=mn,per_train_max_j=mx,
             native_peak_mw=peak,min_travel_tiles=travel,ledger_residual_j=res,
             funded_ticks=int(ticks),hsr_cache_builds=int(cache),station_off_delivered_j=delivered,
             outpost_at_off_j=charged_before,outpost_at_390_j=charged_after,
             min_station_off_movement_tiles=off_move,station_off_factory_delta_j=factory_delta)

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
 assets=Path(__file__).resolve().parent/'em072a5-b3-probe'
 # This module is an ephemeral patch to the extracted copy ONLY.
 control=game/'control.lua';control.write_text(control.read_text()+'\n'+(assets/'root-hook.lua').read_text())
 bridge=game/'scripts/power_bridge_058.lua'
 original=bridge.read_text()
 anchor=' local direct=devices.sample(s,tick,physical,allowed)'
 assert original.count(anchor)==1
 bridge.write_text(original.replace(anchor,anchor+(assets/'auto-demand.patch.lua').read_text()))
 # TEST-ONLY technical_046 whitelist for a native script-owned terminal.
 techfile=game/'scripts/technical_network_046.lua'
 technical=techfile.read_text()
 audit='owner.name=="em-25kv-bridge-port-058"'
 assert technical.count(audit)==1,'Unexpected native anchor audit implementation'
 techfile.write_text(technical.replace(audit,'(owner.name=="em-25kv-bridge-port-058" or owner.name=="em072a5-b3-outpost-terminal")'))
 probe=mods/'em072a5-b3-probe_0.0.1';probe.mkdir()
 for name in ('info.json','data.lua','control.lua'):shutil.copy2(assets/name,probe/name)
 names=['base','ElectrifiedMainline','em072a5-b3-probe']
 dlc=['space-age','elevated-rails','quality','recycler']
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in names]+[{'name':n,'enabled':False} for n in dlc]}))
 private=out/'private';(private/'saves').mkdir(parents=True)
 config=out/'config.ini'
 config.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(config),'--mod-directory',str(mods)]
 run(cmd+['--create',str(out/'start.zip')],out/'create.log')
 result=verified(run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','460','--benchmark-runs','1'],out/'native.log'))
 run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
 settings={'name':'EM072A5 native zero-charge ownership test','description':'Disposable test only',
           'max_players':1,'visibility':{'public':False,'lan':False},
           'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
 (out/'server-settings.json').write_text(json.dumps(settings))
 with socket.socket() as sock:
  sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
 logfile=out/'server.log';checkpoint=private/'saves/em072a5-b3-checkpoint.zip'
 with logfile.open('w',encoding='utf8') as log:
  proc=subprocess.Popen(cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)],stdout=log,stderr=subprocess.STDOUT)
  try:
   for _ in range(160):
    time.sleep(0.25)
    body=logfile.read_text(encoding='utf8',errors='replace')
    if proc.poll() is not None:raise RuntimeError('server stopped: '+body[-1800:])
    if 'non-recoverable error' in body:raise RuntimeError('native server failed: '+body[-1800:])
    if checkpoint.exists() and 'Saving finished' in body and '[EM072A5 B3 DISK SAVE] t=151 requested=true' in body:break
   else:raise TimeoutError('No native server SAVE at tick 151: '+body[-1800:])
  finally:
   proc.terminate()
   try:proc.wait(timeout=5)
   except subprocess.TimeoutExpired:proc.kill();proc.wait()
 reloaded=verified(run(cmd+['--test-save',str(checkpoint),'--test-ticks','309'],out/'native-reload.log'),after_reload=True)
 for f in result:
  if abs(result[f]-reloaded[f])>0.005:raise AssertionError('Disk reload changed '+f)
 report={'status':'NATIVE_B3_ZERO_CHARGE_SCRIPT_TERMINAL_LAB_PASS_NOT_GAMEPLAY','source_mod':'ElectrifiedMainline 0.1.62',
         'source_ci_run':CI_RUN,'source_inner_zip_sha256':CI_ZIP_SHA256,
         'game_code_changed_in_repository':False,'research_only':True,
         'factorio':'2.1.24 build 87808 linux headless','native_benchmark_ticks':460,
         'real_server_save_tick':151,'independent_reload_ticks':309,
         'checkpoint_bytes':checkpoint.stat().st_size,
         'production_terminal_implemented':False, 'outpost_native_accumulator_count':24,
         'outpost_initial_j':0,'native_outpost_max_discharge_w':7200000,
         'real_native_locomotive_count':12,'fixed_train_power_w':2000000,
         'real_em070_station_count':1, 'real_meter_input_mode':'secondary_input',
         'all_original_mast_supply_radius_tiles':0,
         'test_only_outpost_terminal_radius_tiles':24,
         'outpost_initial_native_cell_energy_j':0,
         'test_only_registered_native_script_copper':True,
         'source_gameplay_prototype_mast_supply_radius_tiles':0,'native_result':result,'reload_result':reloaded,
         'native_log_sha256':sha256((out/'native.log').read_bytes()),
         'reload_log_sha256':sha256((out/'native-reload.log').read_bytes()),
         'limitations':['Fixed 2MW/tick demand per live test-driven locomotive; no dynamic throttle model',
                        'Script-owned terminal requires test-only technical_046 audit allowlist; no finished production placement lifecycle',
                        'No factory brownout, split/merge, complete player terminal lifecycle or multiplayer',
                        'Test hooks including technical audit change apply only to disposable extracted CI ZIP']}
 (out/'result.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
 print('[EM072A5 B3 FULL NATIVE+SAVE PASS] '+json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()