> **This layout section was originally documented for stable 0.1.56; proposed public beta 0.1.62 is in PR #46, using the same packaging boundaries.** Current work across branches: [`CURRENT_WORK.md`](CURRENT_WORK.md). In the new docs-only continuation PR, `.agents/skills/` adds portable agent instructions; Updater 1.1 source `tools/updater/` lives **only** on `feature/git-updater-060` at the audit date, not in main's installable `ElectrifiedMainline/` tree.

# Repository layout / структура репозитория

**Current branch:** main 0.1.56, PR #30. Cleanup 048 is historical; packaging boundary remains unchanged. [Branch register](history/BRANCH_ARCHIVE_056.md).

## Active directories
| Path | Purpose |
|---|---|
| `ElectrifiedMainline/` | Installable Factorio mod only: metadata/entrypoints, Lua modules, locale CFG, actual PNG textures |
| `docs/tests/manual/` | Manual test checklists, historical [0.1.48](tests/manual/TEST_NETWORK_048.txt) |
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

Build 44413378503: Lua regressions, approved art verification, 3 package tests, game-only ZIP, separate atlas upload all passed. Docs run 44413378502 passed. Clean artifact 14478116616 downloaded and compared: 51 entries, 16 PNGs unchanged byte for byte versus earlier 048 ZIP; 302634 bytes, CRC clean, SHA256 `dfdeeab22c4cfb16cc9ec8e319d8566362cf86478d440ce7d738b55f9f309d15`. Old archive 322746 bytes. Draft PR #27. Original branch ref update failed with GitHub API errors, so the cleanup is anchored in a separate experimental branch. Subsequent live visual-continuity acceptance: [test report](tests/catenary-0.1.48-user-acceptance.md). Network ID/ordinary-grid isolation remains unverified.

## Distribution policy (owner decision)
All distributable mod ZIPs must be produced by GitHub Actions. The local packaging script is a CI implementation and may be used only for developer validation, not for user distribution. Download and distribute the exact inner ZIP from the successful CI artifact; do not repackage locally. Record commit, run, artifact and SHA256. Do not include QA atlases or outer artifact bundles in the game archive.

**Owner clarification (2026-11-19):** deliver install ZIPs only by direct GitHub Actions artifact links. Do not download, copy, extract, or duplicate distributable ZIPs into the ChatGPT Library or project files for delivery. Library is for technical material, source models, sketches, experiment outputs, and evidence. Record CI validation, source commit and artifact ID; obtain inner archive SHA256 from CI logs if emitted, not by copying the release into Library.
