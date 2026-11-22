#!/usr/bin/env python3
"""B5 test only: real rail CUT/REJOIN and owned terminal detach/rebuild in Factorio.
No production source or user save is touched. Requires exact EM071/EM070 CI ZIP.
"""
import argparse, hashlib, json, re, shutil, socket, subprocess, time, zipfile
from pathlib import Path

CI_ZIP_SHA256='91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575'
CORE_BLOBS={
 'scripts/power_bridge_058.lua':'4a4084e5cf71d57cc057aa15bc524ac68ff6268b',
 'scripts/technical_network_046.lua':'e8b1bad35fb60d22bdb91d2dd1c4c5055c58e172',
 'scripts/bridge_dispatch_059.lua':'4f4399d6277c27ec65b73d45fd1bf82f89d4bfe2',
 'scripts/control.lua':'3546d3b7c983856c367279d5dac21fe1c8b07f95',
 'prototypes/power_bridge_058.lua':'0a69ec8ef61bb62991b57e06581f0018a5159b40'
}
MARKERS_ALL=['[EM072A5 B5 ISOLATION PASS]','[EM072A5 B5 CROSS-COMPONENT CUT PASS]','[EM072A5 B5 INDEPENDENT LIFECYCLE PASS]','[EM072A5 B5 SECOND REMOVAL PASS]','[EM072A5 B5 SECOND SAVE PASS]','[EM072A5 B5 NATIVE PASS]','[EM072A5 B3 ZERO PASS]','[EM072A5 B3 NATIVE CHARGE PASS]',
 '[EM072A5 B3 NATIVE CORRIDOR PASS]','[EM072A5 B4 CUT PASS]',
 '[EM072A5 B4 REJOIN PASS]','[EM072A5 B4 REMOVAL PASS]',
 '[EM072A5 B4 DETACHED CHECK PASS]','[EM072A5 B4 REBUILD PASS]',
 '[EM072A5 B4 NATIVE PASS]']
MARKERS_RELOAD=['[EM072A5 B5 SECOND SAVE PASS]','[EM072A5 B5 NATIVE PASS]','[EM072A5 B4 DETACHED CHECK PASS]','[EM072A5 B4 REBUILD PASS]', '[EM072A5 B4 NATIVE PASS]']

def sha(data):return hashlib.sha256(data).hexdigest()
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def run(cmd,path,timeout=120):
 with path.open('w',encoding='utf8') as f:subprocess.run([str(x) for x in cmd],stdout=f,stderr=subprocess.STDOUT,timeout=timeout,check=True)
 return path.read_text(encoding='utf8')
def verify(log,markers):
 for m in markers:
  if m not in log:raise AssertionError('Missing Factorio native PASS marker: '+m)
 match=re.search(r'\[EM072A5 B4 NATIVE PASS\] delivered_J=([\d.]+) spent_J=([\d.]+) ledger_residual_J=([-\d.]+) min_train_J=([\d.]+) max_train_J=([\d.]+) min_motion_tiles=([\d.]+) builds=(\d+)',log)
 if not match:raise AssertionError('Missing final honest native ledger')
 nums=[float(x) for x in match.groups()]
 assert nums[0]>10e6 and abs(nums[2])<1 and abs(nums[3]-nums[4])<1 and nums[5]>0.05
 return dict(zip(['delivered_j','spent_j','residual_j','train_min_j','train_max_j','travel_tiles','cache_builds'],nums))


def verify_second(log):
 match=re.search(r'\[EM072A5 B5 NATIVE PASS\] second_train_count=(\d+) second_delivered_J=([\d.]+) second_native_spent_J=([\d.]+) second_remaining_burner_J=([\d.]+) second_ledger_residual_J=([-\d.]+) second_min_train_J=([\d.]+) second_max_train_J=([\d.]+) second_min_travel_tiles=([\d.]+) second_cache_builds=(\d+)',log)
 assert match,'missing true second native energy ledger'
 vals=[float(v) for v in match.groups()]
 assert vals[0]==4 and vals[1]>1e7 and abs(vals[1]-vals[2]-vals[3])<1 and abs(vals[4])<3 and abs(vals[5]-vals[6])<3 and vals[7]>0 and vals[8]>=1
 return dict(zip(['second_count','second_delivered_j','second_native_spent_j','second_burner_remaining_j','second_residual_j','second_train_min_j','second_train_max_j','second_travel_tiles','second_cache_builds'],vals))

