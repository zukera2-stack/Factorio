# Development status — ElectrifiedMainline 0.1.24

**Updated:** 2026-11-15. **Mainline promotion:** user-approved; PR/merge tracked in GitHub. `info.json` version **0.1.24**. Target Factorio **2.1**, real user gameplay Factorio **2.1.20 build 87512**.

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
