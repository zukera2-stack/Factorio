"""Use a native 2.1.24 generated EM091 default setting file, never edit user settings."""
import argparse, pathlib, hashlib
p=argparse.ArgumentParser();p.add_argument('native_default',type=pathlib.Path);p.add_argument('output',type=pathlib.Path);a=p.parse_args();b=a.native_default.read_bytes();assert b[:9]==bytes.fromhex('020001001800010000')
for name in (b'em089-experimental-onboard-storage',b'em091-experimental-regeneration'):
 key=name+b'\x05\x00\x01\x00\x00\x00\x00\x05value\x01\x00\x00'
 enabled=key[:-1]+b'\x01'
 assert b.count(key)+b.count(enabled)==1,name
 b=b.replace(key,enabled)
a.output.write_bytes(b);print(hashlib.sha256(b).hexdigest())
