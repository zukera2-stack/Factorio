#!/usr/bin/env python3
"""EM072-C3 disposable actual Factorio 2.1.24 native engine proof.
Proves two 500kW phantom locomotives can fit between unmodified wagon centers
without any increased center-to-center main consist span. DOES NOT prove
paid motor electricity or real rolling stock game-mod integration.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import socket
import subprocess
import time
from pathlib import Path

ASSET=Path(__file__).resolve().parent/'em-phantom-invisible'
R=re.compile(r'EM_PHANTOM_C3\|motion\|tick=(\d+)\|mode=([a-z_]+)\|y=([-\d.]+)\|speed=([\d.]+)\|n=(\d+)\|cars=([^\n]+)')


def call(cmd,log,timeout=180):
    with log.open('wb') as f:
        r=subprocess.run([str(x) for x in cmd],stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
    text=log.read_text('utf-8',errors='replace')
    if r.returncode:
        raise RuntimeError(f'Factorio failed rc={r.returncode} {cmd}:\n{text[-3000:]}')
    return text


def decode(txt,after_save=False):
    values={}
    for tick,mode,y,speed,n,cars in R.findall(txt):
        tick=int(tick)
        if tick not in ((160,240) if after_save else (100,160,240)): continue
        values[(tick,mode)]={'position_y':float(y),'speed':float(speed),'carriages':int(n),
                            'stock_names':[c.split('@')[0] for c in cars.split(',')],
                            'span':abs(float(cars.split(',')[0].split('@')[1])-float(cars.split(',')[-1].split('@')[1]))}
    variants=['control','two_hidden','disabled','offtrain','overlay']
    for tick in ((160,240) if after_save else (100,160,240)):
        for mode in variants:
            assert (tick,mode) in values,(tick,mode,sorted(values))
            x=values[(tick,mode)]
            assert abs(x['span']-14)<0.001, ('center-to-center length changed',tick,mode,x)
            assert x['carriages']==(5 if mode in ('two_hidden','disabled') else 3),(tick,mode,x)
        assert abs(values[(tick,'control')]['position_y']-values[(tick,'offtrain')]['position_y'])<0.001
        assert abs(values[(tick,'control')]['position_y']-values[(tick,'overlay')]['position_y'])<0.001
        assert abs(values[(tick,'two_hidden')]['position_y']-values[(tick,'disabled')]['position_y'])<0.001
        assert values[(tick,'two_hidden')]['position_y']<values[(tick,'control')]['position_y']
    for expected in (
        'EM_PHANTOM_C3|created|mode=overlay|l=true|w1=true|w2=true|p1=false',
        'EM_PHANTOM_C3|api|disabled_set_disabled|ok=true|result=false/false',
        'EM_PHANTOM_C3|api|disabled_set_active|ok=false|result=LuaEntity::active is read only.',
        'EM_PHANTOM_C3|coupled|mode=two_hidden|same=true',
        'EM_PHANTOM_C3|coupled|mode=offtrain|same=false',
    ):
        if not after_save: assert expected in txt,expected
    return {str(t):{mode:values[(t,mode)] for mode in variants}
            for t in ((160,240) if after_save else (100,160,240))}


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--factorio',required=True)
    p.add_argument('--output',required=True)
    a=p.parse_args()
    factorio=Path(a.factorio).resolve()
    out=Path(a.output).resolve()
    if out.exists() and any(out.iterdir()): raise RuntimeError('output directory must be empty')
    out.mkdir(parents=True,exist_ok=True)
    mods=out/'mods';mods.mkdir()
    shutil.copytree(ASSET,mods/'em-phantom-invisible_0.0.1')
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em-phantom-invisible','enabled':True}]}))
    private=out/'private';(private/'saves').mkdir(parents=True)
    cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(factorio.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
    cmd=[factorio,'--config',cfg,'--mod-directory',mods]
    version=subprocess.run([str(factorio),'--version'],capture_output=True,text=True,timeout=12).stdout
    assert '2.1.24' in version and '87808' in version,version
    call(cmd+['--create',out/'test.zip'],out/'create.log')
    txt=call(cmd+['--benchmark',out/'test.zip','--benchmark-ticks','245'],out/'native.log')
    baseline=decode(txt)
    assert 'EM_PHANTOM_C3|disk_save_request|tick=120|ok=true' in txt
    call(cmd+['--create',out/'server-start.zip'],out/'server-create.log')
    settings={'name':'C3 experimental phantom zero length native','description':'disposable no user saves',
              'max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,
              'auto_pause':False,'autosave_interval':100}
    (out/'server-settings.json').write_text(json.dumps(settings))
    with socket.socket() as sk:sk.bind(('127.0.0.1',0));port=sk.getsockname()[1]
    checkpoint=private/'saves/emc3-checkpoint.zip'
    serverlog=out/'server.log'
    with serverlog.open('w') as f:
        proc=subprocess.Popen([str(x) for x in cmd+['--start-server',out/'server-start.zip','--server-settings',out/'server-settings.json','--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
        try:
            for _ in range(240):
                time.sleep(.25)
                st=serverlog.read_text('utf-8',errors='replace')
                if proc.poll() is not None: raise RuntimeError('server stopped '+st[-2500:])
                if checkpoint.exists() and 'Saving finished' in st and 'EM_PHANTOM_C3|disk_save_request|tick=120|ok=true' in st:break
            else:raise TimeoutError('true native server SAVE not found '+st[-2500:])
        finally:
            proc.terminate()
            try:proc.wait(timeout=7)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
    reloadlog=call(cmd+['--test-save',checkpoint,'--test-ticks','125'],out/'native-reload.log')
    loaded=decode(reloadlog,after_save=True)
    for tick in ('160','240'):
        for mode in baseline[tick]:
            assert loaded[tick][mode]==baseline[tick][mode],(tick,mode,loaded[tick][mode],baseline[tick][mode])
    summary={'engine':'Factorio 2.1.24 build87808 Linux Headless Base-only',
      'result':'ZERO LENGTH GROWTH BETWEEN CARGO/FLUID CENTERS WITH TWO NATIVE 500KW INTEGRATED PHANTOM LOCOMOTIVES',
      'physical_unchanged_wagon_main_span_tiles':14,
      'negative_connection_distance':-0.1,'minimum_phantom_joint_distance':0.1,
      'control_train_carriages':3,'phantom_train_carriages':5,
      'native_total_static_nameplate_power_main_w':2000000,'native_total_static_nameplate_power_augmented_w':3000000,
      'phantom_sprite_asset':'__core__/graphics/empty.png',
      'control_speed_change_successful':False,
      'disable_property_ignored':True,'active_property_set_rejected':True,
      'energy_source':'void (MECHANICAL TEST ONLY; UNLIMITED FREE J; NOT GAMEPLAY ACCEPTABLE)',
      'true_native_245_tick_benchmark':True,'real_server_SAVE_tick':120,'independent_test_save_ticks':125,
      'native_checkpoint_bytes':checkpoint.stat().st_size,
      'baseline':baseline,'independent_reload':loaded,
      'benchmark_log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest(),
      'reload_log_sha256':hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest(),
      'native_player_blueprint_undo_mining_and_curves_tested':False,
      'production_mod_files_modified':False}
    (out/'result.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print('[C3 ZERO-LENGTH NATIVE PHANTOM PASS]',json.dumps({k:v for k,v in summary.items() if k not in ('baseline','independent_reload')},ensure_ascii=False))

if __name__=='__main__':main()