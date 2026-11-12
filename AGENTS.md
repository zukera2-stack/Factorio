# Instructions for AI contributors

## First read

1. `AGENTS.md` — these repository-wide contributor rules.
2. `docs/AI_CONTEXT.md` — concise authoritative handoff for continuing work.
3. `docs/PROJECT_STATE.yaml` — machine-readable project state and decisions.
4. `docs/RESEARCH_METHOD.md` — mandatory research-first engineering workflow.
5. `CONTRIBUTING.md` — practical change/review checklist.
6. `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` — copy and complete it before non-trivial mechanic, compatibility, or workaround work.
7. The exact source files relevant to the task.
8. `PROJECT_CONTEXT.md` only when historical detail or longer technical rationale is needed.

## Source of truth

- Current source code is authoritative for implementation.
- `docs/PROJECT_STATE.yaml` is authoritative for accepted decisions and current status labels.
- `docs/AI_CONTEXT.md` is the handoff index and must be updated after material work.
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

- Target: Factorio 2.1.20b, with `factorio_version = "2.1"`.
- Keep the base dependency minimal unless a required API/prototype proves otherwise.
- Optional mod integrations belong in `compatibility/` and must never become hard dependencies by accident.
- Root files `data.lua`, `data-updates.lua`, `data-final-fixes.lua`, `control.lua`, and `info.json` are Factorio-discovered entry points/metadata and must remain in the mod root.


## Mandatory contribution workflow

For the full procedure and evidence labels, follow [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/RESEARCH_METHOD.md](docs/RESEARCH_METHOD.md). The short rule is: **find a working analogue, inspect its source, verify the target-version API, compare, make the smallest isolated change, test the exact gameplay path, and record the evidence.** A failed experiment is a reason to investigate—not permission to guess another flag.
