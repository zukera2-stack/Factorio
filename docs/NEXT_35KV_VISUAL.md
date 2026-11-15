# Next visual work: native mouse cursor silhouette / C mast body split

Current version `0.1.23` game tested: inventory icon works, green/red rings present, ghosts build/copy/dismantle/robot-build/undo, no shown runtime errors; **world cursor model missing**. The prior prototype's `placeable_position_visualization` did not solve this; do not repeat that approach. Source: [user five screenshots/log](tests/catenary-visual-0.1.23-user-test-2026-11-15.md) and [2.1 API design decision](research/catenary-native-cursor-ghost-decision-0.1.24.md).

**Decision, not yet implemented:** separate fixed lattice shaft/foot (native `electric-pole.pictures`) from eight orientation-specific arm/insulator sprites (LuaRendering), keeping native base ghost blur. Ghost Lua overlay becomes arm-only. Test 1 shaft + 2 angles before mass-splitting all eight. Preserve `0.1.22` facing algorithm, stable item ID, copy/ghost/Undo behavior, standard LMB and grid. No new power, `supply_area_distance=0`, no special proxy signals.

**Branch:** `feature/catenary-visual-polish-023` still holds current validated 0.1.23; start separate 0.1.24 experiment later. Do not describe a ZIP or screenshots of 0.1.24 as already existing. Stable `main` 0.1.8 untouched.
