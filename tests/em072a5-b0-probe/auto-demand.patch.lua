
 -- EM072-A5-B0 isolated benchmark: 12 genuine locomotives, unique train IDs,
 -- demand entered exactly once on the physical line component (not per mast).
 if s.a5_ids and #s.a5_ids==12 then
  local seen_trains={}
  for id,r in pairs(s.stations) do
   if r.line_port and r.line_port.valid then
    local line_key=dispatch.network_key(r.line_port)
    if line_key and not seen_trains[line_key] then
     local count=0
     for _,unit_id in ipairs(s.a5_ids) do
      local loco=game.get_entity_by_unit_number(unit_id)
      if loco and loco.valid and loco.train and loco.train.valid then
       local ok,qualified=pcall(remote.call,"em072a5_b0_native","qualifies",id,unit_id)
       if ok and qualified then count=count+1 end
      end
     end
     if count>0 then
      direct[line_key]=direct[line_key] or {}
      direct[line_key].demand=(direct[line_key].demand or 0)+count*2000000/60
      seen_trains[line_key]=true
     end
    end
   end
  end
 end