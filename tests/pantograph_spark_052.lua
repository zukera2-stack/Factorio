package.path='./ElectrifiedMainline/?.lua;'..package.path
local M=require("scripts.pantograph_visual_049")
local objects={};local n=0
rendering={get_object_by_id=function(id)return objects[id] end}
function rendering.draw_animation(arg)
 n=n+1;local o={id=n,valid=true,arg=arg};objects[n]=o
 function o.destroy()o.valid=false end
 return o
end
local e={unit_number=42,position={x=10,y=20},surface={index=1},force={name="player"}}
local row={state="down",frame=64}
local enabled,hsr=true,true
local function contact(surface,force,p)
 assert(surface==1 and force=="player")
 if enabled then return {x=p.x,y=p.y,distance=0} end
end
local function rail(_)return hsr end
local function step(t,speed)M.spark(row,e,speed,t,contact,rail)end
step(0,0);assert(n==0)
row.state="up";step(1,0);assert(n==0)
hsr=false;step(2,.1);assert(n==0)
hsr=true;enabled=false;step(3,.1);assert(n==0)
enabled=true;step(4,.1);assert(n==1 and row.contact and row.flash_count==1)
assert(objects[1].arg.time_to_live==12 and objects[1].arg.animation_speed==2 and objects[1].arg.animation=="em-panto-discharge-052")
local h=M.head_offset(64);assert(math.abs(h.x+.98115)<1e-7 and math.abs(h.y+2.8728125)<1e-7)
step(5,-.2);assert(n==1 and objects[1].target.entity==e)
objects[1].valid=false;step(16,.1);assert(n==1)
assert(row.next_flash>=184 and row.next_flash<=604)
step(row.next_flash,.1);assert(n==2)
enabled=false;step(row.last_flash+1,.1);assert(not objects[2].valid and not row.contact)
enabled=true;step(row.last_flash+2,.1);assert(n==2)
step(row.next_flash,-.1);assert(n==3)
row.state="down";step(row.last_flash+1,.1);assert(not objects[3].valid)
row.state="up";step(row.last_flash+31,.1);assert(n==4)
step(row.last_flash+1,0);assert(not objects[4].valid and not row.contact)
print("052 PASS: raised/moving/HSR/actual contact gating, first and delayed flashes, reverse, bounded TTL, stop and contact-loss cleanup")
