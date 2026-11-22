-- Native actual Factorio Base + FULL ElectrifiedMainline 0.1.63 prototype/scene probe.
-- Independent of the shipped player's optional console scene; no GUI claim.
script.on_event(defines.events.on_tick,function(ev)
  if ev.tick~=2 then return end
  local needed={
    "em-electric-locomotive","em-high-speed-straight-rail",
    "em-35kv-catenary-pole","em-35kv-catenary-pole-north",
    "em-35kv-traction-substation","em-motor-cargo-wagon",
    "em-motor-fluid-wagon","em-c5-technical-booster-1000"
  }
  for _,name in ipairs(needed) do
    assert(prototypes.entity[name],"[EM063 NATIVE FAIL] no REAL mod prototype "..name)
  end
  for _,name in ipairs({
    "em-high-speed-rail","em-electric-locomotive",
    "em-35kv-catenary-pole","em-35kv-catenary-pole-north",
    "em-35kv-traction-substation",
    "em-motor-cargo-wagon","em-motor-fluid-wagon"
  }) do
    assert(prototypes.item[name],"[EM063 NATIVE FAIL] no real placeable item "..name)
  end
  local surface=game.surfaces[1]
  local x,y=500,0
  surface.request_to_generate_chunks({x=x,y=y},3)
  surface.force_generate_chunk_requests()
  local function put(name,dx,dy)
    local e=surface.create_entity{name=name,position={x=x+dx,y=y+dy},
      direction=defines.direction.north,force=game.forces.player,
      raise_built=true}
    assert(e,"[EM063 NATIVE FAIL] cannot place "..name.." dx="..dx.." dy="..dy)
    return e
  end
  for dy=-24,32,2 do put("em-high-speed-straight-rail",0,dy) end
  local loco=put("em-electric-locomotive",0,0)
  local cargo=put("em-motor-cargo-wagon",0,7)
  local fluid=put("em-motor-fluid-wagon",0,14)
  put("em-35kv-catenary-pole",5,-10)
  put("em-35kv-catenary-pole-north",5,10)
  put("em-35kv-traction-substation",12,-2)
  assert(loco.train.speed==0,"[EM063 NATIVE FAIL] train is moving unexpectedly")
  assert(loco.disconnect_rolling_stock(defines.rail_direction.back),
    "[EM063 NATIVE FAIL] cannot decouple one real EM loco")
  local helper=put("em-c5-technical-booster-1000",0,3.5)
  helper.minable_flag=false
  helper.destructible=false
  assert(helper.train and loco.train and helper.train.id==loco.train.id,
    "[EM063 NATIVE FAIL] helper not physically connected")
  local t=loco.train
  assert(#t.carriages==4,"[EM063 NATIVE FAIL] expected 4 native carriages not "..#t.carriages)
  assert(#t.locomotives.front_movers+#t.locomotives.back_movers==2,
    "[EM063 NATIVE FAIL] native hidden helper loco must be counted as locomotive")
  assert(cargo.type=="cargo-wagon" and fluid.type=="fluid-wagon",
    "[EM063 NATIVE FAIL] motor wagons have wrong native type")
  assert(helper.burner.remaining_burning_fuel==0,
    "[EM063 NATIVE FAIL] unpaid hidden helper Joules were seeded")
  local span=math.abs(loco.position.y-fluid.position.y)
  assert(math.abs(span-14)<0.001,
    "[EM063 NATIVE FAIL] visible native span changed")
  log("[EM063 NATIVE PASS] full_real_mod=0.1.63|HSR=29|real_EM=1|motor_cargo=1|motor_fluid=1|masts=2|substation=1|native_carriages=4|native_locos=2|hidden_helper_J=0|span=14")
end)
