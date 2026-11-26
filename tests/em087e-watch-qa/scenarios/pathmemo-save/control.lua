local H='em-high-speed-straight-rail';local M='em-35kv-catenary-pole';local N=60
local function ck(v,m) if not v then error('[EM087G FAIL] '..m) end end
local function mk(s,name,x,y,raised)
 local r=s.create_entity{name=name,position={x=x,y=y},force='player',direction=defines.direction.east,auto_connect=false,raise_built=raised}
 ck(r and r.valid,'create '..name..' at '..x..','..y);return r
end
local function check(st,cut1,cut2)
 local nets={};for i,m in ipairs(st.masts) do nets[i]=m.electric_network_id;ck(nets[i],'no native net '..i) end
 for i=1,N-1 do ck((nets[i]~=nets[i+1])==(i==cut1 or i==cut2),'wrong split at '..i..' tick '..game.tick) end
end
script.on_init(function()
 local s=game.create_surface('em087g-long',{width=2048,height=128});s.generate_with_lab_tiles=true
 for x=-650,650,96 do s.request_to_generate_chunks({x,0},2) end
 s.force_generate_chunk_requests();local st={s=s,masts={},rails={}}
 for x=-643,643,2 do st.rails[x]=mk(s,H,x,1,true) end
 for i=1,N do st.masts[i]=mk(s,M,-601.5+20*(i-1),2.5,true) end
 storage.qa=st
end)
local function cut(st,i) local x=-601+20*(i-1)+10;ck(st.rails[x].destroy{raise_destroy=false},'silent cut '..i) end
local function repair(st,i,raised) local x=-601+20*(i-1)+10;st.rails[x]=mk(st.s,H,x,1,raised) end
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa;local t=e.tick
 if t==120 then check(st)
 elseif t==200 then cut(st,15)
 elseif t==203 then check(st,15)
 elseif t==240 then cut(st,45)
 elseif t==243 then check(st,15,45)
 elseif t==250 and not script.test_arg then game.server_save('em087g-pathmemo-checkpoint')
 elseif t==260 then check(st,15,45)
 elseif t==280 then repair(st,45,true)
 elseif t==283 then check(st,15)
 elseif t==320 then repair(st,15,true)
 elseif t==323 then check(st)
 elseif t==360 then cut(st,15)
 elseif t==363 then check(st,15)
 elseif t==400 then repair(st,15,false)
 elseif t==601 then check(st);log('[EM087G PASS] two distant breaks, positive and negative path invalidation, silent creation audit, all 60 native mast IDs checked');script.finish_test(true) end
end)
