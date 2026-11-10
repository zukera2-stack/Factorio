# Electrified Mainline — AI handoff

> Read this file first when continuing work in a new chat. This is a compact handoff; current source remains authoritative for implementation.
> Last updated: 2026-11-10 — recorded the latest user-reported rail planner/blueprint tests and simplified project workflow for a solo, small mod.

## 1. Repository and working rules

- Repository: https://github.com/zukera2-stack/Factorio
- Default branch: `main`
- Mod directory: `ElectrifiedMainline/`
- Production version on `main`: **0.1.4**. Do not confuse it with diagnostic version 0.1.5 on the isolated branch below.
- Target: Factorio 2.1.20b; `info.json` targets `factorio_version = "2.1"`.
- Before work, read `AGENTS.md`, this file, and `docs/PROJECT_STATE.yaml`; then inspect the relevant current source and latest branch/CI state.
- Source code is authoritative for implementation; `PROJECT_STATE.yaml` is authoritative for current status and accepted decisions.
- Do not infer game behavior from a successful package build. Label evidence as implemented, API-confirmed, user-observed/game-tested, planned, or unverified.
- User has authorized direct repository edits when explicitly requested. Do not make code or GitHub changes without a clear request.
- After material code, behavior, test, or decision changes, update both machine-readable/handoff documents in the same change set.
- Do not overwrite files without fetching their current contents and blob SHAs.
- Keep Factorio entrypoints and `info.json` in the mod root.

## 2. Project-management approach

This is currently a small mod maintained by one developer. Do not create or maintain a GitHub Projects board just for process overhead. Use:
- `docs/AI_CONTEXT.md`: concise handoff for the next assistant/chat — what matters, current technical situation, traps, and next action.
- `docs/PROJECT_STATE.yaml`: structured facts, decisions, implementation/test status, and next actions.
- Git history, PRs, and CI: actual change history and validation.

Keep these notes concise and current. Do not duplicate a full changelog or every historical experiment here; retain detailed API research in dedicated technical notes.

## 3. Accepted product decisions

- Replace vanilla ground rails with custom high-speed rails (ВСМ), preserving rail geometry/topology and normal train behavior.
- Hybrid traction concept: overhead/contact supply plus onboard storage.
- Regeneration priority: shared grid first, onboard storage for surplus.
- Substations should eventually connect ordinary Factorio power and the ВСМ power corridor bidirectionally with a transfer limit.
- Vanilla and custom wagons must be mixable. Unknown third-party rolling stock must not crash or be controlled by our logic.
- Vanilla locomotive on custom rails remains a vanilla locomotive.
- Electrified Mainline locomotive on custom rails is intended to use overhead supply plus storage; on vanilla rails, storage only.
- Factorio does not simulate physical kV levels; model power with MW, buffers, transfer limits, and losses.
- `Electrified Railways` is ideas-only; do not copy its code, fragments, scripts, or prototypes.
- Core dependency should remain base-only. Optional integrations belong in `compatibility/` and must not become hard dependencies.

## 4. Source layout

```text
ElectrifiedMainline/
├── info.json
├── data.lua
├── data-updates.lua
├── data-final-fixes.lua
├── control.lua
├── prototypes/bootstrap.lua
├── scripts/control.lua
├── compatibility/
└── locale/en, locale/ru
```

The root files are Factorio entrypoints/loaders. Main prototype implementation is in `prototypes/bootstrap.lua`; runtime implementation is in `scripts/control.lua`. These files are not yet functionally decomposed into smaller modules.

## 5. Implemented vs not implemented

### Present in source
- Four custom ground rail geometries: straight, curved-A, curved-B, half-diagonal.
- Unified custom rail planner item `em-high-speed-rail`; placement costs 1/3/3/2 for straight/curved-A/curved-B/half-diagonal.
- Custom recipes, technologies, pole, locomotive, cargo wagon, and fluid wagon prototypes.
- Custom pole currently uses the ordinary electric network.
- Runtime tracking of custom rails near custom poles and trains containing the custom locomotive.
- Rail-under-locomotive identity diagnostic; polling every tick is temporary and should be optimized.
- Two-stage vanilla→custom replacement adapter in runtime source: queue vanilla rail demolition, then create matching custom rail ghost after mining.
- Dedicated `em-rail-replacement-planner` selection tool in source; its game behavior remains unverified.
- Persistent state uses `storage.em`; pending replacement queue is defensively initialized. Storage schema version is 1.
- Prototype compatibility checks/logging for the four vanilla/custom geometry pairs.
- Recipe ingredients were changed to explicit Factorio 2.x ingredient objects; the concrete-beam recipe uses vanilla `pipe`, not nonexistent base item `iron-pipe`.

### Not implemented
- Real traction energy use, onboard battery charge/discharge, overhead power delivery, independent ВСМ grid, substation transfer, and regenerative energy transfer.
- Train mass/payload model.
- Full third-party modpack compatibility.
- Reverse custom→vanilla replacement/undo logic.
- Proven end-to-end blueprint overlap replacement and undo/redo.

The locomotive currently has `energy_source = { type = "void" }`; it does not consume electrical or battery energy.

## 6. Latest user-reported in-game rail tests

Factorio 2.1.20b. The exact mod build for this latest sequence was not stated; do not assign a version without confirmation.

