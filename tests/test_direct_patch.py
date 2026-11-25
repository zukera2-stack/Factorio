"""No-game, no-network regression checks of the Direct Patch format."""
from __future__ import annotations
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import direct_patch as dp


class PatchTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.a = self.root / "base"
        self.b = self.root / "candidate"
        for p, version in ((self.a,"0.1.84"),(self.b,"0.1.85")):
            p.mkdir()
            (p / "info.json").write_text(json.dumps({"name":"ElectrifiedMainline", "version":version}),encoding="utf-8")
            (p / "scripts").mkdir()
        (self.a / "scripts" / "original.lua").write_text("return 1\n")
        (self.b / "scripts" / "original.lua").write_text("return 2\n")
        self.zip = self.root / "patch.zip"
        self.man = self.root / "manifest.json"

    def build(self, record_deletions=False):
        return dp.build(self.a,self.b,self.zip,self.man,record_deletions=record_deletions)

    def test_build_validate_no_install_and_determinism(self):
        old=self.a.joinpath("scripts/original.lua").read_bytes()
        m=self.build()
        self.assertEqual([e["path"] for e in m["files"]],["info.json","scripts/original.lua"])
        self.assertEqual(self.a.joinpath("scripts/original.lua").read_bytes(),old)
        with zipfile.ZipFile(self.zip) as z:
            self.assertEqual(z.namelist(),["info.json","scripts/original.lua"])
            self.assertNotIn("manifest.json",z.namelist())
        self.assertEqual(dp.verify(self.a,self.zip,self.man,expected_target=self.b),m)
        h=m["zip_sha256"]
        self.zip.unlink();self.man.unlink();self.build()
        self.assertEqual(h, dp.digest_bytes(self.zip.read_bytes()))

    def test_wrong_base_blocked(self):
        self.build()
        self.a.joinpath("scripts/original.lua").write_text("wrong")
        with self.assertRaisesRegex(dp.PatchError,"Base folder"):
            dp.verify(self.a,self.zip,self.man)

    def test_removed_file_requires_explicit_manifest(self):
        self.b.joinpath("scripts/original.lua").unlink()
        with self.assertRaisesRegex(dp.PatchError,"cannot be deleted"):
            self.build()
        m=self.build(record_deletions=True)
        self.assertEqual(m["delete_after_extract"][0]["path"],"scripts/original.lua")
        dp.verify(self.a,self.zip,self.man,expected_target=self.b)

    def test_invalid_version_or_name(self):
        self.b.joinpath("info.json").write_text(json.dumps({"name":"OtherMod","version":"0.1.85"}))
        with self.assertRaisesRegex(dp.PatchError,"identity"):
            self.build()
        self.b.joinpath("info.json").write_text(json.dumps({"name":"ElectrifiedMainline","version":"0.1.86"}))
        with self.assertRaisesRegex(dp.PatchError,"adjacent"):
            self.build()

    def test_path_traversal_windows_case_and_absolute(self):
        for name in ["../bad.lua","/etc/passwd","scripts/../info.json","scripts\\hi.lua","scripts//bad.lua","manifest.json","docs/readme.md","C:/foo.lua"]:
            with self.subTest(name=name),self.assertRaises(dp.PatchError):
                dp.safe_path(name)
        (self.b/"scripts"/"ORIGINAL.lua").write_text("shadow")
        with self.assertRaisesRegex(dp.PatchError,"case collision"):
            self.build()

    def test_symlink_rejected(self):
        (self.b/"scripts"/"linked.lua").symlink_to(self.a/"scripts"/"original.lua")
        with self.assertRaisesRegex(dp.PatchError,"Symlink"):
            self.build()

    def test_corrupt_manifest_or_zip_rejected(self):
        self.build()
        m=json.loads(self.man.read_text())
        m["files"][0]["path"]="../unsafe"
        self.man.write_text(json.dumps(m))
        with self.assertRaises(dp.PatchError):
            dp.verify(self.a,self.zip,self.man)
        self.man.unlink(); self.zip.unlink()
        self.build()
        b=bytearray(self.zip.read_bytes());b[50]^=1
        self.zip.write_bytes(b)
        with self.assertRaisesRegex(dp.PatchError,"ZIP SHA256"):
            dp.verify(self.a,self.zip,self.man)

    def test_registry_continuity_and_integrity(self):
        reg = json.loads((ROOT / "patches/registry.json").read_text(encoding="utf-8"))
        self.assertEqual(reg["schema"], "factorio-direct-patch-registry/v1")
        entries = reg["entries"]
        self.assertTrue(entries)
        self.assertEqual(len({e["id"] for e in entries}), len(entries))
        for i, e in enumerate(entries):
            self.assertRegex(e["id"], r"^EM\d{3}$")
            self.assertRegex(e["zip_sha256"], r"^[0-9a-f]{64}$")
            self.assertTrue(e["zip"].startswith("/Factorio/Patches/"))
            self.assertNotEqual(e["from"], e["to"])
            if i:
                self.assertEqual(e["from"], entries[i-1]["to"])
            dp.case_unique(e["manual_deletions"])
        self.assertEqual(entries[-1]["to"], reg["latest_integration_candidate_version"])

    def test_output_overwrite_prevented(self):
        self.build()
        with self.assertRaisesRegex(dp.PatchError,"Outputs exist"):
            self.build()


if __name__=="__main__":
    unittest.main()
