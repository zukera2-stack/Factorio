#!/usr/bin/env python3
"""Native Factorio 2.1.24 QA for dynamic catenary electrical topology and disk save/load.

Runs against an explicit installable game ZIP. Uses a disposable headless server,
private write-data/config, temporary probe mod and saves; does not touch player saves.
"""
import argparse, hashlib, json, re, shutil, socket, subprocess, tempfile, time, zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent

def call(args, logfile, timeout=50):
    p=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
    logfile.write_text(p.stdout,encoding='utf-8')
    if p.returncode != 0:raise RuntimeError(f'Factorio exit {p.returncode}; {logfile}:\n{p.stdout[-2500:]}')
    return p.stdout

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine',type=Path,required=True)
    parser.add_argument('--game-zip',type=Path,required=True)
    parser.add_argument('--expected-sha256',required=True)
    parser.add_argument('--out',type=Path,default=HERE/'results')
    a=parser.parse_args()
    assert a.engine.is_file() and a.game_zip.is_file(), 'Missing engine/game ZIP'
    sha=hashlib.sha256(a.game_zip.read_bytes()).hexdigest()
    assert sha==a.expected_sha256, f'Wrong immutable candidate SHA {sha}'
    v=subprocess.check_output([str(a.engine),'--version'],text=True)
    assert '2.1.24' in v and '87808' in v, 'Expected Factorio 2.1.24 build 87808'
    with zipfile.ZipFile(a.game_zip) as z:
        assert z.testzip() is None, 'ZIP CRC failure'
        assert json.loads(z.read('ElectrifiedMainline/info.json'))['version']=='0.1.62'
    a.out.mkdir(parents=True,exist_ok=True)
    print('[EM064] exact Factorio 2.1.24, test mod ZIP '+sha[:16]+'…',flush=True)
    result={'engine':'2.1.24 build 87808','mod_zip_sha256':sha,'scenarios':{},'save_reload':'unverified','transient_observations':[]}
    with tempfile.TemporaryDirectory(prefix='EM064-native-') as d:
        work=Path(d)
        mods=work/'mods';mods.mkdir()
        shutil.copyfile(a.game_zip,mods/'ElectrifiedMainline_0.1.62.zip')
        probe=mods/'em064-topology_0.0.1';probe.mkdir()
        (probe/'info.json').write_text(json.dumps({'name':'em064-topology','version':'0.0.1','title':'EM064 Native Topology QA','author':'QA','factorio_version':'2.1','dependencies':['base >= 2.1.24','ElectrifiedMainline = 0.1.62']}),encoding='utf-8')
        source=(HERE/'em064-topology-probe'/'control.lua').read_text(encoding='utf-8')
        (probe/'control.lua').write_text(source,encoding='utf-8')
        (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True},{'name':'em064-topology','enabled':True}]}),encoding='utf-8')
        cfg=work/'config.ini'
        cfg.write_text('[path]\nread-data='+str(a.engine.resolve().parents[2]/'data')+'\nwrite-data='+str(work/'private-data')+'\n')
        prefix=[str(a.engine),'--config',str(cfg),'--mod-directory',str(mods)]
        save=work/'start.zip'
        print('[EM064] create disposable map',flush=True)
        call(prefix+['--create',str(save)],a.out/'create.log')
        print('[EM064] benchmark 1350 ticks: wires, rails, substation, factory merge, script reload',flush=True)
        native=call(prefix+['--benchmark',str(save),'--benchmark-ticks','1350','--benchmark-runs','1'],a.out/'native-benchmark.log',timeout=90)
        markers=[l for l in native.splitlines() if '[EM064 PASS]' in l]
        assert len(markers)>=10 and '[EM064 NATIVE PASS]' in native, 'Topology checkpoint missing: '+str(markers)
        result['scenarios']['live_reconfiguration']={'passed':True,'ticks':1350,'markers':markers}
        obs=[l.strip() for l in native.splitlines() if '[EM064 OBSERVATION]' in l]
        result['transient_observations']=obs
        print('[EM064] live topology PASS; '+str(len(markers))+' checkpoints',flush=True)
        # Real save creation: run server until it emits checkpoint and passes,
        # then terminate gracefully to avoid running forever.
        server_source=source.replace('    -- EM064_SERVER_SAVE_HOOK (the test runner replaces this in server mode).',
            "    storage.em064_checkpoint_sink=f.sink.energy\n    game.server_save('em064-checkpoint')\n    log('[EM064] server checkpoint requested')")
        assert server_source!=source, 'Failed to inject disk-save hook'
        server_source=server_source.replace('  if t==180 then', '  if t==2 then pcall(function() game.speed=10 end) end\n  if t==180 then')
        (probe/'control.lua').write_text(server_source,encoding='utf-8')
        settings={'name':'EM064 isolated QA','description':'Temporary test', 'max_players':1,
                  'visibility':{'public':False,'lan':False},'require_user_verification':False,
                  'auto_pause':False,'autosave_interval':100,'only_admins_can_pause':True}
        (work/'settings.json').write_text(json.dumps(settings),encoding='utf-8')
        (work/'private-data'/'saves').mkdir(parents=True,exist_ok=True)
        server_log=a.out/'save-server.log'
        print('[EM064] start isolated headless server, save map to disk',flush=True)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1',0)); test_port=sock.getsockname()[1]
        with server_log.open('w',encoding='utf-8') as output:
            proc=subprocess.Popen(prefix+['--start-server',str(save),'--server-settings',str(work/'settings.json'),'--port',str(test_port)],stdout=output,stderr=subprocess.STDOUT)
            try:
                deadline=time.monotonic()+55
                checkpoint=work/'private-data'/'saves'/'em064-checkpoint.zip'
                while time.monotonic()<deadline:
                    time.sleep(0.4)
                    content=server_log.read_text(encoding='utf-8',errors='replace')
                    if proc.poll() is not None:raise RuntimeError('Server stopped: '+content[-1500:])
                    if checkpoint.is_file() and '[EM064 NATIVE PASS]' in content and 'Saving finished' in content:break
                    if 'Error ' in content or 'non-recoverable error' in content:raise RuntimeError('Server Lua error: '+content[-1700:])
                else:raise TimeoutError('Server checkpoint or pass marker not reached')
            finally:
                proc.terminate()
                try:proc.wait(timeout=8)
                except subprocess.TimeoutExpired:proc.kill();proc.wait()
        assert checkpoint.stat().st_size>100000, 'Saved checkpoint missing'
        print('[EM064] saved '+str(checkpoint.stat().st_size)+' bytes; reload real save from disk',flush=True)
        # Real process reload must restore the same networks; probe verifies
        # positive additional delivered joules after loading the saved map.
        reloaded=call(prefix+['--test-save',str(checkpoint),'--test-ticks','200'],a.out/'disk-reload.log',timeout=60)
        m=re.search(r'\[EM064 DISK PASS\].*sink_delta_J=(\d+)',reloaded)
        assert m and '[EM064 NATIVE PASS]' in reloaded, 'Real save/load power continuity not demonstrated'
        delta=int(m.group(1))
        assert delta>5000000
        result['save_reload']={'passed':True,'save_bytes':checkpoint.stat().st_size,'extra_energy_j':delta,'continued_ticks':200}
        print('[EM064] disk SAVE→LOAD PASS: '+str(delta)+' J delivered after load',flush=True)
    result['status']='PASS_WITH_ENERGY_RECONFIGURATION_CAVEAT'
    (a.out/'report.json').write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding='utf-8')
    print('[EM064 RESULT] native live and persisted topology PASS; residual relay buffer reviewed separately',flush=True)

if __name__=='__main__':main()