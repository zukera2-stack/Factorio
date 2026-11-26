from pathlib import Path
import subprocess,sys
p=Path(__file__).parent;old=Path('/mnt/data/em087c');engine=old/'factorio/bin/x64/factorio';logs=p/'bench_logs';logs.mkdir(exist_ok=True)
for name in sys.argv[1:] or ['100x2','50x2','long201']:
 for tag in ['base','codeonly']:
  w=p/tag;out=logs/f'{tag}-{name}.log';cmd=[str(engine),'--config',str(w/'config.ini'),'--mod-directory',str(w/'mods'),'--benchmark',str(old/'evidence/saves'/f'{name}.zip'),'--benchmark-ticks','480' if name!='long201' else '1200','--benchmark-runs','2']
  with out.open('w') as f:rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
  t=out.read_text();print(name,tag,rc,[l.strip() for l in t.splitlines() if 'avg:' in l or 'checksum:' in l.lower()][-6:],flush=True)
  if rc:raise RuntimeError(out)
