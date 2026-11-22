#!/usr/bin/env python3
"""B8 isolated native Factorio experiment: two actual EM070 station sources on one HSR component.
Strict exact CI SHA/source, 16 real moving locomotive IDs, native energy, real SAVE/LOAD.
Does not touch main, installed game, or owner saves.
"""
import argparse,hashlib,json,re,shutil,socket,subprocess,time,zipfile
from pathlib import Path
CI_SHA='91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575'
CORE={
 'scripts/power_bridge_058.lua':'4a4084e5cf71d57cc057aa15bc524ac68ff6268b',
 'scripts/technical_network_046.lua':'e8b1bad35fb60d22bdb91d2dd1c4c5055c58e172',
 'scripts/bridge_dispatch_059.lua':'4f4399d6277c27ec65b73d45fd1bf82f89d4bfe2',
 'scripts/control.lua':'3546d3b7c983856c367279d5dac21fe1c8b07f95',
 'prototypes/power_bridge_058.lua':'0a69ec8ef61bb62991b57e06581f0018a5159b40'}

def sha(b):return hashlib.sha256(b).hexdigest()
def blob(b):return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
def run(cmd, logfile, timeout=130):
 with logfile.open('w') as f:subprocess.run([str(x) for x in cmd],stdout=f,stderr=subprocess.STDOUT,timeout=timeout,check=True)
 return logfile.read_text()
def verify(text,reload=False):
 markers=(['[EM072A5 B8 BROWNOUT PASS]','[EM072A5 B8 SIGNED ENERGY PASS]','[EM072A5 B8 NATIVE PASS]'] if reload else ['[EM072A5 B8 TOPOLOGY PASS]','[EM072A5 B8 FINITE BASELINE]','[EM072A5 B8 DUAL IMPORT PASS]','[EM072A5 B8 BROWNOUT PASS]','[EM072A5 B8 NATIVE PASS]'])
 for x in markers:
  if x not in text:raise AssertionError('missing TRUE Factorio native evidence: '+x+'; log tail: '+text[-1200:])
 m=re.search(r'\[EM072A5 B8 NATIVE PASS\] real_emu=2 native_trains=16 shared_HSR=true station_A_sourcebacked_J=([\d.]+) station_B_sourcebacked_J=([\d.]+) factory_B_shortfall_ticks=(\d+) factory_B_consumed_J=([\d.]+) locomotive_credit_J=([\d.]+) loco_spent_J=([\d.]+) unspent_native_burner_J=([\d.]+) global_ledger_residual_J=([-\d.]+) min_movement_tiles=([\d.]+) plan_A_peak_MW=([\d.]+) plan_B_peak_MW=([\d.]+)',text)
 assert m,'missing B8 final measured native energy ledger'
 vals=[float(x) for x in m.groups()]
 assert vals[0]>0 and vals[1]>0 and vals[2]>20 and vals[3]>1e7 and vals[4]>1e7 and abs(vals[4]-vals[5]-vals[6])<3 and abs(vals[7])<3 and vals[8]>0 and vals[9]<=20.001 and vals[10]<=20.001
 result=dict(zip(['stationA_gross_transfer_j','stationB_gross_transfer_j','factory_brownout_ticks','factory_consumer_real_spent_j','real_train_grants_j','real_train_native_spent_j','burner_remaining_j','global_finite_ledger_residual_j','min_native_train_travel_tiles','station_A_peak_planned_mw','station_B_peak_planned_mw'],vals))
 sm=re.search(r'\[EM072A5 B8 SIGNED ENERGY PASS\] variant=(\w+) A_import_J=([\d.]+) A_export_J=([\d.]+) A_net_J=([-\d.]+) B_import_J=([\d.]+) B_export_J=([\d.]+) B_net_J=([-\d.]+) end_B_direction=(\w+)',text)
 assert sm,'no native direction+signed Joule audit'
 label=sm.group(1); numbers=list(map(float,sm.groups()[1:-1]))
 result['variant']=label;result['end_B_direction']=sm.group(8)
 for key,value in zip(['A_true_import_j','A_true_export_j','A_signed_net_j','B_true_import_j','B_true_export_j','B_signed_net_j'],numbers):result[key]=value
 assert abs(result['A_signed_net_j']-result['A_true_import_j']+result['A_true_export_j'])<1
 assert abs(result['B_signed_net_j']-result['B_true_import_j']+result['B_true_export_j'])<1
 assert result['stationA_gross_transfer_j']>0 and result['stationB_gross_transfer_j']>0
 return result

