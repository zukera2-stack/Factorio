-- 059 pure dispatch, joules/tick. Never writes native accumulators or creates energy.
local M={}
local function positive(v) return math.max(0,v or 0) end
local function parent_key(e)
 local sub=e.electric_network
 if not(sub and sub.valid and sub.parent_network and sub.parent_network.valid) then return nil end
 local parent=sub.parent_network
 local id=sub.id
 for _,n in pairs(parent.sub_networks) do if n.valid and n.id<id then id=n.id end end
 return id,parent
end
function M.network_key(e)
 local ok,id=pcall(parent_key,e)
 if ok then return id end
end
function M.read_network(e)
 local ok,id,flow=pcall(function()
   local id,parent=parent_key(e)
   if not id then return nil end
   local f=parent.flow_last_tick
   if not (f and type(f.primary_output)=="number" and type(f.secondary_demand)=="number" and type(f.tertiary_demand)=="number") then return id,nil end
   return id,f
 end)
 if ok then return id,flow end
end
-- J/tick except stored/capacity in J. Independent readings are not added twice.
function M.balance(f,own,direct)
 own=own or {};direct=direct or {}
 local rawprod=positive((f.primary_output or 0)+(f.secondary_output or 0)+(f.solar_output or 0))
 local rawdemand=positive((f.primary_demand or 0)+(f.secondary_demand or 0))
 local stored=math.max(positive(f.accumulator_energy),positive(direct.stored))
 local capacity=math.max(positive(f.accumulator_capacity),positive(direct.capacity))
 if capacity==0 and positive(f.tertiary_output)==0 and positive(f.tertiary_demand)==0 then
   rawprod=math.max(rawprod,positive(f.maximum_production))
   rawdemand=math.max(rawdemand,positive(f.maximum_consumption))
 end
 local production=math.max(positive(rawprod-(own.offer or 0)),positive(direct.production))
 local demand=math.max(positive(rawdemand-(own.demand or 0)),positive(direct.demand))
 local net=production-demand
 return {gen=positive(net),load=positive(-net),
   battery=math.min(stored,math.max(positive(f.tertiary_output),positive(direct.discharge))),
   charge=math.min(positive(capacity-stored),math.max(positive(f.tertiary_demand),positive(direct.charge))),
   production=production,demand=demand,stored=stored,capacity=capacity}
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
 -- Build a shortest-path tree once per source/pass, not once per destination.
 -- On a 48-station network the prior version searched the same graph up to
 -- 42 times *per source*, and each search recursively checked cycle safety.
 -- A pass operates on a consistent snapshot; commitments are revalidated
 -- against current residual capacity and newly directed arcs below.
 local function shortest_tree(src)
   local q,seen,prev={src},{[src]=true},{}
   local i=1
   while i<=#q do
     local a=q[i];i=i+1
     for _,v in ipairs(adj[a] or {}) do
       local f=flows[v.edge.id] or 0
       if not seen[v.to] and f*v.sign>=0 and math.abs(f)<limit-1 and not reachable(v.to,a) then
         seen[v.to]=true;prev[v.to]={from=a,to=v.to,edge=v.edge,sign=v.sign}
         q[#q+1]=v.to
       end
     end
   end
   return seen,prev
 end
 local function path_from_tree(src,dst,prev)
   local steps={}
   local at=dst
   while at~=src do
     local v=prev[at]
     if not v then return nil end
     steps[#steps+1]=v
     at=v.from
   end
   return steps
 end
 local function route(supply,demand)
   -- Each source gives all currently reachable same-tier destinations one
   -- equal quota per pass. Rebuild the tree only after the pass changes flow.
   for _,src in ipairs(ids) do
     local a=n[src]
     while a[supply]>1 do
       local seen,prev=shortest_tree(src)
       local destinations={}
       for _,dst in ipairs(ids) do
         if dst~=src and n[dst][demand]>1 and seen[dst] then
           destinations[#destinations+1]=dst
         end
       end
       if #destinations==0 then break end
       local budget=a[supply]/#destinations
       local transferred=0
       for _,dst in ipairs(destinations) do
         local b=n[dst]
         local steps=path_from_tree(src,dst,prev)
         if steps then
           local amt=math.min(a[supply],b[demand],budget)
           local extra={}
           local cycle=false
           for _,v in ipairs(steps) do
             local f=flows[v.edge.id] or 0
             if f*v.sign<0 or math.abs(f)>=limit-1 then
               cycle=true;break -- another recipient saturated/reoriented the tree
             end
             -- Already directed arcs cannot introduce a cycle a second time.
             -- New arcs must be checked with all arcs pending in this path.
             if not (directed[v.from] and directed[v.from][v.to]) then
               if reachable(v.to,v.from,extra) then cycle=true;break end
               extra[v.from]=v.to
             end
             amt=math.min(amt,limit-math.abs(f))
           end
           if not cycle and amt>1 then
             a[supply]=a[supply]-amt;b[demand]=b[demand]-amt
             transferred=transferred+amt
             for _,v in ipairs(steps) do
               flows[v.edge.id]=(flows[v.edge.id] or 0)+v.sign*amt
               directed[v.from]=directed[v.from] or {};directed[v.from][v.to]=v.to
             end
           end
         end
       end
       if transferred<=1 then break end
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