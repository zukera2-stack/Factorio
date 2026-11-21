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

**Do not confuse a checked-out `main` with every development branch.** `main` is the accepted 0.1.56 visual baseline. The user-installed and updater-approved 0.1.60, Updater 1.1 source, and ongoing 0.1.61 research live on separate refs. Read [the current work map](docs/CURRENT_WORK.md), verify live SHA and then fetch handoff/source files on the **specific target branch**. The map is date-stamped and does not override actual code or Git history.

Project skills (portable SKILL.md; Codex discovers `.agents/skills`, other assistants can read explicitly):
- [`factorio-handoff`](.agents/skills/factorio-handoff/SKILL.md) — start a new chat, recover live branches and task state.
- [`factorio-native-research`](.agents/skills/factorio-native-research/SKILL.md) — Factorio API/prototype, EEI priority and engine experiments.
- [`factorio-updater-release`](.agents/skills/factorio-updater-release/SKILL.md) — QA, owner-approved test promotion, existing Windows patcher.

A future new chat must not treat `PROJECT_CONTEXT.md` (2026-11-09 notebook), historical README paragraphs or scoped `main` status as the latest feature brief.

## Source of truth

- Current source code is authoritative for implementation.
- `docs/PROJECT_STATE.yaml` is authoritative for accepted decisions and status **on the selected branch**; the `main` copy must keep `project.mod_version: 0.1.56` until an approved main release.
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
Main 0.1.56 is the only **merged owner-accepted baseline**. Other active tested and research branches exist: see [current cross-branch handoff](docs/CURRENT_WORK.md), then live branch HEADs. Preserve original visual algorithm unless a reproducible defect is observed. New standalone main-line features usually branch from `main`; continuation of the existing 060 electric bridge must retain the exact vetted 060 base or it loses the implementation. **Never merge unapproved experiment to main or move `test/updater-approved` without explicit owner permission.** Use the owner's already-installed Updater 1.1 for future approved gameplay test releases instead of repeated manual ZIP installation.
