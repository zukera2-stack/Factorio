> **CURRENT 0.1.15 / 2026-11-14 (documentation audited):** Active branch [`feature/catenary-preview-015`](https://github.com/zukera2-stack/Factorio/tree/feature/catenary-preview-015), based on 0.1.14 at `9916f11`. Testable code commit `d07755c`; docs subsequently synchronized. `/em-35kv-preview [0.5..3]` renders temporary L/R candidate mast bases, guide lines to engine signal references, eight-face labels and pole collision hints. **No construction, signals, automatic snapping, power delivery or Undo/Redo edits.** Download only from [**Build Factorio mod ZIP #43572452213**](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213), artifact [#14105370603](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213/artifacts/14105370603); [docs checks #43572643863](https://github.com/zukera2-stack/Factorio/actions/runs/43572643863) also passed. **Do not use docs runs as ZIP links.** Installation: [TEST_INSTALL_015.md](TEST_INSTALL_015.md). CI mocks pass, **Factorio 2.1.20 gameplay for 0.1.15 pending**. 0.1.14 user screenshot shows four labelled signal markers on one rail segment, not proven mast geometry. `main` = game-tested 0.1.8.

> **0.1.14 TEST BUILD (2026-11-13):** Read-only `/em-35kv-slots` command added for **engine-computed signal slot markers** on selected/nearest custom ВСМ rails. The command draws temporary ground rings and labels (15s), logs positions/directions/layers, and **does not place/move/delete poles or rail signals, enforce HSR-only placement, or change Undo**. Source: `scripts/rail_slot_debug_014.lua`, instructions: `TEST_SLOTS_014.txt`. Pure Lua mocked geometry test exists; User screenshot confirms **four visible labelled marker points on one ВСМ rail section**; exact screenshot-only test does not establish all four rail geometries or a complete Factorio build/log verification. Preserve exact 0.1.13 in commit `52b8aca` and never modify `main`.

> **0.1.14 rail-signal-style placement research (2026-11-13):** [API + GitHub source review](research/catenary-rail-signal-slots-0.1.14.md) confirms `LuaRailEnd.out_signal_location/in_signal_location` provide engine-computed placement coordinates for rail ends. **Proposal only:** use these locations to snap non-signal 35 kV poles exclusively to the four HSR rail prototypes. **Never clone a real rail signal:** hidden signals can alter train blocks. The normal pole still requires script validation; native pre-placement signaling cannot be assumed. **No code or gameplay claims;** next test should be read-only slot-marker visualization, then Undo-safe placement prototyping.

> **0.1.13 archive recovery CI PASS (2026-11-13):** [Build #43452497607](https://github.com/zukera2-stack/Factorio/actions/runs/43452497607) validated Lua 5.2 syntax, 0.1.13 geometry, exact 32-file payload and packaged ZIP; [downloadable ZIP artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43452497607/artifacts/14053025333). [Docs #43452497543](https://github.com/zukera2-stack/Factorio/actions/runs/43452497543) passed. **No Factorio 2.1.20 gameplay verification**; `main` remains 0.1.8.

> **2026-11-13 — Active visual branch:** [`feature/catenary-visuals-014`](https://github.com/zukera2-stack/Factorio/tree/feature/catenary-visuals-014) now tracks **the exact 32 files** of the user-uploaded `ElectrifiedMainline_0.1.13(2).zip`, including 12 original PNGs. Archive provenance is pinned by [`docs/builds/013-payload.json`](builds/013-payload.json) and verified by `scripts/verify_013_payload.py`. The 0.1.13 code is **not** the separately proposed visual patch. **Static QA is not an actual Factorio 2.1.20 load**; do not claim gameplay success. `main` stays 0.1.8. Next changes: visuals only, bump to 0.1.14. See [visual assessment](VISUAL_BASELINE_013.md).

> **ARCHIVED RECOVERY SNAPSHOT (2026-11-13; no longer current):** At the time this note was written, the 0.1.13 user ZIP had **not yet** been imported into GitHub and the recovery checkout was still at 0.1.12. This changed after the verified 0.1.13 import (commit `52b8aca`) into `feature/catenary-visuals-014`. The 12 PNGs and exact 32-file baseline are now tracked; **do not treat the earlier “not imported” statement as current**. Historical record: [RECOVERY_013.md](RECOVERY_013.md). Stable `main` is 0.1.8.

> **0.1.12 successful CI and test artifact (2026-11-13):** [ZIP run #43418015719](https://github.com/zukera2-stack/Factorio/actions/runs/43418015719) passed Lua 5.2, 33 Python sprite QA tests (previous run also 33), straight/curve geometry assertions including 90-degree elbows, and single-version ZIP integrity. Artifact [14033350683](https://github.com/zukera2-stack/Factorio/actions/runs/43418015719/artifacts/14033350683) holds a synthetic-art mod ZIP. [Sprite workflow #43417478709](https://github.com/zukera2-stack/Factorio/actions/runs/43417478709) succeeded. Local higher-detail art ZIP with exact identical Lua/metadata differs only in three PNGs and SHA-256 c972337853fb6ee859c291a9ed10acc5dbc1d37d6806a3e765db973583e59eb0. No game test. Main remains unchanged.

> **0.1.12 rail-aware catenary test:** feature/rail-aware-catenary-012 from 0.1.11. No rail-signal entities. A separate scripted arm points at nearest HSR rail while the mast stays upright; short wire texture segments follow a spline. CI/game proof pending. See docs/research/rail-aware-catenary-0.1.12.md and docs/POWER_TEST_012.md.

> **Optional high-detail local test archive:** a conversation-local `ElectrifiedMainline_0.1.11.zip` with generated AI Г-pole graphics replaces only PNGs in the CI build, preserving the same Lua; SHA256 `de177dc3eb9a6e97bc1f3f3db3f34335a9b85a20034b073fa6f514f55276429c`. It is NOT in GitHub, and not covered by GitHub art tests. Local ZIP/alpha/mirror checks passed; game load unverified. See [test plan](SPRITE_GAME_TEST_0111.md).

> **0.1.11 test build CI success:** [Actions #43410505808](https://github.com/zukera2-stack/Factorio/actions/runs/43410505808) generated and packaged the 4-frame Г-sprite atlases; **28 Python tests**, Lua syntax and ZIP checks passed. [Artifact 14029696360](https://github.com/zukera2-stack/Factorio/actions/runs/43410505808/artifacts/14029696360). Initial docs CI failed solely because project.mod_version remained 0.1.10; updated to 0.1.11, docs CI pending. Factorio game test not run.

> **0.1.11 GAME-TEST branch:** `feature/catenary-sprite-game-test-0111` from sprite QA branch. Changes only 35 kV pole prototype to 4-frame mirrored Г atlas + shadow, registers contact-wire texture, and generates PNGs in CI from the **synthetic fixture**. Existing runtime draw_line, topology, Upgrade Planner, Undo/Redo and 35 kV zero-copper invariants untouched. API 2.1.24 supports RotatedSprite; Factorio 2.1.20 game test pending. See [test plan](SPRITE_GAME_TEST_0111.md).

> **Г-cantilever QA verified (2026-11-13):** [Sprite CI #43388634580](https://github.com/zukera2-stack/Factorio/actions/runs/43388634580) passed **22 tests**, PNG staging, asymmetric mast-anchor preparation, one-sided arm rejection of T-shaped geometry, Lua syntax, and offline API contract. [Artifact 14019876083](https://github.com/zukera2-stack/Factorio/actions/runs/43388634580/artifacts/14019876083) contains updated dark/light/checker preview. [Docs #43388634599](https://github.com/zukera2-stack/Factorio/actions/runs/43388634599) passed. **0.1.10 game prototypes unchanged; no Factorio game load.**

> **Г-geometry CI diagnostic:** First run #43388513885 passed the actual QA and most tests but failed one brittle test that sampled an exact pixel (170,90) after antialiased resizing; the arm shifted vertically. Fixed test to check the upper-right silhouette band instead. Pending retest. No mod runtime changes.

> **User art correction:** 35 kV catenary support must be a one-sided **Г-shaped** railway mast, NOT a symmetrical T. Branch `feature/sprite-pipeline-0111` demo geometry and manifest now use mast foot at (75,354), rightward cantilever, asymmetric alpha-bbox alignment in prepare.py, and silhouette regression tests. 1-direction right-facing art only; left-facing/rotated variants and game test remain pending. User's stock photo link is a shape reference, not a copied asset.

> **Sprite pipeline final tested scope (2026-11-13):** [CI #43387339441](https://github.com/zukera2-stack/Factorio/actions/runs/43387339441) **PASS: 19 Python tests**, including oversized transparent art preparation, 8-pixel stripe rejection, opaque background rejection, no cropping, reproducible PNG hashes, Lua syntax and offline API contract. [Preview artifact 14018579988](https://github.com/zukera2-stack/Factorio/actions/runs/43387339441/artifacts/14018579988). [Docs CI #43387339420](https://github.com/zukera2-stack/Factorio/actions/runs/43387339420) passed. New [art prompt brief](ART_BRIEF_35KV.md). **No final art and no Factorio 2.1.20 data-stage/game tests; playable 0.1.10 unchanged.**

> **Sprite preparation CI bug discovered and corrected:** First run [#43387247942](https://github.com/zukera2-stack/Factorio/actions/runs/43387247942) failed 1/18 tests: periodic-stripe detector incorrectly classified a uniform opaque image as stripes. Fixed by requiring distinct column signatures; uniform images are rejected by the separate opaque-background gate. Added regression test; new CI pending. This was a QA classifier bug, not a Factorio game failure.

> **AI-art input preparation added:** `scripts/sprites/prepare.py` accepts oversized transparent RGBA art, fits it inside the manifest canvas with no cropping, aligns base anchor and validates output. It rejects baked backgrounds, stripe corruption and edge-clipped sources. [Usage](SPRITE_PIPELINE.md). Does not call an AI image API and does not alter Factorio mod prototypes; CI pending.

> **Sprite pipeline final CI verification (2026-11-13):** [Actions #43387041605](https://github.com/zukera2-stack/Factorio/actions/runs/43387041605) passed **14 Python unit tests**, including negative corruption tests, deterministic image QA, Lua 5.2 syntax and offline Factorio prototype contract checks; [docs #43387041331](https://github.com/zukera2-stack/Factorio/actions/runs/43387041331) passed. [Preview artifact 14018364046](https://github.com/zukera2-stack/Factorio/actions/runs/43387041605/artifacts/14018364046). Synthetic preview only; real art and Factorio 2.1.20 data-stage/game testing still pending. Playable 0.1.10 source unchanged.

> **Sprite pipeline first CI pass:** [Actions #43386844327](https://github.com/zukera2-stack/Factorio/actions/runs/43386844327) generated pole/shadow/wire synthetic preview, passed 10 positive/negative image tests, Lua syntax and QA report; artifact 14018039095. Docs validation #43386901818 passed. An additional offline API contract guard now checks sprite paths, dimensions/hashes, schema and zero-copper source invariants; CI pending. **Offline checks are NOT Factorio 2.1.20 game verification.**

> **Sprite generation QA (2026-11-13):** [feature/sprite-pipeline-0111](https://github.com/zukera2-stack/Factorio/tree/feature/sprite-pipeline-0111) contains a deterministic Pillow pipeline for RGBA 35 kV pole/shadow/wire art, strict negative image tests, preview on three backgrounds, SHA-256 report and a review-only Factorio Lua prototype snippet. [Guide](SPRITE_PIPELINE.md) · [API research](research/sprite-pipeline-0.1.11.md). **Playable mod remains 0.1.10 unchanged**; no art loaded into Factorio. Official API inspected was 2.1.24, user game is 2.1.20; CI/static and actual game tests must not be conflated. Synthetic demo is NOT approved final art.

> **0.1.10 CI results:** [Build #43382092112](https://github.com/zukera2-stack/Factorio/actions/runs/43382092112) passed Lua syntax, pure Lua geometry assertions, ZIP structure and single-file upload for commit 60bfda99. Artifact 14016553350 contains only ElectrifiedMainline_0.1.10.zip. [Docs #43382163410](https://github.com/zukera2-stack/Factorio/actions/runs/43382163410) passed. See [build manifest](BUILD_0110.yaml). **No Factorio game test for 0.1.10 yet.**

> **NEW 0.1.10 visual topology branch (2026-11-13):** [feature/catenary-topology-0110](https://github.com/zukera2-stack/Factorio/tree/feature/catenary-topology-0110) is based on 0.1.9. User confirmed 0.1.9 supports place and visual wires draw; screenshot shows multiple diagonal links from the substation. The new version chooses at most two mutually nearest rail-aligned contact neighbours per support and ONE blue feeder per substation. It rebuilds old saved render graphs on version change and refreshes locally after rail edits. **No real MW transfer, exact curve spline, or rail-signal snapping; 0.1.10 gameplay not tested.** See [research](research/catenary-topology-0.1.10.md) and [test worksheet](POWER_TEST_0110.md). `main` 0.1.8 and prior 0.1.9 test branch are untouched.

> **Corrected ZIP (0.1.9):** Initial CI artifact had both 0.1.8 and 0.1.9 by wildcard. Fixed in 9b5a25ea, verified [Actions #43297148331](https://github.com/zukera2-stack/Factorio/actions/runs/43297148331): Lua/ZIP pass, upload confirms **exactly 1 file (ElectrifiedMainline_0.1.9.zip)**. Use this artifact, NOT earlier #43279773067. Docs also passed. See [BUILD_019.yaml](BUILD_019.yaml).

> **0.1.9 CI evidence:** Lua syntax, ZIP validation and artifact creation PASSED on source commit cf49a518 in [Actions #43279773067](https://github.com/zukera2-stack/Factorio/actions/runs/43279773067). YAML/Markdown validation PASSED on documentation commit 97f35b45 in [Actions #43279908413](https://github.com/zukera2-stack/Factorio/actions/runs/43279908413). Test archive is an artifact named ElectrifiedMainline-test-build containing ElectrifiedMainline_0.1.9.zip. See [build manifest](BUILD_019.yaml). **No game launch performed here**.

> NEW 0.1.9 isolated feature branch: feature/35kv-catenary-019. A source prototype adds zero-copper-wire 35 kV poles, ordinary-grid-side substations and purely VISUAL nonconducting spans. No real MW transfer, no rail-signal snap, no powered rails, no gameplay evidence yet. This branch is based on main 0.1.8, which is untouched. Read docs/research/35kv-catenary-0.1.9.md and docs/POWER_ARCHITECTURE.md. Source-only implementation is not a functional energy system.

# Current AI handoff: ElectrifiedMainline 0.1.8

**Current baseline branch:** `main`, ElectrifiedMainline **0.1.8**; [PR #6](https://github.com/zukera2-stack/Factorio/pull/6) merged on 2026-11-12 at [`973559aa`](https://github.com/zukera2-stack/Factorio/commit/973559aa4d0643b2a942edce413e9530494bc498). **Game-tested source:** `ac4624ef5873a1d3adf65194c289e09aee5224ae`, validated in `test/undo-stabilization-018`; **Factorio:** 2.1.20 build 87512. Both CI checks passed. Start new feature branches from `main`; the old test branch remains historical evidence.

**Current verified scope:** native green Upgrade Planner + Undo/Redo for 26 straight, 4 curved-A, 4 curved-B rails; unrelated chest and rail history entries remain separate; superforced Ctrl+Shift blueprint overlay + Undo/Redo for 22 mixed-geometry rails (14 straight, 4 curved-A, 4 curved-B). Factory upgrades were tested as unrelated history actions. See [gameplay test record](tests/undo-0.1.8-2026-11-12.md) and [build provenance](BUILD_018.yaml). Two distinct user logs; no observed mod Lua errors.

**Code audit:** `ElectrifiedMainline/scripts/control.lua` no longer uses fixed `undo_index` or scripted blueprint Undo joining. `blueprint_undo_join` storage is discarded, `pending_rail_replacements` is preserved. Native upgrade and Undo/Redo event observers are non-mutating.

**Do not overclaim:** A passed; B and C only partially passed; D unverified. No half-diagonal gameplay, special selection tool, interrupted robot jobs, complete signal/inventory or compatibility regression yet. Electric traction, batteries and regeneration remain unimplemented.

**Read order:** `AGENTS.md` -> this handoff -> `docs/PROJECT_STATE.yaml` -> `docs/RESEARCH_METHOD.md` -> live source. Historical 0.1.7 details follow and must not override this current 0.1.8 status. Historical 0.1.4 `main` context is archived at [docs/history/AI_CONTEXT-main-0.1.4.md](history/AI_CONTEXT-main-0.1.4.md) and [docs/history/PROJECT_STATE-main-0.1.4.yaml](history/PROJECT_STATE-main-0.1.4.yaml); [exact-version Factorio 2.1.20 API notes](FACTORIO_2_1_RAIL_API_NOTES.md) are preserved as research, not as current gameplay status.

## Historical 0.1.7 handoff (preserved for provenance)

# Electrified Mainline — current AI handoff

> Updated 2026-11-12 after the user confirmed the 0.1.7 native rail replacement/Undo/Redo test works. The confirmed scope remains the tested straight-ground-rail path. This is the compact current handoff; older failures and 0.1.6 history are below, not current capability statements.
> Read in order: `AGENTS.md` -> this file -> `docs/PROJECT_STATE.yaml` -> `docs/RESEARCH_METHOD.md` -> `CONTRIBUTING.md` -> relevant live source files. Before any non-trivial mechanic or workaround, copy `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` into a new `docs/research/` record and complete the research sections before coding. Full older notebook: `PROJECT_CONTEXT.md` (historical only).

## 1. Current repository and environment

- Repository: https://github.com/zukera2-stack/Factorio
- Stable branch: `main`; **current validated experiment on** `diagnostic/blueprint-rail-undo`. Do not assume `main` contains 0.1.7.
- Mod directory/root: `ElectrifiedMainline/`; `info.json` version **0.1.7**, Factorio metadata `2.1`, Base dependency `>= 2.1.0`.
- User test environment: Factorio **2.1.20**, build 87512 (installation path labelled 2.1.20b), Bob's Assembly **3.0.2** and a larger Bob's/Space Age test pack.
- GitHub Actions: `.github/workflows/build-mod.yml`, runs on relevant pushes to `main` or the diagnostic branch. A packaged ZIP is **not** game-test evidence.

## 2. Accepted product decisions

These are user-approved requirements, not suggestions:

| Topic | Decision |
|---|---|
| Rail modernization | Replace vanilla rails with high-speed rail (ВСМ), preserving network topology |
| Power | Hybrid: overhead/contact supply plus onboard storage |
| Rolling stock | Both vanilla and custom wagons must be supported |
| Regeneration priority | Return energy to the shared grid first; store only the surplus onboard |
| Grid concept | ВСМ is also an independent high-voltage-style energy corridor |
| Substations | Connect ordinary Factorio electric network and ВСМ network bidirectionally, with a power limit |
| Remote outposts | ВСМ power corridor should be able to feed a remote outpost through a substation |
| Voltage | Factorio does not simulate physical kV levels; use MW, buffers, transfer limits and gameplay losses |
| Reference mod | Electrified Railways is ideas-only. Do not copy its code, fragments, scripts or prototypes. |

### Rolling-stock interoperability matrix

- Vanilla locomotive on vanilla rails: yes.
- Vanilla locomotive on ВСМ rails: yes, behaves as an ordinary vanilla locomotive.
- Electrified Mainline locomotive on ВСМ rails: overhead supply plus onboard storage, once implemented.
- Electrified Mainline locomotive on vanilla rails: onboard storage only, once implemented.
- Vanilla wagons and custom wagons may be mixed in consists.
- Third-party rolling stock must not crash our logic; unknown entities are not ours to control.


## 3. Current source layout

```text
ElectrifiedMainline/
├── info.json
├── data.lua                    # Factorio entry point -> require("prototypes.bootstrap")
├── data-updates.lua            # Factorio entry point
├── data-final-fixes.lua        # Factorio entry point
├── control.lua                 # Factorio entry point -> require("scripts.control")
├── prototypes/
│   ├── bootstrap.lua           # Current complete prototype implementation
│   └── README.md               # Safe future extraction plan
├── scripts/
│   ├── control.lua             # Current complete runtime implementation
│   └── README.md               # Future runtime module boundaries
├── compatibility/
│   └── README.md               # Adapter rules; no adapters implemented yet
└── locale/
    ├── en/en.cfg
    └── ru/ru.cfg
```

The current monolithic prototype/runtime files were moved, not functionally decomposed. This is deliberate: first establish a stable, navigable structure without changing gameplay semantics. Split them incrementally only when each module boundary is understood.

Factorio root entry points must remain at the mod root. Do not move `info.json`, `data.lua`, `data-updates.lua`, `data-final-fixes.lua` or `control.lua` out of it.


## 4. Current implementation and verified state

### Verified in-game (scoped claims)

- **0.1.7 native green Upgrade Planner on straight ground vanilla rails**: 20 `straight-rail` entities were ordered to upgrade to `em-high-speed-straight-rail` (`on_marked_for_upgrade tick=14284`); robots mined vanilla and built custom rails.
- **Ctrl+Z** (`on_undo_applied tick=14591 action_count=20`): 20 `upgraded-entity` actions with `original_name=straight-rail`; robots removed custom rails and rebuilt vanilla.
- **Ctrl+Y** (`on_redo_applied tick=14940 action_count=20`): 20 native upgrade actions; robots mined vanilla and rebuilt custom rails.
- This session loaded the existing save, logged no observed ElectrifiedMainline runtime errors, and ended normally.
- Prior tests verified the unified rail planner can place custom rails through robots, and rail identity tracking detects selected vanilla and custom rail geometries.

### Implemented in 0.1.7 source

- Four named custom **ground** rail geometries; unified custom `rail-planner` item `em-high-speed-rail`, placement costs 1/3/3/2 by geometry.
- `data-final-fixes.lua`: four geometry-specific `fast_replaceable_group` values (`em-native-<geometry>`), vanilla-to-custom `next_upgrade` mappings, mining/visibility/collision checks, and a guard against overwriting an existing foreign upgrade chain.
- `scripts/control.lua`: `on_marked_for_upgrade` **observes** native upgrades; it must **not cancel** native orders.
- The **separate** `em-rail-replacement-planner` selection tool still uses the old staged mining + custom ghost fallback. Scripted Ctrl+Shift blueprint `undo_index=1` ghost joining also remains in source.
- Rail diagnostics and runtime train/rail tracking, a cloned locomotive/pole/wagons, recipes and technology prototypes.

### Not verified or not implemented

- Native upgrade + Undo/Redo for `curved-rail-a`, `curved-rail-b`, `half-diagonal-rail`. Data-stage eligibility **passed**, but these were not tested by robots in the 0.1.7 supplied log.
- Superforced blueprint `Ctrl+Shift` with native Undo/Redo, separately from the **green Upgrade Planner**.
- Selection-tool fallback correctness, native transitions with trains occupying tracks, signalling/route integrity, inventory refunds, multiplayer or broad compatibility.
- **No actual energy model yet**: overhead traction, real battery charging/discharging, high-speed grid, bidirectional substations, regeneration and train-mass accounting are still planned. Locomotive uses a placeholder `void` energy source.
- Diagnostics currently poll rails each tick; optimize after verification.

## 5. Resolved bug: why 0.1.6 Undo failed and 0.1.7 works

**Old mistaken conclusion:** after the 0.1.3 failed green-planner test we documented native rail robot upgrades as universally unsupported. That conclusion is **false for the straight ground rail test** and must not be repeated.

Research sequence:
1. Compare **Bob's assembler** native upgrades (`fast_replaceable_group`, `next_upgrade`, common collision geometry) with our source. Bob's public repository revision inspected is different from the installed Bob's Assembly 3.0.2: cite the difference.
2. Find a **same-type rail precedent** (Minimal Electric Rails): vanilla and custom ground rails use paired geometry-specific `fast_replaceable_group` and `next_upgrade`.
3. Check official Factorio `EntityPrototype` and `UpgradeItemPrototype` requirements.
4. Set matching prototype properties and stop canceling native `on_marked_for_upgrade`; test real gameplay.

**0.1.6 historical experiment**: delayed straight-rail ghost recreation with `player`/`undo_index=1` allowed a superforced blueprint Undo to remove custom rails but **did not restore** the vanilla rail originals. This legacy scripted path remains experimental.

**0.1.7 outcome**: native green Upgrade Planner made a reversible `upgraded-entity` transaction for 20 straight rails. No custom Undo/Redo implementation needed in that path. We changed several conditions together; the log does not prove which one alone was necessary.

Full process and source references: [`RESEARCH_METHOD.md`](RESEARCH_METHOD.md) and repository [`CONTRIBUTING.md`](../CONTRIBUTING.md). Use the [research worksheet](PROTOTYPE_RESEARCH_TEMPLATE.md) for each non-trivial future mechanic; the [completed 0.1.7 rail-upgrade record](research/rail-native-upgrade-0.1.7.md) shows the required evidence level. This is a mandatory project-wide method, not merely a lesson from the rail bug. Never replace API research with guessed flags or write scripted Undo before checking engine-native ownership.

## 6. Immediate next tests and work

1. Repeat **native** green Upgrade Planner -> robot upgrade -> Ctrl+Z -> Ctrl+Y for curved-A, curved-B and half-diagonal ground rails. Verify direction/connection, quality, and item counts.
2. Test `Ctrl+Shift` blueprint superforce **separately**; do not claim the native test covers the scripted fallback.
3. Evaluate whether the old selection-tool/staged workflow is still needed, and avoid breaking its saves or queued bot jobs before removing it.
4. Check signals, stations, live trains, blocked/partial bot tasks, and cancellation.
5. Trim diagnostic polling and excess logging only after focused regressions.
6. Research native/third-party analogue for overhead power, battery and network transfer *before* new architecture or Lua code.

## 7. Project invariants and evidence

- Preserve native train/rail/signals/stations and vanilla rolling-stock interoperability.
- Core dependency stays Base unless a verified technical requirement changes it; optional mod code goes under `compatibility/` with guards.
- Do not copy code from Electrified Railways, Bob's, Minimal Electric Rails or any reference mod. Learn the prototype contract and implement independently.
- Evidence labels: **implemented**, **API-confirmed**, **game-tested**, **inferred**, **unverified**, **planned**.
- Source is authoritative for what exists; `docs/PROJECT_STATE.yaml` is authoritative for statuses; user logs are proof of specific tested paths. A ZIP CI pass is never proof of gameplay.
- Material code changes must update this file and `docs/PROJECT_STATE.yaml` in the same coherent change set.

## 8. Handoff protocol

Read `AGENTS.md` -> this file -> `docs/PROJECT_STATE.yaml` -> `docs/RESEARCH_METHOD.md` -> `CONTRIBUTING.md` -> live source. For non-trivial mechanics, complete `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` in a new `docs/research/` record before coding. Check the active branch head and mod version. Research existing functionality **before proposing new scripts**. Test only changed behavior, report actual observations and open questions, then synchronize docs and changelog.


## 9. Mandatory research-first contribution method

Every future mechanic, compatibility change, or bug workaround must follow `AGENTS.md`, `CONTRIBUTING.md`, and `RESEARCH_METHOD.md`: define the exact player-visible test; inspect Base/native behavior; find a working same-type mod precedent; record its source ref and version; compare relevant prototype properties and runtime ownership with the official target-version API and our source; state a falsifiable hypothesis; implement the smallest independent change; test the exact path in Factorio; and synchronize project status/evidence. If no suitable analogue exists, document the search and uncertainty rather than inventing flags. Reference code is for study, not copying.

The user's confirmation that "everything works" applies to the 0.1.7 test path already recorded above (20 straight ground rails via the native green Upgrade Planner, robot replacement, Ctrl+Z restore, Ctrl+Y redo). It does not silently promote untested geometries or other replacement tools to game-tested.
