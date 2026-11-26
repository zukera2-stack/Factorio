from pathlib import Path
import zipfile,shutil,json
p=Path(__file__).parent;old=Path('/mnt/data/em087i');base=old/'candidate/mods/ElectrifiedMainline_0.1.95.zip';src=p/'src/ElectrifiedMainline_0.1.95'
with zipfile.ZipFile(base) as z:z.extractall(p/'src')
f=src/'scripts/power_019.lua';s=f.read_text();a='''    if from==nil or to==nil then return nil end
    if (c.left_external and from<=max_walk) or (c.right_external and c.last-from<=max_walk) then return nil end
    local length=math.abs(from-to)''';b='''    if from==nil then return nil end
    if (c.left_external and from<=max_walk) or (c.right_external and c.last-from<=max_walk) then return nil end
    -- Certified cardinal segment, no reachable external HSR continuation.
    -- Every admissible bounded walk stays on this chain. An absent target
    -- (e.g. a parallel disconnected line) cannot be reached. False is a
    -- proven negative, nil means unknown and invokes the exact walker.
    if to==nil then return false end
    local length=math.abs(from-to)
    if length>max_walk then return false end''';assert s.count(a)==1;s=s.replace(a,b);a='    if direct then return direct end';assert s.count(a)==1;s=s.replace(a,'    if direct==false then return nil end\n    if direct then return direct end');f.write_text(s)
f=src/'info.json';s=f.read_text();assert s.count('"version": "0.1.95"')==1;f.write_text(s.replace('"version": "0.1.95"','"version": "0.1.96"'))
eng=Path('/mnt/data/em087c/factorio')
for tag,v in [('base','0.1.95'),('codeonly','0.1.95'),('candidate','0.1.96')]:
 w=p/tag;m=w/'mods';m.mkdir(parents=True,exist_ok=True);name='ElectrifiedMainline_'+v
 if tag=='base':shutil.copy2(base,m/(name+'.zip'))
 else:
  with zipfile.ZipFile(m/(name+'.zip'),'w',zipfile.ZIP_DEFLATED) as z,zipfile.ZipFile(base) as b:
   for f in sorted(src.rglob('*')):
    if f.is_file():
     rel=str(f.relative_to(src));z.writestr(name+'/'+rel,b.read('ElectrifiedMainline_0.1.95/'+rel) if tag=='codeonly' and rel=='info.json' else f.read_bytes())
 shutil.copytree(old/'candidate/mods/em-audit-qa_0.0.1',m/'em-audit-qa_0.0.1',dirs_exist_ok=True);shutil.copy2(old/'candidate/mods/mod-list.json',m/'mod-list.json');(w/'config.ini').write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
