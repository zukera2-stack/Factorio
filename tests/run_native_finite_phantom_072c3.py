#!/usr/bin/env python3
"""EM072-C3 internal-only LuaBurner finite-J proof for hidden 500kW motors.
This DOES use a hidden FuelCategory as ENGINE ADAPTER, explicitly not owner-approved
and no gameplay implementation; the game never receives free paid-motor J.
"""
import argparse, hashlib, json, re, shutil, socket, subprocess, time
from pathlib import Path

SRC=Path(__file__).resolve().parent/'em-phantom-finite'
RE=re.compile(r'EM_C3F\|motion\|tick=(\d+)\|mode=(control|void|paid|empty)\|y=([-\d.]+)\|speed=([\d.]+)\|n=(\d+)\|paid_j_remaining=([\d.]+)')

def run(cmd,log):
    with log.open('wb') as f:x=subprocess.run([str(x) for x in cmd],stdout=f,stderr=subprocess.STDOUT,timeout=170)
    v=log.read_text(errors='replace')
    if x.returncode:raise RuntimeError('Native failed: '+v[-3000:])
    return v

def parse(txt,reload=False):
    data={}
    for t,k,y,v,n,ej in RE.findall(txt):
        t=int(t)
        if t not in ((30,40,60,100,180,240) if reload else (20,30,40,60,100,180,240)):continue
        data[(t,k)]={'y':float(y),'speed':float(v),'n':int(n),'J_remaining':float(ej)}
    ts=(30,40,60,100,180,240) if reload else (20,30,40,60,100,180,240)
    for t in ts:
        for k in ('control','void','paid','empty'):
            assert (t,k) in data,(t,k)
            x=data[(t,k)];assert x['n']==(3 if k=='control' else 5)
        assert data[(t,'void')]['y']<data[(t,'paid')]['y']<data[(t,'control')]['y'] or t==20,(t,'native position expectation',data)
        assert data[(t,'empty')]['J_remaining']==0 and data[(t,'void')]['J_remaining']==0
    assert abs(data[(30,'paid')]['J_remaining']-98888.889)<0.01
    for t in (40,60,100,180,240):assert data[(t,'paid')]['J_remaining']==0
    if not reload:
        assert txt.count('|ok=true|res=nil|value=200000')==2
        assert 'EM_C3F|disk_save_request|tick=25|ok=true' in txt
    return {str(t):{k:data[(t,k)] for k in ('control','void','paid','empty')} for t in ts}

def main():
    p=argparse.ArgumentParser();p.add_argument('--factorio',required=True);p.add_argument('--output',required=True);a=p.parse_args()
    exe=Path(a.factorio).resolve();out=Path(a.output).resolve()
    if out.exists() and any(out.iterdir()):raise RuntimeError('output nonempty')
    out.mkdir(parents=True,exist_ok=True)
    mods=out/'mods';mods.mkdir();shutil.copytree(SRC,mods/'em-phantom-finite_0.0.1')
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'em-phantom-finite','enabled':True}]}))
    private=out/'private';(private/'saves').mkdir(parents=True)
    cfg=out/'config.ini';cfg.write_text('[path]\nread-data='+str(exe.parents[2]/'data')+'\nwrite-data='+str(private)+'\n')
    cmd=[exe,'--config',cfg,'--mod-directory',mods]
    ver=subprocess.run([str(exe),'--version'],capture_output=True,text=True,timeout=12).stdout
    assert '2.1.24' in ver and '87808' in ver
    run(cmd+['--create',out/'initial.zip'],out/'create.log')
    txt=run(cmd+['--benchmark',out/'initial.zip','--benchmark-ticks','245'],out/'native.log')
    data=parse(txt)
    run(cmd+['--create',out/'server-start.zip'],out/'server-create.log')
    settings={'name':'C3 finite hidden native test','description':'disposable no user saves', 'max_players':1,'visibility':{'public':False,'lan':False},'require_user_verification':False,'auto_pause':False,'autosave_interval':100}
    (out/'server-settings.json').write_text(json.dumps(settings))
    with socket.socket() as sk:sk.bind(('127.0.0.1',0));port=sk.getsockname()[1]
    cp=private/'saves/emc3f-checkpoint.zip';server=out/'server.log'
    with server.open('w') as f:
        proc=subprocess.Popen([str(x) for x in cmd+['--start-server',out/'server-start.zip','--server-settings',out/'server-settings.json','--port',str(port)]],stdout=f,stderr=subprocess.STDOUT)
        try:
            for _ in range(240):
                time.sleep(.25);st=server.read_text(errors='replace')
                if proc.poll() is not None:raise RuntimeError('server died: '+st[-2000:])
                if cp.exists() and 'Saving finished' in st and 'EM_C3F|disk_save_request|tick=25|ok=true' in st:break
            else:raise TimeoutError('no checkpoint: '+st[-2200:])
        finally:
            proc.terminate()
            try:proc.wait(timeout=6)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
    reloadtxt=run(cmd+['--test-save',cp,'--test-ticks','220'],out/'native-reload.log')
    loaded=parse(reloadtxt,reload=True)
    for t in loaded:assert loaded[t]==data[t],(t,loaded[t],data[t])
    result={'native_engine':'Factorio 2.1.24 build 87808 Linux Headless Base-only',
      'status':'RESEARCH FINITE-HIDDEN-BURNER API CAN POWER GEOMETRY-NON-GROWING 500kW PHANTOMS AND STOPS ON ZERO J',
      'user_no_fuels_policy_respected_in_gameplay':'no gameplay changes; research uses internally hidden fuel token ONLY, requires separate owner decision',
      'original_visible_carriage_geometry_unchanged_tiles':14.0,'native_carriage_count_augmented':5,
      'phantom_power_each_w':500000,'phantom_initial_j_each':200000,'real_native_phantom_total_burned_j':400000,
      'phantom_paid_energy_J_remaining_at_tick30':data['30']['paid']['J_remaining'],
      'phantom_paid_energy_J_remaining_at_tick40':0,
      'phantom_void_energy_free':True,'disabled_by_script_ignored':True,
      'genuine_server_SAVE_tick':25,'independent_real_LOAD_ticks':220,
      'checkpoint_bytes':cp.stat().st_size,
      'native_log_sha256':hashlib.sha256((out/'native.log').read_bytes()).hexdigest(),
      'independent_log_sha256':hashlib.sha256((out/'native-reload.log').read_bytes()).hexdigest(),
      'tests_with_EM070_actual_grid':False,
      'production_mod_changed':False,
      'benchmark':data,'reload':loaded}
    (out/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print('[C3 FINITE HIDDEN MOTOR REAL SAVE LOAD PASS]',json.dumps({k:v for k,v in result.items() if k not in ('benchmark','reload')},ensure_ascii=False))
if __name__=='__main__':main()