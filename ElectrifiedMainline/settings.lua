data:extend{
  {type='bool-setting',name='em089-experimental-onboard-storage',setting_type='runtime-global',default_value=false,order='em089-a'},
  {type='int-setting',name='em089-storage-capacity-mj',setting_type='startup',default_value=60,minimum_value=1,maximum_value=10000,order='em089-b'},
  {type='int-setting',name='em089-storage-charge-kw',setting_type='startup',default_value=2000,minimum_value=1,maximum_value=100000,order='em089-c'},
  {type='int-setting',name='em089-storage-discharge-kw',setting_type='startup',default_value=4000,minimum_value=1,maximum_value=100000,order='em089-d'}
}
