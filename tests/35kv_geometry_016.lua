-- Lua 5.2 mocked test for the read-only 0.1.16 preview.
package.path='./ElectrifiedMainline/?.lua;'..package.path
defines={direction={north=0},rail_direction={front=0,back=1},
    rail_layer={ground=0,elevated=1}}
local g=require('scripts.mast_geometry_016')
local function loc(x,y,d,layer)
    return {position={x=x,y=y},direction=d,rail_layer=layer or 0}
end
local rail={name='em-high-speed-straight-rail',valid=true,unit_number=17,
    position={x=10,y=10},force={name='player'}}
rail.get_rail_end=function(d)
    if d==0 then return {location=loc(10,10,0)} end
    return {location=loc(10,14,8)}
end
local eq=function(a,b) return math.abs(a-b)<0.000001 end
local offset,index=g.parse_options(nil)
assert(offset==1.5 and index==nil)
offset,index=g.parse_options('1.5 2')
assert(offset==1.5 and index==2)
for _,str in ipairs({'0','4','inf','nan','abc','1.5 0','1.5 9','1.5 2.5','1.5 1 2'}) do
    assert(g.parse_options(str)==nil,'accepted invalid arguments '..str)
end
local candidates,errors,ends,skipped,dups=g.collect(rail,1.5)
assert(#candidates==4 and #errors==0 and ends==2 and skipped==0 and dups==0)
assert(candidates[1].side=='L' and eq(candidates[1].position.x,8.5))
assert(eq(candidates[1].position.y,10) and candidates[1].face=='east')
assert(candidates[2].side=='R' and eq(candidates[2].position.x,11.5)
    and candidates[2].face=='west')
assert(eq(candidates[3].position.x,11.5) and eq(candidates[3].position.y,14))
assert(candidates[3].face=='west')
assert(candidates[4].face=='east')
-- Curved local rail ends and diagonal 45 degree orientation require no
-- signal locations; candidates are derived from the native rail-end tangent.
rail.name='em-curved-high-speed-rail'
rail.get_rail_end=function(d)
    if d==0 then return {location=loc(3,4,2)} end
    return {location=loc(6,7,6)}
end
local curved,err=g.collect(rail,1.5)
assert(#curved==4 and #err==0)
assert(eq(curved[1].position.x,3-1.5*math.cos(math.pi/4)))
assert(eq(curved[1].position.y,4-1.5*math.sin(math.pi/4)))
assert(curved[1].face=='southeast')
rail.name='em-half-diagonal-high-speed-rail'
local diagonal=g.collect(rail,1.5)
assert(#diagonal==4)
rail.get_rail_end=function(d)
    if d==0 then return {location=loc(0,0,0)} end
    return {location=loc(0,0,0)}
end
local dup,_,_,_,merged=g.collect(rail,1.5)
assert(#dup==2 and merged==2,'same-base rail ends must not overdraw')
rail.get_rail_end=function(d)
    if d==0 then return {location=loc(0,0,0,1)} end
    return {location=loc(1,1,0)}
end
local ground,_,n,sk=g.collect(rail,1.5)
assert(#ground==2 and n==1 and sk==1)
rail.name='em-high-speed-straight-rail'
rail.get_rail_end=function(d)
    if d==0 then return {location=loc(10,10,0)} end
    return {location=loc(10,14,8)}
end
local counts={circle=0,text=0,line=0,sprite=0}
local sprites,lines,prints,checks={},{},{},0
rendering={
    draw_circle=function(args) counts.circle=counts.circle+1 end,
    draw_text=function(args) counts.text=counts.text+1 end,
    draw_line=function(args) counts.line=counts.line+1;lines[#lines+1]=args end,
    draw_sprite=function(args) counts.sprite=counts.sprite+1;sprites[#sprites+1]=args end,
}
local surface={
    find_entities_filtered=function(_) return {rail} end,
    can_place_entity=function(args)
        checks=checks+1
        assert(args.name=='em-35kv-catenary-pole' and args.force==rail.force)
        return args.position.x<10
    end
}
rail.surface=surface
log=function(_) end
local player={selected=rail,position={x=8,y=10},force=rail.force,
    surface=surface,print=function(x) prints[#prints+1]=x end}
g.show(player,{parameter='1.5'})
assert(counts.circle==4 and counts.text==4 and counts.line==1 and counts.sprite==1)
assert(checks==4)
assert(sprites[1].sprite=='em-35kv-facing-east')
assert(eq(sprites[1].target.x,8.5) and eq(sprites[1].target.y,10-2.53125))
assert(sprites[1].time_to_live==900)
assert(eq(lines[1].to.x,10) and eq(lines[1].to.y,10))
local before=counts.circle
g.show(player,{parameter='1.5 2'}) -- explicitly blocked candidate
assert(counts.circle==before+4 and counts.sprite==1,
    'explicit blocked candidate must not display a mast sprite')
g.show(player,{parameter='1.5 9'})
assert(counts.circle==before+4,'invalid index must not draw')
g.show(player,{parameter='4'})
assert(counts.circle==before+4,'invalid offset must not draw')
player.selected={name='straight-rail',valid=true}
surface.find_entities_filtered=function(_) return {} end
g.show(player,{parameter='1.5'})
assert(counts.circle==before+4,'vanilla-only region must not draw')
local f=assert(io.open('ElectrifiedMainline/scripts/control.lua','r'))
local source=f:read('*a');f:close()
assert(source:find('local mast_geometry016 = require("scripts.mast_geometry_016")',1,true))
assert(source:find('mast_geometry016.show(player, event)',1,true))
assert(not source:find('then require("scripts.mast_geometry_016")',1,true))
print('0.1.16 rail-end candidate geometry and single-ghost preview: PASS')
