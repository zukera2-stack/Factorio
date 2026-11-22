-- EM063 real FULL mod rail/stock destructive fault probe; separate TEST MOD, not shipped.
-- Exactly the full 0.1.63 game ZIP is installed. NO hand-created fake motor stock.
local BASE_X=500
local function check(condition,text)
  if not condition then error("[EM063 FAULT R FAIL] "..text,2) end
end
local function say(event,fields)
  log("[EM063 FAULT R] event="..event.."|tick="..game.tick.."|"..fields)
end
local function create(s,name,x,y)
  local e=s.create_entity{name=name,position={x=x,y=y},force=game.forces.player,
    direction=defines.direction.north,raise_built=true}
  check(e and e.valid,"native placement failed: "..name.." at "..x..","..y)
  return e
end
local function verify_stock(s,expected_helpers)
  check(s.loco.valid and s.cargo.valid and s.fluid.valid,"a visible unit disappeared")
  local t=s.loco.train
  check(t and t.valid and t.speed==0,"train missing or moving")
  local h=0
  for _,e in ipairs(t.carriages) do
    if e.name=="em-c5-technical-booster-1000" then h=h+1 end
  end
  check(h==expected_helpers,"helper count "..h.." expected "..expected_helpers)
  check(#t.carriages==3+expected_helpers,"native carriages count "..#t.carriages)
  check(#t.locomotives.front_movers+#t.locomotives.back_movers==1+expected_helpers,
    "native locomotive count mismatch")
  check(s.cargo.unit_number==s.cargo_id,"cargo identity drift")
  check(s.fluid.unit_number==s.fluid_id,"fluid identity drift")
  local iron=s.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count("iron-plate")
  local fluid=s.fluid.get_fluid(1)
  local water=fluid and fluid.amount or 0
  check(iron==37 and math.abs(water-9000)<0.0001,
    "cargo/fluid loss iron="..iron.." water="..water)
  check(math.abs(s.loco.position.y-s.fluid.position.y-(-14))<0.0001,
    "visible train geometry changed")
  if expected_helpers>0 then
    check(s.helper.valid and s.helper.burner.remaining_burning_fuel==0,
      "technical helper got free joules or became invalid")
  end
  say("stock", "carriages="..#t.carriages.."|helpers="..h..
    "|iron="..iron.."|water="..water.."|cargo_unit="..s.cargo_id..
    "|fluid_unit="..s.fluid_id.."|hidden_J="..
      tostring(expected_helpers>0 and s.helper.burner.remaining_burning_fuel or 0))
end
local function setup()
  local surface=game.surfaces[1]
  surface.request_to_generate_chunks({BASE_X,0},5)
  surface.force_generate_chunk_requests()
  local entities={
    "em-high-speed-straight-rail","em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b","em-half-diagonal-high-speed-rail",
    "em-electric-locomotive","em-motor-cargo-wagon","em-motor-fluid-wagon",
    "em-electric-pole","em-35kv-catenary-pole","em-35kv-catenary-pole-north",
    "em-35kv-traction-substation","em-c5-technical-booster-1000"
  }
  for _,name in ipairs(entities) do
    check(prototypes.entity[name],"missing actual mod entity "..name)
  end
  local items={
    "em-high-speed-rail","em-rail-replacement-planner",
    "em-electric-locomotive","em-motor-cargo-wagon","em-motor-fluid-wagon",
    "em-electric-pole","em-35kv-catenary-pole",
    "em-35kv-catenary-pole-north","em-35kv-traction-substation",
    "em-concrete-beam","em-heavy-copper-cable",
    "em-traction-motor","em-battery-bank","em-regenerative-brake-unit"
  }
  for _,name in ipairs(items) do check(prototypes.item[name],"missing actual item "..name) end
  check(prototypes.recipe["em-motor-cargo-wagon"],"motor cargo recipe missing")
  check(prototypes.recipe["em-motor-fluid-wagon"],"motor fluid recipe missing")
  for dy=-24,32,2 do create(surface,"em-high-speed-straight-rail",BASE_X,dy) end
  local r={
    create(surface,"em-curved-high-speed-rail",BASE_X+50,-38),
    create(surface,"em-curved-high-speed-rail-b",BASE_X+66,-38),
    create(surface,"em-half-diagonal-high-speed-rail",BASE_X+80,-38)
  }
  for i,e in ipairs(r) do check(e.valid and e.type~="entity-ghost",
    "HSR geometry "..i.." is ghost or missing") end
  create(surface,"em-electric-pole",BASE_X+32,-20)
  create(surface,"em-35kv-catenary-pole",BASE_X+5,-10)
  create(surface,"em-35kv-catenary-pole-north",BASE_X+5,10)
  create(surface,"em-35kv-traction-substation",BASE_X+12,-2)
  local loco=create(surface,"em-electric-locomotive",BASE_X,0)
  local cargo=create(surface,"em-motor-cargo-wagon",BASE_X,7)
  local fluid=create(surface,"em-motor-fluid-wagon",BASE_X,14)
  check(cargo.type=="cargo-wagon" and fluid.type=="fluid-wagon",
    "motor wagon native entity types wrong")
  local inserted=cargo.get_inventory(defines.inventory.cargo_wagon).insert{
    name="iron-plate",count=37}
  fluid.set_fluid(1,{name="water",amount=9000})
  check(inserted==37,"couldn't insert 37 plates")
  local s={loco=loco,cargo=cargo,fluid=fluid,
    cargo_id=cargo.unit_number,fluid_id=fluid.unit_number}
  check(loco.disconnect_rolling_stock(defines.rail_direction.back),
    "could not safely disconnect stopped locomotive for helper")
  s.helper=create(surface,"em-c5-technical-booster-1000",BASE_X,3.5)
  s.helper.minable_flag=false
  s.helper.destructible=false
  storage.rail_fault=s
  verify_stock(s,1)
  say("setup","real_items="..#items.."|real_proto="..#entities..
      "|extra_HSR_geometry=3|straight_HSR=29|masts=2|substation=1")
end
script.on_event(defines.events.on_tick,function(ev)
  local t=ev.tick
  if t==2 then setup() end
  if t==40 or t==90 then verify_stock(storage.rail_fault,1) end
  if t==100 then
    local ok,res=pcall(function() game.server_save("em063-fault-rail_stock-checkpoint") end)
    check(ok,"real disk checkpoint could not be made: "..tostring(res))
    say("disk_checkpoint","name=em063-fault-rail_stock-checkpoint|ok=true")
  end
  if t==126 then
    local s=storage.rail_fault
    local old_unit=s.helper.unit_number
    s.helper.destroy{raise_destroy=true}
    check(not s.helper.valid,"helper could not be removed by script")
    say("remove_helper","old_unit="..old_unit)
    -- A stopped visible train may need explicit native uncoupling on reinsert.
    if s.loco.train and #s.loco.train.carriages>1 then
      s.loco.disconnect_rolling_stock(defines.rail_direction.back)
    end
    s.helper=create(s.loco.surface,"em-c5-technical-booster-1000",BASE_X,3.5)
    s.helper.minable_flag=false
    s.helper.destructible=false
    verify_stock(s,1)
    say("reinsert_helper","old_unit="..old_unit.."|new_unit="..s.helper.unit_number)
  end
  if t==160 then
    local s=storage.rail_fault
    verify_stock(s,1)
    local unit=s.loco.unit_number
    s.loco.destroy{raise_destroy=true}
    check(not s.loco.valid,"owner real EM locomotive not destroyed")
    say("destroy_owner","owner_unit="..unit.."|helper_valid="..tostring(s.helper.valid)..
      "|cargo_unit="..s.cargo.unit_number.."|fluid_unit="..s.fluid.unit_number)
  end
  if t==170 then
    local s=storage.rail_fault
    local cargo=s.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count("iron-plate")
    local fluid=s.fluid.get_fluid(1)
    local water=fluid and fluid.amount or 0
    check(cargo==37 and math.abs(water-9000)<0.001,
      "owner destruction damaged real cargo/fluid")
    say("post_owner_10ticks","hidden_valid="..tostring(s.helper.valid)..
        "|iron="..cargo.."|water="..water)
  end
  if t==240 then
    local s=storage.rail_fault
    local cargo=s.cargo.get_inventory(defines.inventory.cargo_wagon).get_item_count("iron-plate")
    local fluid=s.fluid.get_fluid(1)
    local water=fluid and fluid.amount or 0
    say("post_owner_80ticks","hidden_valid="..tostring(s.helper.valid)..
        "|iron="..cargo.."|water="..water)
    check(cargo==37 and math.abs(water-9000)<0.001,
      "real cargo/fluid damaged after 80 ownerless ticks")
    -- Ownerless hidden locomotive must not remain after 80 ticks (covering
    -- at least two 30-tick main mod train update periods).
    check(not s.helper.valid,
      "PERSISTENT_ORPHAN_HIDDEN_LOCOMOTIVE: 80 ticks after destroying sole real EM owner")
    say("PASS","real full mod stock survived SAVE/LOAD, helper retier and owner destruction")
    log("[EM063 RAIL STOCK PASS] all scoped fullmod native item/geometry/identity/disk/recovery checks")
  end
end)
