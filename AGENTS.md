> **ТЕКУЩИЙ РАБОЧИЙ ПОРЯДОК (25.11.2026): Direct Patch — основной способ выдачи локальных обновлений.** [Единый стандарт](docs/development/DIRECT_PATCH_WORKFLOW.md) · [реестр](patches/registry.json) · [проверяющий инструмент](scripts/direct_patch.py). Прямой ZIP из чата не требует полной GitHub CI-сборки. Полный ZIP для интеграции и будущего официального дистрибутива воспроизводится и проверяется в GitHub Actions. Владелец предоставил реально запускавшуюся 0.1.84; 0.1.85 — полный CI/native кандидат, **Windows-приёмка 0.1.85 не подтверждена**. Версия в main 0.1.62; не сливать без разрешения. Пожалуйста, считайте старые правила CI-only и Updater ниже историческими.

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
- After changing Lua, validate syntax and the **exact Direct Patch overlay** locally before delivery; GitHub full packaging is mandatory only for an integration checkpoint. A successful ZIP build is not an in-game test.
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

## Owner distribution rule — UPDATED 2026-11-25

**Direct Patch for local work:** deliver a small, exact, SHA256-verified ZIP directly to the owner; only changed runtime files, paths relative to the extracted mod root, external manifest/QA in GPT Library. Do not await CI for each local iteration. Follow [Direct Patch](docs/development/DIRECT_PATCH_WORKFLOW.md) and [registry](patches/registry.json). Local visual acceptance belongs to the owner; keep backup outside mods.

**Complete integration ZIP:** must be reproducible from GitHub source and validated in GitHub Actions before reviewing a merge to main. This is a distinct workflow and does not authorize publishing or merging. Keep official build provenance/QA separately.

**Historical rule superseded:** on 2026-11-19 the owner required all ZIPs from GitHub Actions and no downloadable copies in GPT Library. On 2026-11-25 the owner *explicitly replaced this for local development* with Direct Patch and approved Library working snapshots/patches. Windows Updater remains retired.

## Current baseline and branches
Main 0.1.62 is the **owner-accepted historical source baseline**, including the EM071 cosmetic rail fork. Owner-running 0.1.84 and the native+CI-tested 0.1.85 candidate live on separate branches, see registry and integration report. The mod is not finished or released. Other active tested and research branches exist: see [current cross-branch handoff](docs/CURRENT_WORK.md), then live branch HEADs. Preserve original visual algorithm unless a reproducible defect is observed. New standalone main-line features usually branch from `main`; continuation of the existing 060 electric bridge must retain the exact vetted 060 base or it loses the implementation. **Never merge unapproved experiment to main or move `test/updater-approved` without explicit owner permission.** Do not invoke the retired Windows Updater or invent a replacement patcher. Future installation approaches require explicit owner authorization.

## Owner-approved graphics patch delivery (2026-11-25)
For graphical iterations follow [Direct Patch](docs/development/DIRECT_PATCH_WORKFLOW.md). Local render → exact scoped ZIP + external hash manifest → native/full-mod QA → direct owner Windows acceptance. The [historical graphics process](docs/development/GRAPHICS_PATCH_WORKFLOW.md) may guide visuals, but its CI-only delivery requirement is superseded. No installer, main merge or release.
