from pathlib import Path
import subprocess
p=Path(__file__).parent; w=p/'localqa';binary='/mnt/data/em087c/factorio/bin/x64/factorio';base=[binary,'--config',str(w/'config.ini'),'--mod-directory',str(w/'mods')]
for n,args in [('watch-native',['--test-scenario','em-watch-qa/native','--test-ticks','680']),('watch-powered',['--test-scenario','em-watch-qa/powered','--test-arg','full','--test-ticks','370']),('watch-disk-load',['--test-save','/mnt/data/em087e/disk/checkpoint.zip','--test-arg','load','--test-ticks','370'])]:
 with (p/(n+'.log')).open('w') as f:rc=subprocess.run(base+args,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
 t=(p/(n+'.log')).read_text(); print(n,rc,'PASS' if 'Test passed at tick' in t else 'NO PASS',flush=True)
