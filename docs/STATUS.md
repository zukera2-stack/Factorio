> **0.1.32 EXPERIMENT:** 0.1.31 user's four screenshots verify new double-wire sprite graphics load and render in Factorio. South-of-rail masts (face=north) show contact sprite above triangular hangers. Adjust north-facing SPRITE ONLY endpoint by (-0.22,+0.90) tile, leave actual native copper helper, 7 other facings, C mast, rails and 32/16/40 intact. Await game screenshot approval. Research: docs/research/catenary-south-alignment-0.1.32.md. No main merge.

> **0.1.31 EMERGENCY HOTFIX (2026-11-16):** User game load of 0.1.30 crashed during `on_configuration_changed`: `catenary_art_030.lua:170: Require can't be used outside of control.lua parsing`. Moved `scripts.native_wire_028` require into the file's top-level parse stage, runtime `sync()` now uses the already resolved local. Added regression mock denying require while simulating configuration changed and 60/600-tick calls. 0.1.30 ZIP must not be used; 0.1.31 replaces it, using the same textures, spacing, rail logic and C masts. Confirm actual Factorio load before visual QA. Main 0.1.24 unchanged.

> **0.1.30 TEST (2026-11-16):** Real native copper connectors invisible on straight custom ВСМ spans; own contact/messenger/dropper sprites. Curved segments keep 0.1.29 native copper visuals. C masts, rails, Undo untouched; 32/16 tiles and reach 40; no traction power. Test guide TEST_ART_030.txt. Awaiting in-game screenshots; no merge.

> **0.1.29 TEST (2026-11-16):** Long spans straight 32 / curved 16, helper copper reach 40, selected by confirmed connected custom ВСМ rail route (not merely proximity). Shared limits module; loop/detour rejection, denser corridor, middle rail deletion invalidation. User-approved masts, native wire, eight arm sprite offsets preserved. Still 0 MW AC, no new dual-wire texture. Branch experiment/25kv-span-029; main 0.1.24 unchanged, in-game acceptance PENDING.

> **0.1.28 TEST (2026-11-16):** experimental 25 kV visible names, auto native copper helpers for all 8 C-arm sprites. Hard condition: connected custom ВСМ rail path for every contact edge (not just nearby rail), and no auto link to vanilla poles. Config migration replaces earlier 0.1.27 manual probe helpers with automatic 0.1.28 topology. /em-25kv-status and /em-25kv-tune FACE DX DY. Actual power_MW=0. Needs Factorio 2.1.20 game QA, no merge. Docs: research/auto-catenary-25kv-0.1.28.md.

> **Experiment 0.1.27 (2026-11-16):** Native wire tested on real game 0.1.26 (connected 1/1) but endpoints misplaced; SOUTH position reprojected to triangular insulators (+1.75,-0.80 helper offset). Previous Lua overhead/feeder lines entirely disabled. Optional /em-25kv-probe start DX DY for calibration. Main 0.1.24 unchanged; needs new game screenshots. See docs/research/native-copper-wire-alignment-0.1.27.md.

> **0.1.26 ISOLATED NATIVE-WIRE EXPERIMENT (2026-11-15):** Branch `experiment/native-25kv-wire-026` from game-accepted 0.1.24 main (not 0.1.25). Two hidden helper electric-poles connect via native *player-origin copper* on command `/em-25kv-probe start`; `status` and `clear` for diagnosis/cleanup. Real main mast art / normal ghosts / Undo / rails untouched; existing cosmetic lines remain. 25 kV AC is a design target, not simulated voltage: `transfer_MW=0`. Actual rendering, P2 alignment and isolation need game test. See [research](research/native-copper-wire-probe-0.1.26.md) and [game guide](../ElectrifiedMainline/TEST_NATIVE_WIRE_026.txt). **Do not merge without user evidence.**

# Development status — ElectrifiedMainline 0.1.24

