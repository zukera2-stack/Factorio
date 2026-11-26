from pathlib import Path
import zipfile,shutil,json
p=Path(__file__).parent;src=p/'src/ElectrifiedMainline_0.1.92';old=Path('/mnt/data/em087c');base=Path('/mnt/data/em087f/candidate/mods/ElectrifiedMainline_0.1.92.zip')
for tag,v in [('base','0.1.92'),('codeonly','0.1.92'),('candidate','0.1.94')]:
 w=p/tag;m=w/'mods';m.mkdir(parents=True,exist_ok=True);name='ElectrifiedMainline_'+v
 if tag=='base':shutil.copy2(base,m/(name+'.zip'))
 else:
  with zipfile.ZipFile(m/(name+'.zip'),'w',zipfile.ZIP_DEFLATED) as z,zipfile.ZipFile(base) as b:
   for f in sorted(src.rglob('*')):
    if f.is_file():
     rel=str(f.relative_to(src));z.writestr(name+'/'+rel,b.read('ElectrifiedMainline_0.1.92/'+rel) if tag=='codeonly' and rel=='info.json' else f.read_bytes())
 shutil.copytree(old/'evidence/qa_mods/em-audit-qa_0.0.1',m/'em-audit-qa_0.0.1',dirs_exist_ok=True);shutil.copy2(old/'evidence/benchmark_mod-list.json',m/'mod-list.json')
 (w/'config.ini').write_text(f'[path]\nread-data={old}/factorio/data\nwrite-data={w}\n')
