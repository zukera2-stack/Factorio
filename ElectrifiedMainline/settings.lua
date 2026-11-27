data:extend{
  {type='int-setting',name='em089-storage-capacity-mj',setting_type='startup',default_value=60,minimum_value=1,maximum_value=10000,order='em089-b'},
  {type='int-setting',name='em089-storage-charge-kw',setting_type='startup',default_value=2000,minimum_value=1,maximum_value=100000,order='em089-c'},
  {type='int-setting',name='em089-storage-discharge-kw',setting_type='startup',default_value=4000,minimum_value=1,maximum_value=100000,order='em089-d'}
}


-- Standard battery-wagon capacity and power limits.
data:extend{
 {type="int-setting",name="em107-battery-wagon-capacity-mj",setting_type="startup",default_value=600,minimum_value=1,maximum_value=10000,order="em107-b"},
 {type="int-setting",name="em107-battery-wagon-charge-kw",setting_type="startup",default_value=5000,minimum_value=1,maximum_value=100000,order="em107-c"},
 {type="int-setting",name="em107-battery-wagon-discharge-kw",setting_type="startup",default_value=10000,minimum_value=1,maximum_value=100000,order="em107-d"}
}

-- Runtime map-wide opt-in; preserves the movement-only default.
data:extend{{type="bool-setting",name="em128-charge-at-standstill",setting_type="runtime-global",default_value=false,order="em089-e"}}
