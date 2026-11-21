#!/usr/bin/env python3
"""EM072-A3 research only: real native Factorio auto-demand, connected HSR path,
finite-energy debit, rail cut/rejoin, adjacent unconnected HSR and disk SAVE/LOAD.
Uses scratch copies of EM070 0.1.62 and pre-existing EM072-A2 test data.
No changes to installed mods, no public ZIP/release or game code commits.
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

CORE_SHA = {
    "scripts/power_bridge_058.lua": "4a4084e5cf71d57cc057aa15bc524ac68ff6268b",
    "scripts/technical_network_046.lua": "e8b1bad35fb60d22bdb91d2dd1c4c5055c58e172",
    "scripts/bridge_dispatch_059.lua": "4f4399d6277c27ec65b73d45fd1bf82f89d4bfe2",
    "scripts/control.lua": "3546d3b7c983856c367279d5dac21fe1c8b07f95",
}
MARKERS = (
    "[EM072A3 DISCONNECTED HSR PASS]",
    "[EM072A2 NATIVE PASS]",
    "[EM072A3 CUT PASS]",
    "[EM072A3 REJOIN PASS]",
    "[EM072A3 ZERO REQUEST PASS]",
    "[EM072A2 OFF PASS]",
)

def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()

def run(cmd, path, timeout=80):
    with path.open("w", encoding="utf8") as dest:
        subprocess.run(cmd, check=True, stdout=dest, stderr=subprocess.STDOUT, timeout=timeout)
    return path.read_text(encoding="utf8")

def check(text):
    missing=[marker for marker in MARKERS if marker not in text]
    if missing: raise AssertionError("Missing native engine evidence: " + ", ".join(missing))
    match=re.search(r"\[EM072A2 NATIVE PASS\].*?J=(\d+) consumed_J=(\d+) energy_residual=([-\d.]+)", text)
    if not match: raise AssertionError("Missing native joule ledger")
    got,spent,res=float(match[1]),float(match[2]),float(match[3])
    assert got > 4_000_000 and spent > 4_000_000 and abs(res)<0.01, (got,spent,res)
    match2=re.search(r"\[EM072A2 OFF PASS\].*?residual_J=([-\d.]+)",text)
    assert match2 and abs(float(match2[1]))<0.01
    return {'credited_j':got,'burned_j':spent,'remaining_j':got-spent,'residual_j':res}

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--factorio',type=Path,required=True)
    p.add_argument('--game-zip',type=Path,required=True,help='Pre-existing matching 0.1.62 CI ZIP')
    p.add_argument('--output',type=Path,required=True,help='Disposable folder, never a player game directory')
    a=p.parse_args()
    exe=a.factorio.resolve();out=a.output.resolve()
    root=Path(__file__).resolve().parent
    assets=root/'em072a3-auto-demand-probe'
    a2=root/'em072a2-grid-debit-probe'
    assert exe.is_file() and a.game_zip.is_file(), 'Native engine and pre-existing verified game ZIP required'
    for path in ('root-hook.lua','auto-demand.patch.lua','control.lua'):
        assert (assets/path).is_file(), 'Missing real-tested 072a3 fixture '+path
    for path in ('info.json','data.lua'):
        assert (a2/path).is_file(), 'Missing inherited 072a2 test prototype '+path
    if out.exists() and any(out.iterdir()):
        raise ValueError('Use a fresh disposable --output directory, never overwrite saves')
    out.mkdir(parents=True,exist_ok=True)
    mods=out/'mods';mods.mkdir()
    game=mods/'ElectrifiedMainline';game.mkdir()
    with zipfile.ZipFile(a.game_zip) as z:
        for name in z.namelist():
            path=Path(name)
            if not path.parts or path.parts[0] not in ('ElectrifiedMainline','ElectrifiedMainline_0.1.62') or '..' in path.parts:
                raise ValueError('Unsafe ZIP member '+name)
            if len(path.parts)==1 or name.endswith('/'):continue
            target=game.joinpath(*path.parts[1:]);target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(z.read(name))
    inf=json.loads((game/'info.json').read_text())
    assert inf['name']=='ElectrifiedMainline' and inf['version']=='0.1.62'
    for path,sha in CORE_SHA.items():
        assert git_blob((game/path).read_bytes())==sha, 'Wrong EM070 game core: '+path
    # Changes strictly limited to disposable extracted source. Production source is untouched.
    root_control=game/'control.lua'
    root_control.write_text(root_control.read_text()+ (assets/'root-hook.lua').read_text())
    bridge=game/'scripts/power_bridge_058.lua'
    source=bridge.read_text()
    anchor=' local direct=devices.sample(s,tick,physical,allowed)'
    assert source.count(anchor)==1
    bridge.write_text(source.replace(anchor,anchor+(assets/'auto-demand.patch.lua').read_text()))
    probe=mods/'em072-a2-probe_0.0.1';probe.mkdir()
    for name in ('info.json','data.lua'):shutil.copy2(a2/name,probe/name)
    shutil.copy2(assets/'control.lua',probe/'control.lua')
    names=['base','ElectrifiedMainline','em072-a2-probe']
    disabled=['space-age','elevated-rails','quality','recycler']
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in names]+[{'name':n,'enabled':False} for n in disabled]}))
    private=out/'private';(private/'saves').mkdir(parents=True)
    (out/'config.ini').write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
    cmd=[str(exe),'--config',str(out/'config.ini'),'--mod-directory',str(mods)]
    run(cmd+['--create',str(out/'start.zip')],out/'create.log')
    native=run(cmd+['--benchmark',str(out/'start.zip'),'--benchmark-ticks','490','--benchmark-runs','1'],out/'native.log')
    figures=check(native)
    run(cmd+['--create',str(out/'server-start.zip')],out/'server-create.log')
    settings={'name':'EM072-A3 disposable native auto traction QA','description':'Research-only, no player data',
              'max_players':1,'visibility':{'public':False,'lan':False},
              'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
    (out/'server-settings.json').write_text(json.dumps(settings))
    with socket.socket() as sock:
        sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
    logfile=out/'save-server.log'
    with logfile.open('w',encoding='utf8') as dst:
        proc=subprocess.Popen(cmd+['--start-server',str(out/'server-start.zip'),'--server-settings',str(out/'server-settings.json'),'--port',str(port)],stdout=dst,stderr=subprocess.STDOUT)
        checkpoint=private/'saves/em072a2-checkpoint.zip'
        try:
            for _ in range(180):
                time.sleep(.25)
                log=logfile.read_text(encoding='utf8',errors='replace')
                if proc.poll() is not None:raise RuntimeError('Native server exited: '+log[-1200:])
                if checkpoint.is_file() and '[EM072A2 DISK SAVE] t=151 requested=true' in log and 'Saving finished' in log:break
                if 'Error while running event' in log:raise RuntimeError(log[-1600:])
            else:raise TimeoutError('Native engine disk save not created at tick151')
        finally:
            proc.terminate()
            try:proc.wait(timeout=5)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
    resumed=run(cmd+['--test-save',str(checkpoint),'--test-ticks','340'],out/'native-reload.log')
    reloaded=check(resumed)
    for field in ('credited_j','burned_j','residual_j'):
        assert abs(figures[field]-reloaded[field])<0.01, 'Replay changed '+field
    report={'status':'PASS','engine':'Factorio 2.1.24 build 87808','real_gameplay_mod_modified':False,
            'native_benchmark_ticks':490,'server_disk_save_tick':151,'independent_reload_ticks':340,
            'native':figures,'reloaded':reloaded,'all_6_native_markers':list(MARKERS),
            'checkpoint_bytes':checkpoint.stat().st_size,
            'benchmark_log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest(),
            'reload_log_sha256':hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest(),
            'remaining_gates':['more than one train','multi-station fairness','dynamic train ID','UPS',
                'station schedule and automatic driver','collision/overlap rail geometry','factory brownout',
                'no 500kW motor wagons or regenerative braking']}
    (out/'report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
    print('[EM072A3 NATIVE AUTO/HSR/SAVE PASS] '+json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
