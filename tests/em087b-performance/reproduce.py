#!/usr/bin/env python3
"""Repeat native regression and A/B benchmark on exact local archives. No user mod folder touched."""
from pathlib import Path
import argparse,json,hashlib,subprocess,shutil,tempfile,re
ap=argparse.ArgumentParser();ap.add_argument('--factorio',type=Path,required=True);ap.add_argument('--base',type=Path,required=True);ap.add_argument('--candidate',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--mode',choices=['native','bench','all'],default='native');a=ap.parse_args();root=Path(__file__).resolve().parent
binary=a.factorio.resolve();base=a.base.resolve();candidate=a.candidate.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
for f,h in [(base,'b95a2b41108dd7817ffd9bf818c0010f58b0294700de79ddaa301505ad9c4434'),(candidate,'43e4b0d4e24866dfa64eb030694efc08880607741c922a19f7f37f886f595007')]:assert hashlib.sha256(f.read_bytes()).hexdigest()==h,'unexpected archive '+str(f)
assert '2.1.24' in subprocess.check_output([str(binary),'--version'],text=True)
failed=[]
with tempfile.TemporaryDirectory(prefix='em087b-repeat-') as td:
 w=Path(td);mods=w/'mods';mods.mkdir();cfg=w/'config.ini';cfg.write_text('[path]\nread-data='+str(binary.parents[2]/'data')+'\nwrite-data='+str(w)+'\n')
 for d in (root/'qa_mods').iterdir():shutil.copytree(d,mods/d.name)
 modnames=[{'name':'base','enabled':True},{'name':'ElectrifiedMainline','enabled':True}]+[{'name':json.loads((s/'info.json').read_text())['name'],'enabled':True} for s in mods.iterdir() if s.is_dir()];(mods/'mod-list.json').write_text(json.dumps({'mods':modnames}))
 def run(name,args,marker=None):
  logfile=out/(name+'.log')
  with logfile.open('w') as f:rc=subprocess.run([str(binary),'--config',str(cfg),'--mod-directory',str(mods)]+args,stdout=f,stderr=subprocess.STDOUT).returncode
  text=logfile.read_text(errors='replace');ok=rc==0 and (marker in text if marker else 'checksum:' in text);print(name,'PASS' if ok else 'FAIL',flush=True)
  if not ok:failed.append(name)
  return text
 if a.mode in ('native','all'):
  target=mods/'ElectrifiedMainline_0.1.88.zip';shutil.copy2(candidate,target)
  for r in json.loads((root/'regression_cases.json').read_text()):
   args=[str(root/'saves/long201.zip') if x.endswith('/long201.zip') else x for x in r['command'][5:]]
   run(r['case'],args,r['marker'])
  target.unlink()
 if a.mode in ('bench','all'):
  shutil.copy2(root/'benchmark_mod-list.json',mods/'mod-list.json')
  # Create the code-only comparison ZIP from the tested candidate, preserving the base info.json.
  import zipfile
  for name in ('50x2','100x2','long201'):
   z=mods/'ElectrifiedMainline_0.1.87.zip';shutil.copy2(base,z)
   args=['--benchmark',str(root/'saves'/f'{name}.zip'),'--benchmark-ticks','1200' if name=='long201' else '480','--benchmark-runs','2']
   left=run('base-'+name,args)
   with zipfile.ZipFile(base) as old,zipfile.ZipFile(candidate) as new,zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as dest:
    for n in new.namelist():
     relative=n.split('/',1)[1];name87='ElectrifiedMainline_0.1.87/'+relative
     dest.writestr(name87,old.read(name87) if relative=='info.json' else new.read(n))
   right=run('codeonly-'+name,args);z.unlink()
   checks=lambda t:re.findall(r'^\s*checksum: (\d+)',t,re.M)
   if checks(left)!=checks(right):failed.append('checksum-'+name)
print('failed=',failed);raise SystemExit(bool(failed))
