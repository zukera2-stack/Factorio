-- 0.1.10 rail-oriented visual contact graph; NO energy transfer.
local M = {}
local geometry = require("scripts.power_topology")
local visuals = require("scripts.catenary_visuals_012")
local POLE,SUB = "em-35kv-catenary-pole","em-35kv-traction-substation"
local SPAN,RADIUS = 16,3
local RAILS = {"em-high-speed-straight-rail","em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b","em-half-diagonal-high-speed-rail"}
local RAIL_SET = {}
for _,name in pairs(RAILS) do RAIL_SET[name]=true end

function M.ensure_storage()
    storage.em=storage.em or {}
    storage.em.power_019=storage.em.power_019 or {version=3,nodes={},edges={},rail_queue={},arm_renders={}}
    local s=storage.em.power_019
    s.nodes=s.nodes or {};s.edges=s.edges or {};s.rail_queue=s.rail_queue or {}
    s.arm_renders=s.arm_renders or {}
    return s
end
local function edge_key(a,b)
    if a>b then a,b=b,a end
    return tostring(a)..":"..tostring(b)
end
local function delete_edge(s,key)
    local e=s.edges[key]
    if not e then return end
    for _,id in pairs({e.contact_render,e.messenger_render}) do
        local o=rendering.get_object_by_id(id)
        if o and o.valid then o.destroy() end
    end
    visuals.destroy_edge(e)
    s.edges[key]=nil
end
local function rail_tangent(e)
    local rails=e.surface.find_entities_filtered{
        position=e.position,radius=RADIUS+2,name=RAILS,force=e.force}
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
    local nx,ny=geometry.rail_normal(tx,ty,side,
        e.position.x,e.position.y,best.position.x,best.position.y)
    local dist=math.abs(nx*(best.position.x-e.position.x)
        +ny*(best.position.y-e.position.y))
    return tx,ty,side,nx,ny,dist
end
local function register(s,e)
    local id=e.unit_number
    if not id then return end
    local n={id=id,name=e.name,x=e.position.x,y=e.position.y,
        surface_index=e.surface.index,force_name=e.force.name,
        rail_adjacent=e.name==SUB}
    if e.name==POLE then
        n.tx,n.ty,n.side,n.nx,n.ny,n.rail_offset=rail_tangent(e)
        n.rail_adjacent=n.tx~=nil
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
    return visuals.corridor(surface,force,a,b,RAILS,RADIUS)
end
local function draw(s,a,b,kind)
    local key=edge_key(a.unit_number,b.unit_number)
    if s.edges[key] then return end
    if kind=="contact" then
        s.edges[key]=visuals.draw_contact(s,a,b)
        return
    end
    local first=rendering.draw_line{
        surface=a.surface,
        from={entity=a,offset={0,-0.5}},
        to={entity=b,offset={0,-0.5}},
        color=kind=="feeder" and {r=0.35,g=0.8,b=1,a=0.95}
            or {r=0.95,g=0.7,b=0.2,a=0.95},
        width=2}
    local second
    if kind=="contact" then
        second=rendering.draw_line{
            surface=a.surface,
            from={entity=a,offset={0,-0.75}},
            to={entity=b,offset={0,-0.75}},
            color={r=0.5,g=0.6,b=0.85,a=0.7},width=1}
    end
    s.edges[key]={a=a.unit_number,b=b.unit_number,kind=kind,
        contact_render=first.id,messenger_render=second and second.id or nil}
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
end
local function refresh(surface,force,pos)
    local s=M.ensure_storage()
    local touched={}
    for _,e in pairs(surface.find_entities_filtered{
        position=pos,radius=SPAN*2+2,name={POLE,SUB},force=force}) do
        if e.valid and s.nodes[e.unit_number] then
            register(s,e);touched[e.unit_number]=e
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
    for _,e in pairs(touched) do
        if e.name==POLE then visuals.update_arm(s,e) end
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
    visuals.clear_arms(s)
    s.nodes={};s.edges={};s.rail_queue={};s.arm_renders={}
    local all={}
    for _,surface in pairs(game.surfaces) do
        for _,e in pairs(surface.find_entities_filtered{name={POLE,SUB}}) do
            if e.valid and e.unit_number then
                register(s,e);all[e.unit_number]=e
            end
        end
    end
    s.version=3
    for _,e in pairs(all) do
        if e.name==POLE then visuals.update_arm(s,e) end
    end
    build_edges(s,all)
    log("[ElectrifiedMainline][35kv] rebuilt visual graph (schema 2)")
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
    visuals.delete_arm(s,e.unit_number)
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
    local poles,subs,contacts,feeders,stale,arms=0,0,0,0,0,0
    for id,n in pairs(s.nodes) do
        if n.name==POLE then poles=poles+1 else subs=subs+1 end
        if not resolve(s,id) then stale=stale+1 end
    end
    for _,e in pairs(s.edges) do
        if e.kind=="contact" then contacts=contacts+1
        elseif e.kind=="feeder" then feeders=feeders+1 end
    end
    for _ in pairs(s.arm_renders) do arms=arms+1 end
    player.print("[ElectrifiedMainline][35kv] poles="..poles..
        " substations="..subs.." contact_spans="..contacts..
        " feeder_lines="..feeders.." arm_sprites="..arms.." stale_nodes="..stale..
        " energized=NO transfer_MW=0 (visual only)")
end
return M
