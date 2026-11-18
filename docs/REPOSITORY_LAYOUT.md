# Repository layout / структура репозитория

**Current branch:** `experiment/25kv-visible-connectivity-048`, based on `7b2a123447fdeb48c096f2922663950949c39b05` (0.1.48). Stable main 0.1.42 unchanged.

## Active directories
| Path | Purpose |
|---|---|
| `ElectrifiedMainline/` | Installable Factorio mod only: metadata/entrypoints, Lua modules, locale CFG, actual PNG textures |
| `docs/tests/manual/` | Manual test checklists, latest [0.1.48](tests/manual/TEST_NETWORK_048.txt) |
| `docs/tests/evidence/` | Test evidence, screenshots, sprite QA JSON |
| `docs/development/` | Developer notes on prototypes, scripts and optional integrations |
| `docs/research/` | Research decisions and provenance |
| `tests/` | Automated regression tests |
| `scripts/` | Packaging, art/QA tools |
| `build/package/` | Generated installable ZIP, ignored in Git |
| `build/qa/` | Generated diagnostic atlas, separate CI artifact, ignored in Git |
| `dist/` | Historical game-accepted 0.1.8 rollback ZIP, deliberately retained |
| `Исходник_v2.1.20b/` | Historical reference material, not mod payload; preserved pending separate provenance/licensing audit |

## Package contract

Run `python -m unittest discover -s tests -p 'test_package_mod.py' -v` then `python scripts/package_mod.py`. Required root files remain at the exact Factorio-discovered paths. Unexpected files or symlinks fail the build. Archive contains exactly one mod directory, all accepted source bytes, deterministic entry order and timestamps, no dev-only files. CI uploads one exact game ZIP and the atlas separately. Historical build 0.1.13 and other old payloads should be reproduced at their original commits, not by pretending current sources are old versions.

## Moved files (blob-identical)

| From | To |
|---|---|
| `ElectrifiedMainline/SPRITES_039_QA.json` | `docs/tests/evidence/SPRITES_039_QA.json` |
| `ElectrifiedMainline/TEST_ART_030.txt` | `docs/tests/manual/TEST_ART_030.txt` |
| `ElectrifiedMainline/TEST_AUTO_WIRE_028.txt` | `docs/tests/manual/TEST_AUTO_WIRE_028.txt` |
| `ElectrifiedMainline/TEST_CURVE_043.txt` | `docs/tests/manual/TEST_CURVE_043.txt` |
| `ElectrifiedMainline/TEST_CURVE_044.txt` | `docs/tests/manual/TEST_CURVE_044.txt` |
| `ElectrifiedMainline/TEST_FACING_022.txt` | `docs/tests/manual/TEST_FACING_022.txt` |
| `ElectrifiedMainline/TEST_FINE_TUNE_042.txt` | `docs/tests/manual/TEST_FINE_TUNE_042.txt` |
| `ElectrifiedMainline/TEST_GEOMETRY_045.txt` | `docs/tests/manual/TEST_GEOMETRY_045.txt` |
| `ElectrifiedMainline/TEST_NATIVE_WIRE_026.txt` | `docs/tests/manual/TEST_NATIVE_WIRE_026.txt` |
| `ElectrifiedMainline/TEST_NETWORK_046.txt` | `docs/tests/manual/TEST_NETWORK_046.txt` |
| `ElectrifiedMainline/TEST_NETWORK_047.txt` | `docs/tests/manual/TEST_NETWORK_047.txt` |
| `ElectrifiedMainline/TEST_NETWORK_048.txt` | `docs/tests/manual/TEST_NETWORK_048.txt` |
| `ElectrifiedMainline/TEST_SPANS_029.txt` | `docs/tests/manual/TEST_SPANS_029.txt` |
| `ElectrifiedMainline/TEST_SPRITES_039.txt` | `docs/tests/manual/TEST_SPRITES_039.txt` |
| `ElectrifiedMainline/TEST_SPRITES_041.txt` | `docs/tests/manual/TEST_SPRITES_041.txt` |
| `ElectrifiedMainline/TEST_VISUAL_023.txt` | `docs/tests/manual/TEST_VISUAL_023.txt` |
| `ElectrifiedMainline/TEST_VISUAL_024.txt` | `docs/tests/manual/TEST_VISUAL_024.txt` |
| `ElectrifiedMainline/compatibility/README.md` | `docs/development/compatibility.md` |
| `ElectrifiedMainline/prototypes/README.md` | `docs/development/prototypes.md` |
| `ElectrifiedMainline/scripts/README.md` | `docs/development/scripts.md` |

No runtime Lua or assets were removed. Legacy native probe, helpers, tests and source references are deliberately preserved; they may be needed for migration or regression tests. No history rewrite, branch deletion, or main merge. Historical prose can still describe locations as they existed when written; this map resolves old filenames. Current README/handoff/state/status and packaging verifier references use new locations. No version bump because all game data/code is unchanged; this is a clean 0.1.48 repack, not a new mechanic. Compare runtime bytes to pre-cleanup artifact and rerun CI before claiming success.

## Current QA

Pending clean CI and ZIP comparison. Live Factorio 0.1.48 still pending independently of packaging cleanup.
