-- Exact differential tests on simulated rail graphs. Not native engine tests.
local old=os.getenv('EM087_BASE_SCRIPTS') or '/mnt/data/em087/target/scripts/'
local new=os.getenv('EM087_NEW_SCRIPTS') or '/mnt/data/em087b/target/scripts/'
local limits=assert(loadfile(old..'catenary_limits_029.lua'))()
local mock={}
local env=setmetatable({require=function(name) if name=='scripts.catenary_limits_029' then return limits end return {} end,
  defines={rail_direction={front=0,back=1},rail_connection_direction={straight=0,left=1,right=2}},game=mock},{__index=_G})
local oldpower=assert(loadfile(old..'power_019.lua','t',env))()
local newpower=assert(loadfile(new..'power_019.lua','t',env))()
local olddispatch=assert(loadfile(old..'bridge_dispatch_059.lua'))()
local newdispatch=assert(loadfile(new..'bridge_dispatch_059.lua'))()
math.randomseed(870088)
local railQueries,plans,dispatchCases=0,0,0
local function same(a,b,where)
  assert((a==nil)==(b==nil),'nil mismatch '..where)
  if a then assert(a.length==b.length and a.curved==b.curved,'path mismatch '..where) end
end
for case=1,200 do
  local count=(case%5==0) and 240 or 35
  local surface={index=1,valid=true};local force={name='player'};local rails,nodes,lookup={},{},{}
  mock.surfaces={[1]=surface};mock.forces={player=force}
  for i=1,count do
    local r={unit_number=i,valid=true,name=(i%7==0 and 'em-curved-high-speed-rail' or 'em-high-speed-straight-rail'),position={x=math.random(0,24),y=math.random(0,24)},force=force,surface=surface,links={}}
    r.get_connected_rail=function(q) return r.links[q.rail_direction*3+q.rail_connection_direction+1] end
    rails[i]=r;nodes[i]={id=i,rail_id=i,x=r.position.x,y=r.position.y,force_name=force.name,surface_index=1,rail_adjacent=true,name='em-35kv-catenary-pole'}
  end
  surface.find_entities_filtered=function(q)
    local result={};for _,r in ipairs(rails) do if r.valid and (r.position.x-q.position.x)^2+(r.position.y-q.position.y)^2<=q.radius^2 then result[#result+1]=r end end;return result
  end
  for i,r in ipairs(rails) do
    if i>1 then r.links[1]=rails[i-1] end
    if i<count then r.links[4]=rails[i+1] end
    for _,slot in ipairs({2,3,5,6}) do if math.random()<0.55 then r.links[slot]=rails[math.random(count)] end end
  end
  for round=1,2 do
    if round==2 then -- graph changed; new planning phase must never reuse previous result
      for k=1,math.floor(count/5) do rails[math.random(count)].valid=false end
    end
    local oc,nc={starts={},neighbours={}},{starts={},neighbours={}}
    for j=1,30 do
      local a=nodes[math.random(count)]
      for k=1,12 do
        local b=nodes[math.random(count)]
        local oldres=oldpower.technical_path(a,b,oc);local newres=newpower.technical_path(a,b,nc)
        same(oldres,newres,case..'/'..round..'/'..j..'/'..k);railQueries=railQueries+1
      end
    end
    plans=plans+1
  end
end
for case=1,1000 do
  local count=math.random(2,45);local input,edges={},{}
  for i=1,count do input[i]={gen=math.random(0,4)*1000,load=math.random(0,4)*1000,battery=math.random(0,4)*1000,charge=math.random(0,4)*1000} end
  for i=1,count do for j=i+1,count do if math.random()<0.07 then edges[#edges+1]={id=#edges+1,a=i,b=j} end end end
  local a=olddispatch.plan(input,edges,3333);local b=newdispatch.plan(input,edges,3333)
  for k,v in pairs(a) do assert(b[k]==v,'dispatch mismatch '..case..'/'..k) end
  for k,v in pairs(b) do assert(a[k]==v,'extra dispatch '..case..'/'..k) end
  dispatchCases=dispatchCases+1
end
print('DIFFERENTIAL PASS rail_queries='..railQueries..' graph_phases='..plans..' dispatch_cases='..dispatchCases)
