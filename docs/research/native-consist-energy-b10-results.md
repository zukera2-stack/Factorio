# EM072-A5-B10 — native real train composition + energy bus + solo protected reserve

**Status:** ISOLATED NATIVE ENGINE **PASS** on Factorio 2.1.24 build 87808 Linux headless, Base only (Space Age/elevated rails/quality/recycler disabled). 2026-11-22. Author request: combine electric locomotives' energy for a consist, leave an autonomous maneuver reserve for a solitary locomotive, and allow future motor coaches to join the same logical network. No production mod code or user save changed.

**Test-only source:** `tests/em072a5-b10-probe/{info.json,data.lua,control.lua,bus.lua}`, strict reproducible runner `tests/run_native_bus_072a5b10.py`.

## Concrete native evidence

- Real Factorio rolling stock: two actual locomotive clones `em-b10-battery-loco`, native cargo wagon clone `em-b10-powered-wagon` (energy DONOR ONLY), and one independent standalone locomotive; each object has a real persistent `unit_number`.
- Native engine placed adjacent stocks into one train of 3; `on_train_created` on t30 fired 4 events on two real disconnect operations; created 3 separate one-stock native trains. Reconnect t35 fired 2 genuine merge events (6 after initial setup). `train.id` changed, **unit numbers and battery balances did not**. No J modified by coupling/decoupling.
- Three coupled members had 600kJ + 600kJ + 400kJ = 1.6MJ. Protected solo reserves were 200kJ + 200kJ + 100kJ = **500kJ**. From t41–84 real Factorio tick loop debited exactly **1,100,000 J** from OWNED battery records and credited exactly 1,100,000 J to real native `LuaBurner.remaining_burning_fuel. All three remained at protected reserves without overshoot; donor watt ceilings respected.
- Independent solo locomotive started with 300kJ and 150kJ nominal protected reserve. This reserve is NOT locked for its **own** solo movement. t86–155 it debited exactly **300kJ** from own battery, including protected portion, into its genuine native burner; the **solo locomotive physically moved 4.9063 tiles** with no external catenary. The rejoined connected group physically moved **10.5625 tiles** after the credited pooled J. No `train.speed write or fake movement.
- All native burners together genuinely spent **1,400,000 J**. Starting all-unit battery reserve was 1.9MJ. Ending protected energy 0.5MJ; no extra energy anywhere. Full ledger residual −0.000000 J.
- Real 181-tick native benchmark PASS; actual headless server wrote checkpoint at tick75 while bus was actively discharging, actual independent Factorio process LOAD+106 ticks PASS. Both runs produced the exact same metrics. True checkpoint size **816050 bytes**.
- SHA256 benchmark log `d0e7f2aeba7bfbb1fb34304e76a92950e636cd169cd62a747e484f14c8b1410a; independent disk reload `218a3519c88b972eba2de23d37cb2f929e7e50722fb9189000a8e1ae7defcc93.

## What this does NOT prove

- The motor wagon **cannot natively propel** as a cargo-wagon clone. It only contributed saved battery J to a real locomotive; a future powered coach needs a proven actual propulsion design.
- The independent solo locomotive never belonged to the triplet; while the triplet was genuinely split and rejoined with exact preserved J, **the maneuvering-alone-after-detaching-a-previous-member** scenario is still a separate native gate.
- Per-vehicle batteries are LAB Lua storage, not native locomotive battery prototypes. The test does not include actual EM070, native 25kV network recharge, 2.1.24 install mod package, actual electric locomotive (still void-powered), sustained 60 UPS, real user mining/Undo/Blueprint, remote configuration changes or multiplayer.
- The illustrative 600/400/300kJ capacities, reserve 200/100/150kJ, and power 1.0/0.5/0.3MW are **NOT proposed product specifications**. No author decision on amount/duration was requested.
- Owner-approved EM070 AUTO policy **Б**, allowing factory rescue during traction brownout, is untouched; separate *stationary* corridor battery-first/factory-first priority remains unresolved.

**Next:** test the actual detachable former group locomotive using its own protected reserve immediately after a native split, coupled recharge through native 25kV with finite metering (including one failed pantograph), real catenary loss, item/Blueprint/Undo state preservation, then true motor-wagon propulsion. Keep experiments separate and do NOT merge to main/release without explicit owner permission.