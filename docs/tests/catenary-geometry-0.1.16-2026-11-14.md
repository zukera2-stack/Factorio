# Game evidence: ElectrifiedMainline 0.1.16 rail-end mast preview

**Date:** 2026-11-14. **User-provided uploads:** `Тест.zip` (eleven full-resolution screenshots) and `factorio-current(20261114-115034).log`. Separately, `2026-11-14_14-53-47.zip` contains one screenshot of **vanilla rail-signal cursor placement indicators**. Source bytes were inspected in conversation; they are **not stored in GitHub**, to avoid including the user's full game screenshots/log and incidental personal information.

## Independently observed in game log

- Factorio **2.1.20 build 87512**, Windows; Space Age enabled.
- `Loading mod ElectrifiedMainline 0.1.16 (data.lua)` at timestamp 1.589, and the matching data-update and final-fixes stages; custom rail upgrades configured for all four geometry prototypes (configuration is NOT a four-shape gameplay test).
- Existing save `ВСМ.zip` opened; `power_019.lua` rebuilt rail-following visual graph.
- **11 executions** of `[ElectrifiedMainline][0.1.16][geometry]` appeared with identical **ends=2 candidates=4 duplicate=0 clear=4 blocked=0 api_error=0**, distributed as follows:
  - `em-high-speed-straight-rail`: **4** commands.
  - `em-curved-high-speed-rail` (curve A): **3** commands.
  - `em-curved-high-speed-rail-b` (curve B): **4** commands.
  - `em-half-diagonal-high-speed-rail`: **0** commands.
- No mod Lua exception or `Error MainLoop` detected. Log ended with normal `Quitting: user-quit` and `Goodbye`.

## Visual screenshots (11 files)

`2026-11-14_14-45-07.png`, `14-45-44`, `14-46-07`, `14-46-32`, `14-47-00`, `14-47-29`, `14-48-04`, `14-48-32`, `14-48-55`, `14-49-21`, `14-49-54` (all full filename prefix `2026-11-14_`).

The screenshots show four numbered green candidate base rings on each selected straight/curved HSR rail and a **single translucent mast graphic** at the selected point, oriented toward a rail end. The screenshots also show that a green collision result does not necessarily make the sprite physically aligned with the track: on curves the mast base/arm position is sometimes visually unsuitable. The algorithm chooses a rail end and one nearest CLEAR candidate, not a continuous track-side cursor location.

**Native signalling comparator:** `2026-11-14_14-53-47.png` shows dozens of green rail signal installation indicators along a **continuous straight-to-curved rail route**, both sides, while the rail signal item is held. This is **Factorio's placement UI**, not an ElectrifiedMainline-generated overlay or evidence that a normal electric pole can use it.

## Proof boundaries

**Game-tested:** game load and command execution for straight and both curved HSR prototypes in this modpack; four green candidates and one rendered mast image per invocation; no thrown runtime error in supplied log.

**Not game-tested:** half-diagonal, command parameter failures, occupied-site collision reporting, multiple parallel tracks/crossings, actual pole placement, sprites' correct offset/wire alignment, signal block invariants, bot placement, blueprint/ghost Undo/Redo, data compatibility of any rail-signal proxy.

The **11** runs all return `clear=4` and `blocked=0` even where preview looks unfit: `LuaSurface.can_place_entity` is collision preflight, not a mast placement certification. No Undo/Redo was executed in the provided log; unchanged Undo is a design property of read-only current command, not newly proven gameplay behavior.

## Next objective

See [0.1.17 rail-signal-style snap mechanism research](../research/native-signal-snap-for-catenary-0.1.17.md) before altering prototypes. Hold stable `main` at tested 0.1.8 and keep 0.1.16 source unchanged.
