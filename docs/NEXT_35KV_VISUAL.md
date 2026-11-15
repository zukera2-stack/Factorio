**GitHub Actions 0.1.23 compiled:** [Run #43731628908](https://github.com/zukera2-stack/Factorio/actions/runs/43731628908) SUCCESS, [test ZIP artifact #14168876545](https://github.com/zukera2-stack/Factorio/actions/runs/43731628908/artifacts/14168876545). Download outer archive and install inner `ElectrifiedMainline_0.1.23.zip` only. Source includes real 8 C PNG untouched, new south icon, ghost/preview/circle improvements. CI is NOT a Factorio game test.

# 0.1.23 next game test: ghost, cursor icon, quiet circles

Branch `feature/catenary-visual-polish-023`; source version 0.1.23, based on tested 0.1.22 C sprites and RailEnd facing. User screenshot `2026-11-15_18-15-24.png` shows very vivid green/red square overlays and invisible ghost/build cursor shape. Latest requested changes are visual only.

- Inventory item/icon from south C sprite; 64x64 RGBA, also electric-pole entity icon.
- Native cursor placement preview via `placeable_position_visualization` using south C sprite. Normal built pole `pictures` remains hidden, so eight LuaRendered sprites cannot be doubled. **API exists, game display still to test**.
- Actual `entity-ghost` visual via `scripts/ghost_mast_023.lua`: blue-tinted same 8 sprites, anchored to actual ghost, auto removed when ghost destroyed, rebuild existing ghosts on save migration.
- Subdued unfilled circles instead of green/red/amber/magenta squares. All marker placement semantics stay the same.
- New tests: `tests/35kv_ghost_023.lua`, icon structural PNG QA, packaging CI. No Factorio gameplay test by AI.

**User test:** install only 0.1.23 in a copy of ВСМ save; test item icon, preview while holding, ghost via Shift+LMB, blueprints, robots build/remove, Ctrl+Z/Ctrl+Y, save/reload. Inspect bright markers and any double-render. Send screenshots + factorio-current.log. Previous build 0.1.22 had good mast directions per user; verify no regressions. If cursor preview missing even with `placeable_position_visualization`, do NOT fake direct mouse position via `LuaPlayer.cursor_position` (not an API read property) or revive 0.1.20 LMB capsule. Reference: `docs/research/catenary-ghost-cursor-0.1.23.md`.

Stable `main` remains 0.1.8. Wires and traction electricity later; MW=0.
