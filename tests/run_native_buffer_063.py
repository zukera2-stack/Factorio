#!/usr/bin/env python3
"""Real Factorio 2.1.24 experiments with two substations, native EEI relay and accumulators.

Requires a user-provided Factorio headless engine and exact approved experiment ZIP.
Never modifies player saves, production code, updater branch, or main.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import time
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
CASES = ('both', 'source', 'receiver', 'bridge')


def run(argv, logfile):
    start=time.perf_counter()
    result=subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True, timeout=100)
    logfile.write_text(result.stdout, encoding='utf-8')
    return result.returncode, result.stdout, round(time.perf_counter()-start, 3)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--engine',type=Path,required=True)
    p.add_argument('--game-zip',type=Path,required=True)
    p.add_argument('--output',type=Path,default=Path('build/native-buffer-063'))
    p.add_argument('--expected-sha256',default='18bfdd184f901aefa5c7cbf8e266359aa9ebd7a9e4036361b8ea1abda1629040')
    a=p.parse_args()
    if not a.engine.is_file():p.error('Headless Factorio binary not found')
    if not a.game_zip.is_file():p.error('Installable Factorio game ZIP not found')
    game_sha=hashlib.sha256(a.game_zip.read_bytes()).hexdigest()
    if game_sha!=a.expected_sha256:p.error(f'Wrong game ZIP SHA256: {game_sha}')
    with zipfile.ZipFile(a.game_zip) as z:
        assert z.testzip() is None, 'Corrupt game ZIP'
        inf=json.loads(z.read('ElectrifiedMainline/info.json'))
        assert inf['version']=='0.1.62',f'Expected exact 0.1.62, not {inf["version"]}'
    version=subprocess.check_output([str(a.engine),'--version'],text=True)
    assert '2.1.24' in version and '87808' in version, 'Expected Factorio 2.1.24 build 87808'
    a.output.mkdir(parents=True,exist_ok=True)
    result={'engine':version.splitlines()[0],'zip_sha256':game_sha,'cases':[]}
    source=(HERE/'em063-buffer-probe.lua').read_text(encoding='utf-8')
    for case in CASES:
        print(f'[EM063 {case}] preparing isolated native map',flush=True)
        with tempfile.TemporaryDirectory(prefix=f'EM063-{case}-') as temp:
            work=Path(temp); mods=work/'mods';mods.mkdir()
            shutil.copyfile(a.game_zip,mods/'ElectrifiedMainline_0.1.62.zip')
            name=f'em063-buffer-{case}'; root=mods/f'{name}_0.0.1';root.mkdir()
            info={'name':name,'version':'0.0.1','title':'EM063 Buffer '+case,'author':'QA','factorio_version':'2.1','dependencies':['base >= 2.1.24','ElectrifiedMainline = 0.1.62']}
            (root/'info.json').write_text(json.dumps(info),encoding='utf-8')
            (root/'control.lua').write_text(source,encoding='utf-8')
            (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True},{'name':name,'enabled':True}]}),encoding='utf-8')
            save=work/'qa.zip'
            ccode,clog,ct=run([str(a.engine),'--mod-directory',str(mods),'--create',str(save)],a.output/f'{case}-create.log')
            if ccode:raise RuntimeError(f'{case} map failed: {clog[-2000:]}')
            print(f'[EM063 {case}] running 1540 real game ticks',flush=True)
            bcode,blog,bt=run([str(a.engine),'--mod-directory',str(mods),'--benchmark',str(save),'--benchmark-ticks','1540','--benchmark-runs','1'],a.output/f'{case}-benchmark.log')
            delta=re.search(r'\[EM063 DELTA\] case='+case+r' source_battery_used_J=([0-9]+) receiver_battery_used_J=([0-9]+) sink_received_after_off_J=([0-9]+)',blog)
            samples=re.findall(r'\[EM063 SAMPLE\] case='+case+r' dt=(\d+) .*?hidden_out_J=([\d.]+)',blog)
            passed=bcode==0 and f'[EM063 NATIVE PASS] case={case}' in blog and delta is not None
            row={'case':case,'passed':passed,'create_s':ct,'benchmark_s':bt,'ticks':1540,
                 'source_battery_used_j':int(delta[1]) if delta else None,
                 'receiver_battery_used_j':int(delta[2]) if delta else None,
                 'sink_after_off_j':int(delta[3]) if delta else None,
                 'hidden_output_samples_j':[{ 'tick':int(x),'joules':float(y)} for x,y in samples]}
            result['cases'].append(row)
            print(f'[EM063 {case}] '+('PASS' if passed else 'FAIL')+f' | {row["sink_after_off_j"]} J delivered after generator off',flush=True)
            (a.output/'buffer-report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
            if not passed:raise RuntimeError(f'{case} native benchmark failed: {blog[-2200:]}')
    result['status']='PASS'
    result['total_ticks']=sum(x['ticks'] for x in result['cases'])
    (a.output/'buffer-report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(f'[EM063 PASS] {len(result["cases"])} source/sink buffer scenarios, {result["total_ticks"]} native Factorio ticks',flush=True)

if __name__=='__main__':main()