def main():
 ap=argparse.ArgumentParser();
 for k in ['factorio','ci-game-zip','output']:ap.add_argument('--'+k,required=True,type=Path)
 ap.add_argument('--benchmark-only',action='store_true')
 ap.add_argument('--variant',choices=['auto','manual_import'],default='auto')
 a=ap.parse_args();exe=a.factorio.resolve();ci=a.ci_game_zip.resolve();out=a.output.resolve()
 assert '2.1.24 (build 87808' in subprocess.run([str(exe),'--version'],capture_output=True,text=True,check=True).stdout
 assert sha(ci.read_bytes())==CI_SHA,'B8 requires exact EM071/EM070 official CI ZIP'
 if out.exists() and any(out.iterdir()):raise ValueError('output must be empty research scratch')
 out.mkdir(parents=True,exist_ok=True);mods=out/'mods';mods.mkdir();game=mods/'ElectrifiedMainline';game.mkdir()
 with zipfile.ZipFile(ci) as z:
  for name in z.namelist():
   p=Path(name);assert p.parts[0]=='ElectrifiedMainline' and '..' not in p.parts
   if len(p.parts)<2 or name.endswith('/'):continue
   dest=game.joinpath(*p.parts[1:]);dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(z.read(name))
 for name,expected in CORE.items():assert blob((game/name).read_bytes())==expected,'unexpected original game module: '+name
 assert json.loads((game/'info.json').read_text())['version']=='0.1.62'
 assets=Path(__file__).parent/'em072a5-b8-probe'
 root=game/'control.lua';root.write_text(root.read_text()+'\n'+(assets/'root-hook.lua').read_text())
 path=game/'scripts/power_bridge_058.lua';src=path.read_text()
 anchor=' local direct=devices.sample(s,tick,physical,allowed)';assert src.count(anchor)==1
 src=src.replace(anchor,anchor+(assets/'auto-demand.patch.lua').read_text())
 measure='         local ei,eo,amount=M.transfer(math.min(r.input.energy,cap),r.output.energy,r.output.electric_buffer_size)'
 assert src.count(measure)==1
 src=src.replace(measure,measure+'''
         -- B8 TEST-ONLY: distinguish source-backed native EEI J from planner J.
         if c.id==s.b8_a_id or c.id==s.b8_b_id then
           r.b8_transfer_j=(r.b8_transfer_j or 0)+amount
           if c.direction=='import' then r.b8_import_j=(r.b8_import_j or 0)+amount
           elseif c.direction=='export' then r.b8_export_j=(r.b8_export_j or 0)+amount end
           r.b8_net_import_j=(r.b8_import_j or 0)-(r.b8_export_j or 0)
           r.b8_peak_actual_mw=math.max(r.b8_peak_actual_mw or 0,amount*60/1e6)
         end''')
 path.write_text(src)
 path=game/'scripts/technical_network_046.lua';src=path.read_text();needle='owner.name=="em-25kv-bridge-port-058"';assert src.count(needle)==1
 path.write_text(src.replace(needle,'(owner.name=="em-25kv-bridge-port-058" or owner.name=="em072a5-b3-outpost-terminal")'))
 probe=mods/'em072a5-b8-probe_0.0.1';probe.mkdir()
 for fname in ['info.json','data.lua','control.lua']:shutil.copy2(assets/fname,probe/fname)
 if a.variant=='manual_import':
  p=probe/'control.lua';t=p.read_text();assert t.count('local B8_FORCE_MANUAL_IMPORT=false')==1
  p.write_text(t.replace('local B8_FORCE_MANUAL_IMPORT=false','local B8_FORCE_MANUAL_IMPORT=true'))
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ['base','ElectrifiedMainline','em072a5-b8-probe']]+[{'name':n,'enabled':False} for n in ['space-age','elevated-rails','quality','recycler']]}))
 private=out/'private';(private/'saves').mkdir(parents=True)
 cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(cfg),'--mod-directory',str(mods)]
 run(cmd+['--create',str(out/'start.zip')],out/'create.log')
 txt=run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','500','--benchmark-runs','1'],out/'native.log')
 tested=verify(txt)
 data={'source_sha256':CI_SHA,'engine':'Factorio 2.1.24 build 87808','native_500_ticks_pass':True,'native':tested,'native_log_sha256':sha((out/'native.log').read_bytes()),'source_mod_gameplay_files_changed':False,'variant':a.variant}
 if a.benchmark_only:
  (out/'result.json').write_text(json.dumps(data,indent=2)+'\n')
  print('[EM072A5 B8 NATIVE 500 TICK PASS]',json.dumps(tested));return
 run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
 config={'name':'B8 shared EM070 native research','description':'disposable research no owner map','max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
 (out/'server-settings.json').write_text(json.dumps(config))
 with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
 logfile=out/'server.log';checkpoint=private/'saves/em072a5-b8-checkpoint.zip'
 with logfile.open('w') as f:
  process=subprocess.Popen([str(x) for x in cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
  try:
   for _ in range(190):
    time.sleep(.25);log=logfile.read_text(encoding='utf8',errors='replace')
    if process.poll() is not None:raise RuntimeError('native B8 server stopped: '+log[-1700:])
    if checkpoint.is_file() and '[EM072A5 B8 DISK SAVE] tick=300 requested=true' in log and 'Saving finished' in log:break
   else:raise TimeoutError('native B8 checkpoint at t300 not produced')
  finally:
   process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait()
 reload_log=run(cmd+['--test-save',str(checkpoint),'--test-ticks','200'],out/'native-reload.log')
 reloaded=verify(reload_log,reload=True)
 for key,value in tested.items():
  if isinstance(value,(float,int)):assert abs(value-reloaded[key])<0.01,'true B8 SAVE→LOAD mismatch: '+key
  else:assert value==reloaded[key],'true B8 SAVE→LOAD mode mismatch: '+key
 data.update(reload=reloaded,independent_real_SAVE_tick=300,independent_real_LOAD_ticks=200,checkpoint_bytes=checkpoint.stat().st_size,reload_sha256=sha((out/'native-reload.log').read_bytes()))
 (out/'result.json').write_text(json.dumps(data,indent=2)+'\n')
 print('[EM072A5 B8 NATIVE ENGINE + TRUE DISK LOAD PASS]',json.dumps(tested))
if __name__=='__main__':main()