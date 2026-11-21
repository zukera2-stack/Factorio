#!/usr/bin/env python3
"""Standalone repeatable stress testing using real Factorio 2.1.24 engine.

This never modifies a player save or updater. Test-only Lua checks use the actual
engine and unmodified release ZIP. The 48-site performance gate is **diagnostic**;
headless timings include startup and are not a guarantee of user's UPS.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import time
import zipfile
from pathlib import Path

TESTS = (
    ("em062-stress-probe", 1050, "[EM062 STRESS PASS]"),
    ("em062-multisource-probe", 1050, "[EM062 MULTI PASS]"),
    ("em062-factory-reserve-probe", 950, "[EM062 DEFICIT PASS]"),
)
LONG_TEST = ("em062-48sub-probe", 270, "[EM062 48 STAGE1 PASS]")
BASELINE_TEST = ("em061-perf48-probe", 270, "[EM061 PERF 48 STAGE1]")

def inspect_zip(path, version):
    data=path.read_bytes()
    sha=hashlib.sha256(data).hexdigest()
    with zipfile.ZipFile(path) as z:
        info=json.loads(z.read('ElectrifiedMainline/info.json'))
        assert info['version']==version, f"expected game mod {version}, actual {info['version']}"
        assert z.testzip() is None, 'broken game ZIP CRC'
        pngs=sum(n.endswith('.png') for n in z.namelist())
        print(f'[ZIP] v{version}, SHA256={sha}, {len(z.namelist())} files, {pngs} PNGs',flush=True)
    return sha

def invoke(bin_, args, log_path):
    start=time.perf_counter()
    p=subprocess.run([str(bin_), *args],capture_output=True,text=True,errors='replace',timeout=180)
    elapsed=round(time.perf_counter()-start,3)
    body=p.stdout+'\n'+p.stderr
    log_path.write_text(body,encoding='utf-8')
    if p.returncode:
        raise RuntimeError(f'Factorio exit {p.returncode}; last log lines:\n'+'\n'.join(body.splitlines()[-26:]))
    return body,elapsed

def run(bin_,root,output,name,ticks,marker,mod_zip):
    case=output/name
    case.mkdir(parents=True,exist_ok=True)
    mods=case/'mods';mods.mkdir(exist_ok=True)
    game_name='ElectrifiedMainline_'+('0.1.61' if '061' in name else '0.1.62')+'.zip'
    shutil.copy2(mod_zip,mods/game_name)
    shutil.copytree(root/name,mods/(name+'_0.0.1'),dirs_exist_ok=True)
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True},{'name':name,'enabled':True}]}))
    save=case/'temporary-map.zip'
    print(f'[RUN] {name}: create temporary save',flush=True)
    _,create_s=invoke(bin_,['--mod-directory',str(mods),'--create',str(save)],case/'create.log')
    print(f'[RUN] {name}: {ticks} real native ticks',flush=True)
    log,bench_s=invoke(bin_,['--mod-directory',str(mods),'--benchmark',str(save),'--benchmark-ticks',str(ticks),'--benchmark-runs','1'],case/'game.log')
    if marker not in log:
        raise AssertionError(f'missing required {marker}; last log lines:\n'+'\n'.join(log.splitlines()[-15:]))
    metrics={}
    match=re.search(r'avg:\s*([\d.]+)\s*ms, min:\s*([\d.]+)\s*ms, max:\s*([\d.]+)\s*ms',log)
    if match: metrics=dict(zip(['mean_ms_including_setup','min_ms','max_ms'],map(float,match.groups())))
    evidence=[line.strip() for line in log.splitlines() if ('[EM062 STRESS]' in line or '[EM062 MULTI]' in line or '[EM062 DEFICIT]' in line or '[EM062 48 STAGE1 PASS]' in line or '[EM061 PERF]' in line or marker in line)]
    print(f'[PASS] {name}: {ticks} ticks, wall={create_s+bench_s:.2f}s, min={metrics.get("min_ms")}ms',flush=True)
    return {'fixture':name,'ticks':ticks,'marker':marker,'passed':True,'create_wall_seconds':create_s,'benchmark_wall_seconds':bench_s,'metrics':metrics,'evidence':evidence}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine-bin',type=Path,required=True)
    parser.add_argument('--game-zip',type=Path,required=True)
    parser.add_argument('--baseline-zip',type=Path)
    parser.add_argument('--include-48',action='store_true')
    parser.add_argument('--only',choices=[x[0] for x in TESTS]+[LONG_TEST[0]],help='Run one native case to avoid prolonged unattended batches')
    parser.add_argument('--out',type=Path,default=Path('build/native-stress-062'))
    a=parser.parse_args()
    engine=a.engine_bin.resolve();mod=a.game_zip.resolve();out=a.out.resolve()
    out.mkdir(parents=True,exist_ok=True)
    p=subprocess.run([str(engine),'--version'],capture_output=True,text=True)
    assert p.returncode==0 and '2.1.24' in p.stdout, f'Factorio must be 2.1.24; observed {p.stdout[:160]}'
    print('[ENGINE] '+p.stdout.splitlines()[0],flush=True)
    sha=inspect_zip(mod,'0.1.62')
    root=Path(__file__).resolve().parent
    runs=[]
    for name,ticks,marker in TESTS:
        if a.only and name!=a.only: continue
        runs.append(run(engine,root,out,name,ticks,marker,mod))
    warning=None
    if a.include_48 or a.only==LONG_TEST[0]:
        runs.append(run(engine,root,out,*LONG_TEST,mod))
        slow=runs[-1]['metrics'].get('min_ms')
        if slow is not None and slow>1000/60:
            warning=f'48-substation best-tick {slow:.3f}ms exceeds 60UPS update budget {1000/60:.3f}ms'
        if a.baseline_zip:
            prior=a.baseline_zip.resolve();base_sha=inspect_zip(prior,'0.1.61')
            base=run(engine,root,out,*BASELINE_TEST,prior)
            runs.append(base)
            fast=base['metrics'].get('min_ms')
            if slow and fast and slow>fast*2:
                warning=(warning+'; ' if warning else '')+f'062 best tick {slow/fast:.1f}x slower than 061 baseline {fast:.3f}ms'
    obj={'engine_version':'2.1.24','mod_version':'0.1.62','mod_sha256':sha,'native_tests':runs,'performance_warning':warning,'main_or_approved_ref_modified':False}
    (out/'stress-report.json').write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
    if warning: print('[PERFORMANCE WARNING] '+warning,flush=True)
    print(f'[NATIVE STRESS] {len(runs)}/{len(runs)} fixtures passed. Performance gate: {"WARN" if warning else "not evaluated"}.',flush=True)

if __name__=='__main__':
    try: main()
    except Exception as e:
        print('[NATIVE STRESS FAIL] '+str(e),file=sys.stderr,flush=True)
        sys.exit(1)