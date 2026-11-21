#!/usr/bin/env python3
"""EM066: auditable dissipation policy for existing EM065 finite-reservoir evidence.

This is a POLICY/RECONCILIATION tool. It does not modify Factorio's energy
simulation or pretend that the game already models line capacitance and
inductance. Run with --self-test for synthetic invariants and real EM065 cases.
Optional --strict exits 1 while non-demolition losses remain unaccounted.
"""
import argparse
import json
import math
from pathlib import Path

# Each ID refers to the actual observed operation in EM065, not an invented
# electrical-fault object. See 25kv-closed-reservoir-065.md.
EVENTS = {
    201: ("mast_removed", "intentional_network_disconnection"),
    441: ("rail_removed", "intentional_network_disconnection"),
    444: ("rail_settling", "post_switching"),
    671: ("receiving_substation_demolished", "demolition"),
    896: ("factory_grids_merged", "reconfiguration"),
    900: ("factory_merge_settling", "post_switching"),
    902: ("factory_merge_settling", "post_switching"),
    1002: ("factory_grids_split", "reconfiguration"),
    1003: ("factory_split_settling", "post_switching"),
}

TOL_J = 4.0


def field_energy_example(*, c_nf_per_km=10, l_mh_per_km=1,
                         distance_km=1, voltage_v_rms=25000,
                         current_a_rms=800):
    """Average stored field energy for a simple illustrative AC line model.

    This is deliberately NOT the energy in the game's EEI buffer.
    Parameters are hypothetical, and should not be called as-built data.
    """
    if any(v < 0 for v in (c_nf_per_km,l_mh_per_km,distance_km,voltage_v_rms,current_a_rms)):
        raise ValueError("physical parameters must be nonnegative")
    c_f = c_nf_per_km * 1e-9 * distance_km
    l_h = l_mh_per_km * 1e-3 * distance_km
    electric_j = 0.5*c_f*voltage_v_rms**2
    magnetic_j = 0.5*l_h*current_a_rms**2
    return {"electric_field_average_j": electric_j,
            "magnetic_field_average_j": magnetic_j,
            "combined_field_average_j": electric_j+magnetic_j,
            "parameters": {"c_nf_per_km": c_nf_per_km,
                           "l_mh_per_km": l_mh_per_km,
                           "distance_km": distance_km,
                           "voltage_v_rms": voltage_v_rms,
                           "current_a_rms": current_a_rms},
            "is_game_line_field_model": False}


def allowed_event_dissipation(*, kind, measured_loss_j, station_own_hidden_eei_j=0,
                              metered_line_field_destroyed_j=0,
                              line_energy_in_total_ledger=False):
    """Maximum permissible energy loss under the currently approved contract.

    Physical intuition is never an alternative to metering: hypothetical line
    energy does NOT offset disappearing EEI buffers in a reservoir ledger.
    """
    for k, v in {"loss": measured_loss_j,
                 "own_station_eei": station_own_hidden_eei_j,
                 "line_field": metered_line_field_destroyed_j}.items():
        if not isinstance(v, (int,float)) or not math.isfinite(v) or v < 0:
            raise ValueError(f"{k} must be finite and nonnegative")
    if kind == "demolition":
        return min(measured_loss_j, station_own_hidden_eei_j)
    if kind == "explicit_fault_field_dissipation" and line_energy_in_total_ledger:
        return min(measured_loss_j, metered_line_field_destroyed_j)
    # No modeled line field exists in EM065; a routine switch, wire removal,
    # or merge/split has no energy-dissipation allowance merely by label.
    return 0.0


def classify_case(case):
    e = case['energy_ledger']
    rows = e['sampled_loss_events']
    recorded_j = int(e['loss_j'])
    if abs(sum(row['lost_j_rounded'] for row in rows)-recorded_j) > TOL_J:
        raise AssertionError(f"unexplained events missing in {case['variant']}")
    demolition = [x for x in rows if int(x['tick'])==671]
    if len(demolition)!=1:
        raise AssertionError("exactly one measured demolition event required")
    allowance_j=int(e['approved_demolition_discard_j'])
    owned=int(e['demolished_station_buffer_j'])
    live_owned=int(e['surviving_station_buffer_j_at_demolition'])
    if allowance_j != owned:
        raise AssertionError("demolition allowance must equal actual owned-port joules")
    if allowance_j > demolition[0]['lost_j_rounded']+TOL_J:
        raise AssertionError("allowance exceeds measured demolition event loss")
    if e['created_j'] > TOL_J:
        raise AssertionError("unexplained energy creation is forbidden")
    output=[]
    for row in rows:
        t=int(row['tick'])
        if t not in EVENTS:
            raise AssertionError(f"unknown loss at tick {t}; cannot auto-waive")
        name, kind=EVENTS[t]
        loss=int(row['lost_j_rounded'])
        actual_station=owned if kind=='demolition' else 0
        accepted=allowed_event_dissipation(kind=kind,measured_loss_j=loss,
                                           station_own_hidden_eei_j=actual_station)
        output.append({"tick":t,"event":name,"kind":kind,"lost_j":loss,
                       "approved_j":round(accepted),
                       "unaccounted_j":round(loss-accepted)})
    accepted_total=sum(x['approved_j'] for x in output)
    unaccounted=recorded_j-accepted_total
    if accepted_total != allowance_j:
        raise AssertionError("policy counted a forbidden discharge or double counted")
    if abs(unaccounted-int(e['remaining_unexplained_ledger_deficit_j']))>TOL_J:
        raise AssertionError("reconciliation disagrees with independently recorded evidence")
    return {"variant":case['variant'],"observed_total_loss_j":recorded_j,
            "approved_demolition_station_own_eei_j":accepted_total,
            "other_stations_own_eei_at_demolition_j":live_owned,
            "unaccounted_bridge_or_network_loss_j":unaccounted,
            "unexplained_created_energy_j":int(e['created_j']),
            "energy_gate":"FAIL" if unaccounted>TOL_J else "PASS",
            "events":output}


