#!/usr/bin/env python3
"""Verify the complete staged integration ZIP against frozen game payload hashes."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile


def verify(archive, manifest):
    m = json.loads(Path(manifest).read_text(encoding='utf-8'))
    if m['schema'] != 1:
        raise ValueError('unsupported manifest schema')
    code, png = m['git_blob_sha1'], m['png_sha256']
    if set(code) & set(png) or len(code) != m['non_png_count'] or len(png) != m['png_count']:
        raise ValueError('invalid manifest inventory')
    expected = set(code) | set(png)
    with zipfile.ZipFile(archive) as z:
        files = {}
        roots = set()
        for item in z.infolist():
            name = item.filename
            if item.is_dir() or '\\' in name or name.startswith('/') or any(p in ('', '.', '..') for p in name.split('/')):
                raise ValueError(f'unsafe or unexpected ZIP entry: {name}')
            parts = PurePosixPath(name).parts
            if len(parts) < 2 or parts[0] not in ('ElectrifiedMainline', 'ElectrifiedMainline_'+m['version']):
                raise ValueError(f'invalid game root: {name}')
            roots.add(parts[0])
            path = '/'.join(parts[1:])
            if path in files:
                raise ValueError(f'duplicate ZIP entry: {path}')
            files[path] = item
        if len(roots) != 1 or set(files) != expected:
            raise ValueError(f'inventory mismatch: missing={sorted(expected-set(files))}, extra={sorted(set(files)-expected)}')
        for path, item in files.items():
            data = z.read(item)
            if path in png:
                actual, wanted = hashlib.sha256(data).hexdigest(), png[path]
            else:
                actual, wanted = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest(), code[path]
            if actual != wanted:
                raise ValueError(f'payload hash mismatch: {path}')
        info = json.loads(z.read(files['info.json']))
        if info['name'] != 'ElectrifiedMainline' or info['version'] != m['version'] or info['factorio_version'] != '2.1':
            raise ValueError('metadata mismatch')
        if z.testzip() is not None:
            raise ValueError('CRC failure')
    print(f'INTEGRATION PAYLOAD PASS: {len(expected)} files ({len(code)} non-PNG, {len(png)} PNG); version {m["version"]}')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--archive', type=Path, required=True)
    p.add_argument('--manifest', type=Path, default=Path(__file__).resolve().parents[1]/'docs/builds/integration-runtime.json')
    args = p.parse_args()
    verify(args.archive, args.manifest)
