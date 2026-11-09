-- ElectrifiedMainline/data-final-fixes.lua
-- Final fixes and patches applied after all data modifications.

-- Note: In Factorio 2.1, electric-pole doesn't exist as a base entity type.
-- This file is kept for compatibility but many features are simplified.

-- Mark high-speed rails as electrifiable (optional flag for future use)
if data.raw["straight-rail"] and data.raw["straight-rail"]["em-high-speed-straight-rail"] then
  data.raw["straight-rail"]["em-high-speed-straight-rail"].electrifiable = true
end

-- FIX: In Factorio 2.1, curved rails are separate types. Use 'curved-rail-a'.
if data.raw["curved-rail-a"] and data.raw["curved-rail-a"]["em-curved-high-speed-rail"] then
  data.raw["curved-rail-a"]["em-curved-high-speed-rail"].electrifiable = true
end

if data.raw["half-diagonal-rail"] and data.raw["half-diagonal-rail"]["em-half-diagonal-high-speed-rail"] then
    data.raw["half-diagonal-rail"]["em-half-diagonal-high-speed-rail"].electrifiable = true
end

-- Note: In 2.1, locomotives use energy_source :: BurnerEnergySource or VoidEnergySource (not power_source).
-- The electric locomotive is defined in data.lua with void energy source.
