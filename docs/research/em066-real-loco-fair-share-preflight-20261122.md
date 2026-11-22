# EM066 Fair-share source-paid charging of identical locomotives — PRE-IMPLEMENTATION research

## 1. Research metadata
- Feature: Issue [#78](https://github.com/zukera2-stack/Factorio/issues/78), real trains on one 25kV native circuit under insufficient MW.
- Branch `experiment/em066-fair-share-fullmod-20261122` starting from full exact unmodified 0.1.65 `3c69ed6cc30c29f429ff996eb9e349eb1aceda76`.
- Engine: official Factorio **2.1.24 build 87808**, full game source + Base. Additional Space Age / other mod compatibility NOT TESTED.
- Expected new isolated test-only mod source version: **0.1.66**, never main/release.

## 2. Exact owner-visible mechanic
Two equally eligible real EM 2MW locomotives, both with initially 0 Joules, both physically contacting the SAME native 25kV mast network, share 1MW real native factory power via native EM070. The mod currently iterates `unit_number` sorted locomotives and credits each in sequence from the same `r.output.energy` buffer. Actual [native #45043138579](https://github.com/zukera2-stack/Factorio/actions/runs/45043138579): tick60 A=933333.33J B=0J; tick120 A=1933333.33J B=0J, but both eventually reach 1983333.33J. Disproves contact fault; confirms starvation caused by greedy first-come-first-served Lua energy billing.

## 3. Acceptance experiment (unchanged full mod, repeat after fix)
- Native full 0.1.66 GitHub Actions ZIP, not minimal lab. Confirm exact SHA256 across two independent native test jobs; all original genuine 25kV masts, rolling stock, HSR graphics and 0J hidden helper are loaded.
- Baseline same [native 1MW two-real-train audit probe](https://github.com/zukera2-stack/Factorio/blob/audit/em065-native-multitrain-20261122/tests/em065-audit-native-probe/control.lua) on same physical connected network, offgrid true AUTO negative control; NO burner pre-seed, NO speed writes. At t60 BOTH simultaneously eligible and EACH >0 J, source debit limited to measured native output + prior buffers.
- Full native EM070 20MW EEI fault/charger lifecycle, all catalog/HSR/motor wagons/owner #73 destructive suite, real disk SAVE and independent process LOAD in BOTH parallel lanes. Strict gate remains FAIL if #77 native demand=0 or #73 helper orphan; fix does not wave them through.
- Test at second supply limits 0W and high source 20MW, 2,4,10 equal trains when test harness can faithfully establish contacts; unexpected setup failures are NOT_TESTED, never green.
- Undo/client migration, reserve and regen not claimed by fair charging improvement.

## 4. Same-type tested analogue (not third-party code)
Own true Factorio 2.1.24 main source `ElectrifiedMainline/scripts/power_bridge_058.lua` already computes `dispatch.plan` for a constrained source across multiple destinations (same-type finite Joule budgeting). `scripts/traction_paid_065.lua` already validates each loco native catenary contact, EM070 output donor, 2MW/60 J native tick max, 2MJ onboard cap, and source prior debit. Its **per-car first-wins loop** is the only new behavior to replace, not the EEI source plumbing or accepted rail code. Existing full native 2.1.24 single loco 24 tiles + real SAVE/LOAD PASS [run #45041147885](https://github.com/zukera2-stack/Factorio/actions/runs/45041147885). Official [LuaBurner](https://lua-api.factorio.com/latest/classes/LuaBurner.html) RW remaining fuel, [LuaEntity](https://lua-api.factorio.com/latest/classes/LuaEntity.html) native EEI RW energy and [ElectricUsagePriority](https://lua-api.factorio.com/latest/types/ElectricUsagePriority.html) 2.1.24. API version may show newer patch, target native build verifies.

## 5. Comparison with current prototype
Actual real EM loco is native `locomotive` with finite `BurnerEnergySource` (2MW), internal noncraftable fuel, 2MJ test-only capped reserve; not directly an `electric-energy-interface`. Motor cargo/fluid native `cargo-wagon` / `fluid-wagon` have no permitted battery or pantograph. EM070 outputs true `electric-energy-interface` native buffer on verified 25kV, and current donor source is a single valid active import station per network. Existing Lua list sorted `unit_number` never implies fair source rationing. Fair allocator should work at **per-source** output energy budget after native engine payment, never in prototypes and never by writing speed.

## 6. Falsifiable minimal design / rollback
- Keep genuine active donor `donor(network,force)`, `network_for_contact`, `M.requests` intact unless native test disproves exact contact.
- Replace only sequential locomotive charging in `M.on_tick` with **two-pass per-donor allocation**. Pass one: take all eligible, source-contact-verified actual owners; group by **real native output EEI unit_number** and compute each available capacity min(2MW/60, 2MJ-old). Pass two: use max-min equal-share/water-fill allocation within each same-source group, capped by **existing native output.energy**. For identical demands and insufficient source, each gets positive paid J in same tick.
- For each grant, **first subtract exactly paid J from the donor's native EEI buffer**, and only then credit equal J to native burner with zero-seeded internal fuel if necessary. Source debit sums never exceed native available buffer; no math-created energy, no player fuel, no direct train.speed changes.
- No changes to base engine native electrical priority or 25kV topology, accepted PNGs, wagon/helper own energy, GUI or Undo logic. Increases no output generator flow limits.
- **Disproof**: either train remains at zero charge under fair competition, global total granted > measured finite donor, real Factorio native no longer loads, 0W offgrid loco gains J, one-train 24-tile run fails, or disk save/load changes J/UID. Keep original 0.1.65 branch for rollback. P0 #77 and owner #73 remain explicit FAIL until separately fixed.

## 7–9. Later record
Status: PREIMPLEMENTATION. Native implementation and CI proof pending; original full mod 0.1.65 is the only last tested game source at this point. Do not upgrade beyond this proof.
