-- Run from repository root: lua5.2 tests/35kv_topology.lua
package.path="./ElectrifiedMainline/?.lua;./ElectrifiedMainline/?/init.lua;"..package.path
local t=require("scripts.power_topology")
local function n(id,x,y,tx,ty,side)
    return {id=id,x=x,y=y,tx=tx,ty=ty,side=side,rail_adjacent=true}
end
local function eq(node,id)
    assert((node and node.id or nil)==id,
        "expected "..tostring(id).." got "..tostring(node and node.id))
end
local line={}
for i=1,5 do line[i]=n(i,(i-1)*10,-2,1,0,-1) end
for i,a in ipairs(line) do
    local f,b=t.choose(a,line,16)
    eq(f,i<5 and i+1 or nil)
    eq(b,i>1 and i-1 or nil)
end
assert(not t.compatible(line[1],n(6,7,5,1,0,1),16))
assert(not t.compatible(line[1],n(7,7,2.1,1,0,-1),16))
assert(not t.compatible(line[1],n(8,17,-2,1,0,-1),16))
assert(not t.compatible(line[1],n(9,10,-2,0,1,-1),16))
local f,b=t.choose(line[1],{n(10,4,-2,1,0,-1),n(11,6,-2,1,0,-1),
    n(12,-3,-2,1,0,-1),n(13,-6,-2,1,0,-1)},16)
eq(f,10);eq(b,12)
eq(select(1,t.choose(line[1],{n(15,5,-2,1,0,-1),
    n(14,5,-2,1,0,-1)},16)),14)
eq(select(1,t.choose(line[1],{line[2]},16,function()return false end)),nil)
local invalid=n(16,6,-2,1,0,-1);invalid.rail_adjacent=false
assert(not t.compatible(line[1],invalid,16))
print("35 kV topology: all pure Lua assertions passed")

-- 061 compatibility gate: older workflow version lists end at 060.
-- Run every scoped 060 regression in an isolated Lua5.2 subprocess, plus 061.
-- This is only a CI runner; it does NOT substitute for Factorio native engine tests.
local file=assert(io.open("ElectrifiedMainline/info.json","r"))
local info=file:read("*a");file:close()
local is062=info:match('"version"%s*:%s*"0%.1%.62"')~=nil or info:match('"version"%s*:%s*"0%.1%.63"')~=nil or info:match('"version"%s*:%s*"0%.1%.64"')~=nil or (info:match('"version"%s*:%s*"0%.1%.65"')~=nil or (info:match('"version"%s*:%s*"0%.1%.66"')~=nil or (info:match('"version"%s*:%s*"0%.1%.67"')~=nil or (info:match('"version"%s*:%s*"0%.1%.68"')~=nil or info:match('"version"%s*:%s*"0%.1%.69"')~=nil))))
if info:match('"version"%s*:%s*"0%.1%.61"') or is062 then
 local inherited={
  "25kv_visual_042","25kv_visual_geometry_048","25kv_technical_048",
  "25kv_policy_047","25kv_axis_056","25kv_axis_integration_056",
  "locomotive_visual_049","pantograph_spark_052","hsr_concrete_053",
  "prototypes_057","power_bridge_058","power_bridge_integration_058",
  "bridge_dispatch_059","power_bridge_integration_059",
  "bridge_devices_060","power_bridge_cold_start_060",
  "priority_diagnostics_061"
 }
 for _,name in ipairs(inherited) do
   local command="lua5.2 tests/"..name..".lua"
   local ok,why,code=os.execute(command)
   assert(ok==true and why=="exit" and code==0,"061 inherited Lua regression failed: "..name)
 end
 print("061/062 PASS: full legacy 060 regression matrix and diagnostic regression")
 if is062 then
   local ok,why,code=os.execute("lua5.2 tests/bridge_fairness_062.lua")
   assert(ok==true and why=="exit" and code==0,"062 fairness regression failed")
   local opt_ok,opt_why,opt_code=os.execute("lua5.2 tests/bridge_dispatch_efficiency_062.lua")
   assert(opt_ok==true and opt_why=="exit" and opt_code==0,"062 48-station optimized dispatch regression failed")
   local turnout_ok,turnout_why,turnout_code=os.execute("lua5.2 tests/25kv_turnout_cosmetic_071.lua")
   assert(turnout_ok==true and turnout_why=="exit" and turnout_code==0,"071 real rail turnout cosmetic 3-span regression failed")
   local cache_ok,cache_why,cache_code=os.execute("lua5.2 tests/bridge_dispatch_cache_067.lua")
   assert(cache_ok==true and cache_why=="exit" and cache_code==0,"067 dispatcher cache parity test failed")

   local policy_ok,policy_why,policy_code=os.execute("python3 tests/switching_dissipation_contract_066.py --self-test")
   assert(policy_ok==true and policy_why=="exit" and policy_code==0,"066 switching energy policy regression failed")
 end
 if os.getenv("GITHUB_ACTIONS")=="true" then
   local ok,why,code=os.execute(is062 and "bash tests/run_headless_062.sh" or "bash tests/run_headless_061.sh")
   assert(ok==true and why=="exit" and code==0,"061 exact Factorio headless native regression failed")
 end
end
