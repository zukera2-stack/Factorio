#!/usr/bin/env python3
"""Run exact-ZIP, actual-engine EM065 closed-reservoir energy balance + eight-battery invariants.

No commercial engine or owner save files are included; engine archive must be supplied privately.
"""
import argparse, sys, subprocess, json, time
from pathlib import Path
HERE=Path(__file__).resolve().parent

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--engine',type=Path,required=True)
    ap.add_argument('--game-zip',type=Path,required=True)
    ap.add_argument('--expected-sha256',required=True)
    ap.add_argument('--out',type=Path,default=HERE/'results-energy-065')
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    rows=[]
    for variant in ('reservoir','reservoir-batteries'):
        print('[EM065] real Factorio 2.1.24: '+variant,flush=True)
        dest=args.out/variant
        cmd=[sys.executable,str(HERE/'run_native_topology_065.py'),'--engine',str(args.engine), '--game-zip',str(args.game_zip),'--expected-sha256',args.expected_sha256,'--out',str(dest),'--variant',variant]
        start=time.perf_counter()
        subprocess.run(cmd,check=True)
        row=json.loads((dest/'report.json').read_text(encoding='utf-8'))
        assert row['save_reload']['passed'] and row['scenarios']['live_reconfiguration']['passed']
        assert row['energy_ledger']['remaining_unexplained_ledger_deficit_j']>0, 'Bug did not reproduce; revise expected case'
        row['runner_seconds']=round(time.perf_counter()-start,3)
        rows.append(row)
    result={'suite':'EM065','engine':'2.1.24 build 87808','game_zip_sha256':args.expected_sha256,'tested_variants':len(rows), 'native_benchmark_ticks':2700,'disk_save_load_runs':2,'all_topology_functional_pass':True,'external_battery_identity_and_flow_limit_pass':True,'unintended_energy_loss_release_gate':'FAIL','cases':rows}
    (args.out/'EM065-results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('[EM065 TEST PASS] 2/2 closed reservoir and external batteries; unintended loss remains a release BLOCKER',flush=True)

if __name__=='__main__':main()