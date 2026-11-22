# EM072 — architecture proposal: train-scoped traction bus and per-vehicle autonomous reserve

**Date:** 2026-11-22. **Status:** AUTHOR-SUGGESTED DESIGN / RESEARCH PROTOTYPE NATIVE VALIDATED FOR ONE TOPOLOGY. NOT IMPLEMENTED IN GAMEPLAY. Applies to electric locomotives now and potential motor coaches in the future. The value of the solo reserve, installed battery capacity, charging powers and autonomy are NOT yet approved; no gameplay changes authorized by this report.

## A. The physical units own the energy; the train owns only a temporary connection

Every powered vehicle `vehicle.unit_number` owns a durable saved record:

```
energy_units[unit_number] = {
  energy_j, capacity_j, solo_reserve_j,
  max_charge_w, max_discharge_w,
  kind, force_index, surface_index, version
}
```

The current Factorio `LuaTrain.carriages` defines who can share energy. Use `on_train_created` to invalidate membership of both old train IDs and rebuild an ephemeral membership cache on demand; do **not** store conserved J on `train.id`, which changes on detach, merge, or stock creation. No batteries are averaged, cloned or charged merely by coupling. An owned unit has the same J immediately before/after a coupling operation. If the train splits, each new train sees only its actual carriage members and their real energy records.

Source of truth: [Factorio `LuaTrain.carriages`](https://lua-api.factorio.com/latest/classes/LuaTrain.html) and [native `on_train_created`](https://lua-api.factorio.com/latest/events.html); independently confirmed on engine 2.1.24. For actual product implementation, register the bus as ONE component of the existing `scripts/control.lua` handler; never override event handlers or Undo ownership.

## B. Autonomous maneuver/idle reserve on a **single** electric locomotive

A locomotive must be able to work when detached and **without catenary**. Separate two energy needs:

1. **Auxiliaries/standby** (`P_aux`): cab, control, onboard systems even when stopped, which will need a separate tested nonzero drain.
2. **Solo maneuvers** (`E_maneuver`): enough battery energy to move an unladen locomotive a defined distance/time, even after a long haul.

Proposed protected budget per locomotive (formula, NOT game parameters):

`E_solo_protected = min(E_capacity, P_aux * T_standby + P_solo_maneuver * T_maneuver)`.

In an ordinary coupled consist, the unit can **donate** only `max(0, energy_j - E_solo_protected)` onto the train bus, subject to `max_discharge_w`. When uncoupled, the solo locomotive has access to its OWN complete `energy_j`, including the protected segment. This segment is not an extra battery or free charge; it is simply a sharing restriction. A future explicit emergency override of the reserve is a separate author decision, not silently assumed.

## C. Power rather than joule inventories is aggregated

Let `V(train)` be recognized locomotive and future powered-wagon participants. At tick duration `dt=1/60s`:

- `P_traction_requested = sum(P_motor_request_i)` for active motors in the appropriate direction, plus an independently accounted `P_aux` per powered vehicle.
- First obtain **really available**, same HSR/native electric component `E_grid_tick`; do not equate dispatcher planned MW to native EEI J, do not count the same meter as extra direct demand, and preserve existing EM070 AUTO **factory rescue** policy Б.
- Define remaining deficit `D_tick = max(0, E_demand_tick - E_grid_tick)`.
- Connected donor `i` maximum `A_i = min(max(0, E_i - R_i), P_discharge_i*dt)`. For an isolated vehicle `A_i = min(E_i, P_discharge_i*dt)`.
- Fair or weighted allocation across donors, with deterministic `unit_number` sorting: `0 <= debit_i <= A_i`, and `sum(debit_i) <= D_tick`. Deduct J from the actual donor record BEFORE a real receiver's native traction credit. Vehicle's own motor must have a proper prototype and actual consumption; `train.speed` is NEVER assigned.
- `E_grid_tick + sum(debit_i) = delivered_traction_J + losses + residual_buffers_J` (closed ledger). No phantom energy from other HSR components, disconnected carriages, player-built battery banks outside the train, or a deleted controller.

Every locomotive has its own native motor cap; merely adding batteries does not add power if the consist has no additional traction motor. Future **motor wagon** must have both `battery/supply` and `motor/demand` capabilities. A standard vanilla `cargo-wagon` is **not natively a driving motor**, so the real motor-wagon gameplay prototype/driver behavior is a separate engineering and author-design gate. Wagon can still be a donor in the pure power-bus laboratory.

## D. Charging and reserve ownership

- With valid catenary, surplus power first sustains real active traction and auxiliaries; only measured native source-backed surplus may recharge the onboard packs, each bounded by capacity, charge rate, efficiency and safe reservations. No script energy creation, no refill on reconnection.
- When electric contact is lost, the train requests the deficit from its own battery-bearing cars. A solo locomotive may use its own protected reserve for maneuvering. A coupled train does **not** silently drain another vehicle's solo reserve. When group reserves are all protected, usual shared traction stops until the operator requests an approved emergency use, or contact power returns.
- For `on_train_created`: re-evaluate the set of actual carriage IDs; **never** redistribute energy because the physical connection changed. Future tests: split immediately after emergency discharge, save/load across split, locomotive replacement/mining preserving own charge, Blueprint/Undo, charging with 2 genuine locos, future 500kW powered wagon actual native traction.

## E. User-facing UI proposal (not implemented)

A single train HUD could show **“Контактная сеть / Батареи состава / Защищённый маневровый резерв / Дефицит мощности”** and, when selecting a locomotive, its **individual J/charge rate**. Report protected reserves separately, not as unavailable or imaginary capacity. Do not require players to wire locomotives manually: physical Factorio coupling is the bus.

## F. Verified scope and next gates

B10 isolated native Base test: two real coupled locomotive clones + one native coupled cargo-wagon donor, split into 3 and rejoin, 1.1MJ supplied to genuine LuaBurner, 0.5MJ protected across three members; 300kJ supplied to a separate actual solo native locomotive, which drove 4.9063 tiles without contact; connected train drove 10.5625 tiles on already granted finite power; global finite 1.9MJ J ledger exact; 181 native ticks plus actual disk SAVE t75/independent LOAD+106 PASS. These lab capacities are purposely tiny and are NOT production product values.

Still required for production: real em-electric-locomotive battery source (`void` removal), real catenary recharge while coupled, dynamic drive versus brakes, arbitrary multi-loco orientation, connected motor coach actual propulsion, on-mine and item tags preservation, transition between surfaces, multiplayer, UPS. Native physical tests must precede gameplay integration.