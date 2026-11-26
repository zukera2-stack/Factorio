-- EM064 actual engine probe: retirement without deleting old save/game IDs.
script.on_event(defines.events.on_tick,function(e)
 if e.tick~=2 then return end
 local item=assert(prototypes.item["em-electric-pole"],"legacy item must persist")
 local entity=assert(prototypes.entity["em-electric-pole"],"legacy entity must persist")
 local recipe=assert(prototypes.recipe["em-electric-pole"],"legacy recipe must persist")
 assert(item.hidden==true,"old ordinary pole item still visible")
 assert(recipe.hidden==true,"old ordinary pole recipe still visible")
 assert(recipe.enabled==false,"old ordinary pole default crafting enabled")
 local tech=assert(prototypes.technology["em-electrified-railways"])
 for _,effect in ipairs(tech.effects or {}) do
  assert(not (effect.type=="unlock-recipe" and effect.recipe=="em-electric-pole"),
    "obsolete ordinary pole still unlocked by tech")
 end
 assert(prototypes.item["small-electric-pole"],"vanilla normal pole incorrectly removed")
 for _,name in ipairs({"em-35kv-catenary-pole","em-35kv-catenary-pole-north",
    "em-35kv-traction-substation","em-electric-locomotive","em-motor-cargo-wagon",
    "em-motor-fluid-wagon","em-high-speed-straight-rail"}) do
  assert(prototypes.entity[name],"real mod item/rail/mast/stock lost: "..name)
 end
 -- Place the historical entity from old saves and verify its standard mine mapping.
 local surface=game.surfaces[1]
 surface.request_to_generate_chunks({64,0},3)
 surface.force_generate_chunk_requests()
 local pole=surface.create_entity{name="em-electric-pole",position={64,0},force="player",
   raise_built=true}
 assert(pole and pole.valid and pole.type=="electric-pole",
   "legacy placed ordinary electric pole no longer loads")
 assert(entity.mineable_properties.products[1].name=="em-electric-pole",
   "legacy pole mining item was changed")
 local mast=surface.create_entity{name="em-35kv-catenary-pole",
   position={72,0},force="player",raise_built=true}
 local sub=surface.create_entity{name="em-35kv-traction-substation",
   position={80,0},force="player",raise_built=true}
 assert(mast and sub and mast.valid and sub.valid,
   "25kV actual mast/substation placement impacted")
 -- Presence of the locomotive is not proof it consumes 25kV J: its 063 source
 -- remains VoidEnergySource. Do not label this native test as paid traction PASS.
 log("[EM064 NATIVE POLE PASS] obsolete item+recipe hidden|legacy_placed=1|vanilla_pole=preserved|catenary=preserved|substation=preserved|traction_J=NOT_IMPLEMENTED")
end)
