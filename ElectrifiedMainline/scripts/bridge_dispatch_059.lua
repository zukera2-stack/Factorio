-- 059 pure dispatch, joules/tick. Never writes native accumulators or creates energy.
local M={}
local function positive(v) return math.max(0,v or 0) end
function M.read_network(e)
 local ok,id,flow=pcall(function()
   local sub=e.electric_network
   if not(sub and sub.valid and sub.parent_network and sub.parent_network.valid) then return nil end
   local parent=sub.parent_network
   local id=sub.id
   for _,n in pairs(parent.sub_networks) do if n.valid and n.id<id then id=n.id end end
   local f=parent.flow_last_tick
   if not (f and type(f.primary_output)=="number" and type(f.secondary_demand)=="number" and type(f.tertiary_demand)=="number") then return nil end
   return id,f
 end)
 if ok then return id,flow end
end
function M.balance(f,own)
 own=own or {}
 local production=positive((f.primary_output or 0)+(f.secondary_output or 0)+(f.solar_output or 0)-(own.offer or 0))
 local demand=positive((f.primary_demand or 0)+(f.secondary_demand or 0)-(own.demand or 0))
 local net=production-demand
 return {gen=positive(net),load=positive(-net),
   battery=math.min(positive(f.tertiary_output),positive(f.accumulator_energy)),
   charge=math.min(positive(f.tertiary_demand),positive((f.accumulator_capacity or 0)-(f.accumulator_energy or 0)))}
end
-- Greedy deterministic shortest paths. Each station has a shared directed capacity;
-- no reverse edge on the same station, and no directed cycle (even long).
function M.plan(input,edges,limit)
 local n,ids,adj,flows,directed={},{},{},{},{}
 for id,v in pairs(input) do n[id]={gen=positive(v.gen),load=positive(v.load),battery=positive(v.battery),charge=positive(v.charge)};ids[#ids+1]=id end
 table.sort(ids)
 table.sort(edges,function(a,b)return a.id<b.id end)
 for _,e in ipairs(edges) do
   if n[e.a] and n[e.b] and e.a~=e.b then
     adj[e.a]=adj[e.a] or {};adj[e.b]=adj[e.b] or {}
     adj[e.a][#adj[e.a]+1]={edge=e,to=e.b,sign=1}
     adj[e.b][#adj[e.b]+1]={edge=e,to=e.a,sign=-1}
   end
 end
 local function reachable(from,to,extra)
   local queue,seen={from},{[from]=true}
   local i=1
   while i<=#queue do
     local a=queue[i];i=i+1
     if a==to then return true end
     for _,b in pairs(directed[a] or {}) do if not seen[b] then seen[b]=true;queue[#queue+1]=b end end
     if extra and extra[a] and not seen[extra[a]] then seen[extra[a]]=true;queue[#queue+1]=extra[a] end
   end
   return false
 end
 local function path(src,dst)
   local q,seen,prev={src},{[src]=true},{}
   local i=1
   while i<=#q do
     local a=q[i];i=i+1
     if a==dst then
       local steps={}
       while a~=src do local k=prev[a];steps[#steps+1]=k;a=k.from end
       return steps
     end
     for _,v in ipairs(adj[a] or {}) do
       local f=flows[v.edge.id] or 0
       if not seen[v.to] and f*v.sign>=0 and math.abs(f)<limit-1 and not reachable(v.to,a) then
         seen[v.to]=true;prev[v.to]={from=a,to=v.to,edge=v.edge,sign=v.sign};q[#q+1]=v.to
       end
     end
   end
 end
 local function route(supply,demand)
   -- Each greedy path saturates a source, sink, or edge; bounded by graph size.
   for _,src in ipairs(ids) do
     local a=n[src]
     for _,dst in ipairs(ids) do
       local b=n[dst]
       if src~=dst and a[supply]>1 and b[demand]>1 then
         while a[supply]>1 and b[demand]>1 do
           local steps=path(src,dst)
           if not steps then break end
           local amt=math.min(a[supply],b[demand]);local extra={};local cycle=false
           -- Recheck the whole path as a set, not just each link in isolation.
           for _,v in ipairs(steps) do
             if reachable(v.to,v.from,extra) then cycle=true;break end
             extra[v.from]=v.to;amt=math.min(amt,limit-math.abs(flows[v.edge.id] or 0))
           end
           if cycle or amt<=1 then break end
           a[supply]=a[supply]-amt;b[demand]=b[demand]-amt
           for _,v in ipairs(steps) do
             flows[v.edge.id]=(flows[v.edge.id] or 0)+v.sign*amt
             directed[v.from]=directed[v.from] or {};directed[v.from][v.to]=v.to
           end
         end
       end
     end
   end
 end
 route("gen","load")
 for _,id in ipairs(ids) do
   local v=n[id];local localuse=math.min(v.battery,v.load)
   v.battery=v.battery-localuse;v.load=v.load-localuse
 end
 route("battery","load")
 for _,id in ipairs(ids) do
   local v=n[id];local localcharge=math.min(v.gen,v.charge)
   v.gen=v.gen-localcharge;v.charge=v.charge-localcharge
 end
 route("gen","charge")
 return flows
end
return M
