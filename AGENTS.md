**2026-11-28 — EM136 final distribution package:** Owner approved Zukera as author and All Rights Reserved as license; explicitly requested disclosure of AI assistance (ChatGPT). Included LICENSE in repository and game ZIP, AI disclosure in info.json, EN/RU portal descriptions and player guide. 0.2.0 public beta candidate: 503 files, 428 PNG. ZIP SHA256 90d245817e7045621aec5439d385011836fc2c3f7d6c314878a3bc042e810c86; payload tree SHA256 5ee2d2908833962484c30752cf260b1cd590ed2639ef94093f9dbdb850096f3a. Final library directory /Factorio/Release/Final/. Prior candidate checksums are historical. PR #95 remains draft, no merge, tag, publication or game installation. No new gameplay tests or CI. Windows acceptance, current full regression, multiplayer and UPS not established.

**2026-11-28 — EM136:** 0.2.0 public beta candidate, derived from exact 0.1.134 (EM135 PR #94), metadata/locale description/changelog/thumbnail only. 502 game files, 428 PNG (427 existing graphics unchanged + cover). Canonical ZIP SHA256 7a31bf8e7f852f67cacc28abadec5d9e386df41a15eb81e58d80587d84020d2a, payload tree 74be0859a4f03126d7b997b23369487a85abeb80f78c37555412c4b1f03d8452. Library /Factorio/Release/ElectrifiedMainline_0.2.0.zip and EM136_release_materials.zip. [Publication checklist](docs/release/0.2.0/RELEASE_CHECKLIST.md) and [player guide](docs/release/0.2.0/PLAYER_GUIDE.md). Author Bionic Assistant retained pending owner decision; license not selected. No publication, tag, merge, CI or game tests authorized. Windows visual acceptance, full current regression, multiplayer and UPS remain unconfirmed. Main 0.1.103; last inspected owner installation 0.1.133; do not install automatically. Historical notes below are not current status.

**2026-11-27 — EM135 integration candidate:** branch integration/em135-0.1.134-release-candidate contains exact 0.1.134 runtime: 500 files, 427 PNG; canonical payload tree SHA256 b2038ea54154c929086d39ffe3997bad1b88c01df916a4455c9b5f120bf51f42. Owner installed 0.1.133 verified byte-for-byte before EM134 delta applied in a temporary copy. Main remains 0.1.103. Standard onboard storage, battery wagons, regen and grid return approved in EM130; stationary charging remains configurable. EM133 status correction owner accepted; EM134 removes development commands and periodic diagnostics, changes light gating and orientation, fans unchanged. No new gameplay tests or CI run authorized in this task. Historical test results do not prove EM134. Exact runtime is now tracked including PNG; do not stage historical EM080/081/083 assets for this version. See docs/development/EM135_RELEASE_INTEGRATION.md. No merge, installation, release, tag or portal upload authorized.

**2026-11-26 — repository cleanup complete:** `main` is the sole active development branch (0.1.103); `archive/pre-main-0.1.103-20261126` is a retention-only branch at `25f91ad775007f80aca048a8c69eff90a3d9686e`, never merge it into main. All 135 original branch tips verified reachable after deleting their old names (93 also main ancestry, 42 archive-only); 605 reachable commits in archive. All 51 superseded PRs closed with original bodies preserved and archive notes; 0 open PRs, 2 branches verified. Historical branch references below may no longer resolve by name: use [archive inventory](https://github.com/zukera2-stack/Factorio/blob/25f91ad775007f80aca048a8c69eff90a3d9686e/docs/development/BRANCH_ARCHIVE_20261126.md) and exact commit SHA. Restore historical work only when needed; new tasks branch from live main. No runtime/artwork change, issue closure, release, tag or owner installation. The existing native 111/111 and CI 169/169 remain the validated baseline; Windows GUI, multiplayer and UPS remain unverified.

**2026-11-26 — CURRENT AUTHORITATIVE CHECKPOINT:** Owner explicitly approved merge of PR [#91](https://github.com/zukera2-stack/Factorio/pull/91). `main` is the unified **0.1.103 development baseline**, merge commit `4bdbacda206fca1d040a809ce276f5fce1dfab69`. All 130 commits preserved; post-merge game tree `8d64e44d74c37f5a202a01ef09fcda3cda3d01af` identical to tested integration head `ed8639230112668b3c8dd9a12e565988bfde3656`. Native 111/111 (106 explicit completion + 5 stand assertions), CI 169/169 payload including 99 PNG; latest pre-merge CI 45886890810 passed. Start new development from live main. Full package requires frozen EM080/081/083 staging; do not install the unstaged tree. For future intentional runtime changes, update the exact integration payload manifest together with the source and verify the full staged archive; never bypass parity. Last confirmed owner-running archive remains 0.1.84; Windows GUI/actual owner save, multiplayer and UPS unverified. No release, tag, Mod Portal upload, installation or branch deletion authorized by this merge. Historical experimental branches and evidence remain preserved pending separate retention audit. Older status statements below are historical, not current instructions.

> **Integration checkpoint 2026-11-26:** active branch integration/em094d4-main-candidate, exact D4 0.1.103 runtime. Read [integration audit](docs/development/EM094_INTEGRATION_AUDIT.md), [test plan](docs/development/EM094_INTEGRATION_TEST_PLAN.md), [Direct Patch standard](docs/development/DIRECT_PATCH_WORKFLOW.md), [Asset Workshop](docs/development/ASSET_WORKSHOP.md), and [3D pipeline](docs/3D_ASSET_PIPELINE.md). The raw repository must stage frozen graphics before packaging; integration manifest gates every file. No further speculative gameplay changes or optimization required before final acceptance. Main/owner files/branches unchanged. Full CI, exact final native regression and owner decision pending. All older branch/version references are historical unless explicitly confirmed live.

## Resource-budgeted parallel native QA (EM087N, 2026-11-26)

Use parallel independent Factorio headless processes for functional regression whenever measured RAM/CPU limits and fixture isolation permit. This is a development/QA workflow, not multithreaded Lua simulation or a claim of higher in-game UPS. Follow [the parallel QA standard](docs/development/PARALLEL_QA_STANDARD.md).

- Before launching, inspect effective cgroup RAM/CPU limits and current use; calibrate actual worker RSS, keep a 768 MiB reserve in the tested 4 GiB environment, and admit only the workers that fit. Never assume three workers fit every host or save.
- EM087N verified 3 small workers (700 MiB planning allowance per worker), 2 medium workers and 1 dedicated stress100 worker. Each uses isolated writable config, saves, mod-list, QA and logs; share immutable engine/mod inputs only.
- Run exact UPS/profiling and paired performance benchmarks alone, without other QA processes. Preserve deterministic checks, complete native assertions and failed logs. Memory guard is sampled and cannot guarantee OOM prevention.
- Reuse `tests/em087m-mixed-outposts/run_parallel.py` and its [runbook](tests/em087m-mixed-outposts/PARALLEL_QA.md); adapt additional fixtures explicitly, not by silently declaring unexecuted cases passed. Record limits, workers, wall time, peak RAM, OOM events, exact engine/mod SHA and per-case outcomes.
- Evidence: same 11 cases passed sequentially in 44.302 s and with 3 workers in 20.339 s (2.18x batch throughput, 124 matching fixture log lines); [EM087N report](docs/development/EM087N_PARALLEL_QA.md). Future agents must consider this proven workflow before defaulting to serial functional QA.

> **2026-11-25 integration proof**: Owner uploaded actual running `0.1.84` archive to Library `/Factorio/Working-Mod/ElectrifiedMainline_0.1.84_OWNER_RUNNING_20261125.7z` (SHA256 00029dbc64c59687ba85784c7b82c2e5819c6585c1c0a980788ad3b2512e889f). Rebuilt `0.1.85` ZIP and GitHub Actions `45664465532` successfully reproduced all **157 identical game files**. Read [the integration proof](docs/development/EM085_OWNER_ARCHIVE_INTEGRATION.md). The validated candidate is **not merged, not a release**; Windows EM085 owner acceptance still pending. Do not modify `main` without explicit owner permission.

> **EM085 Direct Patch**: owner requested obsolete factory pole `em-electric-pole` removed *completely*. Code and migrations recorded at [EM085](docs/development/EM085_REMOVE_ORDINARY_POLE.md). Item, recipe, entity and research unlock removed; JSON migration maps old item/entity to vanilla small-electric-pole. No changes to 25 kV catenary. Local native migration PASS; owner Windows acceptance pending. GitHub branch sources are not a complete mod without earlier binary sprite patches.

> **EM084 UI Direct Patch candidate:** See docs/development/EM084_MOTOR_WAGON_STATUS.md. Library ZIP version 0.1.83→0.1.84. Linux native probe PASS, owner Windows GUI acceptance pending. Does not alter train power or real alert status.

> **EM083 Direct Patch candidate (2026-11-25):** User rejected custom wrecks (keep vanilla), requested original EM079 raised collector. See [EM083 patch recovery](docs/development/EM083_PANTOGRAPH_RESTORE.md). Only eight raised panto PNGs + info.json in Library; source GitHub branch without binary patch alone is NOT a complete runnable EM083. Owner EM082 baseline remains confirmed; EM083 Windows acceptance pending.

> **Working Library snapshot:** restore `/Factorio/Working-Mod/ElectrifiedMainline_0.1.82_owner.zip` for local QA. Follow [Library workspace recovery](docs/development/GPT_LIBRARY_WORKSPACE.md) and live Direct Patch state. This is an owner-supplied working copy, not CI distribution.

> **LATEST OWNER DECISION (2026-11-25): Direct Patch replaces CI-only delivery for local development.** See [Direct Patch standard](docs/development/DIRECT_PATCH_WORKFLOW.md). Deliver scoped replacement ZIP directly for manual extraction into unpacked mod; no required CI wait or binary upload before each test. Historical CI-only rules below apply to optional official full install ZIPs, not Direct Patch. No updater, main merge or release. EM082 owner confirmed manual patch works.

> **OWNER REJECTED THE EXPERIMENTAL SINGLE-120MW SUBSTATION (2026-11-23).** Gameplay stations are **20MW each**; 2/3/6 ordinary parallel stations can provide 40/60/120MW aggregate if actual factory power and demand allow. Runtime `bridge058` and native EEI input/output are restored to 20MW on an isolated EM074-derived correction. Historical EM072/73/74 single-120MW runs remain archived only as **rejected research**, never current gameplay approval. Local real Factorio 2.1.24 native 2830-tick run of user full 0.1.73 derived with only the two 20MW Lua changes PASS (1/2/3/6 shared factory/contact networks, forward/reverse and overload). Exact corrected EM074 packaged mod and revised 200-wagon tests **NOT RUN**. [Decision](docs/decisions/EM075_REJECT_SINGLE_120MW_2026-11-23.md). No main change, release, merge or GitHub Actions.

> **2026-11-21:** Current source baseline is main 0.1.62 with EM071 accepted on screenshot and merged via PR #47. Windows Updater 1.1 is discontinued by owner and its executable source removed from the historical feature branch. Do not recreate a patcher; do not publish release. Older main=0.1.56 / active updater statements below are historical unless explicitly updated.

> **Owner directive 2026-11-21:** promote tested 0.1.62 EM070 code to `main` only as a development baseline (PR #46). The overall mod is unfinished; NO release/tag/Mod Portal/Updater promotion is authorized. The previous 0.1.56 main-only handoff and beta proposal text below are historical.

# Instructions for AI contributors

## First read

1. `AGENTS.md` — repository-wide contributor rules.
2. **`docs/CURRENT_WORK.md` — cross-branch first-read index (stable main, approved test, updater software, current experiment). Re-fetch live refs.**
3. `docs/AI_CONTEXT.md` — concise **branch-scoped** authoritative handoff for the checked-out branch.
4. `docs/PROJECT_STATE.yaml` — machine-readable **branch-scoped** state and decisions.
5. `docs/RESEARCH_METHOD.md` — mandatory research-first engineering workflow.
6. `CONTRIBUTING.md` — practical change/review checklist.
7. `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` — copy and complete it before non-trivial mechanic, compatibility, or workaround work.
8. The exact source files relevant to the task.
9. `PROJECT_CONTEXT.md` only when historical detail or longer technical rationale is needed.

## Cross-branch recovery and Agent Skills

**Do not confuse a checked-out `main` with every development branch.** `main` is the accepted 0.1.56 visual baseline. The former Updater 1.1 and old test/updater-approved 0.1.61 are preserved only as historical refs; main source is 0.1.62 after accepted EM071. Read [the current work map](docs/CURRENT_WORK.md), verify live SHA and then fetch handoff/source files on the **specific target branch**. The map is date-stamped and does not override actual code or Git history.

Project skills (portable SKILL.md; Codex discovers `.agents/skills`, other assistants can read explicitly):
- [`factorio-handoff`](.agents/skills/factorio-handoff/SKILL.md) — start a new chat, recover live branches and task state.
- [`factorio-native-research`](.agents/skills/factorio-native-research/SKILL.md) — Factorio API/prototype, EEI priority and engine experiments.
- The Windows Git Updater skill was **retired on 2026-11-21** together with executable patcher sources. Do not use or suggest this install workflow.

A future new chat must not treat `PROJECT_CONTEXT.md` (2026-11-09 notebook), historical README paragraphs or scoped `main` status as the latest feature brief.

## Source of truth

- Current source code is authoritative for implementation.
- `docs/PROJECT_STATE.yaml` is authoritative for accepted decisions and status **on the selected branch**; the `main` copy must reflect its current source version 0.1.62 without claiming it is a published release.
- `docs/AI_CONTEXT.md` is the **branch-scoped** handoff and must be updated after material work; `docs/CURRENT_WORK.md` is the repo-wide navigation index. Neither is a substitute for checking live refs and source.
- Historical notes and old logs are evidence, not proof that current code still behaves the same.
- If documents disagree, inspect code and record the discrepancy; do not silently choose one.

## Research-first discipline — mandatory, no blind guesswork

- This is a project-wide engineering requirement, not an optional suggestion: **do not invent prototype flags, event sequences, replacement rules, or workarounds from intuition when the engine/API or a working analogue can be inspected.**
- Before writing a mechanic or bug workaround, find a working native or third-party analogue. Search the Base game first, then maintained mods. Prefer the same Factorio prototype/entity type and the same user-visible operation. Inspect the actual source and prototype properties, not only a forum claim, description, or screenshot.
- Record the reference repo, file, ref/commit and version. A public branch may differ from the user's installed mod; label such mismatches.
- Compare our current prototype/logic to the analogue and official Factorio API: prototype type, flags, mining and placement, fast-replace groups, next-upgrade chain, geometry, collision, item mapping, event ownership, and version-specific behavior.
- Write down what is observed in the reference, what the API guarantees, what differs in our mod, and what remains a hypothesis. A similar-looking entity is not proof of equivalent behavior.
- For every non-trivial mechanic, compatibility change, or bug workaround, complete `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` as a new record under `docs/research/` **before implementation**. Fill source provenance, API version, comparison, and a falsifiable hypothesis; append test evidence afterward. Trivial spelling or documentation-only edits do not need a separate record.
- Prefer engine-native behavior to custom scripts where it already supports the feature. Do not copy third-party code; independently implement the documented mechanism.
- Form a minimal hypothesis, run a focused Factorio test, then record exactly which case passed. **A working straight rail does not prove curved rails or superforced blueprints.**
- Never claim a feature is engine-unsupported based solely on a failed experiment. Cross-check a same-type working example first.
- Full protocol: [`docs/RESEARCH_METHOD.md`](docs/RESEARCH_METHOD.md); copyable worksheet: [`docs/PROTOTYPE_RESEARCH_TEMPLATE.md`](docs/PROTOTYPE_RESEARCH_TEMPLATE.md); completed rail case: [`docs/research/rail-native-upgrade-0.1.7.md`](docs/research/rail-native-upgrade-0.1.7.md).

## Change discipline

- Do not implement speculative mechanics as if they were verified.
- Preserve existing gameplay behavior during structural refactors.
- Make small, coherent commits with descriptive messages.
- After moving files, verify all Factorio entry points remain at the mod root.
- After changing Lua, validate syntax and run the GitHub Actions packaging workflow; a successful ZIP build is not an in-game test.
- Never claim an in-game result unless the user has tested it or a reproducible test result is available.
- **Atomic project memory rule:** after every material code change, update both `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` in the same commit as the code. Do not leave code and project memory out of sync. This also applies to meaningful test-result changes, architecture decisions, dependency/compatibility changes and next-step changes. If a change genuinely does not affect project state, explain why no documentation update is needed in the final report.
- Do not overwrite user changes. Fetch current file content and SHA before updating an existing file.

## Factorio constraints

- Target: Factorio 2.1 (last known owner build 2.1.24 / 87808), with `factorio_version = "2.1"`.
- Keep the base dependency minimal unless a required API/prototype proves otherwise.
- Optional mod integrations belong in `compatibility/` and must never become hard dependencies by accident.
- Root files `data.lua`, `data-updates.lua`, `data-final-fixes.lua`, `control.lua`, and `info.json` are Factorio-discovered entry points/metadata and must remain in the mod root.


## Mandatory contribution workflow

For the full procedure and evidence labels, follow [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/RESEARCH_METHOD.md](docs/RESEARCH_METHOD.md). The short rule is: **find a working analogue, inspect its source, verify the target-version API, compare, make the smallest isolated change, test the exact gameplay path, and record the evidence.** A failed experiment is a reason to investigate—not permission to guess another flag.

## Packaging boundary (0.1.48)
Only game-discovered entrypoints and runtime code/assets belong in `ElectrifiedMainline/`. Put manual tests in `docs/tests/manual/`, QA reports in `docs/tests/evidence/`, developer notes in `docs/development/`, generated archives/atlases under ignored `build/`. Run `python scripts/package_mod.py`; packaging must reject unexpected files rather than silently include them. Preserve the historical 0.1.8 rollback and historical commits. See [repository layout](docs/REPOSITORY_LAYOUT.md). Do not rename or delete Lua modules or legacy helper prototypes without a separate dependency and migration audit.

## Owner distribution rule
Build every distributable install ZIP exclusively via the repository's GitHub Actions packaging workflow. Deliver the exact inner CI-built ZIP or link to the artifact. Never produce a locally repacked user ZIP. Local checks are not release builds. Preserve CI commit/run/artifact/hash provenance and keep QA artifacts separate.

**Owner clarification (2026-11-19):** deliver install ZIPs only by direct GitHub Actions artifact links. Do not download, copy, extract, or duplicate distributable ZIPs into the ChatGPT Library or project files for delivery. Library is for technical material, source models, sketches, experiment outputs, and evidence. Record CI validation, source commit and artifact ID; obtain inner archive SHA256 from CI logs if emitted, not by copying the release into Library.

## Current baseline and branches
Main 0.1.62 is the **owner-accepted source baseline**, including the EM071 cosmetic rail fork. The mod is not finished or released. Other active tested and research branches exist: see [current cross-branch handoff](docs/CURRENT_WORK.md), then live branch HEADs. Preserve original visual algorithm unless a reproducible defect is observed. New standalone main-line features usually branch from `main`; continuation of the existing 060 electric bridge must retain the exact vetted 060 base or it loses the implementation. **Never merge unapproved experiment to main or move `test/updater-approved` without explicit owner permission.** Do not invoke the retired Windows Updater or invent a replacement patcher. Future installation approaches require explicit owner authorization.

## Owner-approved graphics patch delivery (2026-11-25)
For graphical iterations follow [the graphics patch workflow](docs/development/GRAPHICS_PATCH_WORKFLOW.md): local render, scoped exact ZIP inputs, SHA256 validation, official CI full game ZIP only, independent game acceptance. Not an installer or revival of retired Updater. No main or release changes.
