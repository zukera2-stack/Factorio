local C=script.test_arg or '201'
local N=tonumber(C:match('%d+')) or 4
local DUAL=C:find('dual')~=nil
local ZERO=C:find('zero')~=nil
local HIGH=C:find('power')~=nil
local NOPATH=C:find('nopath')~=nil
local VANILLA=C=='vanilla'
local LOCOLESS=C=='standalone'
local PASSIVE=C=='passive'
local MIXED=C=='mixed'
local function ck(x,m) if not x then error('[EXT FAIL] '..C..' '..m) end end
local function say(m) log('[EXT] '..C..' '..m) end
local function create(s,name,x,y,dir)
 local e=s.create_entity{name=name,position={x=x,y=y},direction=dir or defines.direction.west,force='player',raise_built=true}
 ck(e and e.valid,'create '..name..' '..x..','..y);return e
end
local function helper(e) return e.name:match('^em%-c5%-technical%-booster%-%d+$')~=nil end
local function j(e) return e.valid and e.burner and (e.burner.remaining_burning_fuel or 0) or 0 end
local function allhelpers(s) local a={} for _,e in pairs(s.find_entities_filtered{type='locomotive'}) do if helper(e) then a[#a+1]=e end end return a end
local function expected(n,dirs)
 local a={};for _=1,dirs do for i=1,math.floor(n/200) do a[#a+1]=100000 end;if n%200>0 then a[#a+1]=500*(n%200) end end;table.sort(a);return a
end
local function check(st,n,dirs,moving)
 local tr=st.loco.train;ck(tr and tr.valid,'train invalid')
 local ex=expected(n,dirs);local a={};local hj=0;local owners={}
 local seen={};local ids={};local reals=0
 for _,e in ipairs(tr.carriages) do
  seen[e.unit_number]=true
  if helper(e) then
   a[#a+1]=tonumber(e.name:match('(%d+)$'));hj=hj+j(e);ids[#ids+1]=e.unit_number
   ck(not e.operable and not e.minable_flag and not e.destructible,'helper visible interaction')
   local id=remote.call('em072_native_qa_071','snapshot',e.unit_number).owner
   ck(id and (id==st.loco.unit_number or (st.second and st.second.valid and id==st.second.unit_number)),'wrong owner')
   owners[id]=(owners[id] or 0)+1
  elseif e.name=='em-electric-locomotive' then reals=reals+1 end
 end
 table.sort(a);ck(#a==#ex,'count '..#a..' expected '..#ex)
 for i,v in ipairs(ex) do ck(a[i]==v,'block '..i..' '..a[i]..' expected '..v) end
 if n>0 and dirs>0 then local no=0;for _,count in pairs(owners) do no=no+1;ck(count==math.ceil(n/200),'per-owner block count') end;ck(no==dirs,'direction owner count') end
 for _,w in ipairs(st.wagons) do ck(w.valid and seen[w.unit_number],'wagon detached') end
 if st.cargo then ck(st.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count('iron-plate')==37,'cargo lost') end
 if st.fluid then ck(math.abs(st.fluid.get_fluid_count('water')-9000)<0.01,'fluid lost') end
 if ZERO then ck(hj<0.01 and j(st.loco)<0.01,'unpaid fuel') end
 if not moving then ck(tr.speed==0,'unexpected motion') end
 say('CHECK n='..n..' dirs='..dirs..' blocks='..table.concat(a,',')..' helpers_J='..hj..' loco_J='..j(st.loco)..' cars='..#tr.carriages)
 return ids
end
local function proto_check()
 local count=0
 for i=1,256 do
  local p=prototypes.entity['em-c5-technical-booster-'..(500*i)]
  ck(p and p.type=='locomotive','prototype missing '..i);ck(p.hidden,'not hidden '..i)
  ck(p.alert_icon_scale==0,'alert icon '..i);ck(p.burner_prototype and p.burner_prototype.render_no_power_icon==false,'no fuel icon '..i);ck(p.has_flag('not-blueprintable') and p.has_flag('not-on-map') and p.has_flag('hide-alt-info'),'visibility flags '..i);count=count+1
 end
 say('PASS prototypes '..count);script.finish_test(true)
end
script.on_init(function()
 if C=='prototypes' then return end
 local xmax=math.max(500,7*(N+3)+280);local xmin=-340
 local s=game.create_surface('extended-'..C,{width=math.ceil((2*xmax+800)/32)*32,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=xmin,xmax,128 do s.request_to_generate_chunks({x=x,y=0},2) end;s.force_generate_chunk_requests()
 for x=xmin,xmax,2 do create(s,'em-high-speed-straight-rail',x,1,defines.direction.east) end
 if not ZERO then for x=-301.5,xmax-4,20 do create(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east) end end
 local genx=HIGH and -260 or -20;local supply=HIGH and 220000000 or 20000000
 local subs={}
 if HIGH then for i=0,10 do subs[#subs+1]=create(s,'em-35kv-traction-substation',-260+20*i,9,defines.direction.east) end;for i=0,9 do create(s,'big-electric-pole',-250+20*i,9,defines.direction.east) end
 else subs[1]=create(s,'em-35kv-traction-substation',-20,9,defines.direction.east) end
 local gen=create(s,'electric-energy-interface',genx,13,defines.direction.east);gen.electric_interface_mode=defines.electric_interface_mode.primary_output;gen.electric_buffer_size=10000000;gen.power_production=supply/60;gen.power_usage=0;gen.output_flow_limit=supply/60;gen.input_flow_limit=0;gen.energy=0
 local loco=create(s,VANILLA and 'locomotive' or 'em-electric-locomotive',0,1,defines.direction.west)
 local wagons={};local nm=0
 for i=1,N do
  local motor=not PASSIVE and (not MIXED or i%2==1)
  local name=(motor and 'em-motor-' or '')..(i%2==0 and 'fluid-wagon' or 'cargo-wagon')
  wagons[i]=create(s,name,i*7,1,defines.direction.west);if motor then nm=nm+1 end
 end
 local cargo=wagons[1];local fluid=wagons[2]
 if cargo then ck(cargo.get_inventory(defines.inventory.cargo_wagon).insert{name='iron-plate',count=37}==37,'cargo fill') end
 if fluid then ck(fluid.insert_fluid{name='water',amount=9000}==9000,'water fill') end
 local second=DUAL and create(s,'em-electric-locomotive',(N+1)*7,1,defines.direction.east) or nil
 ck(#loco.train.carriages==N+1+(DUAL and 1 or 0),'initial coupling')
 if LOCOLESS then loco.destroy{raise_destroy=true};loco=wagons[1] end
 storage.qa={loco=loco,second=second,wagons=wagons,nm=nm,dirs=(VANILLA or LOCOLESS) and 0 or DUAL and 2 or 1,cargo=cargo,fluid=fluid,s=s,subs=subs,gen=gen,start_x=loco.position.x,peak=0}
 if HIGH then
  local stop
  for _,dy in ipairs({-2,2,0}) do for _,dir in ipairs({defines.direction.west,defines.direction.east}) do
   local a=s.create_entity{name='train-stop',position={x=-160,y=1+dy},direction=dir,force='player',raise_built=true}
   if a and a.valid and a.connected_rail then stop=a;break end;if a and a.valid then a.destroy() end
  end;if stop then break end end
  ck(stop,'stop');stop.backer_name='EXT_STOP';loco.train.schedule={current=1,records={{station='EXT_STOP',wait_conditions={{type='time',compare_type='and',ticks=60}}}}};loco.train.manual_mode=false
 end
end)
script.on_event(defines.events.on_tick,function(e)
 local t=e.tick;if C=='prototypes' then proto_check();return end
 local st=storage.qa
 if NOPATH and t==20 then st.loco.train.schedule={current=1,records={{station='EXT-NO-SUCH-STATION',wait_conditions={{type='time',compare_type='and',ticks=60}}}}};st.loco.train.manual_mode=false end
 if NOPATH and t==120 then ck(st.loco.train.state==defines.train_state.no_path,'native no_path missing');for _,h in ipairs(st.loco.train.carriages) do if helper(h) then ck(h.prototype.alert_icon_scale==0 and h.prototype.burner_prototype.render_no_power_icon==false,'hidden alert flags') elseif h.name=='em-electric-locomotive' then ck(h.prototype.alert_icon_scale>0,'real alert suppressed') end end;check(st,st.nm,st.dirs,false);say('PASS native no_path');script.finish_test(true);return end
 if HIGH then local surf=game.surfaces['em-25kv-isolated-bridge-058'];if surf then for _,h in pairs(surf.find_entities_filtered{name='em-25kv-native-traction-consumer-068'}) do st.peak=math.max(st.peak,(h.input_flow_limit or 0)*60) end end end
 if C=='split' then
  if t==120 then
   local ids=check(st,st.nm,st.dirs,false);st.old=ids[1];local h=game.get_entity_by_unit_number(st.old)
   st.loss=j(h);ck(st.loss>0,'no paid J before split');local other=h.get_connected_rolling_stock(defines.rail_direction.back);ck(other,'no connected stock');ck(h.disconnect_rolling_stock(defines.rail_direction.back),'disconnect refused')
  elseif t==140 then
   ck(not game.get_entity_by_unit_number(st.old),'old helper persists');local q=remote.call('em072_native_qa_071','snapshot');ck(q.lost_J>=st.loss-0.1,'loss not recorded');ck(st.loco.valid,'owner lost')
   -- Find visible stock on other train and connect using native API.
   for _,dir in ipairs({defines.rail_direction.front,defines.rail_direction.back}) do if st.loco.connect_rolling_stock(dir) then break end end
   ck(st.loco.train.id==st.wagons[1].train.id,'visible recouple failed')
  elseif t==180 then local ids=check(st,st.nm,1,false);ck(ids[1]~=st.old,'old helper ID reused');say('PASS split/rejoin');script.finish_test(true) end
  return
 end
 if C=='ownerlossdual' then
  if t==120 then check(st,st.nm,2,false);st.loco.destroy{raise_destroy=true};st.loco=st.second;st.second=nil
  elseif t==180 then check(st,st.nm,1,false);ck(#allhelpers(st.s)==1,'orphan after head deletion');say('PASS one surviving head');script.finish_test(true) end;return
 end
 if HIGH and t==300 then check(st,st.nm,st.dirs,true);ck(st.peak>120000000,'peak native request <=120 MW '..st.peak);ck(math.abs(st.loco.position.x-st.start_x)>0.01,'did not move');say('PASS peak_W='..st.peak..' distance='..math.abs(st.loco.position.x-st.start_x));script.finish_test(true);return end
 if not HIGH and t==120 then check(st,st.nm,st.dirs,false);if VANILLA or LOCOLESS then ck(#allhelpers(st.s)==0,'ownerless helper') end;say('PASS');script.finish_test(true) end
end)
