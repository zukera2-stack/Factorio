# Next task — overhead contact/messenger wire visuals after accepted 0.1.24

**Canonical baseline:** version 0.1.24 accepted by user in Factorio 2.1.20 build 87512; promotion to `main` approved. [Evidence](tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md) · [current status](STATUS.md).

The native lattice mast body, eight arm overlays, ghost/robot/Undo lifecycle, cursor image, SOUTH item icon and subtle circular markers are accepted **and should be preserved**. Existing original 8 C full PNGs remain as rollback.

**Next stage:** examine visual contact wire and messenger cable across straight, curves A/B, half diagonals, transitions and parallel HSR lines. Verify P2 arm clamp center against rail centerline and nearest mast; do not accidentally connect independent parallel rails or draw diagonal feeder spiderwebs. Use actual screenshots, RailEnd projection, realistic suspension height, geometry tests, and isolated feature branch **from merged `main`**. If the visual wire must change, do so separately from traction/electricity code.

**Outside scope until wire approval:** real supply, MW transfer, batteries, regeneration, separate HSR power grid; currently `transfer_MW=0` and `energized=NO`. Likewise do not alter native Undo, Upgrade Planner, collision points or physical rail signals.

Test acceptance: render at all 8 mast orientations, curve A/B both sides, half diagonals, a crossover, parallel rails; check anchor P2 continuity, support positions, save/load and ghost/bot lifecycle; record Factorio 2.1.20 screenshot/log. Branch, PR and CI before merging the next step.
