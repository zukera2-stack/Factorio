-- 0.1.20 TEST ONLY. A SINGLE ITEM PROTOTYPE with native capsule action.
-- The only place_result is the EXISTING electric-pole. No world helper entities,
-- rail signals, tiles, hidden entities or entity destruction/replacement.
-- Factorio engine precedence between capsule_action and place_result is UNKNOWN.
local POLE="em-35kv-catenary-pole"
local ITEM="em-35kv-click-probe-020"
local vanilla=data.raw["capsule"] and data.raw["capsule"]["grenade"]
assert(vanilla, "EM 0.1.20: vanilla grenade capsule missing")
local probe=table.deepcopy(vanilla)
probe.name=ITEM
probe.localised_name={"item-name."..ITEM}
probe.localised_description={"item-description."..ITEM}
probe.icon="__base__/graphics/icons/medium-electric-pole.png"
probe.icon_size=64
probe.icons=nil
probe.subgroup="energy"
probe.order="a[electric-pole]-zz[experimental-click-probe]"
probe.stack_size=50
probe.place_result=POLE
-- Let build_from_cursor be the ONLY consumer of the test item.
probe.capsule_action.uses_stack=false
local attack=probe.capsule_action.attack_parameters
attack.range=32
attack.cooldown=15
attack.ammo_type.target_type="position"
attack.ammo_type.action={
    type="direct",
    action_delivery={
        type="instant",
        target_effects={{type="script",effect_id="em-35kv-probe-use-020"}}
    }
}
data:extend({
    probe,
    {
        type="recipe",name=ITEM,enabled=true,energy_required=0.5,
        ingredients={{type="item",name=POLE,amount=1}},
        results={{type="item",name=ITEM,amount=1}}
    }
})
