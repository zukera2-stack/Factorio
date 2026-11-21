# 0.1.62 experiment: flush hidden EEI buffers before auto-idle cleanup

**Date:** 2026-11-21  
**Branch:** `experiment/buffer-flush-063`, stacked on test-only QA `experiment/buffer-source-sink-063` and optimized 0.1.62 dispatcher. No merge to main or updater-approved.  
**Engine:** actual **Factorio Headless 2.1.24 build 87808**, linux64 x86-64 (user-provided private binary).  
**Exact local candidate ZIP SHA256:** `a0bd3030e6ccda2f2227e76ce4311afc2f3d9792fbb10d9e65ba796c1f1b0f2b`; original optimized CI ZIP SHA256 `18bfdd184f901aefa5c7cbf8e266359aa9ebd7a9e4036361b8ea1abda1629040`. Both have mod version `0.1.62` as a controlled A/B experiment; **the next actual release must bump the game version**.  
**Runtime changed from parent:** only `ElectrifiedMainline/scripts/power_bridge_058.lua`; 83 frozen PNGs unchanged.

## Native bug reproduced

The substation is an **electric-pole without a battery**. Its two hidden electrical relay interfaces each have capacity 333334 J; the outgoing EEI temporarily stores energy to cross between otherwise isolated factory and traction networks. With one 20MW generator at substation A and one 10MW consumer at B, with **no accumulators**:

- At tick 540 (generator cutoff) the hidden outgoing EEI held 333333 J.
- In the original optimized 062, tick 541 delivered only **166667 J** to B, immediately destroyed the output port with the other ~166666 J still present, and the consumer got no more energy. This is loss of an existing, legitimate buffer reserve on auto-idle.
- With the corrected 063 candidate, tick 541 delivers 166667 J (outgoing buffer now 166667 J); tick 542 delivers another 166666 J and removes the empty interfaces. **Total after cutoff = 333333 J**, without any phantom energy after drain.

## Technical change

Added `idle_or_drain(r,raw_flows)` in `scripts/power_bridge_058.lua`. For **automatically idling** and still connected relay ports, it prevents further input flow, moves only pre-existing input joules to available output space without exceeding 20MW/tick and allows the native outgoing EEI to finish discharging before destruction. It never creates energy, changes engine native priorities or turns the electric-pole substation into a battery.

A first naive implementation was explicitly **rejected** after native factory-deficit regression failed: while the local factory generated only 8MW and demanded 12MW, lingering relay power competed against local load (factory gained 28.8MJ vs required >35MJ, remote incorrectly got 19.36MJ). The final implementation disallows source-side buffer draining in an `import` direction whenever the original factory network still has nonzero primary/secondary/solar generation. Native deficit test then recovered to factory gain **47.947MJ**, remote gain **0.267MJ** for the same 8MW generator phase; subsequent `primary-input` priority phase also passed. This guard is scoped to the tested setups, **not** a universal priority proof.

No new persistent storage is introduced: a built-in station accumulator would require a separate native accumulator prototype and careful lifecycle/Undo/rebuild/priority guarantees. The fixed EEI buffer holds only ~0.333MJ per active output port.

## Exact Factorio results (11 independent scenarios, 12,200 actual game ticks)

| Case | Battery energy used at source A | At receiver B | Energy delivered to B after generator cutoff | Result |
|---|---:|---:|---:|---|
| A + B, four vanilla accumulators each | 9.600 MJ | 9.560 MJ | **19.493 MJ** | PASS |
| A only | 9.600 MJ | 0 | **9.893 MJ** | PASS |
| B only | 0 | 9.560 MJ | **9.886 MJ** | PASS |
| Neither — hidden bridge buffer only | 0 | 0 | **0.333 MJ** (previously 0.167) | PASS |

Every case runs 1540 real game ticks. At tick 1200 all batteries are empty; **0 extra joules** appear from tick 1200 to 1480.

