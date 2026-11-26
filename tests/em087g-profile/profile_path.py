from pathlib import Path
import zipfile,shutil,subprocess,re,statistics,json
p=Path(__file__).parent;engine=Path('/mnt/data/em087c/factorio');binary=engine/'bin/x64/factorio';fixture=p/'localqa/mods/em-watch-qa_0.0.1'
results={}
for tag in ['base','candidate']:
 w=p/('profile-'+tag);m=w/'mods';m.mkdir(parents=True,exist_ok=True);source=next((p/tag/'mods').glob('ElectrifiedMainline_*.zip'))
 with zipfile.ZipFile(source) as z,zipfile.ZipFile(m/source.name,'w',zipfile.ZIP_DEFLATED) as out:
  for n in z.namelist():
   data=z.read(n)
   if n.endswith('/scripts/technical_network_046.lua'):
    s=data.decode();a='  local s=M.ensure_storage()\n  local nodes,parents={},{}';b='  return M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)'
    assert s.count(a)==s.count(b)==1
    s=s.replace(a,'  local prof=(game.tick>=190 and game.tick<=380) and helpers.create_profiler() or nil\n'+a)
    s=s.replace(b,'''  local result=M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)
  if prof then prof.stop();log({"","[EM087G PROFILE] sync tick="..game.tick.." ",prof}) end
  return result''')
    data=s.encode()
   out.writestr(n,data)
 shutil.copytree(fixture,m/fixture.name,dirs_exist_ok=True);shutil.copy2(p/'localqa/mods/mod-list.json',m/'mod-list.json');cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={engine}/data\nwrite-data={w}\n')
 samples=[]
 for run in range(2):
  out=p/f'profile-{tag}-{run}.log';cmd=[str(binary),'--config',str(cfg),'--mod-directory',str(m),'--test-scenario','em-watch-qa/pathmemo','--test-ticks','610']
  with out.open('w') as f:rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
  t=out.read_text();print(tag,run,rc,'PASS' if 'Test passed at tick' in t else 'NO PASS',flush=True)
  if rc or 'Test passed at tick' not in t:raise RuntimeError(out)
  lines=[l for l in t.splitlines() if '[EM087G PROFILE]' in l];print('\n'.join(lines),flush=True)
  for l in lines:
   match=re.search(r'sync tick=(\d+) Duration: ([\d.]+)ms',l)
   if match:samples.append([int(match[1]),float(match[2])])
 results[tag]=samples
(p/'profile_results.json').write_text(json.dumps(results,indent=2));print(results,flush=True)
