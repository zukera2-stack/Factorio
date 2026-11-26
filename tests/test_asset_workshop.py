"""Standalone tests of the exact source-edit / image classification gate."""
from __future__ import annotations

import importlib.util
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from PIL import Image

MODULE = Path(__file__).resolve().parents[1] / "scripts/assets/qa_sprite_edit.py"
spec = importlib.util.spec_from_file_location("qa_sprite_edit", MODULE)
assert spec and spec.loader
qa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qa)


class AssetWorkshopTests(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.a = Path(self.tmp.name) / "source.png"
        self.b = Path(self.tmp.name) / "result.png"
        im = Image.new("RGBA", (16, 8))
        for yy in range(1, 7):
            for xx in range(2, 7):
                im.putpixel((xx, yy), (80, 80, 80, 255))
            for xx in range(10, 15):
                im.putpixel((xx, yy), (80, 80, 80, 255))
        im.save(self.a)
        im.save(self.b)

    def test_same_source_passes(self):
        r = qa.check(self.a, self.b, "repaint", 8, 8, 2)
        self.assertTrue(r["alpha_identical"])
        self.assertEqual(r["frame_grid"]["count"], 2)
        self.assertEqual(r["windows_game_acceptance"], "NOT_TESTED")

    def test_recolor_without_alpha_passes(self):
        with Image.open(self.a) as im:
            im = im.copy()
            im.putpixel((3, 3), (200, 40, 40, 255))
            im.save(self.b)
        r = qa.check(self.a, self.b, "repaint", 8, 8, 2)
        self.assertTrue(r["alpha_identical"])
        self.assertIsNotNone(r["changed_bbox"])

    def test_alpha_modified_rejected(self):
        with Image.open(self.a) as im:
            im = im.copy()
            im.putpixel((3, 3), (200, 40, 40, 0))
            im.save(self.b)
        with self.assertRaisesRegex(qa.AssetCheckError, "alpha changed"):
            qa.check(self.a, self.b, "repaint", 8, 8, 2)

    def test_wrong_canvas_rejected(self):
        Image.new("RGBA", (12, 8), (3, 4, 5, 255)).save(self.b)
        with self.assertRaisesRegex(qa.AssetCheckError, "canvas"):
            qa.check(self.a, self.b, "repaint", 8, 8, 2)

    def test_rgb_sprite_rejected(self):
        Image.new("RGB", (16, 8), (3, 4, 5)).save(self.b)
        with self.assertRaisesRegex(qa.AssetCheckError, "RGBA"):
            qa.check(self.a, self.b, "component", 8, 8, 2)

    def test_missing_frame_contract_rejected(self):
        with self.assertRaisesRegex(qa.AssetCheckError, "requires known frame"):
            qa.check(self.a, self.b, "repaint")

    def test_wrong_frame_count_rejected(self):
        with self.assertRaisesRegex(qa.AssetCheckError, "expected frame grid"):
            qa.check(self.a, self.b, "repaint", 8, 8, 3)

    def test_fully_empty_frame_rejected(self):
        with Image.open(self.a) as im:
            im = im.copy()
            for y in range(8):
                for x in range(8):
                    im.putpixel((x, y), (0, 0, 0, 0))
            im.save(self.b)
        with self.assertRaisesRegex(qa.AssetCheckError, "alpha changed"):
            qa.check(self.a, self.b, "repaint", 8, 8, 2)
        with self.assertRaisesRegex(qa.AssetCheckError, "fully transparent"):
            qa.check(self.a, self.b, "component", 8, 8, 2)

    def test_study_is_not_game_asset(self):
        Image.new("RGB", (16, 8), (122, 88, 42)).save(self.b)
        r = qa.check(self.a, self.b, "study")
        self.assertEqual(r["classification"], "REFERENCE_STUDY_NOT_GAME_ASSET")
        self.assertIsNone(r["alpha_identical"])

    def test_component_different_canvas_but_valid_frame(self):
        Image.new("RGBA", (8, 8), (100, 20, 20, 100)).save(self.b)
        r = qa.check(self.a, self.b, "component", 8, 8, 1)
        self.assertEqual(r["candidate_size"], [8, 8])
        self.assertFalse(r["alpha_identical"])

    def test_intentionally_empty_component_layer_needs_explicit_flag(self):
        Image.new("RGBA", (16, 8)).save(self.b)
        with self.assertRaisesRegex(qa.AssetCheckError, "zero visible"):
            qa.check(self.a, self.b, "component", 8, 8, 2)
        r = qa.check(self.a, self.b, "component", 8, 8, 2, allow_empty_layer=True)
        self.assertEqual(r["frame_alpha_bounds"], [None, None])
        self.assertTrue(r["allow_empty_layer"])

    def test_empty_layer_flag_rejected_for_repaint(self):
        with self.assertRaisesRegex(qa.AssetCheckError, "only be explicitly"):
            qa.check(self.a, self.b, "repaint", 8, 8, 2, allow_empty_layer=True)

    def test_unsupported_mode_rejected(self):
        with self.assertRaisesRegex(qa.AssetCheckError, "mode must"):
            qa.check(self.a, self.b, "magic", 8, 8, 2)

    def test_non_png_rejected(self):
        path = Path(self.tmp.name) / "fake.jpg"
        path.write_bytes(self.a.read_bytes())
        with self.assertRaisesRegex(qa.AssetCheckError, "PNG"):
            qa.check(path, self.b, "repaint", 8, 8, 2)


if __name__ == "__main__":
    unittest.main()
