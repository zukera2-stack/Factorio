-- 0.1.19 research ONLY: prove that native green rail-side snap sites
-- belong to rail-signal. This is deliberately NOT a catenary mast.
-- Do NOT place on operational rail networks; as a real rail-signal,
-- it changes block splitting/pathing. No replacement and no conversion.
local probe=table.deepcopy(data.raw["rail-signal"]["rail-signal"])
probe.name="em-35kv-native-placement-probe"
probe.minable={mining_time=0.2,result="em-35kv-native-placement-probe"}
probe.placeable_by={item="em-35kv-native-placement-probe",count=1}
probe.next_upgrade=nil
-- Preserve vanilla rail-signal graphics and all signal flags deliberately:
-- this is a SAME-TYPE control experiment with no disguised electric pole.

data:extend({
    probe,
    {
        type="item",name="em-35kv-native-placement-probe",
        icon="__base__/graphics/icons/rail-signal.png",icon_size=64,
        subgroup="transport",order="a[train-system]-z[em-native-probe]",
        stack_size=50,place_result=probe.name
    },
    {
        type="recipe",name="em-35kv-native-placement-probe",
        enabled=true,energy_required=0.5,
        ingredients={{type="item",name="iron-plate",amount=1}},
        results={{type="item",name="em-35kv-native-placement-probe",amount=1}}
    }
})
