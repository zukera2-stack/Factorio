-- Mock effective data-stage prototype construction, not a Factorio game run.
local function copy(x)
 if type(x)~="table" then return x end
 local y={} for k,v in pairs(x) do y[k]=copy(v) end return y
end
table.deepcopy=copy
data={raw={}}
for _,t in ipairs({"item","recipe","technology","rail-planner","selection-tool","straight-rail","curved-rail-a","curved-rail-b","half-diagonal-rail","electric-pole","locomotive","cargo-wagon","fluid-wagon"}) do data.raw[t]={} end
for t,n in pairs({["rail-planner"]="rail",["selection-tool"]="selection-tool",["straight-rail"]="straight-rail",["curved-rail-a"]="curved-rail-a",["curved-rail-b"]="curved-rail-b",["half-diagonal-rail"]="half-diagonal-rail",["electric-pole"]="small-electric-pole",locomotive="locomotive",["cargo-wagon"]="cargo-wagon",["fluid-wagon"]="fluid-wagon"}) do data.raw[t][n]={name=n,type=t,icons={{icon="native"}},wheels={native=true}} end
function data:extend(ps) for _,p in ipairs(ps) do self.raw[p.type][p.name]=p end end
dofile("ElectrifiedMainline/prototypes/bootstrap.lua")
local l=data.raw.locomotive["em-electric-locomotive"]
assert(l.max_power=="2MW" and l.max_speed==2 and l.braking_force==20 and l.weight==2000 and l.energy_source.type=="void" and l.wheels.native)
for _,kind in ipairs({"cargo","fluid"}) do
 local n="em-high-speed-"..kind.."-wagon"
 assert(not data.raw.item[n] and not data.raw.recipe[n] and not data.raw[kind.."-wagon"][n])
 assert(data.raw[kind.."-wagon"][kind.."-wagon"])
 for _,e in ipairs(data.raw.technology["em-high-speed-locomotive"].effects) do assert(e.recipe~=n) end
end
local rail=data.raw["rail-planner"]["em-high-speed-rail"]
local plan=data.raw["selection-tool"]["em-rail-replacement-planner"]
assert(rail.icon~=plan.icon and rail.icon_size==64 and plan.icon_size==64 and not rail.icons and not plan.icons and #rail.rails==4)
for _,n in ipairs(rail.rails) do
 local e
 for _,t in ipairs({"straight-rail","curved-rail-a","curved-rail-b","half-diagonal-rail"}) do e=e or data.raw[t][n] end
 assert(e and e.icon==rail.icon and not e.icons)
end
assert(data.raw.recipe["em-high-speed-rail"].icon==rail.icon and data.raw.recipe["em-rail-replacement-planner"].icon==plan.icon)
print("057 PASS: cloned effective locomotive, wagon removal, vanilla preservation and icon bindings")
