-- Independent native terminals, only on the bridge lab surface.
local port=table.deepcopy(assert(data.raw["electric-pole"]["em-25kv-technical-anchor-046"]))
port.name="em-25kv-bridge-port-058"
port.maximum_wire_distance=0
port.supply_area_distance=0.5
port.auto_connect_up_to_n_wires=0
port.draw_copper_wires=false
port.draw_circuit_wires=false
port.rewire_neighbours_when_destroying=false
local function interface(name,priority,input,output)
 return {
   type="electric-energy-interface",name=name,hidden=true,
   icon="__base__/graphics/icons/substation.png",icon_size=64,
   flags={"placeable-off-grid","not-on-map","not-blueprintable","not-deconstructable","hide-alt-info","get-by-unit-number"},
   collision_box={{0,0},{0,0}},selection_box={{0,0},{0,0}},collision_mask={layers={}},
   selectable_in_game=false,
   energy_source={type="electric",buffer_capacity="2MJ",usage_priority=priority,
      input_flow_limit=input,output_flow_limit=output,drain="0W",
      render_no_power_icon=false,render_no_network_icon=false},
   energy_production="0W",energy_usage="0W",gui_mode="none"
 }
end
data:extend({port,interface("em-25kv-bridge-input-058","dynamic","120MW","0W"),
 interface("em-25kv-bridge-output-058","dynamic","0W","120MW")})