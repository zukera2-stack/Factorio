# Game test — ElectrifiedMainline 0.1.17 connected native rail-slot preview

**Date:** 2026-11-14. **Game:** Factorio 2.1.20 build 87512, Space Age + Bob's modpack. **Test ZIP source:** e3511464949b5b5dbf6630d3caa06cb43c01c064, [GitHub Actions artifact #14114052350](https://github.com/zukera2-stack/Factorio/actions/runs/43595022975/artifacts/14114052350).

**User-supplied evidence:** `Тест2.zip` (nine original screenshots, filename range 2026-11-14_16-00-33.png through 2026-11-14_16-05-43.png), and `factorio-current(20261114-130713).log`. Files inspected in conversation; raw screenshots/log not committed. ZIP SHA256: 461348b9ca772e483f7ef544ae491e4f7c58ff56489fadfdb69715d1d9024d63; log SHA256: 4db0ebcdb2fcd3ddec39e61e14fce1733aa0a5a375f44582912573647768c19c.

## Nine observed executions of /em-35kv-corridor

| # | Rails | Native slots | Clear | Blocked | Duplicates | Radius | Capped |
|---|---:|---:|---:|---:|---:|---:|---|
| 1 | 19 | 82 | 77 | 5 | 0 | 24 | no |
| 2 | 34 | 138 | 79 | 59 | 4 | 24 | no |
| 3 | 14 | 65 | 60 | 5 | 0 | 24 | no |
| 4 | 16 | 71 | 62 | 9 | 3 | 24 | no |
| 5 | 7 | 30 | 28 | 2 | 0 | 12 | no |
| 6 | 12 | 48 | 24 | 24 | 0 | 12 | no |
| 7 | 7 | 30 | 28 | 2 | 0 | 12 | no |
| 8 | 43 | 160 | 106 | 54 | 4 | 32 | yes |
| 9 | 41 | 160 | 111 | 49 | 23 | 32 | yes |

Each line reports non_ground=0, api_errors=0. Two radius-32 executions reach the 160-slot display cap (capped=true); this means that not all native slot positions in that area were displayed. Game loaded the existing test save and exited normally (Quitting: user-quit / Goodbye). No ElectrifiedMainline Lua exceptions or Error MainLoop present.

## Screenshots — observations

- 16-00-33: many green native-signal-location markers along both sides of a straight custom rail and its incoming bend, with one cyan nearest-clear highlight.
- 16-01-39: parallel/custom closely adjacent rails. Red (BLOCKED) candidate positions between the rails, many green (CLEAR) positions on the outer sides.
- 16-02-07, 16-02-34, 16-03-23, 16-03-41, 16-04-07: curved, straight and U-shaped rail segments. Marker overlay follows many sections of continuous HSR geometry.
- 16-04-52 and 16-05-43: dense multi-line and junction areas, with red inner candidates and outer green candidates. Both radius-32 previews hit the limit of 160 positions.

Clear/blocked is a call to surface.can_place_entity for the actual electric-pole prototype at a **signal reference coordinate**. CLEAR means collision-only permission, NOT that a 35 kV mast base, cantilever and wire align correctly. Dense every-few-tiles markers are not suitable as final 16-tile-spaced mast build sites.

## Proof boundary and decision

**Game-tested:** 0.1.17 read-only command ran nine times on Factorio 2.1.20 build 87512 with zero API errors; rendered track-side reference markers along multi-rail straight/curved corridors and showed collision distinctions; intentional caps were reached safely. Log also separately records native player/robot build events for all four custom rail geometry prototypes including half diagonal, but that does not validate each geometry's mast slots.

**Unverified / not implemented:** real pole placement, native cursor auto-snap, item accounting, Undo/Redo, robots placing masts, exact base offset and local tangent on curves, contact-wire clearance, 16-tile spacing, multi-player, train block invariance under traffic. No on_undo_applied or on_redo_applied event lines appear in this log. The log's 'NO entities created' line comes from the diagnostic code; no world entity census was taken.

**Decision:** accept the connected native slot data acquisition as a working read-only reference. Do not transform every green slot into an actual mast location; derive a separate base/arm geometry and sparse spacing from connected rails as a distinct next experiment. Do not create a rail-signal proxy or destroy/recreate entities; preserve Factorio-native Undo. Stable main remains 0.1.8, and 0.1.17 game ZIP code stays e351146 (documentation-only result update).
