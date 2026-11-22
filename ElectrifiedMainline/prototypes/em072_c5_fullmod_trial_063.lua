-- 0.1.63 owner-facing FULL MOD C5 research build: genuine native cargo/fluid,
-- existing real em-electric-locomotive and existing rail/mast/substation sources
-- remain unmodified. Trial helpers are finite-J and have no player-accessible fuel.
local cargo_name="em-motor-cargo-wagon"
local fluid_name="em-motor-fluid-wagon"

local function wagon(kind,source_name,new_name)
  local source=assert(data.raw[kind] and data.raw[kind][source_name],
    "C5 requires native Base rolling stock "..source_name)
  local p=table.deepcopy(source)
  p.name=new_name
  p.minable={mining_time=0.5,result=new_name}
  p.placeable_by={item=new_name,count=1}
  p.next_upgrade=nil
  local base_item=assert(data.raw["item-with-entity-data"][source_name])
  local item=table.deepcopy(base_item)
  item.name=new_name
  item.place_result=new_name
  item.localised_name={"item-name."..new_name}
  item.localised_description={"item-description."..new_name}
  local recipe=table.deepcopy(assert(data.raw.recipe[source_name]))
  recipe.name=new_name
  recipe.enabled=false
  recipe.results={{type="item",name=new_name,amount=1}}
  recipe.localised_name={"item-name."..new_name}
  recipe.localised_description={"item-description."..new_name}
  data:extend({p,item,recipe})
end

wagon("cargo-wagon","cargo-wagon",cargo_name)
wagon("fluid-wagon","fluid-wagon",fluid_name)

local technology=assert(data.raw.technology["em-high-speed-locomotive"])
technology.effects=technology.effects or {}
table.insert(technology.effects,{type="unlock-recipe",recipe=cargo_name})
table.insert(technology.effects,{type="unlock-recipe",recipe=fluid_name})

-- Internal technical fuel only: hidden and has NO recipe or delivery to player.
-- The C5 GUI fixture NEVER assigns currently_burning nor remaining_burning_fuel.
data:extend({
  {type="fuel-category",name="em-c5-test-internal-energy-063"},
  {type="item",name="em-c5-test-internal-joule-063",
   hidden=true,icon="__base__/graphics/icons/battery.png",icon_size=64,
   stack_size=1,fuel_categories={"em-c5-test-internal-energy-063"},
   fuel_value="10MJ"}
})

local empty="__core__/graphics/empty.png"
for _,kilowatts in ipairs({500,1000,2000}) do
  local p=table.deepcopy(assert(data.raw.locomotive.locomotive))
  p.name="em-c5-technical-booster-"..kilowatts
  p.max_power=kilowatts.."kW"
  p.max_speed=1.2
  p.weight=1
  p.energy_source={
    type="burner", fuel_categories={"em-c5-test-internal-energy-063"},
    effectivity=1, fuel_inventory_size=1
  }
  p.joint_distance=0.1
  p.connection_distance=-0.1
  p.collision_box={{-0.2,-0.26},{0.2,0.26}}
  p.selection_box={{-0.2,-0.26},{0.2,0.26}}
  p.selectable_in_game=false
  p.hidden_in_factoriopedia=true
  p.pictures={rotated={filename=empty,width=1,height=1,direction_count=1}}
  p.wheels={rotated={filename=empty,width=1,height=1,direction_count=1}}
  p.front_light=nil
  p.front_light_pictures=nil
  p.back_light=nil
  p.stand_by_light=nil
  p.minimap_representation=nil
  p.selected_minimap_representation=nil
  p.stop_trigger=nil
  p.minable=nil
  p.placeable_by=nil
  p.next_upgrade=nil
  p.flags={"placeable-off-grid","not-blueprintable",
    "not-deconstructable","not-on-map"}
  data:extend({p})
end
log("[EM C5 FULL 0.1.63] Real cargo/fluid wagons + zero-J technical helpers declared; no EM070-paid traction implementation")