MARKERS_CONFIG=['[EM072A5 B5 CONFIG EVENT PASS]','[EM072A5 B5 CONFIG FAIL-CLOSED PASS]',
 '[EM072A5 B5 CONFIG REATTACH]','[EM072A5 B5 CONFIG RECOVERY PASS]',
 '[EM072A5 B5 NATIVE PASS]','[EM072A5 B4 DETACHED CHECK PASS]',
 '[EM072A5 B4 REBUILD PASS]','[EM072A5 B4 NATIVE PASS]']

def make_upgrade_control(source):
 # Fixture upgrade from probe v0.0.1 to 0.0.2. Never alter the real gameplay mod.
 old=""" if t==390 then
  assert(remote.call('em072a5_b5_secondary','status').authorized,'second native terminal lost on disk SAVE/LOAD')
  assert(b5.granted>b5.before_rejoin+50000,'second corridor failed to pay J after reload')
  log('[EM072A5 B5 SECOND SAVE PASS] first corridor disconnected, second remains powered across independent disk load')
 end"""
 new=""" if t==390 then
  assert(storage.b5_upgrade_seen,'real configuration-change event not fired')
  assert(not remote.call('em072a5_b5_secondary','status').authorized,'old second terminal still authorized after migration')
  assert(math.abs(b5.granted-storage.b5_upgrade_saved_granted)<0.05,
   'phantom native J from disconnected second terminal after configuration migration')
  log('[EM072A5 B5 CONFIG FAIL-CLOSED PASS] obsolete outpost disconnected with zero new J')
 end"""
 assert source.count(old)==1;source=source.replace(old,new)
 old=""" if t==400 then
  p.controller=make(p.surface,'em072a5-b3-outpost-controller',-142,7)"""
 new=""" if t==400 then
  assert(remote.call('em072a5_b5_secondary','attach',b5.controller.unit_number,b5.masts[1].unit_number),
   'second outpost cannot explicitly restore after migration')
  b5.before_upgrade_repair=b5.granted
  log('[EM072A5 B5 CONFIG REATTACH] new script-owned port connected to verified second HSR anchor')
  p.controller=make(p.surface,'em072a5-b3-outpost-controller',-142,7)"""
 assert source.count(old)==1;source=source.replace(old,new)
 old=""" if t==420 then
  local st=remote.call('em072a5_b3_terminal','status')"""
 new=""" if t==420 then
  assert(remote.call('em072a5_b5_secondary','status').authorized and b5.granted>b5.before_upgrade_repair+50000,
   'second outpost failed real native energy recovery after migration')
  log('[EM072A5 B5 CONFIG RECOVERY PASS] reconnected second native outpost resumed paid traction')
  local st=remote.call('em072a5_b3_terminal','status')"""
 assert source.count(old)==1;source=source.replace(old,new)
 source+="""
-- V0.0.2 isolated test-only configuration migration; no production code changed.
script.on_configuration_changed(function(event)
 storage.b5_upgrade_seen=true
 local p=storage.b0
 assert(p and p.b5,'lost second native outpost on version migration')
 storage.b5_upgrade_saved_granted=p.b5.granted
 -- MAIN's storage is per-mod and cannot be inspected from the probe. Always use
 -- the exact registered interface to revoke MAIN's old owner and hidden copper.
 assert(remote.call('em072a5_b5_secondary','detach',p.b5.controller.unit_number),
  'obsolete second native electrical terminal not revoked on mod change')
 log('[EM072A5 B5 CONFIG EVENT PASS] real on_configuration_changed fired and invalidated old native port')
end)
"""
 return source

