package.path='./ElectrifiedMainline/?.lua;'..package.path
local V=require('scripts.catenary_visual_policy_047')
local power=require('scripts.power_019')
local T=require('scripts.technical_network_046')
local name='em-35kv-catenary-pole-north'
local function n(id,x,y,tx,ty,side,px,py)
 return {id=id,name=name,x=x,y=y,tx=tx,ty=ty,side=side,rail_adjacent=true,rail_id=id,force_name='p',surface_index=1,face_target={x=px or x,y=py or y}}
end
local a=n(2717,22.5,-29.5,.949,.316,1,23.461,-30.067)
local b=n(2778,22.5,-33.5,.981,-.196,-1,21.486,-32.508);a.rail_id=1019;b.rail_id=1019
assert(V.plan({[a.id]=a,[b.id]=b})['2717:2778'])
local c=n(2539,23.5,-12.5,0,1,1,25,-12.5)
local d=n(2516,22.5,-7.5,.981,-.196,-1,23.945,-6.874)
assert(V.plan({[c.id]=c,[d.id]=d})['2516:2539'])
local z=n(1,0,0,1,0,1);local w=n(2,32,0,0,1,-1)
assert(V.plan({z,w})['1:2']);w.x=33;assert(not next(V.plan({z,w})))
w.x=30;w.rail_adjacent=false;assert(not next(V.plan({z,w})))
w.rail_adjacent=true;w.surface_index=2;assert(not next(V.plan({z,w})));w.surface_index=1
w.force_name='other';assert(not next(V.plan({z,w})));w.force_name='p'
local line={}
for i=1,5 do line[i]=n(i,(i-1)*5,0,1,0,1) end
local e=V.plan(line);local count=0
for k in pairs(e) do count=count+1 end
assert(count==4 and e['1:2'] and e['2:3'] and e['3:4'] and e['4:5'])
assert(not e['1:5'] and not e['1:3'])
defines={rail_direction={front=1,back=2},rail_connection_direction={straight=1,left=2,right=3}}
local force={name='p'};local surface={index=1};local rails={}
local function rail(id,x,kind)
 local r={unit_number=id,position={x=x,y=0},valid=true,name=kind or 'em-high-speed-straight-rail',force=force,surface=surface,links={}}
 function r.get_connected_rail(q) return r.links[q.rail_direction] end
 rails[#rails+1]=r;return r
end
local r1,r2,r3=rail(101,0),rail(102,20,'em-curved-high-speed-rail'),rail(103,40)
function surface.find_entities_filtered(f)
 local out={}
 for _,r in ipairs(rails) do if r.valid and (r.position.x-f.position.x)^2+(r.position.y-f.position.y)^2<=f.radius^2 then out[#out+1]=r end end
 return out
end
game={surfaces={[1]=surface},forces={p=force}}
local n1,n2=n(1,0,0,1,0,1),n(2,40,0,0,1,-1);n1.rail_id=101;n2.rail_id=103
r1.links[1]=r2;r2.links[2]=r1
assert(not power.technical_path(n1,n2) and not next(T.plan({n1,n2})))
r2.links[1]=r3;r3.links[2]=r2
assert(power.technical_path(n1,n2).curved)
assert(T.plan({n1,n2})['1:2'])
r2.name='straight-rail';assert(not power.technical_path(n1,n2));r2.name='em-curved-high-speed-rail'
r2.valid=false;r1.links[1]=nil;r3.links[2]=nil
assert(not next(T.plan({n1,n2})))
n2.x=1;n2.rail_id=101;assert(power.technical_path(n1,n2).length==0)
assert(T.plan({n1,n2})['1:2'] and V.plan({n1,n2})['1:2'])
n2.x=28;n2.rail_id=103
assert(V.plan({n1,n2})['1:2'] and not next(T.plan({n1,n2})))
print('047 PASS: logged opposite-side pairs, 32 visual limit, no shortcuts, 40 technical reach, actual HSR traversal, vanilla/broken HSR rejected, same rail accepted')
