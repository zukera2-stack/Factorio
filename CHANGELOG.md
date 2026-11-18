# 0.1.46 (experimental, 2026-11-18)

- Separate one-per-real-mast technical anchors, zero native reach, bounded script copper, whitelist and audit.
- Independent 045 pixel-strand renderer and one-ghost dry-run visual preview.
- Retire old duplicate curve/art helper managers from runtime; cleanup on migration. No native Undo changes or power transfer.

# 0.1.45 (experimental, 2026-11-18)

- Pixel-authored contact and steel attachment points independent of hidden calibration.
- Near-vertical-only bow, internal-only sprite overlap, actual polyline droppers.
- Read-only pair diagnostics; graph unchanged. Pending game test.

## 0.1.44 — curved catenary chord geometry corrected (2026-11-18, test only)

- Studied 11 Factorio screenshots of 0.1.43: thick steel cable, faint copper-riveted droppers and curved conductor ends incorrectly passing behind supports.
- Removed rail-centre Catmull-Rom spline interpolation, replaced with taut copper wire chords between registered support tips on curved spans. Curved graph remains validated via connected ВСМ rails.
- Restored byte-identical stable 0.1.42 rail topology code; kept all 12 approved 039 mast PNG and 3 copper/steel/rivet 043 textures. Steel cross-section scaled 0.40, copper 0.48, rivet droppers 1.14 width and at shorter intervals. NORTH_DROP=2.02, 32/16/40, Undo unchanged.
- Added detailed screenshot issue audit, offline rendered geometry/reuse/cleanup regression and SHA256 asset+rail-graph gate; rendering allows up to 4 tiles beyond mast-spacing limits for C-arm tip reach, with max 12 textured segments per line. Graph eligibility remains 32/16. Pending user screenshot acceptance in Factorio. `main` remains 0.1.42.

## 0.1.43 — experimental copper/steel catenary sprites (2026-11-18)

- New PNG textures with exactly the previous sprite dimensions: contact copper wire `128×10`, steel messenger wire `128×10`, riveted steel/copper dropper `10×32`, transparent RGBA; SHA-256 pinned in CI.
- All 25 kV straight and curved spans now use short rotated LuaRendering sprites. Curved geometry is sampled from **connected ВСМ rail centres**, smoothed using Catmull-Rom; short/individual curved rail shapes remain an approximate visual fit, pending game screenshot verification. The native curve connector topology remains, but its visible copper wires are disabled.
- Added dynamic Lua mock test `tests/25kv_curve_sprites_043.lua`, shape/asset verifier `scripts/verify_043_assets.py`, in-game checklist `ElectrifiedMainline/TEST_CURVE_043.txt` and ZIP payload checks in GitHub Actions. Stable `main` remains 0.1.42 and `NORTH_DROP=2.02` unchanged.
- No actual electric MW traction/energy transfer; this is **visual test build**.

## 0.1.42 — promoted to stable main (2026-11-18)