**Updated:** 2026-11-15. **Mainline promotion:** **MERGED [PR #8](https://github.com/zukera2-stack/Factorio/pull/8)** on 2026-11-15; merge `43dd05a5`; [post-merge build #43748406702](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702) and [docs #43748406753](https://github.com/zukera2-stack/Factorio/actions/runs/43748406753) successful. `info.json` version **0.1.24**. Target Factorio **2.1**, real user gameplay Factorio **2.1.20 build 87512**.

## Current accepted milestone

**Rail infrastructure:** Four high-speed ground rail variants and native Upgrade Planner mappings. Prior 0.1.8 game test confirmed upgrading 26 straight + 4 curved-A + 4 curved-B ground rail pieces and separate Ctrl+Z/Ctrl+Y; superforced blueprint overlay 14 straight + 4 curved-A + 4 curved-B with native Undo/Redo. This evidence is still relevant, but no full re-run across the entire 0.1.24 codebase is claimed. [0.1.8 rail evidence](tests/undo-0.1.8-2026-11-12.md).

**35 kV catenary support — accepted visual state:**
- Physical `em-35kv-catenary-pole` is a real 1×1 `electric-pole` placed through native Factorio mechanics; ordinary LMB, ghost blueprint/Shift-click, robots, Undo/Redo have user-game evidence.
- The **native unrotated lattice shaft and base** use `ElectricPolePrototype.pictures` and thus appear as the normal held-placement cursor and as Factorio-rendered ghost mast body.
- Eight transparent **cantilever-only C arm/insulator sprites** use LuaRendering and `scripts/mast_facing_022.lua` to face nearest projected high-speed rail centerline. For ghosts the arm is separately blue-tinted; this is an approximation, **not identical to the engine's entire blurred ghost effect**.
- 64×64 SOUTH C inventory icon; subtle hollow green/red/orange circles for candidate rail locations; original full C source sprites kept as rollback.
- User 0.1.24 Factorio test shows successful game load, native cursor shaft, composite full masts, translucent ghosts and subdued circular indicators; robot construction and Undo/Redo events in log. [0.1.24 acceptance evidence](tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md). Independent scope of comparison [0.1.23 evidence](tests/catenary-visual-0.1.23-user-test-2026-11-15.md).
- Static [ZIP CI #43738070195](https://github.com/zukera2-stack/Factorio/actions/runs/43738070195) and [sprite QA #43737875150](https://github.com/zukera2-stack/Factorio/actions/runs/43737875150) passed.

## Functionality NOT yet delivered / unverified

- **No electrified traction**: overhead/contact wire graphics and link segments are cosmetic only; `transfer_MW=0`, `energized=NO`. No real separate HSR power grid, battery behavior, or regenerative-braking energy transfer.
- Contact/messenger wire attachments, suspension locations, correct electrical continuity along tight curves and junctions require additional visual QA and probable improvement.
- User-provided screenshot and test log do not prove all eight faces, all ghost lifecycle edge cases, multiplayer or large-modpack compatibility.
- Dedicated rail-replacement selection tool, interrupted robot orders, signal-block safety regressions, half-diagonal native Upgrade Planner behavior, and delayed mixed Blueprint Undo need separate tests.
- The selected curved-rail facing point is a sampled approximation; future work should verify visual P2 alignment without changing native rail signaling.

## Next engineering sequence

1. Preserve 0.1.24 as a known good **visual baseline** in `main`. Keep existing original full C sprites and 0.1.8 ZIP for rollback.
2. Design/validate **contact and messenger wire visuals** on straight, both curves, half diagonals, parallel lines and transitions. Avoid adding rails signals or changing placement to "fix" art.
3. Only after visual geometry approval: research 35 kV supply/substation topology, MW-limited energy transfer, train battery fallback, regeneration and compatibility. This is a **new feature scope**.
4. Carry out separate rail-upgrade regression matrix prior to claiming full 0.1.24 mechanical coverage.

Sources and handoff: [machine-readable state](PROJECT_STATE.yaml) · [AI handoff](AI_CONTEXT.md) · [architecture](ARCHITECTURE.md) · [0.1.24 build record](BUILD_024.yaml) · [release changelog](../CHANGELOG.md).
