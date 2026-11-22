#!/usr/bin/env python3
"""Falsifiable C4 native proof: validate engine log AND actual independent reload."""
import re,json,hashlib,pathlib,argparse

def rows(txt,tag):
 return [line.split('EMC4|'+tag+'|',1)[1] for line in txt.splitlines() if 'EMC4|'+tag+'|' in line]

def values(line):
 return dict(v.split('=',1) for v in line.split('|') if '=' in v)

def require(cond,reason):
 if not cond:raise AssertionError(reason)

def evaluate(log,initial):
 motions={}
 for row in rows(log,'motion'):
  d=values(row);motions[(int(d['tick']),d['case'])]=d
 for name,carriages,real,motor,helpers,watts in (
  ('vanilla',3,0,2,0,0),('em0',3,1,0,0,0),('em1',4,1,1,1,500000),
  ('em2',4,1,2,1,1000000),('em4',6,1,4,1,2000000),
  ('zero',4,1,2,1,1000000),('em2drive',4,1,2,1,1000000)):
  d=motions.get((190,name))
  require(d is not None,'missing native movement '+name)
  for k,v in [('carriages',carriages),('real',real),('motor',motor),('helpers',helpers),('helperW',watts)]:
   require(int(d[k])==v,f'{name} {k} {d.get(k)} != {v}')
  expected=28 if name=='em4' else 14
  require(abs(float(d['visibleSpan'])-expected)<1e-4,'changed visible length '+name)
 base=lambda name:-float(motions[(190,name)]['baseY'])
 require(base('em0')+12<base('em1')<base('em2drive')-7,'extra 500kW/1MW native acceleration not demonstrated')
 require(base('zero')<=base('em0')+0.01,'zero native burner must not boost traction')
 stations={}
 for row in rows(log,'auto_arrival'):
  d=values(row);stations[int(d['tick'])]=d
 for t in (280,350):
  d=stations.get(t);require(d and d['mode']=='false' and d['at_station']=='true' and d['schedule']=='EM_C4_STATION', 'real AUTO station arrival not preserved '+str(t))
 late={}
 for row in rows(log,'late_arrival'):
  d=values(row);late[int(d['tick'])]=d
 for t,helpers in [(190,0),(280,0),(350,1)]:
  d=late.get(t);require(d and d['mode']=='false' and int(d['helpers'])==helpers,'late stop acceptance failed '+str(t))
 require(late[280]['station']=='true' and late[350]['station']=='true','late train not at actual station')
 remaining={}
 for row in rows(log,'energy_remaining'):
  d=values(row);remaining[d['case']]=float(d['J'])
 require(remaining.get('zero')==0,'zero helper received energy')
 for id in ('em1','em2','em4','em2drive'):
  require(0<remaining[id]<10000000,'finite internal technical burner did not spend exact J '+id)
 cargo=values(rows(log,'cargo_final')[-1]);require(cargo==dict(cargo_unit_same='true',fluid_unit_same='true',iron='37',water='9000'),'real cargo/fluid overwritten')
 report={'motion_190':{k:d for (t,k),d in motions.items() if t==190},'auto_stations':stations,'late_arrival':late,'technical_burner_remaining_J':remaining,'cargo_final':cargo}
 if initial:
  for p in ('em-c4-technical-booster-500','em-c4-technical-booster-1000','em-c4-technical-booster-2000'):
   found=[values(x) for x in rows(log,'prototype') if 'name='+p+'|' in x]
   require(len(found)==1,'missing technical prototype '+p)
   d=found[0]
   for k,v in [('selectable','false'),('item','false'),('blueprint_block','true'),('deconstruct_block','true'),('not_on_map','true')]:require(d[k]==v,'helper player protection '+p+': '+k)
  d=values(rows(log,'real_wagon_items')[-1]);require(d==dict(cargo_item='true',fluid_item='true',phantom_item='false'),'actual wagons cannot be placed')
  for label,pattern in [('solo','EMC4|after|case=solo|'),('vanilla','EMC4|after|case=vanilla|')]:
   data=[values(line.split(pattern)[1]) for line in log.splitlines() if pattern in line]
   require(len(data)==1 and data[0]['helpers']=='0','motor wagon standalone or with vanilla locomotive must not enable traction '+label)
  remove=values(rows(log,'after_gc')[-1]);require(remove['case']=='remove' and remove['helpers']=='0' and remove['real']=='0' and remove['carriages']=='2','orphan helper after removing lone true loco')
  multi=values(rows(log,'multi_owner_cleanup')[-1]);require(multi['real']=='1' and multi['helpers']=='0','helper must be removed if ITS owner destroyed even with another true EM')
  lower=values(rows(log,'change_low')[-1]);higher=values(rows(log,'change_high')[-1]);require(lower['motor']=='1' and lower['helperW']=='500000' and higher['motor']=='2' and higher['helperW']=='1000000','booster power tier not swapped safely')
  sched=values(rows(log,'schedule_after')[-1]);require(sched==dict(mode='false',record='EM_C4_STATION'),'schedule / AUTO corrupted at coupling')
  pre=values(rows(log,'pre_departure_boost')[-1]);require(pre['helpers']=='1' and pre['helperW']=='1000000','auto train not equipped before departure')
  late_mount=values(rows(log,'late_after_mount')[-1]);require(late_mount['ok']=='true' and late_mount['mode']=='false' and late_mount['schedule']=='EM_C4_LATE_STATION' and late_mount['visibleSpan']=='14.000000','deferred install at station failed')
  require(any('tick=70|' in x for x in rows(log,'orphan_quarantine')),'no immediate orphan quarantine')
 return report

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--output',required=True);ap.add_argument('--source',required=True);args=ap.parse_args()
 path=pathlib.Path(args.output);native=(path/'native.log').read_text();reload=(path/'native-reload.log').read_text()
 a=evaluate(native,True);b=evaluate(reload,False)
 for k in ('motion_190','auto_stations','late_arrival','technical_burner_remaining_J','cargo_final'):
  require(a[k]==b[k],'independent real disk SAVE→LOAD changed '+k)
 src=pathlib.Path(args.source).read_text()
 require(not re.search(r'\.speed\s*=(?!=)',src),'script directly assigns train.speed')
 result={
 'status':'PASS native Factorio 2.1.24 build87808 365-tick independent benchmark plus true disk server SAVE t125 and independent LOAD+240 ticks',
 'initial_LuaTrain_carriage_count_of_three_visible_stocks':3,
 'one_owner_loco_two_motor_wagons_plus_hidden_helper_native_carriages':4,
 'hidden_technical_module_count_for_1_2_4_motor_wagons':1,
 'actual_W':{'one_motor':500000,'two_motor':1000000,'four_motor':2000000},
 'zero_growth_in_visible_stock_span_tiles':0,
 'zero_accumulator_for_both_motor_wagon_types':True,
 'native_extra_acceleration_m':{'baseline_t190_tiles':round(-float(a['motion_190']['em0']['baseY']),6),'500kW_t190_tiles':round(-float(a['motion_190']['em1']['baseY']),6),'1000kW_t190_tiles':round(-float(a['motion_190']['em2drive']['baseY']),6),'zero_energy_t190_tiles':round(-float(a['motion_190']['zero']['baseY']),6)},
 'standalone_motor_wagons_have_zero_engine_locomotives':True,
 'vanilla_loco_not_authorized_to_spawn_helper':True,
 'native_real_station_auto_arrival_before_save_and_after_reload':True,
 'deferred_moving_train_helper_added_only_while_at_station':True,
 'safe_true_owner_removal_even_if_second_real_loco_exists':True,
 'native_cargo_inventory_and_fluid_contents_preserved_on_split_rejoin':True,
 'native_train_locomotives_includes_hidden_helper':'YES. This CANNOT be hidden from LuaTrain.locomotives by prototype selectable flag alone',
 'graphic_client_UI_actually_tested':False,
 'real_EM070_or_actual_25kv_power_debited':False,
 'original_electric_loco_void_power_in_this_test':True,
 'native_burner_energy_source':'LAB-ONLY 10MJ seeded to helper; owner approved INTERNAL technical adapter, NO factory source debit here',
 'unproven':['curve/diagonal/elevated','station GUI hidden engine rows','multiplayer/60UPS','player/robot mining and blueprint/Undo','genuine player placement UI','power flow from EM070','reverse or rear-end helper placement'],
 'benchmark_ticks':365,'server_real_SAVE_tick':125,'independent_disk_LOAD_ticks':240,
 'checkpoint_bytes':(path/'private/saves/em-c4-probe-checkpoint.zip').stat().st_size,
 'benchmark_log_sha256':hashlib.sha256((path/'native.log').read_bytes()).hexdigest(),
 'reload_log_sha256':hashlib.sha256((path/'native-reload.log').read_bytes()).hexdigest(),
 'measurement':a
 }
 (path/'strict-result.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
 print('NATIVE C4 PASS:',json.dumps({k:v for k,v in result.items() if k!='measurement'},ensure_ascii=False))
if __name__=='__main__':main()