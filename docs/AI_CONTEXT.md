# Electrified Mainline — AI handoff

> Read this file first when continuing the project in a new chat. It is a compact working handoff, not a replacement for source inspection.
> Last updated: 2026-11-09 — repository structure reorganized; runtime behavior not intentionally changed.

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
- Custom straight, curved and half-diagonal rail prototypes.
- Custom items, recipes and technologies.
- Custom electric pole cloned from the vanilla small electric pole.
- Custom locomotive cloned from vanilla locomotive.
- Custom cargo and fluid wagons cloned from vanilla rolling stock.
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
- Full interoperability testing with large modpacks.
- Optional compatibility adapters.

The locomotive's current `energy_source = { type = "void" }` is a placeholder. It does not consume grid energy or battery energy.

## 5. Last confirmed in-game test

On 2026-11-09 the user confirmed the mod launches in Factorio 2.1.20b. A supplied `factorio-current.log` was analyzed:

- Mod loaded and the game session continued; no runtime error attributable to the mod was found in the inspected log.
- Rail diagnostics produced 1052 log lines.
- One train (ID 6) with two custom locomotives (IDs 720 and 722) was tracked.
- Detected rail names included vanilla straight, curved A/B, half-diagonal and custom straight high-speed rail.
- The two locomotives detected a transition from custom to vanilla straight rail at different times, as expected for their different positions.
- The log did not prove custom curved or custom half-diagonal rail detection.
- The log did not prove power delivery, battery behavior, traction energy or regeneration.
- Bob's Library emitted ingredient validation warnings such as invalid ingredient name/amount/type. Treat these as a real compatibility signal to investigate, not as proof that Factorio itself aborted recipe loading.

Do not ask the user to resend that log unless a new test requires it.

## 6. Immediate next tasks

1. Validate the new module entry points and packaging workflow after this structural move.
2. Audit recipe ingredient syntax for Factorio 2.1 separately from research ingredient syntax. Do not blindly convert research ingredients to recipe format.
3. Verify all item/prototype/technology references, including the current `steel-gear-wheel` recipe ingredient.
4. Test custom curved and half-diagonal rails, then direction changes.
5. Reduce diagnostic polling frequency after the rail-transition test.
6. Add an explicit powered/unpowered rail state only after rail identity detection is validated.
7. Continue compatibility audit: data-stage prototype inheritance, technology graph, unknown third-party rolling stock, save migrations and optional adapters.
8. Only then implement real power transfer and battery behavior.

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
