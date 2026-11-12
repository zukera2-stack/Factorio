# Electrified Mainline — AI handoff

> Read this file first when continuing the project in a new chat. It is a compact working handoff, not a replacement for source inspection.
> Last updated: 2026-11-10 — green Upgrade Planner pairs remain absent in the user's 0.1.3 test despite all four eligibility checks passing; added a dedicated filtered rail-replacement selection tool in 0.1.4.

## 1. Repository

- GitHub: https://github.com/zukera2-stack/Factorio
- Main branch: `main`
- Mod directory: `ElectrifiedMainline/`
- Target game: Factorio 2.1.20b (user-confirmed); metadata targets Factorio 2.1.
- Current mod version: 0.1.5 (temporary diagnostic build on branch `diagnostic/blueprint-rail-undo`).
- User explicitly authorized direct repository changes.
- User wants work to be resumable from any chat. Read this file, then `docs/PROJECT_STATE.yaml`, then inspect current source.

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

## 4. Implementation status — do not overclaim

### Present in source
- Four custom ground-rail prototypes cloned from the matching vanilla Factorio 2.1.20 prototypes: straight, curved-A, curved-B and half-diagonal.
- One unified custom `rail-planner` item (`em-high-speed-rail`) lists all four custom rail entities; shape-specific rail inventory items were removed.
- Every custom rail entity uses the unified planner item through `placeable_by`; straight/curved-A/curved-B/half-diagonal placement costs are 1/3/3/2 planner items, matching vanilla geometry costs.
- Custom items, recipes and technologies.
- Custom electric pole cloned from the vanilla small electric pole; it currently belongs to the ordinary electric network, not a separate ВСМ grid.
- Custom locomotive cloned from vanilla locomotive.
- Custom cargo and fluid wagons cloned from vanilla rolling stock without capacity or performance changes.
- Runtime tracking of custom rail segments near custom poles.
- Runtime tracking of trains containing the custom locomotive.
- Rail-under-locomotive diagnostic based on `train.get_rails()`, choosing the nearest rail to each locomotive position.
- Diagnostic log only reports when detected rail identity changes.
- Rail diagnostic polling currently runs every tick; this is temporary and must be optimized after testing.
- Previous train speed is stored every 30 ticks as scaffolding.
- Two-stage vanilla-to-ВСМ replacement is implemented in runtime source: queue deconstruction, then create a matching ВСМ rail ghost after the old rail is mined. The legacy `on_marked_for_upgrade` adapter remains, but the user's 0.1.3 test confirmed that vanilla/custom pairs still do not appear in the green Upgrade Planner.
- A dedicated `em-rail-replacement-planner` selection-tool prototype is now added. Its normal selection is whitelisted to the four vanilla rail geometries. The runtime `on_player_selected_area` handler queues only those vanilla rails for deconstruction; the existing mined-rail pipeline then creates the matching custom ghost. The planner recipe is unlocked with the high-speed rail technology. This implementation is source-only until the user tests it in Factorio.
- Persistent runtime state is initialized defensively at the start of every event handler that reads it; `on_tick` also validates the pending replacement queue before iterating it. This protects saves where a runtime-code-only update did not trigger `on_configuration_changed`.
- The replacement workflow is API-backed but not yet game-tested. `data-final-fixes.lua` assigns `fast_replaceable_group = "em-rail-upgrade"` to all four vanilla and all four custom rails, removes `not-upgradable` from either side if present, and logs source eligibility (`minable`, `hidden`, hidden mining products), target visibility/build item, and collision-box/mask compatibility for every geometry pair. These diagnostics do not prove that the green planner will display the pairs or that robots can replace rails. Configure four geometry mappings in the green upgrade planner: straight → straight, curved-A → curved-A, curved-B → curved-B, half-diagonal → half-diagonal.

### Not implemented / not verified
- Actual electric traction energy consumption.
- Real onboard battery charging/discharging.
- Real two-network substation or bidirectional power transfer.
- Actual overhead line power delivery.
- Regenerative energy transfer to grid or battery.
- Train mass model and cargo/fluid payload mass.
- Unified rail planner operation is game-tested; user confirmed construction robots place its custom rails. Full blueprint behavior and all geometry-specific cases remain unverified.
- Custom rail replacement selection tool and robot replacement workflow are not yet game-tested.
- Full interoperability testing with large modpacks.
- Optional compatibility adapters.

The locomotive's current `energy_source = { type = "void" }` is a placeholder. It does not consume grid energy or battery energy.

## 5. Last confirmed in-game test

On 2026-11-09 the user confirmed the mod launches in Factorio 2.1.20b. A supplied `factorio-current.log` was analyzed:

