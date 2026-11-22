"""Full-source 0.1.63: static checks only, NOT a native Factorio game run."""
import json
import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
MOD=ROOT/"ElectrifiedMainline"

class FullModTrialTest(unittest.TestCase):
    def test_full_mod_not_two_base_only_labs(self):
        meta=json.loads((MOD/"info.json").read_text(encoding="utf-8"))
        self.assertEqual(meta["name"],"ElectrifiedMainline")
        self.assertIn(meta["version"],("0.1.63","0.1.64","0.1.65"))
        self.assertEqual(meta["factorio_version"],"2.1")
        self.assertNotIn("em-c4-loco-mounted-probe",str(meta))
        self.assertNotIn("em-c5-client-gui-observer",str(meta))
    def test_preserved_real_data_stage(self):
        source=(MOD/"data.lua").read_text()
        for name in ("prototypes.bootstrap","prototypes.power_019",
                     "prototypes.locomotive_visual_049","prototypes.hsr_concrete_053",
                     "prototypes.power_bridge_058","prototypes.em072_c5_fullmod_trial_063"):
            self.assertIn('require("'+name+'")',source)
    def test_no_override_of_undo_and_power_scripts(self):
        source=(MOD/"scripts/control.lua").read_text()
        self.assertIn('require("scripts.power_bridge_058")',source)
        self.assertIn("on_undo_applied",source)
        self.assertIn("on_redo_applied",source)
        self.assertIn('require("scripts.em072_c5_fullmod_trial_063")',source)
        p=(MOD/"scripts/em072_c5_fullmod_trial_063.lua").read_text()
        self.assertNotIn("script.on_event(defines.events.on_tick",p)
        self.assertNotIn("script.on_init",p)
        self.assertNotIn("remaining_burning_fuel=",p)
        self.assertNotIn("train.speed =",p)
        self.assertIn('"em-high-speed-straight-rail"',p)
        self.assertIn('"em-electric-locomotive"',p)
        self.assertIn('"em-35kv-traction-substation"',p)
    def test_real_motor_wagons_and_0j_hidden_helper(self):
        p=(MOD/"prototypes/em072_c5_fullmod_trial_063.lua").read_text()
        self.assertIn('wagon("cargo-wagon","cargo-wagon",cargo_name)',p)
        self.assertIn('wagon("fluid-wagon","fluid-wagon",fluid_name)',p)
        self.assertIn('type="burner"',p)
        self.assertIn('p.selectable_in_game=false',p)
        self.assertNotIn('type="void"',p)
        self.assertIn('"not-blueprintable"',p)
    def test_every_main_game_entrypoint_exists(self):
        for name in ("data.lua","data-updates.lua","data-final-fixes.lua",
                     "control.lua","info.json"):
            self.assertTrue((MOD/name).is_file(),name)

if __name__=="__main__":
    unittest.main()