All seven previous native fixture types passed again (6040 ticks): the original 20MW transfer, vanilla battery charge and reverse, EEI priority modes, three-network fairness, 32-station single-source and four-source scenarios, factory brownout protection, and complete 48-station reroute/source outage. 48-station minimum tick in this fixture = **1.859ms**, but this is **not** proof of 60UPS on arbitrary maps. Full machine-readable evidence: `25kv-buffer-flush-063.json`.

## Reproducibility

Use `tests/run_native_buffer_063.py` and `tests/em063-buffer-probe.lua` from the **parent QA PR**. The runner verifies Factorio version and supplied exact ZIP SHA before creating four temporary maps:

```bash
python3 tests/run_native_buffer_063.py \
 --engine /path/to/factorio/bin/x64/factorio \
 --game-zip /path/to/ElectrifiedMainline_0.1.62.zip \
 --expected-sha256 a0bd3030e6ccda2f2227e76ce4311afc2f3d9792fbb10d9e65ba796c1f1b0f2b \
 --output build/native-buffer-063
```

The runner in this branch has a stricter **bridge-only** acceptance: after the generator is fully off, the consumer must receive 300k–500k J, so the original build (167k J) fails as a useful regression indicator. For all large network fixtures use the existing native Factorio stress suite and the exact experimental candidate ZIP. This experiment does **not** test native Bob's accumulators, multiplayer, migrations, off-mode energy retention or arbitrary graph topology. **Do not promote** to `test/updater-approved` or stable `main` until explicitly approved, with a unique released version and further compatibility acceptance.
## Alignment of the inherited 059 Lua runtime mock with the 063 buffer lifecycle

The inherited `tests/power_bridge_integration_059.lua` originally asserted that **every** auto-idle station immediately deleted its EEI output, even when its output still held 100000 J. That was the *historical contract* which caused the confirmed native energy loss at cutoff. Once auto-idle explicitly enters `draining-buffer`, the old mock's line 103 must be revised: source A still stops immediately if empty, but receiver B retains its genuine 100000 J, stops requesting **new** input (`input_flow_limit=0`), and stays attached while discharging. A mock engine-step explicitly zeros the buffer and the next update confirms `auto-idle` cleanup. This is a changed assertion matching newly observed native engine behavior, not an arbitrary deletion/skip of test coverage.

All real native tests were already run on the new behavior; the mock update only fixes a stale invariant in the earlier 059 regression, and adds a positive assertion for the new lifecycle.

The inherited `tests/power_bridge_cold_start_060.lua` likewise carried the obsolete immediate-deletion expectation after an output still held `small=20000J`. In the updated mock, both outputs enter `draining-buffer`, no new source intake is permitted, and after a simulated native EEI discharge step both correctly transition to `auto-idle` with removed ports. This keeps all earlier cold-start, 118-tick buffered transfer and battery-reversal assertions in place.

## CI-archive exact native replay (2026-11-21)

The final GitHub ZIP builder [run 44892720155](https://github.com/zukera2-stack/Factorio/actions/runs/44892720155) succeeded, artifact **14702513298**, inner game ZIP SHA256 **`a869c7fb5b76aa49ae38f50af8f1c74b9e8dcd9254e4e354b127e3698d966a07`**. Its 130 extracted game files (including all 83 PNG, altered Lua energy module) are byte-identical to the previously tested local package; **ZIP compression encoding differs**, so whole-archive bytes/SHA256 differ. Instead of asserting identical archives, we **re-ran all 11 native tests directly against this downloaded GitHub ZIP**: four source/sink tests 6160 ticks and seven inherited tests 6040 ticks, **11/11 PASS, 12,200 actual Factorio 2.1.24 game ticks**. One aggregate run of the four-source 32-station fixture exceeded batch timeout; isolated repeat emitted `[EM062 MULTI PASS]` and exited normally in ~9 seconds. This exception is recorded, not hidden. See [full CI exact QA](25kv-buffer-flush-063-CI.md) and [machine JSON](25kv-buffer-flush-063-CI.json). This validates **only this exact CI artifact** and the tested configurations; it is still not approved to install or promote.