- [PR #20](https://github.com/zukera2-stack/Factorio/pull/20) merged, commit `5e2625c49b40f03c1262507e2fbfd8862f91ba7f`. User tested the clean GitHub build and confirmed «все работает».
- Factorio 2.1.24 (build 87808) log confirms loading, bot/ghost builds, native Undo/Redo of straight and curved rail activities without runtime error. [Final QA report](docs/tests/catenary-0.1.42-main-acceptance-2026-11-18.md).
- Maintains 16 active PNGs, `NORTH_DROP=2.02`, 32/16/40 HSR spans and native Undo. Actual MW electric traction is future work.

### Очистка спрайтов 0.1.42 (2026-11-18)

- Удалены 20 ненужных исторических PNG из экспериментальной ветки: 8 полных 012, 8 консолей 024, старый native mast, старый скрытый столб, заглушка провода и прежняя иконка. Сохранена используемая тень.
- Убран устаревший спрайт `em-35kv-contact-wire-texture` и промежуточный 024 путь в прототипе, удалены старые 033/035/036 генераторы и растровые проверки.
- CI теперь контролирует разрешённый список из 16 PNG и SHA-256 12 принятых спрайтов. `NORTH_DROP=2.02`, рельсы, 32/16/40 и Undo не менялись; стабильная `main` не затронута.

## 0.1.42 — visually accepted 25 kV mast family; GitHub import (2026-11-18)

- User confirmed in Factorio that the long southern and short northern mast consoles visually align. North shortened variant uses `NORTH_DROP=2.02` tiles; 0.1.41 used 2.05, 0.1.40 used 2.10.
- Active 0.1.39 artwork imported as twelve **byte-identical tracked PNGs**: long and short masts, eight direction-specific console/insulator overlays, and two item icons. Original prototype IDs remain for save compatibility.
- 0.1.37/0.1.38 source-art conversion exposed broken clipped/undersized mounts and scaling; 0.1.39 corrected alpha cropping, mount points and eight mirror projections. These older attempts are not recommended test baselines.
- Straight 25 kV conductor visuals and hidden native connector graph inherited from 0.1.29–0.1.31, with 32 / 16 / 40 tile limits; real traction MW=0.
- Added 0.1.42 binary-sha/source tests and version-gated older geometry tests. This experimental branch remains outside `main` (still 0.1.24). Visual acceptance is not full Factorio rail/Undo regression acceptance.

## 0.1.36 — native SOUTH arm lowered; stretched lattice replaced (2026-11-16)

- Screenshot matched SOUTH standard C-arm ~0.40 tile too high; return native picture, shadow and separate arm DOWN 0.40 tile, aligning triangles with short NORTH and intact 25 kV contact wire and placement marker.
- Copper helper and custom contact/messenger/dropper render positions deliberately left unchanged from 0.1.35; connected ВСМ geometry/32-16-40 and real Undo unchanged.
- Replace 0.1.35 stretched truss with 54 unscaled source rows repeated from real 0.1.24 mast art, 10-pixel seam blend, exact original footer and cap. Add Lua and PNG contract tests.
- Isolated gameplay screenshot trial; no main merge.

## 0.1.35 — south standard C shaft length measured from screenshot

- Measured 27px mismatch of north/south contact-wire levels on 1927x1080 screenshot at game zoom (source scale .5).
- Standard south native pole 512x512 image keeps foundation world anchor fixed; truss segment extended by 54 RGBA source rows and arm moved -0.84375 tiles. Separate wires (contact/messenger/droppers) drawn at corrected matching height.
- Restored south native hidden copper helper attachment to its pre-0.1.34 location, without changing track graph/32/16/40/Undo. Short north native mast remains unchanged.
- Added offline pixel-geometry contract and Lua test, game test still needed; no main merge.

## 0.1.34 — fixed north cantilever and raised south standard mast (2026-11-16)

- Resolved 0.1.33 missing cantilever by drawing per-face C-arm sprites for north short variant, rather than assuming arm baked into its shaft-only native PNG.
- Raised standard south-side native mast, shadow, arm and hidden copper tip by 0.40 tiles; north short remains at previous vertical shift.
- Introduced shared visual projection table, synced blueprint ghost overlays for both entity types and added regression tests for all 8 facings.
- No ВСМ/rail prototype, 32/16/40, electric traction or native Undo changes; requires game acceptance.

## 0.1.33 — short northern native C mast trial

- Distinct north-of-track native pole item and prototype. Original south mast unchanged.
- New reproducibly generated PNG shortens central mast lattice 70px, shifts graphics +2.20 tiles, base toward HSR ballast; native connectors follow hanger.
- Graph supports mixed prototype trackside poles, 32/16/40 limits, HSR rail PNGs, normal Undo and blueprint life cycle unmodified.
- Existing poles NOT auto-swapped; user must place variant manually for test. Traction model still MW=0.

## 0.1.32 - south-of-track catenary sprite alignment trial (2026-11-16)

- Screenshot observation: 0.1.31 custom contact wire and dropper graphics render, but south-side C-mast triangular hangers sit below contact sprite ends.
- Calibrate only north-facing (south-of-rail) ART sprite endpoint by -0.22 x/+0.90 y world tiles; hidden native copper helper remains at exact 0.1.31 position.
- All other face directions, 32/16/40 limits, Factorio native copper topology, C mast art and HSR rails unchanged.
- Automated regression checks for visual-only correction; Factorio screenshot QA pending, do not merge main.

## 0.1.31 — critical 0.1.30 save-load crash hotfix (2026-11-16)

- Fix Factorio hard error during `on_configuration_changed`: nested runtime `require` in `scripts/catenary_art_030.lua:sync` moved to top-level module initialization.
- Add regression test that disallows all `require` during simulated game configuration callbacks, synch, periodic ticks and cleanup.
- No changes to C mast and ВСМ rail visuals, dual cable art, native connection/Undo, 32/16/40 limits or MW=0.
- 0.1.30 experimental ZIP is invalid; install 0.1.31. Actual game loading still to be confirmed.

## 0.1.30 — visual contact catenary pilot (2026-11-16)

- Straight custom ВСМ: invisible real Factorio copper connectors with textured contact, messenger and dropper sprites.
- Curves: retain visible 0.1.29 native copper rendering. No global utility-sprite replacement.
- C masts, rails, Undo, spacing 32/16/40 unchanged, 25 kV traction still MW=0.
- Tests and screenshot guide; not yet game-approved, no main merge.

## 0.1.29 — experimental long 25 kV contact spans (2026-11-16)

- Requested maxima: straight 32 tiles, curves 16 tiles, hidden native-copper helper 40-tile wire reach.
- Added HSR-only bounded rail connection walk that identifies a curved piece anywhere along a span, rejects significant detours, and never traverses vanilla rail.
- Dense straight corridor samples (~2 tiles) and enlarged rail-change rescan; removed all custom old LuaRendering lines remain removed.
- Does not implement approved messenger/contact/dropper sprite graphics yet; native copper wire, C mast sprites, current insulator offsets, native Undo and vanilla rail behavior unchanged.
- Not tested in-game. Do not merge into main before user's Factorio 2.1.20 test.

## 0.1.28 — experimental automatic native contact wires / nominal 25 kV (2026-11-16)

- Names shown in Russian and English changed 35 kV → 25 kV, while existing prototype IDs kept for backward-compatible saves.
- Eight C-arm sprite-specific hidden native-wire anchors; SOUTH offset accepted in gameplay 0.1.27, seven provisional and tunable.
- Automatic native copper wires only along connected custom high-speed rail paths; straight edges now also validate get_connected_rail.
- On every rail/mast topology change schedule coalesced native wire sync; remove helpers and forbidden ordinary electric-pole links; no Lua lines.
- No actual 25,000 V AC electricity model/traction; no main changes until game QA.

## 0.1.27 — experimental C-insulator native-wire alignment (2026-11-16)

- Shifted native hidden copper helper toward SOUTH C-arm triangular insulator using user gameplay screenshot (+1.75 right, 2.30 up vs 0.1.26).
- Removed all LuaRendering.draw_line contact/messenger/feeder segments; retained topology and C mast graphics.
- Added in-game DX/DY calibration and cleaned legacy 0.1.26 helper nodes during version update.
- 25 kV AC is future model, no automatic wiring, no main merge until user game QA.

## 0.1.26 — experimental native copper-wire probe, NOT a release (2026-11-15)

- Separate `experiment/native-25kv-wire-026` branch from accepted 0.1.24 main; independent of 0.1.25 thin-line experiment.
- Two invisible offset helper poles at existing C-mast arm tips plus on-demand visible copper connection via the Factorio engine. Commands: `/em-25kv-probe start`, `status`, `clear`.
- No new engine wire type, no real 25 kV AC/MW model, no traction or regeneration. Existing mast art and native rail/Undo remain unchanged. Needs user game screenshots and logs; CI only checks source/ZIP.

## 2026-11-15 — 0.1.24 merged into main (PR #8)

- User-approved catenary C-mast visual milestone [merged via PR #8](https://github.com/zukera2-stack/Factorio/pull/8), merge commit `43dd05a544a02de75f3b4a3c3689cd795f853d21`. The `main` `info.json` now reports **0.1.24**.
- Post-merge [GitHub Actions build #43748406702](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702) PASS, [main ZIP artifact #14175755233](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702/artifacts/14175755233), [post-merge docs validation #43748406753](https://github.com/zukera2-stack/Factorio/actions/runs/43748406753) PASS. Only documentation adjustments follow this merge.
- Old `dist/ElectrifiedMainline_0.1.8.zip` remains for rollback. **Electricity `transfer_MW=0`**, wires visual only; next engineering phase is contact/messenger wire art and geometry, not an untested power simulation.

## 0.1.24 — accepted 35 kV C-mast visual milestone (2026-11-15)

**Game-tested by user on Factorio 2.1.20 build 87512**, and explicitly approved for promotion to `main`. [Actual screenshot/log evidence](docs/tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md); [GitHub Actions ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/43738070195/artifacts/14171451634).

- Factorio-native visible lattice shaft under build cursor; native ghost shaft effect.
- Eight Lua-rendered rail-facing C cantilever/insulator overlays; blue-tinted arm-only ghost art.
- SOUTH sprite 64×64 inventory icon and muted circular rail-slot hints.
- User-tested manual/robot construction, ghosts and native Undo/Redo sequences without reported Lua errors. Existing 0.1.8 rail Upgrade Planner evidence retained; not every scenario was re-run in 0.1.24.
- **No real overhead power (`transfer_MW=0`), batteries or energy regeneration.** Next phase: precise visual contact/messenger wires.
- This is an accepted *visual* baseline, not a claim of complete railway electrification.

## 2026-11-15 — 0.1.24 GitHub ZIP static verification

- [Build run #43737875221](https://github.com/zukera2-stack/Factorio/actions/runs/43737875221): SUCCESS, [ZIP artifact #14171016545](https://github.com/zukera2-stack/Factorio/actions/runs/43737875221/artifacts/14171016545). Lua/ghost/cursor regressions, 9 PNG SHA256/alpha tests, package metadata and ZIP PASS.
- [Sprite QA #43737875150](https://github.com/zukera2-stack/Factorio/actions/runs/43737875150): SUCCESS.
- New `0.1.24` Factorio game behavior remains unverified; expected mouse cursor displays nonrotating mast shaft rather than full G-arm. Main 0.1.8 not touched.

## 0.1.24 — native cursor mast and direction-specific arm sprites (EXPERIMENTAL)

- Isolate original eight C mast PNGs into a common **native lattice mast shaft** and eight **arm-only C graphics**, all RGBA 512x384. Original full original sprites retained in repo for exact rollback. Static transparent masks preserve lower 225 px foot/shaft and arm positions; artistic seams require game confirmation.
- `prototypes/power_019.lua` sets `catenary.pictures` to shaft (one orientation), retains existing shadow and one wire connection point. Removes incorrect `placeable_position_visualization` as full cursor picture.
- Lua faces still selected by unchanged RailEnd algorithm. Built mast and ghost render only cantilever/insulator with higher-object-above ordering; Factorio engine renders shaft, placement cursor and native ghost shaft.
- The south item icon, circular rail-slot indicator, native build, ghost lifecycle, robotic construction, rail Upgrade Planner and Undo unchanged. Electricity 0 MW.
- Added PNG integrity and geometry static QA (no engine test). Test guide in `ElectrifiedMainline/TEST_VISUAL_024.txt`. `main` 0.1.8 untouched.

## 2026-11-15 — 0.1.23 user game evidence + native cursor API design decision (docs only)

- User reports full item icon, successful ghost placement/copy/deconstruction/robot building; screenshot/log inspection confirms mod loads and ghost/Undo/Redo events occur. The mouse placement model is still invisible (only shadow), no game Lua exception.
- Found incorrect 0.1.23 assumption: `placeable_position_visualization` does not replace engine `ElectricPolePrototype.pictures`, which drives the native cursor/ghost graphics. Native blue blur cannot simply be applied by `LuaRendering.tint`.
- Select **native fixed lattice mast body plus eight Lua-rendered arm-only overlays** as next scoped artwork experiment (0.1.24), not yet produced; preserve 0.1.23 mechanics. [Decision](docs/research/catenary-native-cursor-ghost-decision-0.1.24.md).
- [User test report](docs/tests/catenary-visual-0.1.23-user-test-2026-11-15.md). `main` untouched; no gameplay code or PNG changes in this commit.

## 2026-11-15 — 0.1.23 CI/ZIP ready for user testing

- [GitHub Actions #43731628908](https://github.com/zukera2-stack/Factorio/actions/runs/43731628908) PASS, [downloadable build](https://github.com/zukera2-stack/Factorio/actions/runs/43731628908/artifacts/14168876545) with `ElectrifiedMainline_0.1.23.zip` nested inside, 38 files. Lua mocks for ghost lifecycle/rail-slot rings and icon dimensions PASS.
- Changes to test fixtures only after initial commit; real build/ghost/wire/Undo code unchanged in those fixes.
- **No in-game 0.1.23 confirmation yet**. Await user's ghost, cursor-preview and robot Undo screenshots/log.

## 0.1.23 — Visual polish (experimental GitHub Actions ZIP; game pending)

- Generate 64x64 transparent catenary icon from the **south** of the existing approved C sprites, use it for the item and entity.
- Add native cursor placement visualization of the southern C mast without touching the real world's invisible electric-pole picture. Appearance must be validated in Factorio 2.1.20.
- Draw 8-way blue translucent C sprites for actual `entity-ghost` entities via LuaRendering, auto-destroy with ghost target and restore across mod/save migration. No gameplay changes to ghost build/robot/Undo.
- Replace bright square marker overlays with muted green/red/amber/magenta open circular rings, leaving READY/BLOCKED/OUT_OF_REACH/ERROR classification and Alt+LMB untouched.
- Add mocked ghost lifecycle regression, icon PNG structural QA and [API research](docs/research/catenary-ghost-cursor-0.1.23.md). CI/static pass **does not** prove gameplay.
- `main` 0.1.8 untouched; power 0 MW.

## 2026-11-15 — cleanup CI pass and corrected history links (docs-only)

- [Post-cleanup ZIP build #43727816486](https://github.com/zukera2-stack/Factorio/actions/runs/43727816486) PASS, artifact [#14167038465](https://github.com/zukera2-stack/Factorio/actions/runs/43727816486/artifacts/14167038465). Exactly the same 0.1.22 playable Lua and current C graphics, with obsolete assets and test memos excluded.
- Repaired Markdown links referencing removed full-res art sources: use immutable pre-cleanup Git commit. The first documentation check failed on those references; rerun required after correction.
- No game-tested claim for 0.1.22 facing, and stable main 0.1.8 unchanged.

## 2026-11-15 — audited 0.1.22 repository cleanup, no gameplay code changes

- Removed **21 superseded files** (about 6.55 MiB): 0.1.21 raw high-res C source images and original duplicate ZIP (still recoverable from Git history), outdated unreferenced 4-frame atlas, and old in-mod 0.1.12–0.1.18 test memo files.
- Kept all eight active 0.1.21-origin C sprite images, active shadow, current Lua/rail/Undo logic, sprite QA pipeline, user test screenshot evidence and historical research; added accurate 0.1.22 test memo inside the mod instead.
- Updated README current-development text (previously incorrectly said 0.1.16 was active) and corrected authoritative status/source-archive locations. [Full audit](docs/REPOSITORY_AUDIT_2026-11-15.md).
- Stable main 0.1.8 unaffected. Build/QA after this cleanup required before claiming the new archive works.

## 2026-11-15 — verify finished GitHub-built 0.1.22 ZIP (docs only)

- GitHub Actions [#43725722949](https://github.com/zukera2-stack/Factorio/actions/runs/43725722949) passed 0.1.22 Lua syntax, mocks and packaging. The delivered ZIP was independently downloaded and inspected: nested mod archive is valid, exact original 0.1.21 C PNGs and shadow match byte-for-byte, and new 0.1.22 facing module is inside.
- GitHub project-state was reconciled: obsolete "PNG not uploaded", "022 CI pending" and "021 visual test not started" flags were updated to the observed facts. New facing code is STILL unverified in real Factorio.
- Stable main remains untouched.

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
