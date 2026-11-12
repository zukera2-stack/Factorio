# ElectrifiedMainline 0.1.8 — in-game Undo/Redo regression record

Date: 2026-11-12. **Evidence classification: game-tested for the exact scenarios below**, not a general proof of all Undo semantics.

## Provenance

- Repository: `zukera2-stack/Factorio`; branch: `test/undo-stabilization-018`. No merge to `main`.
- Gameplay-tested source: `ac4624ef5873a1d3adf65194c289e09aee5224ae`; test build: `dist/ElectrifiedMainline_0.1.8.zip` (SHA-256 `8218d9ae147f6a017dd1b9c3f6de1dccd6a1c832018328d5d28f1c94e7ae63cf`, per `docs/BUILD_018.yaml`).
- Factorio 2.1.20, build 87512, with a modded environment including Bob's Assembly and Space Age.
- User-uploaded log `factorio-current(20261112-170348).log`, SHA-256 `832808759fea8270384155799f6cd3f64a83b3dd4144ee3c187d04f0ce833171`. The separately uploaded `factorio-current(20261112-170208).log` has the **same SHA-256**: it is the same session, not an independent repetition.
- User-uploaded log `factorio-current(20261112-171003).log`, SHA-256 `e5ccf8b67c51cbdcbad9e43ba1b2151bf5bc1c3ded041d3dfe30b96df3d1cb22`: a **second distinct session**.
- Log files were examined in the conversation; they are **not committed to this public repository**. The user independently confirmed the visible in-game results.

## Session 1: native upgrade, unrelated chest, superforced straight overlay

Log: `factorio-current(20261112-170348).log`.

| Test / game tick | Recorded result |
| --- | --- |
| Green Upgrade Planner: 34 rail entities | 26 `straight-rail`, 4 `curved-rail-a`, 4 `curved-rail-b` upgraded to matching high-speed geometry; robot replacement events observed |
| Undo tick 23999 | `on_undo_applied`, 34 `upgraded-entity` actions; native rail originals restored |
| Redo tick 24581 | `on_redo_applied`, 34 `upgraded-entity` actions; high-speed rails rebuilt |
| Undo tick 29766 | One `built-entity` action for `storage-chest`; unrelated action was isolated |
| Undo tick 29988 | 34 rail `upgraded-entity` actions, separate from the chest |
| Redo ticks 30251 and 31701 | 34 rail actions, then one `removed-entity` chest action, in LIFO-consistent order |
| `on_pre_build` tick 38970 | `build_mode=2` (superforced blueprint overlay) |
| Undo tick 39434 | 14 `upgraded-entity` actions, all straight rails; vanilla rails rebuilt |
| Redo of the 14-rail superforced operation | Not recorded in this session; do not infer from the earlier native Redo |

## Session 2: factory actions and mixed-geometry superforced blueprint

Log: `factorio-current(20261112-171003).log`.

The player reports: placed/upgraded assembling machines and overlaid a blueprint; later built vanilla rails, upgraded with the green planner, copied the high-speed rails into a blueprint, overlaid it onto vanilla rails, performed Undo, then Redo.

| Test / game tick | Recorded result |
| --- | --- |
| Undo tick 16902 | Two `upgraded-entity` actions for `assembling-machine-2` -> `bob-assembling-machine-4`, distinct from later rail operations |
| Native rail upgrade tick 19364 | Upgrade orders include straight, curved-A and curved-B geometry |
| Superforced blueprint `on_pre_build` tick 20353 | `build_mode=2`; corresponding native rail upgrade orders observed |
| Undo tick 20721 | 22 `upgraded-entity` actions: 14 straight, 4 curved-A, 4 curved-B; robot replacement restored vanilla geometry |
| Redo tick 20971 | 22 `upgraded-entity` actions: 14 straight, 4 curved-A, 4 curved-B; robot replacement rebuilt high-speed geometry |

Both distinct sessions loaded ElectrifiedMainline 0.1.8 and exited normally. No Lua runtime errors attributable to ElectrifiedMainline were observed in these supplied logs.

## Source audit of the tested branch

Inspected `ElectrifiedMainline/scripts/control.lua` and the root `ElectrifiedMainline/control.lua` loader at branch head `0133e49305a9e1bb3c4c5230fc14fd4560c550c9`, which carries the gameplay-tested source.

- **PASS:** no fixed `undo_index=1`, no `undo_index` assignment, and no scripted superforced-blueprint ghost-destruction/undo-join handler in the current runtime source.
- **PASS:** `ensure_storage()` sets obsolete `storage.em.blueprint_undo_join = nil` and leaves `storage.em.pending_rail_replacements` intact.
- **PASS:** `on_undo_applied` / `on_redo_applied` handlers log diagnostics only; `on_pre_build` is diagnostic only; `on_marked_for_upgrade` does not cancel native upgrade orders.
- **LIMITATION:** the separate `em-rail-replacement-planner` still schedules deconstruction and later creates replacement ghosts through its own queue. That is a different code path and has **not** been regression-tested here. Its retry/cleanup behavior still needs review.
- **LIMITATION:** source inspection and these tests cannot rule out all future timing/compatibility problems.

## Acceptance tests A–D (see `ElectrifiedMainline/TEST_UNDO_018.txt`)

- **A — passed in the observed native rail scenario:** more than 20 straight rails, both curved geometries, and robot-based Undo/Redo.
- **B — partially passed:** superforced blueprint Undo/Redo passed for 22 mixed-geometry rails; an unrelated chest and rail Undo stack were independent in a separate native-upgrade sequence. The exact interleaving of unrelated action X *after a blueprint while robots are delayed* was not tested as specified.
- **C — partially passed:** repeated native rail Undo/Redo succeeded; interrupted/partially completed robot jobs and inventory accounting were not tested.
- **D — unverified:** dedicated selection tool, cancelled tasks, pending-job save/load migration and geometry/quality/refund checks remain outstanding.

**Scope exclusions:** `half-diagonal-rail` gameplay, rail signals and live trains, special selection-tool fallback, multiplayer, partial robot jobs, item accounting and broad modpack compatibility. No power-grid, battery or regenerative-braking features are claimed.

## Decision

**Undo stabilization 0.1.8: core gameplay regression passed for the documented native and superforced-blueprint scenarios.** Keep the build on `test/undo-stabilization-018`. Do not merge to `main` without explicit player approval; do not relabel A–D as fully passed.
