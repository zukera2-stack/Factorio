-- Read-only train observation, one cosmetic render per actual EM locomotive.
-- No energy, entity creation, changes to trains or Undo operations.
local M={}
local NAME="em-electric-locomotive"
local COUNT=256
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
local function clear_spark(row)
    if not row or not row.spark_id then return end
    local spark=rendering.get_object_by_id(row.spark_id)
    if spark and spark.valid then spark.destroy() end
    row.spark_id=nil
end
local function destroy(row)
    clear_spark(row)
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
-- Same quantized camera projection as render_polish_052.py.
function M.head_offset(frame)
    local t=frame*2*math.pi/COUNT
    local a=math.atan2(math.sin(t)/math.sqrt(2),math.cos(t))
    local y=-.93*1.055
    return {x=y*math.sin(a),y=-y*math.cos(a)/math.sqrt(2)-2.8728125}
end
local function next_delay(id,tick)
    return 180+(id*97+tick*53)%421
end
function M.spark(row,e,speed,tick,contact_at,is_hsr)
    if not (tick and contact_at and is_hsr) then return end
    local contact=nil
    if row.state=="up" and math.abs(speed or 0)>STOP and is_hsr(e) then
        local h=M.head_offset(row.frame)
        contact=contact_at(e.surface.index,e.force.name,{x=e.position.x+h.x,y=e.position.y+h.y})
    end
    local was=row.contact
    row.contact=contact~=nil
    row.contact_distance=contact and contact.distance or nil
    if not contact then clear_spark(row);return end
    local target={entity=e,offset={contact.x-e.position.x,contact.y-e.position.y}}
    local ob=row.spark_id and rendering.get_object_by_id(row.spark_id)
    if ob and ob.valid then ob.target=target;return end
    row.spark_id=nil
    local fresh=not was and (not row.last_flash or tick-row.last_flash>=30)
    if fresh or tick>=(row.next_flash or 0) then
        local spark=rendering.draw_animation{animation="em-panto-discharge-052",target=target,surface=e.surface,
            render_layer="wires",x_scale=.20,y_scale=.20,animation_speed=2,
            animation_offset=(-tick*2)%24,time_to_live=12}
        row.spark_id=spark.id;row.last_flash=tick;row.next_flash=tick+next_delay(e.unit_number,tick)
        row.flash_count=(row.flash_count or 0)+1
    end
end
function M.sync(trains,get_locomotives,tick,contact_at,is_hsr)
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
                    local sprite=string.format("em-panto-052-%s-%03d",state,frame)
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
                    M.spark(s[id],e,train.speed,tick,contact_at,is_hsr)
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
    if row then msg=msg..string.format(" visual_contact=%s distance=%s flashes=%d",tostring(row.contact),tostring(row.contact_distance),row.flash_count or 0) end
    log(msg);player.print(msg)
end
return M
