-- EM072-A4: pure deterministic max-min fairness for a single verified rail/electric component.
-- Joules per tick. Never manufactures joules; caller debits a physically backed EEI.
local M={}
local EPS=1e-8
function M.allocate(requests,budget)
  assert(type(requests)=="table" and type(budget)=="number" and budget>=0)
  local ids,grants={},{}
  for id,req in pairs(requests) do
    assert(type(id)=="number" and type(req)=="number" and req>=0)
    ids[#ids+1]=id;grants[id]=0
  end
  table.sort(ids)
  local left=budget
  while left>EPS and #ids>0 do
    local slice=left/#ids
    local next_ids={}
    local used=0
    for _,id in ipairs(ids) do
      local delta=math.min(slice,math.max(0,requests[id]-grants[id]))
      grants[id]=grants[id]+delta;used=used+delta
      if requests[id]-grants[id]>EPS then next_ids[#next_ids+1]=id end
    end
    left=math.max(0,left-used)
    if used<EPS then break end
    ids=next_ids
  end
  return grants,budget-left
end
-- De-duplicate locomotives by unit number. All locomotives in a train aggregate
-- into ONE demand keyed by native train.id. No station-level multiplication.
function M.aggregate(entries)
  local train_request,units,unit_to_train={}, {}, {}
  for _,entry in pairs(entries) do
    if entry and type(entry.train_id)=="number" and type(entry.unit_id)=="number"
      and type(entry.watts)=="number" and entry.watts>=0 and not units[entry.unit_id] then
      units[entry.unit_id]=true
      local id=entry.train_id
      train_request[id]=(train_request[id] or 0)+entry.watts/60
      unit_to_train[entry.unit_id]=id
    end
  end
  return train_request,unit_to_train
end
return M
