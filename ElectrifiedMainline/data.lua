-- Factorio data-stage entry point.
-- Keep this loader at the mod root: Factorio discovers data.lua by filename.
require("prototypes.bootstrap")
require("prototypes.power_019")

-- Dedicated Alt+LMB alternate build uses true player cursor item.
require("prototypes.catenary_cursor_input_018")

-- 0.1.20 experimental item-local LMB; adds NO world entities.
require("prototypes.click_capsule_probe_020")
