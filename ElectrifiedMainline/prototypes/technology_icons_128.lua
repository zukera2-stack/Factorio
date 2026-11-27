-- Dedicated 256px research icons; inventory/recipe icons stay at native item size.
local function technology(name, filename)
  local t=assert(data.raw.technology[name]);t.icons=nil;t.icon=filename;t.icon_size=256
end
technology("em-electrified-railways", "__base__/graphics/technology/electric-energy-distribution-2.png")
technology("em-high-speed-rails", "__base__/graphics/technology/railway.png")
technology("em-regenerative-braking", "__base__/graphics/technology/battery.png")
technology("em-high-speed-locomotive", "__ElectrifiedMainline__/graphics/technology/high-speed-locomotive.png")
technology("em-battery-rolling-stock", "__ElectrifiedMainline__/graphics/technology/battery-rolling-stock.png")
