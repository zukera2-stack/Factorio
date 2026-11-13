-- ElectrifiedMainline 0.1.12 - rail-aware visual layer; signal-free.
local M={}
local geometry=require("scripts.power_topology")
local function destroy(id)
    if not id then return end
    local obj=rendering.get_object_by_id(id)
    if obj and obj.valid then obj.destroy() end
end
function M.destroy_edge(edge)
    for _,id in pairs(edge.renders or {}) do destroy(id) end
end
function M.delete_arm(s,id)
    s.arm_renders=s.arm_renders or {}
    local old=s.arm_renders[id]
    if old then destroy(old.render_id) end
    s.arm_renders[id]=nil
end
function M.clear_arms(s)
    for id in pairs(s.arm_renders or {}) do M.delete_arm(s,id) end
end
function M.update_arm(s,e)
    s.arm_renders=s.arm_renders or {}
    local n=s.nodes[e.unit_number]
    if not (n and n.name=="em-35kv-catenary-pole") then return end
    local orientation=n.nx and geometry.sprite_orientation(n.nx,n.ny) or nil
    local old=s.arm_renders[n.id]
    if old and orientation and math.abs(old.orientation-orientation)<0.0001 then
        local object=rendering.get_object_by_id(old.render_id)
        if object and object.valid then return end
    end
    M.delete_arm(s,n.id)
    if not orientation then return end
    -- This render does not create a signal, a rail block or a second entity.
    local object=rendering.draw_sprite{
        sprite="sprite.em-35kv-cantilever",
        surface=e.surface,
        target={entity=e,offset={0,-4.28125}},
        orientation=orientation,render_layer="higher-object-above",tall=true,
    }
    s.arm_renders[n.id]={render_id=object.id,orientation=orientation}
end
function M.corridor(surface,force,a,b,rails,radius)
    local path=geometry.path(a,b,8)
    for _,i in ipairs({3,5,7}) do
        local p=path[i]
        if surface.count_entities_filtered{
            position={x=p.x,y=p.y},radius=radius+1,
            name=rails,force=force,limit=1}==0 then return false end
    end
    return true
end
function M.draw_contact(s,a,b)
    local edge={a=a.unit_number,b=b.unit_number,kind="contact",renders={}}
    local path=geometry.path(s.nodes[a.unit_number],s.nodes[b.unit_number],8)
    for layer=1,2 do
        local drop=layer==1 and 0 or -0.20
        for i=1,#path-1 do
            local p,q=path[i],path[i+1]
            local dx,dy=q.x-p.x,q.y-p.y
            local len=math.sqrt(dx*dx+dy*dy)
            if len>0.01 then
                local object=rendering.draw_sprite{
                    sprite="sprite.em-35kv-contact-wire-texture",
                    surface=a.surface,
                    target={x=(p.x+q.x)/2,y=(p.y+q.y)/2+drop},
                    orientation=geometry.sprite_orientation(dx/len,dy/len),
                    x_scale=len/8,y_scale=layer==1 and 0.75 or 0.52,
                    tint=layer==1 and {r=0.88,g=0.79,b=0.61,a=1}
                        or {r=0.68,g=0.77,b=0.83,a=0.9},
                    render_layer="wires",
                }
                edge.renders[#edge.renders+1]=object.id
            end
        end
    end
    return edge
end
return M
