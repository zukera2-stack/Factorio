> **0.1.17 experimental branch, 2026-11-14:** Read-only connected-HSR corridor native signal-slot overlay implemented, with bounded native rail-graph traversal and collision-only markers. No signal proxy or real pole placement; Lua 5.2 mock tests and ZIP CI PASS at [#43595022975](https://github.com/zukera2-stack/Factorio/actions/runs/43595022975) (source e351146, artifact 14114052350, 40 mod ZIP entries); in-game Factorio 2.1.20 evidence still pending. Stable main remains tested 0.1.8. See [installation](TEST_INSTALL_017.md) and [research](research/catenary-corridor-native-slots-0.1.17.md).

> **NEW 0.1.17 RESEARCH ONLY (2026-11-14):** [Exact source/API comparison](research/native-signal-snap-for-catenary-0.1.17.md) identifies the native rail-signal placement cursor mechanism in the [Electrified Railways](https://github.com/AudricSan/Factorio-Mods/tree/3c9b713244c5721e7cb582ce5ee46381659323fb/ElectrifiedRailways) mod: its item builds a cloned `rail-signal` proxy, which is then destroyed/replaced by a real electric pole. This explains the user's screenshot of dozens of green signal placement squares, but **we must not copy/enable this blindly** due to possible train-block and native Undo/Redo disruption. Prefer a **read-only full-corridor HSR signal-slot visualizer** first. **0.1.16 now game-tested** for the *read-only command* on straight/curve A/curve B in Factorio 2.1.20 build 87512 ([11-run evidence](tests/catenary-geometry-0.1.16-2026-11-14.md)); all runs 4 CLEAR/0 errors, but this does not certify actual mast geometry. **Source remains 0.1.16**, no new ZIP; stable `main` untouched.

> **0.1.16 TEST BUILD / 2026-11-14:** The experimental [`feature/catenary-geometry-016`](https://github.com/zukera2-stack/Factorio/tree/feature/catenary-geometry-016) creates at most **4 temporary candidate bases** from `LuaRailEnd.location` of the selected custom ВСМ rail (2 per ground rail end), de-duplicates identical positions, and draws **one** transparent copy of the installed eight-direction Г-mast SpritePrototype for the selected collision-clear candidate. The command `/em-35kv-geometry [offset] [index]` does not place or delete entities, alter signals, power, or Undo. Static Lua 5.2 tests / ZIP [PASS, build #43586035896](https://github.com/zukera2-stack/Factorio/actions/runs/43586035896), [artifact #14109793189](https://github.com/zukera2-stack/Factorio/actions/runs/43586035896/artifacts/14109793189). [Docs CI #43586035869](https://github.com/zukera2-stack/Factorio/actions/runs/43586035869) passed for implementation commit. **Actual Factorio 2.1.20 gameplay for 0.1.16 is UNTESTED**, particularly curves and half-diagonal. [Install / test guide](TEST_INSTALL_016.md). This is not real snapping: CLEAR only checks collisions and engine rail end is not a measured wire contact point. Stable `main` stays 0.1.8.

> **0.1.15 USER SCREENSHOT TEST (2026-11-14):** [Seven-screenshot evidence record](tests/catenary-preview-0.1.15-screenshots-2026-11-14.md): `/em-35kv-preview` successfully draws labeled candidate rings/guide lines and console collision results on straight horizontal/vertical, curved A and curved B custom ВСМ rails at offsets **1** and **1.5**. Straight: 4 slots/8 markers; curved A/B: 5 slots/10 markers. Curve A at 1.5 includes two CLEAR positions for one `alternative_in` slot; overlapping labels and multiple candidates prove collision CLEAR is not enough to approve actual mast location. **Game-test partially passed for visible read-only command only**. Half-diagonal, negative cases, invalid offsets, Undo/Redo, physical pole placement and full game-build identification are still unverified. No source modifications in this documentation update.

> **0.1.15 TEST BUILD (2026-11-14):** [`feature/catenary-preview-015`](https://github.com/zukera2-stack/Factorio/tree/feature/catenary-preview-015) implements read-only `/em-35kv-preview [0.5..3]` diagnostic. Draws symmetric candidate 35 kV mast bases on both normals of each **ground-layer** engine signal slot, 15-second L/R rings and guide lines, existing eight-face art direction labels, and live prototype collision hints. **Not an actual snap/build system:** no electric poles, ghosts, rail signals, upgrades, power-transfer or Undo code changed. Candidate positions and face directions are hypotheses for visual calibration. **Static CI PASS:** [ZIP + Lua test run #43572452213](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213) and [documentation run #43572508712](https://github.com/zukera2-stack/Factorio/actions/runs/43572508712). Exact Factorio 2.1.20 game test **pending**. [Installation / ZIP download guide](TEST_INSTALL_015.md). Game plan: `ElectrifiedMainline/TEST_PREVIEW_015.txt`. Research: [0.1.15 preview](research/catenary-mast-preview-0.1.15.md). `main` stays tested 0.1.8.

> **0.1.14 TEST BUILD (2026-11-13):** Read-only `/em-35kv-slots` command added for **engine-computed signal slot markers** on selected/nearest custom ВСМ rails. The command draws temporary ground rings and labels (15s), logs positions/directions/layers, and **does not place/move/delete poles or rail signals, enforce HSR-only placement, or change Undo**. Source: `scripts/rail_slot_debug_014.lua`, instructions: `TEST_SLOTS_014.txt`. Pure Lua mocked geometry test exists; **One user screenshot** shows four labelled `in/out` markers on one ВСМ track section (d0/d8). This is visual evidence for that limited test only; it does **not** certify game build, all rail shapes or correct future mast placement. Preserve exact 0.1.13 in commit `52b8aca` and never modify `main`.

> **0.1.14 rail-signal-style placement research (2026-11-13):** [API + GitHub source review](research/catenary-rail-signal-slots-0.1.14.md) confirms `LuaRailEnd.out_signal_location/in_signal_location` provide engine-computed placement coordinates for rail ends. **Proposal only:** use these locations to snap non-signal 35 kV poles exclusively to the four HSR rail prototypes. **Never clone a real rail signal:** hidden signals can alter train blocks. The normal pole still requires script validation; native pre-placement signaling cannot be assumed. **No code or gameplay claims;** next test should be read-only slot-marker visualization, then Undo-safe placement prototyping.

> **0.1.13 archive recovery CI PASS (2026-11-13):** [Build #43452497607](https://github.com/zukera2-stack/Factorio/actions/runs/43452497607) validated Lua 5.2 syntax, 0.1.13 geometry, exact 32-file payload and packaged ZIP; [downloadable ZIP artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43452497607/artifacts/14053025333). [Docs #43452497543](https://github.com/zukera2-stack/Factorio/actions/runs/43452497543) passed. **No Factorio 2.1.20 gameplay verification**; `main` remains 0.1.8.

> **2026-11-13 — Active visual branch:** [`feature/catenary-visuals-014`](https://github.com/zukera2-stack/Factorio/tree/feature/catenary-visuals-014) now tracks **the exact 32 files** of the user-uploaded `ElectrifiedMainline_0.1.13(2).zip`, including 12 original PNGs. Archive provenance is pinned by [`docs/builds/013-payload.json`](builds/013-payload.json) and verified by `scripts/verify_013_payload.py`. The 0.1.13 code is **not** the separately proposed visual patch. **Static QA is not an actual Factorio 2.1.20 load**; do not claim gameplay success. `main` stays 0.1.8. Next changes: visuals only, bump to 0.1.14. See [visual assessment](VISUAL_BASELINE_013.md).

> **Recovery 2026-11-13 (uploaded 0.1.13):** The user-supplied 0.1.13 ZIP is a **prototype connection-point count hotfix**, not the separately discussed 0.1.13 visual patch. The uploaded ZIP includes 12 graphics PNGs and a different 0.1.12 renderer not tracked in this GitHub branch. **The archive has NOT been imported or game-tested here.** Stable `main` remains 0.1.8. See [exact hashes, archive diff, screenshot review, and next steps](RECOVERY_013.md).

> **0.1.12 latest CI PASS:** [build #43418015719](https://github.com/zukera2-stack/Factorio/actions/runs/43418015719), 33 image tests, Lua geometry/syntax and ZIP validation; [artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43418015719/artifacts/14033350683). Exact 2.1.20 game loading and visually correct arm/wire rotation remain UNVERIFIED. A conversation-local higher-detail ZIP uses byte-identical Lua but three different artistic PNGs.

> **0.1.12:** auto-aiming Г-cantilever and curved textured wires; zero energy transfer, signal/Undo untouched; game/CI pending. See docs/POWER_TEST_012.md.

> **Higher-detail optional sprite ZIP:** ChatGPT-local `ElectrifiedMainline_0.1.11.zip` uses original generated Г-art, not committed to GitHub; source Lua equals CI-verified 0.1.11. Local ZIP and alpha checks passed, game load pending. [Details](SPRITE_GAME_TEST_0111.md).

> **0.1.11 test ZIP built:** [GitHub Actions #43410505808](https://github.com/zukera2-stack/Factorio/actions/runs/43410505808), 28 Python tests, Lua syntax, PNG atlas and ZIP verification passed. [Artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43410505808/artifacts/14029696360). Gameplay 2.1.20 still untested; final artwork not included.

> **0.1.11 experimental Г-sprite game build in progress:** [test plan](SPRITE_GAME_TEST_0111.md). Four-frame mirror atlas, separate shadow, zero-copper isolation preserved; CI and actual Factorio load pending. Stable main and 0.1.10 unchanged.

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
