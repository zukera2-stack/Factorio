# Electrified Mainline

A Factorio 2.1 mod project exploring high-speed railway infrastructure, an electric locomotive concept, battery support and regenerative braking.

> **Development status: 0.1.8, game-tested release baseline (PR #6 into `main`).** Factorio 2.1.20 build 87512: native Upgrade Planner upgraded **26 straight + 8 curved** rails with working Ctrl+Z/Ctrl+Y; Ctrl+Shift superforced blueprint overlay upgraded **14 straight + 8 curved** rails with working Undo/Redo. Experimental scripted Undo joining was removed. Half-diagonal gameplay, the separate replacement selection tool and interrupted robot jobs remain unverified; electric traction, battery, overhead transfer and regeneration are not yet implemented. See [current status](docs/STATUS.md) and [test evidence](docs/tests/undo-0.1.8-2026-11-12.md).

## Project contents

| Path | Purpose |
| --- | --- |
| `ElectrifiedMainline/` | Mod source. This directory is the mod root and contains `info.json`, data-stage scripts, runtime script and locale files. |
| `mods/` | Previously packaged mod archive(s). |
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

For the 0.1.8 release baseline, use the committed [validated 0.1.8 ZIP](dist/ElectrifiedMainline_0.1.8.zip) or a successful **Build Factorio mod ZIP** artifact from [GitHub Actions](https://github.com/zukera2-stack/Factorio/actions/workflows/build-mod.yml) (artifact name `ElectrifiedMainline-test-build`). The old `mods/ElectrifiedMainline_0.1.0.zip` is historical, **not** the current version. The game-tested ZIP checksum and source SHA are in [BUILD_018.yaml](docs/BUILD_018.yaml).

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
