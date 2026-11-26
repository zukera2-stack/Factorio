local H='em-high-speed-straight-rail';local M='em-35kv-catenary-pole';local A='em-25kv-technical-anchor-046'
local function ck(v,m) if not v then error('[EM087F FAIL] '..m) end end
local function mk(s,name,x,y,raised)
 local r=s.create_entity{name=name,position={x,y},force='player',direction=defines.direction.east,auto_connect=false,raise_built=raised}
 ck(r and r.valid,'create '..name..' at '..x..','..y);return r
end
local function cknet(g,same,label)
 local a,b=g.masts[1].electric_network_id,g.masts[3].electric_network_id
 ck(a and b and ((a==b)==same),label..' '..tostring(a)..'/'..tostring(b))
 return a,b
end
local function audit_others(st)
 for i=2,4 do local a,b=cknet(st.groups[i],true,'other corridor '..i);ck(a==st.ids[i] and b==a,'unaffected network ID changed '..i) end
end
script.on_init(function()
 local s=game.create_surface('em087f-local',{width=256,height=1024});s.generate_with_lab_tiles=true
 local st={s=s,groups={},ids={}}
 for i=1,4 do
  local y=(i-2)*160+1
  s.request_to_generate_chunks({0,y},2)
 end
 s.force_generate_chunk_requests()
 for i=1,4 do
  local y=(i-2)*160+1;local g={y=y,rails={},masts={}};st.groups[i]=g
  for x=-43,43,2 do g.rails[x]=mk(s,H,x,y,true) end
  for _,x in ipairs({-21.5,-1.5,18.5}) do g.masts[#g.masts+1]=mk(s,M,x,y+1.5,true) end
 end
 storage.qa=st
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa;local g=st.groups[1];local t=e.tick
 if t==120 then
  for i,v in ipairs(st.groups) do st.ids[i]=cknet(v,true,'initial '..i) end
  for i=1,4 do for j=i+1,4 do ck(st.ids[i]~=st.ids[j],'independent corridors shorted') end end
 elseif t==200 then ck(g.rails[-11].destroy{raise_destroy=false},'silent cut refused')
 elseif t==203 then cknet(g,false,'silent cut');audit_others(st);log('[EM087F] local split, other 3 unchanged')
 elseif t==240 then g.rails[-11]=mk(st.s,H,-11,g.y,true)
 elseif t==243 then cknet(g,true,'raised repair');audit_others(st);log('[EM087F] local repair, other 3 unchanged')
 elseif t==300 then
  ck(g.rails[-11].destroy{raise_destroy=false},'second cut refused')
  ck(st.groups[2].rails[-11].destroy{raise_destroy=false},'second group cut refused')
 elseif t==303 then
  cknet(g,false,'two cuts first');cknet(st.groups[2],false,'two cuts second');cknet(st.groups[3],true,'unaffected third');cknet(st.groups[4],true,'unaffected fourth')
 elseif t==340 then
  g.rails[-11]=mk(st.s,H,-11,g.y,false);st.groups[2].rails[-11]=mk(st.s,H,-11,st.groups[2].y,false)
 elseif t==601 then
  for i,v in ipairs(st.groups) do cknet(v,true,'full audit silent repair '..i) end
  log('[EM087F PASS] local 1/4 and 2/4 split/repair; independent native nets stable; full audit restores silent creation');script.finish_test(true)
 end
end)
