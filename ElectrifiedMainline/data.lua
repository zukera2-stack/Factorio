-- Factorio data-stage entry point.
-- Keep this loader at the mod root: Factorio discovers data.lua by filename.
require("prototypes.bootstrap")
require("prototypes.power_019")

-- Dedicated Alt+LMB alternate build uses true player cursor item.
require("prototypes.catenary_cursor_input_018")

-- 0.1.19 isolated SAME-TYPE native rail-signal placement experiment.
require("prototypes.native_signal_probe_019")
