"""Runtime-package boundary tests; no Factorio engine required."""
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from package_mod import REQUIRED, inventory, package


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.mod = self.root / "ElectrifiedMainline"
        self.mod.mkdir()
        for file in REQUIRED:
            (self.mod / file).write_text("-- unchanged")
        (self.mod / "info.json").write_text(json.dumps(dict(name="ElectrifiedMainline", version="0.1.48", title="Test", author="Test", factorio_version="2.1")))

    def test_runtime_payload(self):
        for filename in ("scripts/runtime.lua", "graphics/entity/mast.png", "locale/ru/ru.cfg", "migrations/0.1.48.lua"):
            p = self.mod / filename
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(b"payload")
        a = package(self.mod, self.root / "out")
        original = a.read_bytes()
        self.assertEqual(package(self.mod, self.root / "out").read_bytes(), original)
        with zipfile.ZipFile(a) as z:
            self.assertIsNone(z.testzip())
            self.assertEqual(set(z.namelist()), {"ElectrifiedMainline/" + f for f in inventory(self.mod)})
            self.assertEqual(z.read("ElectrifiedMainline/scripts/runtime.lua"), b"payload")

    def test_reject_development_material(self):
        for filename in ("TEST_NETWORK_048.txt", "SPRITES_039_QA.json", "scripts/README.md", "geometry-045-atlas.png", "graphics/qa/report.json", "scripts/__pycache__/bad.lua", "dist/old.zip"):
            p = self.mod / filename
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(b"not game data")
            with self.subTest(filename=filename), self.assertRaisesRegex(ValueError, "Non-runtime"):
                inventory(self.mod)
            p.unlink()

    def test_missing_required(self):
        (self.mod / "data-final-fixes.lua").unlink()
        with self.assertRaisesRegex(ValueError, "Missing Factorio entrypoints"):
            inventory(self.mod)


if __name__ == "__main__":
    unittest.main()
