-- EM072-A5 B0: actual Factorio native rail and train motion, finite native grid reservoir.
-- Isolated lab only; no writing to production mod tree or user save.
local function make(surface,name,x,y,other)
 local opts={name=name,position={x,y},force="player",raise_built=true}
 for k,v in pairs(other or {}) do opts[k]=v end
 local e=surface.create_entity(opts)
 assert(e and e.valid,"cannot place "..name.." at "..x..","..y)
 return e
end
local function sum_state(p)
 local total=0
 for _,a in ipairs(p.cells) do assert(a.valid);total=total+a.energy end
 local b=remote.call("em072a5_b0_native","balances",p.sub.unit_number)
 total=total+(b.input or 0)+(b.output or 0)
 for _,loco in ipairs(p.locos) do total=total+loco.burner.remaining_burning_fuel end
 return total,b
end
local function setup()
 local s=game.create_surface("em072a5-native-overload",{width=1024,height=320})
 s.generate_with_lab_tiles=true
 s.request_to_generate_chunks({0,0},13);s.force_generate_chunk_requests()
 for x=-200,380,2 do make(s,"em-high-speed-straight-rail",x,1,{direction=defines.direction.east}) end
 local masts={}
 for x=-141.5,278.5,20 do
  masts[#masts+1]=make(s,"em-35kv-catenary-pole",x,2.5)
 end
 local sub=make(s,"em-35kv-traction-substation",-20,9)
 local cells={}
 for x=-56,24,4 do for _,y in ipairs({14,18,27,31}) do
  cells[#cells+1]=make(s,"accumulator",x,y)
 end end
 assert(#cells==84)
 local poles={}
 for x=-48,16,16 do poles[#poles+1]=make(s,"substation",x,23) end
 for _,a in ipairs(cells) do a.energy=5000000 end
 local locos,drivers,starts,ids={},{},{},{}
 for i=0,11 do
  local x=-128+i*32
  local loco=make(s,"em072a5-b0-burner-loco",x,1,{direction=defines.direction.east})
  locos[#locos+1]=loco;starts[#starts+1]=x;ids[#ids+1]=loco.unit_number
  local driver=make(s,"character",x,-8)
  drivers[#drivers+1]=driver
  loco.set_driver(driver)
  assert(loco.get_driver()==driver,"native driver missing")
  loco.train.manual_mode=true
  driver.riding_state={acceleration=defines.riding.acceleration.accelerating,direction=defines.riding.direction.straight}
 end
 assert(remote.call("em072a5_b0_native","register",ids),"native train registry rejected")
 storage.b0={surface=s,sub=sub,masts=masts,cells=cells,locos=locos,drivers=drivers,starts=starts,
  got={},spent={},previous={},peak=0,granted=0,total_tick=0,first_supply_tick=0,init_j=0}
 local p=storage.b0
 for i=1,12 do p.got[i]=0;p.spent[i]=0;p.previous[i]=0 end
 log("[EM072A5 B0 SETUP] 12 real native locomotive train objects, one EM070, 84 native accumulators (420MJ/25.2MW), 22 overhead masts")
end
script.on_event(defines.events.on_tick,function(event)
 local t=event.tick
 if t==1 then setup() end
 local p=storage.b0
 if not p then return end
 local distinct={}
 for i,loco in ipairs(p.locos) do
  assert(loco.valid and loco.train and loco.train.valid,"missing real native train: "..i)
  distinct[loco.train.id]=true
  local now=loco.burner.remaining_burning_fuel
  local consumption=math.max(0,p.previous[i]-now)
  p.spent[i]=p.spent[i]+consumption
  p.previous[i]=now
 end
 if t==35 then
  local count=0;for _ in pairs(distinct) do count=count+1 end
  assert(count==12,"not 12 different real native LuaTrain.ids: "..count)
  log("[EM072A5 B0 TRAINS PASS] count=12 distinct native LuaTrain.id")
 end
 if t==90 then
  local _,topology= sum_state(p)
  assert(topology.factory and topology.line and topology.factory~=topology.line,"EM070 physical isolation broken")
  local connected=0
  for _,a in ipairs(p.cells) do if a.electric_network_id==topology.factory then connected=connected+1 end end
  assert(connected==84,"not all finite factory accumulator sources are in same native network: "..connected)
  log("[EM072A5 B0 PHYSICAL SOURCE PASS] 84/84 native accumulators on factory network, separate corridor network")
  p.init_j=sum_state(p)
  assert(p.init_j>400000000 and p.init_j<425000000,"unexpected source energy in reservoir")
  log("[EM072A5 B0 START LEDGER] t=90 native_total_j="..p.init_j)
 end
 if t>=91 and t<=340 then
  local actual=remote.call("em072a5_b0_native","take_all",p.sub.unit_number)
  local total=0;local min_v=math.huge;local max_v=0;local funded=0
  for i,loco in ipairs(p.locos) do
   local j=actual[loco.unit_number] or 0
   if j>0 then funded=funded+1 end
   assert(j>=0 and j<=2000000/60+0.05,"train power above 2MW")
   total=total+j;min_v=math.min(min_v,j);max_v=math.max(max_v,j)
   p.got[i]=p.got[i]+j
   p.previous[i]=loco.burner.remaining_burning_fuel
  end
  assert(total<=20000000/60+0.05,"EM070 20 MW physical power limit broken: "..total)
  if total>0 then
   assert(funded==12,"allocated some but not all reachable equal trains: "..funded)
   assert(max_v-min_v<0.2,"max-min fairness broken within a native tick: "..(max_v-min_v))
   p.first_supply_tick=p.first_supply_tick==0 and t or p.first_supply_tick
   p.peak=math.max(p.peak,total);p.granted=p.granted+total;p.total_tick=p.total_tick+1
  end
 end
 if t%60==0 then
  local total,b=sum_state(p)
  local spent=0;for _,v in ipairs(p.spent) do spent=spent+v end
  local delta=t>=90 and p.init_j-total-spent or 0
  log(string.format("[EM072A5 B0 TRACE] t=%d planned=%.3fMW dir=%s status=%s line=%s factory=%s transfer=%.0f J spent=%.0f J residual=%.3f J funded_ticks=%d",t,b.planned or 0,tostring(b.direction),tostring(b.status),tostring(b.line),tostring(b.factory),p.granted,spent,delta,p.total_tick))
  if t>=120 then assert(math.abs(delta)<3000,"native energy balance violated: "..delta) end
 end
 if t==151 then
  local ok,err=pcall(function() game.server_save("em072a5-b0-checkpoint") end)
  log("[EM072A5 B0 DISK SAVE] t=151 requested="..tostring(ok).." err="..tostring(err))
 end
 if t==360 then
  local sum_got=0;local min_got=math.huge;local max_got=0;local min_move=math.huge;local sum_spent=0
  for i,loco in ipairs(p.locos) do
   sum_got=sum_got+p.got[i];min_got=math.min(min_got,p.got[i]);max_got=math.max(max_got,p.got[i])
   min_move=math.min(min_move,math.abs(loco.position.x-p.starts[i]));sum_spent=sum_spent+p.spent[i]
  end
  local total,b=sum_state(p)
  local deficit=p.init_j-total-sum_spent
  assert(p.total_tick>120,"not enough real power delivery ticks: "..p.total_tick)
  assert(sum_got>15000000,"native supply too low: "..sum_got)
  assert(min_got>0 and max_got-min_got<3,"unfair native joule split: "..(max_got-min_got))
  assert(min_move>0.05,"at least one locomotive did not move under paid power: "..min_move)
  assert(b.direction=="import" and b.mode=="auto","actual EM070 did not import in AUTO")
  assert(b.cache_builds>=1 and b.cache_builds<=2,"native physical HSR path cache was not used")
  assert(math.abs(deficit)<3000,"joule accounting exceeds error budget: "..deficit)
  log(string.format("[EM072A5 B0 NATIVE PASS] 12 moving trains actual_J=%.0f spent_J=%.0f min_train_J=%.3f max_train_J=%.3f peak_MW=%.6f 20MW_cap=true min_move_tiles=%.4f ledger_residual_J=%.6f funded_ticks=%d cache_builds=%d",sum_got,sum_spent,min_got,max_got,p.peak*60/1e6,min_move,deficit,p.total_tick,b.cache_builds))
 end
end)