-- 0.1.12 rail-following visual contact graph, cosmetic sprites only; no MW transfer.
-- 0.1.27: C mast + native wire probe, no scripted overhead lines.
local M = {}
local axis056 = require("scripts.catenary_axis_056")
local view = require("scripts.overhead_geometry_012")
local face022 = require("scripts.mast_facing_022")
local limits = require("scripts.catenary_limits_029")
local mast034 = require("scripts.mast_visual_034")
local POLE,NORTH,SUB = "em-35kv-catenary-pole","em-35kv-catenary-pole-north","em-35kv-traction-substation"
local POLES={POLE,NORTH}
local function is_pole(name) return name==POLE or name==NORTH end
local SPAN,RADIUS = limits.STRAIGHT,3
local RAILS = {"em-high-speed-straight-rail","em-curved-high-speed-rail",
    "em-curved-high-speed-rail-b","em-half-diagonal-high-speed-rail"}
local RAIL_SET = {}
for _,name in pairs(RAILS) do RAIL_SET[name]=true end

function M.ensure_storage()
    storage.em=storage.em or {}
    storage.em.power_019=storage.em.power_019 or {version=4,nodes={},edges={},rail_queue={},sprites={}}
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
    -- Both native mast sprites are SHAFT ONLY: restored separate arm for
    -- the north-side shorter mast; never suppress the cantilever here.
    -- 0.1.33 skipped NORTH here, leaving bare shafts (user screenshot).
    local n=s.nodes[id]
    local face=n and n.face or "east"
    local obj=rendering.draw_sprite{
        sprite="em-35kv-facing-"..face,
        surface=e.surface,
        target={entity=e,offset={0,mast034.cantilever_shift(e.name)}},
        -- Native shaft is drawn by the engine on the object layer.
        -- The C arm must be in front of its own native mounting plate.
        render_layer="higher-object-above",
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
    if is_pole(e.name) then
        local rail
        n.tx,n.ty,n.side,rail=rail_tangent(e)
        n.rail_adjacent=n.tx~=nil
        n.rail_id=rail and rail.unit_number or nil
        -- The visual G-arm must face the closest point of running track,
        -- not the arbitrary entity center of a curved/half-diagonal rail.
        -- Rail tangent and contact-line graph semantics remain unchanged.
        local rails=e.surface.find_entities_filtered{
            position=e.position,radius=RADIUS,name=RAILS,force=e.force}
        local reference=face022.nearest(e.position,rails,
            defines.rail_direction.front,defines.rail_direction.back,
            defines.rail_layer.ground)
        local target=reference and reference.point or (rail and rail.position)
        n.face=view.face(e.position,target)
        n.face_source=reference and reference.method or "no_rail_default"
        n.face_rail_name=reference and reference.rail_name or nil
        n.face_target=target and {x=target.x,y=target.y} or nil
    end
    s.nodes[id]=n
end
local function resolve(s,id)
    if s.preview and s.preview.unit_number==id then return s.preview end
    local n=s.nodes[id]
    if not n then return nil end
    local e=game.get_entity_by_unit_number(id)
    if e and e.valid and e.name==n.name and
        e.surface.index==n.surface_index and e.force.name==n.force_name then
        return e
    end
end
-- This is deliberately *not* RailSignalPrototype: no changes to train blocks.
-- Check real rail connectivity, so nearby but independent tracks do not join.
local function rail_path_info(a,b,max_distance)
    if not (a and b and a.rail_id and b.rail_id
        and a.surface_index==b.surface_index
        and a.force_name==b.force_name) then return nil end
    local surface=game.surfaces[a.surface_index]
    local force=game.forces[a.force_name]
    if not (surface and force) then return nil end
    local start
    for _,r in pairs(surface.find_entities_filtered{
        position={x=a.x,y=a.y},radius=RADIUS,name=RAILS,force=force}) do
        if r.unit_number==a.rail_id then start=r;break end
    end
    if not (start and start.valid and RAIL_SET[start.name]) then return nil end
    local straight="em-high-speed-straight-rail"
    if a.rail_id==b.rail_id then
        return {length=0,curved=start.name~=straight}
    end
    local directions={defines.rail_direction.front,defines.rail_direction.back}
    local turns={defines.rail_connection_direction.straight,
        defines.rail_connection_direction.left,defines.rail_connection_direction.right}
    -- Bounded lowest-cost rail walk; never traverse vanilla, elevated,
    -- enemy or disconnected rail. Cost is approximate entity-centre path
    -- distance, not Factorio's exact rail spline length.
    local queue={{rail=start,length=0,curved=start.name~=straight}}
    local best={[start.unit_number]=0}
    local visited=0
    local max_walk=max_distance or (limits.STRAIGHT*1.5+4)
    while #queue>0 and visited<192 do
        local best_i=1
        for i=2,#queue do
            if queue[i].length<queue[best_i].length then best_i=i end
        end
        local cur=table.remove(queue,best_i)
        if cur.length<=best[cur.rail.unit_number]+0.00001 then
            visited=visited+1
            if cur.rail.unit_number==b.rail_id then
                return {length=cur.length,curved=cur.curved}
            end
            for _,d in ipairs(directions) do
                for _,turn in ipairs(turns) do
                    local other=cur.rail.get_connected_rail{
                        rail_direction=d,rail_connection_direction=turn}
                    if other and other.valid and RAIL_SET[other.name]
                        and other.unit_number and other.force.name==a.force_name
                        and other.surface.index==a.surface_index then
                        local dx=other.position.x-cur.rail.position.x
                        local dy=other.position.y-cur.rail.position.y
                        local cost=cur.length+math.max(1,math.sqrt(dx*dx+dy*dy))
                        if cost<=max_walk and
                            (not best[other.unit_number] or
                                cost<best[other.unit_number]-0.00001) then
                            best[other.unit_number]=cost
                            queue[#queue+1]={rail=other,length=cost,
                                curved=cur.curved or other.name~=straight}
                        end
                    end
                end
            end
        end
    end
    return nil
end
local function connected_rail_path(a,b)
    return rail_path_info(a,b)~=nil
end
-- HSR continuity only; no geometric side/angle gate.
function M.technical_path(a,b)
    if not (a and b and a.rail_adjacent and b.rail_adjacent) then return nil end
    return rail_path_info(a,b,limits.WIRE_REACH*1.5+4)
end

-- Deterministic complete cosmetic plan, no rail walk.
-- Feeder metadata remains for future substation work.
local function build_edges(s,touched)
    for key in pairs(s.edges) do delete_edge(s,key) end
    s.edges=axis056.plan(s.nodes)
    for id,n in pairs(s.nodes) do
        if n.name==SUB then
            local e=resolve(s,id)
            if e then
                local best,nearest=SPAN*SPAN+1,nil
                for _,pole in pairs(e.surface.find_entities_filtered{
                    position=e.position,radius=SPAN,name=POLES,force=e.force}) do
                    local q=s.nodes[pole.unit_number]
                    if q and q.rail_adjacent then
                        local dx,dy=q.x-n.x,q.y-n.y
                        local d=dx*dx+dy*dy
                        if d<best or (d==best and nearest and q.id<nearest) then best,nearest=d,q.id end
                    end
                end
                if nearest then s.edges[edge_key(id,nearest)]={a=id,b=nearest,kind="feeder",corner=false} end
            end
        end
    end
end
local function refresh(surface,force,pos)
    local s=M.ensure_storage()
    local touched={}
    for _,e in pairs(surface.find_entities_filtered{
        position=pos,radius=SPAN*2+2,name={POLE,NORTH,SUB},force=force}) do
        if e.valid and s.nodes[e.unit_number] then
            register(s,e);touched[e.unit_number]=e
        if is_pole(e.name) then render_sprite(s,e) end
        end
    end
    -- A touched pole may have a feeder from a substation just outside
    -- the refresh circle. Include that substation before removing edges.
    local additional={}
    for _,e in pairs(touched) do
        if is_pole(e.name) then
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
        for _,e in pairs(surface.find_entities_filtered{name={POLE,NORTH,SUB}}) do
            if e.valid and e.unit_number then
                register(s,e);all[e.unit_number]=e
                if is_pole(e.name) then render_sprite(s,e) end
            end
        end
    end
    s.version=4
    build_edges(s,all)
    log("[ElectrifiedMainline][25kv] rebuilt rail-axis cosmetic graph (056)")
end
function M.on_built(event)
    local e=event.entity
    if not (e and e.valid and (is_pole(e.name) or e.name==SUB)) then return end
    local s=M.ensure_storage()
    register(s,e)
    if is_pole(e.name) and not s.nodes[e.unit_number].rail_adjacent then
        local player=event.player_index and game.get_player(event.player_index)
        if player and player.valid then player.print({"message.em-35kv-no-rail"}) end
    end
    refresh(e.surface,e.force,e.position)
    if is_pole(e.name) then
        local n=s.nodes[e.unit_number]
        if n then
            local target=n.face_target
            log(string.format(
                "[ElectrifiedMainline][face022] pole=(%.3f,%.3f) face=%s via=%s rail=%s target=%s",
                n.x,n.y,tostring(n.face),tostring(n.face_source),
                tostring(n.face_rail_name),target and
                string.format("(%.3f,%.3f)",target.x,target.y) or "nil"))
        end
    end
end
function M.on_removed(event)
    local e=event.entity
    if not (e and e.valid and (is_pole(e.name) or e.name==SUB)) then return end
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
    if not next(s.rail_queue) then return false end
    local buckets={}
    local changed=false
    for key,change in pairs(s.rail_queue) do
        if tick>=change.tick then
            s.rail_queue[key]=nil
            changed=true
            local surface=game.surfaces[change.surface_index]
            local force=game.forces[change.force_name]
            if surface and force then
                for _,pole in pairs(surface.find_entities_filtered{
                    -- A removed middle rail can be 8+ tiles from BOTH masts.
                    -- Rescan the full eligible span, not just a 5-tile circle.
                    position=change.position,radius=limits.WIRE_REACH*1.5+4+RADIUS,
                    name=POLES,force=force}) do
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
    -- Even a rail-only edit can split a technical path.
    return changed
end
function M.status(player)
    local s=M.ensure_storage()
    local poles,subs,contacts,feeders,stale,turns=0,0,0,0,0,0
    for id,n in pairs(s.nodes) do
        if is_pole(n.name) then poles=poles+1 else subs=subs+1 end
        if not resolve(s,id) then stale=stale+1 end
    end
    for _,e in pairs(s.edges) do
        if e.kind=="contact" then
            contacts=contacts+1
            if e.corner then turns=turns+1 end
        elseif e.kind=="feeder" then feeders=feeders+1 end
    end
    player.print("[ElectrifiedMainline][25kv] poles="..poles..
        " substations="..subs.." contact_spans="..contacts..
        " feeder_lines="..feeders.." curved_spans="..turns..
        " oriented_sprites="..tostring(s.sprites and (function()
            local count=0;for _ in pairs(s.sprites) do count=count+1 end
            return count end)() or 0).." stale_nodes="..stale..
        " visual_span=32 tech_reach=40 energized=NO transfer_MW=0")
end
-- Share the same RailEnd projection with non-native ghost images.
-- This does not mutate real poles or their contact graph.
function M.facing_at(entity)
    local rails=entity.surface.find_entities_filtered{
        position=entity.position,radius=RADIUS,name=RAILS,force=entity.force}
    local reference=face022.nearest(entity.position,rails,
        defines.rail_direction.front,defines.rail_direction.back,
        defines.rail_layer.ground)
    return view.face(entity.position,reference and reference.point)
end
-- Dry-run the SAME real placement graph calculation on a local copy.
-- Only predicts one hypothetical real mast against currently built masts.
-- No create/destroy, no rendering, no mutation of real nodes/edges.
function M.preview_at(ghost)
    local live=M.ensure_storage()
    local id=9007199254740991
    local e={unit_number=id,name=ghost.ghost_name,position=ghost.position,
        surface=ghost.surface,force=ghost.force,valid=true}
    if not is_pole(e.name) then return nil,{} end
    local s={nodes={},edges={},preview=e}
    for k,n in pairs(live.nodes) do s.nodes[k]=n end
    register(s,e)
    local n=s.nodes[id]
    local touched={[id]=e}
    for _,other in pairs(e.surface.find_entities_filtered{
        position=e.position,radius=SPAN*2+2,name={POLE,NORTH,SUB},force=e.force}) do
        if other.valid and s.nodes[other.unit_number] then
            register(s,other);touched[other.unit_number]=other
        end
    end
    s.edges=axis056.plan(s.nodes)
    local spans={}
    for _,edge in pairs(s.edges) do
        if edge.kind=="contact" and (edge.a==id or edge.b==id) then
            spans[#spans+1]={a=s.nodes[edge.a],b=s.nodes[edge.b],corner=edge.corner}
        end
    end
    return n,spans,s.nodes
end
-- Read-only visual graph view.
function M.graph() return M.ensure_storage() end
-- Used by pure-Lua regression to prove disconnected ВСМ tracks are rejected.
M.connected_rail_path=connected_rail_path
M.rail_path_info=rail_path_info
return M
