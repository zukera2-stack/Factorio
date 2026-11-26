from pathlib import Path
import zipfile,shutil,json
p=Path(__file__).parent;src=p/'base_src/ElectrifiedMainline_0.1.96';target=p/'src/ElectrifiedMainline_0.1.97';shutil.copytree(src,target,dirs_exist_ok=True)
def edit(name,changes):
 f=target/'scripts'/name;s=f.read_text()
 for a,b in changes:
  assert s.count(a)==1,(name,a,s.count(a));s=s.replace(a,b)
 f.write_text(s)
edit('catenary_art_030.lua', [('''        local i=math.min(row.contact_pieces,math.floor(t*row.contact_pieces)+1)
        local obj=rendering.get_object_by_id(row.ids[i])
        if ds<=best2 and obj and obj.valid and obj.visible~=false then
          best2=ds;best={x=q.x,y=q.y,distance=math.sqrt(ds),key=key}
        end''','''        if ds<=best2 then
          local i=math.min(row.contact_pieces,math.floor(t*row.contact_pieces)+1)
          local obj=rendering.get_object_by_id(row.ids[i])
          if obj and obj.valid and obj.visible~=false then
            best2=ds;best={x=q.x,y=q.y,distance=math.sqrt(ds),key=key}
          end
        end''')])
edit('traction_paid_065.lua', [('''  local contact=art.contact_at(e.surface.index,e.force.name,
    {x=e.position.x+h.x,y=e.position.y+h.y})''','''  local surface=e.surface.index
  local force=e.force
  local pos=e.position
  local contact=art.contact_at(surface,force.name,
    {x=pos.x+h.x,y=pos.y+h.y})'''),('''  if not (aa and ab and aa.surface.index==e.surface.index
    and ab.surface.index==e.surface.index and aa.force==e.force
    and ab.force==e.force and aa.electric_network_id
    and aa.electric_network_id==ab.electric_network_id) then
    return nil,"native-25kv-network-unverified"
  end
  return aa.electric_network_id,nil,aa''','''  if not (aa and ab and aa.surface.index==surface
    and ab.surface.index==surface and aa.force==force
    and ab.force==force) then
    return nil,"native-25kv-network-unverified"
  end
  local net=aa.electric_network_id
  if not net or net~=ab.electric_network_id then
    return nil,"native-25kv-network-unverified"
  end
  return net,nil,aa''')])
edit('pantograph_visual_049.lua',[('''                    local sprite=string.format("em-panto-052-%s-%03d",state,frame)
                    local r=render_object(row)''','''                    local r=render_object(row)'''),('''                        r=rendering.draw_sprite{sprite=sprite,surface=e.surface,''','''                        r=rendering.draw_sprite{sprite=string.format("em-panto-052-%s-%03d",state,frame),surface=e.surface,'''),('''                            r.sprite=sprite''','''                            r.sprite=string.format("em-panto-052-%s-%03d",state,frame)''')])
# Reuse an isolation scan only after port repair, and only within a synchronous call.
edit('power_bridge_058.lua',[(''' local idle_corridor
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
 end''',''' local live_corridor
 local function corridor_keys()
   if not live_corridor then
     live_corridor={}
     for _,aid in pairs(t.helpers) do
       local a=lookup(aid)
       if valid(a) then
         local raw=a.electric_network_id
         if raw then live_corridor[observe(a,raw) or raw]=true end
       end
     end
   end
   return live_corridor
 end
 local function idle_isolated(factory_key,line_key)
   if not factory_key or factory_key==line_key then return false end
   return not corridor_keys()[factory_key]
 end'''),(''' local corridor={}
 -- No transfer candidates means no interface can be credited below.
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
 end''',''' -- Port repairs have finished; idle_or_drain only changes EEI buffers/flows
 -- or retires empty EEIs. No pole or wire is edited between these checks.
 -- Retain live isolation for every nonempty batch, using the same native
 -- corridor set if a drain already required it in this synchronous phase.
 local corridor=#candidates>0 and corridor_keys() or {}''')])
info=json.loads((target/'info.json').read_text());info['version']='0.1.97';(target/'info.json').write_text(json.dumps(info,indent=2,ensure_ascii=False)+'\n')
eng=Path('/mnt/data/em087c/factorio');base=Path('/mnt/data/em087j/candidate/mods/ElectrifiedMainline_0.1.96.zip');qa=Path('/mnt/data/em087j/candidate/mods')
for tag,version in [('base','0.1.96'),('codeonly','0.1.96'),('candidate','0.1.97')]:
 w=p/tag;m=w/'mods';m.mkdir(parents=True,exist_ok=True);(w/'config.ini').write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
 for q in qa.iterdir():
  if q.is_dir():shutil.copytree(q,m/q.name,dirs_exist_ok=True)
  elif q.name=='mod-list.json':shutil.copy2(q,m/q.name)
 if tag=='base':shutil.copy2(base,m/base.name);continue
 with zipfile.ZipFile(m/f'ElectrifiedMainline_{version}.zip','w',zipfile.ZIP_DEFLATED) as z:
  for f in sorted(target.rglob('*')):
   if f.is_file():
    rel=f.relative_to(target);b=(src/'info.json').read_bytes() if tag=='codeonly' and rel.as_posix()=='info.json' else f.read_bytes();z.writestr(f'ElectrifiedMainline_{version}/{rel}',b)
