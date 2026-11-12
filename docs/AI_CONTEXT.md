# Current: 0.1.8 test candidate

Branch `test/undo-stabilization-018`, based on `fb3e5ca6307cf09585d67cd83566fa16e07839a8`. Manual blueprint Undo join removed; independent selection queue and native Upgrade Planner preserved. A-D statically reviewed; all 0.1.8 game tests pending. See `ElectrifiedMainline/TEST_UNDO_018.txt` (repository root) and `docs/BUILD_018.yaml` for provenance. No main merge without player log and approval.

## Historical 0.1.7 handoff (preserved)

# Electrified Mainline — current AI handoff

> Updated 2026-11-12 after the user confirmed the 0.1.7 native rail replacement/Undo/Redo test works. The confirmed scope remains the tested straight-ground-rail path. This is the compact current handoff; older failures and 0.1.6 history are below, not current capability statements.
> Read in order: `AGENTS.md` -> this file -> `docs/PROJECT_STATE.yaml` -> `docs/RESEARCH_METHOD.md` -> `CONTRIBUTING.md` -> relevant live source files. Before any non-trivial mechanic or workaround, copy `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` into a new `docs/research/` record and complete the research sections before coding. Full older notebook: `PROJECT_CONTEXT.md` (historical only).

## 1. Current repository and environment

- Repository: https://github.com/zukera2-stack/Factorio
- Stable branch: `main`; **current validated experiment on** `diagnostic/blueprint-rail-undo`. Do not assume `main` contains 0.1.7.
- Mod directory/root: `ElectrifiedMainline/`; `info.json` version **0.1.7**, Factorio metadata `2.1`, Base dependency `>= 2.1.0`.
- User test environment: Factorio **2.1.20**, build 87512 (installation path labelled 2.1.20b), Bob's Assembly **3.0.2** and a larger Bob's/Space Age test pack.
- GitHub Actions: `.github/workflows/build-mod.yml`, runs on relevant pushes to `main` or the diagnostic branch. A packaged ZIP is **not** game-test evidence.

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


## 4. Current implementation and verified state

### Verified in-game (scoped claims)

- **0.1.7 native green Upgrade Planner on straight ground vanilla rails**: 20 `straight-rail` entities were ordered to upgrade to `em-high-speed-straight-rail` (`on_marked_for_upgrade tick=14284`); robots mined vanilla and built custom rails.
- **Ctrl+Z** (`on_undo_applied tick=14591 action_count=20`): 20 `upgraded-entity` actions with `original_name=straight-rail`; robots removed custom rails and rebuilt vanilla.
- **Ctrl+Y** (`on_redo_applied tick=14940 action_count=20`): 20 native upgrade actions; robots mined vanilla and rebuilt custom rails.
- This session loaded the existing save, logged no observed ElectrifiedMainline runtime errors, and ended normally.
- Prior tests verified the unified rail planner can place custom rails through robots, and rail identity tracking detects selected vanilla and custom rail geometries.

### Implemented in 0.1.7 source

- Four named custom **ground** rail geometries; unified custom `rail-planner` item `em-high-speed-rail`, placement costs 1/3/3/2 by geometry.
- `data-final-fixes.lua`: four geometry-specific `fast_replaceable_group` values (`em-native-<geometry>`), vanilla-to-custom `next_upgrade` mappings, mining/visibility/collision checks, and a guard against overwriting an existing foreign upgrade chain.
- `scripts/control.lua`: `on_marked_for_upgrade` **observes** native upgrades; it must **not cancel** native orders.
- The **separate** `em-rail-replacement-planner` selection tool still uses the old staged mining + custom ghost fallback. Scripted Ctrl+Shift blueprint `undo_index=1` ghost joining also remains in source.
- Rail diagnostics and runtime train/rail tracking, a cloned locomotive/pole/wagons, recipes and technology prototypes.

### Not verified or not implemented

- Native upgrade + Undo/Redo for `curved-rail-a`, `curved-rail-b`, `half-diagonal-rail`. Data-stage eligibility **passed**, but these were not tested by robots in the 0.1.7 supplied log.
- Superforced blueprint `Ctrl+Shift` with native Undo/Redo, separately from the **green Upgrade Planner**.
- Selection-tool fallback correctness, native transitions with trains occupying tracks, signalling/route integrity, inventory refunds, multiplayer or broad compatibility.
- **No actual energy model yet**: overhead traction, real battery charging/discharging, high-speed grid, bidirectional substations, regeneration and train-mass accounting are still planned. Locomotive uses a placeholder `void` energy source.
- Diagnostics currently poll rails each tick; optimize after verification.

## 5. Resolved bug: why 0.1.6 Undo failed and 0.1.7 works

