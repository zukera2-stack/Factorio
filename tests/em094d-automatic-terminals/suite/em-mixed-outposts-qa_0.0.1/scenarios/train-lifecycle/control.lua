local function ck(x,m)if not x then error('[LIFECYCLE FAIL] '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function snap()return remote.call('em094_line_terminal','snapshot')end
local function count(s)
 local lab=game.surfaces['em094-terminal-lab'];return lab and #lab.find_entities_filtered{type='electric-energy-interface'} or 0
end
script.on_init(function()
 local s=game.create_surface('lifecycle',{width=512,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-160,160,64 do s.request_to_generate_chunks({x,0},2)end;s.force_generate_chunk_requests()
 local st={s=s,locos={}}
 for i=1,2 do local y=i*40-59
  for x=-143,143,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})end
  for x=-141.5,139,20 do make(s,'em-35kv-catenary-pole',x,y+1.5)end
  st.locos[i]=make(s,'em-electric-locomotive',41,y,{direction=defines.direction.west})
 end
 storage.st=st
end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  local q=snap();ck(q.ports==2 and q.valid==2 and count()==4,'create two automatic ports');local port
  for _,row in pairs(q.rows)do local a=game.get_entity_by_unit_number(row.anchor);if a.position.y<0 then port=game.get_entity_by_unit_number(row.port)end end
  ck(port,'port');st.pos=port.position;ck(st.locos[1].destroy{raise_destroy=true},'remove loco')
 elseif t==245 then
  local q=snap();ck(q.ports==1 and q.valid==1 and q.retired==1 and count()==2,'retirement');ck(q.retired_sink_J==0,'unexpected loss');st.locos[1]=make(st.s,'em-electric-locomotive',41,-19,{direction=defines.direction.west})
 elseif t==260 then
  local q=snap();ck(q.ports==2 and q.valid==2 and count()==4,'recreate');local mast
  for id,row in pairs(q.rows)do local a=game.get_entity_by_unit_number(row.anchor);if a.position.y<0 then local p=game.get_entity_by_unit_number(row.port);ck(p.position.x==st.pos.x and p.position.y==st.pos.y,'slot not reused');mast=game.get_entity_by_unit_number(id) end end
  ck(mast and mast.destroy{raise_destroy=true},'remove anchor mast')
 elseif t==265 then
  local q=snap();ck(q.ports<=2 and q.valid==q.ports and q.retired>=2,'invalid terminal persisted');ck(q.retired_sink_J==0 and q.unobserved==0,'unexplained loss');
 elseif t==300 then
  for _,l in ipairs(st.locos)do if l.valid then ck(l.destroy{raise_destroy=true},'delete loco')end end
 elseif t==425 then
  local q=snap();ck(q.ports==0 and count()==0,'orphan interface');ck(q.retired>=3 and q.retired_sink_J==0 and q.unobserved==0,'retire ledger');log('[LIFECYCLE PASS] retired='..q.retired..' loss='..q.retired_sink_J);script.finish_test(true)
 end
end)
