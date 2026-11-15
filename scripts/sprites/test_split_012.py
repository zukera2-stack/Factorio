import shutil
import tempfile
import unittest
from pathlib import Path
from PIL import Image
from split_012 import make,OUT

ROOT=Path(__file__).resolve().parents[2]
GRAPHICS=ROOT/"ElectrifiedMainline/graphics/entity/35kv"

class Split012Tests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder=Path(self.temp.name)
        for f in ("pole-4dir-hr.png","pole-shadow-4dir-hr.png"):
            shutil.copy2(GRAPHICS/f,self.folder/f)

    def test_mask_and_metadata(self):
        info=make(self.folder)
        self.assertFalse(info["game_tested"])
        self.assertFalse(info["signal_prototypes_created"])
        self.assertEqual(info["outputs"]["pole-arm-hr.png"]["size"],[512,512])
        for f in OUT:
            self.assertTrue((self.folder/f).is_file())

    def test_mast_stays_upright_and_arm_separate(self):
        make(self.folder)
        with Image.open(self.folder/"pole-mast-hr.png") as m:
            self.assertGreater(m.getchannel("A").getpixel((256,250)),32)
            self.assertEqual(m.getchannel("A").getpixel((360,86)),0)
        with Image.open(self.folder/"pole-arm-hr.png") as a:
            self.assertGreater(a.getchannel("A").getpixel((360,262)),32)

    def test_no_crossbar_left(self):
        make(self.folder)
        with Image.open(self.folder/"pole-arm-hr.png") as a:
            alpha=a.getchannel("A")
            self.assertFalse(any(alpha.getpixel((x,y))>32
                for y in range(195,350) for x in range(0,130)))

    def test_reproducible_hashes(self):
        self.assertEqual(make(self.folder)["outputs"],make(self.folder)["outputs"])

    def test_wrong_atlas_rejected(self):
        Image.new("RGBA",(64,64)).save(self.folder/"pole-4dir-hr.png")
        with self.assertRaisesRegex(ValueError,"atlas"):
            make(self.folder)

if __name__=="__main__":
    unittest.main(verbosity=2)
