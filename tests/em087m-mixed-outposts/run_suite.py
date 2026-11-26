#!/usr/bin/env python3
"""Run exact EM087L full-mod native mixed-grid QA. No user mods or saves touched."""
import argparse, hashlib, json, pathlib, shutil, subprocess, zipfile
p=argparse.ArgumentParser();p.add_argument('--factorio',type=pathlib.Path,required=True);p.add_argument('--full-mod',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);p.add_argument('--checkpoint',type=pathlib.Path);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parent;eng=a.factorio.resolve();archive=a.full_mod.resolve();out=a.output.resolve()
assert hashlib.sha256(archive.read_bytes()).hexdigest()=='9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a','wrong exact 0.1.98 ZIP'
assert '2.1.24 (build 87808' in subprocess.check_output([str(eng),'--version'],text=True),'wrong native engine'
with zipfile.ZipFile(archive) as z:assert z.testzip() is None and len(z.namelist())==157
assert not out.exists(),'use a new isolated output directory';mods=out/'mods';mods.mkdir(parents=True)
shutil.copy2(archive,mods/'ElectrifiedMainline_0.1.98.zip');q=root/'em-mixed-outposts-qa_0.0.1';shutil.copytree(q,mods/q.name)
(mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','ElectrifiedMainline','em-mixed-outposts-qa')]}))
config=out/'config.ini';config.write_text(f'[path]\nread-data={eng.parents[2]/"data"}\nwrite-data={out}\n');cmd=[str(eng),'--config',str(config),'--mod-directory',str(mods)]
cases=[(x,['--test-scenario','em-mixed-outposts-qa/native','--test-arg',x]) for x in ('mixed','reverse','ring','train','solar','empty','battery','buffer','limit')]+[('scale',['--test-scenario','em-mixed-outposts-qa/scale'])]
if a.checkpoint:cases.append(('disk-load',['--test-save',str(a.checkpoint.resolve()),'--test-arg','mixed']))
result=[]
for name,args in cases:
 with (out/(name+'.log')).open('w') as f:rc=subprocess.run(cmd+args+['--test-ticks','1520'],stdout=f,stderr=subprocess.STDOUT,timeout=240).returncode
 s=(out/(name+'.log')).read_text(errors='replace');passed=rc==0 and 'Test passed at tick' in s;result.append({'name':name,'rc':rc,'pass':passed});print(name,'PASS' if passed else 'FAIL',flush=True)
(out/'results.json').write_text(json.dumps(result,indent=2));assert all(x['pass'] for x in result)
