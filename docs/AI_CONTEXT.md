# Electrified Mainline — AI handoff

> Read this file first when continuing the project in a new chat. It is a compact working handoff, not a replacement for source inspection.
> Last updated: 2026-11-10 — fixed invalid vanilla recipe ingredient reference (`iron-pipe` → `pipe`); user confirmed unified rail planner works and construction robots place its rails.

## 1. Repository

- GitHub: https://github.com/zukera2-stack/Factorio
- Main branch: `main`
- Mod directory: `ElectrifiedMainline/`
- Target game: Factorio 2.1.20b (user-confirmed); metadata targets Factorio 2.1.
- Current mod version: 0.1.0.
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

### Not implemented / not verified
- Actual electric traction energy consumption.
- Real onboard battery charging/discharging.
- Real two-network substation or bidirectional power transfer.
- Actual overhead line power delivery.
- Regenerative energy transfer to grid or battery.
- Train mass model and cargo/fluid payload mass.
- Full rail replacement/upgrade workflow.
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
- On 2026-11-10, the user confirmed that construction robots successfully place custom rails using the unified planner. The vanilla-to-custom rail upgrade workflow has not yet been tested.

Do not ask the user to resend that log unless a new test requires it.

## 6. Immediate next tasks

1. Test upgrading an existing vanilla rail line to custom ВСМ rails using the upgrade planner; check straight, curved and diagonal sections, including robot execution.
2. Verify blueprints, all four geometries and mining/refund counts for the unified planner.
3. Re-test recipe loading with Bob's Library after the explicit ingredient-format correction.
4. Verify the corrected technology unlock progression in-game.
5. Compare custom rail placement, mining and blueprint behavior against vanilla rail workflows; verify no vanilla planner behavior changed.
6. Test direction changes and rail transitions at speed.
7. Reduce diagnostic polling frequency after rail-shape coverage is understood.
8. Continue compatibility audit: data-stage prototype inheritance, unknown third-party rolling stock, save migrations and optional adapters.
9. Only then implement real power transfer, battery behavior and regeneration.

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
