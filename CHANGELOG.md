## 0.1.12 (experimental graphics branch)

- Mast remains upright while a separate rendered cantilever aims automatically toward nearest high-speed rail. No manual R or signal entity.
- Contact and messenger wire textures follow a rail-oriented Hermite path through corners.
- 35 kV is still a visual prototype; native signals, upgrade Undo, power isolation are preserved.
- Factorio 2.1.20 game test pending.

## 0.1.11 (test branch only — visual sprite integration)

- Experimental one-sided Г-shaped overhead contact support rendered from 4-frame right/left atlas and separate shadow.
- Procedural QA sprite generation in GitHub Actions; final artist-approved artwork is NOT included.
- Contact wire sprite registered but not yet drawn; existing line graph and electrical isolation preserved.
- Factorio 2.1.20 game loading and rotation behavior not yet verified.

## 0.1.10 — contact topology correction (experimental, not released)

- Correct multiple diagonal substation wires seen in the 0.1.9 game screenshot: one distinct feeder to nearest eligible support.
- Contact spans connect mutually selected nearest neighbours along the estimated rail axis, at most two per pole, with corridor sampling and track-side checks.
- Migrate existing 0.1.9 visual graph on configuration change; refresh local topology when rails are built or removed.
- Add pure Lua geometry tests and an in-game test worksheet. No MW transfer or exact rail-signal placement.

## 0.1.9 — experimental branch (not released)

- Added strictly copper-disconnected 35 kV contact support prototype and vanilla-side traction substation prototype.
- Added event-driven logical spans drawn as nonconducting graphics; no real electricity yet.
- Included basic recipes, localization and inspection command. No rail-signal snap, train energy, or actual MW bridge.
- Corrected two obsolete technical comments. Native Upgrade Planner remains unchanged; runtime game tests pending.

# Changelog

## [0.1.8] - 2026-11-12 (test branch, Undo stabilization)

- Remove experimental scripted blueprint ghost Undo joining and fixed `undo_index=1`; discard obsolete `blueprint_undo_join` storage marks. Keep native upgrade prototypes, observational event handlers, and the independent special selection-tool queue.
- **Game-tested in Factorio 2.1.20 build 87512:** green Upgrade Planner, robot replacement, Undo and Redo for 26 straight, 4 curved-A and 4 curved-B rails.
- **Game-tested:** chest and rail actions remained independent in Undo/Redo; superforced Ctrl+Shift blueprint overlay on 22 mixed-geometry rails (14 straight, 4 curved-A, 4 curved-B) was undone and redone. A separate 14-straight-rail superforce Undo also succeeded.
- **Still unverified:** half-diagonal geometry, special selection tool, interrupted robot jobs, inventory/refunds, signalling and broader mod compatibility. Acceptance tests A passed, B/C partial, D unverified.
- Evidence: [0.1.8 game-test record](docs/tests/undo-0.1.8-2026-11-12.md). The tested ZIP and its source SHA remain those in [BUILD_018.yaml](docs/BUILD_018.yaml). Release PR [#6](https://github.com/zukera2-stack/Factorio/pull/6) was merged to `main` on 2026-11-12 as [`973559aa`](https://github.com/zukera2-stack/Factorio/commit/973559aa4d0643b2a942edce413e9530494bc498) after both CI checks passed. Earlier main-only 0.1.4 docs and Factorio 2.1.20 API notes were preserved.

All notable project changes are recorded here.

The project is currently in an early prototype stage. This file starts the public change history; it does not imply that earlier development work did not happen.

## [Unreleased] - Documentation

- Add a reusable prototype-research worksheet and a completed 0.1.7 rail-upgrade research record.
- Make source provenance, target-version API comparison, falsifiable hypotheses, and scoped game evidence explicit requirements before and after non-trivial mechanic work.
- Link the research workflow from contributor instructions, handoff documents, status, architecture, and both README files.
- Correct the README ZIP-folder example to match the current CI archive layout.

## [0.1.7] - 2026-11-12 (diagnostic branch, native ground-rail upgrades)

- Assign a geometry-specific fast-replace group to each matching vanilla/high-speed ground-rail pair; connect the vanilla source to the custom target via `next_upgrade`.
- Stop canceling native `on_marked_for_upgrade` orders; keep the separate scripted rail-replacement selection tool as a fallback.
- **User-verified:** native Upgrade Planner converted 20 vanilla straight rails to high-speed rails with robots. Ctrl+Z returned all 20 to vanilla; Ctrl+Y upgraded them again. Curves, half-diagonal, and Ctrl+Shift superforce workflows still require separate testing.
- Record the [research-first method](docs/RESEARCH_METHOD.md) discovered by comparing Bob's assembler prototypes with a working rail mod and official Factorio API.

## [0.1.6] - 2026-11-12 (experimental branch)

- Test joining delayed replacement ghosts to native Undo using `undo_index=1` for straight rails.
- **User-verified limitation:** superforced-blueprint Undo removed the new rails but did not restore vanilla rails; Redo rebuilt new rails. This is not a complete solution.

## [0.1.0] - Initial repository snapshot

- Added the initial Electrified Mainline mod source.
- Added English and Russian locale files.
- Added the existing `ElectrifiedMainline_0.1.0.zip` archive.
- Added repository documentation and a clear development-status record.
