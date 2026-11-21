-- Native Factorio + actual ElectrifiedMainline bridge. Research-only.
local function make(s,name,x,y,other)
 local p={name=name,position={x,y},force="player",raise_built=true}
 for k,v in pairs(other or {}) do p[k]=v end
 local e=s.create_entity(p)
 assert(e and e.valid,"create failed "..name.." at "..x..","..y)
 return e
end
local function setup()
 local s=game.create_surface("em072-a2-native-bridge",{width=512,height=256})
 s.generate_with_lab_tiles=true
 s.request_to_generate_chunks({0,0},5);s.force_generate_chunk_requests()
 for x=-120,120,2 do make(s,"em-high-speed-straight-rail",x,1,{direction=defines.direction.east}) end
 local mast={make(s,"em-35kv-catenary-pole",-21.5,2.5),make(s,"em-35kv-catenary-pole",-1.5,2.5),make(s,"em-35kv-catenary-pole",18.5,2.5)}
 local sub=make(s,"em-35kv-traction-substation",-20,9)
 local source={}
 for x=-28,-12,4 do
  local a=make(s,"accumulator",x,12)
  a.energy=5000000;source[#source+1]=a
 end
  for x=-120,120,2 do make(s,"em-high-speed-straight-rail",x,22,{direction=defines.direction.east}) end
 local rogueHSR=make(s,"em072-grid-burner-loco",-18,22,{direction=defines.direction.east})
  for x=-120,120,2 do make(s,"straight-rail",x,45,{direction=defines.direction.east}) end
 local rogue=make(s,"em072-grid-burner-loco",-18,45,{direction=defines.direction.east})
 local loco=make(s,"em072-grid-burner-loco",-18,1,{direction=defines.direction.east})
 local driver=make(s,"character",-18,-6)
 loco.set_driver(driver)
 assert(loco.get_driver()==driver,"driver not placed")
 loco.train.manual_mode=true
 driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 assert(remote.call("em072a2_native_probe","mode",sub.unit_number))
 assert(remote.call("em072a2_native_probe","register",loco.unit_number))
 storage.probe={s=s,sub=sub,mast=mast,source=source,loco=loco,rogue=rogue,rogueHSR=rogueHSR,last=0,spent=0,inject=0,init_energy=0,stopped=false,draw=0}
 log("[EM072A2 SETUP] source=25MJ native real accumulators, actual EM070 buffers + native 2MW locomotive")
end
local function total(p)
 local j=0
 for _,a in ipairs(p.source) do if a.valid then j=j+a.energy end end
  local balances=remote.call("em072a2_native_probe","balances",p.sub.unit_number)
 j=j+(balances.input or 0)+(balances.output or 0)
 j=j+(p.loco.valid and p.loco.burner.remaining_burning_fuel or 0)
 return j
end
local function setup_network_id(p)
 local a=p.mast[1]
 local b=remote.call("em072a2_native_probe","balances",p.sub.unit_number)
 return a.electric_network_id and b.line_network and b.output_network and a.electric_network_id==b.line_network and b.output_network==b.line_network
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick
 if t==1 then setup() end
 local p=storage.probe
 if not p then return end
 local b=p.loco.burner
 local before=b.remaining_burning_fuel or 0
 local delta=(p.last or 0)-before
 if delta>0 then p.spent=p.spent+delta end
 if not p.stopped and t>=390 then
  p.stopped=true
  p.inject_at_stop=p.inject
  log("[EM072A2 STOP] switch real EM070 substation to OFF at tick "..t)
  assert(remote.call("em072a2_native_probe","off",p.sub.unit_number))
 end
 local take=0
 if t>60 and t<390 and setup_network_id(p) then
  local max=2000000/60
  take=remote.call("em072a2_native_probe","take",p.sub.unit_number,p.loco.unit_number,max)
  if take>0 then p.inject=p.inject+take end
 end
 p.last=b.remaining_burning_fuel or 0
 if t==60 then p.init_energy=total(p) end
 if t%30==0 then
  local bb=remote.call("em072a2_native_probe","balances",p.sub.unit_number)
  log("[EM072A2 IDS] mast="..tostring(p.mast[1].electric_network_id).." sub="..tostring(p.sub.electric_network_id).." ports="..tostring(bb.input_network).."/"..tostring(bb.output_network).." status="..tostring(bb.status))
  log(string.format("[EM072A2 TRACE] t=%d line=%s source=%.1f consumed=%.1f meter=%.1f transferred=%.1f burner=%.1f spent=%.1f speed=%.6f total=%.1f ledger_delta=%.1f",t,tostring(setup_network_id(p)),(function() local j=0;for _,x in ipairs(p.source) do j=j+x.energy end;return j end)(),p.spent,remote.call("em072a2_native_probe","balances",p.sub.unit_number).output or 0,p.inject,b.remaining_burning_fuel,p.spent,p.loco.train.speed,total(p),p.init_energy-total(p)-p.spent))
 end
 if t==410 then
  local data=remote.call("em072a2_native_probe","balances",p.sub.unit_number)
  assert(data.mode=="off","station unexpectedly powered after manual OFF")
  assert(p.inject==p.inject_at_stop,"engine received energy after bridge OFF")
  local deficit=p.init_energy-total(p)-p.spent
  assert(math.abs(deficit)<100,"bridge OFF lost/doubled energy: "..deficit)
  log(string.format("[EM072A2 OFF PASS] tick=%d source+buffers+burner+spent=constant residual_J=%.6f",t,deficit))
 end
 if t==255 then
    local rails=p.s.find_entities_filtered{position={x=-10,y=1},radius=2.2,name="em-high-speed-straight-rail"}
    assert(#rails>=1,"missing HSR target cut rail")
    p.cut_at={x=rails[1].position.x,y=rails[1].position.y}
    rails[1].destroy{raise_destroy=true}
    p.before_cut=p.inject
    log("[EM072A3 CUT] removed physically connected HSR x=-10")
 end
 if t==265 then
   assert(not remote.call("em072a2_native_probe","qualifies",p.sub.unit_number,p.loco.unit_number),"HSR rail cut still returned eligible")
   assert(p.inject==p.before_cut,"traction delivered across broken HSR rail segment")
   log("[EM072A3 CUT PASS] physically severed HSR rail got no new Joules")
 end
 if t==280 then
   assert(p.cut_at,"cut position missing")
   make(p.s,"em-high-speed-straight-rail",p.cut_at.x,p.cut_at.y,{direction=defines.direction.east})
   log("[EM072A3 REJOIN] physically reconnected HSR rail")
 end
 if t==300 then
   assert(remote.call("em072a2_native_probe","qualifies",p.sub.unit_number,p.loco.unit_number),"HSR rail rejoin not detected")
   assert(p.inject>p.before_cut,"energy did not resume after HSR rejoin")
   log("[EM072A3 REJOIN PASS] reconnected HSR rail resumed physically debited traction")
 end
 if t==335 then
   p.zero_at=p.inject
   assert(remote.call("em072a2_native_probe","unregister"))
   log("[EM072A3 ZERO REQUEST] unregistered all traction demand")
 end
 if t==365 then
   assert(p.inject==p.zero_at,"native burner was credited despite zero train demand")
   log("[EM072A3 ZERO REQUEST PASS] zero traction demand -> zero new native burner joules")
 end
 if t==151 then
      local ok,err=pcall(function() game.server_save('em072a2-checkpoint') end)
      log('[EM072A2 DISK SAVE] t=151 requested='..tostring(ok)..' err='..tostring(err))
    end
 if t==210 then
  local unauthorized=remote.call("em072a2_native_probe","take",p.sub.unit_number,p.rogue.unit_number,2000000/60)
  assert(unauthorized==0,"unpowered vanilla rail locomotive stole EM070 energy")
  assert(p.rogue.burner.remaining_burning_fuel==0,"unpowered control received energy")
  local unauthorized_hsr=remote.call("em072a2_native_probe","take",p.sub.unit_number,p.rogueHSR.unit_number,2000000/60)
  assert(unauthorized_hsr==0,"disconnected parallel HSR track stole power")
  assert(not remote.call("em072a2_native_probe","qualifies",p.sub.unit_number,p.rogueHSR.unit_number),"disconnected HSR incorrectly eligible")
  log("[EM072A3 DISCONNECTED HSR PASS] adjacent parallel HSR same surface/force refused 0 J")
  log("[EM072A2 NO UNCONNECTED FEED PASS] parallel vanilla rail train received 0J")
 end
 if t==240 then
  assert(remote.call("em072a2_native_probe","qualifies",p.sub.unit_number,p.loco.unit_number),"powered HSR actual path failed before cut")
  assert(setup_network_id(p),"traction meter not on actual EM070 corridor")
  assert(p.inject>1000000,"no native corridor power reached native burner")
  assert(p.spent>1000000,"native burner did not spend physically supplied electricity")
  assert(p.loco.position.x>-10,"train failed to move under transferred energy")
  local deficit=p.init_energy-total(p)-p.spent
  assert(math.abs(deficit)<150000,"energy conservation failed: "..deficit)
  log(string.format("[EM072A2 NATIVE PASS] real EM070 power -> native sink -> LuaBurner J=%.0f consumed_J=%.0f energy_residual=%.3f",p.inject,p.spent,deficit))
 end
end)
