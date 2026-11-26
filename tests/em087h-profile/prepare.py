from pathlib import Path
import zipfile,shutil
p=Path(__file__).parent
base=Path('/mnt/data/em087f/candidate/mods/ElectrifiedMainline_0.1.92.zip')
with zipfile.ZipFile(base) as z:z.extractall(p/'base_src')
src=p/'src/ElectrifiedMainline_0.1.92';shutil.copytree(p/'base_src/ElectrifiedMainline_0.1.92',src)
def edit(name,a,b):
 f=src/name;s=f.read_text();assert s.count(a)==1,(name,s.count(a));f.write_text(s.replace(a,b))
edit('info.json','"version": "0.1.92"','"version": "0.1.94"')
edit('scripts/power_bridge_058.lua',''' local n=0
 for _,link in pairs(a.real_connections) do
   if not (link.target and link.target.valid and link.target==b and link.origin==defines.wire_origin.script) then return false end
   n=n+1
 end
 return n==1''',''' -- Native count + native origin-aware connectivity; both connectors belong
 -- to live physical entities. No materialized WireConnection array needed.
 return a.real_connection_count==1 and a.is_connected_to(b,defines.wire_origin.script)''')
edit('scripts/bridge_dispatch_059.lua',''' if not(sub and sub.valid and sub.parent_network and sub.parent_network.valid) then return nil end
 local parent=sub.parent_network''',''' if not (sub and sub.valid) then return nil end
 local parent=sub.parent_network
 if not (parent and parent.valid) then return nil end''')
