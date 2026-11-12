# Changelog

All notable project changes are recorded here.

The project is currently in an early prototype stage. This file starts the public change history; it does not imply that earlier development work did not happen.

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
