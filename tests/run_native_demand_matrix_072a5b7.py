#!/usr/bin/env python3
"""EM072-A5-B7 strict repeatable native 4-way demand/cache matrix + real disk SAVE/LOAD.
Requires original Factorio 2.1.24 and exact CI ZIP; research-only/no owner save or production modification.
"""
import argparse, json, subprocess, sys, hashlib
from pathlib import Path

def main():
 ap=argparse.ArgumentParser()
 for key in ['factorio','ci-game-zip','output']: ap.add_argument('--'+key,required=True,type=Path)
 ap.add_argument('--reuse-validated-full',type=Path,default=None,help='reuse an earlier FULL 500-tick benchmark + native disk LOAD, after checking all log hashes')
 a=ap.parse_args();target=a.output.resolve()
 if target.exists() and any(target.iterdir()):raise ValueError('output must be empty to protect owner saves')
 target.mkdir(parents=True,exist_ok=True)
 runner=Path(__file__).with_name('run_native_flow_072a5b7.py')
 results={}
 for variant in ['add','copy_add','copy_max','meter']:
  out=target/variant
  command=[sys.executable,str(runner),'--factorio',str(a.factorio),'--ci-game-zip',str(a.ci_game_zip),'--output',str(out),'--variant',variant,'--benchmark-only']
  with (target/(variant+'.stdout.log')).open('w') as f:subprocess.run(command,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=120)
  d=json.loads((out/'result.json').read_text());results[variant]=d
 # Corrected baseline also verifies independent native headless disk SAVE and LOAD after 385 ticks.
 complete=a.reuse_validated_full.resolve() if a.reuse_validated_full else (target/'copy_add_save_load')
 if not a.reuse_validated_full:
  command=[sys.executable,str(runner),'--factorio',str(a.factorio),'--ci-game-zip',str(a.ci_game_zip),'--output',str(complete),'--variant','copy_add']
  with (target/'copy_add_save_load.stdout.log').open('w') as f:subprocess.run(command,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=150)
 real=json.loads((complete/'result.json').read_text())
 for filename,hashkey in [('native.log','native_log_sha256'),('native-reload.log','reload_log_sha256')]:
  assert hashlib.sha256((complete/filename).read_bytes()).hexdigest()==real[hashkey], 'unverified reused native disk evidence '+filename
 assert real['source_game_zip_sha256']==hashlib.sha256(a.ci_game_zip.read_bytes()).hexdigest() and real['native_status']=='PASS', 'wrong original CI/engine evidence'
 baseline=results['add'];corrected=results['copy_add'];other=results['copy_max'];native=results['meter']
 def field(d,name):return d['native_b7'][name]
 def compare(a,b,tol=.01):return abs(a-b)<tol
 assert compare(field(baseline,'planned_peak_mw'),20), 'regression: cache alias original was not measured'
 assert compare(field(corrected,'planned_peak_mw'),0.8), 'fixed snapshot did not remove spurious 20MW planner demand'
 assert compare(field(corrected,'transfer_j'),field(other,'transfer_j')) and compare(field(corrected,'transfer_j'),field(native,'transfer_j'))
 assert field(baseline,'transfer_j')>4*field(corrected,'transfer_j'), 'cache mutation did not raise real source import'
 for v,d in results.items():
  assert abs(d['native_primary']['residual_j'])<0.01, 'first ledger failed '+v
  assert abs(d['native_secondary']['second_residual_j'])<0.01,'second ledger failed '+v
  assert d['native_secondary']['second_delivered_j']>30e6
  assert d['native_b6']['shortfall_ticks']>100
 for v in ['copy_add','copy_max','meter']:
  assert compare(results[v]['native_secondary']['second_delivered_j'],baseline['native_secondary']['second_delivered_j']), 'changed train energy with policy '+v
 p=field(baseline,'flow_pre_brownout');q=field(corrected,'flow_pre_brownout')
 assert len(p)==len(q)==10
 assert p[0]['sampled_tick']==p[-1]['sampled_tick'], 'alias effect should appear within a single device_sample caching window'
 assert p[-1]['direct_demand_j']>p[0]['direct_demand_j']+5e6
 assert all(compare(x['direct_demand_j'],8000000/60) for x in q)
 assert compare(field(baseline,'native_battery_snapshots')[0]['outpost_j'],120000000)
 assert field(corrected,'native_battery_snapshots')[0]['outpost_j']<114000000, 'local buffer was not used after fixing stale demand'
 for key in ['transfer_j','pre_brownout_transfer_j','actual_peak_mw','planned_peak_mw']:
  assert compare(real['native_b7'][key],real['reload_b7'][key]),'SAVE-LOAD B7 actual engine flow mismatch '+key
 assert compare(field(real,'transfer_j'),field(corrected,'transfer_j'))
 assert real['native_b6']['shortfall_ticks']==real['reload_b6']['shortfall_ticks']
 digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
 summary={'label':'EM072-A5-B7 native demand-cache mutation isolated', 'native':True,'engine':'Factorio 2.1.24 build 87808 Linux headless',
 'original_CI_sha256':digest(a.ci_game_zip),
 '4_modes_benchmark_pass':True,'full_corrected_disk_save_load_pass':True,
 'control':{},'variants':{},'corrected_independent_load':{'native_b7':real['reload_b7'],'checkpoint_bytes':real['checkpoint_bytes'],'native_log_sha256':real['native_log_sha256'],'reload_log_sha256':real['reload_log_sha256']},
 'limitations':['B7 changes only disposable test clone, not mod gameplay','primary+secondary injected fixed test demand, no native dynamic throttle','locomotive in main still void','outpost battery dispatch priority concept not selected','user/robot mining/blueprint/undo/MP/UPS not tested']}
 for v,d in results.items():
  b=d['native_b7'];summary['variants'][v]={
   'planned_station_peak_mw':b['planned_peak_mw'],'native_bridge_EEI_to_EEI_j':b['transfer_j'],'pre_brownout_native_bridge_transfer_j':b['pre_brownout_transfer_j'],
   'native_transfer_peak_mw':b['actual_peak_mw'], 'bank_j_tick_295':b['native_battery_snapshots'][0]['outpost_j'],
   'factory_j_tick_295':b['native_battery_snapshots'][0]['factory_j'],
   'bank_j_tick_496':b['native_battery_snapshots'][1]['outpost_j'],
   'four_native_locomotives_received_j':d['native_secondary']['second_delivered_j'],
   'second_factory_brownout_ticks':d['native_b6']['shortfall_ticks'],
   'primary_j_received':d['native_primary']['delivered_j'], 'primary_residual_j':d['native_primary']['residual_j'],
   'secondary_residual_j':d['native_secondary']['second_residual_j'],
   'log_sha256':d['native_log_sha256']}
 summary['control']={'cached_sample_tick_at_250':p[0]['sampled_tick'],'cached_sample_tick_at_295':p[-1]['sampled_tick'],
 'broken_direct_demand_J_tick250':p[0]['direct_demand_j'],'broken_direct_demand_J_tick295':p[-1]['direct_demand_j'],
 'fixed_direct_demand_J_tick250':q[0]['direct_demand_j'],'fixed_direct_demand_J_tick295':q[-1]['direct_demand_j'],
 'native_secondary_raw_demand_J_tick250':p[0]['raw_secondary_demand_j']}
 (target/'matrix-result.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
 print('EM072-A5-B7 4-NATIVE-MODE-MATRIX + REAL DISK LOAD PASS')
 print(json.dumps(summary['control'],ensure_ascii=False))
 for v,values in summary['variants'].items(): print(v,values['planned_station_peak_mw'],'MW planned',values['native_bridge_EEI_to_EEI_j'],'J actual bridge transfer','bank at t295',values['bank_j_tick_295'],'J')
 print('REAL DISK LOAD PASS, finite ledgers PASS; see matrix-result.json')
if __name__=='__main__':main()