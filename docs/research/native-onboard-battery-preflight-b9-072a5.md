# EM072-A5-B9 — research worksheet / acceptance contract: approved AUTO Б + finite onboard battery

**Date:** 2026-11-22. **Owner-approved AUTO policy:** rescue the factory in brownout even when locomotives are undersupplied. **Experimental branch only**; starts at B8 native tested commit `e9c70b2e5d7d788fe686806ea9f4a83090115bcd`. Engine Factorio 2.1.24 build 87808. Mod original official CI 0.1.62 SHA256 `91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`.

## 1–3: operation / inputs / explicit acceptance

Two physically actual EM070 stations on one HSR; 16 actual moving native locomotive burner entities, native 32MW traction meter. Second factory B experiences real 30MW EEI load against finite 25.2MW accumulator output. AUTO B must reverse to EXPORT and deliver native-paid J to factory B; do not override that author decision. Locomotive per-instance battery reserve: finite 2MJ, max 1MW native burner credit rate, test knobs only; alongside each real train's metered grid-power top-up, transfer only the unmet portion from that locomotive's own saved battery ledger. All native burner grants and spending measured, finite global ledger includes per-loco battery remaining. Battery EMPTY control must yield zero battery J, same actual grid delivery, same factory rescue export; extra battery credit must equal exactly 32MJ. Run full server disk SAVE while battery partially spent and independent LOAD. Real speed is engine-owned.

## 4–5: analogue/prototype + API contracts

- Exact original `ElectrifiedMainline/prototypes/bootstrap.lua`: the user's game **em-electric-locomotive** prototype has `energy_source={type="void"}`, `max_power="2MW"`, `max_speed=2.0`, not a working built-in battery.
- Native Factorio `LuaBurner.currently_burning` and `remaining_burning_fuel` can drive **real locomotive motion** from bounded J. The previous validated B8 experiment runs 16 independent LuaTrain IDs and meters genuinely native factory/line EEI Joules.
- Existing same-type `tests/em072a5-b8-probe/{control,data,root-hook}.lua` is the observed, native-tested previous reference, ref B8 commit `e9c70b2e5d7d788fe686806ea9f4a83090115bcd`; no external code is copied.
- No claim that a vanilla accumulator has a separate movable battery port; this experiment uses an **explicit Lua per-locomotive battery inventory** while the real Factorio burner receives debited J. Vanilla electric network remains unchanged. Official Lua API reference: https://lua-api.factorio.com/latest/classes/LuaBurner.html and https://lua-api.factorio.com/latest/classes/LuaEntity.html (latest page not independently version pinned; 2.1.24 engine tested).

## 6–7: falsifiable hypothesis / minimal design

Given native allocated grid J <2MW/60, finite per-entity indexed saved battery remainder provides `min(2MW/60-grid_J,1MW/60,battery_remaining_J)` without calling native accumulator.energy or generating unbacked burner fuel. With total 32MJ per 16 real moving trains, the native hybrid credited J must exceed no-battery case by exactly 32MJ; battery depleted by tick496, both finite conservation ledgers close. If any native grant exceeds 2MW/60, battery balance becomes negative, AUTO B ceases rescue-export, or SAVE/LOAD diverges, test FAILS. Implement only in disposable test probe, leave production main code unchanged. Manual Import is NOT the adopted default. No player mining or blueprint operations are implied by programmatic setup.

## 8–9: native observations and scope

Both `battery` and `empty` variants: actual 500-tick native Factorio pass, true server SAVE tick300, separate process LOAD 200 ticks matching all logged outputs. Battery 32MJ consumed by tick373, hybrid 136 ticks; grid unchanged 148.492753623MJ, AUTO exported 10.217391304MJ, global finite ledger residual ~0J. The extra 32MJ is a **credit to burner**, not a proven 32MJ increase in mechanical work; 35.46MJ fuel remains unburned at tick496. All tests to integrate an actual locomotive battery/charge/regen lifecycle remain open. Ownership decision Б explicitly approved; this research verifies its compatibility with a finite scripted hybrid reserve.

## 10: source/licensing

The disposable test reuses the owner's own B8 research scripts and original CI 0.1.62 mod; no third-party resources or licenses copied. NO main merge/NO release.