package.path = './ElectrifiedMainline/?.lua;' .. package.path
local D=require('scripts.bridge_dispatch_059')
local L=20000000/60
local function approx(a,b)
  assert(math.abs((a or 0)-b)<0.0001,('expected %.6f got %.6f'):format(b,a or 0))
end
local function net(gen,load,battery,charge)
  return {gen=gen or 0,load=load or 0,battery=battery or 0,charge=charge or 0}
end
local function edge(id,a,b) return {id=id,a=a,b=b} end
local function test()
 local e={edge(1,1,2)}
 approx(D.plan({[1]=net(L*2),[2]=net(0,L*2)},e,L)[1],L)
 approx(D.plan({[1]=net(0,L*2),[2]=net(L*2)},e,L)[1],-L)
 approx(D.plan({[1]=net(0,L*2),[2]=net(0,L*2)},e,L)[1],0)
 approx(D.plan({[1]=net(0,0,L),[2]=net(0,L)},e,L)[1],L)
 approx(D.plan({[1]=net(L),[2]=net(0,0,0,L)},e,L)[1],L)
 local ee={edge(1,1,2),edge(2,2,3)}
 local f=D.plan({[1]=net(L),[2]=net(),[3]=net(0,L)},ee,L)
 approx(f[1],L);approx(f[2],L)
 local m=D.balance({primary_output=500,secondary_output=200,solar_output=0,secondary_demand=100,primary_demand=0,accumulator_energy=10,accumulator_capacity=100,tertiary_output=15,tertiary_demand=20},{offer=200,demand=0},{production=450,stored=30,capacity=200,discharge=8,charge=70})
 approx(m.production,500);approx(m.demand,100);approx(m.gen,400);approx(m.battery,15);approx(m.charge,70)
 local n=D.balance({primary_output=0,secondary_output=0,solar_output=0,secondary_demand=0,primary_demand=0,accumulator_energy=0,accumulator_capacity=0,tertiary_output=0,tertiary_demand=0,maximum_production=0,maximum_consumption=0},{},{})
 approx(n.gen,0);approx(n.load,0)
end
test()
math.randomseed(61061)
local scenarios=700
for iteration=1,scenarios do
  local N=3+math.random(0,5)
  local inp={}
  local supply,demand=0,0
  for i=1,N do
    local g,b,l,c=math.random(0,3)*L/4,math.random(0,3)*L/4,math.random(0,3)*L/4,math.random(0,3)*L/4
    if iteration%11==0 then g=0;b=0 end
    inp[i]=net(g,l,b,c)
    supply=supply+g+b;demand=demand+l+c
  end
  local es={};local seen={};local id=0
  for i=1,N do for j=i+1,N do if math.random()<0.36 then
    id=id+1;es[#es+1]=edge(id,i,j)
  end end end
  local flow=D.plan(inp,es,L)
  local netout={}
  for i=1,N do netout[i]=0 end
  for _,e in ipairs(es) do
    local v=flow[e.id] or 0
    assert(v==v and math.abs(v)<=L+0.00001,'per-station 20 MW limit exceeded')
    netout[e.a]=netout[e.a]+v
    netout[e.b]=netout[e.b]-v
  end
  local total=0
  for i=1,N do
    local n=inp[i];local out=netout[i]
    assert(out<=n.gen+n.battery+0.00001,'spontaneous energy at source')
    assert(-out<=n.load+n.charge+0.00001,'excess energy at sink')
    total=total+out
  end
  assert(math.abs(total)<0.00001,'global energy flow does not balance')
  if supply==0 or demand==0 then
    for _,v in pairs(flow) do assert(v==0,'nonzero flow without supply or demand') end
  end
end
print('[LOCAL QA PASS] dispatch: 5 exact cases, balanced flow and caps on '..scenarios..' randomized graphs')