"""One-time freeze of the exact native-tested 060 artwork, no rendering."""
import hashlib, json, sys, zipfile
from pathlib import Path, PurePosixPath
ROOT=Path(__file__).resolve().parents[3]
MOD=ROOT/"ElectrifiedMainline"
EXPECTED="10b00013e66ed1d63ec901449fb166ab9a80fa391c2afb0d0f0c0910901fcbf9"
sha=lambda b: hashlib.sha256(b).hexdigest()
archive=Path(sys.argv[1])
assert sha(archive.read_bytes())==EXPECTED,"Unexpected archive SHA256"
with zipfile.ZipFile(archive) as z:
    assert not z.testzip()
    names=z.namelist()
    assert len(names)==len(set(names))==129
    payload={}
    for n in names:
        path=PurePosixPath(n)
        assert path.parts[0]=="ElectrifiedMainline" and len(path.parts)>1
        assert all(x not in ("..",".") for x in path.parts) and not n.startswith("/")
        rel=PurePosixPath(*path.parts[1:]).as_posix()
        payload[rel]=z.read(n)
    png={p:b for p,b in payload.items() if p.startswith("graphics/") and p.endswith(".png")}
    assert len(png)==83
    existing={p.relative_to(MOD).as_posix():p.read_bytes() for p in MOD.rglob("*") if p.is_file()}
    assert len([p for p in existing if p in png])==16
    assert all(p in payload and b==payload[p] for p,b in existing.items()),"Existing runtime byte differs"
    missing=set(payload)-set(existing)
    assert len(missing)==67 and missing<=png.keys()
    for p in sorted(missing):
        dest=MOD/p;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(png[p])
    actual={p.relative_to(MOD).as_posix():p.read_bytes() for p in MOD.rglob("*") if p.is_file()}
    assert actual==payload
manifest={"schema":1,"source_version":"0.1.60","source_run":44762226699,"source_artifact":14642176934,"source_commit":"581724a99b129b2c3772b207ac358ca1c3b00e34","source_zip_sha256":EXPECTED,"files":{p:sha(png[p]) for p in sorted(png)}}
(ROOT/"docs/builds/runtime-artwork.json").write_text(json.dumps(manifest,indent=2)+"\n")
ignore=ROOT/".gitignore"
t=ignore.read_text()
old="# Full 052 locomotive sheets produced by GitHub Actions, not distributed from Library.\n/ElectrifiedMainline/graphics/entity/locomotive-052/\n"
assert old in t
ignore.write_text(t.replace(old,"# Approved 052 runtime sheets are tracked; temporary render outputs stay under build/.\n"))
# Keep the historical renderer only for branches without the frozen manifest.
wf=ROOT/".github/workflows/build-mod.yml"
t=wf.read_text()
def once(a,b):
    global t
    assert t.count(a)==1,(a,t.count(a))
    t=t.replace(a,b,1)
once("      version: ${{ steps.version.outputs.version }}","      version: ${{ steps.version.outputs.version }}\n      frozen: ${{ steps.artwork.outputs.frozen }}")
once("  lua_qa:\n","      - id: artwork\n        run: |\n          if test -f docs/builds/runtime-artwork.json; then echo frozen=true >> \"$GITHUB_OUTPUT\"; else echo frozen=false >> \"$GITHUB_OUTPUT\"; fi\n  lua_qa:\n")
# Every active runtime art generation / old stage-specific validator is skipped
# only when an explicit manifest exists. The verifier then fails on any mismatch.
lines=t.splitlines()
skip={"Verify 0.1.48 visual continuity and approved assets","Generate and validate 0.1.49 alpha1 locomotive sprites","Retrieve complete 052 sprite set inside GitHub Actions","Verify complete 1280-cell native sprite contract","Render 053 concrete and elastomer layers","Render and verify 054 slab depth and grime","Generate and verify 057 inventory art and migration","Upload 052 QA preview"}
for i,l in enumerate(lines):
    if l.strip()=="render052:":
        assert lines[i+2].strip().startswith("if:")
        v=lines[i+2].split("if: ",1)[1]
        lines[i+2]="    if: needs.detect.outputs.frozen != 'true' && ("+v+")"
        continue
    if not l.startswith("      - name: "): continue
    if l.split(": ",1)[1] not in skip: continue
    nxt=lines[i+1]
    if nxt.startswith("        if: "):
        lines[i+1]="        if: needs.detect.outputs.frozen != 'true' && ("+nxt.split("if: ",1)[1]+")"
    else:
        lines[i]+="\n        if: needs.detect.outputs.frozen != 'true'"
t="\n".join(lines)+"\n"
once("      - name: Validate package boundary","      - name: Verify frozen runtime PNG manifest\n        if: needs.detect.outputs.frozen == 'true'\n        run: python scripts/verify_runtime_artwork.py\n      - name: Validate package boundary")
once('      - "docs/builds/013-payload.json"','      - "docs/builds/013-payload.json"\n      - "docs/builds/runtime-artwork.json"')
wf.write_text(t)
print("FREEZE PASS: all 129 runtime files identical to tested archive; 67 missing PNGs recovered, 83 manifest entries")
