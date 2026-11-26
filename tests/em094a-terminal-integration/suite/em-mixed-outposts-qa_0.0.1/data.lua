-- QA-only source, unavailable in the real mod. Seeded once by fixture.
local source=table.deepcopy(data.raw['electric-energy-interface']['em-25kv-bridge-output-058'])
source.name='em092-qa-finite-source'
data:extend{source}
local offer=table.deepcopy(source);offer.name='em092-qa-offer-only';data:extend{offer}
