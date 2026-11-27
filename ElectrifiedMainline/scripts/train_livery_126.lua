local M={}
local EM_LOCO="em-electric-locomotive"
local WAGONS={["em-motor-cargo-wagon"]=true,["em-motor-fluid-wagon"]=true,["em-battery-wagon"]=true}
local function real_locomotive(e)
  return e and e.valid and e.type=="locomotive" and not e.name:match("^em%-c5%-technical%-booster%-")
end
local function same(a,b)
  return a and b and math.abs(a.r-b.r)<0.00001 and math.abs(a.g-b.g)<0.00001 and math.abs(a.b-b.b)<0.00001 and math.abs((a.a or 1)-(b.a or 1))<0.00001
end
local updating=false
function M.sync(train,source)
  if updating or not (train and train.valid) then return end
  local stock=train.carriages
  if not real_locomotive(source) then
    local other=nil
    for _,e in ipairs(stock) do
      if e.valid and e.name==EM_LOCO then source=e;break end
      if not other and real_locomotive(e) then other=e end
    end
    source=source or other
  end
  if not real_locomotive(source) or not source.color then return end
  local c=source.color;local color={r=c.r,g=c.g,b=c.b,a=1}
  updating=true
  for _,e in ipairs(stock) do
    if e.valid and e~=source and (WAGONS[e.name] or e.name==EM_LOCO) and not same(e.color,color) then e.color=color end
  end
  updating=false
end
function M.changed(event)
  local e=event.entity
  if real_locomotive(e) then M.sync(e.train,e) end
end
function M.built(e)
  if e and e.valid and (WAGONS[e.name] or e.name==EM_LOCO) then M.sync(e.train) end
end
function M.reconcile()
  for _,t in pairs(game.train_manager.get_trains({stock={EM_LOCO,"em-motor-cargo-wagon","em-motor-fluid-wagon","em-battery-wagon"}})) do M.sync(t) end
end
return M
