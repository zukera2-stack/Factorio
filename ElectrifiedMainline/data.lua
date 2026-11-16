-- Factorio data-stage entry point.
-- Keep this loader at the mod root: Factorio discovers data.lua by filename.
require("prototypes.bootstrap")
require("prototypes.power_019")

-- Dedicated Alt+LMB alternate build uses true player cursor item.
require("prototypes.catenary_cursor_input_018")

-- 0.1.28 automatically wired 35 kV C-mast helper (not real AC power).
require("prototypes.native_wire_028")
