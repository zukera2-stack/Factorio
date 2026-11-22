#!/usr/bin/env python3
"""Genuine Factorio 2.1.24 native PRE-COUPLED -> temporary disconnect ->
insert two 500kW invisible locomotives -> reconnect, without changing 14-tile
center span; plus reversing by destroying and reconnecting, SAVE/LOAD.
Source VOID/UNPAID kinematics only, do not merge into gameplay.
"""
import argparse, hashlib, json, re, shutil, socket, subprocess, time
from pathlib import Path

SRC=Path(__file__).resolve().parent/'em-phantom-dynamic'
RE=re.compile(r'EM_C3D\|motion\|tick=(\d+)\|mode=([a-z_]+)\|y=([\d.-]+)\|train=(\d+)\|n=(\d+)\|span=([\d.]+)\|stock=([^\n]+)')


def run(cmd,out,timeout=180):
    with out.open('wb') as f:p=subprocess.run([str(v) for v in cmd],stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
    result=out.read_text(errors='replace')
    if p.returncode:raise RuntimeError(f'{p.returncode} {cmd}:\n{result[-2500:]}')
    return result


def parse(log,reload=False):
    data={}
    for t,k,y,tid,n,span,cars in RE.findall(log):
        if int(t) not in ((160,240) if reload else (100,160,240)):continue
        data[(int(t),k)]={'y':float(y),'n':int(n),'span':float(span),'stock':[x.split('@')[0] for x in cars.split(',')]}
    expect={'baseline':3,'hot':3,'detached':4,'detached_both':5,'restore':3,'prebuilt':5}
    for t in ((160,240) if reload else (100,160,240)):
        for k,n in expect.items():
            assert (t,k) in data,('missing',t,k)
            d=data[(t,k)];assert d['n']==n and abs(d['span']-14)<0.0001,(t,k,d)
        assert data[(t,'baseline')]['y']==data[(t,'hot')]['y']==data[(t,'restore')]['y'],(t,'restore did not return baseline motion')
        assert data[(t,'prebuilt')]['y']==data[(t,'detached_both')]['y'],(t,'dynamic two-phantom change did not match prebuilt')
        assert data[(t,'prebuilt')]['y']<data[(t,'detached')]['y']<data[(t,'baseline')]['y'],(t,'wrong native acceleration contribution')
    if not reload:
        phrases=['EM_C3D|insert|hot|p1=false|p2=false',
        'EM_C3D|both_second|added=true|train=',
        'EM_C3D|restore_both_inserted|p1=true|p2=true',
        'EM_C3D|restored_final|train=',
        'EM_C3D|api|restore_join_main|ok=true|out=true',
        'EM_C3D|api|restore_join_cargo|ok=true|out=true',
        'EM_C3D|disk_save_request|tick=120|ok=true']
        for p in phrases:assert p in log,p
    return {str(t):{k:data[(t,k)] for k in expect} for t in ((160,240) if reload else (100,160,240))}


def main():
    p=argparse.ArgumentParser();p.add_argument('--factorio',required=True);p.add_argument('--output',required=True);a=p.parse_args()
    exe=Path(a.factorio).resolve();out=Path(a.output).resolve()
    if out.exists() and any(out.iterdir()):raise RuntimeError('output nonempty')
    out.mkdir(parents=True,exist_ok=True);mods=out/'mods';mods.mkdir()
    shutil.copytree(SRC,mods/'em-phantom-dynamic_0.0.1')
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em-phantom-dynamic','enabled':True}]}))
    private=out/'private';(private/'saves').mkdir(parents=True)
    cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
    cmd=[exe,'--config',cfg,'--mod-directory',mods]
    vers=subprocess.run([str(exe),'--version'],capture_output=True,text=True,timeout=12).stdout
    assert '2.1.24' in vers and '87808' in vers,vers
    run(cmd+['--create',out/'initial.zip'],out/'create.log')
    bench=run(cmd+['--benchmark',out/'initial.zip','--benchmark-ticks','245'],out/'native.log')
    data=parse(bench)
    run(cmd+['--create',out/'server-start.zip'],out/'server-create.log')
    settings={'name':'C3 dynamic reconfiguration native','description':'scratch without user saves', 'max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
    (out/'server-settings.json').write_text(json.dumps(settings))
    with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
    cp=private/'saves/emc3d-checkpoint.zip';serverlog=out/'server.log'
    with serverlog.open('w') as f:
        proc=subprocess.Popen([str(v) for v in cmd+['--start-server',out/'server-start.zip','--server-settings',out/'server-settings.json','--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
        try:
            for i in range(240):
                time.sleep(.25);st=serverlog.read_text(errors='replace')
                if proc.poll() is not None:raise RuntimeError('server died '+st[-2400:])
                if cp.exists() and 'Saving finished' in st and 'EM_C3D|disk_save_request|tick=120|ok=true' in st:break
            else:raise TimeoutError('no disk checkpoint '+st[-2500:])
        finally:
            proc.terminate()
            try:proc.wait(timeout=8)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
    reloadtxt=run(cmd+['--test-save',cp,'--test-ticks','125'],out/'native-reload.log')
    loaded=parse(reloadtxt,reload=True)
    for tick in ('160','240'):assert loaded[tick]==data[tick],(tick,'SAVE/LOAD metric mismatch')
    result={'native_factorio':'2.1.24 build87808 Linux Headless Base only',
        'result':'DYNAMIC PHANTOM 500KW MOTORS CAN BE INSERTED INTO ALREADY COUPLED TRAIN WITH ZERO VISIBLE CENTER-LENGTH GROWTH AFTER SAFE DISCONNECT, RESTORE ALSO WORKS',
        'no_direct_insertion_into_occupied_joint':True,
        'genuine_dynamically_inserted_two_hidden_engines':2,
        'physical_original_locomotive_cargo_fluid_span_tiles':14.0,
        'main_original_stock_unit_numbers_preserved_in_test':True,
        'actual_native_train_ids_change_on_split_join':True,
        'native_train_carriages_before':3,'native_carriages_after_two_hidden':5,
        'native_carriages_after_removed_and_restored':3,
        'benchmark_ticks':245,'real_server_save_tick':120,'independent_reload_ticks':125,
        'checkpoint_bytes':cp.stat().st_size,
        'native_log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest(),
        'reload_log_sha256':hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest(),
        'mechanics_source':'void infinite power, strictly isolated physics, NOT approved energy accounting',
        'curved_tracks_and_mining_UI_MP': 'not tested',
        'benchmark':data,'reload':loaded}
    (out/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print('[EM072-C3 DYNAMIC TRUE NATIVE SAVE LOAD PASS]',json.dumps({k:v for k,v in result.items() if k not in ('benchmark','reload')},ensure_ascii=False))
if __name__=='__main__':main()