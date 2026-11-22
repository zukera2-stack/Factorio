"""Offline parser checks only; NOT a Factorio/game GUI test."""
import pathlib
import sys
import unittest
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from verify_c5_gui import analyze

class C5LogParserTests(unittest.TestCase):
    def test_no_gui_is_not_pass(self):
        data = analyze("EMC5|manual_inspect|tick=50|train_id=1|technical_helpers=1")
        self.assertEqual(data["status"], "NO_NATIVE_TRAIN_GUI_EVENTS")
        self.assertEqual(data["visual_train_gui_verdict"], "UNVERIFIED_REQUIRES_CLIENT_SCREENSHOTS")

    def test_gui_with_helper_is_only_observed(self):
        line = "EMC5|gui_open|tick=200|case=em2|train_id=42|native_locomotives=2|real_locomotives=1|technical_helpers=1"
        data = analyze(line)
        self.assertEqual(data["status"], "COUNTS_OBSERVED_ONLY")
        self.assertTrue(data["helper_present_while_gui_opened"])
        self.assertEqual(data["observed_cases"], ["em2"])
        self.assertNotEqual(data["visual_train_gui_verdict"], "PASS")

if __name__ == "__main__":
    unittest.main()
