import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageOps
from pipeline import QAError, demo_sources, spec_read
from game_test_pack import build, atlas, verify_atlas, FRAME

class GameTestPackTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.mod=self.root/"ElectrifiedMainline"

    def test_demo_atlas_generation_and_report(self):
        report=build(self.mod,"demo",output=self.root/"report")
        self.assertEqual(report["frame_order"],["right","right","left","left"])
        self.assertEqual(report["foot_anchor_in_each_frame"],[256,354])
        self.assertFalse(report["factorio_2_1_20_game_test"])
        for name,info in report["files"].items():
            with Image.open(self.mod/"graphics/entity/35kv"/name) as image:
                self.assertEqual(image.mode,"RGBA")
                self.assertEqual(list(image.size),info["size"])
        self.assertTrue((self.root/"report/atlas-report.json").is_file())

    def test_mirror_is_pixel_exact(self):
        build(self.mod,"demo")
        with Image.open(self.mod/"graphics/entity/35kv/pole-4dir-hr.png") as im:
            a=im.crop((0,0,512,384))
            b=im.crop((0,384,512,768))
            self.assertEqual(ImageOps.mirror(a).tobytes(),b.tobytes())

    def test_corrupted_mirror_is_rejected(self):
        build(self.mod,"demo")
        with Image.open(self.mod/"graphics/entity/35kv/pole-4dir-hr.png") as im:
            im=im.copy()
        im.putpixel((0,384),(255,0,0,255))
        with self.assertRaisesRegex(QAError,"mirror"):
            verify_atlas(im,"pole")

    def test_unapproved_external_art_is_labeled_experimental(self):
        source=self.root/"art"
        demo_sources(spec_read(),source)
        report=build(self.mod,"experimental",source)
        self.assertEqual(report["source_approval"],"not_approved")
        self.assertEqual(report["art_mode"],"experimental")

    def test_demo_refuses_external_art(self):
        with self.assertRaisesRegex(QAError,"cannot use external"):
            build(self.mod,"demo",self.root/"art")

    def test_experimental_requires_sources(self):
        with self.assertRaisesRegex(QAError,"requires a source"):
            build(self.mod,"experimental")

if __name__=="__main__":
    unittest.main(verbosity=2)
