# Factorio 2.1.20 API notes — rail replacement, ghosts and undo

> Scope: API behavior checked against the exact Factorio 2.1.20 documentation, not the moving `latest` docs. Target game for this mod is 2.1.20b.
> Status: API-confirmed documentation findings; the proposed replacement/undo behavior is not yet proven in-game.

## 1. Core distinction: fast replace vs forced ghost placement

These are separate engine paths and must not be treated as equivalent.

- `LuaSurface.can_fast_replace{ name, position, direction, force }` checks whether an existing entity can be fast-replaced by the specified entity.
- `LuaSurface.create_entity{ ..., fast_replace = true }` asks the engine to simulate the building operation as a fast replace.
- Passing `player` to `LuaSurface.create_entity` sets the last user; together with `fast_replace = true`, it simulates fast replacement using that player and adds the action to that player's undo queue.
- `undo_index` controls the undo item association: `0` creates a new undo item; otherwise the action can be associated with an existing undo item. Omission lets the engine choose an appropriate item.
- `LuaSurface.can_place_entity` has a `forced` option. Forced placement ignores entities that can be marked for deconstruction, but this option is only applicable to `manual_ghost`, `script_ghost` and `blueprint_ghost` build-check types.

**Interpretation:** forced blueprint ghost placement can coexist with entities that are eligible for deconstruction; it does not itself perform fast replacement. This matches the observed difference between direct rail-planner placement and a Ctrl+Shift blueprint placement.

