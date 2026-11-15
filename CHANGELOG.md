## 2026-11-15 — complete C concept art archive and user test montage

- Committed **all nine original full-resolution C images** to `art/sources/021-C/`, verified by per-file original SHA256 and Git blob SHA. No palette conversions or recompression.
- Committed six-image 0.1.21 **Factorio user screenshot contact sheet** to `docs/tests/evidence/`, embedded in the existing facing failure report. User's original six screenshot files total 28 MB and remain in original chat attachment; repository version is a review montage, not unmodified evidence originals.
- 0.1.22 source build [Actions #43725722949](https://github.com/zukera2-stack/Factorio/actions/runs/43725722949) **SUCCESS**, [artifact #14166570620](https://github.com/zukera2-stack/Factorio/actions/runs/43725722949/artifacts/14166570620). Actual revised facing in Factorio still unverified.

## 0.1.22 — Github-source complete C-mast facing experiment

- Original C-mast PNG images (8 facings plus common base shadow) are now tracked **byte-identically** in the repository. They match the user's 0.1.21 tested ZIP; no quality-reducing conversion. Exact 0.1.21 ZIP saved as `art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip`.
- `info.json` bumped to 0.1.22; package is now fully reproducible by GitHub Actions, no conversation-local binaries needed.
- `scripts/mast_facing_022.lua` and `power_019.lua` change ONLY selection of the visual G-arm octant, using closest RailEnd geometry rather than rail entity.center. Added `[face022]` logging and mocked regression tests.
- No changes to placement tiles, green markers, native Undo, train signals, Upgrade Planner, or electrical power (still 0 MW).
- **Gameplay result of 0.1.22 new algorithm is pending.** See [0.1.21 user visual evidence](docs/tests/catenary-C-art-0.1.21-facing-2026-11-15.md) and [new test instructions](docs/TEST_INSTALL_022.md).

## 2026-11-15 — 0.1.21 game-test; begin isolated 0.1.22 visual-facing correction (not a release)

- User screenshots and log confirm actual Factorio 2.1.20 game load of C mast art (0.1.21), but multiple curved/half-diagonal cases point G-arms away from the nearby rail. [Game report](docs/tests/catenary-C-art-0.1.21-facing-2026-11-15.md).
- Source analysis identifies facing by `rail LuaEntity.position`, not by nearest running-line point. New read-only helper `mast_facing_022.lua` projects to RailEnd chord or sampled curve; changes only SpritePrototype-facing selection in `power_019.lua`. No placement filters or script placement adjustments.
- Added mocked facing regression and diagnostic logs. **Factorio runtime of revised algorithm not tested.** Exact 0.1.21 C-art binaries remain outside GitHub; this commit is NOT yet a reproducible 0.1.22 C-art ZIP. Main stable 0.1.8 unchanged.

## 2026-11-15 — local 0.1.21 art ZIP ready for user Factorio test (DOCS only in GitHub)

- Concept C eight-direction sprite assets generated locally from selected art, with SOUTH=east-like and NORTH=west-like screen projection. Local ZIP with replacement 512×384 RGBA sprites, new base shadow, version bump 0.1.21 and tester memo successfully verified for archive/image integrity.
- **IMPORTANT: GitHub source assets and this ZIP are NOT checked in**; this docs update records their name/SHA256 and precise build methodology. GitHub code remains 0.1.18 art branch, and no GitHub CI/game-test result for 0.1.21 yet.
- Test instructions and evidence boundary in [builds/021-local-c-mast-game-test.md](docs/builds/021-local-c-mast-game-test.md). User next tests copy of save, captures screenshots and log. If accepted, persist graphics into GitHub properly.
- No changes to power transfer, rail physics, Undo/Redo, signal blocks or stable main.

## 2026-11-15 — user selects C mast concept, C2 visual refinement specification (docs only)

- User viewed three artistic sketch options and chose C, balanced industrial lattice mast. No more A/B/C choice needed.
- New [C2 refinement plan](docs/concepts/35kv-mast-C-refinement-2026-11-15.md) specifies simplified single arm, compact 1×1 base, P0/P1/P2 anchor locations, streamlined insulators, no baked-in long wires or substation box.
- C2 sketch still pending approval. Later: one east prototype frame, seven other sprites/shadows, CI ZIP, real Factorio test, visual wires, electricity last.
- No code or art binary changed; stable main 0.1.8 unchanged.

## 2026-11-14 — user-approved catenary mast ART DIRECTION, documentation only

- Work order pinned for cross-chat continuity: **sketch concepts A/B/C first → explicit choice → 8-direction mast PNG + shadow pass → real Factorio screenshot game QA → independent contact-wire visual pass → electrical logic last**. No sprites or new ZIP in this commit.
- New [full visual specification](docs/ART_DIRECTION_35KV.md), [short next-chat handoff](docs/NEXT_35KV_VISUAL.md), and updated `docs/AI_CONTEXT.md`, `docs/STATUS.md`, `docs/PROJECT_STATE.yaml`.
- New planning branch `feature/catenary-mast-art-plan-021` based on game-tested 0.1.18 docs head, deliberately excluding failed 0.1.20 capsule placement experiment. Existing main 0.1.8 unchanged.

## 0.1.18 — 2026-11-14 gameplay observations (docs only)

- Two user screenshots + Factorio 2.1.20 log verify colored rail-adjacent squares while holding the real 35kV pole and one Alt+LMB `build_from_cursor` construction at (30.5,-17.5), true `electric-pole` type.
- Event detail: tick 49936 shows two `on_pre_build` but one `on_built_entity`. Normal/robot pole Undo/Redo works, but Alt-built pole's Undo/Redo is still unverified because no undo action targeted its position.
- Next isolated test: 3 poles -> exactly one Alt click -> immediate Ctrl+Z/Ctrl+Y; verify item counts and native undo event. [Full evidence](docs/tests/catenary-native-player-build-0.1.18-2026-11-14.md).
- No new mod code/build or main changes.

## 0.1.18 — 2026-11-14 experimental Factorio-owned mast building

- When the real 35 kV mast item is held, automatically paint short-lived green/amber/red ground squares from nearby native rail signal location references, normalized to the actual electric pole grid. No sparse 16-tile filter or fake rail-signal entities.
- Alt + Left Click tries the nearest HSR-adjacent pole site using LuaPlayer.can_build_from_cursor and LuaPlayer.build_from_cursor. Native engine handles actual entity and cursor item. Vanilla LMB preserved; script does not create/destroy/teleport pole, inject Undo actions or place rail-signal proxies.
- New Lua 5.2 mocked contract checks, CI packaging and test plan. Static Lua 5.2 syntax/mock regression tests and ZIP packaging PASSED in [Actions #43601951663](https://github.com/zukera2-stack/Factorio/actions/runs/43601951663) (ZIP artifact 14115959103); actual pole positions, signal-style UI fidelity and scripted native undo ownership remain unverified until Factorio 2.1.20 user test.
- Stable main 0.1.8 and existing 0.1.17 tools untouched.

## 0.1.17 — 2026-11-14 user game-test evidence (docs only)

- Nine screenshots and Factorio 2.1.20 build 87512 log confirm nine /em-35kv-corridor invocations, zero API errors, 7-43 HSR rails per call and 30-160 native slots; two capped radius-32 views.
- Connected curved and straight segments display reference locations; densely parallel rails show many collision-blocked positions. This is not accepted real mast placement geometry, and Undo/signalling under traffic remain unverified.
- [Game-test report](docs/tests/catenary-corridor-0.1.17-2026-11-14.md). No code, game ZIP or main changes.

## 0.1.17 — research only (no mod version bump or runtime changes)

- Recorded full 0.1.16 game evidence: user screenshots and Factorio 2.1.20 build 87512 log confirm eleven `/em-35kv-geometry` invocations on straight, curved A/B custom rails with all 4 candidates CLEAR; half-diagonal, real pole placement, and Undo untested.
- Inspected Factorio's native signal placement UI and the exact AudricSan Electrified Railways GPL-3.0 source analogue using a **temporary rail-signal placement proxy** followed by pole replacement. Identified risks to block semantics and native Undo/Redo; **do not introduce the proxy in our code yet**.
- Documented safer full-track read-only signal-slot preview and future native-player-build experimental gates. Research branch `feature/catenary-snap-research-017`, **info.json and source stay 0.1.16**; `main` stays stable.

## 0.1.16 (experimental; read-only rail-end mast geometry)

- Added `/em-35kv-geometry [offset] [index]` (default offset 1.5 tiles), deriving at most four symmetric mast-base candidates from **engine rail-end locations** instead of per-signal positions; exact overlaps are removed.
- The preview draws short numbered colored rings and at most **one translucent full-size existing Г-mast SpritePrototype**, oriented toward the corresponding rail end. An optional index chooses which candidate to inspect. The colour reports only prototype collision clearance.
- Existing `/em-35kv-slots` (0.1.14) and `/em-35kv-preview` (0.1.15) remain available for independent A/B comparison. Real rails, poles, train signals, actual placement, native Upgrade Planner/Undo/Redo, power and save storage are untouched.
- [Research and falsification plan](docs/research/catenary-rail-end-geometry-0.1.16.md), [test worksheet](docs/TEST_INSTALL_016.md), standalone mocked Lua test and 0.1.15 regression tests are present; [CI Lua/ZIP PASS #43586035896](https://github.com/zukera2-stack/Factorio/actions/runs/43586035896). **Factorio 2.1.20 gameplay for 0.1.16 remains UNVERIFIED.**
- Current feature branch `feature/catenary-geometry-016`, based on 0.1.15 screenshot-evidence commit `727e998`. Stable `main` unchanged.

## 0.1.15 (experimental; read-only mast position preview)

- Added `/em-35kv-preview [0.5..3]` to draw L/R mast-base candidates from engine signal slots of custom ВСМ rails (default offset 1 tile).
- Shows proposed eight-face cantilever direction toward each signal **reference** and `LuaSurface.can_place_entity` collision hints; circles, lines and labels expire after 15 seconds.
- Filters to ground rail-layer slots; invalid offset and non-ВСМ selection produce messages without marker creation.
- No pole or ghost creation, no train signal or existing mast changes, no Undo/Redo hooks, no electrical MW transfer, no enforced HSR-only building.
- Includes mocked Lua tests, new test worksheet and [research](docs/research/catenary-mast-preview-0.1.15.md). [Static CI passed](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213) (Lua 5.2 geometry tests and ZIP packaging); [documentation checks passed](https://github.com/zukera2-stack/Factorio/actions/runs/43572508712). Actual Factorio 2.1.20 game testing **pending**.
- Isolated branch `feature/catenary-preview-015` from 0.1.14 `9916f11`. Stable `main` unchanged.

- Documentation correction (2026-11-14): separate stable 0.1.8 and experimental 0.1.15 in both READMEs; add [ZIP installation/test instructions](docs/TEST_INSTALL_015.md), distinguish build artifacts from documentation-only Actions and mark the archived 0.1.13 pre-import handoff as superseded. No runtime changes.

- Gameplay evidence update (2026-11-14): seven user screenshots verify visible read-only marker rendering on straight horizontal/vertical and curved A/B for offsets 1.0/1.5, but NOT correct mast positioning; see [detailed scoped record](docs/tests/catenary-preview-0.1.15-screenshots-2026-11-14.md). No code modifications; half-diagonal and Undo tests remain pending.

## 0.1.14 (experimental; read-only rail slot diagnostic)

- Added `/em-35kv-slots` to display up to eight engine-provided signal-slot positions beside the selected or nearest ВСМ rail, with direction/layer printout and 15-second markers.
- Added mocked Lua slot geometry test; no signal entity creation, pole snapping, native signal edits, Undo queue modifications or real electrical MW transfer.
- HSR-only placement restriction is **not implemented** in this diagnostic version; screenshots are required to choose safe mast offsets.
- Factorio 2.1.20 runtime testing **pending**; this is not a gameplay-certified release.

## 0.1.13 (user-archive recovery; experimental visual baseline)

- Imported the exact user-supplied 0.1.13 mod payload into isolated `feature/catenary-visuals-014`, preserving 12 original PNGs and the eight-facing rail-aware runtime.
- The only 0.1.12 -> 0.1.13 source hotfix limits invisible pole `connection_points` to one to match `direction_count=1`; no change to signal logic, rail Upgrade Planner, Undo or real energy transfer.
- Added immutable per-file SHA-256 manifest and source/ZIP validation; next art revisions must use a new version (0.1.14).
- This is a source recovery and static QA milestone, **not** a Factorio 2.1.20 gameplay certification.

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

## [0.1.17] - 2026-11-14 (isolated experimental native-slot preview)

- Introduce /em-35kv-corridor to draw transient collision-classified native rail-signal location markers along connected custom HSR rails (straight, curved A/B, half diagonal); no real signals, build/move/replace, inventory, MW or Undo interaction.
- Hard caps: 128 rails and 160 unique physical slots, bounded radius 8..32; no per-tick scan. Existing diagnostics retained.
- Add Lua 5.2 mock contract regression, build workflow integration and in-game test instructions. Static CI and in-game status must be tracked separately; gameplay unverified.
- Stable main 0.1.8 untouched. Research: docs/research/catenary-corridor-native-slots-0.1.17.md.


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
