-- 0.1.19 research diagnostic ensures semantics are never mislabeled.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local f=assert(io.open("ElectrifiedMainline/prototypes/native_signal_probe_019.lua"))
local s=f:read("*a");f:close()
assert(s:find('data.raw["rail-signal"]["rail-signal"]',1,true))
assert(s:find('place_result=probe.name',1,true))
assert(s:find('probe.name="em-35kv-native-placement-probe"',1,true))
for _,forbidden in ipairs({"destroy(", "create_entity(", "undo_index", "electric%-pole"}) do
    assert(not s:find(forbidden),"not a native signal-only experiment: "..forbidden)
end
local d=assert(io.open("ElectrifiedMainline/data.lua")):read("*a")
assert(d:find('require("prototypes.native_signal_probe_019")',1,true))
local source=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(source:find('catenary.name = "em-35kv-catenary-pole"',1,true))
assert(source:find('data.raw["electric-pole"]["small-electric-pole"]',1,true))
print("0.1.19 rail-signal engine snap proof is isolated from real catenary electric-pole: PASS")
