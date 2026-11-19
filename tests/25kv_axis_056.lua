package.path='./ElectrifiedMainline/?.lua;'..package.path
local M=require('scripts.catenary_axis_056')
local rows={}
local function r(id,l) rows[id]={length=l,ends={[-1]={},[1]={}}};rows[id].links=function(s) return rows[id].ends[s] end end
local function link(a,sa,b,sb) table.insert(rows[a].ends[sa],{id=b,sign=-sb});table.insert(rows[b].ends[sb],{id=a,sign=-sa}) end
for i=1,6 do r(i,10) end
link(1,1,2,-1);link(2,1,3,-1);link(4,1,5,-1);link(5,1,6,-1)
local function p(rail,s,x,y) return {rail=rail,s=s,x=x,y=y} end
local placements={[1]=p(1,2,2,0),[2]=p(2,5,15,0),[3]=p(3,8,28,0),[4]=p(4,2,2,4),[5]=p(5,5,15,4),[6]=p(6,8,28,4)}
local function plan() return M.select(placements,function(id) return rows[id] end) end
local e=plan();assert(e['1:2'] and e['2:3'] and e['4:5'] and e['5:6'])
local n=0;for _ in pairs(e) do n=n+1 end;assert(n==4)
rows[2].ends[1]={};rows[3].ends[-1]={};e=plan();assert(not e['2:3'] and e['4:5'])
link(2,1,3,-1);placements[2]=nil;e=plan();assert(e['1:3'])
placements[3]=p(3,8,2,4);e=plan();assert(not e['1:3'],'loop/parallel shortcut')
local points,length=M.polyline({position={x=0,y=0},direction=4},{position={x=8,y=3},direction=6})
local x=M.project({x=4,y=1},points);assert(length>8 and x.s>0 and x.s<length)
-- Pure attachment policy: no unit-number tie breaker across separate paths.
local function candidate(id,s,x,y,dist) return {rail=id,s=s,x=x,y=y,d2=dist*dist} end
local function getrow(id) return rows[id] end
local a,b=candidate(1,5,5,0,2),candidate(4,5,5,4,2)
local p,status=M.choose_attachment({a,b},getrow);assert(not p and status=="ambiguous")
p,status=M.choose_attachment({b,a},getrow);assert(not p and status=="ambiguous")
local near=candidate(4,5,5,4,2.04)
p,status=M.choose_attachment({near,a},getrow);assert(not p and status=="ambiguous")
local far=candidate(4,5,5,4,2.1)
p,status=M.choose_attachment({far,a},getrow);assert(p==a and status=="attached")
local j1,j2=candidate(1,10,10,0,1.5),candidate(2,0,10,0,1.5)
p,status=M.choose_attachment({j2,j1},getrow);assert(p==j1 and status=="attached")
local crossing=candidate(4,0,10,0,1.5)
p,status=M.choose_attachment({crossing,j1},getrow);assert(not p and status=="ambiguous")
p,status=M.choose_attachment({},getrow);assert(not p and status=="detached")
print('056 axis PASS: parallel paths independent; nearest mast per direction; gap; restoration; no loop shortcut; curve projection')
