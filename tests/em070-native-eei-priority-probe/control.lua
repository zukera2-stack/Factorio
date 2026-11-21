-- Native electricity solver test, NO custom script-transfer between circuits.
local variants={
 {"fixed-input","em070-secondary-input","out"},
 {"fixed-output","em070-secondary-output","out"},
 {"dynamic","em070-dynamic","out"},
 {"base-dynamic","electric-energy-interface","out"},
 {"fixed-input","em070-secondary-input","in"},
 {"fixed-output","em070-secondary-output","in"},
 {"dynamic","em070-dynamic","in"},
 {"base-dynamic","electric-energy-interface","in"}
}
local function get(e) assert(e and e.valid);return e end
local function inspect(t,label)
 for _,v in ipairs(storage.pairs or {}) do
  local e,b=get(v.eei),get(v.battery)
  log(string.format("[EM070 %s] tick=%d name=%s dir=%s mode=%s network=%s battery_network=%s eei_J=%.0f battery_J=%.0f input_limit=%.0f output_limit=%.0f",
   label,t,v.name,v.direction,tostring(e.electric_interface_mode),tostring(e.electric_network_id),tostring(b.electric_network_id),
   e.energy,b.energy,e.input_flow_limit,e.output_flow_limit))
 end
end
script.on_init(function()storage.pairs={} end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick
 if t==1 then
  local surface=game.surfaces[1]
  for i,v in ipairs(variants) do
   local x=i*55
   local p=surface.create_entity{name="substation",position={x=x,y=0},force="player"}
   local b=surface.create_entity{name="accumulator",position={x=x+4,y=0},force="player"}
   local e=surface.create_entity{name=v[2],position={x=x+7,y=0},force="player"}
   assert(p and b and e)
   e.power_production=0;e.power_usage=0;e.input_flow_limit=0;e.output_flow_limit=0
   if v[3]=="out" then e.energy=2000000;b.energy=0 else e.energy=0;b.energy=2000000 end
   storage.pairs[i]={name=v[1],direction=v[3],eei=e,battery=b}
  end
  log("[EM070 SETUP] 8 isolated real vanilla factory power networks")
 elseif t==15 then inspect(t,"BEFORE")
 elseif t==30 then
  for _,v in ipairs(storage.pairs) do
   local e=get(v.eei)
   local mode=(v.direction=="out") and defines.electric_interface_mode.secondary_output or defines.electric_interface_mode.secondary_input
   e.electric_interface_mode=mode
   if v.direction=="out" then e.output_flow_limit=2000000/60 else e.input_flow_limit=2000000/60 end
   assert(e.electric_interface_mode==mode)
  end
 elseif t==180 then
  inspect(t,"FINAL")
  for _,v in ipairs(storage.pairs) do
   local e,b=get(v.eei),get(v.battery)
   assert(e.electric_network_id and e.electric_network_id==b.electric_network_id)
   local moved=(v.direction=="out") and b.energy or e.energy
   assert(math.abs(e.energy+b.energy-2000000)<4,"Energy vanished or created: "..v.name)
   if v.name=="dynamic" or v.name=="base-dynamic" then
    assert(moved>500000,"Dynamic EEI failed to switch: "..v.direction)
   elseif (v.name=="fixed-input" and v.direction=="out") or (v.name=="fixed-output" and v.direction=="in") then
    assert(moved==0,"Fixed usage_priority unexpectedly switched")
   else
    assert(moved>500000,"Fixed same-direction control failed")
   end
   log(string.format("[EM070 RESULT] name=%s dir=%s transferred_J=%.1f balance_J=%.1f",v.name,v.direction,moved,e.energy+b.energy))
  end
  log("[EM070 NATIVE COMPLETE] 8 same-type EEI comparisons in Factorio 2.1.24")
 end
end)