- Mod loaded and the game session continued; no runtime error attributable to the mod was found in the inspected log.
- The reorganized root loaders and `require` paths were exercised successfully: the mod loaded, the existing save opened, runtime script loaded from `scripts/control.lua`, and the session ended normally.
- The latest supplied log contained 404 rail-diagnostic entries for train ID 6 and custom locomotives 720 and 722.
- Detected rail names included vanilla `straight-rail`, `curved-rail-a`, `curved-rail-b`, `half-diagonal-rail`, plus custom `em-high-speed-straight-rail`, `em-curved-high-speed-rail` and `em-half-diagonal-high-speed-rail`.
- Custom curved and custom half-diagonal rail identity detection is now confirmed in the supplied log; this is still identity detection only, not proof of electrical power.
- The log did not prove power delivery, battery behavior, traction energy or regeneration.
- Bob's Library emitted ingredient validation warnings because recipe ingredients used legacy two-element tuples. The source has now been converted to explicit Factorio 2.x ingredient objects (`type`, `name`, `amount`). This correction still requires a fresh game test with Bob's Library enabled.
- On 2026-11-10, the user reported a fresh mod-load failure at `em-concrete-beam.ingredients[2]`: `iron-pipe` does not exist in base Factorio. The source recipe was corrected to use the vanilla `pipe` item; the corrected build passed CI and the user subsequently confirmed the mod loads and the rail planner works.
- On 2026-11-10, the user reported that vanilla rails are not replaced by placing the custom rail planner over them and that the green upgrade planner did not work. API research found that Factorio's built-in robot upgrade operation is not supported for rails. Runtime code now intercepts compatible green-planner upgrade marks, cancels the native upgrade, queues rail deconstruction, and creates a custom rail ghost one tick after mining. This is a two-stage replacement adapter, not native in-place rail upgrading, and has not yet been tested in-game.
- On 2026-11-10, the user tested the 0.1.3 build in Factorio 2.1.20b. All four `[upgrade-check]` lines passed: source minable/visible/hidden-mining-product checks, target visibility/build item, shared group, collision box and collision mask. Despite this, the user confirmed that vanilla/custom pairs remain absent from the green Upgrade Planner. This is direct in-game evidence that the tested eligibility conditions do not make the rails available in that planner UI. Decision: stop iterating on planner flags/groups and provide a dedicated selection-tool workflow.
- On 2026-11-10, the user tested the replacement build and reported a runtime crash at `control.lua:352`: `next(storage.em.pending_rail_replacements)` received nil on tick 70465. This shows the persistent queue was absent in the loaded save; relying only on `on_init`/`on_configuration_changed` was insufficient for a runtime-code-only update with unchanged mod version. The fix initializes persistent state defensively in every event handler that accesses it, validates the queue before iteration, and bumps the mod version from 0.1.0 to 0.1.1 so Factorio also sees a configuration version change. The fix is not yet game-tested.
- Geometry mapping: `straight-rail` → `em-high-speed-straight-rail`; `curved-rail-a` → `em-curved-high-speed-rail`; `curved-rail-b` → `em-curved-high-speed-rail-b`; `half-diagonal-rail` → `em-half-diagonal-high-speed-rail`.
- The adapter stores only primitive replacement metadata in `storage.em.pending_rail_replacements`; storage schema version 1 adds this field through an additive migration. Curved-B was also added to the runtime rail tracking whitelist.
- API references used for the adapter: [LuaEntity](https://lua-api.factorio.com/2.1.20/classes/LuaEntity.html) (`cancel_upgrade`, `order_deconstruction`) and [runtime events](https://lua-api.factorio.com/2.1.20/events.html) (`on_marked_for_upgrade`, `on_robot_mined_entity`).


Do not ask the user to resend that log unless a new test requires it.

## 6. Temporary diagnostic build — blueprint rail undo

- Branch: `diagnostic/blueprint-rail-undo`, based on main commit `5d733127887d368d1366c586e4509a16517b3062`.
- Temporary mod version: 0.1.5. This is an isolated test branch; `main` is unchanged.
- Added observation-only log handlers for `on_pre_build`, `on_marked_for_deconstruction`, `on_built_entity`, `on_robot_built_entity`, `script_raised_built`, `script_raised_revive`, `on_robot_mined_entity`, `on_player_mined_entity`, `on_pre_ghost_deconstructed`, `on_cancelled_deconstruction`, `on_undo_applied`, and `on_redo_applied`.
- Log prefix: `[ElectrifiedMainline][em-rail-diag]`. Undo/redo action records include action type, target name/position/direction/quality, surface index, and original entity identity where exposed by the API.
- The diagnostics are observational only: no blueprint, replacement, ghost, or undo behavior is changed by these handlers.
- Test sequence requested: (1) place a ВСМ blueprint over vanilla rails using Ctrl+Shift; (2) Ctrl+Z once; (3) Ctrl+Y once. Then provide `factorio-current.log`.
- Not yet validated in-game. Packaging CI still required; logs must confirm actual event order and action payloads before implementing the fix.

## 7. Immediate next tasks

1. Install mod version 0.1.4 and confirm the new replacement planner is available after researching high-speed rails.
2. Test the custom selection tool on a short straight segment; confirm the vanilla rail is marked for deconstruction and construction robots place the matching ВСМ ghost.
3. Test curved-A, curved-B and half-diagonal rails; verify direction, quality, geometry and automatic reconnection.
4. Test a selected area containing mixed vanilla/custom rails; custom rails must remain untouched.
5. Test with and without construction robots in range, and cancel a queued deconstruction to confirm the pending replacement is cleared.
6. Verify signals, stations, train routes, blueprints and mining/refund counts after replacement.
7. Re-test explicit recipe ingredient format with Bob's Library enabled.
8. Continue the remaining rail planner, technology and modpack compatibility checks.
6. Check replacement with trains present and absent; verify signals, stations and train routes after replacement.
7. Verify blueprints, all four geometries and mining/refund counts for the unified planner.
8. Re-test recipe loading with Bob's Library after the explicit ingredient-format correction.
9. Verify the corrected technology unlock progression in-game.
10. Compare custom rail placement, mining and blueprint behavior against vanilla rail workflows; verify no vanilla planner behavior changed.
11. Test direction changes and rail transitions at speed.
12. Reduce diagnostic polling frequency after rail-shape coverage is understood.
13. Continue compatibility audit: data-stage prototype inheritance, unknown third-party rolling stock, save migrations and optional adapters.
14. Only then implement real power transfer, battery behavior and regeneration.

## 8. Compatibility rules

- Core mod must not require Bob's, Angel's, Krastorio 2, Space Age or another third-party mod unless an explicit product decision changes this.
- Do not mutate third-party prototypes unnecessarily.
- Guard every optional prototype/reference.
- Unknown rail/locomotive/wagon types must be tolerated, not treated as errors.
- Keep all custom prototype names namespaced with `em-`.
- Use optional adapters in `compatibility/`; an adapter directory does not mean compatibility has been tested.
- Preserve vanilla train, signal, station, blueprint and logistics behavior where the engine allows it.
- Avoid scanning every train/entity each tick; filter to our rolling stock.
- Introduce versioned `storage.em` migrations before changing persistent data shape.

## 9. Evidence labels

Use these labels in notes and answers:

- **Implemented** — visible in current source.
- **Game-tested** — reproduced in Factorio 2.1.20b.
- **API-confirmed** — verified against the exact 2.1 API.
- **Planned** — agreed or proposed, not implemented.
- **Unverified** — present but not tested or not enough evidence.

A successful GitHub Actions ZIP build proves packaging only, not in-game functionality.

## 10. Working protocol for every new chat

1. Read `AGENTS.md`.
2. Read this `docs/AI_CONTEXT.md`.
3. Read `docs/PROJECT_STATE.yaml`.
4. Inspect current `git` source files relevant to the task.
5. Check the latest commit and workflow status; never assume this handoff is newer than the repository.
6. After material changes, update the state and handoff documents in the same change set.
7. Report exact commit, files changed, workflow result, and what still needs an in-game test.

## 2026-11-12 — test build 0.1.6
- User verified superforced blueprint replacement of 14 vanilla straight rails with construction robots.
- Native Ctrl+Z registered 29 actions (14 upgraded-entity, 15 built-entity), removed custom rails but did not restore vanilla rails.
- Ctrl+Y rebuilt custom rails. Bob's assembling-machine upgrade correctly restored the original machine on Undo.
- Experimental `undo_index=1` ghost attachment works for the tested straight rails; full native restoration remains unimplemented.
- Diagnostic branch publishes GitHub Actions test ZIPs; packaging is not an in-game test.

## 2026-11-12 — 0.1.7 native-upgrade test (source only)
- Inspected Bob's assembling-machine prototypes: assembling machines 4/5/6 use identical collision boxes, a common fast_replaceable_group, and a next_upgrade chain; engine performs native Undo/Redo, not Bob's Lua runtime.
- Inspected MIT-licensed Minimal Electric Rails as technical reference: each ground rail geometry uses a separate fast_replaceable_group and vanilla next_upgrade points at matching custom ground rail.
- 0.1.6 source had one shared em-rail-upgrade group across geometries, no next_upgrade, and on_marked_for_upgrade actively canceled and staged upgrades.
- 0.1.7 applies per-geometry groups + next_upgrade to eligible vanilla/custom pairs. Native on_marked_for_upgrade is observation-only. Custom replacement selection tool remains staged fallback.
- Test native green Upgrade Planner first, then Ctrl+Z/Ctrl+Y with robots; test superforce blueprints separately. Ground rail runtime result unverified pending user log.
- Existing experimental 0.1.6 delayed ghost Undo attachment remains for legacy superforce fallback; restoring vanilla rails in that fallback remains incomplete.
- Do not copy third-party mod code or claim ground native replacement as proven merely from prototype validation or ZIP build.
