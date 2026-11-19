-- Read-only train observation, one cosmetic render per actual EM locomotive.
-- No energy, entity creation, changes to trains or Undo operations.
local M={}
local NAME="em-electric-locomotive"
local COUNT=32
local START,STOP=0.002,0.001
local function rows()
    storage.em=storage.em or {}
    storage.em.pantograph_049=storage.em.pantograph_049 or {}
    return storage.em.pantograph_049
end
function M.frame(orientation)
    return math.floor((orientation%1)*COUNT+0.5)%COUNT
end
function M.state(speed,previous)
    local v=math.abs(speed or 0)
    if previous=="up" then return v>STOP and "up" or "down" end
    return v>=START and "up" or "down"
end
local function render_object(row)
    if not row then return nil end
    local r=rendering.get_object_by_id(row.id)
    if r and r.valid then return r end
end
local function destroy(row)
    local r=render_object(row)
    if r then r.destroy() end
end
function M.clear()
    local s=rows()
    for _,r in pairs(s) do destroy(r) end
    storage.em.pantograph_049={}
end
function M.remove(e)
    if not (e and e.valid and e.name==NAME and e.unit_number) then return end
    local s=rows()
    destroy(s[e.unit_number]);s[e.unit_number]=nil
end
function M.sync(trains,get_locomotives)
    local s=rows()
    local seen={}
    for _,train in pairs(trains) do
        if train.valid then
            for _,e in pairs(get_locomotives(train)) do
                if e.valid and e.name==NAME and e.unit_number and not seen[e.unit_number] then
                    local id=e.unit_number;seen[id]=true
                    local row=s[id]
                    local state=M.state(train.speed,row and row.state)
                    local frame=M.frame(e.orientation)
                    local sprite=string.format("em-panto-049-%s-%02d",state,frame)
                    local r=render_object(row)
                    if not r then
                        r=rendering.draw_sprite{sprite=sprite,surface=e.surface,
                            target={entity=e,offset={0,-1}},render_layer="higher-object-above"}
                        s[id]={id=r.id,state=state,frame=frame}
                    else
                        if row.state~=state or row.frame~=frame then
                            r.sprite=sprite
                            row.state=state;row.frame=frame
                        end
                    end
                end
            end
        end
    end
    for id,row in pairs(s) do
        if not seen[id] then destroy(row);s[id]=nil end
    end
end
function M.status(player)
    local e=player.selected
    if not (e and e.valid and e.name==NAME) then
        player.print("[EM049] Select an EM electric locomotive.");return
    end
    local row=rows()[e.unit_number]
    local tr=e.train
    local msg=string.format("[EM049] loco=%s orientation=%.6f speed=%.6f state=%s frame=%s render_valid=%s",
        tostring(e.unit_number),e.orientation,tr and tr.valid and tr.speed or 0,
        tostring(row and row.state),tostring(row and row.frame),tostring(render_object(row)~=nil))
    -- Probe only: exact draw_data semantics/gap vs entity position to be tested.
    local ok,d=pcall(function() return e.draw_data end)
    if ok and d then
        msg=msg..string.format(" draw_orientation=%s height=%s slope=%s draw_position=(%s,%s) entity_position=(%s,%s)",
            tostring(d.orientation),tostring(d.height),tostring(d.slope),tostring(d.position and d.position.x),
            tostring(d.position and d.position.y),tostring(e.position.x),tostring(e.position.y))
    end
    local c=e.color
    if c then msg=msg..string.format(" color=(%.4f,%.4f,%.4f,%.4f)",c.r,c.g,c.b,c.a or 1) end
    log(msg);player.print(msg)
end
return M
