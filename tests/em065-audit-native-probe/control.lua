-- READ ONLY audit of actual EM065 0.1.65 game source.
-- No modifications to the original mod's prototypes/control/logic.
-- A low-energy shared native circuit makes charge allocation observable.
local SOURCE_W=1000000
local L=SOURCE_W/60
local function create(s,name,x,y,other)
  local arg={name=name,position={x=x,y=y},direction=defines.direction.east,force="player",raise_built=true}
  for k,v in pairs(other or {}) do arg[k]=v end
  local e=s.create_entity(arg)
  assert(e and e.valid,"AUDIT fixture cannot create "..name.." at "..x..","..y)
  return e
end
local function rails(s)
  for x=-35,65,2 do create(s,"em-high-speed-straight-rail",x,1) end
end
local function goal(s)
  for _,cfg in ipairs({
    {27,3,defines.direction.east},{27,-1,defines.direction.west},
    {29,3,defines.direction.east},{29,-1,defines.direction.west}
  }) do
    local e=s.create_entity{name="train-stop",position={x=cfg[1],y=cfg[2]},
      direction=cfg[3],force="player",raise_built=true}
    if e and e.valid and e.connected_rail then
      e.backer_name="EM065_AUDIT_OFFGRID_TARGET"
      return e
    end
    if e and e.valid then e.destroy() end
  end
  error("AUDIT cannot place actual native AUTO train-stop")
end
local function setup()
  local s=game.create_surface("em065-audit-shared-1mw",{width=256,height=128})
  s.generate_with_lab_tiles=true
  s.request_to_generate_chunks({0,0},2)
  s.force_generate_chunk_requests()
  rails(s)
  local masts={}
  for _,x in ipairs({-21.5,-1.5,18.5,38.5}) do
    masts[#masts+1]=create(s,"em-35kv-catenary-pole",x,2.5)
  end
  create(s,"em-35kv-traction-substation",-20,9)
  create(s,"em-35kv-traction-substation",20,9)
  local gen=create(s,"electric-energy-interface",-20,13)
  gen.electric_interface_mode=defines.electric_interface_mode.primary_output
  gen.electric_buffer_size=10000000
  gen.power_production=L
  gen.power_usage=0
  gen.input_flow_limit=0
  gen.output_flow_limit=L
  gen.energy=0
  local a=create(s,"em-electric-locomotive",0,1)
  local b=create(s,"em-electric-locomotive",12,1)
  assert(a.unit_number~=b.unit_number and a.train.id~=b.train.id,
    "AUDIT fixture must have TWO real independent native EM trains")
  assert(a.burner and b.burner and
    a.burner.remaining_burning_fuel==0 and b.burner.remaining_burning_fuel==0,
    "AUDIT two fullmod locomotives must start at exactly zero energy")
  local no=game.create_surface("em065-audit-offgrid-AUTO",{width=128,height=128})
  no.generate_with_lab_tiles=true
  no.request_to_generate_chunks({0,0},2)
  no.force_generate_chunk_requests()
  for x=-35,35,2 do create(no,"em-high-speed-straight-rail",x,1) end
  local neg=create(no,"em-electric-locomotive",0,1)
  goal(no)
  storage.audit={source=gen,a=a,b=b,neg=neg,neg_x=neg.position.x,
    mast=masts[2],
    charge60={},charge120={},charge240={},charge300={}}
  log("[AUDIT EM065 SETUP] two native 2MW locos on ONE verified 25kV circuit; native EEI source 1MW; unrelated offgrid EM locomotive will get AUTO destination")
end
local function snap(t)
  local f=storage.audit
  local ja,jb=f.a.burner.remaining_burning_fuel,f.b.burner.remaining_burning_fuel
  local n=f.neg.burner.remaining_burning_fuel
  local parent=f.source.electric_network and f.source.electric_network.parent_network
  local flow=parent and parent.flow_last_tick
  local produced=flow and flow.primary_output or -1
  local row={a=ja,b=jb,negative=n,produced=produced}
  f["charge"..t]=row
  -- Native grid stats, not the EM065 Lua dispatch's synthetic demand:
  -- this answers the owner's complaint that the 25kV electricity UI shows
  -- no consumer despite train motion. Never read other mod's private storage.
  local ln=f.mast and f.mast.valid and f.mast.electric_network
  local lpn=ln and ln.parent_network
  local lf=lpn and lpn.flow_last_tick
  local linePrimaryDemand=lf and lf.primary_demand or -1
  local lineSecondaryDemand=lf and lf.secondary_demand or -1
  local linePrimaryOutput=lf and lf.primary_output or -1
  local lineSecondaryOutput=lf and lf.secondary_output or -1
  log(string.format("[AUDIT EM065 25KV NATIVE FLOW] tick=%d mast_network=%s native_primary_demand_J_tick=%.3f native_secondary_demand_J_tick=%.3f native_primary_output_J_tick=%.3f native_secondary_output_J_tick=%.3f native_total_train_battery_J=%.3f",
    t,tostring(f.mast.electric_network_id),linePrimaryDemand,
    lineSecondaryDemand,linePrimaryOutput,lineSecondaryOutput,ja+jb))
  log(string.format("[AUDIT EM065 SHARED] tick=%d A_J=%.3f B_J=%.3f sum_J=%.3f negative_AUTO_J=%.3f source_last_primary_J_tick=%.3f A_train=%d B_train=%d",
    t,ja,jb,ja+jb,n,produced,f.a.train.id,f.b.train.id))
end
script.on_event(defines.events.on_tick,function(e)
  if e.tick==2 then setup() end
  if not storage.audit then return end
  local f=storage.audit
  if e.tick==60 then
    snap(60)
    f.neg.train.schedule={current=1,records={{station="EM065_AUDIT_OFFGRID_TARGET",
      wait_conditions={{type="time",ticks=500}}}}}
    f.neg.train.manual_mode=false
    log("[AUDIT EM065 NEGATIVE AUTO] tick=60|manual=false|real_station=EM065_AUDIT_OFFGRID_TARGET")
  end
  if e.tick==120 then snap(120) end
  if e.tick==240 then
    snap(240)
    assert(f.neg.burner.remaining_burning_fuel==0 and
      math.abs(f.neg.position.x-f.neg_x)<0.001,
      "AUDIT FAIL: real AUTO train without electrical contact moved or gained J")
    log("[AUDIT EM065 NO POWER AUTO PASS] true_native_auto_route=on|negative_J=0|distance_tiles=0")
  end
  if e.tick==300 then
    snap(300)
    local first=f.charge60
    local later=f.charge300
    local hasProof=later.a>100000 and later.b>100000
    local starved=(first.a>300000 and first.b<1000) or
      (first.b>300000 and first.a<1000)
    log("[AUDIT EM065 MULTITRAIN RESULT] both_eventually_contact="..tostring(hasProof)..
      "|first_min_J="..math.min(first.a,first.b)..
      "|first_max_J="..math.max(first.a,first.b)..
      "|starvation_under_one_MW="..tostring(starved)..
      "|last_A_J="..later.a.."|last_B_J="..later.b)
    if hasProof and starved then
      log("[AUDIT EM065 FAIRNESS DEFECT REPRODUCED] both trains charge later, but one received zero during shared shortage")
    elseif not hasProof then
      log("[AUDIT EM065 FAIRNESS INCONCLUSIVE] contact for both trains not proven by t300; cannot label fairness")
    else
      log("[AUDIT EM065 FAIRNESS NOT FAILED] no early complete starvation under this source constraint")
    end
  end
end)
