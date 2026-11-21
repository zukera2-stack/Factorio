#!/usr/bin/env python3
"""Real Factorio 2.1.24 x86-64, isolated 48-station dispatcher benchmark.

Works against a single immutable ZIP. Run separately for baseline and candidate,
compare median repeated results; never modifies a player's Factorio data.
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

def run(argv, log_file, timeout):
    started = time.perf_counter()
    with log_file.open('w', encoding='utf-8') as output:
        try:
            result = subprocess.run(argv, stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(f'Factorio exceeded {timeout}s; see {log_file}') from exc
    data = log_file.read_text(encoding='utf-8', errors='replace')
    if result.returncode != 0:
        raise RuntimeError(f'Factorio exited {result.returncode}; tail:\n{data[-3500:]}')
    return data, round(time.perf_counter()-started, 3)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine',type=Path,required=True)
    parser.add_argument('--game-zip',type=Path,required=True)
    parser.add_argument('--expected-sha256',required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--verbose',action='store_true',help='Record per-tick full profiler CSV; adds overhead')
    args=parser.parse_args()
    assert args.engine.is_file() and args.game_zip.is_file()
    assert '2.1.24' in subprocess.check_output([str(args.engine),'--version'],text=True)
    sha=hashlib.sha256(args.game_zip.read_bytes()).hexdigest()
    assert sha==args.expected_sha256, f'ZIP mismatch: {sha}'
    with zipfile.ZipFile(args.game_zip) as z:
        assert z.testzip() is None
        assert json.loads(z.read('ElectrifiedMainline/info.json'))['version']=='0.1.62'
    args.out.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='EM067-48-native-') as t:
        path=Path(t)
        mods=path/'mods';mods.mkdir()
        probe=mods/'em067-48sub-probe_0.0.1';probe.mkdir()
        for filename in ('control.lua','info.json'):
            shutil.copyfile(HERE/'em067-48sub-probe'/filename,probe/filename)
        shutil.copyfile(args.game_zip,mods/'ElectrifiedMainline_0.1.62.zip')
        (mods/'mod-list.json').write_text(json.dumps({'mods':[
            {'name':'base','enabled':True},
            {'name':'ElectrifiedMainline','enabled':True},
            {'name':'em067-48sub-probe','enabled':True}]}),encoding='utf-8')
        cfg=path/'config.ini'
        cfg.write_text('[path]\nread-data='+str(args.engine.resolve().parents[2]/'data')+'\nwrite-data='+str(path/'write')+'\n',encoding='utf-8')
        prefix=[str(args.engine),'--config',str(cfg),'--mod-directory',str(mods)]
        save=path/'fresh.zip'
        run(prefix+['--create',str(save)],args.out/'create.log',40)
        print('[EM067] Factorio 48 substations, 6x20MW, 42 sinks, 960 ticks',flush=True)
        command=prefix+['--benchmark',str(save),'--benchmark-ticks','960','--benchmark-runs','1']
        if args.verbose:command+=['--benchmark-verbose','all']
        log,seconds=run(command,args.out/'factorio-960.log',120)
        required=['[EM067 48 STAGE1 PASS]','[EM067 48 REROUTE PASS]','[EM067 48 PASS]']
        assert all(x in log for x in required), 'Game checks failed; tail: '+log[-3000:]
        match=re.search(r'Performed 960 updates in ([\d.]+) ms\s+avg: ([\d.]+) ms, min: ([\d.]+) ms, max: ([\d.]+) ms',log)
        assert match, 'Engine timing summary missing'
        data={'engine':'Factorio 2.1.24 headless','zip_sha256':sha,'native_48_pass':True,
              'checks':required,'engine_updates':960,'wall_seconds':seconds,
              'game_engine_updates_ms':float(match.group(1)),
              'game_engine_avg_ms_per_tick':float(match.group(2)),
              'game_engine_min_ms_per_tick':float(match.group(3)),
              'game_engine_max_ms_per_tick':float(match.group(4)),
              'profiling_verbose_enabled':args.verbose,
              'remark':'Includes map setup in tick 1; do not treat as steady-state UPS guarantee.'}
        (args.out/'report.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print('[EM067 NATIVE 48 PASS] '+json.dumps(data,ensure_ascii=False),flush=True)

if __name__=='__main__':main()