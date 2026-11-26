from pathlib import Path
import zipfile,shutil
p=Path(__file__).parent; src=p/'src/ElectrifiedMainline_0.1.95';f=src/'scripts/power_bridge_058.lua';s=f.read_text()
def edit(a,b):
 global s
 assert s.count(a)==1,(a,s.count(a));s=s.replace(a,b)
edit('local function idle_or_drain(r,raw_flows,route_open)','local function idle_or_drain(r,raw_flows,route_open,is_isolated,factory_key,line_key)')
edit('   -- Stop new imports; old J can leave ONLY when a peer is connected.','''   -- A native peer alone is not isolation proof. Stored joules must remain
   -- frozen if this factory shares any physical corridor parent network.
   if not is_isolated(factory_key,line_key) then reject(r,"factory-corridor-short");return end
   -- Stop new imports; old J can leave ONLY when a peer is connected.''')
edit(' for _,edge in ipairs(auto_edges) do\n   local r=s.stations[edge.id]',''' -- Only build this synchronous native-network set for an actual drain.
 -- No permission survives a tick; normal candidate isolation below remains.
 local idle_corridor
 local function idle_isolated(factory_key,line_key)
   if not factory_key or factory_key==line_key then return false end
   if not idle_corridor then
     idle_corridor={}
     for _,aid in pairs(t.helpers) do
       local a=lookup(aid)
       if valid(a) then
         local raw=a.electric_network_id
         if raw then idle_corridor[observe(a,raw) or raw]=true end
       end
     end
   end
   return not idle_corridor[factory_key]
 end
 for _,edge in ipairs(auto_edges) do
   local r=s.stations[edge.id]''')
edit('else idle_or_drain(r,raw_flows,(connected_peers[edge.b] or 0)>1) end','else idle_or_drain(r,raw_flows,(connected_peers[edge.b] or 0)>1,idle_isolated,edge.a,edge.b) end')
f.write_text(s)
base=p/'base/mods/ElectrifiedMainline_0.1.95.zip'
for tag,v in [('codeonly','0.1.95'),('candidate','0.1.96')]:
 name='ElectrifiedMainline_'+v;zpath=p/tag/'mods'/(name+'.zip');shutil.copy2(zpath,p/('before-idle-'+tag+'.zip'))
 with zipfile.ZipFile(zpath,'w',zipfile.ZIP_DEFLATED) as z,zipfile.ZipFile(base) as b:
  for f in sorted(src.rglob('*')):
   if f.is_file():
    rel=str(f.relative_to(src));z.writestr(name+'/'+rel,b.read('ElectrifiedMainline_0.1.95/'+rel) if tag=='codeonly' and rel=='info.json' else f.read_bytes())
shutil.copy2(p/'candidate/mods/ElectrifiedMainline_0.1.96.zip',p/'idle/mods/ElectrifiedMainline_0.1.96.zip')
