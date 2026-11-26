from pathlib import Path
import zipfile,shutil,json
p=Path(__file__).parent;base=Path('/mnt/data/em087h/candidate/mods/ElectrifiedMainline_0.1.94.zip');src=p/'src/ElectrifiedMainline_0.1.94'
with zipfile.ZipFile(base) as z:z.extractall(p/'src')
def edit(n,a,b):
 f=src/n;s=f.read_text();assert s.count(a)==1,(n,s.count(a));f.write_text(s.replace(a,b))
edit('info.json','"version": "0.1.94"','"version": "0.1.95"')
edit('scripts/mast_network_059.lua','''         for _,l in pairs(pc.real_connections) do
           if l.target and l.target.valid and not(ac and l.target.owner==a and l.origin==origin) then bad[#bad+1]=l end
         end''','''         -- Exact native singleton proof; any other shape retains the full audit.
         if not (ac and pc.real_connection_count==1 and pc.is_connected_to(ac,origin)) then
           for _,l in pairs(pc.real_connections) do
             if l.target and l.target.valid and not(ac and l.target.owner==a and l.origin==origin) then bad[#bad+1]=l end
           end
         end''')
edit('scripts/power_bridge_058.lua',''' for _,aid in pairs(t.helpers) do
   local a=lookup(aid)
   if valid(a) then
     local raw=a.electric_network_id
     if raw then corridor[observe(a,raw) or raw]=true end
   end
 end
 local safe,shorted={},{}''',''' -- No transfer candidates means no interface can be credited below.
 -- The complete live isolation scan remains mandatory for every nonempty batch.
 -- observe() only updates phase-local tables here, after dispatch and logging.
 if #candidates>0 then
   for _,aid in pairs(t.helpers) do
     local a=lookup(aid)
     if valid(a) then
       local raw=a.electric_network_id
       if raw then corridor[observe(a,raw) or raw]=true end
     end
   end
 end
 local safe,shorted={},{}''')
old=Path('/mnt/data/em087c')
for tag,v in [('base','0.1.94'),('codeonly','0.1.94'),('candidate','0.1.95')]:
 w=p/tag;m=w/'mods';m.mkdir(parents=True,exist_ok=True);name='ElectrifiedMainline_'+v
 if tag=='base':shutil.copy2(base,m/(name+'.zip'))
 else:
  with zipfile.ZipFile(m/(name+'.zip'),'w',zipfile.ZIP_DEFLATED) as z,zipfile.ZipFile(base) as b:
   for f in sorted(src.rglob('*')):
    if f.is_file():
     rel=str(f.relative_to(src));z.writestr(name+'/'+rel,b.read('ElectrifiedMainline_0.1.94/'+rel) if tag=='codeonly' and rel=='info.json' else f.read_bytes())
 shutil.copytree(old/'evidence/qa_mods/em-audit-qa_0.0.1',m/'em-audit-qa_0.0.1',dirs_exist_ok=True);shutil.copy2(old/'evidence/benchmark_mod-list.json',m/'mod-list.json')
 (w/'config.ini').write_text(f'[path]\nread-data={old}/factorio/data\nwrite-data={w}\n')
