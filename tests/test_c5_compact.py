"""Static contract for a human-sized C5 fixture; real Factorio GUI still needs screenshots."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parent

class CompactHumanTest(unittest.TestCase):
    def test_c4_benchmark_omitted_when_C5_loaded(self):
        source=(ROOT/"em-c4-loco-mounted-probe"/"control.lua").read_text()
        guard='if script.active_mods["em-c5-client-gui-observer"] then return end'
        self.assertEqual(source.count(guard),2)
        self.assertIn("for y=-360,360,2 do",source)  # Historical C4 benchmark preserved
    def test_one_local_compact_scene_and_zero_seeded_J(self):
        source=(ROOT/"em-c5-client-gui-observer"/"control.lua").read_text()
        self.assertIn("for y=-24,32,2 do",source)
        self.assertIn("em-c4-technical-booster-1000",source)
        self.assertIn("helper_remaining_J",source)
        self.assertIn("native_carriages=",source)
        self.assertNotIn("remaining_burning_fuel=",source)
        self.assertNotIn("for y=-360",source)
        self.assertNotIn("local lanes=",source)
        self.assertNotIn("server_save(",source)
    def test_no_production_mod_loaded_in_test_artifact(self):
        source=(ROOT.parent/".github"/"workflows"/"build-mod.yml").read_text()
        self.assertIn("c5_disposable_client_test_artifact:",source)
        self.assertIn("em-c5-client-gui-observer",source)

if __name__=="__main__":
    unittest.main()
