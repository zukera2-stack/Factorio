import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
from pipeline import QAError, demo_sources, inspect, spec_read
from prepare import prepare_file

class PreparationTests(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root=Path(t.name)
        self.spec=spec_read()
        self.source=self.root/"source"
        demo_sources(self.spec,self.source)

    def test_all_demo_inputs_prepare_and_pass_qa(self):
        for a in self.spec["assets"]:
            out=self.root/"prepared"/a["source"]
            prepare_file(self.source/a["source"],a["id"],out)
            _,stats=inspect(out,a)
            self.assertGreaterEqual(stats["margin"],a["min_margin"])

    def test_opaque_raw_art_rejected(self):
        path=self.root/"opaque.png"
        Image.new("RGBA",(256,384),(50,60,80,255)).save(path)
        with self.assertRaisesRegex(QAError,"mostly opaque"):
            prepare_file(path,"pole",self.root/"no.png")
        self.assertFalse((self.root/"no.png").exists())

    def test_raw_art_touching_edge_rejected(self):
        path=self.root/"cropped.png"
        im=Image.new("RGBA",(256,384))
        ImageDraw.Draw(im).rectangle((0,25,100,200),fill=(70,80,90,255))
        im.save(path)
        with self.assertRaisesRegex(QAError,"touches image edge"):
            prepare_file(path,"pole",self.root/"no.png")

    def test_wrong_raw_mode_rejected(self):
        path=self.root/"rgb.png"
        Image.new("RGB",(256,384),(60,70,80)).save(path)
        with self.assertRaisesRegex(QAError,"RGBA"):
            prepare_file(path,"pole",self.root/"no.png")

if __name__=="__main__":
    unittest.main(verbosity=2)
