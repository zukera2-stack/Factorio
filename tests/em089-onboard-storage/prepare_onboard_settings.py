"""Exact Factorio 2.1.24 template from default-disabled EM089A run; test-only."""
import argparse,hashlib,pathlib
p=argparse.ArgumentParser();p.add_argument('native_default',type=pathlib.Path);p.add_argument('output',type=pathlib.Path);a=p.parse_args();b=a.native_default.read_bytes()
assert b[:9]==bytes.fromhex('020001001800010000'),'expected exact 2.1.24 version header'
key=b'em089-experimental-onboard-storage'+b'\x05\x00\x01\x00\x00\x00\x00\x05value\x01\x00\x00'
assert b.count(key)==1,'native default false setting missing/ambiguous'
x=b.replace(key,key[:-1]+b'\x01');assert hashlib.sha256(x).hexdigest()=='c2e23ccbdfb873c1ae7541c2ede63e489e05c003ec2005d64fc7dff78b46b7da','nondefault template'
a.output.write_bytes(x)
