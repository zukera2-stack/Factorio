# Runtime scripts

- `control.lua` contains the current runtime event handling and is loaded by the root `control.lua`.

Future extraction boundaries, when justified by implementation, are:

- `storage.lua` — persistent state initialization and migrations;
- `rails.lua` — rail identity and electrification markers;
- `trains.lua` — train discovery and composition lifecycle;
- `power.lua` — energy transfer and battery accounting.

Do not split the current runtime code until the data ownership and event-registration boundaries are clear. Register each Factorio event handler only once.