def reconcile(evidence):
    if evidence['tested_variants'] != 2 or len(evidence['cases'])!=2:
        raise AssertionError('expected EM065 two independent variants')
    if evidence['engine']!='2.1.24 build 87808':
        raise AssertionError('unknown native engine provenance')
    if evidence['game_zip_sha256']!='a869c7fb5b76aa49ae38f50af8f1c74b9e8dcd9254e4e354b127e3698d966a07':
        raise AssertionError('unknown game ZIP provenance')
    cases=[classify_case(case) for case in evidence['cases']]
    return {"policy_version":"EM066-1", "source":"EM065 native finite-reservoir evidence",
            "model":"explicit_metered_lifecycle_events_only",
            "no_physical_line_field_in_game_ledger": True,
            "no_automatic_waiver_for_cable_or_merge_loss": True,
            "real_engine_evidence":True,
            "model_introduction_does_not_fix_runtime":True,
            "hypothetical_physical_field_example":field_energy_example(),
            "cases":cases,
            "overall_energy_gate":"FAIL" if any(c['energy_gate']=='FAIL' for c in cases) else "PASS"}


def tests(data):
    x=field_energy_example()
    assert abs(x['combined_field_average_j']-323.125)<1e-9
    assert allowed_event_dissipation(kind='demolition',measured_loss_j=500000,
                                     station_own_hidden_eei_j=166667)==166667
    assert allowed_event_dissipation(kind='demolition',measured_loss_j=500000,
                                     station_own_hidden_eei_j=0)==0
    assert allowed_event_dissipation(kind='intentional_network_disconnection',
                                     measured_loss_j=333333)==0
    assert allowed_event_dissipation(kind='explicit_fault_field_dissipation',
                                     measured_loss_j=333333,
                                     metered_line_field_destroyed_j=330,
                                     line_energy_in_total_ledger=False)==0
    assert allowed_event_dissipation(kind='explicit_fault_field_dissipation',
                                     measured_loss_j=333333,
                                     metered_line_field_destroyed_j=330,
                                     line_energy_in_total_ledger=True)==330
    try:
        allowed_event_dissipation(kind='demolition',measured_loss_j=-1)
        raise AssertionError('negative energy accepted')
    except ValueError:
        pass
    cases=reconcile(data)['cases']
    expected={'reservoir':(166667,1500000),
              'reservoir-batteries':(186667,1537742)}
    for case in cases:
        a,b=expected[case['variant']]
        assert case['approved_demolition_station_own_eei_j']==a
        assert case['unaccounted_bridge_or_network_loss_j']==b
        assert case['energy_gate']=='FAIL'
    print('[EM066 POLICY TEST PASS] no automatic pardon of 1.5MJ; owned station buffers only',flush=True)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--evidence',type=Path,default=Path(__file__).resolve().parent.parent/'docs/research/25kv-closed-reservoir-065.json')
    p.add_argument('--report',type=Path)
    p.add_argument('--self-test',action='store_true')
    p.add_argument('--strict',action='store_true',help='Non-zero exit when unaccounted energy loss remains')
    a=p.parse_args()
    evidence=json.loads(a.evidence.read_text(encoding='utf-8'))
    if a.self_test: tests(evidence)
    result=reconcile(evidence)
    for c in result['cases']:
        print(f"[EM066] {c['variant']}: measured={c['observed_total_loss_j']} J; "
              f"authorized demolition={c['approved_demolition_station_own_eei_j']} J; "
              f"unaccounted={c['unaccounted_bridge_or_network_loss_j']} J; "
              f"energy_gate={c['energy_gate']}",flush=True)
    if a.report:
        a.report.parent.mkdir(parents=True,exist_ok=True)
        a.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    if a.strict and result['overall_energy_gate']=='FAIL':
        raise SystemExit('EM066 POLICY RELEASE BLOCKED: unaccounted energy remains')

if __name__=='__main__':main()
