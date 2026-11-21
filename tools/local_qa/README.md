# Electrified Mainline: fast, offline QA kit

Run `python3 tools/local_qa/run_local_qa.py --mod /path/to/ElectrifiedMainline_0.1.61.zip --expected-version 0.1.61 --report build/local-qa.json` from any directory. It also accepts an unzipped `ElectrifiedMainline/` folder or the outer GitHub Actions artifact ZIP. Use `--log /path/to/factorio-current.log` for a separately labelled analysis of a real previous game session.

The runner needs only Python 3 and a Lua interpreter: `lua5.2` is preferred; if absent on Linux, `liblua5.4.so.0` is used through Python `ctypes`. No external Python packages, network, GitHub Actions, or game installation is needed for fast unit and ZIP checks. Every stage prints `[PASS]`/`[FAIL]` immediately, and optionally writes JSON. Lua 5.4 compatibility is not exact Lua 5.2 compatibility: official Factorio 2.1 testing remains a separate acceptance gate.

It checks actual packaged game files: ZIP structure and CRC, metadata and PNG inventory, compiles all runtime Lua, then executes pure Lua tests of the **real** `scripts.bridge_dispatch_059`, `scripts.bridge_devices_060`, `scripts.priority_diagnostics_061` and `scripts.power_topology` modules. Dispatch includes 700 seeded randomized multi-node graphs, conservation constraints, reverse flows, 20 MW/station caps and storage. Bob's accumulator test is a *mocked device API* with observed 240/960 kW properties, not Factorio/Bob's native simulation.

## Scope and limits

- **Does prove:** the downloaded versioned byte-for-byte package passes local static checks, real pure-module Lua control laws satisfy test invariants for the generated scenarios, 061 read-only diagnostic uses correct unit conversion, and any supplied log has historical observations.
- **Does not prove:** actual Factorio electric solver dispatch, priority scheduling, in-game locomotive load, Bob's engine compatibility in all circumstances, save-game migration, integrity of physical rail layout. Native Factorio checks must be run with the real engine; when it is unavailable, this toolkit clearly reports so and never labels local Lua emulation `Game PASS`.
- No game or updater code is modified. This QA kit never writes savegames or user mods. It consumes temp extracted copies.

Repository path: `tools/local_qa`. For new chats see `docs/CURRENT_WORK.md` and `.agents/skills/factorio-native-research/SKILL.md` in the **main** branch; check live refs.