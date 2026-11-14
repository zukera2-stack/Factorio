-- Mocked Lua test; not a real Factorio game test.
package.path='./ElectrifiedMainline/?.lua;'..package.path
defines={direction={north=0},rail_direction={front=0,back=1},rail_layer={ground=0,elevated=1}}
local preview=require('scripts.mast_preview_015')
local function loc(x,y,d,layer)
    return {position={x=x,y=y},direction=d,rail_layer=layer or 0}
end
local rail={name='em-high-speed-straight-rail',valid=true,position={x=10,y=20},
    direction=0,unit_number=7,force={name='player'}}
rail.get_rail_end=function(d)
    if d==0 then return {out_signal_location=loc(10,20,0),
        alternative_in_signal_location=loc(2,2,0,1)} end
    return {in_signal_location=loc(30,40,4)}
end
assert(preview.parse_offset(nil)==1 and preview.parse_offset(' ')==1)
assert(preview.parse_offset('1.5')==1.5)
for _,bad in ipairs({'0','4','abc','-1'}) do assert(preview.parse_offset(bad)==nil) end
local c,err,total,skip=preview.candidates(rail,1)
assert(#err==0 and total==3 and skip==1 and #c==4)
local function near(a,b) return math.abs(a-b)<0.000001 end
assert(c[1].side=='L' and near(c[1].base.x,9) and near(c[1].base.y,20) and c[1].face=='east')
assert(c[2].side=='R' and near(c[2].base.x,11) and c[2].face=='west')
assert(c[3].side=='L' and near(c[3].base.y,39) and c[3].face=='south')
assert(c[4].side=='R' and near(c[4].base.y,41) and c[4].face=='north')
local prints,circles,lines,labels,checks={},{},{},{},{}
local surface={
    find_entities_filtered=function(_) return {rail} end,
    can_place_entity=function(args)
        checks[#checks+1]=args
        assert(args.name=='em-35kv-catenary-pole')
        assert(args.direction==0 and args.force==rail.force)
        return args.position.x<20
    end
}
rail.surface=surface
rendering={
    draw_circle=function(args) circles[#circles+1]=args end,
    draw_line=function(args) lines[#lines+1]=args end,
    draw_text=function(args) labels[#labels+1]=args end
}
log=function(_) end
local player={selected=rail,position={x=10,y=20},surface=surface,force=rail.force,
    print=function(v) prints[#prints+1]=v end}
preview.show(player,{parameter='1'})
assert(#checks==4 and #circles==4 and #lines==4 and #labels==4)
assert(#prints==5)
assert(lines[1].to.x==10 and near(lines[1].from.x,9))
assert(circles[1].color.g>0.8 and circles[3].color.r==1)
assert(circles[1].time_to_live==900)
local oldcount=#circles
preview.show(player,{parameter='4'})
assert(#circles==oldcount)
player.selected={name='straight-rail',valid=true}
surface.find_entities_filtered=function(_) return {} end
preview.show(player,{parameter='1'})
assert(#circles==oldcount)
local f=assert(io.open('ElectrifiedMainline/scripts/control.lua','r'))
local control=f:read('*a');f:close()
assert(control:find('local mast_preview015 = require("scripts.mast_preview_015")',1,true))
assert(control:find('mast_preview015.show(player, event)',1,true))
assert(not control:find('then require("scripts.mast_preview_015")',1,true))
print('0.1.15 read-only mast preview mocked geometry: PASS')
