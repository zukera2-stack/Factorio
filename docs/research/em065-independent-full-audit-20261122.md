# Independent source-and-native audit — EM065 0.1.65 / owner 0.1.63
Date 2026-11-22. SOURCE UNMODIFIED; dedicated native test-only mod on branch `audit/em065-native-multitrain-20261122` based on `053fdd9d528b39db8f57eba5698aebfe9d79c506`. GitHub main and owner's tested zip unchanged.

## Initial evidence from original source before new tests
- Current full 0.1.65 true locomotive `prototypes/traction_paid_065.lua` uses finite BurnerEnergySource; source capped 2MW/60J per tick, 2MJ onboard. `scripts/traction_paid_065.lua` charges only via native EM070 output buffer on verified current mast contact. Official [paid native run 45041147885](https://github.com/zukera2-stack/Factorio/actions/runs/45041147885) PASS actual 24-tile native motion + separate-process save/load. This proves one drive path.
- Previous `tests/em065-native-paid-locomotive-probe/control.lua` never gives the 0J negative locomotive an AUTO route; positive is sent to the stop only after charging and **already arrived** when source is switched off. Hence negative motion and moving outage needed independent tests.
- Original `M.charge` picks the first id-sorted bridge donor; trains processed in unit_number order; output J are drawn first-come-first-served. Original tests use one positive true loco at 20MW source, so no 2+ real train shortage/fairness test. This is a risk until measured.
- `pantograph_visual_049.state` puts pantograph DOWN when stopped; `network_for_contact` allows charge based on rendered wire coordinates without checking its raised state. User-facing power/contact visualization may disagree. Confirm with native GUI before release.
- `scripts/em072_c5_fullmod_trial_063.lua` creates 0J hidden actual locomotive with `destructible=false`; owner destruction leaves hidden orphan >80 ticks (Issue #73) in verified previous independent native test. Not fixed by 0.1.65.
- `docs/research/25kv-switching-dissipation-066.md` historical 0.1.62 *closed-reservoir ledger* measured 1,500,000 J unexplained loss (and 1,537,742 J with real accumulators). Latest EM065 fullmod only validated positive current flow, not these owner dismantle/line switching closed-reservoir cases. Do not infer the historical leak necessarily reproduces under 0.1.65 without a fresh native regression.

## New independent falsifiable native test
Creates **two real, independent EM locomotives** stationary on the SAME 25kV and HSR network; both start 0J, native engine 2.1.24 source only **1MW** primary-output EEI (not 20MW overcapacity), 4 real masts, 2 substations. Logs actual native burner J of both at ticks 60/120/240/300. Only declare fairness starvation when one real locomotive got >300kJ and the other <1kJ at tick60 **AND BOTH eventually charge >100kJ by tick300**, ruling out missing contact. No versioned mod gameplay code changed.

Separate offgrid surface: true native locomotive starts 0J, is given an actual connected native train stop and AUTO schedule at tick60; strictly requires no motion and 0J through tick240. The original official native 0.1.65 test did not give its negative locomotive a route.

## Status
Native engine test NOT YET RUN; this file is preflight and must be updated from original logs regardless of PASS/FAIL. Future audit should also test real 2+ trains at full speed, source outage **during** traction, old-save migration, GUI power graphs, curves and elevation, Undo, multiperson multiplayer, memory/runtime.
