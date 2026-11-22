-- EM065 native proof: actual 20MW EM070 source, authenticated contact,
-- real 2MW EM burner. No artificial fuel, ever. Probe is NOT user mod source.
local LIMIT=20000000/60
local function entity(s,name,x,y,other)
  local opts={name=name,position={x=x,y=y},force=game.forces.player,
    raise_built=true,direction=defines.direction.east}
  for key,value in pairs(other or {}) do opts[key]=value end
  local e=s.create_entity(opts)
  assert(e and e.valid,"EM065 cannot create "..name.." x="..x.." y="..y)
  return e
end
local function setup()
  local s=game.create_surface("em065-paid-test",{width=256,height=128})
  s.generate_with_lab_tiles=true
  s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
  for x=-35,35,2 do entity(s,"em-high-speed-straight-rail",x,1) end
  entity(s,"em-35kv-catenary-pole",-21.5,2.5)
  entity(s,"em-35kv-catenary-pole",-1.5,2.5)
  entity(s,"em-35kv-catenary-pole",18.5,2.5)
  local sub=entity(s,"em-35kv-traction-substation",-20,9)
  local subb=entity(s,"em-35kv-traction-substation",20,9)
  local source=entity(s,"electric-energy-interface",-20,13)
  source.electric_interface_mode=defines.electric_interface_mode.primary_output
  source.electric_buffer_size=10000000
  source.power_production=LIMIT;source.power_usage=0
  source.input_flow_limit=0;source.output_flow_limit=LIMIT;source.energy=0
  -- A positive owner at a true contact span, one negative untouched off-line.
  local loco=entity(s,"em-electric-locomotive",0,1)
  local no=game.create_surface("em065-no-catenary",{width=128,height=128})
  no.generate_with_lab_tiles=true
  no.request_to_generate_chunks({0,0},2);no.force_generate_chunk_requests()
  for x=-13,13,2 do entity(no,"em-high-speed-straight-rail",x,1) end
  local negative=entity(no,"em-electric-locomotive",0,1)
  assert(loco.burner and negative.burner,"actual 0.1.65 EM locomotive has no native burner")
  assert((loco.burner.remaining_burning_fuel or 0)==0 and
         (negative.burner.remaining_burning_fuel or 0)==0,
    "new real EM locomotive starts with unpaid J")
  storage.em065_test={source=source,positive=loco,negative=negative,
    source_substation=sub,sink_substation=subb,source_initial=0}
  log("[EM065 PROBE] setup=actual_HSR_real_loco_20MW_3mast_2sub|burner_J=0|source_W=20000000")
end
script.on_event(defines.events.on_tick,function(e)
  if e.tick==2 then setup() end
  local s=storage.em065_test
  if not s then return end
  if e.tick%60==0 then
    log(string.format("[EM065 PROBE] tick=%d source_J=%.1f positive_J=%.1f negative_J=%.1f",
      e.tick,s.source.energy,s.positive.burner.remaining_burning_fuel,
      s.negative.burner.remaining_burning_fuel))
  end
  if e.tick==240 then
    local paid=s.positive.burner.remaining_burning_fuel
    local unpowered=s.negative.burner.remaining_burning_fuel
    assert(unpowered==0,"negative off-line loco received unpaid J: "..unpowered)
    assert(paid>100000,"live 25kV true contact delivered NO paid real-loco Joules: "..paid)
    assert(paid<=2000000,"paid real loco exceeded 2MJ physical reserve")
    log("[EM065 NATIVE PAID PASS] initial_J=0|grid_20MW=on|loco_burner_J="..
      paid.."|negative_offline_J=0|no_fake_fuel")
    -- Once paid positive-control confirmed, cut the true source.
    s.source.power_production=0;s.source.output_flow_limit=0
    s.source_substation.destroy{raise_destroy=true}
    s.positive_before_source_loss=paid
  end
  if e.tick==420 then
    local neg=s.negative.burner.remaining_burning_fuel
    assert(neg==0,"off-line loco gained free energy at tick420")
    log("[EM065 NATIVE 0W CONTROL] offline_loco_J=0|source_W=0|no_fake_positive")
  end
end)