def main():
 ap=argparse.ArgumentParser()
 for flag in ['factorio','ci-game-zip','output']:ap.add_argument('--'+flag,type=Path,required=True)
 args=ap.parse_args();exe=args.factorio.resolve();ci=args.ci_game_zip.resolve();out=args.output.resolve()
 assert '2.1.24 (build 87808' in subprocess.run([exe,'--version'],capture_output=True,text=True,check=True).stdout
 assert sha(ci.read_bytes())==CI_ZIP_SHA256,'wrong exact original CI ZIP'
 if out.exists() and any(out.iterdir()):raise ValueError('scratch output must be EMPTY; never owner save')
 out.mkdir(parents=True,exist_ok=True);mods=out/'mods';mods.mkdir();game=mods/'ElectrifiedMainline';game.mkdir()
 with zipfile.ZipFile(ci) as f:
  for name in f.namelist():
   p=Path(name);assert p.parts and p.parts[0]=='ElectrifiedMainline' and '..' not in p.parts
   if len(p.parts)<2 or name.endswith('/'):continue
   target=game.joinpath(*p.parts[1:]);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(f.read(name))
 assert json.loads((game/'info.json').read_text())['version']=='0.1.62'
 for name,digest in CORE_BLOBS.items():assert blob((game/name).read_bytes())==digest,'wrong game source '+name
 assets=Path(__file__).resolve().parent/'em072a5-b5-probe'
 control=game/'control.lua';control.write_text(control.read_text()+'\n'+(assets/'root-hook.lua').read_text())
 bridge=game/'scripts/power_bridge_058.lua';source=bridge.read_text()
 anchor=' local direct=devices.sample(s,tick,physical,allowed)'
 assert source.count(anchor)==1
 bridge.write_text(source.replace(anchor,anchor+(assets/'auto-demand.patch.lua').read_text()))
 tech=game/'scripts/technical_network_046.lua';source=tech.read_text();anchor='owner.name=="em-25kv-bridge-port-058"'
 assert source.count(anchor)==1
 tech.write_text(source.replace(anchor,'(owner.name=="em-25kv-bridge-port-058" or owner.name=="em072a5-b3-outpost-terminal")'))
 # Crucial: invalidate HSR reach cache on every real rail edit, via genuine source event callback.
 pfile=game/'scripts/power_019.lua';source=pfile.read_text();anchor='function M.on_rail_changed(e)\n    if not (e and e.valid and RAIL_SET[e.name]) then return end'
 assert source.count(anchor)==1
 pfile.write_text(source.replace(anchor, anchor+'''\n    local b4=storage.em and storage.em.bridge058
    if b4 then b4.a5_seed_id=nil;b4.a5_reach=nil;b4.a5_reach_generation=nil;b4.b5_reach=nil;b4.b5_seed=nil end'''))
 probe=mods/'em072a5-b5-probe_0.0.1';probe.mkdir()
 for name in ['info.json','data.lua','control.lua']:shutil.copy2(assets/name,probe/name)
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ['base','ElectrifiedMainline','em072a5-b5-probe']]+[{'name':n,'enabled':False} for n in ['space-age','elevated-rails','quality','recycler']]}))
 private=out/'private';(private/'saves').mkdir(parents=True);cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
 cmd=[str(exe),'--config',str(cfg),'--mod-directory',str(mods)]
 run(cmd+['--create',str(out/'start.zip')],out/'create.log')
 log_native=run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','500','--benchmark-runs','1'],out/'native.log')
 native=verify(log_native,MARKERS_ALL)
 native_second=verify_second(log_native)
 run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
 settings={'name':'B5 dual physical-component test','description':'Disposable research only','max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
 (out/'server-settings.json').write_text(json.dumps(settings))
 with socket.socket() as sk:sk.bind(('127.0.0.1',0));port=sk.getsockname()[1]
 logfile=out/'server.log';checkpoint=private/'saves/em072a5-b4-checkpoint.zip'
 with logfile.open('w',encoding='utf8') as f:
  process=subprocess.Popen([str(x) for x in cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
  try:
   for _ in range(180):
    time.sleep(.25)
    log=logfile.read_text(encoding='utf8',errors='replace')
    if process.poll() is not None:raise RuntimeError('native server stopped: '+log[-1800:])
    if checkpoint.is_file() and '[EM072A5 B4 DISK SAVE] t=385 requested=true' in log and 'Saving finished' in log:break
   else:raise TimeoutError('Native disk SAVE not created at tick385')
  finally:
   process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait()
 log_reload=run(cmd+['--test-save',str(checkpoint),'--test-ticks','115'],out/'native-reload.log')
 reload=verify(log_reload,MARKERS_RELOAD)
 reload_second=verify_second(log_reload)
 for field in native:assert abs(native[field]-reload[field])<.01,'SAVE/LOAD mismatched '+field
 for field in native_second:assert abs(native_second[field]-reload_second[field])<.01,'SAVE/LOAD mismatched secondary '+field
 # Actual native config-change test: modify ONLY disposable research mod from
 # version 0.0.1 to 0.0.2, load SAME saved world independently. Official mod stays 0.1.62.
 original=mods/'em072a5-b5-probe_0.0.1'
 upgraded=mods/'em072a5-b5-probe_0.0.2'
 assert original.is_dir() and not upgraded.exists()
 original.rename(upgraded)
 uinfo=json.loads((upgraded/'info.json').read_text())
 assert uinfo['name']=='em072a5-b5-probe' and uinfo['version']=='0.0.1'
 uinfo['version']='0.0.2'
 (upgraded/'info.json').write_text(json.dumps(uinfo,indent=2)+'\n')
 uctrl=upgraded/'control.lua';uctrl.write_text(make_upgrade_control(uctrl.read_text()))
 upgraded_log=run(cmd+['--test-save',str(checkpoint),'--test-ticks','115'],out/'native-config-reload.log')
 upgraded_primary=verify(upgraded_log,MARKERS_CONFIG)
 upgraded_second=verify_second(upgraded_log)
 for k in native:
  assert abs(upgraded_primary[k]-native[k])<0.05,'production OFF stage changed after test-only mod version change: '+k
 assert upgraded_second['second_delivered_j']<native_second['second_delivered_j']-100000, 'disconnected migration interval was not actually without power'
 assert upgraded_second['second_residual_j']<0.05,'configuration migration leaked physical Joules'
 data={'native_status':'PASS','branch':'research only','engine':'Factorio 2.1.24 build 87808','test_only':True,'real_rail_cut_and_rejoin':True,'test_controller_real_destroy_event_and_reattach':True,
  'read_only_source_ci_sha256':CI_ZIP_SHA256,'actual_native_trains':16,'distinct_native_HSR_components':2,'outpost_banks':2,'second_initial_native_cell_j':120000000,'second_test_precharged_j':120000000,'station_limit_mw':20,
  'benchmark_ticks':500,'native_server_disk_save_tick':385,'independent_reload_ticks':115,
  'checkpoint_bytes':checkpoint.stat().st_size,'native':native,'reload':reload,'native_second':native_second,'reload_second':reload_second,'migrated_probe_version':'0.0.1 -> 0.0.2','native_config_upgrade_primary':upgraded_primary,'native_config_upgrade_second':upgraded_second,
  'native_log_sha256':sha((out/'native.log').read_bytes()),'reload_log_sha256':sha((out/'native-reload.log').read_bytes()),'config_upgrade_log_sha256':sha((out/'native-config-reload.log').read_bytes()),
  'not_tested':['real player cursor actions/Undo','production on_configuration_changed with established gameplay outposts','two EM070 substation dispatchers on separate components','brownout','MP']}
 (out/'result.json').write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
 print('[EM072A5 B5 ENGINE+DISK PASS] '+json.dumps(data,ensure_ascii=False))
if __name__=='__main__':main()