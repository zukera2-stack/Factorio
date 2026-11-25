from pathlib import Path
import argparse, json, shutil, subprocess, hashlib, tempfile
p=argparse.ArgumentParser();p.add_argument('--factorio',required=True,type=Path);p.add_argument('--mod-zip',required=True,type=Path);p.add_argument('--out',required=True,type=Path);a=p.parse_args();root=Path(__file__).resolve().parent;binary=a.factorio.resolve();z=a.mod_zip.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(z.read_bytes()).hexdigest()=='b95a2b41108dd7817ffd9bf818c0010f58b0294700de79ddaa301505ad9c4434','incorrect mod ZIP'
assert '2.1.24' in subprocess.check_output([str(binary),'--version'],text=True)
results=json.loads((root/'results.json').read_text());fail=[]
with tempfile.TemporaryDirectory(prefix='em087-regression-') as td:
 w=Path(td);mods=w/'mods';mods.mkdir();shutil.copy2(z,mods/'ElectrifiedMainline_0.1.87.zip')
 for s in (root/'qa_mods').iterdir():shutil.copytree(s,mods/s.name)
 (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True}]+[{'name':json.loads((s/'info.json').read_text())['name'],'enabled':True} for s in mods.iterdir() if s.is_dir()]}))
 cfg=w/'config.ini';cfg.write_text('[path]\nread-data='+str(binary.parents[2]/'data')+'\nwrite-data='+str(w)+'\n')
 for r in results:
  if r['status']!='PASS':continue
  cmd=r['command'][5:];cmd=[str(root/'fixtures/long201.zip') if x.endswith('/long201.zip') else x for x in cmd]
  with (out/(r['case']+'.log')).open('w') as f:rc=subprocess.run([str(binary),'--config',str(cfg),'--mod-directory',str(mods)]+cmd,stdout=f,stderr=subprocess.STDOUT).returncode
  ok=rc==0 and r['marker'] in (out/(r['case']+'.log')).read_text(errors='replace');print(r['case'],'PASS' if ok else 'FAIL',flush=True)
  if not ok:fail.append(r['case'])
print('Failed:',fail);raise SystemExit(bool(fail))
