-- 0.1.12 rail-following visual contact graph, cosmetic sprites only; no MW transfer.
local M = {}
local geometry = require("scripts.power_topology")
local view = require("scripts.overhead_geometry_012")
local POLE,SUB = "em-35kv-catenary-pole","em-35kv-traction-substation"
local SPAN,RADIUS = 16,3
local RAILS = {"em-high-speed-straight-rail","em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b","em-half-diagonal-high-speed-rail"}
local RAIL_SET = {}
for _,name in pairs(RAILS) do RAIL_SET[name]=true end

function M.ensure_storage()
    storage.em=storage.em or {}
    storage.em.power_019=storage.em.power_019 or {version=3,nodes={},edges={},rail_queue={},sprites={}}
    local s=storage.em.power_019
    s.nodes=s.nodes or {};s.edges=s.edges or {};s.rail_queue=s.rail_queue or {}
    s.sprites=s.sprites or {}
    return s
end
local function edge_key(a,b)
    if a>b then a,b=b,a end
    return tostring(a)..":"..tostring(b)
end
local function delete_edge(s,key)
    local e=s.edges[key]
    if not e then return end
    local ids=e.render_ids or {e.contact_render,e.messenger_render}
    for _,id in pairs(ids) do
        if id then
            local o=rendering.get_object_by_id(id)
            if o and o.valid then o.destroy() end
        end
    end
    s.edges[key]=nil
end
local function clear_sprite(s,id)
    local rid=s.sprites[id]
    if rid then
        local o=rendering.get_object_by_id(rid)
        if o and o.valid then o.destroy() end
    end
    s.sprites[id]=nil
end
local function render_sprite(s,e)
    local id=e.unit_number
    if not id then return end
    clear_sprite(s,id)
    local n=s.nodes[id]
    local face=n and n.face or "east"
    local obj=rendering.draw_sprite{
        sprite="em-35kv-facing-"..face,
        surface=e.surface,
        target={entity=e,offset={0,-2.53125}},
        render_layer="object",
    }
    s.sprites[id]=obj.id
end
local function rail_tangent(e)
    local rails=e.surface.find_entities_filtered{
        position=e.position,radius=RADIUS,name=RAILS,force=e.force}
    local best,d2=nil,math.huge
    for _,r in pairs(rails) do
        local x,y=e.position.x-r.position.x,e.position.y-r.position.y
        local v=x*x+y*y
        if r.valid and v<d2 then best,d2=r,v end
    end
    if not best then return nil end
    local dx,dy=e.position.x-best.position.x,e.position.y-best.position.y
    local tx,ty
    if best.name=="em-high-speed-straight-rail" or d2<0.64 then
        local angle=(best.direction%16)*math.pi/8
        tx,ty=math.sin(angle),-math.cos(angle)
    else
        local length=math.sqrt(d2)
        tx,ty=-dy/length,dx/length
    end
    if tx < -0.000001 or (math.abs(tx)<0.000001 and ty<0) then
        tx,ty=-tx,-ty
    end
    local cross=tx*dy-ty*dx
    local side=cross>0.25 and 1 or (cross < -0.25 and -1 or 0)
    return tx,ty,side,best
end
local function register(s,e)
    local id=e.unit_number
    if not id then return end
    local n={id=id,name=e.name,x=e.position.x,y=e.position.y,
        surface_index=e.surface.index,force_name=e.force.name,
        rail_adjacent=e.name==SUB}
    if e.name==POLE then
        local rail
        n.tx,n.ty,n.side,rail=rail_tangent(e)
        n.rail_adjacent=n.tx~=nil
        n.rail_id=rail and rail.unit_number or nil
        n.face=view.face(e.position,rail and rail.position)
    end
    s.nodes[id]=n
end
local function resolve(s,id)
    local n=s.nodes[id]
    if not n then return nil end
    local e=game.get_entity_by_unit_number(id)
    if e and e.valid and e.name==n.name and
        e.surface.index==n.surface_index and e.force.name==n.force_name then
        return e
    end
end
local function corridor(surface,force,a,b)
    for _,t in pairs({0.25,0.5,0.75}) do
        if surface.count_entities_filtered{
            position={x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t},
            radius=RADIUS,name=RAILS,force=force,limit=1}==0 then
            return false
        end
    end
    return true
