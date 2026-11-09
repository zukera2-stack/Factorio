# Architecture and design notes

## Mod layout

`ElectrifiedMainline/` is the standalone Factorio mod directory.

- `info.json` — mod identity, version and dependencies.
- `data.lua` — item, recipe, technology and entity prototype definitions.
- `data-updates.lua` — data updates stage; currently contains explanatory comments only.
- `data-final-fixes.lua` — final data-stage adjustments.
- `control.lua` — runtime event handlers and persistent gameplay state.
- `locale/en/en.cfg` — English strings.
- `locale/ru/ru.cfg` — Russian strings.

## Intended gameplay model

The current concept combines three systems:

1. **Infrastructure:** custom high-speed rail variants and visual overhead-line components.
2. **Rolling stock:** a locomotive prototype intended to use a simplified battery-backed electric-power model, plus future high-speed wagon variants.
3. **Energy recovery:** regenerative braking intended to return part of the train's kinetic energy to the battery reserve.

The exact electrical model is not yet finalized. The current runtime code contains placeholder behavior, so the intended model must not be confused with a verified simulation.

## Data stage versus runtime

Factorio loads prototypes during the data stage. Runtime behavior belongs in `control.lua` and is driven by script events. Keep these responsibilities separate:

- Prototype definitions, recipes and technologies belong in the data-stage files.
- Per-save state and event-driven train behavior belong in `control.lua`.
- Locale files contain player-facing strings only.

## Persistent state

The current runtime implementation stores battery and rail markers in global mod state. Before further development, confirm the correct persistent-storage API for the target Factorio version and define a migration strategy for existing saves.

## Design decisions still open

- Whether overhead poles are purely visual markers or actual placeable entities.
- How electrified track sections are detected and maintained.
- Whether the locomotive receives continuous external power or only periodic battery charging.
- Battery capacity, charging rate, traction demand and regenerative-braking efficiency.
- Whether custom wagons are required as distinct entities or whether vanilla wagons should be modified.
- Exact Factorio and Space Age compatibility targets.
