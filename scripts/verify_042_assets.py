#!/usr/bin/env python3
"""Verify accepted Factorio 0.1.42 binary sprites without regenerating them.

This is an OFFLINE asset/source contract, not an in-engine gameplay test.
All PNG digests are from the actual 0.1.42 ZIP accepted visually by user.
"""
import hashlib
import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'ElectrifiedMainline'
GFX = MOD / 'graphics/entity/35kv'
ICONS = MOD / 'graphics/icons'
FACES = ('east', 'southeast', 'south', 'southwest', 'west',
         'northwest', 'north', 'northeast')
SHAS = {
 'pole-arm-east-039.png':'c208e31fe1c6bb0124921b4bbccc78bb965529d5ac444c0d9a94d8625b9fe068',
 'pole-arm-southeast-039.png':'349a712ce36ea54f1c4c5d9f8e05b4cafdbf7377decf5b1e73320eb031a8a955',
 'pole-arm-south-039.png':'f2ef4d3dce75eea01c25228ffa11b9951da9406f5fcc43ec92f8f0d59852b52d',
 'pole-arm-southwest-039.png':'e781d9951220bc9467ed76fbcaadce6c5932e4284dd68e4bcefc38fb3b9fe105',
 'pole-arm-west-039.png':'c320d317f615e96c6fed1fd28950c55ff09491b4e75058b82a837da91bd63380',
 'pole-arm-northwest-039.png':'0ef059521a74e98915ed3ca3513c4a274438454cb435730bbd8ad1c387b8fe1e',
 'pole-arm-north-039.png':'2c597cf1c13845443dc4201948084d02e4e6576af503f7c6e19b94de1de38566',
 'pole-arm-northeast-039.png':'8ca517ee635dd05195b77b46a26c98c33c957c2dfdfdba9f59d741017a2858bb',
 'pole-north-039.png':'5ba8dda7f93db22b1ccb745dc35a6a03369ddce68e945c2dd574a2b877c37ab8',
 'pole-south-039.png':'26b529a8ef2e9e9321a8eeed7bd71b87983b155b75680b66cb9e1a3422bc47f4',
 '25kv-north-039.png':'a5bf73d69cd6dc91cc333b0d0657c892f5997c6eca87ed562d4c2f1c280c0d6b',
 '25kv-south-039.png':'f60671e2ae01267be8c3304260f0ca08f0c7fc1870bc53affd8d00adf2cd8571',
}


def check_png(name, digest):
    filename = (ICONS if name.startswith('25kv-') else GFX) / name
    raw = filename.read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n', (name, 'not PNG')
    assert raw[12:16] == b'IHDR', (name, 'no IHDR')
    width, height = struct.unpack('>II', raw[16:24])
    expected = (64, 64) if name.startswith('25kv-') else (
        (512, 512) if name == 'pole-south-039.png' else (512, 384))
    assert (width, height) == expected, (name, width, height, expected)
    assert raw[25] == 6, (name, 'expected RGBA PNG color type 6')
    actual = hashlib.sha256(raw).hexdigest()
    assert actual == digest, (name, 'unexpected changed artwork', actual)
    return width, height


def main():
    assert json.loads((MOD/'info.json').read_text())['version'] == '0.1.42'
    proto = (MOD/'prototypes/power_019.lua').read_text()
    layout = (MOD/'scripts/mast_visual_034.lua').read_text()
    assert re.search(r'\bM\.NORTH_DROP\s*=\s*2\.02\b', layout), 'wrong accepted north offset'
    for name, digest in SHAS.items():
        check_png(name, digest)
        assert name in proto, ('sprite not referenced by prototype', name)
    assert 'northern.icon=north_icon' in proto and 'icon=north_icon' in proto
    assert 'width = 512, height = 512, direction_count = 1' in proto
    assert 'pole-native-mast-024.png' not in proto
    assert 'em-35kv-contact-wire-texture' not in proto
    assert 'northern.pictures.layers[1].height=384' in proto
    # Every PNG shipped is referenced by the current mod. Stale assets
    # must fail CI instead of becoming untracked baggage in release ZIPs.
    allowed_35kv = {'pole-south-039.png', 'pole-north-039.png',
                    'pole-shadow-4dir-hr.png'} | {
        f'pole-arm-{face}-039.png' for face in FACES}
    found_35kv = {p.name for p in GFX.glob('*.png')}
    assert found_35kv == allowed_35kv, (
        'stale/missing mast PNGs', sorted(found_35kv ^ allowed_35kv))
    allowed_icons = {'25kv-north-039.png','25kv-south-039.png'}
    assert {p.name for p in ICONS.glob('*.png')} == allowed_icons
    allowed_wire = {'contact-030.png','messenger-030.png','dropper-030.png'}
    assert {p.name for p in (MOD/'graphics/entity/25kv').glob('*.png')} == allowed_wire
    qa = json.loads((ROOT/'docs/tests/evidence/SPRITES_039_QA.json').read_text())
    contracts = qa['tip_contracts']
    assert len(contracts) == 8
    assert {row['face'] for row in contracts} == set(FACES)
    assert all(0 <= float(row['error_px']) < 1.0 for row in contracts)
    for row in contracts:
        assert row['mount_x_px'] == row['image_bbox'][0] or row['mount_x_px'] == row['image_bbox'][2]
    print('0.1.42 accepted PNG/source contract PASS: 12 SHA256, 8 faces, 2 icons, north=2.02; gameplay separate')


if __name__ == '__main__':
    main()