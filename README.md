> **Current project across branches:** Read [`docs/CURRENT_WORK.md`](docs/CURRENT_WORK.md) first. The contents below document the previous **stable 0.1.56 visual milestone**. **0.1.62 public beta** is prepared in PR #46 (native substation power, reversals and dynamic EEI, tested in Factorio 2.1.24). The installed Updater-approved channel stays on 0.1.61 until separately approved; PR #46 merge alone does not update it.

# Electrified Mainline 0.1.56 — stable main visual milestone (19 Nov 2026)

Merged via [PR #30](https://github.com/zukera2-stack/Factorio/pull/30) with owner approval.

Original rail-axis contact graph, autonomous locomotive with 256 directions and cosmetic pantograph/sparks, concrete HSR slabs with native fasteners. [Scoped game acceptance](docs/tests/catenary-0.1.56-user-acceptance.md). [CI install ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575/artifacts/14572849193) (121 files, 81 PNGs; extract only the inner ZIP). Actual traction energy transfer remains zero. Experimental phase-2 attachment excluded. Previous stable 0.1.48: [PR #27](https://github.com/zukera2-stack/Factorio/pull/27) and [historical ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/44415412191/artifacts/14478562971).

---

# Electrified Mainline

A **Factorio 2.1** mod for high-speed railway infrastructure and 25 kV overhead-line support masts; real electric traction, onboard energy storage and regeneration remain future work.

**Historical previous stable `main` version: 0.1.24**, user-tested with **Factorio 2.1.20 build 87512** on the `ВСМ` save. The promotion was merged in [PR #8](https://github.com/zukera2-stack/Factorio/pull/8). The C catenary-mast graphics show a native visible shaft in the placement cursor, eight rail-facing cantilevers, translucent ghosts, native robot construction/Undo, the SOUTH-based item icon and subdued circular placement hints. [Scoped game-test evidence](docs/tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md) · [0.1.24 GitHub Actions ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702/artifacts/14175755233).

**The rendered overhead wires are cosmetic.** Actual traction transfer remains `transfer_MW=0`, so this is a **visual milestone**, not a complete electrification system.

The prior **0.1.8 ZIP** remains the historical rollback baseline and preserves game evidence for native Upgrade Planner + Undo/Redo on straight and curved-A/B rails. Those full rail regressions have **not** all been rerun in 0.1.24. [0.1.8 test details](docs/tests/undo-0.1.8-2026-11-12.md).

## Current 25 kV mast architecture (legacy 35 kV prototype IDs)

- A single native `electric-pole.pictures` C lattice shaft supplies the standard mouse cursor and engine-rendered ghost body.
- Eight cantilever-only sprites are dynamically selected using RailEnd projection, with blue-tinted arm-only overlays for ghosts.
- Placement, ghost creation, copying, robots and Undo/Redo remain engine-native, not proxy signal entities.
- All active source graphics and PNG QA live in this branch; the obsolete 012/024 frames were removed and remain available only from Git history or the stable main branch.

Next: separately research actual MW energy exchange; preserve the accepted visual graph. [Status](docs/STATUS.md) · [Architecture](docs/ARCHITECTURE.md) · [AI handoff](docs/AI_CONTEXT.md).

## History

Versions 0.1.15–0.1.23 are historical implementation steps, not current builds. Their studies and evidence are under [research](docs/research/) and [test reports](docs/tests/), with full source ancestry in Git history.

## Project contents

| Path | Purpose |
| --- | --- |
| `ElectrifiedMainline/` | Mod source. This directory is the mod root and contains `info.json`, data-stage scripts, runtime script and locale files. |
| `build/package/` | Generated game ZIP (not tracked); published separately by GitHub Actions. |
| `build/qa/` | Generated QA atlas (not tracked; never included in game ZIP). |
| `dist/` | Historical 0.1.8 rollback ZIP only. |
| `docs/` | Design notes, implementation status and development guidance. |
| `CONTRIBUTING.md` | Mandatory research-first contributor workflow and evidence rules. |
| `README.ru.md` | Russian version of this overview. |
| `CHANGELOG.md` | Version history. |

## Intended features

The project is being developed around these ideas:

- high-speed straight, curved and half-diagonal rail variants;
- an electric locomotive with a battery reserve;
- overhead-line infrastructure represented by a simplified in-game system;
- regenerative braking;
- dedicated rolling-stock concepts;
- English and Russian localization.

These are project goals, not a claim that every feature is currently complete. The current implementation status is documented in [docs/STATUS.md](docs/STATUS.md).

## Requirements

- Factorio **2.1**
- Base game dependency: `base >= 2.1.0`
- Space Age is mentioned in source comments, but its necessity has not been established in the mod metadata.

## Installation

For 0.1.56, download [the accepted GitHub Actions artifact](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575/artifacts/14572849193), extract the **inner** `ElectrifiedMainline_0.1.56.zip` and install only that inner ZIP in `mods`. The [0.1.8 ZIP](dist/ElectrifiedMainline_0.1.8.zip) is preserved for historical rollback, not the active source version.

For a manual test:

1. Back up your save.
2. Copy the archive into Factorio's mods directory.
3. Enable the mod from the in-game Mods menu.
4. Start a disposable test save and check the log if loading fails.

Do not use this prototype in an important save until its data-stage and runtime behavior have been tested.

## Development

The mod source is kept in `ElectrifiedMainline/` as a self-contained Factorio mod directory. Keep `info.json` at the top level of that directory.

Before preparing a release:

1. For every non-trivial mechanic, compatibility change, or workaround, copy the [research worksheet](docs/PROTOTYPE_RESEARCH_TEMPLATE.md) into `docs/research/` and complete it before coding. Follow the [research-first method](docs/RESEARCH_METHOD.md): inspect working native/same-type analogues and the official target-version API, then compare them with our source.
2. Test loading with only the base game, then with the intended expansion setup.
3. Exercise placement, mining, train creation, train merging/splitting and save/load behavior.
4. Build the Factorio mod ZIP with **exactly one mod folder**, matching the current CI layout: `ElectrifiedMainline/info.json` at archive root. The current CI packages `ElectrifiedMainline/` inside the ZIP (no duplicate nested copy); metadata validation checks it. Do not package the inner contents bare or insert a second redundant folder.
5. Update `CHANGELOG.md` and the version in `info.json` together.

## Development workflow

Contributors and AI coding agents must follow [`AGENTS.md`](AGENTS.md) and the [research-first contribution guide](CONTRIBUTING.md): inspect a working native or same-type mod analogue, verify the official target-version API, compare before coding, then test the exact gameplay path. Do not guess mechanics or treat CI packaging as gameplay proof.

## Documentation

- [Development status and known gaps](docs/STATUS.md)
- [Architecture and design notes](docs/ARCHITECTURE.md)
- [Research method: working analogues over guesses](docs/RESEARCH_METHOD.md)
- [Prototype research worksheet](docs/PROTOTYPE_RESEARCH_TEMPLATE.md)
- [Completed 0.1.7 rail-upgrade research record](docs/research/rail-native-upgrade-0.1.7.md)
- [Contributor workflow](CONTRIBUTING.md)
- [Project state](docs/PROJECT_STATE.yaml)
- [Russian overview](README.ru.md)

## License

No license has been selected yet. Until one is added, the repository should be treated as **all rights reserved**; do not assume that the code is open for redistribution or modification by third parties.

[Historical branch archive](docs/history/BRANCH_ARCHIVE_056.md). Only main is active; future development branches from main.
