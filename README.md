# Electrified Mainline

A Factorio 2.1 mod project exploring high-speed railway infrastructure, an electric locomotive concept, battery support and regenerative braking.

> **Development status:** early prototype. The repository contains source files and a 0.1.0 archive, but the current implementation has not yet been fully validated in-game. Some items and mechanics are placeholders or incomplete. See [Development status](docs/STATUS.md) before installing or building on this project.

## Project contents

| Path | Purpose |
| --- | --- |
| `ElectrifiedMainline/` | Mod source. This directory is the mod root and contains `info.json`, data-stage scripts, runtime script and locale files. |
| `mods/` | Previously packaged mod archive(s). |
| `docs/` | Design notes, implementation status and development guidance. |
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

The repository includes `mods/ElectrifiedMainline_0.1.0.zip`. It is retained as an existing package; it has **not** been independently verified against the current source tree.

For a manual test:

1. Back up your save.
2. Copy the archive into Factorio's mods directory.
3. Enable the mod from the in-game Mods menu.
4. Start a disposable test save and check the log if loading fails.

Do not use this prototype in an important save until its data-stage and runtime behavior have been tested.

## Development

The mod source is kept in `ElectrifiedMainline/` as a self-contained Factorio mod directory. Keep `info.json` at the top level of that directory.

Before preparing a release:

1. Validate all prototypes and recipe/technology references against the target Factorio version.
2. Test loading with only the base game, then with the intended expansion setup.
3. Exercise placement, mining, train creation, train merging/splitting and save/load behavior.
4. Build the distributable ZIP from the contents of `ElectrifiedMainline/` (the archive must contain `info.json` at its root, not an extra enclosing directory).
5. Update `CHANGELOG.md` and the version in `info.json` together.

## Documentation

- [Development status and known gaps](docs/STATUS.md)
- [Architecture and design notes](docs/ARCHITECTURE.md)
- [Russian overview](README.ru.md)

## License

No license has been selected yet. Until one is added, the repository should be treated as **all rights reserved**; do not assume that the code is open for redistribution or modification by third parties.
