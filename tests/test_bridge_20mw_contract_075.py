"""Offline regression: ensure single traction substation stays at the accepted 20 MW cap."""
import re
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class BridgeLimit(unittest.TestCase):
    def test_runtime_cap(self):
        src=(ROOT/"ElectrifiedMainline/scripts/power_bridge_058.lua").read_text(encoding="utf-8")
        self.assertEqual(re.findall(r'local M=\{LIMIT=(\d+)/60,',src),["20000000"])
        self.assertIn('SUB="em-35kv-traction-substation"',src)
    def test_native_input_output_cap(self):
        src=(ROOT/"ElectrifiedMainline/prototypes/power_bridge_058.lua").read_text(encoding="utf-8")
        self.assertIn('interface("em-25kv-bridge-input-058","dynamic","20MW","0W")',src)
        self.assertIn('interface("em-25kv-bridge-output-058","dynamic","0W","20MW")',src)
        self.assertNotIn('"120MW"',src)
if __name__=="__main__": unittest.main()