| Scenario | Observed result |
|---|---|
| Place custom rail planner directly over existing vanilla rails | Works: custom rails replace vanilla rails; old rails are returned to inventory |
| Cancel/remove that direct replacement order | Works: drones remove custom rails, vanilla rail ghosts appear, drones restore vanilla rails |
| Place a custom rail ghost/blueprint ghost over existing vanilla rails | Does not replace: ghost reports that existing rails obstruct placement |
| Place custom rail blueprint on empty ground | Works: ghosts appear and construction robots build the rails |
| Cancel custom rail ghost construction on empty ground | Works |
| Ctrl+Shift blueprint over vanilla rails | Works as a two-stage operation: vanilla rails are marked for deconstruction; after robots remove them, custom rail ghosts appear and robots build them |
| Cancel/undo after Ctrl+Shift blueprint has produced custom rails | User reported that cancellation “does not work”; exact operation is ambiguous (Ctrl+Z vs cancelling/removing a demolition/build order). Do not assume which one failed |

Important: Ctrl+Shift over vanilla rails has already been tested. Do not ask the user to repeat it as a generic troubleshooting step. The unresolved question is the exact undo/cancellation action and its event sequence.

Earlier confirmed tests:
- Mod loads in Factorio 2.1.20b; reorganized root loaders and `require` paths worked.
- Unified custom rail planner builds rails with construction robots.
- Rail identity diagnostics detected vanilla and custom rail types, including custom curved and half-diagonal rails.
- A 0.1.3 test showed all four prototype eligibility checks passing, but vanilla/custom pairs still did not appear in the green Upgrade Planner. Stop iterating on flags/groups as a way to make that planner display the pairs.
- User reported and resolved the missing `iron-pipe` prototype load error by switching to vanilla `pipe`.
- A prior save/runtime crash occurred because `storage.em.pending_rail_replacements` was nil; defensive initialization/guards were added. Do not reintroduce assumptions that storage is initialized.

## 7. Blueprint/undo technical findings

Detailed exact-version notes: [FACTORIO_2_1_RAIL_API_NOTES.md](FACTORIO_2_1_RAIL_API_NOTES.md).

- `fast_replaceable_group` does not make a forced blueprint ghost perform fast replacement.
- `can_place_entity(... forced=true)` and `create_entity(... fast_replace=true)` are different engine paths.
- Factorio 2.1.20 documents `LuaSurface.create_entity{fast_replace=true, player=..., undo_index=...}` for player-associated fast replacement/undo. This is promising but untested for this rail/robot workflow.
- Useful events include `on_pre_build`, `on_marked_for_deconstruction`, `on_pre_ghost_deconstructed`, `on_cancelled_deconstruction`, robot mined/built events, `on_undo_applied`, and `on_redo_applied`.
- `on_blueprint_settings_pasted` is not a blueprint-placement event.
- Do not edit/remove undo-stack actions before observing the actual action arrays and grouping.
- Current replacement implementation is one-way vanilla→custom and creates the replacement ghost without associating it with the initiating player/undo item.

### Isolated diagnostic branch
- Branch: `diagnostic/blueprint-rail-undo`
- PR: https://github.com/zukera2-stack/Factorio/pull/4
- Temporary mod version: 0.1.5; main remains 0.1.4.
- Observation-only handlers log build, deconstruction, ghost, robot, and undo/redo lifecycle under `[ElectrifiedMainline][em-rail-diag]`.
- Lua syntax and packaging CI passed; ZIP artifact was produced.
- No in-game validation of this diagnostic build has been reported.
- Keep the branch/PR isolated; do not merge it into main until diagnostic findings are reviewed.

## 8. Next action

1. Establish whether the user's failed “cancel” on the Ctrl+Shift path means Ctrl+Z, cancelling a deconstruction order, or deleting/cancelling a custom rail ghost. Ask only if needed; do not conflate these operations.
2. Use the 0.1.5 diagnostic build and obtain `factorio-current.log` for the exact sequence: Ctrl+Shift blueprint over vanilla rails → wait until custom rails are built → Ctrl+Z once → Ctrl+Y once. If the user already ran this exact diagnostic build, analyze their log rather than asking for a repeat.
3. Inspect actual `on_undo_applied`/`on_redo_applied` action arrays and event ordering before designing reversible behavior.
4. Only after the undo issue is understood, test the selection tool and replacement workflow across all four rail geometries, quality/direction, mixed areas, robots/no robots, signals, stations, trains, and refund counts.
5. Re-test recipe loading with Bob's Library enabled.
6. Optimize diagnostic polling.
7. Only after rail replacement/blueprint foundation is stable, implement real traction power, storage, overhead supply, substations, and regeneration.

## 9. Compatibility and engineering constraints

- Keep core dependency base-only.
- Guard optional prototypes and references.
- Do not mutate third-party prototypes unnecessarily.
- Unknown rail/locomotive/wagon types must be tolerated.
- Keep custom prototype names namespaced with `em-`.
- Avoid scanning every train/entity every tick; filter to our rolling stock.
- Introduce explicit versioned `storage.em` migrations before changing persistent data shape.
- After Lua changes, validate syntax and run packaging CI. A successful ZIP build is not an in-game test.

## 10. New-chat protocol

1. Read `AGENTS.md`, this file, and `docs/PROJECT_STATE.yaml`.
2. Check current main/branch/PR state and inspect relevant source; this handoff can become stale.
3. Continue from the latest confirmed test, not from old planned tasks.
4. After material changes, update both handoff and YAML state in the same change set.
5. Report exact commit, files changed, CI result, and remaining in-game tests.
