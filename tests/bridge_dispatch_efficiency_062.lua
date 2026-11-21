-- Regression for the 48-station fan-out that made the original fair dispatcher slow.
-- This runs unchanged gameplay Lua, not a rewritten model of the planner.
package.path='./ElectrifiedMainline/?.lua;'..package.path
local D=require('scripts.bridge_dispatch_059')
local L=20000000/60
local hub=49
local function net(g,l,b,c) return {gen=g or 0,load=l or 0,battery=b or 0,charge=c or 0} end
local function close(a,b,label)
 assert(math.abs((a or 0)-b)<0.1,(label or 'flow')..': expected '..b..' got '..tostring(a))
end
local function star(n_sources,active)
 local nodes,edges,sinks,sources={}, {}, {}, {}
 nodes[hub]=net()
 for i=1,48 do
   edges[#edges+1]={id=i,a=i,b=hub}
   if (i-1)%8==0 and #sources<n_sources then
     nodes[i]=net(L);sources[#sources+1]=i
   else
     local live=active==nil or active(i)
     nodes[i]=net(0,live and L or 0)
     if live then sinks[#sinks+1]=i end
   end
 end
 local flows=D.plan(nodes,edges,L)
 local budget=math.min(#sources*L,#sinks*L)
 local sink_share=budget/#sinks
 local sent=0;local received=0
 for _,i in ipairs(sources) do
   close(flows[i],L,'48-source '..i)
   sent=sent+(flows[i] or 0)
 end
 for _,i in ipairs(sinks) do
   close(flows[i],-sink_share,'48-sink '..i)
   received=received-(flows[i] or 0)
 end
 close(received,budget,'source balance')
 close(sent,budget,'consumer balance')
 for i=1,48 do assert(math.abs(flows[i] or 0)<=L+.01,'20MW station cap') end
 return #sources,#sinks
end
local a,b=star(6);assert(a==6 and b==42)
local a2,b2=star(6,function(i)return i%2==1 end);assert(a2==6 and b2==18)
-- No power when the generators go offline, even if loads remain attached.
local input,edges={[hub]=net()},{}
for i=1,48 do input[i]=net(0,L);edges[i]={id=i,a=i,b=hub} end
local no=D.plan(input,edges,L)
for i=1,48 do close(no[i],0,'source outage '..i) end
-- Battery-backed reverse power must be possible in a small branched graph.
local flows=D.plan({[1]=net(0,L),[2]=net(),[3]=net(0,0,L)},{{id=1,a=1,b=2},{id=2,a=2,b=3}},L)
close(flows[1],-L,'battery reverse first link')
close(flows[2],-L,'battery reverse second link')
print('[EM062 OPT UNIT PASS] 48 station star 6x20MW/42 sinks, 18 sink reroute, outage, battery reverse')