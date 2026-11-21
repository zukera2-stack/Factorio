#!/usr/bin/env python3
"""EM069 native Factorio 2.1.24 strict energy conservation + lifecycle + SAVE/LOAD.

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
    parser.add_argument('--variant',choices=['reservoir','reservoir-batteries'],required=True,help='Source EEI starts with 700MJ, zero native production')
    parser.add_argument('--require-zero-loss',action='store_true',help='Fail the release gate if any joules disappear during reconfiguration')
    parser.add_argument('--require-no-unintended-loss',action='store_true',help='Release gate: ignore only owner-measured buffers of explicitly dismantled substation')
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
    result={'variant':a.variant,'engine':'2.1.24 build 87808','mod_zip_sha256':sha,'scenarios':{},'save_reload':'unverified','transient_observations':[]}
    with tempfile.TemporaryDirectory(prefix='EM069-native-') as d:
        work=Path(d)
        mods=work/'mods';mods.mkdir()
        shutil.copyfile(a.game_zip,mods/'ElectrifiedMainline_0.1.62.zip')
        probe_name='em069-reservoir-probe' if a.variant=='reservoir' else 'em069-reservoirbattery-probe'
        probe=mods/(probe_name+'_0.0.1');probe.mkdir()
        (probe/'info.json').write_text(json.dumps({'name':probe_name,'version':'0.0.1','title':'EM065 Native Energy QA','author':'QA','factorio_version':'2.1','dependencies':['base >= 2.1.24','ElectrifiedMainline = 0.1.62']}),encoding='utf-8')
        source=(HERE/probe_name/'control.lua').read_text(encoding='utf-8')
        (probe/'control.lua').write_text(source,encoding='utf-8')
        (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True},{'name':probe_name,'enabled':True}]}),encoding='utf-8')
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
        meter=re.search(r'\[EM064 LEDGER RESULT\] lost_J=(\d+) loss_events=(\d+) created_J=(\d+) creation_events=(\d+)',native)
        assert meter, 'Per-tick energy ledger did not finish'
        lost,loss_events,created,create_events=map(int,meter.groups())
        policy=re.search(r'\[EM064 POLICY RESULT\] allowed_demolition_J=(\d+) unexplained_deficit_J=(\d+) created_J=(\d+)',native)
        assert policy, 'Substation-owner-specific policy ledger missing'
        allowed,unexplained,created_policy=map(int,policy.groups())
        assert abs((allowed+unexplained)-lost)<=3 and created_policy==created, 'Policy bucket mismatch'
        owned=re.search(r'\[EM064 DEMOLITION INVENTORY\] dt=(\d+) removed_station_J=(\d+) surviving_station_J=(\d+)',native)
        assert owned and int(owned.group(1))==670, 'Demolished substation inventory was not measured'
        measured_owner,measured_survivor=map(int,owned.groups()[1:])
        assert 0<=allowed<=measured_owner<=666668, 'Demolition allowance exceeds removed entity energy'
        assert measured_survivor>=0, 'Invalid surviving station energy inventory'

        event_rows=[]
        for hit in re.finditer(r'\[EM064 LEDGER\] dt=(\d+) total_J=([\d.]+) delta_J=([-\d.]+) expected_generation_J=([\d.]+) bridge_J=([\d.]+)',native):
            tick=int(hit.group(1))
            expected=float(hit.group(4));delta=float(hit.group(3))
            if expected-delta>4:
                event_rows.append({'tick':tick,'lost_j_rounded':round(expected-delta),'hidden_j_rounded':round(float(hit.group(5)))})
        result['energy_ledger']={'source_generation_mw':0,'period_ticks':1250,'loss_j':lost,'loss_events':loss_events,
                                 'created_j':created,'creation_events':create_events,'strict_zero_loss_pass':lost<=4 and created<=4,
                                 'accepted_for_release':unexplained<=4 and created<=4,'sampled_loss_events':event_rows,
                                 'note':'Whole-run ledger uses unrounded Lua double values; per-event sampled log integers can differ by a few rounding joules.'}
        result['energy_ledger'].update({
            'policy':'destroyed_substation_own_hidden_EEI_energy_may_dissipate',
            'demolished_station_buffer_j':measured_owner,
            'surviving_station_buffer_j_at_demolition':measured_survivor,
            'approved_demolition_discard_j':allowed,
            'remaining_unexplained_ledger_deficit_j':unexplained,
            'no_unintended_loss_release_gate_pass':unexplained<=4 and created<=4,
            'note_provenance':'EM065 finite source with power_production=0; exact native inventory of reservoir, sink, hidden EEI, vanilla accumulators.'})
        assert created<=4, f'UNACCEPTABLE: unexpected energy creation {created} J'
        reservoir=re.search(r'\[EM065 SOURCE RESERVOIR\] remaining_J=(\d+) production_setting_J=(\d+)', native)
        assert reservoir and int(reservoir.group(2))==0 and int(reservoir.group(1))>100000000, 'Finite-reservoir source test not demonstrated'
        result['source_reservoir']={'production_setting_j_per_tick':int(reservoir.group(2)),'remaining_j':int(reservoir.group(1))}
        assert unexplained<=4 and created<=4, f'EM069 release gate: unexplained {unexplained} J created {created} J'
        battery_match=re.search(r'\[EM065 BATTERY RESULT\] A_J=(\d+) B_J=(\d+) count=(\d+) limits_held=true',native)
        if a.variant=='reservoir-batteries':
            assert battery_match and int(battery_match.group(3))==8 and int(battery_match.group(1))>10000000 and int(battery_match.group(2))>10000000, 'External batteries were lost or depleted unexpectedly'
            result['external_accumulators']={'count':8,'source_total_end_j':int(battery_match.group(1)),'sink_total_end_j':int(battery_match.group(2)),'per_tick_flow_limits_respected':True}
        else:
            assert battery_match is None, 'No-battery case unexpectedly has accumulator markers'
        print(f'[EM064] live topology PASS ({len(markers)} checkpoints); ENERGY LEDGER loss={lost} J, created={created} J',flush=True)
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
        if a.variant=='reservoir-batteries': assert '[EM065 BATTERY RESULT]' in reloaded, 'External accumulator identities not rehydrated after save/load'
        delta=int(m.group(1))
        assert delta>5000000
        result['save_reload']={'passed':True,'save_bytes':checkpoint.stat().st_size,'extra_energy_j':delta,'continued_ticks':200}
        print('[EM064] disk SAVE→LOAD PASS: '+str(delta)+' J delivered after load',flush=True)
    result['status']='FUNCTIONAL_PASS_NONDEMOLITION_LEDGER_UNRESOLVED' if not result['energy_ledger']['no_unintended_loss_release_gate_pass'] else 'FUNCTIONAL_AND_POLICY_ENERGY_PASS'
    (a.out/'report.json').write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding='utf-8')
    print('[EM064 RESULT] native lifecycle and disk load PASS; policy-adjusted energy ledger '+('PASS' if result['energy_ledger']['no_unintended_loss_release_gate_pass'] else 'UNRESOLVED'),flush=True)
    if a.require_no_unintended_loss and not result['energy_ledger']['no_unintended_loss_release_gate_pass']:
        raise SystemExit('NONDEMOLITION ENERGY RELEASE GATE FAILED: '+str(result['energy_ledger']['remaining_unexplained_ledger_deficit_j'])+' J unresolved')
    if a.require_zero_loss and not result['energy_ledger']['strict_zero_loss_pass']:
        raise SystemExit('ENERGY RELEASE GATE FAILED: '+str(result['energy_ledger']['loss_j'])+' J lost')

if __name__=='__main__':main()