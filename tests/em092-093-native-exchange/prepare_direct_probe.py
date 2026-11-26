import pathlib as P, zipfile, hashlib
base=P.Path('/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip')
assert hashlib.sha256(base.read_bytes()).hexdigest()=='eebed6e004a13b002a2a33101d771a3b7b0ee12d3dbba2bd12e19f6cb902e1a7'
out=P.Path('/mnt/data/em092/direct-probe.zip')
with zipfile.ZipFile(base) as z, zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as w:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/scripts/traction_paid_065.lua'):
   s=b.decode(); old='  return index\nend\nlocal function phase_bridge'; assert s.count(old)==1
   new='''  -- EM092 TEST-ONLY: use a finite QA source on a verified existing line port.
  -- Not a production permission, no factory or arbitrary network search.
  local lab=game.surfaces['em-25kv-isolated-bridge-058']
  if lab and prototypes.entity['em092-qa-finite-source'] then
    local sources=lab.find_entities_filtered{name='em092-qa-finite-source'}
    table.sort(sources,function(a,b)return a.unit_number<b.unit_number end)
    for _,output in ipairs(sources) do
      local net=output.electric_network_id
      for id,r in pairs(bridge.stations) do
        local line=r.line_port;local factory=r.factory_port
        if output.valid and net and line and line.valid and factory and factory.valid
          and entity(id) and line.electric_network_id==net and factory.electric_network_id~=net
          and output.force==line.force and output.surface==line.surface
          and output.position.x==line.position.x and output.position.y==line.position.y then
          local f=output.force.index;index[f]=index[f] or {}
          local row=index[f]
          if not row[net] or not row[net].qa then
            row[net]={count=1,id=output.unit_number,qa=true,donor={output=output,line_port=line,mode='qa-only'}}
          end
        end
      end
    end
  end
  return index
end
local function phase_bridge'''
   s=s.replace(old,new);b=s.encode();P.Path('/mnt/data/em092/traction_paid_065.probe.lua').write_bytes(b)
  w.writestr(n,b)
print(hashlib.sha256(out.read_bytes()).hexdigest())
