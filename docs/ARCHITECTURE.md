# Architecture

## Runtime constraints

Factorio discovers the following files by their exact names at the mod root:

- `info.json`
- `data.lua`
- `data-updates.lua`
- `data-final-fixes.lua`
- `control.lua`

The root Lua files are thin entry points where practical. Implementation is kept in named modules and loaded with `require`.

## Current layout

- `prototypes/bootstrap.lua` — current complete prototype definitions, loaded by root `data.lua`.
- `scripts/control.lua` — current runtime event handlers, loaded by root `control.lua`.
- `compatibility/` — isolated optional-mod adapters; currently documentation only.
- `locale/` — player-facing English and Russian strings.
- `docs/AI_CONTEXT.md` — cross-chat working handoff.
- `docs/PROJECT_STATE.yaml` — machine-readable accepted decisions and implementation status.
- `AGENTS.md` — instructions for AI contributors.

The prototype and runtime implementations are intentionally still single files. They were moved without semantic refactoring to establish stable paths first. Split them incrementally only after mapping dependencies and preserving load order.

## Intended module boundaries

### Prototype layer
- items
- recipes
- technologies
- rails
- rolling stock
- power infrastructure

### Runtime layer
- persistent storage and migrations
- rail identity/electrification
- train lifecycle and composition
- power transfer
- battery accounting and regeneration

Do not create empty placeholder modules. Extract a module when it owns real code and can be tested independently.

## Compatibility architecture

The core mod should depend only on Base unless a required feature proves otherwise. Optional integrations belong in `compatibility/<mod-name>/` and must guard every optional prototype/API reference. Unknown third-party entities must be tolerated.

## Native rail replacement and experimental fallback

- `data-final-fixes.lua` assigns **one `fast_replaceable_group` per ground rail geometry** and connects each vanilla rail's `next_upgrade` to its matching custom rail, subject to eligibility and existing-chain checks.
- The native green Upgrade Planner then owns robot mining/building, and Factorio's native Undo/Redo. `on_marked_for_upgrade` observes native orders and **must not** cancel them.
- **0.1.8 game-tested:** native green Upgrade Planner, construction-robot replacement and Undo/Redo for 26 straight + 4 curved-A + 4 curved-B rails. The half-diagonal geometry remains unverified in gameplay.
- **0.1.8 game-tested:** Ctrl+Shift superforced blueprint overlay with 14 straight + 4 curved-A + 4 curved-B rails; native Undo and Redo restored and reapplied them. See [evidence record](tests/undo-0.1.8-2026-11-12.md).
- The former experimental scripted Ctrl+Shift ghost Undo joining and fixed `undo_index=1` were **removed** in 0.1.8. Undo/Redo event handlers are observational only.
- The separate `em-rail-replacement-planner` **still** uses an independent staged deconstruction/ghost queue. It has not passed dedicated 0.1.8 gameplay regression; its Undo behavior is not promised.
- Before modifying a mechanic, follow the [working-analogue research protocol](RESEARCH_METHOD.md) and complete a [prototype research record](PROTOTYPE_RESEARCH_TEMPLATE.md). Compare prototype type, group, upgrade chain, collision, mining/placement, runtime ownership, and target-version API with a proven implementation; save the record under `docs/research/`.

## Change and verification policy

- Keep prototype names and runtime behavior stable during structural-only changes.
- Keep Factorio entry points at the mod root.
- Test data-stage loading and runtime separately.
- A successful ZIP workflow confirms packaging, not game behavior.
- Update `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` after material changes.
