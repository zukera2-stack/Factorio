-- Factorio data-stage entry point.
-- Keep this loader at the mod root: Factorio discovers data.lua by filename.
require("prototypes.bootstrap")
require("prototypes.power_019")

-- Dedicated Alt+LMB alternate build uses true player cursor item.
require("prototypes.catenary_cursor_input_018")

-- Optional 0.1.26 native-wire attachment experiment (command only).
require("prototypes.native_wire_probe_026")

-- Native auto-connection endpoint prototype, attached by scripts/native_wire_028.lua.
require("prototypes.native_wire_auto_028")

-- Isolated 0.1.30 double-contact wire visual pilot.
require("prototypes.catenary_art_030")

-- 0.1.49 alpha1: native body/mask/shadow, independently attached pantograph.
require("prototypes.locomotive_visual_049")

-- 053: concrete HSR appearance only; no rail geometry or runtime changes.
require("prototypes.hsr_concrete_053")

-- 058 isolated native power bridge.
require("prototypes.power_bridge_058")

-- 0.1.63 TEST BRANCH ONLY: two real native wagon types and finite-J hidden GUI adapter.
require("prototypes.em072_c5_fullmod_trial_063")

-- Research 0.1.64: non-destructive retirement of redundant factory pole.
require("prototypes.em063_retire_ordinary_pole_064")
