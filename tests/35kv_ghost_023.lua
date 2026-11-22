-- Offline mocked ghost rendering regression. Never treats CI as Factorio gameplay.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local actual_faces=0
local mast034=require("scripts.mast_visual_034")
package.loaded["scripts.power_019"]={facing_at=function(_) actual_faces=actual_faces+1;return "south" end,
 preview_at=function(_) return {rail_adjacent=true,face="south"},{} end}
storage={}
log=function(_) end -- Factorio global; mocked by unit tests.
local objects,drawn={},{}
local next_id=0
rendering={
    get_object_by_id=function(id) return objects[id] end,
    draw_sprite=function(spec)
        next_id=next_id+1
        local obj={id=next_id,valid=true,config=spec}
        function obj.destroy() obj.valid=false end
        objects[next_id]=obj;drawn[#drawn+1]=obj
        return obj
    end
}
local rail_surface={index=1}
local ghost={
    valid=true,name="entity-ghost",ghost_name="em-35kv-catenary-pole",
    position={x=1.5,y=2.5},force={name="player"},surface=rail_surface
}
local ordinary={valid=true,name="em-35kv-catenary-pole",position=ghost.position,
    force=ghost.force,surface=rail_surface}
rail_surface.find_entities_filtered=function(filter)
    assert(filter.name=="entity-ghost")
    if filter.ghost_name=="em-35kv-catenary-pole" then return {ghost} end
    assert(filter.ghost_name=="em-35kv-catenary-pole-north")
    return {}
end
game={surfaces={[1]=rail_surface}}
local M=require("scripts.ghost_mast_023")
assert(not M.on_built(ordinary))
assert(M.on_built(ghost))
assert(#drawn==1 and actual_faces==1)
local draw=drawn[1].config
assert(draw.sprite=="em-35kv-facing-south")
assert(draw.render_layer=="higher-object-above")
assert(draw.tint.a>0 and draw.tint.a<1)
assert(draw.target.entity==ghost and draw.target.offset[2]==mast034.cantilever_shift(ghost.ghost_name))
assert(M.on_built(ghost) and #drawn==1,"ghost must not get duplicate render")
M.rebuild_all()
assert(#drawn==2 and drawn[1].valid==false and drawn[2].valid)
assert(M.on_removed(ghost) and drawn[2].valid==false)
assert(not M.on_removed(ordinary))
assert(M.on_built(ghost) and #drawn==3)
-- Factorio destroys entity-targeted render when a construction bot revives ghost.
drawn[3].valid=false; ghost.valid=false
M.on_tick(1800)
assert(next(storage.em.ghost_visual_023.sprites)==nil)
assert(not M.on_built(ghost))
local northGhost={valid=true,name="entity-ghost",ghost_name="em-35kv-catenary-pole-north",
  position={x=3.5,y=2.5},force=ghost.force,surface=ghost.surface}
assert(M.on_built(northGhost))
assert(drawn[#drawn].config.target.offset[2]==mast034.cantilever_shift(northGhost.ghost_name))
assert(M.on_removed(northGhost))
local src=assert(io.open("ElectrifiedMainline/scripts/control.lua")):read("*a")
assert(src:find("ghost_visual023.on_built(entity)",1,true))
assert(src:find("ghost_visual023.rebuild_all()",1,true))
assert(src:find("ghost_visual023.on_removed(event.ghost)",1,true))
local proto=assert(io.open("ElectrifiedMainline/prototypes/power_019.lua")):read("*a")
assert(proto:find('catenary.placeable_position_visualization = nil',1,true))
-- The native ghost construction contract stays the same across art sets,
-- but current 0.1.42 uses reviewed 039 shaft, arm and icon assets.
local info=assert(io.open("ElectrifiedMainline/info.json")):read("*a")
if info:find('"version": "0.1.42"',1,true) or info:find('"version": "0.1.43"',1,true) or info:find('"version": "0.1.44"',1,true) or info:find('"version": "0.1.45"',1,true) or info:find('"version": "0.1.46"',1,true) or info:find('"version": "0.1.47"',1,true) or info:find('"version": "0.1.48"',1,true) or info:find('"version": "0.1.49"',1,true) or info:find('"version": "0.1.50"',1,true) or info:find('"version": "0.1.51"',1,true) or info:find('"version": "0.1.52"',1,true) or info:find('"version": "0.1.53"',1,true) or info:find('"version": "0.1.54"',1,true) or info:find('"version": "0.1.55"',1,true) or info:find('"version": "0.1.56"',1,true) or info:find('"version": "0.1.57"',1,true) or info:find('"version": "0.1.58"',1,true) or info:find('"version": "0.1.59"',1,true) or (info:find('"version": "0.1.60"',1,true) or (info:find('"version": "0.1.61"',1,true) or (info:find('"version": "0.1.62"',1,true) or (info:find('"version": "0.1.63"',1,true) or info:find('"version": "0.1.64"',1,true))))) then
    assert(proto:find('pole-south-039.png',1,true))
    assert(proto:find('pole-north-039.png',1,true))
    assert(proto:find('pole-arm-south-039.png',1,true))
    assert(proto:find('25kv-south-039.png',1,true))
    assert(proto:find('25kv-north-039.png',1,true))
else
    assert(proto:find('pole-native-mast-024.png',1,true))
    assert(proto:find('pole-arm-south-024.png',1,true))
    assert(proto:find("35kv-mast-south-icon-64.png",1,true))
end
local cursor=assert(io.open("ElectrifiedMainline/scripts/catenary_cursor_018.lua")):read("*a")
assert(cursor:find("rendering.draw_circle",1,true))
assert(not cursor:find("rendering.draw_rectangle",1,true))
print("0.1.23 ghost & visual cursor mock PASS; Factorio gameplay UNVERIFIED")
