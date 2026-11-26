import pathlib as P,zipfile,hashlib
r=P.Path(__file__).parent;base=P.Path('/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip');out=r/'terminal-probe-QA-ONLY.zip'
assert hashlib.sha256(base.read_bytes()).hexdigest()=='eebed6e004a13b002a2a33101d771a3b7b0ee12d3dbba2bd12e19f6cb902e1a7'
with zipfile.ZipFile(base) as z,zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as w:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/scripts/control.lua'):
   b+=b'''\n-- QA-ONLY diagnostic terminal interface. Never ship this mutation interface.\nlocal term094=require('scripts.line_terminal_094')\nremote.add_interface('em094_terminal_QA_ONLY',{ensure=function(mast)return term094.ensure(mast)~=nil end,offer=term094.offer,demand=term094.demand,settle=term094.settle,snapshot=term094.snapshot})\n'''
  w.writestr(n,b)
 w.writestr('ElectrifiedMainline_0.1.102/scripts/line_terminal_094.lua',(r/'line_terminal_first.lua').read_bytes())
print(hashlib.sha256(out.read_bytes()).hexdigest())
