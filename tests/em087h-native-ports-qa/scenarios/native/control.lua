local S=defines.wire_origin.script
local P=defines.wire_origin.player
local C=defines.wire_connector_id.pole_copper
local function ck(ok,m) if not ok then error('[EM087H FAIL] '..m) end end
local function old(a,b)
 local n=0
 for _,l in pairs(a.real_connections) do
  if not (l.target and l.target.valid and l.target==b and l.origin==S) then return false end
  n=n+1
 end
 return n==1
end
local function new(a,b) return a.real_connection_count==1 and a.is_connected_to(b,S) end
local function test(a,b,label,expected)
 local x,y=old(a,b),new(a,b)
 log('[EM087H WIRE] '..label..' old='..tostring(x)..' native='..tostring(y)..' real='..a.real_connection_count..' total='..a.connection_count)
 ck(x==y,label..' mismatch');if expected~=nil then ck(x==expected,label..' unexpected value') end
end
script.on_init(function()
 local s=game.create_surface('em087h-wire',{width=128,height=128});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
 local function pole(x,y)
  local e=s.create_entity{name='small-electric-pole',position={x,y},force='player',auto_connect=false,raise_built=false};ck(e and e.valid,'pole creation');return e
 end
 local a,b,c=pole(0,0),pole(4,0),pole(0,4)
 local ac,bc,cc=a.get_wire_connector(C,true),b.get_wire_connector(C,true),c.get_wire_connector(C,true)
 test(ac,bc,'no-wire',false)
 ck(ac.connect_to(bc,false,P),'player connection');test(ac,bc,'player-only',false)
 ac.disconnect_all(P);ck(ac.connect_to(bc,false,S),'script connection');test(ac,bc,'script-only',true)
 ck(ac.connect_to(cc,false,S),'extra script');test(ac,bc,'extra-script',false)
 ac.disconnect_from(cc,S);ck(ac.connect_to(cc,false,P),'extra player');test(ac,bc,'extra-player',false)
 ac.disconnect_from(cc,P);test(ac,cc,'wrong-target',false)
 local res=ac.connect_to(bc,false,P);log('[EM087H WIRE] second origin native result='..tostring(res));test(ac,bc,'same-target-two-origins')
 ac.disconnect_all(P);if not ac.is_connected_to(bc,S) then ck(ac.connect_to(bc,false,S),'restore') end
 local g=s.create_entity{name='entity-ghost',inner_name='small-electric-pole',position={-4,0},force='player',raise_built=false};ck(g and g.valid,'ghost');local gc=g.get_wire_connector(C,true);ck(gc and gc.valid,'ghost connector')
 local gr=ac.connect_to(gc,false,S);log('[EM087H WIRE] ghost connect='..tostring(gr));test(ac,bc,'ghost-wire',true)
 g.destroy();test(ac,bc,'ghost-removed')
 b.destroy();test(ac,cc,'target-destroyed',false)
 log('[EM087H NATIVE PASS] all origin, count and ghost comparisons equal');script.finish_test(true)
end)
