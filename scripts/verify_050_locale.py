"""Check native CFG sections and explicit locomotive names."""
from pathlib import Path
import configparser
root=Path(__file__).resolve().parents[1]/'ElectrifiedMainline/locale'
for lang in ('en','ru'):
    cfg=configparser.ConfigParser(interpolation=None, strict=True)
    cfg.read(root/lang/(lang+'.cfg'),encoding='utf-8')
    for section in ('entity-name','item-name','item-description'):
        assert cfg.has_option(section,'em-electric-locomotive'),(lang,section)
    for s in cfg.sections():
        for key in cfg[s]:
            assert '.' not in key,(lang,s,key)
    assert cfg['entity-name']['em-electric-locomotive']==cfg['item-name']['em-electric-locomotive']
    assert cfg.has_option('entity-name','em-high-speed-straight-rail')
    assert cfg.has_option('entity-name','em-35kv-catenary-pole')
print('050 PASS: RU/EN native locale sections, no duplicate/dotted keys, locomotive and rail names')
