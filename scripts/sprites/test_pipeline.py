import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
from pipeline import QAError, demo_sources, inspect, run, shift, snippet, spec_read, striped

class SpriteTests(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root=Path(t.name)
        self.spec=spec_read()
        self.source=self.root/"source"
        demo_sources(self.spec,self.source)

    def test_positive_assets(self):
        for a in self.spec["assets"]:
            image,stats=inspect(self.source/a["source"],a)
            self.assertEqual(list(image.size),a["size"])
            self.assertGreater(stats["soft_edge_pixels"],20)

    def test_end_to_end_deterministic(self):
        out=self.root/"out"
        first=run("demo",None,out)
        self.assertEqual(len(first["assets"]),3)
        self.assertTrue((out/"preview.png").is_file())
        self.assertIn("draw_as_shadow = true",snippet(self.spec))
        self.assertIn("direction_count = 1",snippet(self.spec))
        hashes=[x["output_sha256"] for x in first["assets"]]
        second=run("demo",None,out)
        self.assertEqual(hashes,[x["output_sha256"] for x in second["assets"]])

    def test_stripes_rejected(self):
        a=self.spec["assets"][0]
        im=Image.new("RGBA",tuple(a["size"]))
        for x in range(im.width):
            for y in range(im.height):
                if x%8<4:
                    im.putpixel((x,y),(0,255,150,180))
        self.assertTrue(striped(im))
        im.save(self.source/a["source"])
        with self.assertRaisesRegex(QAError,"stripes"):
            inspect(self.source/a["source"],a)

    def test_uniform_image_is_not_misclassified_as_periodic_stripes(self):
        im=Image.new("RGBA",(256,384),(55,60,80,255))
        self.assertFalse(striped(im))

    def test_opaque_background_rejected(self):
        a=self.spec["assets"][0]
        Image.new("RGBA",tuple(a["size"]),(55,60,80,255)).save(self.source/a["source"])
        with self.assertRaises(QAError):
            inspect(self.source/a["source"],a)

    def test_rgb_rejected(self):
        a=self.spec["assets"][0]
        Image.new("RGB",tuple(a["size"]),(55,60,80)).save(self.source/a["source"])
        with self.assertRaisesRegex(QAError,"RGBA"):
            inspect(self.source/a["source"],a)

    def test_wrong_dimensions_rejected(self):
        a=self.spec["assets"][0]
        Image.new("RGBA",(32,32)).save(self.source/a["source"])
        with self.assertRaisesRegex(QAError,"RGBA"):
            inspect(self.source/a["source"],a)

    def test_cropped_edge_rejected(self):
        a=self.spec["assets"][0]
        with Image.open(self.source/a["source"]) as im:
            im=im.copy()
        ImageDraw.Draw(im).rectangle((0,0,8,25),fill=(200,40,40,255))
        im.save(self.source/a["source"])
        with self.assertRaisesRegex(QAError,"margin"):
            inspect(self.source/a["source"],a)

    def test_missing_production_sources_rejected(self):
        with self.assertRaisesRegex(QAError,"source missing"):
            run("production",self.root/"missing",self.root/"out")

    def test_demo_install_rejected(self):
        with self.assertRaisesRegex(QAError,"human-approved"):
            run("demo",None,self.root/"out",install=True)

    def test_shift_in_world_tiles(self):
        self.assertEqual(shift(self.spec["assets"][0]),(0.0,-2.53125))

if __name__=="__main__":
    unittest.main(verbosity=2)
