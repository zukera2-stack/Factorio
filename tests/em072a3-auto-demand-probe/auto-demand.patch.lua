
 -- EM072-A3 disposable native automatic traction demand; production bridge unchanged.
 local probe_loco=s.em072a3_loco_id and game.get_entity_by_unit_number(s.em072a3_loco_id)
 if probe_loco and probe_loco.valid then
   for station_id,r in pairs(s.stations) do
     if r.line_port and r.line_port.valid then
       local ok,eligible=pcall(remote.call,"em072a2_native_probe","qualifies",station_id,s.em072a3_loco_id)
       if ok and eligible then
         local line_key=dispatch.network_key(r.line_port)
         if line_key then
           direct[line_key]=direct[line_key] or {}
           direct[line_key].demand=(direct[line_key].demand or 0)+2000000/60
         end
       end
     end
   end
 end
