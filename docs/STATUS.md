> **Г-shaped catenary support preview:** [22 passing QA tests](https://github.com/zukera2-stack/Factorio/actions/runs/43388634580), [updated preview artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43388634580/artifacts/14019876083). Off-centre mast anchor and one-sided arm enforced. Not yet a playable sprite replacement.

> **Sprite pipeline verified offline:** [CI #43387339441](https://github.com/zukera2-stack/Factorio/actions/runs/43387339441) passed 19 tests, Lua syntax and API contract guard; [QA preview](https://github.com/zukera2-stack/Factorio/actions/runs/43387339441/artifacts/14018579988). [Art brief](ART_BRIEF_35KV.md). Playable 0.1.10 remains unchanged; actual 2.1.20 load and real art not tested.

> **Sprite pipeline QA passed:** [CI #43387041605](https://github.com/zukera2-stack/Factorio/actions/runs/43387041605) (14 tests + Lua syntax + offline API contract); [docs #43387041331](https://github.com/zukera2-stack/Factorio/actions/runs/43387041331) passed. [Download preview](https://github.com/zukera2-stack/Factorio/actions/runs/43387041605/artifacts/14018364046). No game integration; 0.1.10 unchanged.

> **Sprite QA preview CI:** [first successful run #43386844327](https://github.com/zukera2-stack/Factorio/actions/runs/43386844327), 10 image tests and deterministic preview; [docs #43386901818](https://github.com/zukera2-stack/Factorio/actions/runs/43386901818) passed. Added an offline Factorio API contract guard; not a data-stage/game test.

> **0.1.11-dev sprite QA preview branch:** Art source validation and reproducible preview pipeline added; playable 0.1.10 remains unchanged. Demo art is synthetic and not production quality. Real artist assets, game integration and 2.1.20 tests pending. [Sprite guide](SPRITE_PIPELINE.md) · [API research](research/sprite-pipeline-0.1.11.md).

> **CI passed for 0.1.10:** [one-ZIP build and Lua geometry tests](https://github.com/zukera2-stack/Factorio/actions/runs/43382092112); [docs validation](https://github.com/zukera2-stack/Factorio/actions/runs/43382163410). [Download test artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43382092112/artifacts/14016553350). Gameplay not tested; no MW transfer.

> **0.1.10 experimental branch:** Corrects the 0.1.9 visual substation spiderweb with a single feeder and nearest-neighbour contact spans along a locally estimated rail axis. Includes save-graph migration, rail-change refresh and Lua geometry tests. **Gameplay unverified, energy transmission unimplemented.** See [0.1.10 test worksheet](POWER_TEST_0110.md).

> **0.1.9 preliminary CI:** Lua syntax and ZIP build passed at cf49a518; documentation YAML/link validation passed at 97f35b45. Download the experimental artifact from [Actions](https://github.com/zukera2-stack/Factorio/actions/runs/43279773067). All game-play claims remain unverified, and 35kV energy transfer is intentionally disabled. See [BUILD_019.yaml](BUILD_019.yaml).

> The isolated feature/35kv-catenary-019 branch now prototypes 35 kV visual line endpoints and a distinct logical graph. NO energy transfer and NO exact signal-like placement yet; gameplay tests pending. main remains the verified 0.1.8 baseline.

# Current: ElectrifiedMainline 0.1.8 — core Undo regression game-tested

**Current baseline:** `main`, ElectrifiedMainline **0.1.8**. **Release:** [PR #6](https://github.com/zukera2-stack/Factorio/pull/6) merged on 2026-11-12; merge commit [`973559aa`](https://github.com/zukera2-stack/Factorio/commit/973559aa4d0643b2a942edce413e9530494bc498). Both Lua/ZIP and YAML/Markdown checks passed. Future features should branch from `main`. **Game-tested source:** `ac4624ef5873a1d3adf65194c289e09aee5224ae`. **Game:** Factorio 2.1.20 build 87512. **Test date:** 2026-11-12.

- **Game-tested:** green Upgrade Planner + robot Undo/Redo for 26 straight, 4 curved-A, 4 curved-B rails; independent chest/rail Undo history; Ctrl+Shift superforced blueprint overlay with Undo/Redo for 14 straight, 4 curved-A and 4 curved-B rails. Two distinct user log sessions, no observed Lua errors.
- **Source-audited:** fixed `undo_index=1` and manual blueprint Undo joining removed. Native upgrades preserved. Obsolete join marks discarded; independent custom selection-tool queue retained.
- **Not yet fully tested:** delayed robots with an unrelated action after blueprint overlay; partially completed jobs; dedicated rail replacement selection tool; half-diagonal rails; signalling, inventory, broad compatibility.
- **A–D status:** A passed; B partially passed; C partially passed; D unverified. See [game test evidence](tests/undo-0.1.8-2026-11-12.md) and [build manifest](BUILD_018.yaml). The ZIP's source provenance and SHA-256 remain unchanged; documentation updates are not a new game build.

## Historical 0.1.7 snapshot (not current 0.1.8 status)

# Development status

**Branch-specific status:** `diagnostic/blueprint-rail-undo`, ElectrifiedMainline **0.1.7**.
**Last verified in-game session:** 2026-11-12, Factorio **2.1.20** (user installation directory labelled 2.1.20b).

## Verified

- The 0.1.7 mod loads with the user's Bob's Mods environment and opens the existing test save.
- Vanilla **straight ground rails** upgrade to high-speed straight rails through the **native green Upgrade Planner** and construction robots.
- **Ctrl+Z** reverses the upgrade and robots restore the original vanilla straight rails; **Ctrl+Y** upgrades them again. Both Undo and Redo logged **20 `upgraded-entity` actions**, with corresponding mining/building events.
- `data-final-fixes.lua` configured four corresponding ground-rail prototype pairs (straight, curved-A, curved-B, half-diagonal), and logged successful eligibility checks. This does **not** mean all four have passed gameplay tests.
- Earlier separate tests confirmed the unified custom rail planner places custom rail entities with robots and recognizes additional rail geometries for detection.

## Unverified or still experimental

- Native green Upgrade Planner upgrade/Undo/Redo for **curved-A, curved-B, half-diagonal** rails.
- **Ctrl+Shift superforced blueprint overlay** and its Undo/Redo. Do not equate that workflow with the confirmed green planner test.
- The separate `em-rail-replacement-planner` selection tool and its staged deconstruction/ghost workflow.
- Complete rail signal/route behavior, train occupancy, simultaneous work, inventory refunds and modpack compatibility.
- Actual electric traction, overhead transfer, onboard battery, bidirectional substations and regenerative braking are **not implemented**.

## Known legacy behavior

The 0.1.6 scripted superforce-ghost `undo_index=1` experiment allowed Undo to remove new rails but **did not restore** the originals. The old two-stage fallback remains in current source, and must not be described as fully reversible.

## Evidence & development

- [Mandatory contributor workflow](../CONTRIBUTING.md) — find and inspect a working native or same-type mod analogue, verify the target-version API, compare before coding, and test the exact gameplay path. Guessing mechanics is not an accepted workflow.
- [Project state — authoritative statuses](PROJECT_STATE.yaml)
- [Current AI handoff](AI_CONTEXT.md)
- [Research-first engineering method](RESEARCH_METHOD.md) — **mandatory: inspect working examples and prototype/API contracts before implementing a workaround**
- [Prototype research worksheet](PROTOTYPE_RESEARCH_TEMPLATE.md) — complete the research sections before non-trivial implementation; append exact test evidence afterward.
- [Completed 0.1.7 rail-upgrade record](research/rail-native-upgrade-0.1.7.md) — worked example with explicit proof boundaries.
- [Architecture](ARCHITECTURE.md)

CI packaging and Lua syntax checks do **not** prove in-game behavior. Every claim must have a scoped game test or be labelled unverified.
