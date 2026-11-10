# Electrified Mainline — AI handoff

> Read this file first when continuing the project in a new chat. It is a compact working handoff, not a replacement for source inspection.
> Last updated: 2026-11-10 — added explicit shared fast-replaceable group and data-stage validation for vanilla/custom rail upgrade pairs; bumped mod version to 0.1.2.

## 1. Repository

- GitHub: https://github.com/zukera2-stack/Factorio
- Main branch: `main`
- Mod directory: `ElectrifiedMainline/`
- Target game: Factorio 2.1.20b (user-confirmed); metadata targets Factorio 2.1.
- Current mod version: 0.1.2.
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
- Two-stage vanilla-to-ВСМ replacement is implemented in runtime source: intercept `on_marked_for_upgrade`, cancel the engine upgrade, order deconstruction, then create a matching ВСМ rail ghost after the old rail is mined. This uses the standard green upgrade planner as the selection/mapping UI; it does not rely on Factorio's unsupported in-place rail robot upgrade.
- Persistent runtime state is initialized defensively at the start of every event handler that reads it; `on_tick` also validates the pending replacement queue before iterating it. This protects saves where a runtime-code-only update did not trigger `on_configuration_changed`.
- The replacement workflow is API-backed but not yet game-tested. `data-final-fixes.lua` assigns `fast_replaceable_group = "em-rail-upgrade"` to all four vanilla and all four custom rails, then asserts matching `collision_box` and `collision_mask` for each geometry pair. This is a compatibility experiment; it does not prove that the green planner will select rails or that robots can replace them. Configure four geometry mappings in the green upgrade planner: straight → straight, curved-A → curved-A, curved-B → curved-B, half-diagonal → half-diagonal.

### Not implemented / not verified
- Actual electric traction energy consumption.
- Real onboard battery charging/discharging.
- Real two-network substation or bidirectional power transfer.
- Actual overhead line power delivery.
- Regenerative energy transfer to grid or battery.
- Train mass model and cargo/fluid payload mass.
- Unified rail planner operation is game-tested; user confirmed construction robots place its custom rails. Full blueprint behavior and all geometry-specific cases remain unverified.
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
- On 2026-11-10, the user tested the replacement build and reported a runtime crash at `control.lua:352`: `next(storage.em.pending_rail_replacements)` received nil on tick 70465. This shows the persistent queue was absent in the loaded save; relying only on `on_init`/`on_configuration_changed` was insufficient for a runtime-code-only update with unchanged mod version. The fix initializes persistent state defensively in every event handler that accesses it, validates the queue before iteration, and bumps the mod version from 0.1.0 to 0.1.1 so Factorio also sees a configuration version change. The fix is not yet game-tested.
- Geometry mapping: `straight-rail` → `em-high-speed-straight-rail`; `curved-rail-a` → `em-curved-high-speed-rail`; `curved-rail-b` → `em-curved-high-speed-rail-b`; `half-diagonal-rail` → `em-half-diagonal-high-speed-rail`.
- The adapter stores only primitive replacement metadata in `storage.em.pending_rail_replacements`; storage schema version 1 adds this field through an additive migration. Curved-B was also added to the runtime rail tracking whitelist.
- API references used for the adapter: [LuaEntity](https://lua-api.factorio.com/2.1.20/classes/LuaEntity.html) (`cancel_upgrade`, `order_deconstruction`) and [runtime events](https://lua-api.factorio.com/2.1.20/events.html) (`on_marked_for_upgrade`, `on_robot_mined_entity`).


Do not ask the user to resend that log unless a new test requires it.

## 6. Immediate next tasks

1. Install mod version 0.1.2 and load the existing save; verify it loads and the data-stage log reports all four validated collision-box/mask pairs.
2. Test whether the shared fast-replaceable group makes vanilla rails selectable/configurable in the green upgrade planner.
3. If pair configuration succeeds, apply it to a short straight segment and verify bots deconstruct the vanilla rail then build the matching ВСМ ghost.
4. Repeat for curved-A, curved-B and half-diagonal rails; verify direction/orientation and automatic rail reconnection.
5. If rails remain unselectable or the adapter does not fire, use a dedicated custom selection tool as the fallback.
6. Check replacement with trains present and absent; verify signals, stations and train routes after replacement.
7. Verify blueprints, all four geometries and mining/refund counts for the unified planner.
8. Re-test recipe loading with Bob's Library after the explicit ingredient-format correction.
9. Verify the corrected technology unlock progression in-game.
10. Compare custom rail placement, mining and blueprint behavior against vanilla rail workflows; verify no vanilla planner behavior changed.
11. Test direction changes and rail transitions at speed.
12. Reduce diagnostic polling frequency after rail-shape coverage is understood.
13. Continue compatibility audit: data-stage prototype inheritance, unknown third-party rolling stock, save migrations and optional adapters.
14. Only then implement real power transfer, battery behavior and regeneration.

## 7. Compatibility rules

- Core mod must not require Bob's, Angel's, Krastorio 2, Space Age or another third-party mod unless an explicit product decision changes this.
- Do not mutate third-party prototypes unnecessarily.
- Guard every optional prototype/reference.
- Unknown rail/locomotive/wagon types must be tolerated, not treated as errors.
- Keep all custom prototype names namespaced with `em-`.
- Use optional adapters in `compatibility/`; an adapter directory does not mean compatibility has been tested.
- Preserve vanilla train, signal, station, blueprint and logistics behavior where the engine allows it.
- Avoid scanning every train/entity each tick; filter to our rolling stock.
- Introduce versioned `storage.em` migrations before changing persistent data shape.

## 8. Evidence labels

Use these labels in notes and answers:

- **Implemented** — visible in current source.
- **Game-tested** — reproduced in Factorio 2.1.20b.
- **API-confirmed** — verified against the exact 2.1 API.
- **Planned** — agreed or proposed, not implemented.
- **Unverified** — present but not tested or not enough evidence.

A successful GitHub Actions ZIP build proves packaging only, not in-game functionality.

## 9. Working protocol for every new chat

1. Read `AGENTS.md`.
2. Read this `docs/AI_CONTEXT.md`.
3. Read `docs/PROJECT_STATE.yaml`.
4. Inspect current `git` source files relevant to the task.
5. Check the latest commit and workflow status; never assume this handoff is newer than the repository.
6. After material changes, update the state and handoff documents in the same change set.
7. Report exact commit, files changed, workflow result, and what still needs an in-game test.
