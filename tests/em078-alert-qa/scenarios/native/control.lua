local CASE=script.test_arg or '201'
local N=tonumber(CASE:match('%d+')) or 201
local DUAL=CASE:find('dual')~=nil
local ZERO=CASE:find('zero')~=nil
local function ck(ok,msg) if not ok then error('[EM078 QA FAIL] '..CASE..' '..msg) end end
local function spawn(s,name,x,y,d)
 local e=s.create_entity{name=name,position={x=x,y=y},force='player',direction=d or defines.direction.west,raise_built=true}
 ck(e and e.valid,'cannot create '..name..' at '..x)
 return e
end
script.on_init(function()
 ck(N>=1 and N<=800,'QA expects 1..800 motor wagons')
 local xmax=math.max(500,7*(N+(DUAL and 2 or 1))+280)
 local s=game.create_surface('em078-no-path-'..CASE,{width=math.ceil((xmax+650)/32)*32,height=256})
 s.generate_with_lab_tiles=true;s.always_day=true
 for x=-320,xmax,128 do s.request_to_generate_chunks({x=x,y=0},2) end
 s.force_generate_chunk_requests()
 for x=-340,xmax,2 do spawn(s,'em-high-speed-straight-rail',x,1,defines.direction.east) end
 if not ZERO then
  for x=-301.5,xmax-4,20 do spawn(s,'em-35kv-catenary-pole',x,2.5,defines.direction.east) end
 end
 spawn(s,'em-35kv-traction-substation',-20,9,defines.direction.east)
 spawn(s,'em-35kv-traction-substation',20,9,defines.direction.east)
 local gen=spawn(s,'electric-energy-interface',-20,13,defines.direction.east)
 local supply=ZERO and 0 or 20000000
 gen.electric_interface_mode=defines.electric_interface_mode.primary_output
 gen.electric_buffer_size=10000000;gen.power_production=supply/60
 gen.power_usage=0;gen.output_flow_limit=supply/60;gen.input_flow_limit=0;gen.energy=0
 local loco=spawn(s,'em-electric-locomotive',0,1,defines.direction.west)
 for i=1,N do
  spawn(s,i%2==0 and 'em-motor-fluid-wagon' or 'em-motor-cargo-wagon',i*7,1,defines.direction.west)
 end
 if DUAL then spawn(s,'em-electric-locomotive',(N+1)*7,1,defines.direction.east) end
 ck(#loco.train.carriages==N+1+(DUAL and 1 or 0),'initial train split')
 storage.qa={loco=loco}
 log('[EM078 QA] '..CASE..' SETUP motor_wagons='..N)
end)
script.on_event(defines.events.on_tick,function(event)
 if event.tick==20 then
  local t=storage.qa.loco.train
  ck(t and t.valid,'train missing before no-path')
  t.schedule={current=1,records={{station='EM078-NO-SUCH-STATION',wait_conditions={{type='time',compare_type='and',ticks=60}}}}}
  t.manual_mode=false
 end
 if event.tick==44 then
  local t=storage.qa.loco.train
  ck(t and t.valid and t.state==defines.train_state.no_path,'native train did not enter no_path')
  local hidden,visible=0,0
  for _,e in ipairs(t.carriages) do
   if e.name:match('^em%-c5%-technical%-booster%-%d+$') then
    hidden=hidden+1
    ck(e.prototype.alert_icon_scale==0,'hidden helper still has path alert scale')
    ck(e.prototype.burner_prototype.render_no_power_icon==false,'hidden helper fuel icon enabled')
   elseif e.name=='em-electric-locomotive' then
    visible=visible+1
    ck(e.prototype.alert_icon_scale>0,'real train warning unexpectedly hidden')
   end
  end
  ck(hidden==math.ceil(N/200)*(DUAL and 2 or 1),'incorrect mounted helper count '..hidden)
  ck(visible==(DUAL and 2 or 1),'real locomotives missing')
  log('[EM078 QA] '..CASE..'|NATIVE_NO_PATH|hidden='..hidden..'|real='..visible..'|PASS')
  script.finish_test(true)
 end
end)
