from pathlib import Path
import json,re,hashlib,zipfile,subprocess
p=Path(__file__).parent;root=p.parent
metrics={};lines=['| Stand | Base mean ms | Code-only mean ms | Change | Worst base/new ms | Checksum base/new |','|---|---:|---:|---:|---:|---|']
tags=['[EM072 PAID LEDGER]','[EM068 ACTUAL NATIVE TRAIN LOAD]','[EM065 CONTACT]','[EM060]','[EM069 BUFFER STOP]']
for name in ['50x2','100x2','long201']:
 data={};logs={}
 for tag in ['base','codeonly']:
  log=(p/'bench_logs'/f'{tag}-{name}.log').read_text();logs[tag]=log
  runs=re.findall(r'avg: ([0-9.]+) ms, min: ([0-9.]+) ms, max: ([0-9.]+) ms',log);checks=re.findall(r'^\s*checksum: (\d+)',log,re.M)
  assert len(runs)==len(checks)==2,(name,tag,runs,checks)
  data[tag]={'runs':runs,'mean_ms':sum(float(x[0]) for x in runs)/2,'max_ms':max(float(x[2]) for x in runs),'checksums':checks}
 compare={}
 for prefix in tags:
  a,b=([x[x.index(prefix):] for x in logs[tag].splitlines() if prefix in x] for tag in ['base','codeonly']);compare[prefix]={'base_count':len(a),'candidate_count':len(b),'equal':a==b}
 data['logs']=compare;metrics[name]=data;a,b=data['base'],data['codeonly'];pct=100*(b['mean_ms']/a['mean_ms']-1)
 lines.append(f"| {name} | {a['mean_ms']:.3f} | {b['mean_ms']:.3f} | {pct:+.2f}% | {a['max_ms']:.3f}/{b['max_ms']:.3f} | {a['checksums'][0]}/{b['checksums'][0]} |")
(p/'benchmarks.json').write_text(json.dumps(metrics,indent=2))
reg=json.loads((p/'regression_results.json').read_text());assert len(reg)==53 and all(x['status']=='PASS' for x in reg)
extra=['watch-native','watch-powered','watch-disk-load','localplan','pathmemo','native-router','disk-reload'];assert all('Test passed at tick' in (p/(x+'.log')).read_text() for x in extra)
report=(p/'report_header.md').read_text()+'\n\n### Fresh same-version disk reload\n\nSaved 0.1.93 at tick250 with two breaks and a populated path memo (real headless server). Loaded the exact disk ZIP (1002639 bytes) with same game version and QA scenario, verified both splits at t260, positive/negative reuse on subsequent repairs, further silent cut, restoration by full audit; explicit PASS t602. The first server attempt failed because the isolated saves directory did not exist; corrected fixture setup and repeated successfully. Gameplay unchanged. This adds one scenario, total **60/60** (55 explicit + 5 stands), plus four profiled runs. No Windows GUI or MP sync verification.\n\n## Stationary whole-tick comparison\n\nSame synthetic saves, code-only variant with same info version 0.1.92, two runs each, 480 ticks for 50/100, 1200 for long201. Full version performance A/B not run. Run in sequence after functional testing.\n\n'+'\n'.join(lines)+'\n\n'
report+='Paired recorded logs (prefix removed):\n\n'
for name,data in metrics.items():report+=f'- {name}: '+', '.join(f'{tag}: {v["base_count"]}/{v["candidate_count"]}, '+('equal' if v['equal'] else 'DIFFERENT') for tag,v in data['logs'].items())+'\n'
report+='\n## Decision / next\n\nDo not adopt EM087G as an optimization: functional tests passed but event sync regressed 11.2%, 100 stationary trains regressed ~3.9%, performance gate NOT MET. Keep as research branch; use EM087F 0.1.92 as comparison base for next experiment, without assuming it is accepted. User explicitly prefers vanilla-first. Next prioritize profile of native wire audit and bridge reads; reduce redundant checks only with exact equivalence evidence. Explore native subnetwork accounting vs the verified topology policy, never equate electrical ID alone with allowed HSR path or assume native train routing is electrical continuity. Avoid adding layers of persistent Lua graph/cache without measured benefit. Do not change 60/600 cadence without safe coverage for silent edits. 100km, junctions, multiplayer, mod compatibility, long run, memory A/B and full Windows helper invisibility remain open. No main merge, release or primary install.\n\n## Direct Patch\n\nTwo replacements, zero deletions, approved build/verify PASS. ZIP SHA256 `b1e5f966a83d5cd2b6f228444d25a38ba8903c233a2a381a00339fc4b6bd00ae`; target tree `5a85264832b69e907f3cc4f950f20adce986289a7f46f2f34f01667ea8726166`. Exact 0.1.92 isolated install only.\n\n## Regression results\n\n| Case | Status | seconds |\n|---|---|---:|\n'
report+='\n'.join(f"| `{x['case']}` | {x['status']} | {x['seconds']:.3f} |" for x in reg)+'\n'+'\n'.join(f'| `{x}` | PASS | — |' for x in extra)+'\n'
reportpath=root/'EM087G_PATH_MEMO_QA.md';reportpath.write_text(report)
out=root/'EM087G_PATH_MEMO_EVIDENCE.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for f in [reportpath,root/'EM087G_path_memo.manifest.json',root/'EM087G_path_memo_EXPERIMENT_Direct_Patch_from_0.1.92.zip',*[p/x for x in ['prepare.py','regression.py','extra.py','bench.py','profile_path.py','disk_test.py','finalize.py','regression_results.json','profile_results.json','benchmarks.json','regression.progress','extra.progress','profile.progress','bench.progress','disk.progress']],*p.glob('*.log')]:z.write(f,'reports/'+f.name)
 for d in ['regression','bench_logs']:
  for f in sorted((p/d).glob('*')):z.write(f,d+'/'+f.name)
 for d in [p/'disk/mods/em-watch-qa_0.0.1',Path('/mnt/data/em087c/evidence/qa_mods')]:
  for f in sorted(d.rglob('*')):
   if f.is_file():z.write(f,'qa_mods/'+(d.name+'/' if d.name!='qa_mods' else '')+str(f.relative_to(d)))
 for f in Path('/mnt/data/em087c/evidence/saves').glob('*.zip'):z.write(f,'saves/'+f.name)
 for f,n in [(Path('/mnt/data/em087e/disk/checkpoint.zip'),'em087e-watcher.zip'),(p/'pathmemo-checkpoint.zip','em087g-pathmemo-checkpoint.zip')]:z.write(f,'saves/'+n)
 for n in ['regression_cases.json','benchmark_mod-list.json']:z.write(Path('/mnt/data/em087c/evidence')/n,'reports/'+n)
 for x in json.loads((root/'EM087G_path_memo.manifest.json').read_text())['files']:z.write(p/'src/ElectrifiedMainline_0.1.92'/x['path'],'changed_source/'+x['path'])
 print('evidence entries',len(z.namelist()))
print('\n'.join(lines));print(json.dumps({k:v['logs'] for k,v in metrics.items()}));print('report',reportpath,'zip',out,out.stat().st_size)