end
local function draw(s,a,b,kind,corner)
    local key=edge_key(a.unit_number,b.unit_number)
    if s.edges[key] then return end
    local renders={}
    local function segment(from,to,color,width)
        local o=rendering.draw_line{
            surface=a.surface, from=from,to=to,
            color=color,width=width}
        renders[#renders+1]=o.id
    end
    if kind=="feeder" then
        segment({entity=a,offset={0,-0.5}},
            {entity=b,offset={0,-0.5}},
            {r=0.35,g=0.8,b=1,a=0.9},1.5)
    else
        local na,nb=s.nodes[a.unit_number],s.nodes[b.unit_number]
        local from=view.wire_anchor(na,0.5)
        local to=view.wire_anchor(nb,0.5)
        -- Direction from the adjacent railway is authoritative, not the R key.
        local A={x=from.x,y=from.y,tx=na.tx,ty=na.ty}
        local B={x=to.x,y=to.y,tx=nb.tx,ty=nb.ty}
        local pts=corner and view.bezier(A,B,8) or {A,B}
        for i=1,#pts-1 do
            local x,y=pts[i],pts[i+1]
            segment(x,y,{r=0.57,g=0.60,b=0.62,a=0.95},1.5)
            segment({x=x.x,y=x.y-0.20},{x=y.x,y=y.y-0.20},
                {r=0.38,g=0.43,b=0.48,a=0.85},1.0)
        end
    end
    s.edges[key]={a=a.unit_number,b=b.unit_number,kind=kind,
        render_ids=renders,corner=corner or false}
end

-- This is deliberately *not* RailSignalPrototype: no changes to train blocks.
-- Check real rail connectivity, so nearby but independent tracks do not join.
local function connected_rail_path(a,b)
    if not (a.rail_id and b.rail_id) then return false end
    if a.rail_id==b.rail_id then return true end
    -- Resolve rails spatially: unlike our poles, third-party rail prototypes may
    -- not carry the get-by-unit-number flag. A stored number is just an identity.
    local surface=game.surfaces[a.surface_index]
    local force=game.forces[a.force_name]
    if not (surface and force) then return false end
    local start
    for _,candidate in pairs(surface.find_entities_filtered{
        position={x=a.x,y=a.y},radius=RADIUS,name=RAILS,force=force}) do
        if candidate.unit_number==a.rail_id then start=candidate;break end
    end
    if not (start and start.valid and RAIL_SET[start.name]) then return false end
    local queue={start};local seen={[start.unit_number]=true};local index=1
    local directions={defines.rail_direction.front,defines.rail_direction.back}
    local turns={defines.rail_connection_direction.straight,
        defines.rail_connection_direction.left,defines.rail_connection_direction.right}
    while index<=#queue and index<=96 do
        local rail=queue[index];index=index+1
        for _,d in pairs(directions) do
            for _,c in pairs(turns) do
                local other=rail.get_connected_rail{
                    rail_direction=d,rail_connection_direction=c}
                if other and other.valid and RAIL_SET[other.name]
                    and other.unit_number and not seen[other.unit_number]
                    and other.force.name==a.force_name
                    and other.surface.index==a.surface_index then
                    if other.unit_number==b.rail_id then return true end
                    seen[other.unit_number]=true
                    queue[#queue+1]=other
                end
            end
        end
    end
    return false
end

local function curve_corridor(surface,force,a,b)
    local A={x=a.x,y=a.y,tx=a.tx,ty=a.ty}
    local B={x=b.x,y=b.y,tx=b.tx,ty=b.ty}
    local pts=view.bezier(A,B,8)
    for i=2,#pts-1 do
        if surface.count_entities_filtered{
            position=pts[i],radius=RADIUS+1,name=RAILS,force=force,limit=1}==0 then
            return false
        end
    end
    return true
end

local function build_corner_edges(s,touched)
    local degrees={}
    for _,edge in pairs(s.edges) do
        if edge.kind=="contact" then
            degrees[edge.a]=(degrees[edge.a] or 0)+1
            degrees[edge.b]=(degrees[edge.b] or 0)+1
        end
    end
    local candidates={}
    for id,e in pairs(touched) do
        local a=s.nodes[id]
        if a and a.name==POLE and a.rail_adjacent and (degrees[id] or 0)<2 then
            for _,other in pairs(e.surface.find_entities_filtered{
                position=e.position,radius=SPAN*1.45,name=POLE,force=e.force}) do
                local b=s.nodes[other.unit_number]
                if b and (degrees[b.id] or 0)<2
                    and not s.edges[edge_key(id,b.id)] then
                    local possible,dist=view.corner_candidate(a,b,SPAN)
                    if possible and connected_rail_path(a,b)
                        and curve_corridor(e.surface,e.force,a,b) then
                        candidates[#candidates+1]={a=id,b=b.id,dist=dist}
                    end
                end
            end
        end
    end
    table.sort(candidates,function(x,y)
        if x.dist~=y.dist then return x.dist<y.dist end
        if x.a~=y.a then return x.a<y.a end
        return x.b<y.b
    end)
    for _,c in pairs(candidates) do
        local key=edge_key(c.a,c.b)
        if not s.edges[key] and (degrees[c.a] or 0)<2
            and (degrees[c.b] or 0)<2 then
            local a,b=resolve(s,c.a),resolve(s,c.b)
            if a and b then
                draw(s,a,b,"contact",true)
                degrees[c.a]=(degrees[c.a] or 0)+1
                degrees[c.b]=(degrees[c.b] or 0)+1
            end
        end
    end
end

local function build_edges(s,touched)
    local choices,checks={},{}
    local function select_neighbours(e)
        local id=e.unit_number
        if choices[id] then return choices[id][1],choices[id][2] end
        local a=s.nodes[id]
        if not (a and a.name==POLE and a.rail_adjacent) then
            choices[id]={};return nil,nil
        end
        local candidates={}
        for _,other in pairs(e.surface.find_entities_filtered{
            position=e.position,radius=SPAN,name=POLE,force=e.force}) do
            if other.valid and s.nodes[other.unit_number] then
                candidates[#candidates+1]=s.nodes[other.unit_number]
            end
        end
        local function check(x,y)
            local key=edge_key(x.id,y.id)
            if checks[key]==nil then
                checks[key]=corridor(e.surface,e.force,x,y)
            end
            return checks[key]
        end
        local f,b=geometry.choose(a,candidates,SPAN,check)
        choices[id]={f,b}
        return f,b
    end
    for id,e in pairs(touched) do
        local n=s.nodes[id]
        if n and n.name==POLE and n.rail_adjacent then
            local f,b=select_neighbours(e)
            for _,candidate in pairs({f,b}) do
                local other=candidate and resolve(s,candidate.id)
                if other then
                    local of,ob=select_neighbours(other)
                    if (of and of.id==id) or (ob and ob.id==id) then
                        draw(s,e,other,"contact")
                    end
                end
            end
        elseif n and n.name==SUB then
            local best,nearest=SPAN*SPAN+1,nil
            for _,pole in pairs(e.surface.find_entities_filtered{
                position=e.position,radius=SPAN,name=POLE,force=e.force}) do
                local p=s.nodes[pole.unit_number]
                if p and p.rail_adjacent then
                    local dx,dy=pole.position.x-e.position.x,pole.position.y-e.position.y
                    local d2=dx*dx+dy*dy
                    if d2<best or (d2==best and nearest
                        and pole.unit_number<nearest.unit_number) then
                        best,nearest=d2,pole
                    end
                end
            end
            if nearest then draw(s,e,nearest,"feeder") end
        end
    end
    build_corner_edges(s,touched)
end
local function refresh(surface,force,pos)
    local s=M.ensure_storage()
    local touched={}
    for _,e in pairs(surface.find_entities_filtered{
        position=pos,radius=SPAN*2+2,name={POLE,SUB},force=force}) do
        if e.valid and s.nodes[e.unit_number] then
            register(s,e);touched[e.unit_number]=e
        if e.name==POLE then render_sprite(s,e) end
        end
    end
    -- A touched pole may have a feeder from a substation just outside
    -- the refresh circle. Include that substation before removing edges.
    local additional={}
    for _,e in pairs(touched) do
        if e.name==POLE then
            for _,sub in pairs(surface.find_entities_filtered{
                position=e.position,radius=SPAN,name=SUB,force=force}) do
                if sub.valid and s.nodes[sub.unit_number] then
                    additional[sub.unit_number]=sub
                end
            end
        end
    end
    for id,e in pairs(additional) do
        register(s,e);touched[id]=e
    end
    local stale={}
    for key,edge in pairs(s.edges) do
        if touched[edge.a] or touched[edge.b] then stale[#stale+1]=key end
    end
    for _,key in pairs(stale) do delete_edge(s,key) end
    build_edges(s,touched)
end
function M.rebuild_all()
    local s=M.ensure_storage()
    for key in pairs(s.edges) do delete_edge(s,key) end
    for id in pairs(s.sprites) do clear_sprite(s,id) end
    s.nodes={};s.edges={};s.rail_queue={};s.sprites={}
    local all={}
    for _,surface in pairs(game.surfaces) do
        for _,e in pairs(surface.find_entities_filtered{name={POLE,SUB}}) do
            if e.valid and e.unit_number then
                register(s,e);all[e.unit_number]=e
                if e.name==POLE then render_sprite(s,e) end
            end
        end
    end
    s.version=3
    build_edges(s,all)
    log("[ElectrifiedMainline][35kv] rebuilt rail-following visual graph (schema 3)")
end
function M.on_built(event)
    local e=event.entity
    if not (e and e.valid and (e.name==POLE or e.name==SUB)) then return end
    local s=M.ensure_storage()
    register(s,e)
    if e.name==POLE and not s.nodes[e.unit_number].rail_adjacent then
        local player=event.player_index and game.get_player(event.player_index)
        if player and player.valid then player.print({"message.em-35kv-no-rail"}) end
    end
    refresh(e.surface,e.force,e.position)
end
function M.on_removed(event)
    local e=event.entity
    if not (e and e.valid and (e.name==POLE or e.name==SUB)) then return end
    local s=M.ensure_storage()
    s.nodes[e.unit_number]=nil
    clear_sprite(s,e.unit_number)
    local stale={}
    for key,edge in pairs(s.edges) do
        if edge.a==e.unit_number or edge.b==e.unit_number then
            stale[#stale+1]=key
        end
    end
    for _,key in pairs(stale) do delete_edge(s,key) end
    -- The entity is still alive during removal; missing node excludes it.
    refresh(e.surface,e.force,e.position)
end
function M.on_rail_changed(e)
    if not (e and e.valid and RAIL_SET[e.name]) then return end
    local s=M.ensure_storage()
    local x,y=e.position.x,e.position.y
    local key=tostring(e.surface.index)..":"..e.force.name..":"..
        tostring(math.floor(x/4))..":"..tostring(math.floor(y/4))
    s.rail_queue[key]={surface_index=e.surface.index,
        force_name=e.force.name,position={x=x,y=y},tick=game.tick+1}
end
function M.on_tick(tick)
    local s=M.ensure_storage()
    if not next(s.rail_queue) then return end
    local buckets={}
    for key,change in pairs(s.rail_queue) do
        if tick>=change.tick then
            s.rail_queue[key]=nil
            local surface=game.surfaces[change.surface_index]
            local force=game.forces[change.force_name]
            if surface and force then
                for _,pole in pairs(surface.find_entities_filtered{
                    position=change.position,radius=RADIUS+2,
                    name=POLE,force=force}) do
                    local bucket=tostring(surface.index)..":"..force.name..":"..
                        tostring(math.floor(pole.position.x/16))..":"..
                        tostring(math.floor(pole.position.y/16))
                    buckets[bucket]={surface=surface,force=force,
                        position={x=pole.position.x,y=pole.position.y}}
                end
            end
        end
    end
    for _,entry in pairs(buckets) do
        refresh(entry.surface,entry.force,entry.position)
    end
end
function M.status(player)
    local s=M.ensure_storage()
    local poles,subs,contacts,feeders,stale,turns=0,0,0,0,0,0
    for id,n in pairs(s.nodes) do
        if n.name==POLE then poles=poles+1 else subs=subs+1 end
        if not resolve(s,id) then stale=stale+1 end
    end
    for _,e in pairs(s.edges) do
        if e.kind=="contact" then
            contacts=contacts+1
            if e.corner then turns=turns+1 end
        elseif e.kind=="feeder" then feeders=feeders+1 end
    end
    player.print("[ElectrifiedMainline][35kv] poles="..poles..
        " substations="..subs.." contact_spans="..contacts..
        " feeder_lines="..feeders.." curved_spans="..turns..
        " oriented_sprites="..tostring(s.sprites and (function()
            local count=0;for _ in pairs(s.sprites) do count=count+1 end
            return count end)() or 0).." stale_nodes="..stale..
        " energized=NO transfer_MW=0 (visual only)")
end
return M
