# Electrified Mainline 0.1.42 — Final Factorio acceptance

**Date:** 2026-11-18. **Result:** User reports «все работает» for the clean GitHub Actions build of 0.1.42; [PR #20](https://github.com/zukera2-stack/Factorio/pull/20) merged into main (merge commit `5e2625c49b40f03c1262507e2fbfd8862f91ba7f`).

## Test evidence

- Supplied file: `factorio-current(3).log`. SHA-256 `fb5e79a9f5f3429b1c7e2f4c9454a6129c167519e80229ff3f65a87cf450dd7e`.
- Factorio **2.1.24**, build **87808**, successfully loads **ElectrifiedMainline 0.1.42** and an existing save.
- No `Error`, `Failed`, `Exception` or Lua traceback found. Normal game shutdown (`Quitting: user-quit` followed by `Goodbye`).
- The game rebuilds rail-following topology graph (schema 3) and restores ghost rendering.
- Long and short 25 kV masts are placed/removed by player and robots, including ghosts, with rail-facing directions on straight and curved ВСМ rails.
- Undo and Redo each report 10 straight rail actions, accompanied by robot building/mining events.
- A separate 20-action Undo records straight-rail/high-speed-rail replacement operations; curved high-speed rail-b Undo and robot reconstruction are also present.
- Earlier in-game screenshot establishes visually accepted mast heights with `NORTH_DROP=2.02`.

## Test limitations

This is **user acceptance supported by observed game events**, not automated coverage of every rail topology, multiplayer case or 32/16/40 boundary. Real electric traction MW transfer and regeneration are NOT implemented. The full log contains local device paths; its SHA-256 is retained here instead of publishing the log.

All pre-merge CI checks passed: [build](https://github.com/zukera2-stack/Factorio/actions/runs/44290077674), [docs](https://github.com/zukera2-stack/Factorio/actions/runs/44290077882), [sprite QA](https://github.com/zukera2-stack/Factorio/actions/runs/44290078001).
