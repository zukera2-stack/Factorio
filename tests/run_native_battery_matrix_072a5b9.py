#!/usr/bin/env python3
"""Strict B9 Factorio 2.1.24 native policy B + finite onboard battery positive/zero comparison.
Runs two independent native worlds, real native 500-tick benchmark + SAVE/LOAD per world.
All outputs are disposable; no production source, owner game, or main-branch changes.
"""
import argparse, json, subprocess, sys
from pathlib import Path

def main():
    ap=argparse.ArgumentParser()
    for key in ['factorio','ci-game-zip','output']:
        ap.add_argument('--'+key, required=True, type=Path)
    args=ap.parse_args()
    out=args.output.resolve()
    if out.exists() and any(out.iterdir()):raise ValueError('output must be empty')
    out.mkdir(parents=True,exist_ok=True)
    cases={}
    for variant in ['battery','empty']:
        target=out/variant
        cmd=[sys.executable,str(Path(__file__).parent/'run_native_battery_072a5b9.py'),
            '--factorio',str(args.factorio.resolve()),'--ci-game-zip',str(args.ci_game_zip.resolve()),
            '--output',str(target),'--variant',variant]
        print(f'[B9] Starting true native {variant} scenario',flush=True)
        subprocess.run(cmd,check=True)
        data=json.loads((target/'result.json').read_text())
        assert data.get('native_500_ticks_pass') and data.get('independent_real_LOAD_ticks')==200, 'no real SAVE/LOAD confirmation'
        cases[variant]=data
    b=cases['battery']['native'];e=cases['empty']['native']
    assert b['battery_initial_j']==32000000 and b['battery_debited_j']==32000000 and b['battery_remaining_j']==0
    assert e['battery_initial_j']==e['battery_debited_j']==e['battery_remaining_j']==0
    assert b['concurrent_hybrid_ticks']>0 and e['concurrent_hybrid_ticks']==0
    assert b['battery_empty_tick']>260 and e['battery_empty_tick']==-1
    assert abs(b['burner_all_granted_j']-e['burner_all_granted_j']-32000000)<1
    assert abs(b['grid_all_j']-e['grid_all_j'])<0.1
    assert abs(b['auto_B_factory_export_j']-e['auto_B_factory_export_j'])<0.1
    assert b['end_B_direction']==e['end_B_direction']=='export' and b['variant']==e['variant']=='auto'
    assert b['factory_brownout_ticks']==e['factory_brownout_ticks']==217
    assert abs(b['finite_ledger_residual_j'])<0.01 and abs(e['finite_ledger_residual_j'])<0.01
    output={'source':'exact EM071 CI 0.1.62 sha256 91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575',
      'native_engine':'Factorio 2.1.24 build 87808','author_policy':'B_AUTO_factory_backfeed_allowed_even_when_traction_short',
      'source_gameplay_code_changed':False,'test_onboard_capacity_per_locomotive_J':2000000,
      'test_onboard_discharge_rate_W':1000000,'actual_native_locomotives':16,
      'native_proof':'two independent true 500-tick benchmarks + real server SAVE t300 and separate disk LOAD +200 ticks for BOTH',
      'test_battery_kind':'finite script-owned per-loco J ledger injecting precisely debited J to REAL native LuaBurner, NOT vanilla real battery prototype',
      'battery':cases['battery'],'empty_control':cases['empty']}
    (out/'comparison.json').write_text(json.dumps(output,indent=2,ensure_ascii=False)+'\n')
    print('[EM072A5 B9 FULL MATRIX + NATIVE SAVE LOAD PASS]',json.dumps({
       'policy':'B AUTO factory backfeed allowed','battery_start_j':b['battery_initial_j'],
       'battery_debited_j':b['battery_debited_j'], 'battery_empty_tick':b['battery_empty_tick'],
       'concurrent_grid_and_battery_ticks':b['concurrent_hybrid_ticks'],
       'same_grid_J':b['grid_all_j'],'extra_battery_to_real_burners_j':b['burner_all_granted_j']-e['burner_all_granted_j'],
       'factory_B_export_j':b['auto_B_factory_export_j'],'conservation_j':b['finite_ledger_residual_j']}))

if __name__=='__main__':main()