**Old mistaken conclusion:** after the 0.1.3 failed green-planner test we documented native rail robot upgrades as universally unsupported. That conclusion is **false for the straight ground rail test** and must not be repeated.

Research sequence:
1. Compare **Bob's assembler** native upgrades (`fast_replaceable_group`, `next_upgrade`, common collision geometry) with our source. Bob's public repository revision inspected is different from the installed Bob's Assembly 3.0.2: cite the difference.
2. Find a **same-type rail precedent** (Minimal Electric Rails): vanilla and custom ground rails use paired geometry-specific `fast_replaceable_group` and `next_upgrade`.
3. Check official Factorio `EntityPrototype` and `UpgradeItemPrototype` requirements.
4. Set matching prototype properties and stop canceling native `on_marked_for_upgrade`; test real gameplay.

**0.1.6 historical experiment**: delayed straight-rail ghost recreation with `player`/`undo_index=1` allowed a superforced blueprint Undo to remove custom rails but **did not restore** the vanilla rail originals. This legacy scripted path remains experimental.

**0.1.7 outcome**: native green Upgrade Planner made a reversible `upgraded-entity` transaction for 20 straight rails. No custom Undo/Redo implementation needed in that path. We changed several conditions together; the log does not prove which one alone was necessary.

Full process and source references: [`RESEARCH_METHOD.md`](RESEARCH_METHOD.md) and repository [`CONTRIBUTING.md`](../CONTRIBUTING.md). Use the [research worksheet](PROTOTYPE_RESEARCH_TEMPLATE.md) for each non-trivial future mechanic; the [completed 0.1.7 rail-upgrade record](research/rail-native-upgrade-0.1.7.md) shows the required evidence level. This is a mandatory project-wide method, not merely a lesson from the rail bug. Never replace API research with guessed flags or write scripted Undo before checking engine-native ownership.

## 6. Immediate next tests and work

1. Repeat **native** green Upgrade Planner -> robot upgrade -> Ctrl+Z -> Ctrl+Y for curved-A, curved-B and half-diagonal ground rails. Verify direction/connection, quality, and item counts.
2. Test `Ctrl+Shift` blueprint superforce **separately**; do not claim the native test covers the scripted fallback.
3. Evaluate whether the old selection-tool/staged workflow is still needed, and avoid breaking its saves or queued bot jobs before removing it.
4. Check signals, stations, live trains, blocked/partial bot tasks, and cancellation.
5. Trim diagnostic polling and excess logging only after focused regressions.
6. Research native/third-party analogue for overhead power, battery and network transfer *before* new architecture or Lua code.

## 7. Project invariants and evidence

- Preserve native train/rail/signals/stations and vanilla rolling-stock interoperability.
- Core dependency stays Base unless a verified technical requirement changes it; optional mod code goes under `compatibility/` with guards.
- Do not copy code from Electrified Railways, Bob's, Minimal Electric Rails or any reference mod. Learn the prototype contract and implement independently.
- Evidence labels: **implemented**, **API-confirmed**, **game-tested**, **inferred**, **unverified**, **planned**.
- Source is authoritative for what exists; `docs/PROJECT_STATE.yaml` is authoritative for statuses; user logs are proof of specific tested paths. A ZIP CI pass is never proof of gameplay.
- Material code changes must update this file and `docs/PROJECT_STATE.yaml` in the same coherent change set.

## 8. Handoff protocol

Read `AGENTS.md` -> this file -> `docs/PROJECT_STATE.yaml` -> `docs/RESEARCH_METHOD.md` -> `CONTRIBUTING.md` -> live source. For non-trivial mechanics, complete `docs/PROTOTYPE_RESEARCH_TEMPLATE.md` in a new `docs/research/` record before coding. Check the active branch head and mod version. Research existing functionality **before proposing new scripts**. Test only changed behavior, report actual observations and open questions, then synchronize docs and changelog.


## 9. Mandatory research-first contribution method

Every future mechanic, compatibility change, or bug workaround must follow `AGENTS.md`, `CONTRIBUTING.md`, and `RESEARCH_METHOD.md`: define the exact player-visible test; inspect Base/native behavior; find a working same-type mod precedent; record its source ref and version; compare relevant prototype properties and runtime ownership with the official target-version API and our source; state a falsifiable hypothesis; implement the smallest independent change; test the exact path in Factorio; and synchronize project status/evidence. If no suitable analogue exists, document the search and uncertainty rather than inventing flags. Reference code is for study, not copying.

The user's confirmation that "everything works" applies to the 0.1.7 test path already recorded above (20 straight ground rails via the native green Upgrade Planner, robot replacement, Ctrl+Z restore, Ctrl+Y redo). It does not silently promote untested geometries or other replacement tools to game-tested.
