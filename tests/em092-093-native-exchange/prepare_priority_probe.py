import pathlib as P,zipfile,hashlib
r=P.Path('/mnt/data/em092');base=r/'exchange-probe.zip';out=r/'priority-probe.zip'
with zipfile.ZipFile(base) as z,zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as w:
 for n in z.namelist():
  b=z.read(n)
  if n.endswith('/scripts/brake_recovery_091.lua'):
   s=b.decode().replace("lab.find_entities_filtered{name='em092-qa-finite-source'}", "lab.find_entities_filtered{name={'em092-qa-finite-source','em092-qa-offer-only'}}");b=s.encode()
  w.writestr(n,b)
print(hashlib.sha256(out.read_bytes()).hexdigest())
