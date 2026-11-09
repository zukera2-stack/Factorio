# Instructions for AI contributors

## First read

1. `docs/AI_CONTEXT.md` — concise authoritative handoff for continuing work in any chat.
2. `docs/PROJECT_STATE.yaml` — machine-readable project state and decisions.
3. The exact source files relevant to the task.
4. `PROJECT_CONTEXT.md` only when historical detail or a longer technical rationale is needed.

## Source of truth

- Current source code is authoritative for implementation.
- `docs/PROJECT_STATE.yaml` is authoritative for accepted decisions and current status labels.
- `docs/AI_CONTEXT.md` is the handoff index and must be updated after material work.
- Historical notes and old logs are evidence, not proof that current code still behaves the same.
- If documents disagree, inspect code and record the discrepancy; do not silently choose one.

## Change discipline

- Do not implement speculative mechanics as if they were verified.
- Preserve existing gameplay behavior during structural refactors.
- Make small, coherent commits with descriptive messages.
- After moving files, verify all Factorio entry points remain at the mod root.
- After changing Lua, validate syntax and run the GitHub Actions packaging workflow; a successful ZIP build is not an in-game test.
- Never claim an in-game result unless the user has tested it or a reproducible test result is available.
- Update `docs/PROJECT_STATE.yaml` and `docs/AI_CONTEXT.md` whenever decisions, code structure, test status or next actions change.
- Do not overwrite user changes. Fetch current file content and SHA before updating an existing file.

## Factorio constraints

- Target: Factorio 2.1.20b, with `factorio_version = "2.1"`.
- Keep the base dependency minimal unless a required API/prototype proves otherwise.
- Optional mod integrations belong in `compatibility/` and must never become hard dependencies by accident.
- Root files `data.lua`, `data-updates.lua`, `data-final-fixes.lua`, `control.lua`, and `info.json` are Factorio-discovered entry points/metadata and must remain in the mod root.