References:
- [LuaSurface 2.1.20](https://lua-api.factorio.com/2.1.20/classes/LuaSurface.html) — `can_fast_replace`, `can_place_entity`, `create_entity`, `fast_replace`, `undo_index`, `player`, `forced`.
- [LuaEntityPrototype 2.1.20](https://lua-api.factorio.com/2.1.20/classes/LuaEntityPrototype.html) — `fast_replaceable_group`.

## 2. Prototype properties: what they do and do not prove

- `fast_replaceable_group` declares entities that may be fast-replaced with one another when the relevant engine placement path is used.
- Matching collision boxes/masks and a shared fast-replaceable group are eligibility/configuration evidence, not proof that a particular planner UI or robot workflow will offer the replacement.
- `additional_pastable_entities` concerns copying/pasting entity settings. It is not a rail replacement or blueprint-overlap mechanism.
- `placeable_by` has not been established as the mechanism that makes forced blueprint ghosts replace an existing rail. Do not change it speculatively.

## 3. Runtime events relevant to replacement lifecycle

| Event | Documented purpose / useful data | Use in this project |
|---|---|---|
| `on_pre_build` | Fires before a player builds with an item; includes player, position, build mode, direction and blueprint flip fields | Detect/characterize player build attempts; does not by itself provide the full blueprint entity list |
| `on_marked_for_deconstruction` | Entity is marked for deconstruction; includes entity and player index | Capture the old vanilla rail and associate its removal with a replacement request |
| `on_pre_ghost_deconstructed` | Fires before a ghost is destroyed due to deconstruction marking; includes ghost and player index | Detect cancellation/removal of a planned replacement ghost |
| `on_cancelled_deconstruction` | Deconstruction mark is cancelled on an entity | Handle cancellation of the old rail's demolition order; distinct from pre-ghost-deconstruction |
| `on_robot_mined_entity` | Robot mines an entity | Detect completion of the old rail demolition |
| `on_robot_built_entity` | Robot builds an entity | Detect completion of custom ghost construction |
| `on_undo_applied` | Player applies undo; event contains an `actions` array | Inspect the engine's actual inverse actions and target data |
| `on_redo_applied` | Player applies redo; event contains an `actions` array | Inspect the engine's actual replay actions |

Additional notes:

- `on_blueprint_settings_pasted` is not a blueprint placement event. It concerns settings pasted onto an existing entity or ghost.
- `on_built_entity` is a player-build event; do not assume it reports every blueprint ghost lifecycle step without observing it in-game.
- `LuaEntity.order_deconstruction(force, player, undo_index)` accepts player/undo association arguments. `LuaEntity.revive()` does not accept player or undo-index arguments.
- Event order and exact action payloads for the Ctrl+Shift → Ctrl+Z → Ctrl+Y sequence still need a real game log.

References:
- [Events 2.1.20](https://lua-api.factorio.com/2.1.20/events.html) — `on_pre_build`, `on_marked_for_deconstruction`, `on_pre_ghost_deconstructed`, `on_cancelled_deconstruction`, `on_undo_applied`, `on_redo_applied`, robot build/mined events.
- [LuaEntity 2.1.20](https://lua-api.factorio.com/2.1.20/classes/LuaEntity.html) — `order_deconstruction`, `cancel_deconstruction`, `revive`.

## 4. Undo/redo API

Factorio 2.1.20 exposes `LuaPlayer.undo_redo_stack` as `LuaUndoRedoStack`, including inspection of undo/redo items and action collections, as well as APIs for removing items/actions and reading/writing tags.

Relevant action kinds include:

- `built-entity`
- `removed-entity`
- `upgraded-entity`

For entity actions, `target` is blueprint-entity-shaped data. `removed-entity` may include `surface_index`; the field can be absent for objects the engine cannot restore. `upgraded-entity` may include `original_name` and `original_quality_name`.

**Design constraint:** do not manipulate/remove undo items or actions to force a desired result until the actual event payload and grouping have been captured. First log `on_undo_applied` and `on_redo_applied` for the user's exact test.

References:
- [LuaUndoRedoStack 2.1.20](https://lua-api.factorio.com/2.1.20/classes/LuaUndoRedoStack.html).
- [UndoRedoAction 2.1.20](https://lua-api.factorio.com/2.1.20/types/UndoRedoAction.html).

## 5. Implications for Electrified Mainline

Current runtime replacement is a one-way vanilla-to-custom workflow: queue the vanilla rail for deconstruction, wait for mining, then create a custom rail ghost. It does not yet model the reverse custom-to-vanilla operation, and its replacement ghost creation currently does not associate the operation with the initiating player/undo item.

The next investigation is event-driven, not another speculative prototype-flag change:

1. Capture `on_marked_for_deconstruction` for source vanilla rails.
2. Capture the build/ghost lifecycle and correlate source rail positions with custom blueprint ghosts.
3. Capture robot mining/building and ghost deconstruction/cancellation.
4. Capture the complete action arrays from `on_undo_applied` and `on_redo_applied`.
5. Only after examining the log decide whether to use engine fast-replace with player/undo association, or maintain a custom reversible workflow.

A promising API capability is `LuaSurface.create_entity{ fast_replace = true, player = ..., undo_index = ... }`. It must be tested for this rail case before adoption: direct entity creation may not preserve the desired construction-robot ghost workflow.

## 6. Observed user behavior (separate from API-confirmed facts)

The user has reported these Factorio 2.1.20b observations:

- Direct placement with the custom rail planner over vanilla rails replaces them; undoing/cancelling the route can restore vanilla rail ghosts and construction.
- A custom rail ghost placed over an existing vanilla rail reports a collision instead of replacing it.
- A blueprint on empty ground creates custom rail ghosts and construction robots build them.
- Ctrl+Shift blueprint placement over vanilla rails marks the vanilla rails for deconstruction; after robots remove them, custom rail ghosts appear and are built.
- The reverse/cancellation behavior for that blueprint path is not yet adequately characterized.

These are user-reported game observations, not guarantees inferred from API documentation.

## 7. Evidence labels

- **API-confirmed** — present in the exact Factorio 2.1.20 API docs.
- **User-observed** — reported from a Factorio 2.1.20b test.
- **Implemented** — present in current mod source.
- **Unverified** — plausible or implemented but not yet tested in-game.
