#!/usr/bin/env python3
"""Compare the old and optimized *same-version* 0.1.62 dispatcher in Factorio 2.1.24.

Both candidate ZIPs are required; do not compare against 0.1.61 because that
version is faster by starving consumers. Uses the same 48-site fixture and
960 real Factorio updates per build. Runs are independent disposable saves.

The single-max-removed average is a transparent diagnostic, not a hard UPS
or FPS guarantee, because more than one tick can include setup overhead.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time
import zipfile

BASELINE_SHA='8b3a22c6270afd676d7f451943feb61b2e5ba01060f4867628251098c8a977bb'
PATTERN=re.compile(r'Performed\s+(\d+) updates in\s+([\d.]+) ms\s+avg:\s+([\d.]+) ms, min:\s+([\d.]+) ms, max:\s+([\d.]+) ms')


def archive_sha(p):
    b=p.read_bytes()
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None, 'ZIP CRC failed'
        info=json.loads(z.read('ElectrifiedMainline/info.json'))
        assert info['version']=='0.1.62', 'both candidates must be exact 0.1.62 (no 061 starvation comparison)'
    return hashlib.sha256(b).hexdigest()


def invoke(exe,cmd,log,timeout):
    t=time.perf_counter()
    p=subprocess.run([str(exe),*cmd],text=True,capture_output=True,timeout=timeout,errors='replace')
    text=p.stdout+'\n'+p.stderr
    log.write_text(text,encoding='utf-8')
    if p.returncode:
        raise RuntimeError('Factorio exit='+str(p.returncode)+ '\n'+ '\n'.join(text.splitlines()[-15:]))
    return text,round(time.perf_counter()-t,2)


def run_case(exe,zip_path,fixture,out,label,ticks,timeout):
    case=out/label
    mods=case/'mods';mods.mkdir(parents=True,exist_ok=True)
    shutil.copy2(zip_path,mods/'ElectrifiedMainline_0.1.62.zip')
    shutil.copytree(fixture,mods/'em062-48sub-probe_0.0.1',dirs_exist_ok=True)
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True},{'name':'em062-48sub-probe','enabled':True}]}))
    sha=archive_sha(zip_path)
    print(f'[NATIVE {label}] creating temporary Factorio map...',flush=True)
    _,create_s=invoke(exe,['--mod-directory',str(mods),'--create',str(case/'save.zip')],case/'create.log',timeout)
    print(f'[NATIVE {label}] benchmarking {ticks} real Factorio ticks...',flush=True)
    s,elapsed=invoke(exe,['--mod-directory',str(mods),'--benchmark',str(case/'save.zip'),'--benchmark-ticks',str(ticks),'--benchmark-runs','1'],case/'game.log',timeout)
    x=PATTERN.search(s)
    if x is None:raise ValueError('native benchmark timing was not found')
    n=int(x.group(1));total=float(x.group(2));avg=float(x.group(3));lo=float(x.group(4));hi=float(x.group(5))
    if n!=ticks:raise ValueError(f'only {n}/{ticks} requested ticks executed')
    if '[EM062 48 STAGE1 PASS]' not in s:raise ValueError(f'{label} did not pass common 48-station source fairness test')
    full='[EM062 STRESS PASS]' in s
    warm=(total-hi)/(n-1) if n>1 else 0
    print(f'[NATIVE {label}] min={lo:.3f} ms, raw-avg={avg:.3f} ms, adjusted-single-peak={warm:.3f} ms, full-reroute={full}',flush=True)
    return {'name':label,'mod_sha256':sha,'ticks':n,'game_ms_total':total,'native_min_tick_ms':lo,'native_avg_tick_ms_including_map_setup':avg,'max_tick_ms':hi,'single_peak_removed_average_ms_diagnostic_only':round(warm,3),'full_reroute_and_outage_passed':full,'create_wall_s':create_s,'benchmark_wall_s':elapsed}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--engine-bin',type=Path,required=True)
    p.add_argument('--old-game-zip',type=Path,required=True)
    p.add_argument('--new-game-zip',type=Path,required=True)
    p.add_argument('--fixture-dir',type=Path,default=Path(__file__).resolve().parent/'em062-48sub-probe')
    p.add_argument('--out',type=Path,default=Path('build/opt-benchmark'))
    p.add_argument('--ticks',type=int,default=960)
    p.add_argument('--timeout',type=int,default=180)
    p.add_argument('--max-adjusted-ms',type=float,default=16.667)
    p.add_argument('--min-speedup',type=float,default=1.5)
    a=p.parse_args()
    exe=a.engine_bin.resolve();old=a.old_game_zip.resolve();new=a.new_game_zip.resolve();fixture=a.fixture_dir.resolve();out=a.out.resolve()
    out.mkdir(parents=True,exist_ok=True)
    v=subprocess.run([str(exe),'--version'],capture_output=True,text=True,timeout=15)
    assert v.returncode==0 and '2.1.24' in v.stdout, 'need actual Factorio 2.1.24 native engine'
    old_sha=archive_sha(old);new_sha=archive_sha(new)
    assert old_sha==BASELINE_SHA, 'old candidate should be the known slow 062 CI ZIP; wrong baseline'
    assert new_sha!=old_sha, 'optimized ZIP and old ZIP are identical'
    oldr=run_case(exe,old,fixture,out,'baseline',a.ticks,a.timeout)
    newr=run_case(exe,new,fixture,out,'optimized',a.ticks,a.timeout)
    speedup=oldr['single_peak_removed_average_ms_diagnostic_only']/max(newr['single_peak_removed_average_ms_diagnostic_only'],1e-9)
    okay=(speedup>=a.min_speedup and newr['single_peak_removed_average_ms_diagnostic_only']<=a.max_adjusted_ms and newr['full_reroute_and_outage_passed'])
    result={'game_version':'2.1.24','game_build':87808,'baseline':oldr,'optimized':newr,'speedup_single_peak_removed_heuristic':round(speedup,3),'target_ms_diagnostic':a.max_adjusted_ms,'full_optimized_functional_pass':newr['full_reroute_and_outage_passed'],'passed':okay,'limitations':'One peak removed mean is not a true steady-state sample; no universal UPS guarantee.'}
    (out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(f'[NATIVE PERF {"PASS" if okay else "FAIL"}] speedup={speedup:.2f}x, new estimate={newr["single_peak_removed_average_ms_diagnostic_only"]:.3f}ms, all 48-station phases={newr["full_reroute_and_outage_passed"]}',flush=True)
    if not okay:raise SystemExit(2)

if __name__=='__main__':main()