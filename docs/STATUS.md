# Development status

This document distinguishes what is present in the source from what is verified in-game.

## Current snapshot

- Mod metadata declares Factorio 2.1 and `base >= 2.1.0`.
- Source contains data-stage definitions for custom rail prototypes, an electric-locomotive prototype, item prototypes, recipes and technologies.
- English and Russian locale files are present.
- A 0.1.0 ZIP archive is stored under `mods/`.
- No reproducible in-game test result is currently recorded in this repository.

## Gaps visible in the current source

The following are source-review findings, not a claim that every issue has been reproduced in-game:

1. **Runtime update interval:** `control.lua` uses `update_interval` in the tick handler, but no declaration is present in the reviewed source. This needs to be defined before the handler can safely perform the modulo operation.
2. **Electrical connection is currently simulated, not detected:** the tick handler sets `on_electrified` to true unconditionally. The battery-discharge path therefore does not represent travel on non-electrified track.
3. **Battery units/comment mismatch:** the initial charge value is `600000000000` joules (600 GJ), while the nearby comment says 600 MJ. The intended capacity must be decided and the value corrected.
4. **Previous train speed:** the braking logic reads `train.previous_speed`. The mod should not rely on this without confirming that the property exists in the target runtime API; storing the previous speed in mod state may be necessary.
5. **Entity/event access:** the runtime code uses `game.get_entity_at` and `event.position` in build handlers. These calls and event fields must be checked against the exact Factorio 2.1 API; build events commonly provide the created entity directly.
6. **Train enumeration:** the code iterates `player.trains` and then `train.locomotives`. Confirm the API shape and ensure trains without a player association are handled.
7. **Prototype completeness:** the source defines items for the electric pole and high-speed wagons, but the reviewed data-stage file does not define matching placeable pole or wagon entity prototypes. Their intended behavior needs to be implemented or clearly presented as non-placeable components.
8. **Research ingredients and references:** verify every technology ingredient, prerequisite, recipe unlock and referenced item against the target Factorio version. In particular, check that the names used in technology unit ingredients are valid science-pack names.
9. **Regenerative-braking item:** a recipe is defined and unlocked for `em-regenerative-brake-unit`; verify that the corresponding item prototype exists.
10. **Archive consistency:** the committed ZIP has not yet been unpacked and compared with the source directory. Rebuild it after source changes.

## Suggested work order

### P0 — Make the mod load and run safely
- Validate all data-stage prototypes and references in Factorio 2.1.
- Resolve runtime API mismatches.
- Define a safe update cadence and persistent state.
- Test save/load and train lifecycle events.

### P1 — Make the advertised mechanics real
- Implement actual rail/power-state detection, or rename the mechanic to reflect its simplified behavior.
- Define the battery capacity and energy accounting consistently.
- Implement and test regenerative braking using measured speed changes.
- Decide whether poles and wagons are functional entities or intentionally omitted from the prototype.

### P2 — Release hygiene
- Rebuild the ZIP from the source folder.
- Confirm the archive layout and version metadata.
- Record tested Factorio build and expansion requirements.
- Add screenshots and a release note only after the corresponding features are verified.

## Verification checklist

- [ ] Mod loads in the target Factorio 2.1 build.
- [ ] No prototype validation errors.
- [ ] No runtime errors on a new save.
- [ ] Mod state survives save/load.
- [ ] Player-built and robot-built rails are handled.
- [ ] Train creation, merge, split and destruction are handled.
- [ ] Battery charge changes according to the intended power model.
- [ ] Regenerative braking is tested.
- [ ] English and Russian locale keys cover all visible custom prototypes.
- [ ] Release ZIP matches the source folder.
